import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/domain/board_stats.dart';
import 'package:goals_challenge/domain/default_goals.dart';
import 'package:goals_challenge/domain/models.dart';

void main() {
  final days = ['2026-11-10', '2026-11-11', '2026-11-12', '2026-11-13'];

  group('currentStreak', () {
    test('counts good days ending today', () {
      expect(
        currentStreak({
          '2026-11-11': 70,
          '2026-11-12': 100,
          '2026-11-13': 80,
        }, '2026-11-13'),
        3,
      );
    });
    test('an unfinished today does not break it', () {
      expect(
        currentStreak({
          '2026-11-11': 90,
          '2026-11-12': 90,
          '2026-11-13': 10,
        }, '2026-11-13'),
        2,
      );
    });
    test('a bad or missing day breaks it', () {
      expect(
        currentStreak({'2026-11-11': 90, '2026-11-13': 90}, '2026-11-13'),
        1,
      );
      expect(currentStreak(const {}, '2026-11-13'), 0);
    });
    test('works across month boundaries', () {
      expect(
        currentStreak({'2026-10-31': 80, '2026-11-01': 80}, '2026-11-01'),
        2,
      );
    });
  });

  test('bestStreak finds the longest run', () {
    expect(
      bestStreak({'2026-11-10': 80, '2026-11-12': 80, '2026-11-13': 90}, days),
      2,
    );
  });

  test('averagePercent counts missing days as 0', () {
    expect(averagePercent({'2026-11-10': 100, '2026-11-11': 60}, days), 40);
    expect(averagePercent(const {}, const []), 0);
  });

  test('goalSuccessRates per goal', () {
    final daily = defaultGoals
        .where((g) => g.period == GoalPeriod.daily)
        .toList();
    DaySummary s(String date, Map<String, GoalStatus> st) =>
        DaySummary(uid: 'u', date: date, statuses: st, percent: 0);
    final rates = goalSuccessRates(
      [
        s('2026-11-10', {GoalIds.water: GoalStatus.met}),
        s('2026-11-11', {
          GoalIds.water: GoalStatus.met,
          GoalIds.reading: GoalStatus.notMet,
        }),
      ],
      daily,
      days,
    );
    expect(rates[GoalIds.water], 50);
    expect(rates[GoalIds.reading], 0);
    expect(rates.keys, hasLength(9));
  });
}
