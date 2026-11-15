import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/app.dart';
import 'package:goals_challenge/core/dates.dart';
import 'package:goals_challenge/data/memory/memory_backend.dart';
import 'package:goals_challenge/domain/default_goals.dart';
import 'package:goals_challenge/domain/models.dart';
import 'package:goals_challenge/features/pairing/invite_code_card.dart';
import 'package:goals_challenge/features/today/today_header.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

/// Tall enough that every card of the list is built.
const _tall = Size(400, 3200);

final _dailyGoals = defaultGoals
    .where((g) => g.period == GoalPeriod.daily)
    .toList();

Finder _inCard(String goalId, Finder matching) => find.descendant(
  of: find.byKey(ValueKey('goal-$goalId')),
  matching: matching,
);

Finder _inHeader(Finder matching) =>
    find.descendant(of: find.byType(TodayHeader), matching: matching);

Future<DaySummary?> _mySummary(MemoryBackend b) => b
    .watchDaySummary(
      pairId: 'demo-pair',
      uid: b.currentUser!.uid,
      date: todayKey(),
    )
    .first;

void main() {
  testWidgets('paired user sees all daily goals and the partner strip', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    await pumpApp(tester, b, size: _tall);

    for (final g in _dailyGoals) {
      expect(find.byKey(ValueKey('goal-${g.id}')), findsOneWidget);
      expect(find.text(g.titleEn), findsOneWidget);
    }
    expect(find.text('Noa'), findsOneWidget);
    expect(find.text('Waiting for your partner'), findsNothing);
    expect(_inHeader(find.text('0%')), findsOneWidget);
    expect(_inHeader(find.text('0 of 9 goals done')), findsOneWidget);
    expect(_inHeader(find.text('Day 21 of 90')), findsOneWidget);
    // Weekly teaser.
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('3 workouts a week'), findsOneWidget);
    // Everything starts unlogged.
    expect(find.text('Not logged'), findsNWidgets(9));
  });

  testWidgets('tapping + on water updates value, summary and the ring', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    await pumpApp(tester, b, size: _tall);

    final plus = find.byTooltip('Increase 8 glasses of water');
    await tester.tap(plus);
    await tester.pumpAndSettle();
    expect(_inCard(GoalIds.water, find.text('1')), findsOneWidget);
    expect(_inCard(GoalIds.water, find.text('1 / 8')), findsOneWidget);
    expect(_inCard(GoalIds.water, find.text('Not yet')), findsOneWidget);
    expect((await _mySummary(b))!.statuses[GoalIds.water], GoalStatus.notMet);

    for (var i = 0; i < 7; i++) {
      await tester.tap(plus);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(_inCard(GoalIds.water, find.text('8 / 8')), findsOneWidget);
    expect(_inCard(GoalIds.water, find.text('Done')), findsOneWidget);
    expect(_inHeader(find.text('11%')), findsOneWidget);
    expect(_inHeader(find.text('1 of 9 goals done')), findsOneWidget);
    final summary = (await _mySummary(b))!;
    expect(summary.percent, 11);
    expect(summary.statuses[GoalIds.water], GoalStatus.met);

    await tester.tap(find.byTooltip('Decrease 8 glasses of water'));
    await tester.pumpAndSettle();
    expect(_inCard(GoalIds.water, find.text('7 / 8')), findsOneWidget);
    expect(_inHeader(find.text('0%')), findsOneWidget);
  });

  testWidgets('boolean goal: kept / didn\'t / tap again to clear', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    await pumpApp(tester, b, size: _tall);
    const id = GoalIds.noSugaryDrinks;

    await tester.tap(_inCard(id, find.text('Kept it ✓')));
    await tester.pumpAndSettle();
    expect(_inCard(id, find.text('Done')), findsOneWidget);
    expect((await _mySummary(b))!.statuses[id], GoalStatus.met);

    await tester.tap(_inCard(id, find.text("Didn't")));
    await tester.pumpAndSettle();
    expect(_inCard(id, find.text('Not yet')), findsOneWidget);

    await tester.tap(_inCard(id, find.text("Didn't")));
    await tester.pumpAndSettle();
    expect(_inCard(id, find.text('Not logged')), findsOneWidget);
    expect((await _mySummary(b))!.statuses[id], GoalStatus.unlogged);
  });

  testWidgets('sweets "None today" sets 0 and counts as met', (tester) async {
    final b = await signedInPairedBackend();
    await pumpApp(tester, b, size: _tall);
    const id = GoalIds.sweets;

    // Only limit goals offer it.
    expect(find.text('None today ✓'), findsOneWidget);
    await tester.tap(_inCard(id, find.text('None today ✓')));
    await tester.pumpAndSettle();
    expect(_inCard(id, find.text('0')), findsOneWidget);
    expect(_inCard(id, find.text('Done')), findsOneWidget);
    expect(find.text('None today ✓'), findsNothing);
    expect((await _mySummary(b))!.statuses[id], GoalStatus.met);
  });

  testWidgets('steps: quick +1000 and precise entry dialog', (tester) async {
    final b = await signedInPairedBackend();
    await pumpApp(tester, b, size: _tall);
    const id = GoalIds.steps;

    await tester.tap(find.byTooltip('Increase 10,000 steps'));
    await tester.pumpAndSettle();
    expect(_inCard(id, find.text('1,000 / 10,000 steps')), findsOneWidget);

    await tester.tap(_inCard(id, find.text('1,000')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '12345');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(_inCard(id, find.text('12,345 / 10,000 steps')), findsOneWidget);
    expect(_inCard(id, find.text('Done')), findsOneWidget);
  });

  testWidgets('reaching 100% shows the celebration', (tester) async {
    final b = await signedInPairedBackend();
    final uid = b.currentUser!.uid;
    const values = {
      GoalIds.water: 8,
      GoalIds.steps: 10000,
      GoalIds.noSugaryDrinks: 1,
      GoalIds.veggies: 1,
      GoalIds.meals: 3,
      GoalIds.noMorningSugar: 1,
      GoalIds.socialMedia: 30,
      GoalIds.reading: 60,
    };
    for (final e in values.entries) {
      await b.setGoalValue(
        pairId: 'demo-pair',
        uid: uid,
        date: todayKey(),
        goalId: e.key,
        value: e.value,
        dailyGoals: _dailyGoals,
      );
    }
    await pumpApp(tester, b, size: _tall);
    expect(_inHeader(find.text('89%')), findsOneWidget);

    await tester.tap(_inCard(GoalIds.sweets, find.text('None today ✓')));
    await tester.pumpAndSettle();
    expect(_inHeader(find.text('100%')), findsOneWidget);
    expect(find.text("All of today's goals are done! 🎉"), findsOneWidget);
  });

  testWidgets('solo user sees waiting-for-partner card with invite code', (
    tester,
  ) async {
    final b = await signedInSoloBackend();
    await pumpApp(tester, b, size: _tall);

    expect(find.text('Waiting for your partner'), findsOneWidget);
    final card = tester.widget<InviteCodeCard>(find.byType(InviteCodeCard));
    expect(card.code, hasLength(6));
    expect(find.text('Noa'), findsNothing);
  });

  testWidgets('demo banner is shown and can be dismissed', (tester) async {
    final b = await signedInPairedBackend();
    tester.view.physicalSize = _tall;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: memoryOverrides(b, demo: true),
        child: const GoalsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining(MemoryBackend.demoInviteCode), findsOneWidget);
    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.textContaining(MemoryBackend.demoInviteCode), findsNothing);
  });

  for (final lang in ['he', 'en']) {
    testWidgets('renders without overflow at 360px in $lang', (tester) async {
      final b = await signedInPairedBackend(languageCode: lang);
      await pumpApp(tester, b, size: const Size(360, 3400));
      expect(tester.takeException(), isNull);

      final expectedDir = lang == 'he' ? TextDirection.rtl : TextDirection.ltr;
      expect(
        Directionality.of(
          tester.element(find.byKey(ValueKey('goal-${GoalIds.water}'))),
        ),
        expectedDir,
      );
      for (final g in _dailyGoals) {
        expect(find.text(g.title(lang)), findsOneWidget);
      }
      // Exercise logged states too (pills, badges, chips change width).
      await tester.tap(
        _inCard(
          GoalIds.sweets,
          find.text(lang == 'he' ? 'כלום היום ✓' : 'None today ✓'),
        ),
      );
      await tester.tap(
        _inCard(
          GoalIds.veggies,
          find.text(lang == 'he' ? 'לא הפעם' : "Didn't"),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('solo user in Hebrew at 360px does not overflow', (tester) async {
    final b = await signedInSoloBackend(languageCode: 'he');
    await pumpApp(tester, b, size: const Size(360, 3400));
    expect(tester.takeException(), isNull);
    expect(find.text('מחכים לבן/בת הזוג'), findsOneWidget);
  });
}
