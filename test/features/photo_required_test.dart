import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/core/dates.dart';
import 'package:goals_challenge/data/memory/memory_backend.dart';
import 'package:goals_challenge/domain/default_goals.dart';
import 'package:goals_challenge/domain/goal_eval.dart';
import 'package:goals_challenge/domain/models.dart';
import 'package:goals_challenge/features/goals/goals_editor_screen.dart';
import 'package:goals_challenge/features/photos/photo_processing.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

final daily = [
  for (final g in defaultGoals)
    if (g.period == GoalPeriod.daily)
      g.id == GoalIds.veggies ? g.copyWith(requiresPhoto: true) : g,
];

/// Makes veggies require a photo in the demo challenge.
Future<void> requirePhotoForVeggies(MemoryBackend b) async {
  final c = (await b.watchActiveChallenge('demo-pair').first)!;
  await b.updateGoals(
    pairId: 'demo-pair',
    challengeId: c.id,
    goals: [
      for (final g in c.goals)
        g.id == GoalIds.veggies ? g.copyWith(requiresPhoto: true) : g,
    ],
  );
}

Future<DaySummary?> mySummary(MemoryBackend b) => b
    .watchDaySummary(
      pairId: 'demo-pair',
      uid: b.currentUser!.uid,
      date: todayKey(),
    )
    .first;

void main() {
  group('scoring', () {
    final log = DailyLog(
      uid: 'u',
      date: '2026-11-16',
      values: {GoalIds.veggies: 1, GoalIds.water: 8},
    );

    test('a photo-required goal counts only with a photo', () {
      expect(
        summarizeDay(log, daily).statuses[GoalIds.veggies],
        GoalStatus.notMet,
      );
      final withPhoto = summarizeDay(
        log,
        daily,
        photoGoalIds: {GoalIds.veggies},
      );
      expect(withPhoto.statuses[GoalIds.veggies], GoalStatus.met);
      expect(withPhoto.percent, 22); // veggies + water of 9
      expect(summarizeDay(log, daily).percent, 11);
    });

    test('a photo alone does not complete it', () {
      final empty = DailyLog(uid: 'u', date: '2026-11-16');
      expect(
        summarizeDay(
          empty,
          daily,
          photoGoalIds: {GoalIds.veggies},
        ).statuses[GoalIds.veggies],
        GoalStatus.unlogged,
      );
    });

    test('waitingForPhoto only when the value is reached', () {
      final g = daily.firstWhere((g) => g.id == GoalIds.veggies);
      expect(waitingForPhoto(g, 1, const {}), isTrue);
      expect(waitingForPhoto(g, 0, const {}), isFalse);
      expect(waitingForPhoto(g, 1, {GoalIds.veggies}), isFalse);
    });

    test('stored with the goal (and absent when off)', () {
      final g = daily.firstWhere((g) => g.id == GoalIds.veggies);
      expect(GoalDef.fromMap(g.toMap()).requiresPhoto, isTrue);
      expect(defaultGoals.first.toMap().containsKey('requiresPhoto'), isFalse);
      expect(
        GoalDef.fromMap(defaultGoals.first.toMap()).requiresPhoto,
        isFalse,
      );
    });
  });

  testWidgets('the goal editor can require a photo', (tester) async {
    final b = await signedInPairedBackend();
    await pumpApp(tester, b);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await scrollToCenter(tester, find.text('Edit goals'));
    await tester.tap(find.text('Edit goals'));
    await tester.pumpAndSettle();
    expect(find.byType(GoalsEditorScreen), findsOneWidget);

    await scrollToCenter(
      tester,
      find.byKey(const ValueKey('edit-${GoalIds.veggies}')),
    );
    await tester.tap(find.byKey(const ValueKey('edit-${GoalIds.veggies}')));
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('goal-photo-required'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    final save = find.text('Save').last;
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.textContaining('📷 photo required'), findsOneWidget);
    await tester.tap(find.text('Save').first);
    await tester.pumpAndSettle();

    final veggies = (await b.watchActiveChallenge('demo-pair').first)!.goals
        .firstWhere((g) => g.id == GoalIds.veggies);
    expect(veggies.requiresPhoto, isTrue);
  });

  testWidgets('on Today it waits for the photo, then counts', (tester) async {
    final b = await signedInPairedBackend();
    final me = b.currentUser!.uid;
    await requirePhotoForVeggies(b);
    await pumpApp(tester, b);

    final card = find.byKey(const ValueKey('goal-${GoalIds.veggies}'));
    await scrollToCenter(tester, card);
    expect(
      find.descendant(
        of: card,
        matching: find.text('📷 Counts only with a photo'),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: card, matching: find.text('Kept it ✓')),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: card, matching: find.text('Needs a photo')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text('Add a photo to complete this goal'),
      ),
      findsOneWidget,
    );
    expect((await mySummary(b))!.statuses[GoalIds.veggies], GoalStatus.notMet);

    // The photo arrives (e.g. from the camera): the goal is done, and the
    // group sees it.
    final photo = processPhoto(img.encodeJpg(img.Image(width: 64, height: 48)));
    await b.addPhoto(
      pairId: 'demo-pair',
      uid: me,
      date: todayKey(),
      goalId: GoalIds.veggies,
      fullJpeg: photo.full,
      thumbnailJpeg: photo.thumbnail,
      width: photo.width,
      height: photo.height,
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: card, matching: find.text('Needs a photo')),
      findsNothing,
    );
    expect(
      find.descendant(of: card, matching: find.text('Done')),
      findsOneWidget,
    );
    expect((await mySummary(b))!.statuses[GoalIds.veggies], GoalStatus.met);
  });
}
