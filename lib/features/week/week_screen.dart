import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/errors.dart';
import '../../core/providers.dart';
import '../../core/status_ui.dart';
import '../../domain/goal_eval.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import 'week_providers.dart';

/// Weekly goals: log workouts and weekly counters (junk food) for any day
/// of the week, and see whether the others met their weekly goals (status
/// only — never their workouts or counts).
class WeekScreen extends ConsumerWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final challenge = ref.watch(challengeProvider).value;
    final selected = ref.watch(selectedWeekProvider);
    // Publish edits made here (e.g. to a past week) for the group.
    ref.watch(weekSummaryPublisherProvider(selected.week));
    final isCurrent = selected.week == currentWeekStart();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final title = isCurrent
        ? l.weekTitle
        : l.weekPastTitle(
            DateFormat.MMMd(locale).format(parseDayKey(selected.week)),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: l.weekPrev,
            icon: const Icon(Icons.chevron_left),
            onPressed: () => ref.read(selectedWeekProvider.notifier).shift(-1),
          ),
          IconButton(
            tooltip: l.weekNext,
            icon: const Icon(Icons.chevron_right),
            onPressed: isCurrent
                ? null
                : () => ref.read(selectedWeekProvider.notifier).shift(1),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: challenge == null
            ? const Center(child: CircularProgressIndicator())
            : Align(
                alignment: AlignmentDirectional.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      4,
                      16,
                      32,
                    ),
                    children: [
                      _DayPicker(selected: selected, challenge: challenge),
                      const SizedBox(height: 16),
                      for (final goal in challenge.weeklyGoals) ...[
                        if (goal.type == GoalType.workouts)
                          _WorkoutsCard(goal: goal, selected: selected)
                        else
                          _WeeklyCounterCard(
                            goal: goal,
                            selected: selected,
                            dailyGoals: challenge.dailyGoals,
                          ),
                        const SizedBox(height: 12),
                      ],
                      _GroupWeekCard(
                        week: selected.week,
                        weeklyGoals: challenge.weeklyGoals,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Sunday..Saturday chips; the selected day is where new entries go. Each
/// chip shows my daily % for that day.
class _DayPicker extends ConsumerWidget {
  const _DayPicker({required this.selected, required this.challenge});

  final ({String week, String day}) selected;
  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = ref.watch(todayKeyProvider);
    return Row(
      children: [
        for (final day in daysOfWeek(selected.week))
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Builder(
                builder: (context) {
                  final date = parseDayKey(day);
                  final future = day.compareTo(today) > 0;
                  final isSelected = day == selected.day;
                  final log = ref.watch(myDayLogProvider(day)).value;
                  final percent = log == null
                      ? 0
                      : summarizeDay(log, challenge.dailyGoals).percent;
                  return Semantics(
                    selected: isSelected,
                    button: true,
                    label: DateFormat.MMMMEEEEd(locale).format(date),
                    child: Material(
                      color: isSelected
                          ? scheme.primaryContainer
                          : scheme.surface.withValues(alpha: future ? 0.4 : 1),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: future
                            ? null
                            : () => ref
                                  .read(selectedWeekProvider.notifier)
                                  .selectDay(day),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              Text(
                                DateFormat.E(locale).format(date),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Text(
                                '${date.day}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: day == today
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              _PercentDot(percent: future ? null : percent),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// Small dot whose fill shows a day's %.
class _PercentDot extends StatelessWidget {
  const _PercentDot({required this.percent});
  final int? percent;

  @override
  Widget build(BuildContext context) {
    final p = percent;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: p == null || p == 0
            ? scheme.outlineVariant.withValues(alpha: 0.5)
            : GoalStatus.met.color.withValues(alpha: 0.25 + 0.75 * p / 100),
      ),
    );
  }
}

String _workoutLabel(AppLocalizations l, WorkoutType t) => switch (t) {
  WorkoutType.run => l.workoutRun,
  WorkoutType.strength => l.workoutStrength,
  WorkoutType.other => l.workoutOther,
};

String _workoutIcon(WorkoutType t) => switch (t) {
  WorkoutType.run => '🏃',
  WorkoutType.strength => '💪',
  WorkoutType.other => '🤸',
};

/// Card header shared by the weekly goal cards: icon, title, status chip.
class _GoalHeader extends StatelessWidget {
  const _GoalHeader({
    required this.goal,
    required this.status,
    required this.subtitle,
    this.open = false,
  });

  final GoalDef goal;
  final GoalStatus status;
  final String subtitle;

  /// The week shown is still running.
  final bool open;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Row(
      children: [
        Text(
          goal.icon,
          style: const TextStyle(fontSize: 26),
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.title(lang),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: status == GoalStatus.unlogged
                      ? theme.colorScheme.onSurfaceVariant
                      : goalOutcome(goal, status, periodOpen: open).color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _StatusChip(outcome: goalOutcome(goal, status, periodOpen: open)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.outcome});
  final GoalOutcome outcome;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: outcome.color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      outcome.label(AppLocalizations.of(context)),
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: outcome.color, fontWeight: FontWeight.w700),
    ),
  );
}

class _WorkoutsCard extends ConsumerWidget {
  const _WorkoutsCard({required this.goal, required this.selected});

  final GoalDef goal;
  final ({String week, String day}) selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final entries =
        ref.watch(myWeekWorkoutsProvider(selected.week)).value ??
        const <WorkoutEntry>[];
    final minMinutes = (goal.requirements['minMinutes'] ?? 0).toInt();
    final counted = entries.where((e) => e.minutes >= minMinutes).toList();
    final status = evaluateWorkouts(goal, entries);

    final parts = <String>[
      l.weekDone(counted.length, goal.target.toInt()),
      for (final type in [WorkoutType.run, WorkoutType.strength])
        if ((goal.requirements[type.name] ?? 0) > 0)
          '${_workoutIcon(type)} ${l.weekDone(counted.where((e) => e.type == type).length, goal.requirements[type.name]!.toInt())}',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GoalHeader(
              goal: goal,
              status: status,
              subtitle: parts.join(' · '),
            ),
            if (minMinutes > 0)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 4, start: 38),
                child: Text(
                  l.weekMinMinutes(minMinutes),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l.weekNoWorkouts,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final e in entries)
              ListTile(
                key: ValueKey('workout-${e.id}'),
                contentPadding: EdgeInsets.zero,
                leading: Text(
                  _workoutIcon(e.type),
                  style: const TextStyle(fontSize: 22),
                ),
                title: Text(
                  '${_workoutLabel(l, e.type)} · ${l.weekMinutes(e.minutes)}',
                ),
                subtitle: Text(
                  [
                    DateFormat.EEEE(locale).format(parseDayKey(e.date)),
                    if (e.minutes < minMinutes) l.weekTooShort(minMinutes),
                  ].join(' · '),
                ),
                trailing: IconButton(
                  tooltip: l.weekDeleteWorkout,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, ref, e),
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
                onPressed: () => _add(context, ref, minMinutes),
                icon: const Icon(Icons.add),
                label: Text(l.weekAddWorkout),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref, int minMinutes) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result =
        await showModalBottomSheet<({WorkoutType type, int minutes})>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (_) => _AddWorkoutSheet(
            defaultMinutes: minMinutes > 0 ? minMinutes : 30,
          ),
        );
    if (result == null) return;
    final uid = ref.read(authStateProvider).value?.uid;
    final pairId = ref.read(profileProvider).value?.pairId;
    if (uid == null || pairId == null) return;
    HapticFeedback.selectionClick();
    try {
      await ref
          .read(logRepositoryProvider)
          .addWorkout(
            pairId: pairId,
            entry: WorkoutEntry(
              id: '',
              uid: uid,
              date: selected.day,
              type: result.type,
              minutes: result.minutes,
            ),
          );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(l, e))));
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    WorkoutEntry e,
  ) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final pairId = ref.read(profileProvider).value?.pairId;
    if (pairId == null) return;
    final repo = ref.read(logRepositoryProvider);
    try {
      await repo.deleteWorkout(pairId: pairId, id: e.id);
    } catch (err) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(l, err))));
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.todayClearedGoal(_workoutLabel(l, e.type))),
          behavior: SnackBarBehavior.floating,
          persist: false,
          action: SnackBarAction(
            label: l.todayUndo,
            onPressed: () => repo.addWorkout(pairId: pairId, entry: e),
          ),
        ),
      );
  }
}

