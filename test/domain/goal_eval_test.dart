import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/domain/default_goals.dart';
import 'package:goals_challenge/domain/goal_eval.dart';
import 'package:goals_challenge/domain/models.dart';

GoalDef goal(String id) => defaultGoals.firstWhere((g) => g.id == id);

void main() {
  group('evaluateGoal', () {
    test('unlogged when value is null', () {
      expect(evaluateGoal(goal(GoalIds.water), null), GoalStatus.unlogged);
    });
    test('atLeast', () {
      expect(evaluateGoal(goal(GoalIds.water), 7), GoalStatus.notMet);
      expect(evaluateGoal(goal(GoalIds.water), 8), GoalStatus.met);
      expect(evaluateGoal(goal(GoalIds.steps), 12000), GoalStatus.met);
    });
    test('atMost', () {
      expect(evaluateGoal(goal(GoalIds.sweets), 0), GoalStatus.met);
      expect(evaluateGoal(goal(GoalIds.sweets), 1), GoalStatus.met);
      expect(evaluateGoal(goal(GoalIds.sweets), 2), GoalStatus.notMet);
      expect(evaluateGoal(goal(GoalIds.socialMedia), 75), GoalStatus.notMet);
    });
    test('exactly', () {
      expect(evaluateGoal(goal(GoalIds.meals), 3), GoalStatus.met);
      expect(evaluateGoal(goal(GoalIds.meals), 4), GoalStatus.notMet);
    });
    test('boolean', () {
      expect(evaluateGoal(goal(GoalIds.veggies), 1), GoalStatus.met);
      expect(evaluateGoal(goal(GoalIds.veggies), 0), GoalStatus.notMet);
    });
  });

  test('summarizeDay computes percent over daily goals', () {
    final daily = defaultGoals
        .where((g) => g.period == GoalPeriod.daily)
        .toList();
    expect(daily, hasLength(9));
    final log = DailyLog(
      uid: 'u',
      date: '2026-11-15',
      values: {GoalIds.water: 8, GoalIds.steps: 10000, GoalIds.sweets: 3},
    );
    final s = summarizeDay(log, daily);
    expect(s.percent, 22); // 2 of 9
    expect(s.statuses[GoalIds.sweets], GoalStatus.notMet);
    expect(s.statuses[GoalIds.reading], GoalStatus.unlogged);
    expect(unloggedGoals(log, daily), hasLength(6));
  });

  group('evaluateWorkouts', () {
    final g = goal(GoalIds.workouts);
    WorkoutEntry w(WorkoutType t, int m) =>
        WorkoutEntry(id: '', uid: 'u', date: '2026-11-15', type: t, minutes: m);

    test('needs 1 run + 2 strength of >= 30 min', () {
      expect(evaluateWorkouts(g, []), GoalStatus.unlogged);
      expect(
        evaluateWorkouts(g, [
          w(WorkoutType.run, 30),
          w(WorkoutType.strength, 45),
          w(WorkoutType.strength, 30),
        ]),
        GoalStatus.met,
      );
      expect(
        evaluateWorkouts(g, [
          w(WorkoutType.strength, 30),
          w(WorkoutType.strength, 30),
          w(WorkoutType.strength, 30),
        ]),
        GoalStatus.notMet,
      );
    });
    test('short workouts do not count', () {
      expect(
        evaluateWorkouts(g, [
          w(WorkoutType.run, 20),
          w(WorkoutType.strength, 45),
          w(WorkoutType.strength, 30),
        ]),
        GoalStatus.notMet,
      );
    });
  });
}
