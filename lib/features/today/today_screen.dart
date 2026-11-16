import 'dart:async';

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/demo.dart';
import '../../core/errors.dart';
import '../../core/providers.dart';
import '../../domain/default_goals.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../home_access/home_access_ui.dart';
import '../home_access/quick_actions.dart';
import '../photos/photo_capture.dart';
import '../week/week_glance.dart';
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

  /// How long a partner's reaction must stay put before it is announced, so
  /// cycling ❤️ → 💪 → 🔥 produces one snackbar, not three.
  static const reactionSettle = Duration(milliseconds: 1500);
  final _reactionTimers = <String, Timer>{};

  /// Whether the Android lost-camera-photo check already ran this session.
  bool _recoveryStarted = false;

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
    for (final t in _reactionTimers.values) {
      t.cancel();
    }
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _runQuickAction() async {
    final action = ref.read(pendingQuickActionProvider.notifier).take();
    final challenge = ref.read(challengeProvider).value;
    if (action == null || challenge == null) return;
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    switch (action) {
      case QuickAction.logWater:
        final water = challenge.dailyGoals
            .where((g) => g.id == GoalIds.water)
            .firstOrNull;
        if (water == null) return;
        final current =
            ref.read(todayLogProvider).value?.valueOf(water.id) ?? 0;
        final next = current + 1;
        final messenger = ScaffoldMessenger.of(context);
        HapticFeedback.selectionClick();
        try {
          await ref
              .read(todayLogControllerProvider.notifier)
              .setValue(water.id, next);
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  l.shortcutWaterLogged(
                    water.icon,
                    next.toInt(),
                    water.target.toInt(),
                  ),
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text(errorMessage(l, e))));
        }
      case QuickAction.addPhoto:
        final goal = await showGoalChooser<GoalDef>(
          context,
          title: l.shortcutChooseGoal,
          options: [
            for (final g in challenge.goals) (g.icon, g.title(lang), g),
          ],
        );
        if (goal != null && mounted) await addGoalPhoto(context, ref, goal);
    }
  }

  /// Announces [r] once the partner's reaction on that photo has settled for
  /// [reactionSettle]; nothing if they removed it in the meantime.
  void _scheduleReaction(PartnerReaction r, String myUid) {
    _reactionTimers.remove(r.photo.id)?.cancel();
    _reactionTimers[r.photo.id] = Timer(reactionSettle, () {
      _reactionTimers.remove(r.photo.id);
      if (!mounted) return;
      final photo = (ref.read(todayPhotosProvider).value ?? const <GoalPhoto>[])
          .where((p) => p.id == r.photo.id)
          .firstOrNull;
      final emoji = photo?.reactions[r.reactorUid];
      if (photo == null || emoji == null) return;
      _showReaction((
        photo: photo,
        reactorUid: r.reactorUid,
        emoji: emoji,
      ), myUid);
    });
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
      for (final r in newPartnerReactions(before, after, myUid)) {
        _scheduleReaction(r, myUid);
      }
    });

    // Android may kill the app while the camera is open; pick the photo up
    // once today's challenge is loaded (an upload needs the pair and day).
    if (!_recoveryStarted &&
        pickerMayLoseData &&
        ref.watch(todayScopeProvider) != null) {
      _recoveryStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) recoverLostGoalPhoto(context, ref);
      });
    }

    // A launcher shortcut (long-press on the app icon) waiting to run. It
    // needs the day's log loaded, so +1 never overwrites a value not seen yet.
    if (ref.watch(pendingQuickActionProvider) != null &&
        ref.watch(todayScopeProvider) != null &&
        ref.watch(challengeProvider).value != null &&
        ref.watch(todayLogProvider).hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _runQuickAction();
      });
    }

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
              const InstallAppCard(),
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
                WeekGlanceCard(goals: weeklyGoals),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
