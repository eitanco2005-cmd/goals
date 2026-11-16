import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/data/memory/memory_backend.dart';
import 'package:goals_challenge/domain/default_goals.dart';
import 'package:goals_challenge/domain/goal_eval.dart';
import 'package:goals_challenge/domain/models.dart';
import 'package:goals_challenge/features/week/week_providers.dart';
import 'package:goals_challenge/features/week/week_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

final weekly = defaultGoals
    .where((g) => g.period == GoalPeriod.weekly)
    .toList();

WorkoutEntry w(WorkoutType t, int minutes) => WorkoutEntry(
  id: '',
  uid: 'u',
  date: '2026-11-16',
  type: t,
  minutes: minutes,
);

Future<void> openWeek(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.view_week_outlined));
  await tester.pumpAndSettle();
  expect(find.byType(WeekScreen), findsOneWidget);
}

Future<List<WeekSummary>> published(MemoryBackend b) => b
    .watchWeekSummaries(pairId: 'demo-pair', weekStart: currentWeekStart())
    .first;

void main() {
  group('summarizeWeek', () {
    test('workouts from entries, junk food from daily totals', () {
      final s = summarizeWeek(
        uid: 'u',
        weekStart: '2026-11-15',
        weeklyGoals: weekly,
        workouts: [
          w(WorkoutType.run, 30),
          w(WorkoutType.strength, 45),
          w(WorkoutType.strength, 30),
        ],
        totals: {GoalIds.junkFood: 2},
      );
      expect(s.statuses[GoalIds.workouts], GoalStatus.met);
      expect(s.statuses[GoalIds.junkFood], GoalStatus.notMet);
    });

    test('nothing logged: workouts unlogged, a limit is on track', () {
      final s = summarizeWeek(
        uid: 'u',
        weekStart: '2026-11-15',
        weeklyGoals: weekly,
        workouts: const [],
        totals: const {},
      );
      expect(s.statuses[GoalIds.workouts], GoalStatus.unlogged);
      expect(s.statuses[GoalIds.junkFood], GoalStatus.met);
    });

    test('sumLogs adds values across days', () {
      final totals = sumLogs([
        DailyLog(
          uid: 'u',
          date: 'a',
          values: {GoalIds.junkFood: 1, GoalIds.water: 3},
        ),
        DailyLog(uid: 'u', date: 'b', values: {GoalIds.junkFood: 1}),
      ]);
      expect(totals, {GoalIds.junkFood: 2, GoalIds.water: 3});
    });
  });

  testWidgets('add a run, see it count, and the group sees only the status', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    final me = b.currentUser!.uid;
    await pumpApp(tester, b);
    await openWeek(tester);
    expect(find.text('No workouts logged this week'), findsOneWidget);

    await tester.tap(find.text('Add workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🏃 Run'));
    await tester.tap(find.text('45 min'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Run · 45 min'), findsOneWidget);
    expect(find.textContaining('1/3'), findsOneWidget);

    // Published for the group after the debounce: statuses only.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final mine = (await published(b)).singleWhere((s) => s.uid == me);
    expect(mine.statuses[GoalIds.workouts], GoalStatus.notMet);
    expect(mine.statuses[GoalIds.junkFood], GoalStatus.met);
  });

  testWidgets('a too-short workout is shown but does not count', (
    tester,
  ) async {
    await pumpApp(tester, await signedInPairedBackend());
    await openWeek(tester);
    await tester.tap(find.text('Add workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20 min'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining("Under 30 min – doesn't count"), findsOneWidget);
    expect(find.textContaining('0/3'), findsOneWidget);
  });

  testWidgets('deleting a workout can be undone', (tester) async {
    await pumpApp(tester, await signedInPairedBackend());
    await openWeek(tester);
    await tester.tap(find.text('Add workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete workout'));
    await tester.pumpAndSettle();
    expect(find.text('No workouts logged this week'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Run · 30 min'), findsOneWidget);
  });

  testWidgets('junk food: one is fine, two breaks the weekly limit', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    final me = b.currentUser!.uid;
    await pumpApp(tester, b);
    await openWeek(tester);
    final plus = find.byTooltip('Increase Junk food max once a week');
    await tester.ensureVisible(plus);
    await tester.tap(plus);
    await tester.pumpAndSettle();
    expect(find.textContaining('1 this week · max 1'), findsOneWidget);
    await tester.tap(plus);
    await tester.pumpAndSettle();
    expect(find.textContaining('2 this week · max 1'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final mine = (await published(b)).singleWhere((s) => s.uid == me);
    expect(mine.statuses[GoalIds.junkFood], GoalStatus.notMet);
  });

  testWidgets('the group card lists the others with their statuses', (
    tester,
  ) async {
    await pumpApp(tester, await signedInPairedBackend());
    await openWeek(tester);
    final row = find.byKey(const ValueKey('week-member-demo-partner'));
    await tester.ensureVisible(row);
    expect(
      find.descendant(of: row, matching: find.text('Noa')),
      findsOneWidget,
    );
  });

  testWidgets('can browse back a week but not into the future', (tester) async {
    await pumpApp(tester, await signedInPairedBackend());
    await openWeek(tester);
    final next = find.byTooltip('Next week');
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_right),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Previous week'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Week of'), findsOneWidget);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('This week'), findsWidgets);
  });

  testWidgets('no overflow at 360px in Hebrew', (tester) async {
    await pumpApp(
      tester,
      await signedInPairedBackend(languageCode: 'he'),
      size: const Size(360, 780),
    );
    await openWeek(tester);
    expect(tester.takeException(), isNull);
  });
}
