import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/core/dates.dart';
import 'package:goals_challenge/domain/default_goals.dart';
import 'package:goals_challenge/domain/models.dart';

void main() {
  group('todayKey applies the $dayStartHour:00 day start', () {
    test('03:59 is still the previous day, 04:00 is the new one', () {
      expect(todayKey(DateTime(2026, 5, 10, 3, 59, 59)), '2026-05-09');
      expect(todayKey(DateTime(2026, 5, 10, 4)), '2026-05-10');
      expect(todayKey(DateTime(2026, 5, 10, 0, 30)), '2026-05-09');
      expect(todayKey(DateTime(2026, 5, 10, 23, 59)), '2026-05-10');
    });

    test('crosses month, leap-day and year boundaries', () {
      expect(todayKey(DateTime(2026, 6, 1, 1)), '2026-05-31');
      expect(todayKey(DateTime(2028, 3, 1, 2)), '2028-02-29');
      expect(todayKey(DateTime(2027, 1, 1, 3)), '2026-12-31');
      expect(todayKey(DateTime(2027, 1, 1, 4)), '2027-01-01');
    });

    test('dayKey stays a pure calendar-date formatter', () {
      expect(dayKey(DateTime(2026, 5, 10, 0, 30)), '2026-05-10');
    });
  });

  test('nextDayStart is the next $dayStartHour:00 strictly after now', () {
    expect(nextDayStart(DateTime(2026, 5, 10, 1)), DateTime(2026, 5, 10, 4));
    expect(nextDayStart(DateTime(2026, 5, 10, 4)), DateTime(2026, 5, 11, 4));
    expect(nextDayStart(DateTime(2026, 12, 31, 22)), DateTime(2027, 1, 1, 4));
  });

  test('week helpers use calendar dates (unaffected by the day start)', () {
    // Sunday 2026-05-10, 00:30.
    final keys = weekDayKeys(DateTime(2026, 5, 10, 0, 30));
    expect(keys.first, '2026-05-10');
    expect(keys.last, '2026-05-16');
    expect(weekStart(DateTime(2026, 5, 16, 3)), DateTime(2026, 5, 10));
  });

  test('challengeProgress', () {
    const c = Challenge(
      id: 'c',
      pairId: 'p',
      startDate: '2026-03-01',
      endDate: '2026-03-31',
      goals: defaultGoals,
    );
    expect(
      challengeProgress(c, '2026-03-02'),
      const ChallengeDay(day: 2, total: 31),
    );
    expect(challengeProgress(c, '2026-03-02').inProgress, isTrue);
    expect(challengeProgress(c, '2026-02-28').inProgress, isFalse);
    expect(challengeProgress(c, '2026-04-01').inProgress, isFalse);
  });
}
