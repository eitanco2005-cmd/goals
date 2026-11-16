import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/app.dart';
import 'package:goals_challenge/core/dates.dart';
import 'package:goals_challenge/data/memory/memory_backend.dart';
import 'package:goals_challenge/data/repositories.dart';
import 'package:goals_challenge/domain/default_goals.dart';
import 'package:goals_challenge/domain/models.dart';
import 'package:goals_challenge/features/photos/photo_capture.dart';
import 'package:goals_challenge/features/photos/photo_processing.dart';
import 'package:goals_challenge/features/photos/photo_providers.dart';
import 'package:goals_challenge/features/photos/photo_thumbnails.dart';
import 'package:goals_challenge/features/photos/photo_viewer.dart';
import 'package:goals_challenge/features/today/partner_strip.dart';
import 'package:goals_challenge/l10n/gen/app_localizations.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

const _tall = Size(400, 3200);
const _pairId = 'demo-pair';
const _partnerUid = 'demo-partner';

/// A JPEG (or PNG) with a smooth gradient, like a real photo compresses.
Uint8List _image(int w, int h, {bool png = false, int? orientation}) {
  final image = img.Image(width: w, height: h);
  for (final p in image) {
    p
      ..r = p.x * 255 ~/ w
      ..g = p.y * 255 ~/ h
      ..b = (p.x + p.y) * 255 ~/ (w + h);
  }
  if (orientation != null) image.exif.imageIfd.orientation = orientation;
  return png ? img.encodePng(image) : img.encodeJpg(image, quality: 85);
}

img.Image _decode(Uint8List bytes) => img.decodeImage(bytes)!;

class _FakePicker implements PhotoPicker {
  _FakePicker(this.bytes);

  final Uint8List? bytes;
  LostPhoto? lost;
  final sources = <PhotoSource>[];
  final targets = <PhotoTarget>[];

  @override
  Future<Uint8List?> pick(PhotoSource source, PhotoTarget target) async {
    sources.add(source);
    targets.add(target);
    return bytes;
  }

  @override
  Future<LostPhoto?> retrieveLost() async {
    final l = lost;
    lost = null;
    return l;
  }
}

Future<void> _pump(
  WidgetTester tester,
  MemoryBackend b, {
  Size size = _tall,
  PhotoPicker? picker,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...memoryOverrides(b),
        photoPickerProvider.overrideWithValue(picker ?? _FakePicker(null)),
        // Synchronous: no isolates under the widget-test fake clock.
        photoProcessorProvider.overrideWithValue(
          (bytes) async => processPhoto(bytes),
        ),
      ],
      child: const GoalsApp(),
    ),
  );
  await tester.pumpAndSettle();
}

final _small = processPhoto(_image(400, 300));

Future<GoalPhoto> _addPhoto(
  MemoryBackend b, {
  required String uid,
  String goalId = GoalIds.veggies,
}) => b.addPhoto(
  pairId: _pairId,
  uid: uid,
  date: todayKey(),
  goalId: goalId,
  fullJpeg: _small.full,
  thumbnailJpeg: _small.thumbnail,
  width: _small.width,
  height: _small.height,
);

/// Today's photos of the signed-in user (the demo seed has Noa's photos).
Future<List<GoalPhoto>> _photos(MemoryBackend b) => b
    .watchPhotos(
      pairId: _pairId,
      uid: b.currentUser!.uid,
      from: todayKey(),
      to: todayKey(),
    )
    .first;

Future<GoalPhoto> _photo(MemoryBackend b, String id) async =>
    (await b
            .watchPhotos(pairId: _pairId, from: todayKey(), to: todayKey())
            .first)
        .singleWhere((p) => p.id == id);

/// Removes the demo seed's photos of Noa for today.
Future<void> _deleteSeededPartnerPhotos(MemoryBackend b) async {
  for (final p
      in await b
          .watchPhotos(pairId: _pairId, from: todayKey(), to: todayKey())
          .first) {
    await b.deletePhoto(pairId: _pairId, photoId: p.id);
  }
}

