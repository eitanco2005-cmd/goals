import 'package:material_ui/material_ui.dart' show Color;

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
