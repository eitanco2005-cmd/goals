import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../pairing/invite_code_card.dart';
import 'progress_ring.dart';
import 'today_format.dart';
import 'today_providers.dart';

/// Partner strip, or a "waiting for your partner" card until they join.
class PartnerSection extends ConsumerWidget {
  const PartnerSection({super.key, required this.dailyGoals});

  final List<GoalDef> dailyGoals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pair = ref.watch(pairProvider).value;
    if (pair == null) return const SizedBox.shrink();
    final partnerUid = ref.watch(partnerUidProvider);
    if (partnerUid == null) return WaitingForPartnerCard(code: pair.inviteCode);
    return PartnerStrip(
      name:
          pair.memberNames[partnerUid] ??
          AppLocalizations.of(context).todayPartnerFallbackName,
      summary: ref.watch(partnerTodaySummaryProvider).value,
      dailyGoals: dailyGoals,
    );
  }
}

/// The partner's day at a glance: name, % and a ✔/✘ dot per goal.
/// Built ONLY from their public [DaySummary].
class PartnerStrip extends StatelessWidget {
  const PartnerStrip({
    super.key,
    required this.name,
    required this.summary,
    required this.dailyGoals,
  });

  final String name;
  final DaySummary? summary;
  final List<GoalDef> dailyGoals;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final summary = this.summary;
    final percent = summary?.percent ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.partner,
                  child: Text(
                    name.characters.firstOrNull?.toUpperCase() ?? '?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        summary == null
                            ? l.todayPartnerNothingYet
                            : l.todayPartnerPercent(percent),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ProgressRing(
                  percent: percent,
                  size: 48,
                  strokeWidth: 5,
                  color: AppColors.partner,
                  semanticsLabel: '$name: ${l.todayProgressSemantics(percent)}',
                  labelStyle: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final g in dailyGoals)
                  PartnerGoalDot(
                    icon: g.icon,
                    status: summary?.statuses[g.id] ?? GoalStatus.unlogged,
                    semanticsLabel: l.todayGoalStatusSemantics(
                      g.title(lang),
                      (summary?.statuses[g.id] ?? GoalStatus.unlogged).label(l),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A goal icon in a circle tinted by status.
class PartnerGoalDot extends StatelessWidget {
  const PartnerGoalDot({
    super.key,
    required this.icon,
    required this.status,
    required this.semanticsLabel,
  });

  final String icon;
  final GoalStatus status;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final unlogged = status == GoalStatus.unlogged;
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: status.color.withValues(alpha: unlogged ? 0.12 : 0.2),
          border: Border.all(
            color: unlogged ? Colors.transparent : status.color,
            width: 2,
          ),
        ),
        child: Opacity(
          opacity: unlogged ? 0.45 : 1,
          child: Text(
            icon,
            style: const TextStyle(fontSize: 16),
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}

/// Shown instead of the partner strip until the partner joins.
class WaitingForPartnerCard extends StatelessWidget {
  const WaitingForPartnerCard({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      color: Color.alphaBlend(
        AppColors.partner.withValues(alpha: 0.08),
        theme.colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('💌', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.todayWaitingTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l.todayWaitingBody, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            InviteCodeCard(code: code),
          ],
        ),
      ),
    );
  }
}
