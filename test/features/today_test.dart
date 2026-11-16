import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/app.dart';
import 'package:goals_challenge/core/dates.dart';
import 'package:goals_challenge/core/providers.dart';
import 'package:goals_challenge/data/memory/memory_backend.dart';
import 'package:goals_challenge/data/repositories.dart';
import 'package:goals_challenge/domain/default_goals.dart';
import 'package:goals_challenge/domain/models.dart';
import 'package:goals_challenge/features/pairing/invite_code_card.dart';
import 'package:goals_challenge/features/photos/photo_thumbnails.dart';
import 'package:goals_challenge/features/today/partner_strip.dart';
import 'package:goals_challenge/features/today/today_header.dart';
import 'package:goals_challenge/features/today/today_providers.dart';
import 'package:image/image.dart' as img;
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

/// Writes resolve only when completed by the test, and the log stream only
/// emits what the test pushes (it never echoes writes back by itself).
class _NoEchoLogs implements LogRepository {
  final writes = <Completer<void>>[];
  final logs = StreamController<DailyLog>();

  @override
  Stream<DailyLog> watchDailyLog({
    required String pairId,
    required String uid,
    required String date,
  }) => logs.stream;

  @override
  Future<void> setGoalValue({
    required String pairId,
    required String uid,
    required String date,
    required String goalId,
    required num? value,
    required List<GoalDef> dailyGoals,
  }) {
    final c = Completer<void>();
    writes.add(c);
    return c.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _emptyLog = DailyLog(uid: 'u', date: '2026-05-10');

void main() {
  group('TodayLogController', () {
    late _NoEchoLogs logs;
    late ProviderContainer container;

    tearDown(() => logs.logs.close());

    setUp(() async {
      logs = _NoEchoLogs();
      container = ProviderContainer.test(
        overrides: [
          logRepositoryProvider.overrideWithValue(logs),
          todayScopeProvider.overrideWithValue((
            pairId: 'p',
            uid: 'u',
            date: '2026-05-10',
          )),
          challengeProvider.overrideWith(
            (ref) => Stream.value(
              const Challenge(
                id: 'c',
                pairId: 'p',
                startDate: '2026-05-01',
                endDate: '2026-07-29',
                goals: defaultGoals,
              ),
            ),
          ),
        ],
      );
      container
        ..listen(todayLogProvider, (_, _) {})
        ..listen(challengeProvider, (_, _) {});
      await container.read(challengeProvider.future);
      logs.logs.add(_emptyLog);
      await container.read(myTodayLogStreamProvider.future);
    });

    Map<String, num?> pending() => container.read(todayLogControllerProvider);
    TodayLogController controller() =>
        container.read(todayLogControllerProvider.notifier);

    num? shown() =>
        container.read(todayLogProvider).value!.valueOf(GoalIds.water);

    test('a saved value never masks later updates from the stream', () async {
      final write = controller().setValue(GoalIds.water, 3);
      expect(pending(), {GoalIds.water: 3});
      expect(shown(), 3);

      // Saved, but the stream has not caught up yet: keep showing it.
      logs.writes.single.complete();
      await write;
      expect(shown(), 3);

      // Whatever the stream says next wins (e.g. another device's update).
      logs.logs.add(_emptyLog.withValue(GoalIds.water, 5));
      await pumpEventQueue();
      expect(pending(), isEmpty);
      expect(shown(), 5);
    });

    test('a failed write drops its optimistic value right away', () async {
      final write = controller().setValue(GoalIds.water, 3);
      logs.writes.single.completeError(const AppException('network'));
      await expectLater(write, throwsA(isA<AppException>()));
      expect(pending(), isEmpty);
      expect(shown(), isNull);
    });

    test('an older write settling keeps the newer pending value', () async {
      final first = controller().setValue(GoalIds.water, 1);
      final second = controller().setValue(GoalIds.water, 2);
      logs.writes.first.complete();
      await first;
      // The echo of the older write doesn't drop the newer value either.
      logs.logs.add(_emptyLog.withValue(GoalIds.water, 1));
      await pumpEventQueue();
      expect(pending(), {GoalIds.water: 2});

      logs.writes.last.completeError(const AppException('network'));
      await expectLater(second, throwsA(isA<AppException>()));
      expect(pending(), isEmpty);
      expect(shown(), 1);
    });
  });

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

  testWidgets('− at 0 clears a mistaken "None today", and Undo restores it', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    await pumpApp(tester, b, size: _tall);
    const id = GoalIds.sweets;
    final semantics = tester.ensureSemantics();

    await tester.tap(_inCard(id, find.text('None today ✓')));
    await tester.pumpAndSettle();
    expect(_inCard(id, find.text('Done')), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'Max one sweet/snack: 0$')),
      findsOneWidget,
    );
    semantics.dispose();

    await tester.tap(find.byTooltip('Decrease Max one sweet/snack'));
    await tester.pumpAndSettle();
    expect(_inCard(id, find.text('Not logged')), findsOneWidget);
    expect(_inCard(id, find.text('None today ✓')), findsOneWidget);
    expect((await _mySummary(b))!.statuses[id], GoalStatus.unlogged);
    expect(find.text('Max one sweet/snack cleared'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(_inCard(id, find.text('Done')), findsOneWidget);
    expect((await _mySummary(b))!.statuses[id], GoalStatus.met);
  });

  testWidgets('partner goal dots fit on one row at 390px', (tester) async {
    final b = await signedInPairedBackend(languageCode: 'he');
    await pumpApp(tester, b, size: const Size(390, 3200));
    final dots = find.byType(PartnerGoalDot);
    expect(dots, findsNWidgets(9));
    final top = tester.getTopLeft(dots.first).dy;
    for (final e in dots.evaluate()) {
      expect(tester.getTopLeft(find.byWidget(e.widget)).dy, top);
      expect(
        tester.getSize(find.byWidget(e.widget)).width,
        greaterThanOrEqualTo(PartnerGoalDot.minSize),
      );
    }
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

  testWidgets('a write rejected later shows a localized snackbar', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    final errors = StreamController<AppException>.broadcast();
    addTearDown(errors.close);
    tester.view.physicalSize = _tall;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...memoryOverrides(b),
          logWriteErrorsProvider.overrideWith((ref) => errors.stream),
        ],
        child: const GoalsApp(),
      ),
    );
    await tester.pumpAndSettle();

    errors.add(const AppException('network'));
    await tester.pumpAndSettle();
    expect(
      find.text('No connection. Check your internet and try again'),
      findsOneWidget,
    );
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

  for (final lang in ['he', 'en']) {
    testWidgets('renders photos without overflow at 360px in $lang', (
      tester,
    ) async {
      final b = await signedInPairedBackend(languageCode: lang);
      final jpeg = img.encodeJpg(img.Image(width: 40, height: 30));
      Future<void> add(String uid, String goalId) => b.addPhoto(
        pairId: 'demo-pair',
        uid: uid,
        date: todayKey(),
        goalId: goalId,
        fullJpeg: jpeg,
        thumbnailJpeg: jpeg,
        width: 40,
        height: 30,
      );
      // Many of mine on the tightest cards, plus plenty of Noa's.
      for (final goalId in [GoalIds.sweets, GoalIds.steps, GoalIds.veggies]) {
        for (var i = 0; i < 6; i++) {
          await add(b.currentUser!.uid, goalId);
        }
      }
      for (var i = 0; i < 8; i++) {
        await add('demo-partner', GoalIds.water);
      }
      await pumpApp(tester, b, size: const Size(360, 3600));
      expect(tester.takeException(), isNull);
      expect(
        _inCard(GoalIds.sweets, find.byType(PhotoThumbnail)),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: find.byType(PartnerStrip),
          matching: find.byType(PhotoThumbnail),
        ),
        findsWidgets,
      );
    });
  }

  testWidgets('solo user in Hebrew at 360px does not overflow', (tester) async {
    final b = await signedInSoloBackend(languageCode: 'he');
    await pumpApp(tester, b, size: const Size(360, 3400));
    expect(tester.takeException(), isNull);
    expect(find.text('מחכים לבן/בת הזוג'), findsOneWidget);
  });
}
