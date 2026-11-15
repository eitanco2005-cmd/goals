/// Pure presentation helpers for the Today screen (no widgets), so they can
/// be unit-tested directly with a looked-up [AppLocalizations].
library;

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart' show Color;

import '../../core/dates.dart';
import '../../core/theme.dart';
import '../../domain/default_goals.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';

/// Where a given day falls inside a challenge's date range.
class ChallengeDay {
  const ChallengeDay({required this.day, required this.total});

  /// 1-based index of the day. `< 1` before the start, `> total` after the end.
  final int day;

  /// Number of days in the challenge (inclusive range).
  final int total;

  bool get notStarted => day < 1;
  bool get ended => day > total;

  /// Days left until day 1 (only meaningful when [notStarted]).
  int get daysUntilStart => 1 - day;

  @override
  bool operator ==(Object other) =>
      other is ChallengeDay && other.day == day && other.total == total;

  @override
  int get hashCode => Object.hash(day, total);

  @override
  String toString() => 'ChallengeDay($day/$total)';
}

/// Computes "day X of Y" from `yyyy-MM-dd` keys. Uses UTC day ordinals so
/// daylight-saving transitions never skew the count.
ChallengeDay challengeDay({
  required String startDate,
  required String endDate,
  required String today,
}) {
  int ordinal(String key) {
    final d = parseDayKey(key);
    return DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  final start = ordinal(startDate);
  return ChallengeDay(
    day: ordinal(today) - start + 1,
    total: ordinal(endDate) - start + 1,
  );
}

/// "Day 3 of 90", "The challenge starts tomorrow", "Challenge complete".
String challengeDayLabel(AppLocalizations l, ChallengeDay d) {
  if (d.notStarted) return l.todayChallengeStartsIn(d.daysUntilStart);
  if (d.ended) return l.todayChallengeEnded;
  return l.todayDayOfTotal(d.day, d.total);
}

/// Time-of-day greeting.
String greetingFor(AppLocalizations l, int hour) => switch (hour) {
  >= 5 && < 12 => l.todayGreetingMorning,
  >= 12 && < 17 => l.todayGreetingAfternoon,
  >= 17 && < 22 => l.todayGreetingEvening,
  _ => l.todayGreetingNight,
};

/// Localized number / target texts for goals.
class GoalFormatter {
  GoalFormatter(this.l, String locale)
    : _number = NumberFormat.decimalPattern(locale);

  final AppLocalizations l;
  final NumberFormat _number;

  /// Grouped number, e.g. `6,400`.
  String number(num v) => _number.format(v);

  /// Short unit word shown next to a value ("steps", "min"), if any.
  String? unit(GoalDef g) => switch (g.type) {
    GoalType.number when g.id == GoalIds.steps => l.todayUnitSteps,
    GoalType.minutes => l.todayUnitMinutes,
    _ => null,
  };

  String _withUnit(GoalDef g, String text) => switch (g.type) {
    GoalType.number when g.id == GoalIds.steps => l.todayValueSteps(text),
    GoalType.minutes => l.todayValueMinutes(text),
    _ => text,
  };

  /// Target description shown under the goal title:
  /// `5 / 8`, `6,400 / 10,000 steps`, `max 60 min`. Null for yes/no goals.
  String? target(GoalDef g, num? value) {
    if (g.type == GoalType.boolean || g.type == GoalType.workouts) return null;
    if (g.comparison == Comparison.atMost) {
      return l.todayAtMost(_withUnit(g, number(g.target)));
    }
    return _withUnit(
      g,
      l.todayProgressOf(number(value ?? 0), number(g.target)),
    );
  }
}

/// Consistent color/label for a [GoalStatus].
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
