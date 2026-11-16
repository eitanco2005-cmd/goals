import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/data/repositories.dart';
import 'package:goals_challenge/domain/models.dart';

/// Behavior every [PhotoRepository] must share; run against both backends
/// (memory_backend_test.dart, firebase_backend_test.dart) so they cannot
/// drift apart.
void photoRepositoryContract(PhotoRepository Function() create) {
  late PhotoRepository repo;
  setUp(() => repo = create());

  const pairId = 'pair1';

  Uint8List jpeg(int size, [int fill = 1]) =>
      Uint8List.fromList(List.filled(size, fill));

  Future<GoalPhoto> add({
    String uid = 'alice',
    String date = '2026-11-15',
    String goalId = 'veggies',
    int fullSize = 1000,
    int thumbSize = 100,
    int fill = 1,
  }) async {
    final photo = await repo.addPhoto(
      pairId: pairId,
      uid: uid,
      date: date,
      goalId: goalId,
      fullJpeg: jpeg(fullSize, fill),
      thumbnailJpeg: jpeg(thumbSize, fill),
      width: 1080,
      height: 1350,
    );
    // createdAt has millisecond resolution; keep additions strictly ordered.
    await Future<void>.delayed(const Duration(milliseconds: 3));
    return photo;
  }

  Future<List<GoalPhoto>> watch({
    String? uid,
    String from = '2000-01-01',
    String to = '2100-01-01',
  }) => repo.watchPhotos(pairId: pairId, uid: uid, from: from, to: to).first;

  test('addPhoto returns the photo and watchPhotos lists it', () async {
    final photo = await add(fill: 9);
    expect(photo.id, isNotEmpty);
    expect(photo.uid, 'alice');
    expect(photo.date, '2026-11-15');
    expect(photo.goalId, 'veggies');
    expect(photo.width, 1080);
    expect(photo.height, 1350);
    expect(photo.reactions, isEmpty);

    final listed = (await watch()).single;
    expect(listed.id, photo.id);
    expect(listed.thumbnail, isA<Uint8List>());
    expect(listed.thumbnail, jpeg(100, 9));
    expect(
      listed.createdAt.millisecondsSinceEpoch,
      photo.createdAt.millisecondsSinceEpoch,
    );
    expect(
      await repo.loadFullImage(pairId: pairId, photoId: photo.id),
      jpeg(1000, 9),
    );
  });

  test('watchPhotos: inclusive date range, uid filter, oldest first', () async {
    final a1 = await add(date: '2026-11-14');
    final a2 = await add(date: '2026-11-15', goalId: 'water');
    final b1 = await add(uid: 'bob', date: '2026-11-15');
    final a3 = await add(date: '2026-11-15', goalId: 'reading');
    await add(date: '2026-11-16');

    expect(
      (await watch(from: '2026-11-14', to: '2026-11-15')).map((p) => p.id),
      [a1.id, a2.id, b1.id, a3.id],
    );
    expect(
      (await watch(
        uid: 'alice',
        from: '2026-11-15',
        to: '2026-11-15',
      )).map((p) => p.id),
      [a2.id, a3.id],
    );
    expect((await watch(uid: 'bob')).map((p) => p.id), [b1.id]);
    expect(await watch(uid: 'carol'), isEmpty);
    expect(await watch(from: '2026-11-17', to: '2026-11-30'), isEmpty);
  });

  test('fetchPhotos: same filter and order as watchPhotos', () async {
    final a1 = await add(date: '2026-11-14');
    final a2 = await add(date: '2026-11-15', goalId: 'water');
    final b1 = await add(uid: 'bob', date: '2026-11-15');
    await add(date: '2026-11-16');
    await repo.setReaction(
      pairId: pairId,
      photoId: a2.id,
      uid: 'bob',
      emoji: photoReactions[1],
    );

    Future<List<GoalPhoto>> fetch({
      String? uid,
      String from = '2000-01-01',
      String to = '2100-01-01',
    }) => repo.fetchPhotos(pairId: pairId, uid: uid, from: from, to: to);

    final fetched = await fetch(from: '2026-11-14', to: '2026-11-15');
    expect(fetched.map((p) => p.id), [a1.id, a2.id, b1.id]);
    expect(fetched[1].reactions, {'bob': photoReactions[1]});
    expect(fetched[0].thumbnail, jpeg(100));
    expect(
      (await fetch(
        uid: 'alice',
        from: '2026-11-15',
        to: '2026-11-16',
      )).map((p) => p.date),
      ['2026-11-15', '2026-11-16'],
    );
    expect(await fetch(uid: 'carol'), isEmpty);
    for (final (uid, from, to) in [
      (null, '2026-11-14', '2026-11-15'),
      ('alice', '2026-11-15', '2026-11-16'),
    ]) {
      expect(
        (await fetch(uid: uid, from: from, to: to)).map((p) => p.id),
        (await watch(uid: uid, from: from, to: to)).map((p) => p.id),
      );
    }
  });

  test('setReaction on a photo deleted just before is a no-op', () async {
    final p = await add();
    await repo.deletePhoto(pairId: pairId, photoId: p.id);
    await repo.setReaction(
      pairId: pairId,
      photoId: p.id,
      uid: 'bob',
      emoji: photoReactions[0],
    );
    expect(await watch(), isEmpty);
  });

  test('watchPhotos emits again on changes', () async {
    final stream = repo.watchPhotos(
      pairId: pairId,
      from: '2026-11-15',
      to: '2026-11-15',
    );
    final lengths = <int>[];
    final sub = stream.listen((l) => lengths.add(l.length));
    await pumpEventQueue();
    final p = await add();
    await add(date: '2026-12-01'); // outside the range
    await pumpEventQueue();
    await repo.deletePhoto(pairId: pairId, photoId: p.id);
    await pumpEventQueue();
    await sub.cancel();
    expect(lengths.first, 0);
    expect(lengths, containsAllInOrder([0, 1, 0]));
    expect(lengths.last, 0);
  });

  test('deletePhoto removes the metadata and the full image', () async {
    final keep = await add();
    final gone = await add(goalId: 'water');
    await repo.deletePhoto(pairId: pairId, photoId: gone.id);
    expect((await watch()).map((p) => p.id), [keep.id]);
    await expectLater(
      repo.loadFullImage(pairId: pairId, photoId: gone.id),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'unknown')),
    );
  });

  test('loadFullImage of an unknown photo throws unknown', () async {
    await expectLater(
      repo.loadFullImage(pairId: pairId, photoId: 'nope'),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'unknown')),
    );
  });

  test('setReaction sets, replaces and removes one reaction', () async {
    final p = await add();
    Future<Map<String, String>> reactions() async =>
        (await watch()).single.reactions;

    await repo.setReaction(
      pairId: pairId,
      photoId: p.id,
      uid: 'bob',
      emoji: photoReactions[0],
    );
    expect(await reactions(), {'bob': photoReactions[0]});
    await repo.setReaction(
      pairId: pairId,
      photoId: p.id,
      uid: 'bob',
      emoji: photoReactions[2],
    );
    expect(await reactions(), {'bob': photoReactions[2]});
    await repo.setReaction(
      pairId: pairId,
      photoId: p.id,
      uid: 'bob',
      emoji: null,
    );
    expect(await reactions(), isEmpty);
  });

  test('setReaction on a missing photo is a no-op', () async {
    await repo.setReaction(
      pairId: pairId,
      photoId: 'nope',
      uid: 'bob',
      emoji: photoReactions[0],
    );
    expect(await watch(), isEmpty);
  });

  test('photo-too-large: full or thumbnail over the limit', () async {
    final tooLarge = throwsA(
      isA<AppException>().having((e) => e.code, 'code', 'photo-too-large'),
    );
    await expectLater(add(fullSize: maxFullPhotoBytes + 1), tooLarge);
    await expectLater(add(thumbSize: maxThumbnailBytes + 1), tooLarge);
    expect(await watch(), isEmpty);
    // Exactly at the limits is fine.
    await add(fullSize: maxFullPhotoBytes, thumbSize: maxThumbnailBytes);
    expect(await watch(), hasLength(1));
  });

  test('photo-limit: at most maxPhotosPerDay per person and day', () async {
    for (var i = 0; i < maxPhotosPerDay; i++) {
      await repo.addPhoto(
        pairId: pairId,
        uid: 'alice',
        date: '2026-11-15',
        goalId: 'veggies',
        fullJpeg: jpeg(10),
        thumbnailJpeg: jpeg(10),
        width: 1,
        height: 1,
      );
    }
    await expectLater(
      add(),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'photo-limit')),
    );
    // Other days and the partner are not affected.
    await add(date: '2026-11-16');
    await add(uid: 'bob');
    expect(
      await watch(uid: 'alice', from: '2026-11-15', to: '2026-11-15'),
      hasLength(maxPhotosPerDay),
    );
  });
}
