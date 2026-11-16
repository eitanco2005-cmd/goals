import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/core/dates.dart';
import 'package:goals_challenge/data/memory/memory_backend.dart';
import 'package:goals_challenge/domain/default_goals.dart';
import 'package:goals_challenge/domain/models.dart';
import 'package:goals_challenge/features/goals/goal_form_sheet.dart';
import 'package:goals_challenge/features/goals/goals_editor_screen.dart';
import 'package:goals_challenge/features/today/today_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

Future<void> openEditor(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pumpAndSettle();
  await scrollToCenter(tester, find.text('Edit goals'));
  await tester.tap(find.text('Edit goals'));
  await tester.pumpAndSettle();
  expect(find.byType(GoalsEditorScreen), findsOneWidget);
}

Future<Challenge> active(MemoryBackend b) async =>
    (await b.watchActiveChallenge('demo-pair').first)!;

Future<void> tapGoal(WidgetTester tester, String id) async {
  await scrollToCenter(tester, find.byKey(ValueKey('edit-$id')));
  await tester.tap(find.byKey(ValueKey('edit-$id')));
  await tester.pumpAndSettle();
}

/// Taps the Save button inside the goal form sheet (scrolling to it).
Future<void> saveSheet(WidgetTester tester) async {
  final save = find.text('Save').last;
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('change a target and save for the group', (tester) async {
    final b = await signedInPairedBackend();
    await pumpApp(tester, b);
    await openEditor(tester);
    expect(find.text('at least 8'), findsOneWidget);

    await tapGoal(tester, GoalIds.water);
    await tester.enterText(find.byKey(const ValueKey('goal-target')), '10');
    await saveSheet(tester);
    expect(find.text('at least 10'), findsOneWidget);

    await tester.tap(find.text('Save').first);
    await tester.pumpAndSettle();
    expect(find.byType(GoalsEditorScreen), findsNothing);
    expect(find.text('Goals updated for the group'), findsOneWidget);
    final water = (await active(b)).goals
        .firstWhere((g) => g.id == GoalIds.water);
    expect(water.target, 10);
  });

  testWidgets('add a custom yes/no goal; it shows up on Today', (tester) async {
    final b = await signedInPairedBackend();
    await pumpApp(tester, b);
    await openEditor(tester);
    await tester.tap(find.text('Add goal'));
    await tester.pumpAndSettle();
    expect(find.text('New goal'), findsOneWidget);

    // Name is required.
    await saveSheet(tester);
    expect(find.text('Give the goal a name'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('goal-name')), 'Meditate');
    await tester.tap(find.text('🧘'));
    await saveSheet(tester);
    expect(find.text('Meditate'), findsOneWidget);
    await tester.tap(find.text('Save').first);
    await tester.pumpAndSettle();

    final added = (await active(b)).goals.last;
    expect(added.titleEn, 'Meditate');
    expect(added.titleHe, 'Meditate');
    expect(added.type, GoalType.boolean);
    expect(added.icon, '🧘');

    await tester.tap(find.byIcon(Icons.today_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
    await scrollToCenter(tester, find.text('Meditate'));
    expect(find.text('Meditate'), findsOneWidget);
  });

  testWidgets('a number goal with a unit; small targets count +1/-1', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    await pumpApp(tester, b);
    await openEditor(tester);
    await tester.tap(find.text('Add goal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('goal-name')), 'Pages');
    await tester.tap(find.text('Number'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('goal-target')), '20');
    await tester.enterText(find.byKey(const ValueKey('goal-unit')), 'pages');
    await saveSheet(tester);
    await scrollToCenter(tester, find.text('at least 20 pages'));
    expect(find.text('at least 20 pages'), findsOneWidget);
    await tester.tap(find.text('Save').first);
    await tester.pumpAndSettle();

    final added = (await active(b)).goals.last;
    expect(added.type, GoalType.counter);
    expect(added.step, 1);
    expect(added.unitEn, 'pages');
    expect(added.unitHe, 'pages');

    await tester.tap(find.byIcon(Icons.today_outlined));
    await tester.pumpAndSettle();
    await scrollToCenter(tester, find.text('0 / 20 pages'));
    expect(find.text('0 / 20 pages'), findsOneWidget);
  });

  test('big number targets get typing and bigger steps', () {
    expect(numberStep(8), 1);
    expect(numberStep(250), 10);
    expect(numberStep(10000), 1000);
  });

  test('units survive a save and load', () {
    const g = GoalDef(
      id: 'x',
      titleHe: 'x',
      titleEn: 'x',
      type: GoalType.counter,
      comparison: Comparison.atLeast,
      target: 20,
      period: GoalPeriod.daily,
      icon: '📘',
      unitHe: 'עמודים',
      unitEn: 'pages',
    );
    final back = GoalDef.fromMap(g.toMap());
    expect(back.unit('he'), 'עמודים');
    expect(back.unit('en'), 'pages');
    expect(GoalDef.fromMap({...g.toMap()}..remove('unitEn')).unitEn, '');
  });

  testWidgets('a new weekly goal is a count', (tester) async {
    final b = await signedInPairedBackend();
    await pumpApp(tester, b);
    await openEditor(tester);
    await tester.tap(find.text('Add goal'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('goal-name')),
      'Family dinner',
    );
    await tester.tap(find.text('Weekly').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('goal-target')), '2');
    await saveSheet(tester);
    await scrollToCenter(tester, find.text('at least 2 a week'));
    expect(find.text('at least 2 a week'), findsOneWidget);
  });

  testWidgets('delete a goal; leaving unsaved asks first', (tester) async {
    final b = await signedInPairedBackend();
    await pumpApp(tester, b);
    await openEditor(tester);
    await tapGoal(tester, GoalIds.socialMedia);
    await tester.ensureVisible(find.text('Delete goal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete goal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete goal').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('edit-${GoalIds.socialMedia}')),
      findsNothing,
    );

    // Back with unsaved changes -> confirm; discarding keeps the old goals.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard your changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(GoalsEditorScreen), findsNothing);
    expect(
      (await active(b)).goals.any((g) => g.id == GoalIds.socialMedia),
      isTrue,
    );
  });

  testWidgets('workouts: edit the weekly requirements', (tester) async {
    final b = await signedInPairedBackend();
    await pumpApp(tester, b);
    await openEditor(tester);
    await tapGoal(tester, GoalIds.workouts);
    expect(find.text('Workouts per week'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('goal-target')), '4');
    await saveSheet(tester);
    await tester.tap(find.text('Save').first);
    await tester.pumpAndSettle();
    final w = (await active(b)).goals
        .firstWhere((g) => g.id == GoalIds.workouts);
    expect(w.target, 4);
    expect(w.type, GoalType.workouts);
    expect(w.requirements, {'run': 1, 'strength': 2, 'minMinutes': 30});
  });

  testWidgets('start a new round with the same goals', (tester) async {
    final b = await signedInPairedBackend();
    final before = await active(b);
    await pumpApp(tester, b);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await scrollToCenter(tester, find.text('Start a new round'));
    await tester.tap(find.text('Start a new round'));
    await tester.pumpAndSettle();
    expect(find.byType(NewRoundScreen), findsOneWidget);
    await scrollToCenter(tester, find.text('Start the round'));
    await tester.tap(find.text('Start the round'));
    await tester.pumpAndSettle();

    expect(find.byType(NewRoundScreen), findsNothing);
    expect(find.text('A new round started'), findsOneWidget);
    final after = await active(b);
    expect(after.id, isNot(before.id));
    expect(after.goals.map((g) => g.id), before.goals.map((g) => g.id));
    // It replaces the current round from today.
    expect(after.startDate, todayKey());
  });
}