/// Type + duration picker for a new workout.
class _AddWorkoutSheet extends StatefulWidget {
  const _AddWorkoutSheet({required this.defaultMinutes});
  final int defaultMinutes;

  @override
  State<_AddWorkoutSheet> createState() => _AddWorkoutSheetState();
}

class _AddWorkoutSheetState extends State<_AddWorkoutSheet> {
  var _type = WorkoutType.run;
  late var _minutes = widget.defaultMinutes;

  static const _durations = [20, 30, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.weekAddWorkout, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(l.weekWorkoutType, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<WorkoutType>(
              segments: [
                for (final t in WorkoutType.values)
                  ButtonSegment(
                    value: t,
                    label: Text('${_workoutIcon(t)} ${_workoutLabel(l, t)}'),
                  ),
              ],
              selected: {_type},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            Text(l.weekWorkoutDuration, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in {..._durations, _minutes}.toList()..sort())
                  ChoiceChip(
                    label: Text(l.weekMinutes(m)),
                    selected: _minutes == m,
                    onSelected: (_) => setState(() => _minutes = m),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop((type: _type, minutes: _minutes)),
              child: Text(l.todaySave),
            ),
          ],
        ),
      ),
    );
  }
}

/// A weekly limit/target counted from daily entries (e.g. junk food).
class _WeeklyCounterCard extends ConsumerWidget {
  const _WeeklyCounterCard({
    required this.goal,
    required this.selected,
    required this.dailyGoals,
  });

