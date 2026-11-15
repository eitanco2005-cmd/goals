import 'models.dart';

/// Pure scoring logic. No Flutter / Firebase imports – fully unit-testable.

/// Evaluates a single numeric goal value.
GoalStatus evaluateGoal(GoalDef goal, num? value) {
  if (value == null) return GoalStatus.unlogged;
  final ok = switch (goal.comparison) {
    Comparison.atLeast => value >= goal.target,
    Comparison.atMost => value <= goal.target,
    Comparison.exactly => value == goal.target,
  };
  return ok ? GoalStatus.met : GoalStatus.notMet;
}

/// Builds the public [DaySummary] for a day from the private [DailyLog].
DaySummary summarizeDay(DailyLog log, List<GoalDef> dailyGoals) {
  final statuses = <String, GoalStatus>{
    for (final g in dailyGoals) g.id: evaluateGoal(g, log.valueOf(g.id)),
  };
  final met = statuses.values.where((s) => s == GoalStatus.met).length;
  final percent =
      dailyGoals.isEmpty ? 0 : ((met / dailyGoals.length) * 100).round();
  return DaySummary(
    uid: log.uid,
    date: log.date,
    statuses: statuses,
    percent: percent,
  );
}

/// Goals that still need input today (used by the end-of-day check).
List<GoalDef> unloggedGoals(DailyLog log, List<GoalDef> dailyGoals) =>
    dailyGoals.where((g) => log.valueOf(g.id) == null).toList();

/// Evaluates the weekly workouts goal from the week's workout entries.
/// Only workouts of at least `minMinutes` count.
GoalStatus evaluateWorkouts(GoalDef goal, List<WorkoutEntry> weekEntries) {
  final minMinutes = goal.requirements['minMinutes'] ?? 0;
  final valid = weekEntries.where((e) => e.minutes >= minMinutes).toList();
  if (valid.isEmpty) return GoalStatus.unlogged;
  final runs = valid.where((e) => e.type == WorkoutType.run).length;
  final strength = valid.where((e) => e.type == WorkoutType.strength).length;
  final ok = valid.length >= goal.target &&
      runs >= (goal.requirements['run'] ?? 0) &&
      strength >= (goal.requirements['strength'] ?? 0);
  return ok ? GoalStatus.met : GoalStatus.notMet;
}
