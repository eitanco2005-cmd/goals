import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../domain/goal_eval.dart';
import '../../domain/models.dart';
import '../repositories.dart';
import 'firebase_errors.dart';

typedef _Json = Map<String, dynamic>;

/// Firebase Auth + Cloud Firestore implementation of every repository.
///
/// Behaves like `MemoryBackend` (same semantics, same [AppException] codes).
/// The Firestore layout is documented in `data/repositories.dart` and
/// secured by `firestore.rules`.
///
/// Offline: plain writes (logging values, workouts, settings) are applied to
/// the local cache immediately and synced later, so their futures complete
/// after at most [serverAckWait] even without a connection. Pairing
/// (`createPair` / `joinPair`) uses transactions and therefore needs a
/// connection; it fails with `AppException('network')` when offline.
class FirebaseBackend
    implements
        AuthRepository,
        ProfileRepository,
        PairRepository,
        ChallengeRepository,
        LogRepository,
        PhotoRepository {
  FirebaseBackend({
    required this._auth,
    required this._firestore,
    Random? random,
    this.serverAckWait = const Duration(seconds: 2),
    this.fullImageCacheBytes = defaultFullImageCacheBytes,
  }) : _random = random ?? Random.secure();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Random _random;

  /// How long a plain write waits for the server before returning anyway
  /// (the write stays queued in the offline cache and syncs later).
  final Duration serverAckWait;

  final _writeErrors = StreamController<AppException>.broadcast();

  /// The sign-up in flight, if any (see [ensureProfile]).
  Future<AppUser>? _signUpInFlight;

  /// Per `pairId/uid/date`: the day's log (null: no log document) as it is
  /// once the [setGoalValue] calls issued so far are applied. Present only
  /// while such a write is in flight; see [setGoalValue].
  final _pendingLogs = <String, Future<DailyLog?>>{};

  /// Invite code alphabet: no 0/O or 1/I to avoid confusion when typed.
  static const inviteAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const inviteLength = 6;
  static const _maxCodeAttempts = 8;

  // --------------------------------------------------------------- Paths
  DocumentReference<_Json> _userDoc(String uid) => _firestore.doc('users/$uid');
  DocumentReference<_Json> _inviteDoc(String code) =>
      _firestore.doc('inviteCodes/$code');
  DocumentReference<_Json> _pairDoc(String pairId) =>
      _firestore.doc('pairs/$pairId');
  CollectionReference<_Json> _challenges(String pairId) =>
      _pairDoc(pairId).collection('challenges');
  DocumentReference<_Json> _logDoc(String pairId, String uid, String date) =>
      _pairDoc(pairId).collection('logs').doc(uid).collection('days').doc(date);
  CollectionReference<_Json> _summaries(String pairId) =>
      _pairDoc(pairId).collection('summaries');
  DocumentReference<_Json> _summaryDoc(
    String pairId,
    String uid,
    String date,
  ) => _summaries(pairId).doc('${uid}_$date');
  CollectionReference<_Json> _workouts(String pairId) =>
      _pairDoc(pairId).collection('workouts');
  CollectionReference<_Json> _weekSummaries(String pairId) =>
      _pairDoc(pairId).collection('weekSummaries');
  CollectionReference<_Json> _photos(String pairId) =>
      _pairDoc(pairId).collection('photos');
  CollectionReference<_Json> _photoData(String pairId) =>
      _pairDoc(pairId).collection('photoData');

  /// Server timestamp added to every write (debugging aid; ignored by
  /// the models' `fromMap`).
  static _Json get _stamp => {'updatedAt': FieldValue.serverTimestamp()};

  // ------------------------------------------------------------- Helpers

  /// Awaits [commit] for at most [serverAckWait]. Firestore applies writes
  /// to the local cache synchronously but only completes the future once
  /// the server acknowledges them, which never happens while offline.
  /// Errors reported after the wait are emitted on [writeErrors].
  Future<void> _write(Future<void> commit) async {
    final done = Completer<void>();
    final timer = Timer(serverAckWait, () {
      if (!done.isCompleted) done.complete();
    });
    commit.then(
      (_) {
        if (!done.isCompleted) done.complete();
      },
      onError: (Object e, StackTrace st) {
        if (!done.isCompleted) {
          done.completeError(toAppException(e), st);
        } else {
          debugPrint('FirebaseBackend: queued write failed: $e');
          _writeErrors.add(toAppException(e));
        }
      },
    );
    try {
      await done.future;
    } finally {
      timer.cancel();
    }
  }

  /// Reads [ref] from the local cache (instant, works offline), falling back
  /// to the server when it is not cached.
  Future<DocumentSnapshot<_Json>> _getPreferCache(
    DocumentReference<_Json> ref,
  ) async {
    try {
      return await ref.get(const GetOptions(source: Source.cache));
    } on FirebaseException {
      return ref.get();
    }
  }

  /// Snapshots of a single document mapped with [fromMap] (null if missing).
  Stream<T?> _watchDoc<T>(
    DocumentReference<_Json> ref,
    T Function(_Json) fromMap,
  ) => ref
      .snapshots()
      .map((s) => s.exists ? fromMap(s.data()!) : null)
      .guarded();

  /// Snapshots of a per-user, date-ranged query (summaries, workouts).
  /// Requires the composite index (uid ASC, date ASC) in
  /// firestore.indexes.json.
  Stream<List<T>> _watchRange<T>(
    CollectionReference<_Json> col,
    String uid,
    String from,
    String to,
    T Function(_Json) fromMap,
  ) => col
      .where('uid', isEqualTo: uid)
      .where('date', isGreaterThanOrEqualTo: from)
      .where('date', isLessThanOrEqualTo: to)
      .orderBy('date')
      .snapshots()
      .map((q) => [for (final d in q.docs) fromMap(d.data())])
      .guarded();

  String _newInviteCode() => List.generate(
    inviteLength,
    (_) => inviteAlphabet[_random.nextInt(inviteAlphabet.length)],
  ).join();

  // ---------------------------------------------------------------- Auth
  static AppUser? _toAppUser(User? u) => u == null
      ? null
      : AppUser(uid: u.uid, email: u.email, displayName: u.displayName);

  @override
  Stream<AppUser?> authStateChanges() =>
      _auth.authStateChanges().map(_toAppUser).guarded();

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    required String languageCode,
  }) => _signUpInFlight = guard(() async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    final profile = UserProfile(
      uid: user.uid,
      displayName: displayName,
      languageCode: languageCode,
    );
    await Future.wait([
      user.updateDisplayName(displayName),
      _write(_userDoc(user.uid).set({...profile.toMap(), ..._stamp})),
    ]);
    return AppUser(uid: user.uid, email: user.email, displayName: displayName);
  });

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      guard(() async {
        final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        return _toAppUser(cred.user)!;
      });

  @override
  Future<void> sendPasswordReset(String email) =>
      guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() => guard(_auth.signOut);

  // ------------------------------------------------------------- Profile
  @override
  Stream<UserProfile?> watchProfile(String uid) =>
      _watchDoc(_userDoc(uid), UserProfile.fromMap);

  @override
  Future<void> setLanguage(String uid, String languageCode) =>
      _updateProfile(uid, {'languageCode': languageCode});

  @override
  Future<void> setDisplayName(String uid, String displayName) =>
      guard(() async {
        await _updateProfile(uid, {'displayName': displayName});
        // Keep the name the partner sees (pair.memberNames) in sync.
        final snap = await _getPreferCache(_userDoc(uid));
        final pairId = snap.data()?['pairId'] as String?;
        if (pairId == null) return;
        await _write(
          _pairDoc(pairId).update({'memberNames.$uid': displayName, ..._stamp}),
        );
      });

  @override
  Future<void> ensureProfile(AppUser user, {required String languageCode}) =>
      guard(() async {
        try {
          await _signUpInFlight;
        } catch (_) {
          // A failed sign-up is exactly what this recovers from.
        }
        final ref = _userDoc(user.uid);
        if ((await ref.get()).exists) return;
        final profile = UserProfile(
          uid: user.uid,
          displayName: fallbackProfileName(user),
          languageCode: languageCode,
        );
        await _write(ref.set({...profile.toMap(), ..._stamp}));
      });

  /// Updates profile fields; a missing profile is a no-op (like the memory
  /// backend).
  Future<void> _updateProfile(String uid, _Json fields) => guard(
    () => _write(
      _userDoc(uid)
          .update({...fields, ..._stamp})
          .catchError(
            (_) {},
            test: (e) => e is FirebaseException && e.code == 'not-found',
          ),
    ),
  );

  // ---------------------------------------------------------------- Pair
  @override
  Future<Pair> createPair({
    required String uid,
    required String displayName,
    required String startDate,
    required String endDate,
    required List<GoalDef> goals,
  }) => guard(() async {
    final pairRef = _firestore.collection('pairs').doc();
    final challengeRef = _challenges(pairRef.id).doc();
    final challenge = Challenge(
      id: challengeRef.id,
      pairId: pairRef.id,
      startDate: startDate,
      endDate: endDate,
      goals: goals,
    );
    // Failures are passed out via [failure] instead of being thrown inside
    // the handler, because native SDKs may wrap exceptions thrown there.
    AppException? failure;

    final pair = await _firestore.runTransaction<Pair?>((tx) async {
      final userRef = _userDoc(uid);
      failure = _notPairable(await tx.get(userRef));
      if (failure != null) return null;
      final code = await _findFreeCode(tx);
      if (code == null) {
        failure = const AppException('unknown', 'no free invite code');
        return null;
      }
      final pair = Pair(
        id: pairRef.id,
        memberUids: [uid],
        memberNames: {uid: displayName},
        inviteCode: code,
        activeChallengeId: challenge.id,
      );
      tx
        ..set(pairRef, {...pair.toMap(), 'createdBy': uid, ..._stamp})
        ..set(challengeRef, {...challenge.toMap(), ..._stamp})
        ..set(_inviteDoc(code), {
          'pairId': pairRef.id,
          'open': true,
          'createdBy': uid,
        })
        ..update(userRef, {'pairId': pairRef.id, ..._stamp});
      return pair;
    });
    if (failure != null) throw failure!;
    return pair!;
  });

  /// Picks a random invite code that is not taken yet (read inside [tx] so
  /// a concurrent creator cannot grab the same one). Null if every attempt
  /// collided.
  Future<String?> _findFreeCode(Transaction tx) async {
    for (var i = 0; i < _maxCodeAttempts; i++) {
      final code = _newInviteCode();
      if (!(await tx.get(_inviteDoc(code))).exists) return code;
    }
    return null;
  }

  /// Why the user with this profile cannot create/join a pair, or null.
  static AppException? _notPairable(DocumentSnapshot<_Json> profile) {
    if (!profile.exists) return const AppException('unknown', 'no profile');
    if (profile.data()!['pairId'] != null) {
      return const AppException('already-paired');
    }
    return null;
  }

  @override
  Future<Pair> joinPair({
    required String uid,
    required String displayName,
    required String code,
  }) => guard(() async {
    final normalized = code.trim().toUpperCase();
    if (!RegExp(r'^[A-Z0-9]{1,32}$').hasMatch(normalized)) {
      throw const AppException('invalid-code');
    }
    AppException? failure; // see createPair

    final joined = await _firestore.runTransaction<Pair?>((tx) async {
      final userRef = _userDoc(uid);
      final inviteRef = _inviteDoc(normalized);
      failure = _notPairable(await tx.get(userRef));
      if (failure != null) return null;
      final invite = await tx.get(inviteRef);
      if (!invite.exists) {
        failure = const AppException('invalid-code');
        return null;
      }
      // A full group is not readable by outsiders, so the invite code
      // doc carries an `open` flag that is cleared when the group fills.
      if (invite.data()!['open'] != true) {
        failure = const AppException('pair-full');
        return null;
      }
      final pairRef = _pairDoc(invite.data()!['pairId'] as String);
      final pairSnap = await tx.get(pairRef);
      if (!pairSnap.exists) {
        failure = const AppException('invalid-code');
        return null;
      }
      final pair = Pair.fromMap(pairSnap.data()!);
      if (pair.isFull) {
        failure = const AppException('pair-full');
        return null;
      }
      final joined = Pair(
        id: pair.id,
        memberUids: [...pair.memberUids, uid],
        memberNames: {...pair.memberNames, uid: displayName},
        inviteCode: pair.inviteCode,
        activeChallengeId: pair.activeChallengeId,
      );
      tx
        ..update(pairRef, {
          'memberUids': joined.memberUids,
          FieldPath(['memberNames', uid]): displayName,
          ..._stamp,
        })
        ..update(userRef, {'pairId': pair.id, ..._stamp});
      // The last free spot: close the invite code.
      if (joined.isFull) tx.update(inviteRef, {'open': false});
      return joined;
    });
    if (failure != null) throw failure!;
    return joined!;
  });

  @override
  Stream<Pair?> watchPair(String pairId) =>
      _watchDoc(_pairDoc(pairId), Pair.fromMap);

  // ----------------------------------------------------------- Challenge
  @override
  Stream<Challenge?> watchActiveChallenge(String pairId) =>
      watchPair(pairId)
          .map((p) => p?.activeChallengeId)
          .distinct()
          .switchMap(
            (id) => id == null
                ? Stream<Challenge?>.value(null)
                : _watchDoc(_challenges(pairId).doc(id), Challenge.fromMap),
          );

  @override
  Future<Challenge> createChallenge({
    required String pairId,
    required String startDate,
    required String endDate,
    required List<GoalDef> goals,
  }) => guard(() async {
    final ref = _challenges(pairId).doc();
    final challenge = Challenge(
      id: ref.id,
      pairId: pairId,
      startDate: startDate,
      endDate: endDate,
      goals: goals,
    );
    final batch = _firestore.batch()
      ..set(ref, {...challenge.toMap(), ..._stamp})
      ..update(_pairDoc(pairId), {'activeChallengeId': ref.id, ..._stamp});
    await _write(batch.commit());
    return challenge;
  });

  // ---------------------------------------------------------------- Logs
  @override
  Stream<DailyLog> watchDailyLog({
    required String pairId,
    required String uid,
    required String date,
  }) => _watchDoc(
    _logDoc(pairId, uid, date),
    DailyLog.fromMap,
  ).map((log) => log ?? DailyLog(uid: uid, date: date));

  /// Writes the changed value into the private log and the recomputed
  /// public summary in ONE atomic batch.
  ///
  /// A batch (not a transaction) is used so logging works offline. The log
  /// is patched field-by-field (merge), so a concurrent edit of another goal
  /// from a second device is never lost; at worst the summary is
  /// momentarily stale until the next edit.
  ///
  /// Calls for the same day are chained through [_pendingLogs]: each one
  /// starts from the log the previous call produced instead of re-reading
  /// the cache (which may not reflect a just-issued batch yet), without
  /// waiting for the server to acknowledge the previous batch.
  @override
  Future<void> setGoalValue({
    required String pairId,
    required String uid,
    required String date,
    required String goalId,
    required num? value,
    required List<GoalDef> dailyGoals,
  }) => guard(() async {
    final key = '$pairId/$uid/$date';
    final logRef = _logDoc(pairId, uid, date);
    Future<DailyLog?> readLog() async {
      final snap = await _getPreferCache(logRef);
      return snap.exists ? DailyLog.fromMap(snap.data()!) : null;
    }

    Future<void>? commit;
    final previous = _pendingLogs[key];
    final step =
        (previous == null ? readLog() : previous.catchError((_) => readLog()))
            .then((before) {
              // Clearing a value of a day without a log: nothing to write
              // (a merge holding only a delete would also fail the rules).
              if (before == null && value == null) return null;
              final after = (before ?? DailyLog(uid: uid, date: date))
                  .withValue(goalId, value);
              final summary = summarizeDay(after, dailyGoals);
              commit =
                  (_firestore.batch()
                        ..set(logRef, {
                          'uid': uid,
                          'date': date,
                          'values': {goalId: value ?? FieldValue.delete()},
                          ..._stamp,
                        }, SetOptions(merge: true))
                        ..set(_summaryDoc(pairId, uid, date), {
                          ...summary.toMap(),
                          ..._stamp,
                        }))
                      .commit();
              return after;
            });
    _pendingLogs[key] = step;
    try {
      await step;
      if (commit != null) await _write(commit!);
    } finally {
      if (identical(_pendingLogs[key], step)) _pendingLogs.remove(key);
    }
  });

  @override
  Stream<AppException> get writeErrors => _writeErrors.stream;

  @override
  Stream<DaySummary?> watchDaySummary({
    required String pairId,
    required String uid,
    required String date,
  }) => _watchDoc(_summaryDoc(pairId, uid, date), DaySummary.fromMap);

  @override
  Stream<List<DaySummary>> watchSummaries({
    required String pairId,
    required String uid,
    required String from,
    required String to,
  }) => _watchRange(_summaries(pairId), uid, from, to, DaySummary.fromMap);

  @override
  Stream<List<WorkoutEntry>> watchWorkouts({
    required String pairId,
    required String uid,
    required String from,
    required String to,
  }) => _watchRange(_workouts(pairId), uid, from, to, WorkoutEntry.fromMap);

  /// Adds [entry]; an empty `entry.id` gets a generated one.
  @override
  Future<void> addWorkout({
    required String pairId,
    required WorkoutEntry entry,
  }) => guard(() async {
    final ref = entry.id.isEmpty
        ? _workouts(pairId).doc()
        : _workouts(pairId).doc(entry.id);
    final e = WorkoutEntry(
      id: ref.id,
      uid: entry.uid,
      date: entry.date,
      type: entry.type,
      minutes: entry.minutes,
    );
    await _write(ref.set({...e.toMap(), ..._stamp}));
  });

  @override
  Future<void> deleteWorkout({required String pairId, required String id}) =>
      guard(() => _write(_workouts(pairId).doc(id).delete()));

  /// All members' summaries of one week (single-field query on weekStart).
  @override
  Stream<List<WeekSummary>> watchWeekSummaries({
    required String pairId,
    required String weekStart,
  }) =>
      _weekSummaries(pairId)
          .where('weekStart', isEqualTo: weekStart)
          .snapshots()
          .map((q) => [for (final d in q.docs) WeekSummary.fromMap(d.data())])
          .guarded();

  @override
  Future<void> setWeekSummary({
    required String pairId,
    required WeekSummary summary,
  }) => guard(
    () => _write(
      _weekSummaries(pairId)
          .doc('${summary.uid}_${summary.weekStart}')
          .set({...summary.toMap(), ..._stamp}),
    ),
  );

  // -------------------------------------------------------------- Photos
  //
  // Each photo is two documents written in one batch: the metadata with the
  // small thumbnail (`photos/{id}`, listed by the photo strips) and the
  // full JPEG (`photoData/{id}`, fetched only when a photo is opened), so
  // listing never downloads full images. Bytes are stored as `Blob`s.
  // `photos.thumbnail` and the `photoData` fields are never queried, so
  // firestore.indexes.json exempts them from single-field indexing.

  /// Full images kept in memory by [loadFullImage], most recently used last.
  final _fullImages = <String, Uint8List>{};

  /// Total size of the images in [_fullImages].
  int _fullImagesBytes = 0;

  /// Byte budget of the [_fullImages] cache. Full images are 150–800 KB,
  /// so the default holds roughly 25–130 of them.
  final int fullImageCacheBytes;
  static const defaultFullImageCacheBytes = 20 * 1024 * 1024;

  /// Adds [bytes] as the most recently used image, then evicts the least
  /// recently used ones while over [fullImageCacheBytes] (the newest image
  /// is always kept, even if it alone exceeds the budget).
  void _cacheFullImage(String photoId, Uint8List bytes) {
    _uncacheFullImage(photoId);
    _fullImages[photoId] = bytes;
    _fullImagesBytes += bytes.length;
    while (_fullImagesBytes > fullImageCacheBytes && _fullImages.length > 1) {
      _uncacheFullImage(_fullImages.keys.first);
    }
  }

  void _uncacheFullImage(String photoId) {
    _fullImagesBytes -= _fullImages.remove(photoId)?.length ?? 0;
  }

  /// [GoalPhoto] from a `photos` document (converts the thumbnail `Blob`).
  static GoalPhoto _photoFromDoc(DocumentSnapshot<_Json> d) {
    final m = d.data()!;
    return GoalPhoto.fromMap({
      ...m,
      'thumbnail': (m['thumbnail'] as Blob).bytes,
    }, isPending: d.metadata.hasPendingWrites);
  }

  /// Photos in an inclusive date range, ordered by date then creation time.
  /// Requires the composite indexes (date, createdAt) and
  /// (uid, date, createdAt) in firestore.indexes.json.
  Query<_Json> _photosQuery(
    String pairId,
    String? uid,
    String from,
    String to,
  ) {
    Query<_Json> q = _photos(pairId);
    if (uid != null) q = q.where('uid', isEqualTo: uid);
    return q
        .where('date', isGreaterThanOrEqualTo: from)
        .where('date', isLessThanOrEqualTo: to)
        .orderBy('date')
        .orderBy('createdAt');
  }

  /// Includes metadata changes so [GoalPhoto.isPending] flips to false once
  /// an upload reaches the server; snapshots that change nothing a
  /// [GoalPhoto] exposes (e.g. only `fromCache`) are dropped.
  @override
  Stream<List<GoalPhoto>> watchPhotos({
    required String pairId,
    String? uid,
    required String from,
    required String to,
  }) => _photosQuery(pairId, uid, from, to)
      .snapshots(includeMetadataChanges: true)
      .map((q) => [for (final d in q.docs) _photoFromDoc(d)])
      .distinct(_samePhotos)
      .guarded();

  /// Whether two lists of [watchPhotos] look the same: the other fields of
  /// a photo never change after it is created.
  static bool _samePhotos(List<GoalPhoto> a, List<GoalPhoto> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].isPending != b[i].isPending ||
          !mapEquals(a[i].reactions, b[i].reactions)) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<List<GoalPhoto>> fetchPhotos({
    required String pairId,
    String? uid,
    required String from,
    required String to,
  }) => guard(() async {
    final q = _photosQuery(pairId, uid, from, to);
    QuerySnapshot<_Json> snap;
    try {
      snap = await q.get(const GetOptions(source: Source.server));
    } on FirebaseException catch (e) {
      if (!isNetworkError(e)) rethrow;
      snap = await q.get(const GetOptions(source: Source.cache));
    }
    return [for (final d in snap.docs) _photoFromDoc(d)];
  });

  /// Served from an in-memory LRU cache, then the Firestore cache, then the
  /// server.
  @override
  Future<Uint8List> loadFullImage({
    required String pairId,
    required String photoId,
  }) => guard(() async {
    final cached = _fullImages[photoId];
    if (cached != null) {
      _cacheFullImage(photoId, cached); // mark as recently used
      return cached;
    }
    final snap = await _getPreferCache(_photoData(pairId).doc(photoId));
    final blob = snap.data()?['data'];
    if (blob is! Blob) {
      throw const AppException('unknown', 'photo not found');
    }
    _cacheFullImage(photoId, blob.bytes);
    return blob.bytes;
  });

  /// Number of [uid]'s photos on [date]: from the server when reachable
  /// within [serverAckWait], else from the local cache (so adding a photo
  /// works offline). Only a soft limit: concurrent adds can exceed it.
  Future<int> _countPhotos(String pairId, String uid, String date) async {
    final q = _photos(pairId)
        .where('uid', isEqualTo: uid)
        .where('date', isEqualTo: date);
    try {
      final agg = await q.count().get().timeout(serverAckWait);
      return agg.count ?? 0;
    } on Object {
      return (await q.get(const GetOptions(source: Source.cache))).size;
    }
  }

  @override
  Future<GoalPhoto> addPhoto({
    required String pairId,
    required String uid,
    required String date,
    required String goalId,
    required Uint8List fullJpeg,
    required Uint8List thumbnailJpeg,
    required int width,
    required int height,
  }) => guard(() async {
    if (fullJpeg.length > maxFullPhotoBytes ||
        thumbnailJpeg.length > maxThumbnailBytes) {
      throw const AppException('photo-too-large');
    }
    if (await _countPhotos(pairId, uid, date) >= maxPhotosPerDay) {
      throw const AppException('photo-limit');
    }
    final ref = _photos(pairId).doc();
    final photo = GoalPhoto(
      id: ref.id,
      uid: uid,
      date: date,
      goalId: goalId,
      createdAt: DateTime.now(),
      thumbnail: thumbnailJpeg,
      width: width,
      height: height,
    );
    final batch = _firestore.batch()
      ..set(_photoData(pairId).doc(ref.id), {
        'uid': uid,
        'date': date,
        'data': Blob(fullJpeg),
        ..._stamp,
      })
      ..set(ref, {
        ...photo.toMap(),
        'thumbnail': Blob(thumbnailJpeg),
        ..._stamp,
      });
    // Own photos open instantly, even offline before the upload finished.
    _cacheFullImage(ref.id, fullJpeg);
    await _write(batch.commit());
    return photo;
  });

  @override
  Future<void> deletePhoto({required String pairId, required String photoId}) =>
      guard(() {
        _uncacheFullImage(photoId);
        final batch = _firestore.batch()
          ..delete(_photos(pairId).doc(photoId))
          ..delete(_photoData(pairId).doc(photoId));
        return _write(batch.commit());
      });

  /// A missing photo (e.g. just deleted by its owner) is a no-op, like the
  /// memory backend.
  @override
  Future<void> setReaction({
    required String pairId,
    required String photoId,
    required String uid,
    required String? emoji,
  }) => guard(() {
    final ref = _photos(pairId).doc(photoId);
    return _write(
      _ignoreIfMissing(
        ref,
        ref.update({
          FieldPath(['reactions', uid]): emoji ?? FieldValue.delete(),
          ..._stamp,
        }),
      ),
    );
  });

  /// Completes normally if [update] of [ref] failed because the document
  /// does not exist. The server reports that as `permission-denied` (the
  /// rules reject updates of missing documents) rather than `not-found`, so
  /// that error is ignored only when a read confirms the document is gone:
  /// from the server (quick, it just answered), else from the local cache.
  Future<void> _ignoreIfMissing(
    DocumentReference<_Json> ref,
    Future<void> update,
  ) async {
    try {
      await update;
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') return;
      if (e.code != 'permission-denied') rethrow;
      DocumentSnapshot<_Json>? snap;
      try {
        snap = await ref
            .get(const GetOptions(source: Source.server))
            .timeout(serverAckWait);
      } on Object {
        try {
          snap = await ref.get(const GetOptions(source: Source.cache));
        } on FirebaseException {
          // Not cached either: cannot tell, keep the original error.
        }
      }
      if (snap == null || snap.exists) rethrow;
    }
  }
}