  final GoalDef goal;
  final ({String week, String day}) selected;
  final List<GoalDef> dailyGoals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final totals = ref.watch(myWeekTotalsProvider(selected.week));
    final total = (totals?[goal.id] ?? 0).toInt();
    final dayLog = ref.watch(myDayLogProvider(selected.day)).value;
    final onDay = (dayLog?.valueOf(goal.id) ?? 0).toInt();
    final status = evaluateGoal(
      goal,
      totals?[goal.id] ?? (goal.comparison == Comparison.atMost ? 0 : null),
    );
    final dayName = DateFormat.EEEE(locale).format(parseDayKey(selected.day));

    Future<void> set(int value) async {
      final uid = ref.read(authStateProvider).value?.uid;
      final pairId = ref.read(profileProvider).value?.pairId;
      if (uid == null || pairId == null) return;
      HapticFeedback.selectionClick();
      try {
        await ref
            .read(logRepositoryProvider)
            .setGoalValue(
              pairId: pairId,
              uid: uid,
              date: selected.day,
              goalId: goal.id,
              value: value <= 0 ? null : value,
              dailyGoals: dailyGoals,
            );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(errorMessage(l, e))));
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GoalHeader(
              goal: goal,
              status: status,
              open: ref.watch(selectedWeekProvider).week == currentWeekStart(),
              subtitle: goal.comparison == Comparison.atMost
                  ? l.weekLimitTotal(total, goal.target.toInt())
                  : l.weekDone(total, goal.target.toInt()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.weekOnDay(dayName, onDay),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: l.todayDecrease(goal.title(locale.substring(0, 2))),
                  onPressed: onDay > 0 ? () => set(onDay - 1) : null,
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: l.todayIncrease(goal.title(locale.substring(0, 2))),
                  onPressed: () => set(onDay + 1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The others' weekly goal statuses (published summaries only).
class _GroupWeekCard extends ConsumerWidget {
  const _GroupWeekCard({required this.week, required this.weeklyGoals});

  final String week;
  final List<GoalDef> weeklyGoals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final others = ref.watch(otherMemberUidsProvider);
    if (others.isEmpty || weeklyGoals.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final pair = ref.watch(pairProvider).value;
    final summaries = {
      for (final s
          in ref.watch(weekSummariesProvider(week)).value ??
              const <WeekSummary>[])
        s.uid: s,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.weekGroup,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final uid in others)
              Padding(
                key: ValueKey('week-member-$uid'),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        pair?.memberNames[uid] ?? l.todayPartnerFallbackName,
                        style: theme.textTheme.bodyLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    for (final g in weeklyGoals)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 8),
                        child: Builder(
                          builder: (context) {
                            final status =
                                summaries[uid]?.statuses[g.id] ??
                                GoalStatus.unlogged;
                            final outcome = goalOutcome(
                              g,
                              status,
                              periodOpen: week == currentWeekStart(),
                            );
                            return Semantics(
                              label: '${g.title(lang)}: ${outcome.label(l)}',
                              child: Container(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: outcome.color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: outcome.color.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  '${g.icon} ${switch (outcome) {
                                    GoalOutcome.met || GoalOutcome.onTrack => '✓',
                                    GoalOutcome.failed => '✗',
                                    GoalOutcome.notYet => '…',
                                    GoalOutcome.unlogged => '–',
                                  }}',
                                  textDirection: TextDirection.ltr,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