Finder _inCard(String goalId, Finder matching) => find.descendant(
  of: find.byKey(ValueKey('goal-$goalId')),
  matching: matching,
);

Finder _inPartnerStrip(Finder matching) =>
    find.descendant(of: find.byType(PartnerStrip), matching: matching);

void main() {
  group('processPhoto', () {
    test('resizes a large photo and makes a thumbnail', () {
      final out = processPhoto(_image(1600, 1200));
      expect((out.width, out.height), (fullPhotoMaxSide, 810));
      final full = _decode(out.full);
      expect((full.width, full.height), (out.width, out.height));
      final thumb = _decode(out.thumbnail);
      expect((thumb.width, thumb.height), (thumbnailMaxSide, 240));
      expect(img.findFormatForData(out.full), img.ImageFormat.jpg);
      expect(img.findFormatForData(out.thumbnail), img.ImageFormat.jpg);
      expect(out.full.length, lessThanOrEqualTo(maxFullPhotoBytes));
      expect(out.thumbnail.length, lessThanOrEqualTo(maxThumbnailBytes));
    });

    test('converts other formats to JPEG, keeping portrait shape', () {
      final out = processPhoto(_image(540, 1440, png: true));
      expect((out.width, out.height), (405, fullPhotoMaxSide));
      expect(img.findFormatForData(out.full), img.ImageFormat.jpg);
      final thumb = _decode(out.thumbnail);
      expect((thumb.width, thumb.height), (120, thumbnailMaxSide));
    });

    test('reuses an already small JPEG without metadata as is', () {
      final input = _image(600, 400);
      final out = processPhoto(input);
      expect(identical(out.full, input), isTrue);
      expect((out.width, out.height), (600, 400));
    });

    test('applies the EXIF orientation and strips the metadata', () {
      final input = _image(400, 300, orientation: 6);
      expect(img.decodeJpgExif(input)!.imageIfd.orientation, 6);
      final out = processPhoto(input);
      expect((out.width, out.height), (300, 400));
      expect(identical(out.full, input), isFalse);
      final full = _decode(out.full);
      expect((full.width, full.height), (300, 400));
      expect(img.decodeJpgExif(out.full)?.isEmpty ?? true, isTrue);
    });

    test('rejects bytes that are not an image', () {
      expect(
        () => processPhoto(Uint8List.fromList(List.filled(64, 7))),
        throwsA(
          isA<AppException>().having((e) => e.code, 'code', 'photo-unreadable'),
        ),
      );
    });

    test('too large even at a lower quality -> photo-too-large', () {
      expect(
        () => processPhoto(
          _image(800, 600),
          limits: const PhotoLimits(maxFullBytes: 2000),
        ),
        throwsA(
          isA<AppException>().having((e) => e.code, 'code', 'photo-too-large'),
        ),
      );
    });
  });

  group('newPartnerReactions', () {
    GoalPhoto photo(String uid, Map<String, String> reactions) => GoalPhoto(
      id: 'p-$uid',
      uid: uid,
      date: '2026-05-10',
      goalId: GoalIds.veggies,
      createdAt: DateTime(2026, 5, 10, 9),
      thumbnail: Uint8List(0),
      width: 1,
      height: 1,
      reactions: reactions,
    );

    test('reports added and changed reactions on my photos only', () {
      final before = [photo('me', {}), photo('noa', {})];
      expect(newPartnerReactions(before, before, 'me'), isEmpty);

      final reacted = [
        photo('me', {'noa': '❤️'}),
        photo('noa', {'me': '🔥'}),
      ];
      final r = newPartnerReactions(before, reacted, 'me').single;
      expect((r.photo.id, r.reactorUid, r.emoji), ('p-me', 'noa', '❤️'));

      final changed = [
        photo('me', {'noa': '💪'}),
      ];
      expect(newPartnerReactions(reacted, changed, 'me').single.emoji, '💪');
      // Removing a reaction is not news.
      expect(newPartnerReactions(changed, [photo('me', {})], 'me'), isEmpty);
    });

    test('photos that were not there before are skipped', () {
      expect(
        newPartnerReactions([], [
          photo('me', {'noa': '❤️'}),
        ], 'me'),
        isEmpty,
      );
    });
  });

  testWidgets('adding a photo from the gallery shows it on the goal card', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    final picker = _FakePicker(_image(1600, 1200));
    await _pump(tester, b, picker: picker);
    expect(_inCard(GoalIds.veggies, find.byType(PhotoThumbnail)), findsNothing);

    await tester.tap(find.byTooltip('Add a photo: Vegetables with every meal'));
    await tester.pumpAndSettle();
    expect(find.text('Take photo'), findsOneWidget);
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(picker.sources, [PhotoSource.gallery]);
    final stored = (await _photos(b)).single;
    expect(stored.goalId, GoalIds.veggies);
    expect(stored.uid, b.currentUser!.uid);
    expect((stored.width, stored.height), (fullPhotoMaxSide, 810));
    expect(
      _inCard(GoalIds.veggies, find.byKey(ValueKey('photo-${stored.id}'))),
      findsOneWidget,
    );
    // No spinner left behind, and other cards are untouched.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(_inCard(GoalIds.water, find.byType(PhotoThumbnail)), findsNothing);
  });

  testWidgets('cancelling the picker adds nothing', (tester) async {
    final b = await signedInPairedBackend();
    await _pump(tester, b);
    await tester.tap(find.byTooltip('Add a photo: 8 glasses of water'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();
    expect(await _photos(b), isEmpty);
  });

  testWidgets('an unreadable picked file shows a localized error', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    await _pump(
      tester,
      b,
      picker: _FakePicker(Uint8List.fromList(List.filled(64, 1))),
    );
    await tester.tap(find.byTooltip('Add a photo: 8 glasses of water'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();
    expect(
      find.text("Couldn't read this photo. Try another one"),
      findsOneWidget,
    );
    expect(await _photos(b), isEmpty);
  });

  testWidgets('at the daily limit the picker does not even open', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    for (var i = 0; i < maxPhotosPerDay; i++) {
      await _addPhoto(b, uid: b.currentUser!.uid, goalId: GoalIds.water);
    }
    await _pump(tester, b);
    await tester.tap(find.byTooltip('Add a photo: 8 glasses of water'));
    await tester.pumpAndSettle();
    expect(find.text('Take photo'), findsNothing);
    expect(
      find.text("You've reached the limit of $maxPhotosPerDay photos a day"),
      findsOneWidget,
    );
  });

  testWidgets('partner photo: strip -> viewer -> react ❤️ -> toggle off', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    final me = b.currentUser!.uid;
    final photo = await _addPhoto(b, uid: _partnerUid);
    await _pump(tester, b);

    final thumb = _inPartnerStrip(find.byKey(ValueKey('photo-${photo.id}')));
    expect(thumb, findsOneWidget);
    await tester.tap(thumb);
    await tester.pumpAndSettle();

    expect(find.byType(PhotoViewer), findsOneWidget);
    expect(find.text('Vegetables with every meal'), findsWidgets);
    expect(find.textContaining('Noa · '), findsOneWidget);
    // Not my photo: reactions, but no delete.
    expect(find.byTooltip('Delete photo'), findsNothing);

    await tester.tap(find.byTooltip('React ❤️'));
    await tester.pumpAndSettle();
    expect((await _photo(b, photo.id)).reactions, {me: '❤️'});

    // Switching replaces the reaction; tapping the selected one removes it.
    await tester.tap(find.byTooltip('React 🔥'));
    await tester.pumpAndSettle();
    expect((await _photo(b, photo.id)).reactions, {me: '🔥'});

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewer), findsNothing);
    expect(_inPartnerStrip(find.text('🔥')), findsOneWidget);

    await tester.tap(thumb);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('React 🔥'));
    await tester.pumpAndSettle();
    expect((await _photo(b, photo.id)).reactions, isEmpty);
  });

  testWidgets('partner strip hides the photo row when there are none', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    // Remove the demo seed's photos of Noa.
    for (final p
        in await b
            .watchPhotos(pairId: _pairId, from: todayKey(), to: todayKey())
            .first) {
      await b.deletePhoto(pairId: _pairId, photoId: p.id);
    }
    await _pump(tester, b);
    expect(find.byType(PartnerPhotoRow), findsNothing);

    await _addPhoto(b, uid: _partnerUid);
    await tester.pumpAndSettle();
    expect(find.byType(PartnerPhotoRow), findsOneWidget);
  });

  testWidgets('own photo: viewer shows the partner reaction and deletes', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    final photo = await _addPhoto(b, uid: b.currentUser!.uid);
    await b.setReaction(
      pairId: _pairId,
      photoId: photo.id,
      uid: _partnerUid,
      emoji: '💪',
    );
    await _pump(tester, b);

    await tester.tap(
      _inCard(GoalIds.veggies, find.byKey(ValueKey('photo-${photo.id}'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Noa reacted 💪'), findsOneWidget);
    expect(find.byTooltip('React ❤️'), findsNothing);

    // Cancel keeps it.
    await tester.tap(find.byTooltip('Delete photo'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this photo?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await _photos(b), hasLength(1));

    await tester.tap(find.byTooltip('Delete photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(await _photos(b), isEmpty);
    expect(find.byType(PhotoViewer), findsNothing);
    expect(find.text('Photo deleted'), findsOneWidget);
    expect(_inCard(GoalIds.veggies, find.byType(PhotoThumbnail)), findsNothing);
  });

  testWidgets('a snackbar tells me when the partner reacts to my photo', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    final me = b.currentUser!.uid;
    final old = await _addPhoto(b, uid: me, goalId: GoalIds.water);
    await b.setReaction(
      pairId: _pairId,
      photoId: old.id,
      uid: _partnerUid,
      emoji: '🔥',
    );
    final photo = await _addPhoto(b, uid: me);
    await _pump(tester, b);
    // Reactions that were already there on load are not news.
    expect(find.byType(SnackBar), findsNothing);

    // The partner cycles through reactions: only the final one is announced,
    // and only once it has settled.
    for (final emoji in ['🔥', '💪', '❤️']) {
      await b.setReaction(
        pairId: _pairId,
        photoId: photo.id,
        uid: _partnerUid,
        emoji: emoji,
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.byType(SnackBar), findsNothing);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('Noa reacted ❤️ to your photo 🥗'), findsOneWidget);
    expect(find.textContaining('reacted 🔥'), findsNothing);

    // "View" opens the photo.
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewer), findsOneWidget);
    expect(find.text('Noa reacted ❤️'), findsOneWidget);
  });

  testWidgets('a reaction removed before it settles is not announced', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    final me = b.currentUser!.uid;
    final photo = await _addPhoto(b, uid: me);
    await _pump(tester, b);
    await b.setReaction(
      pairId: _pairId,
      photoId: photo.id,
      uid: _partnerUid,
      emoji: '❤️',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await b.setReaction(
      pairId: _pairId,
      photoId: photo.id,
      uid: _partnerUid,
      emoji: null,
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a partner photo of a weekly goal is labelled with its title', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    await _deleteSeededPartnerPhotos(b);
    await _addPhoto(b, uid: _partnerUid, goalId: GoalIds.workouts);
    await _pump(tester, b);
    expect(find.bySemanticsLabel(RegExp('3 workouts a week')), findsWidgets);
  });

  testWidgets(
    'the viewer drops a photo the owner deletes and closes when empty',
    (tester) async {
      final b = await signedInPairedBackend();
      await _deleteSeededPartnerPhotos(b);
      final photo = await _addPhoto(b, uid: _partnerUid);
      await _pump(tester, b);
      await tester.tap(
        _inPartnerStrip(find.byKey(ValueKey('photo-${photo.id}'))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PhotoViewer), findsOneWidget);

      await b.deletePhoto(pairId: _pairId, photoId: photo.id);
      await tester.pumpAndSettle();
      expect(find.byType(PhotoViewer), findsNothing);
    },
  );

  testWidgets('Escape closes the viewer', (tester) async {
    final b = await signedInPairedBackend();
    await _deleteSeededPartnerPhotos(b);
    final photo = await _addPhoto(b, uid: _partnerUid);
    await _pump(tester, b);
    await tester.tap(
      _inPartnerStrip(find.byKey(ValueKey('photo-${photo.id}'))),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewer), findsNothing);
  });

  testWidgets('a pending upload shows the upload badge', (tester) async {
    final photo = await _addPhoto(
      await signedInPairedBackend(),
      uid: 'someone',
    );
    final pending = GoalPhoto(
      id: photo.id,
      uid: photo.uid,
      date: photo.date,
      goalId: photo.goalId,
      createdAt: photo.createdAt,
      thumbnail: photo.thumbnail,
      width: photo.width,
      height: photo.height,
      isPending: true,
    );
    Widget thumb(GoalPhoto p) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PhotoThumbnail(
          photo: p,
          size: 44,
          semanticsLabel: 'Photo',
          onTap: () {},
        ),
      ),
    );
    await tester.pumpWidget(thumb(pending));
    expect(find.byKey(const ValueKey('photo-pending')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Uploading')), findsOneWidget);
    await tester.pumpWidget(thumb(photo));
    expect(find.byKey(const ValueKey('photo-pending')), findsNothing);
  });

  testWidgets('Android: a photo lost while the camera was open is uploaded '
      'on the next start', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final b = await signedInPairedBackend();
    final me = b.currentUser!.uid;
    final picker = _FakePicker(null)
      ..lost = (
        target: (goalId: GoalIds.veggies, day: todayKey()),
        bytes: _image(400, 300),
      );
    await _pump(tester, b, picker: picker);
    await tester.pumpAndSettle();
    final mine = await b
        .watchPhotos(pairId: _pairId, uid: me, from: todayKey(), to: todayKey())
        .first;
    expect(mine.map((p) => p.goalId), [GoalIds.veggies]);
    expect(picker.lost, isNull);
  });

  testWidgets('Android: a lost photo from another day is discarded', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final b = await signedInPairedBackend();
    final me = b.currentUser!.uid;
    final picker = _FakePicker(null)
      ..lost = (
        target: (goalId: GoalIds.veggies, day: '2000-01-01'),
        bytes: _image(400, 300),
      );
    await _pump(tester, b, picker: picker);
    await tester.pumpAndSettle();
    final mine = await b
        .watchPhotos(pairId: _pairId, uid: me, from: todayKey(), to: todayKey())
        .first;
    expect(mine, isEmpty);
  });

  testWidgets('in Hebrew the viewer swipes to the next photo toward the left', (
    tester,
  ) async {
    final b = await signedInPairedBackend(languageCode: 'he');
    await _addPhoto(b, uid: _partnerUid, goalId: GoalIds.water);
    final newest = await _addPhoto(b, uid: _partnerUid);
    await _pump(tester, b);

    await tester.tap(
      _inPartnerStrip(find.byKey(ValueKey('photo-${newest.id}'))),
    );
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(PageView))),
      TextDirection.rtl,
    );
    // Newest first (like the strip); the next one sits on the left in RTL,
    // so a swipe to the right brings it in.
    expect(find.text('ירקות בכל ארוחה'), findsWidgets);
    await tester.fling(find.byType(PageView), const Offset(300, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('8 כוסות מים'), findsWidgets);
    expect(find.text('ירקות בכל ארוחה'), findsNothing);
  });
}
