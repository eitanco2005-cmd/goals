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
enum GoalOutcome { met, failed, notYet, unlogged }

/// The [GoalOutcome] of [goal] with [status]; [value] when known.
GoalOutcome goalOutcome(GoalDef goal, GoalStatus status, {num? value}) =>
    switch (status) {
      GoalStatus.met => GoalOutcome.met,
      GoalStatus.unlogged => GoalOutcome.unlogged,
      GoalStatus.notMet =>
        isFailure(goal, value) ? GoalOutcome.failed : GoalOutcome.notYet,
    };

extension GoalOutcomeUi on GoalOutcome {
  Color get color => switch (this) {
    GoalOutcome.met => AppColors.met,
    GoalOutcome.failed => AppColors.notMet,
    GoalOutcome.notYet => AppColors.inProgress,
    GoalOutcome.unlogged => AppColors.unlogged,
  };

  String label(AppLocalizations l) => switch (this) {
    GoalOutcome.met => l.statusMet,
    GoalOutcome.failed => l.statusFailed,
    GoalOutcome.notYet => l.statusNotMet,
    GoalOutcome.unlogged => l.statusUnlogged,
  };
}
