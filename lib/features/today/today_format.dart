/// Pure presentation helpers for the Today screen (no widgets), so they can
/// be unit-tested directly with a looked-up [AppLocalizations].
library;

import 'package:intl/intl.dart';

import '../../core/dates.dart';
import '../../domain/default_goals.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';

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
    _ => _custom(g),
  };

  /// A unit the goal was given in the goal form, if any.
  String? _custom(GoalDef g) {
    final u = g.unit(l.localeName.substring(0, 2));
    return u.isEmpty ? null : u;
  }

  String _withUnit(GoalDef g, String text) => switch (g.type) {
    GoalType.number when g.id == GoalIds.steps => l.todayValueSteps(text),
    GoalType.minutes => l.todayValueMinutes(text),
    _ => [text, ?_custom(g)].join(' '),
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
