import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/data/firebase/firebase_backend.dart';
import 'package:goals_challenge/data/firebase/firebase_errors.dart';
import 'package:goals_challenge/data/repositories.dart';
import 'package:goals_challenge/domain/default_goals.dart';
import 'package:goals_challenge/domain/models.dart';

import 'photo_contract.dart';

/// Auth mock whose sign-in / sign-up fail with a given Firebase error code.
class _FailingAuth extends MockFirebaseAuth {
  _FailingAuth(this.code);
  final String code;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) => Future.error(FirebaseAuthException(code: code));

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) => Future.error(FirebaseAuthException(code: code));
}

Matcher throwsAppException(String code) =>
    throwsA(isA<AppException>().having((e) => e.code, 'code', code));

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore db;
  late FirebaseBackend b;

  setUp(() {
    auth = MockFirebaseAuth();
    db = FakeFirebaseFirestore();
    b = FirebaseBackend(auth: auth, firestore: db);
  });

  Future<AppUser> signUp(String name) => b.signUp(
    email: '${name.toLowerCase()}@x.com',
    password: 'secret1',
    displayName: name,
    languageCode: 'he',
  );

  // fake_cloud_firestore applies transaction writes without awaiting them,
  // so let them land before reading.
  Future<Pair> createPair(AppUser u) async {
    final pair = await b.createPair(
      uid: u.uid,
      displayName: u.displayName!,
      startDate: '2026-11-15',
      endDate: '2026-12-14',
      goals: defaultGoals,
    );
    await pumpEventQueue();
    return pair;
  }

  Future<Pair> join(AppUser u, String code) async {
    final pair = await b.joinPair(
      uid: u.uid,
      displayName: u.displayName!,
      code: code,
    );
    await pumpEventQueue();
    return pair;
  }

  test('sign up creates the profile document', () async {
    final u = await signUp('A');
    expect(u.displayName, 'A');
    final profile = await b.watchProfile(u.uid).first;
    expect(profile!.displayName, 'A');
    expect(profile.languageCode, 'he');
    expect(profile.pairId, isNull);

    await b.setLanguage(u.uid, 'en');
    expect((await b.watchProfile(u.uid).first)!.languageCode, 'en');
    // Missing profile is a no-op, like the memory backend.
    await b.setDisplayName('nobody', 'X');
  });

  test('create pair writes pair, challenge, invite code and profile', () async {
    final a = await signUp('A');
    final pair = await createPair(a);

    expect(pair.inviteCode, hasLength(6));
    expect(pair.inviteCode, matches(RegExp(r'^[A-HJ-NP-Z2-9]{6}$')));
    expect(pair.memberUids, [a.uid]);
    expect(pair.isComplete, isFalse);

    expect((await b.watchPair(pair.id).first)!.memberNames, {a.uid: 'A'});
    expect((await b.watchProfile(a.uid).first)!.pairId, pair.id);
    final invite = await db.doc('inviteCodes/${pair.inviteCode}').get();
    expect(invite.data(), containsPair('pairId', pair.id));
    final challenge = (await b.watchActiveChallenge(pair.id).first)!;
    expect(challenge.id, pair.activeChallengeId);
    expect(challenge.goals, hasLength(defaultGoals.length));

    await expectLater(createPair(a), throwsAppException('already-paired'));
  });

  test(
    'join by lowercase code, then full / already-paired / invalid',
    () async {
      final a = await signUp('A');
      final pair = await createPair(a);
      final c = await signUp('C');

      await expectLater(
        b.joinPair(uid: c.uid, displayName: 'C', code: 'nope00'),
        throwsAppException('invalid-code'),
      );
      await expectLater(
        b.joinPair(uid: c.uid, displayName: 'C', code: 'a/b'),
        throwsAppException('invalid-code'),
      );

      final joined = await join(c, pair.inviteCode.toLowerCase());
      expect(joined.isComplete, isTrue);
      expect(joined.partnerOf(c.uid), a.uid);
      final stored = (await b.watchPair(pair.id).first)!;
      expect(stored.memberUids, [a.uid, c.uid]);
      expect(stored.memberNames, {a.uid: 'A', c.uid: 'C'});
      expect((await b.watchProfile(c.uid).first)!.pairId, pair.id);

      // Same user again -> already paired.
      await expectLater(
        b.joinPair(uid: c.uid, displayName: 'C', code: pair.inviteCode),
        throwsAppException('already-paired'),
      );
      // A third user -> pair full.
      final d = await signUp('D');
      await expectLater(
        b.joinPair(uid: d.uid, displayName: 'D', code: pair.inviteCode),
        throwsAppException('pair-full'),
      );
    },
  );

  test('renaming updates the name stored on the pair', () async {
    final a = await signUp('A');
    final pair = await createPair(a);
    await b.setDisplayName(a.uid, 'Eitan');
    await pumpEventQueue();
    expect((await b.watchProfile(a.uid).first)!.displayName, 'Eitan');
    expect((await b.watchPair(pair.id).first)!.memberNames[a.uid], 'Eitan');
  });

  test('setGoalValue writes the log and the summary', () async {
    final a = await signUp('A');
    final pair = await createPair(a);
    final goals = (await b.watchActiveChallenge(pair.id).first)!.dailyGoals;
    const date = '2026-11-15';

    expect(
      await b.watchDaySummary(pairId: pair.id, uid: a.uid, date: date).first,
      isNull,
    );
    final empty = await b
        .watchDailyLog(pairId: pair.id, uid: a.uid, date: date)
        .first;
    expect(empty.values, isEmpty);

    Future<void> set(String goalId, num? v) => b.setGoalValue(
      pairId: pair.id,
      uid: a.uid,
      date: date,
      goalId: goalId,
      value: v,
      dailyGoals: goals,
    );

    await set(GoalIds.water, 8);
    await set(GoalIds.reading, 60);
    await set(GoalIds.sweets, 3);

    final log = await b
        .watchDailyLog(pairId: pair.id, uid: a.uid, date: date)
        .first;
    expect(log.values, {
      GoalIds.water: 8,
      GoalIds.reading: 60,
      GoalIds.sweets: 3,
    });
    var summary = (await b
        .watchDaySummary(pairId: pair.id, uid: a.uid, date: date)
        .first)!;
    expect(summary.statuses[GoalIds.water], GoalStatus.met);
    expect(summary.statuses[GoalIds.sweets], GoalStatus.notMet);
    expect(summary.statuses[GoalIds.steps], GoalStatus.unlogged);
    expect(summary.percent, 22); // 2 of 9

    // Clearing a value removes it from the log and the summary.
    await set(GoalIds.reading, null);
    final cleared = await b
        .watchDailyLog(pairId: pair.id, uid: a.uid, date: date)
        .first;
    expect(cleared.values.keys, [GoalIds.water, GoalIds.sweets]);
    summary = (await b
        .watchDaySummary(pairId: pair.id, uid: a.uid, date: date)
        .first)!;
    expect(summary.statuses[GoalIds.reading], GoalStatus.unlogged);
    expect(summary.percent, 11);

    // Stored at the documented paths.
    expect(
      (await db.doc('pairs/${pair.id}/summaries/${a.uid}_$date').get()).exists,
      isTrue,
    );
    expect(
      (await db.doc('pairs/${pair.id}/logs/${a.uid}/days/$date').get()).exists,
      isTrue,
    );
  });

  test('concurrent setGoalValue calls all land in the summary', () async {
    final a = await signUp('A');
    final pair = await createPair(a);
    final goals = (await b.watchActiveChallenge(pair.id).first)!.dailyGoals;
    const date = '2026-11-15';
    Future<void> set(String goalId, num? v) => b.setGoalValue(
      pairId: pair.id,
      uid: a.uid,
      date: date,
      goalId: goalId,
      value: v,
      dailyGoals: goals,
    );

    // Fired without awaiting in between, like quick taps.
    await Future.wait([
      set(GoalIds.water, 8),
      set(GoalIds.reading, 60),
      set(GoalIds.sweets, 3),
      set(GoalIds.reading, null),
      set(GoalIds.veggies, 1),
    ]);

    final log = await b
        .watchDailyLog(pairId: pair.id, uid: a.uid, date: date)
        .first;
    expect(log.values, {GoalIds.water: 8, GoalIds.sweets: 3, GoalIds.veggies: 1});
    final summary = (await b
        .watchDaySummary(pairId: pair.id, uid: a.uid, date: date)
        .first)!;
    expect(summary.statuses[GoalIds.water], GoalStatus.met);
    expect(summary.statuses[GoalIds.veggies], GoalStatus.met);
    expect(summary.statuses[GoalIds.sweets], GoalStatus.notMet);
    expect(summary.statuses[GoalIds.reading], GoalStatus.unlogged);
    expect(summary.percent, 22); // 2 of 9
  });

  test('clearing a value of a day without a log writes nothing', () async {
    final a = await signUp('A');
    final pair = await createPair(a);
    final goals = (await b.watchActiveChallenge(pair.id).first)!.dailyGoals;
    const date = '2026-11-20';
    await b.setGoalValue(
      pairId: pair.id,
      uid: a.uid,
      date: date,
      goalId: GoalIds.water,
      value: null,
      dailyGoals: goals,
    );
    expect(
      (await db.doc('pairs/${pair.id}/logs/${a.uid}/days/$date').get()).exists,
      isFalse,
    );
    expect(
      (await db.doc('pairs/${pair.id}/summaries/${a.uid}_$date').get()).exists,
      isFalse,
    );
  });

  test('ensureProfile creates a missing profile and keeps an existing one',
      () async {
    final u = await signUp('Dana');
    await b.ensureProfile(u, languageCode: 'en');
    expect((await b.watchProfile(u.uid).first)!.languageCode, 'he');

    await db.doc('users/${u.uid}').delete();
    await b.ensureProfile(
      const AppUser(uid: 'x', email: 'noa.k@x.com'),
      languageCode: 'en',
    );
    final created = (await b.watchProfile('x').first)!;
    expect(created.displayName, 'noa.k');
    expect(created.languageCode, 'en');
    expect(created.pairId, isNull);

    await b.ensureProfile(
      AppUser(uid: u.uid, displayName: 'D' * 150),
      languageCode: 'he',
    );
    expect((await b.watchProfile(u.uid).first)!.displayName, 'D' * 100);
  });

  test('ensureProfile waits for a sign-up in flight', () async {
    final pending = signUp('Dana');
    final u = await b.authStateChanges().firstWhere((u) => u != null);
    await b.ensureProfile(
      AppUser(uid: u!.uid, email: u.email),
      languageCode: 'en',
    );
    await pending;
    final profile = (await b.watchProfile(u.uid).first)!;
    expect(profile.displayName, 'Dana');
    expect(profile.languageCode, 'he');
  });

  test('writeErrors is a broadcast stream', () {
    expect(b.writeErrors.isBroadcast, isTrue);
  });

  test('watchSummaries returns one user in an inclusive date range', () async {
    final a = await signUp('A');
    final pair = await createPair(a);
    final goals = (await b.watchActiveChallenge(pair.id).first)!.dailyGoals;
    for (final (uid, date) in [
      (a.uid, '2026-11-14'),
      (a.uid, '2026-11-15'),
      (a.uid, '2026-11-17'),
      (a.uid, '2026-11-18'),
      ('other', '2026-11-16'),
    ]) {
      await b.setGoalValue(
        pairId: pair.id,
        uid: uid,
        date: date,
        goalId: GoalIds.water,
        value: 8,
        dailyGoals: goals,
      );
    }
    final list = await b
        .watchSummaries(
          pairId: pair.id,
          uid: a.uid,
          from: '2026-11-15',
          to: '2026-11-17',
        )
        .first;
    expect(list.map((s) => s.date), ['2026-11-15', '2026-11-17']);
    expect(list.every((s) => s.uid == a.uid), isTrue);
  });

  test('workouts add (generated id) and delete', () async {
    final a = await signUp('A');
    final pair = await createPair(a);
    await b.addWorkout(
      pairId: pair.id,
      entry: WorkoutEntry(
        id: '',
        uid: a.uid,
        date: '2026-11-16',
        type: WorkoutType.run,
        minutes: 35,
      ),
    );
    await b.addWorkout(
      pairId: pair.id,
      entry: WorkoutEntry(
        id: 'w-fixed',
        uid: a.uid,
        date: '2026-11-15',
        type: WorkoutType.strength,
        minutes: 40,
      ),
    );
    await b.addWorkout(
      pairId: pair.id,
      entry: const WorkoutEntry(
        id: '',
        uid: 'other',
        date: '2026-11-15',
        type: WorkoutType.run,
        minutes: 30,
      ),
    );

    Future<List<WorkoutEntry>> week() => b
        .watchWorkouts(
          pairId: pair.id,
          uid: a.uid,
          from: '2026-11-15',
          to: '2026-11-21',
        )
        .first;
    var list = await week();
    expect(list.map((w) => w.date), ['2026-11-15', '2026-11-16']);
    expect(list.first.id, 'w-fixed');
    expect(list.last.id, isNotEmpty);

    await b.deleteWorkout(pairId: pair.id, id: list.last.id);
    list = await week();
    expect(list.map((w) => w.id), ['w-fixed']);
  });

  test('createChallenge switches the active challenge', () async {
    final a = await signUp('A');
    final pair = await createPair(a);
    final next = await b.createChallenge(
      pairId: pair.id,
      startDate: '2027-01-01',
      endDate: '2027-01-31',
      goals: defaultGoals.take(3).toList(),
    );
    final active = (await b.watchActiveChallenge(pair.id).first)!;
    expect(active.id, next.id);
    expect(active.goals, hasLength(3));
  });

  group('error mapping', () {
    test('auth errors map to AppException codes', () async {
      for (final (fb, app) in [
        ('invalid-credential', 'invalid-credentials'),
        ('wrong-password', 'invalid-credentials'),
        ('user-not-found', 'invalid-credentials'),
        ('email-already-in-use', 'email-in-use'),
        ('weak-password', 'weak-password'),
        ('invalid-email', 'invalid-email'),
        ('network-request-failed', 'network'),
        ('something-else', 'unknown'),
      ]) {
        expect(
          toAppException(FirebaseAuthException(code: fb)).code,
          app,
          reason: fb,
        );
      }
      expect(
        toAppException(FirebaseException(plugin: 'x', code: 'unavailable'))
            .code,
        'network',
      );
    });

    test('signIn surfaces mapped auth exceptions', () async {
      b = FirebaseBackend(auth: _FailingAuth('wrong-password'), firestore: db);
      await expectLater(
        b.signIn(email: 'a@x.com', password: 'nope'),
        throwsAppException('invalid-credentials'),
      );
    });

    test('signUp surfaces email-in-use', () async {
      b = FirebaseBackend(
        auth: _FailingAuth('email-already-in-use'),
        firestore: db,
      );
      await expectLater(signUp('A'), throwsAppException('email-in-use'));
    });
  });

  test('authStateChanges emits AppUser', () async {
    final events = <String?>[];
    final sub = b.authStateChanges().listen((u) => events.add(u?.uid));
    final u = await signUp('A');
    await b.signOut();
    await pumpEventQueue();
    expect(events, containsAllInOrder([u.uid, null]));
    expect(b.currentUser, isNull);
    await sub.cancel();
  });
  group('photos', () {
    photoRepositoryContract(() => b);

    Future<GoalPhoto> addPhoto() => b.addPhoto(
      pairId: 'pair1',
      uid: 'alice',
      date: '2026-11-15',
      goalId: 'water',
      fullJpeg: Uint8List.fromList([1, 2, 3]),
      thumbnailJpeg: Uint8List.fromList([4, 5]),
      width: 1080,
      height: 1350,
    );

    test('stores metadata + thumbnail and the full image as Blobs', () async {
      final photo = await addPhoto();
      final meta = (await db.doc('pairs/pair1/photos/${photo.id}').get())
          .data()!;
      expect(meta['id'], photo.id);
      expect(meta['uid'], 'alice');
      expect(meta['goalId'], 'water');
      expect(meta['createdAt'], photo.createdAt.millisecondsSinceEpoch);
      expect((meta['thumbnail'] as Blob).bytes, [4, 5]);
      expect(meta['reactions'], isEmpty);
      expect(meta, contains('updatedAt'));

      final data = (await db.doc('pairs/pair1/photoData/${photo.id}').get())
          .data()!;
      expect(data['uid'], 'alice');
      expect(data['date'], '2026-11-15');
      expect((data['data'] as Blob).bytes, [1, 2, 3]);
      expect(data, contains('updatedAt'));
    });

    test('loadFullImage reads Firestore once, then the memory cache', () async {
      final photo = await addPhoto();
      // A fresh backend (empty memory cache) reads the photoData doc.
      final other = FirebaseBackend(auth: auth, firestore: db);
      expect(await other.loadFullImage(pairId: 'pair1', photoId: photo.id), [
        1,
        2,
        3,
      ]);
      // Served from memory afterwards, even if the document is gone.
      await db.doc('pairs/pair1/photoData/${photo.id}').delete();
      expect(await other.loadFullImage(pairId: 'pair1', photoId: photo.id), [
        1,
        2,
        3,
      ]);
    });

    test('the full-image cache keeps the most recently used photos', () async {
      final other = FirebaseBackend(auth: auth, firestore: db);
      final ids = <String>[];
      for (var i = 0; i <= FirebaseBackend.fullImageCacheSize; i++) {
        await db.doc('pairs/pair1/photoData/p$i').set({
          'uid': 'alice',
          'date': '2026-11-15',
          'data': Blob(Uint8List.fromList([i])),
        });
        ids.add('p$i');
      }
      Future<Uint8List> load(String id) =>
          other.loadFullImage(pairId: 'pair1', photoId: id);
      await load('p0');
      for (final id
          in ids.skip(1).take(FirebaseBackend.fullImageCacheSize - 1)) {
        await load(id);
      }
      await load('p0'); // p0 is now the most recent, p1 the least
      await load('p${FirebaseBackend.fullImageCacheSize}'); // evicts p1
      for (final id in ['p0', 'p1']) {
        await db.doc('pairs/pair1/photoData/$id').delete();
      }
      expect(await load('p0'), [0]);
      await expectLater(load('p1'), throwsAppException('unknown'));
    });

    test('reactions are written as a single map entry', () async {
      final photo = await addPhoto();
      await b.setReaction(
        pairId: 'pair1',
        photoId: photo.id,
        uid: 'bob',
        emoji: photoReactions.first,
      );
      final meta = (await db.doc('pairs/pair1/photos/${photo.id}').get())
          .data()!;
      expect(meta['reactions'], {'bob': photoReactions.first});
    });
  });
}
