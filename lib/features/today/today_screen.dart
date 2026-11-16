import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/demo.dart';
import '../../core/errors.dart';
import '../../core/providers.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../photos/photo_capture.dart';
import '../photos/photo_providers.dart';
import '../photos/photo_thumbnails.dart';
import '../photos/photo_viewer.dart';
import 'goal_card.dart';
import 'partner_strip.dart';
import 'today_cards.dart';
import 'today_format.dart';
import 'today_header.dart';
import 'today_providers.dart';

/// The heart of the app: log today's goals and glance at the partner's day.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Roll the day over when the app comes back after the day start.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(todayKeyProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// "Noa reacted ❤️ to your photo 🥗", with a shortcut to the photo.
  void _showReaction(PartnerReaction reaction, String myUid) {
    final l = AppLocalizations.of(context);
    final name =
        ref.read(pairProvider).value?.memberNames[reaction.reactorUid] ??
        l.todayPartnerFallbackName;
    final goals = ref.read(challengeProvider).value?.goals ?? const [];
    final icon =
        goals.where((g) => g.id == reaction.photo.goalId).firstOrNull?.icon ??
        unknownGoalIcon;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.photoReactionSnack(name, reaction.emoji, icon)),
          behavior: SnackBarBehavior.floating,
          persist: false, // auto-hide even though it has an action
          action: SnackBarAction(
            label: l.photoView,
            onPressed: () {
              final mine = ref.read(userTodayPhotosProvider(myUid));
              final i = mine.indexWhere((p) => p.id == reaction.photo.id);
              if (i >= 0) {
                openPhotoViewer(context, photos: mine, initialIndex: i);
              }
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    ref.listen(myTodaySummaryProvider.select((s) => s?.percent), (prev, next) {
      if (prev != null && prev < 100 && next == 100) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(l.todayAllDone),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    });

    ref.listen(logWriteErrorsProvider, (_, next) {
      if (next case AsyncData(:final value)) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage(l, value))));
      }
    });

    ref.listen(todayPhotosProvider, (prev, next) {
      final before = prev?.value;
      final after = next.value;
      final myUid = ref.read(authStateProvider).value?.uid;
      if (before == null || after == null || myUid == null) return;
      final reactions = newPartnerReactions(before, after, myUid);
      if (reactions.isNotEmpty) _showReaction(reactions.last, myUid);
    });

    final body = switch (ref.watch(challengeProvider)) {
      AsyncValue(value: final Challenge challenge) => _TodayContent(
        challenge: challenge,
      ),
      AsyncValue(hasValue: true) => TodayMessage(
        emoji: '🌱',
        title: l.todayNoChallengeTitle,
        body: l.todayNoChallengeBody,
      ),
      AsyncError(:final error) => TodayMessage(
        emoji: '😕',
        title: errorMessage(l, error),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
    return Scaffold(body: SafeArea(bottom: false, child: body));
  }
}

class _TodayContent extends ConsumerWidget {
  const _TodayContent({required this.challenge});

  final Challenge challenge;

  /// Sets [value]; when that clears a logged value, offers an Undo.
  Future<void> _set(
    BuildContext context,
    WidgetRef ref,
    GoalDef goal,
    num? value,
  ) async {
    HapticFeedback.selectionClick();
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    final controller = ref.read(todayLogControllerProvider.notifier);
    final previous = ref.read(todayLogProvider).value?.valueOf(goal.id);

    Future<void> write(num? v) async {
      try {
        await controller.setValue(goal.id, v);
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(errorMessage(l, e))));
      }
    }

    if (value == null && previous != null) {
      final lang = Localizations.localeOf(context).languageCode;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l.todayClearedGoal(goal.title(lang))),
            behavior: SnackBarBehavior.floating,
            persist: false, // auto-hide even though it has an action
            action: SnackBarAction(
              label: l.todayUndo,
              onPressed: () => write(previous),
            ),
          ),
        );
    }
    await write(value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final todayKey = ref.watch(todayKeyProvider);
    final log = ref.watch(todayLogProvider);
    final summary = ref.watch(myTodaySummaryProvider);
    final name =
        ref.watch(profileProvider.select((p) => p.value?.displayName)) ?? '';
    final showDemo =
        ref.watch(isDemoModeProvider) &&
        !ref.watch(demoBannerDismissedProvider);
    final lang = Localizations.localeOf(context).languageCode;
    final dailyGoals = challenge.dailyGoals;
    final weeklyGoals = challenge.weeklyGoals;
    final met =
        summary?.statuses.values.where((s) => s == GoalStatus.met).length ?? 0;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 32),
          sliver: SliverList.list(
            children: [
              if (showDemo) ...[
                DemoModeBanner(
                  code: demoInviteCode,
                  onDismiss: () =>
                      ref.read(demoBannerDismissedProvider.notifier).dismiss(),
                ),
                const SizedBox(height: 16),
              ],
              TodayHeader(
                greeting: greetingFor(l, DateTime.now().hour),
                name: name,
                dateText: DateFormat.MMMMEEEEd(locale)
                    .format(parseDayKey(todayKey)),
                dayLabel: challengeDayLabel(
                  l,
                  challengeProgress(challenge, todayKey),
                ),
                percent: summary?.percent ?? 0,
                met: met,
                total: dailyGoals.length,
              ),
              const SizedBox(height: 20),
              PartnerSection(dailyGoals: dailyGoals),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
                child: Text(
                  l.todayYourGoals,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (log case AsyncError(:final error))
                TodayMessage(emoji: '😕', title: errorMessage(l, error))
              else if (dailyGoals.isEmpty)
                TodayMessage(emoji: '🗒️', title: l.todayNoDailyGoals)
              else
                for (final goal in dailyGoals)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GoalCard(
                      key: ValueKey('goal-${goal.id}'),
                      goal: goal,
                      value: log.value?.valueOf(goal.id),
                      enabled: log.value != null,
                      onChanged: (v) => _set(context, ref, goal, v),
                      photoAction: GoalPhotoButton(
                        goal: goal,
                        title: goal.title(lang),
                      ),
                      photos: GoalPhotoStrip(
                        goal: goal,
                        title: goal.title(lang),
                      ),
                    ),
                  ),
              if (weeklyGoals.isNotEmpty) ...[
                const SizedBox(height: 12),
                WeeklyTeaserCard(goals: weeklyGoals),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
