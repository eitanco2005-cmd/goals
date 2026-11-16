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

/// Status of one daily goal, given which goals have a photo that day.
/// A goal that requires a photo is not met until it has one.
GoalStatus dayGoalStatus(
  GoalDef goal,
  DailyLog log, {
  Set<String> photoGoalIds = const {},
}) {
  final status = evaluateGoal(goal, log.valueOf(goal.id));
  if (status == GoalStatus.met &&
      goal.requiresPhoto &&
      !photoGoalIds.contains(goal.id)) {
    return GoalStatus.notMet;
  }
  return status;
}

/// Whether [goal]'s logged value reaches its target but its required photo
/// is still missing ("add a photo to complete").
bool waitingForPhoto(GoalDef goal, num? value, Set<String> photoGoalIds) =>
    goal.requiresPhoto &&
    !photoGoalIds.contains(goal.id) &&
    evaluateGoal(goal, value) == GoalStatus.met;

/// Builds the public [DaySummary] for a day from the private [DailyLog].
/// [photoGoalIds]: goals the person attached a photo to that day.
DaySummary summarizeDay(
  DailyLog log,
  List<GoalDef> dailyGoals, {
  Set<String> photoGoalIds = const {},
}) {
  final statuses = <String, GoalStatus>{
    for (final g in dailyGoals)
      g.id: dayGoalStatus(g, log, photoGoalIds: photoGoalIds),
  };
  final met = statuses.values.where((s) => s == GoalStatus.met).length;
  final percent = dailyGoals.isEmpty
      ? 0
      : ((met / dailyGoals.length) * 100).round();
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
  final ok =
      valid.length >= goal.target &&
      runs >= (goal.requirements['run'] ?? 0) &&
      strength >= (goal.requirements['strength'] ?? 0);
  return ok ? GoalStatus.met : GoalStatus.notMet;
}

/// Builds the public [WeekSummary] for [weeklyGoals].
///
/// Workout goals are scored from [workouts] (this week's entries). Counter
/// goals (e.g. junk food) are scored from [totals]: the sum of that goal's
/// value over the week's daily logs. For a limit ("at most") nothing logged
/// counts as 0, i.e. on track; for a minimum it stays unlogged.
WeekSummary summarizeWeek({
  required String uid,
  required String weekStart,
  required List<GoalDef> weeklyGoals,
  required List<WorkoutEntry> workouts,
  required Map<String, num> totals,
}) => WeekSummary(
  uid: uid,
  weekStart: weekStart,
  statuses: {
    for (final g in weeklyGoals)
      g.id: g.type == GoalType.workouts
          ? evaluateWorkouts(g, workouts)
          : evaluateGoal(
              g,
              totals[g.id] ?? (g.comparison == Comparison.atMost ? 0 : null),
            ),
  },
);

/// Sums each goal's values over several daily logs (e.g. one week).
Map<String, num> sumLogs(Iterable<DailyLog> logs) {
  final totals = <String, num>{};
  for (final log in logs) {
    log.values.forEach((k, v) => totals[k] = (totals[k] ?? 0) + v);
  }
  return totals;
}

/// Whether a goal that is not met has FAILED (a rule was broken) rather
/// than being still open: a limit was exceeded ("at most"), a yes/no goal
/// was answered no, or an "exactly" target was overshot. Goals still short
/// of a minimum are open, not failed.
///
/// [value] may be null when only the public summary is known (another
/// member): limits and yes/no goals then count as failed, except a yes/no
/// goal that requires a photo (it may just be missing the photo).
bool isFailure(GoalDef goal, num? value) {
  if (goal.type == GoalType.workouts) return false;
  if (goal.type == GoalType.boolean) {
    return value == null ? !goal.requiresPhoto : value < goal.target;
  }
  return switch (goal.comparison) {
    Comparison.atMost =>
      value == null ? !goal.requiresPhoto : value > goal.target,
    Comparison.exactly => value != null && value > goal.target,
    Comparison.atLeast => false,
  };
}
