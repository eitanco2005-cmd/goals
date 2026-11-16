import '../core/dates.dart';
import 'models.dart';

/// A day counts toward a streak when at least this share of the daily
/// goals was met.
const goodDayPercent = 70;

/// Days in a row (ending today, or yesterday while today is still in
/// progress) with at least [goodDayPercent]. [percentByDay] maps day keys
/// to the daily %; missing days count as 0.
int currentStreak(Map<String, int> percentByDay, String today) {
  var day = parseDayKey(today);
  // Today doesn't break the streak until it's over.
  if ((percentByDay[today] ?? 0) < goodDayPercent) {
    day = DateTime(day.year, day.month, day.day - 1);
  }
  var streak = 0;
  while ((percentByDay[dayKey(day)] ?? 0) >= goodDayPercent) {
    streak++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return streak;
}

/// Longest run of good days in [days] (in order).
int bestStreak(Map<String, int> percentByDay, List<String> days) {
  var best = 0;
  var run = 0;
  for (final d in days) {
    run = (percentByDay[d] ?? 0) >= goodDayPercent ? run + 1 : 0;
    if (run > best) best = run;
  }
  return best;
}

/// Average daily % over [days] (missing days count as 0); 0 for no days.
int averagePercent(Map<String, int> percentByDay, List<String> days) {
  if (days.isEmpty) return 0;
  final sum = days.fold<int>(0, (s, d) => s + (percentByDay[d] ?? 0));
  return (sum / days.length).round();
}

/// For each daily goal, the % of [days] on which it was met.
Map<String, int> goalSuccessRates(
  List<DaySummary> summaries,
  List<GoalDef> dailyGoals,
  List<String> days,
) {
  if (days.isEmpty) return {for (final g in dailyGoals) g.id: 0};
  final byDay = {for (final s in summaries) s.date: s};
  return {
    for (final g in dailyGoals)
      g.id:
          (days
                      .where((d) => byDay[d]?.statuses[g.id] == GoalStatus.met)
                      .length *
                  100 /
                  days.length)
              .round(),
  };
}
