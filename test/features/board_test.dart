import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/core/dates.dart';
import 'package:goals_challenge/data/memory/memory_backend.dart';
import 'package:goals_challenge/domain/default_goals.dart';
import 'package:goals_challenge/features/board/board_providers.dart';
import 'package:goals_challenge/features/board/board_screen.dart';
import 'package:goals_challenge/features/photos/photo_viewer.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

Future<void> openBoard(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.grid_view_outlined));
  await tester.pumpAndSettle();
  expect(find.byType(BoardScreen), findsOneWidget);
}

String daysAgo(int n) {
  final t = parseDayKey(todayKey());
  return dayKey(DateTime(t.year, t.month, t.day - n));
}

void main() {
  test('ramp: empty for 0 %/no data, darker for more', () {
    expect(boardColor(null, Brightness.light), isNull);
    expect(boardColor(0, Brightness.light), isNull);
    expect(boardColor(10, Brightness.light), boardRampLight[0]);
    expect(boardColor(50, Brightness.light), boardRampLight[1]);
    expect(boardColor(99, Brightness.light), boardRampLight[3]);
    expect(boardColor(100, Brightness.light), boardRampLight[4]);
    expect(boardColor(100, Brightness.dark), boardRampDark[4]);
  });

  testWidgets('one card per member with stats and a heatmap', (tester) async {
    await pumpApp(tester, await signedInPairedBackend());
    await openBoard(tester);
    expect(find.byKey(const ValueKey('board-me')), findsOneWidget);
    expect(find.byKey(const ValueKey('board-demo-partner')), findsOneWidget);
    expect(find.text('Noa'), findsOneWidget);
    expect(find.text('Streak'), findsNWidgets(2));
    // Noa's seeded history colours past cells.
    expect(find.byKey(ValueKey('cell-${daysAgo(3)}')), findsWidgets);
  });

  testWidgets('my goals: success rates from my own days', (tester) async {
    final b = await signedInPairedBackend();
    final me = b.currentUser!.uid;
    final challenge = (await b.watchActiveChallenge('demo-pair').first)!;
    await b.setGoalValue(
      pairId: 'demo-pair',
      uid: me,
      date: daysAgo(1),
      goalId: GoalIds.water,
      value: 8,
      dailyGoals: challenge.dailyGoals,
    );
    await pumpApp(tester, b);
    await openBoard(tester);
    final rates = find.text('How often you met each goal');
    await tester.scrollUntilVisible(
      rates,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(rates, findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    final card = find.ancestor(of: rates, matching: find.byType(Card));
    // Water: met on 1 of the 20 finished days. Others: never.
    expect(
      find.descendant(of: card, matching: find.text('5%')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('0%')),
      findsNWidgets(8),
    );
  });

  testWidgets('tapping a day opens its photo diary', (tester) async {
    await pumpApp(tester, await signedInPairedBackend());
    await openBoard(tester);
    final cell = find.descendant(
      of: find.byKey(const ValueKey('board-me')),
      matching: find.byKey(ValueKey('cell-${daysAgo(1)}')),
    );
    await tester.ensureVisible(cell);
    await tester.pumpAndSettle();
    await tester.tap(cell);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('diary-demo-partner')), findsOneWidget);
    final photo = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey &&
          '${(w.key! as ValueKey).value}'.startsWith('diary-photo-'),
    );
    expect(photo, findsWidgets);
    await tester.tap(photo.first);
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewer), findsOneWidget);
  });

  testWidgets('a long challenge scrolls; no overflow at 360px in Hebrew', (
    tester,
  ) async {
    final b = MemoryBackend(seedDemo: true);
    final u = await b.signUp(
      email: 'me@x.com',
      password: 'secret1',
      displayName: 'Me',
      languageCode: 'he',
    );
    await b.createPair(
      uid: u.uid,
      displayName: 'Me',
      startDate: daysAgo(200),
      endDate: daysAgo(-165),
      goals: defaultGoals,
    );
    await pumpApp(tester, b, size: const Size(360, 780));
    await openBoard(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(ValueKey('cell-${todayKey()}')), findsOneWidget);
  });
}
