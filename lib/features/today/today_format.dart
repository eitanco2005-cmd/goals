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

  /// A goal's value as shown: `6,400`, or `1:15` for a time goal in hours.
  String amount(GoalDef g, num v) =>
      g.type == GoalType.minutes && g.hours ? hoursMinutes(v) : number(v);

  /// Minutes as hours: `2`, `1:15`, `0:30`.
  static String hoursMinutes(num minutes) {
    final total = minutes.round();
    final h = total ~/ 60;
    final m = total % 60;
    return m == 0 ? '$h' : '$h:${m.toString().padLeft(2, '0')}';
  }

  /// The +/- button text: `1,000`, `15`, or `0:15` for a goal in hours.
  String stepLabel(GoalDef g) => amount(g, g.step);

  /// Short unit word shown next to a value ("steps", "min"), if any.
  String? unit(GoalDef g) => switch (g.type) {
    GoalType.number when g.id == GoalIds.steps => l.todayUnitSteps,
    GoalType.minutes => g.hours ? l.todayUnitHours : l.todayUnitMinutes,
    _ => _custom(g),
  };

  /// A unit the goal was given in the goal form, if any.
  String? _custom(GoalDef g) {
    final u = g.unit(l.localeName.substring(0, 2));
    return u.isEmpty ? null : u;
  }

  String _withUnit(GoalDef g, String text) => switch (g.type) {
    GoalType.number when g.id == GoalIds.steps => l.todayValueSteps(text),
    GoalType.minutes =>
      g.hours ? l.todayValueHours(text) : l.todayValueMinutes(text),
    _ => [text, ?_custom(g)].join(' '),
  };

  /// Target description shown under the goal title:
  /// `5 / 8`, `6,400 / 10,000 steps`, `max 60 min`. Null for yes/no goals.
  String? target(GoalDef g, num? value) {
    if (g.type == GoalType.boolean || g.type == GoalType.workouts) return null;
    if (g.comparison == Comparison.atMost) {
      return l.todayAtMost(_withUnit(g, amount(g, g.target)));
    }
    return _withUnit(
      g,
      l.todayProgressOf(amount(g, value ?? 0), amount(g, g.target)),
    );
  }
}
