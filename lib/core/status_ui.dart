import 'package:material_ui/material_ui.dart' show Color;

import '../domain/goal_eval.dart';
import '../domain/models.dart';
import '../l10n/gen/app_localizations.dart';
import 'theme.dart';

/// Consistent color/label for a [GoalStatus] across all screens.
extension GoalStatusUi on GoalStatus {
  Color get color => switch (this) {
    GoalStatus.met => AppColors.met,
    GoalStatus.notMet => AppColors.notMet,
    GoalStatus.unlogged => AppColors.unlogged,
  };

  String label(AppLocalizations l) => switch (this) {
    GoalStatus.met => l.statusMet,
    GoalStatus.notMet => l.statusNotMet,
    GoalStatus.unlogged => l.statusUnlogged,
  };
}

/// What a goal's status means to the person: done, failed (a rule was
/// broken), not yet (still possible), or not logged.
/// [onTrack]: a limit not broken yet while its period is still running
/// (e.g. no junk food so far this week).
enum GoalOutcome { met, onTrack, failed, notYet, unlogged }

/// The [GoalOutcome] of [goal] with [status]; [value] when known.
/// [periodOpen]: the goal's week is still running (weekly limits then read
/// "on track" rather than "done"). [onPace]: a workouts goal not done yet
/// is keeping pace (see `workoutsOnPace`), which also reads "on track".
/// [periodEnded]: the goal's week is over; a weekly goal not met then
/// reads "failed".
GoalOutcome goalOutcome(
  GoalDef goal,
  GoalStatus status, {
  num? value,
  bool periodOpen = false,
  bool onPace = false,
  bool periodEnded = false,
}) => switch (status) {
  GoalStatus.met =>
    periodOpen &&
            goal.period == GoalPeriod.weekly &&
            goal.comparison == Comparison.atMost
        ? GoalOutcome.onTrack
        : GoalOutcome.met,
  // A week that is over without reaching the goal: failed, not "not yet".
  _ when periodEnded && goal.period == GoalPeriod.weekly => GoalOutcome.failed,
  // Workouts not done yet but keeping pace while the week runs.
  _ when periodOpen && onPace && goal.type == GoalType.workouts =>
    GoalOutcome.onTrack,
  GoalStatus.unlogged => GoalOutcome.unlogged,
  GoalStatus.notMet =>
    isFailure(goal, value) ? GoalOutcome.failed : GoalOutcome.notYet,
};

extension GoalOutcomeUi on GoalOutcome {
  Color get color => switch (this) {
    GoalOutcome.met || GoalOutcome.onTrack => AppColors.met,
    GoalOutcome.failed => AppColors.notMet,
    GoalOutcome.notYet => AppColors.inProgress,
    GoalOutcome.unlogged => AppColors.unlogged,
  };

  String label(AppLocalizations l) => switch (this) {
    GoalOutcome.met => l.statusMet,
    GoalOutcome.onTrack => l.statusOnTrack,
    GoalOutcome.failed => l.statusFailed,
    GoalOutcome.notYet => l.statusNotMet,
    GoalOutcome.unlogged => l.statusUnlogged,
  };
}
