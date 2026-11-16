import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/app.dart';
import 'package:goals_challenge/core/dates.dart';
import 'package:goals_challenge/domain/default_goals.dart';
import 'package:goals_challenge/domain/models.dart';
import 'package:goals_challenge/features/widget/widget_snapshot.dart';
import 'package:goals_challenge/features/widget/widget_sync.dart';
import 'package:goals_challenge/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

class FakeWidgetStore implements WidgetStore {
  final files = <String, Uint8List>{};
  final published = <WidgetSnapshot>[];
  var saves = 0;

  @override
  Future<String?> photoPath(String id) async =>
      files.containsKey(id) ? '/w/$id.jpg' : null;

  @override
  Future<String> savePhoto(String id, Uint8List jpeg) async {
    saves++;
    files[id] = jpeg;
    return '/w/$id.jpg';
  }

  @override
  Future<void> prune(Set<String> keep) async =>
      files.removeWhere((id, _) => !keep.contains(id));

  @override
  Future<void> publish(WidgetSnapshot snapshot) async =>
      published.add(snapshot);
}

GoalPhoto photo(String id, String goalId, int minute) => GoalPhoto(
  id: id,
  uid: 'p',
  date: '2026-11-16',
  goalId: goalId,
  createdAt: DateTime(2026, 11, 16, 13, minute),
  thumbnail: Uint8List(0),
  width: 10,
  height: 10,
);

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final he = lookupAppLocalizations(const Locale('he'));
  final daily = defaultGoals.where((g) => g.period == GoalPeriod.daily);

  group('buildWidgetSnapshot', () {
    final summary = DaySummary(
      uid: 'p',
      date: '2026-11-16',
      percent: 22,
      statuses: {
        for (final g in daily) g.id: GoalStatus.unlogged,
        GoalIds.water: GoalStatus.met,
        GoalIds.veggies: GoalStatus.met,
        GoalIds.sweets: GoalStatus.notMet,
      },
    );

    test('title, met goals and captions (English)', () {
      final s = buildWidgetSnapshot(
        l: en,
        members: [WidgetMember(uid: 'p', name: 'Noa', summary: summary)],
        goals: defaultGoals,
        photos: [
          photo('b', GoalIds.workouts, 20),
          photo('a', GoalIds.veggies, 5),
        ],
        paths: {'a': '/w/a.jpg', 'b': '/w/b.jpg'},
      );
      expect(s.title, 'Noa · 22% today');
      expect(s.status, '2/9 · 💧🥗');
      expect(s.rtl, isFalse);
      expect(s.photos.map((p) => p.caption), [
        '🏋️ 3 workouts a week · 13:20',
        '🥗 Vegetables with every meal · 13:05',
      ]);
      final json = jsonDecode(s.encode()) as Map<String, dynamic>;
      expect((json['photos'] as List).first['path'], '/w/b.jpg');
    });

    test('Hebrew is RTL; photos without a stored file are skipped', () {
      final s = buildWidgetSnapshot(
        l: he,
        members: const [WidgetMember(uid: 'p', name: 'נועה', summary: null)],
        goals: defaultGoals,
        photos: [photo('a', GoalIds.water, 1), photo('x', GoalIds.water, 2)],
        paths: {'a': '/w/a.jpg'},
      );
      expect(s.rtl, isTrue);
      expect(s.title, 'נועה · 0% היום');
      expect(s.status, '0/9');
      expect(s.emptyText, contains('נועה'));
      expect(s.photos.map((p) => p.id), ['a']);
    });

    test('a group: everyone\'s %, best first, and who took each photo', () {
      DaySummary pct(String uid, int p) => DaySummary(
        uid: uid,
        date: '2026-11-16',
        statuses: const {},
        percent: p,
      );
      final s = buildWidgetSnapshot(
        l: en,
        members: [
          WidgetMember(uid: 'p', name: 'Noa', summary: pct('p', 40)),
          WidgetMember(uid: 'q', name: 'Dan', summary: pct('q', 75)),
          const WidgetMember(uid: 'r', name: 'Lior', summary: null),
        ],
        goals: defaultGoals,
        photos: [photo('a', GoalIds.water, 7)],
        paths: {'a': '/w/a.jpg'},
      );
      expect(s.title, 'Dan 75% · Noa 40% · Lior 0%');
      expect(s.status, '1 photo today');
      expect(s.emptyText, 'No photos from the group yet today');
      expect(s.photos.single.caption, 'Noa · 💧 8 glasses of water · 13:07');
    });
  });

  group('syncPartnerWidget', () {
    test('stores new photos once, keeps the newest, prunes the rest', () async {
      final b = await signedInPairedBackend();
      final store = FakeWidgetStore()..files['stale'] = Uint8List(1);
      final today = todayKey();
      final noa = await b.fetchPhotos(
        pairId: 'demo-pair',
        uid: 'demo-partner',
        from: today,
        to: today,
      );
      expect(noa, isNotEmpty);

      Future<WidgetSnapshot> sync() => syncGroupWidget(
        store: store,
        photoRepo: b,
        pairId: 'demo-pair',
        l: en,
        members: const [
          WidgetMember(uid: 'demo-partner', name: 'Noa', summary: null),
        ],
        goals: defaultGoals,
        photos: noa,
      );

      final first = await sync();
      expect(first.photos, hasLength(noa.length));
      // Newest first.
      expect(first.photos.first.id, noa.last.id);
      expect(store.files.keys, isNot(contains('stale')));
      expect(store.saves, noa.length);

      await sync();
      expect(store.saves, noa.length, reason: 'already stored photos reused');
      expect(store.published, hasLength(2));
    });

    test('a photo that fails to download is skipped, not fatal', () async {
      final b = await signedInPairedBackend();
      final store = FakeWidgetStore();
      final s = await syncGroupWidget(
        store: store,
        photoRepo: b,
        pairId: 'demo-pair',
        l: en,
        members: const [WidgetMember(uid: 'p', name: 'Noa', summary: null)],
        goals: defaultGoals,
        photos: [photo('missing', GoalIds.water, 1)],
      );
      expect(s.photos, isEmpty);
      expect(store.published, hasLength(1));
    });
  });

  testWidgets('the running app publishes the partner\'s day to the widget', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    final store = FakeWidgetStore();
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: memoryOverrides(b, widgetStore: store),
        child: const GoalsApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(widgetSyncDebounce);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(store.published, isNotEmpty);
    final s = store.published.last;
    expect(s.title, startsWith('Noa · '));
    expect(s.photos, isNotEmpty);
  });

  test('only the Android app has a widget store', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(widgetStoreProvider), isNull);
  });
}
