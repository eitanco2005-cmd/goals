import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/core/status_ui.dart';
import 'package:goals_challenge/domain/board_stats.dart';
import 'package:goals_challenge/domain/default_goals.dart';
import 'package:goals_challenge/domain/goal_eval.dart';
import 'package:goals_challenge/domain/models.dart';
import 'package:goals_challenge/features/goals/goals_editor_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

GoalDef goal(String id) => defaultGoals.firstWhere((g) => g.id == id);

void main() {
  group('failed vs not yet', () {
    test('a broken limit is failed', () {
      expect(isFailure(goal(GoalIds.socialMedia), 75), isTrue);
      expect(isFailure(goal(GoalIds.sweets), 2), isTrue);
      expect(isFailure(goal(GoalIds.junkFood), null), isTrue);
    });
    test('a "no" on a yes/no rule is failed', () {
      expect(isFailure(goal(GoalIds.noMorningSugar), 0), isTrue);
      expect(isFailure(goal(GoalIds.noSugaryDrinks), null), isTrue);
    });
    test('short of a minimum is only "not yet"', () {
      expect(isFailure(goal(GoalIds.water), 5), isFalse);
      expect(isFailure(goal(GoalIds.reading), 30), isFalse);
      expect(isFailure(goal(GoalIds.workouts), null), isFalse);
    });
    test('"exactly": over is failed, under is not yet', () {
      expect(isFailure(goal(GoalIds.meals), 4), isTrue);
      expect(isFailure(goal(GoalIds.meals), 2), isFalse);
      expect(isFailure(goal(GoalIds.meals), null), isFalse);
    });
    test('a yes/no goal waiting for its photo is not failed', () {
      final g = goal(GoalIds.veggies).copyWith(requiresPhoto: true);
      expect(isFailure(g, null), isFalse);
      expect(isFailure(g, 0), isTrue);
    });
    test('a weekly limit reads "on track" while the week runs', () {
      final junk = goal(GoalIds.junkFood);
      expect(
        goalOutcome(junk, GoalStatus.met, periodOpen: true),
        GoalOutcome.onTrack,
      );
      expect(goalOutcome(junk, GoalStatus.met), GoalOutcome.met);
      expect(
        goalOutcome(goal(GoalIds.workouts), GoalStatus.met, periodOpen: true),
        GoalOutcome.met,
      );
    });
    test('workouts: on pace mid-week reads "on track"', () {
      final w = goal(GoalIds.workouts);
      WorkoutEntry e(int min) => WorkoutEntry(
        id: 'e$min',
        uid: 'u',
        date: '2026-11-16',
        type: WorkoutType.run,
        minutes: min,
      );
      // 3 a week: none needed through Tuesday, 1 by Wednesday, 2 by Friday.
      expect(workoutsOnPace(w, const [], 2), isTrue);
      expect(workoutsOnPace(w, const [], 3), isFalse);
      expect(workoutsOnPace(w, [e(40)], 3), isTrue);
      expect(workoutsOnPace(w, [e(40)], 5), isFalse);
      expect(workoutsOnPace(w, [e(10)], 3), isFalse); // too short to count
      expect(
        goalOutcome(w, GoalStatus.notMet, periodOpen: true, onPace: true),
        GoalOutcome.onTrack,
      );
      expect(
        goalOutcome(w, GoalStatus.notMet, periodOpen: true),
        GoalOutcome.notYet,
      );
      expect(
        goalOutcome(w, GoalStatus.notMet, onPace: true),
        GoalOutcome.notYet,
      );
    });
    test('board stats start at the first logged day', () {
      const days = ['2026-11-13', '2026-11-14', '2026-11-15', '2026-11-16'];
      final s = [
        DaySummary(uid: 'u', date: '2026-11-15', statuses: {}, percent: 50),
      ];
      expect(daysSinceFirstLog(s, days), ['2026-11-15', '2026-11-16']);
      expect(daysSinceFirstLog(const [], days), isEmpty);
    });
    test('outcomes', () {
      expect(
        goalOutcome(goal(GoalIds.water), GoalStatus.notMet, value: 3),
        GoalOutcome.notYet,
      );
      expect(
        goalOutcome(goal(GoalIds.socialMedia), GoalStatus.notMet, value: 90),
        GoalOutcome.failed,
      );
      expect(goalOutcome(goal(GoalIds.water), GoalStatus.met), GoalOutcome.met);
    });
  });

  testWidgets('swiping a goal deletes it, and Undo brings it back', (
    tester,
  ) async {
    await pumpApp(tester, await signedInPairedBackend());
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await scrollToCenter(tester, find.text('Edit goals'));
    await tester.tap(find.text('Edit goals'));
    await tester.pumpAndSettle();
    expect(find.byType(GoalsEditorScreen), findsOneWidget);

    final tile = find.byKey(const ValueKey('dismiss-${GoalIds.reading}'));
    await scrollToCenter(tester, tile);
    await tester.drag(tile, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(tile, findsNothing);
    expect(find.text('"At least 1 hour reading" deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('edit-${GoalIds.reading}')),
      findsOneWidget,
    );
  });
}
