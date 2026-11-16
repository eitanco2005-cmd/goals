import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../core/dates.dart';
import '../../core/demo.dart' as demo;
import '../../domain/default_goals.dart';
import '../../domain/goal_eval.dart';
import '../../domain/models.dart';
import '../repositories.dart';
import 'demo_photos.dart';

/// In-memory implementation of every repository, used for:
///  * tests,
///  * the demo build (no Firebase project configured yet).
///
/// [seedDemo] creates a demo partner ("Noa") who is already in a pair with
/// invite code `DEMO42` and has logged some data, so the UI can be explored
/// end-to-end on a single device.
class MemoryBackend
    implements
        AuthRepository,
        ProfileRepository,
        PairRepository,
        ChallengeRepository,
        LogRepository,
        PhotoRepository {
  MemoryBackend({bool seedDemo = false, Random? random})
      : _random = random ?? Random() {
    if (seedDemo) _seed();
  }

  final Random _random;
  final _changes = StreamController<void>.broadcast();

  // "Tables"
  final Map<String, ({String password, AppUser user})> _accounts = {};
  final Map<String, UserProfile> _profiles = {};
  final Map<String, Pair> _pairs = {};
  final Map<String, Challenge> _challenges = {}; // by pairId (active)
  final Map<String, DailyLog> _logs = {}; // key: pairId|uid|date
  final Map<String, DaySummary> _summaries = {}; // key: pairId|uid|date
  final Map<String, List<WorkoutEntry>> _workouts = {}; // by pairId
  AppUser? _current;

  /// The sign-up in flight, if any (see [ensureProfile]).
  Future<AppUser>? _signUpInFlight;

  int _idCounter = 0;
  String _id(String prefix) => '$prefix${++_idCounter}';

  void _notify() => _changes.add(null);

  /// Emits [read()] on listen and after every change. Subscribes to the
  /// changes together with the first read, so no change is missed.
  Stream<T> _watch<T>(T Function() read) {
    StreamSubscription<void>? changes;
    late final StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () {
        controller.add(read());
        changes = _changes.stream.listen((_) => controller.add(read()));
      },
      onPause: () => changes?.pause(),
      onResume: () => changes?.resume(),
      // Not returned: `first` would wait on it, which can stall under
      // fake-async widget tests.
      onCancel: () {
        changes?.cancel();
      },
    );
    return controller.stream;
  }

  // ---------------------------------------------------------------- Auth
  @override
  Stream<AppUser?> authStateChanges() => _watch(() => _current).distinct();

  @override
  AppUser? get currentUser => _current;

  /// Like Firebase, the new user is signed in (and emitted) BEFORE the
  /// profile exists, so the app sees a signed-in user without a profile.
  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    required String languageCode,
  }) => _signUpInFlight = () async {
    final key = email.trim().toLowerCase();
    if (!key.contains('@')) throw const AppException('invalid-email');
    if (password.length < 6) throw const AppException('weak-password');
    if (_accounts.containsKey(key)) throw const AppException('email-in-use');
    final user = AppUser(uid: _id('u'), email: key, displayName: displayName);
    _accounts[key] = (password: password, user: user);
    _setCurrent(user);
    await _letListenersRun();
    _profiles[user.uid] = UserProfile(
        uid: user.uid, displayName: displayName, languageCode: languageCode);
    _notify();
    return user;
  }();

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    final acc = _accounts[email.trim().toLowerCase()];
    if (acc == null || acc.password != password) {
      throw const AppException('invalid-credentials');
    }
    _setCurrent(acc.user);
    return acc.user;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async => _setCurrent(null);

  void _setCurrent(AppUser? u) {
    _current = u;
    _notify();
  }

  /// An async gap long enough for stream listeners (a few microtask hops
  /// deep) to see the previous change. Uses microtasks, not a timer, which
  /// fake-async widget tests would only run when pumped.
  static Future<void> _letListenersRun() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.value();
    }
  }

  // ------------------------------------------------------------- Profile
  @override
  Stream<UserProfile?> watchProfile(String uid) => _watch(() => _profiles[uid]);

  @override
  Future<void> setLanguage(String uid, String languageCode) async {
    final p = _profiles[uid];
    if (p == null) return;
    _profiles[uid] = p.copyWith(languageCode: languageCode);
    _notify();
  }

  @override
  Future<void> setDisplayName(String uid, String displayName) async {
    final p = _profiles[uid];
    if (p == null) return;
    _profiles[uid] = p.copyWith(displayName: displayName);
    final pair = p.pairId == null ? null : _pairs[p.pairId];
    if (pair != null) {
      _pairs[pair.id] = Pair(
        id: pair.id,
        memberUids: pair.memberUids,
        memberNames: {...pair.memberNames, uid: displayName},
        inviteCode: pair.inviteCode,
        activeChallengeId: pair.activeChallengeId,
      );
    }
    _notify();
  }

  @override
  Future<void> ensureProfile(AppUser user, {required String languageCode}) async {
    try {
      await _signUpInFlight;
    } catch (_) {
      // A failed sign-up is exactly what this recovers from.
    }
    if (_profiles.containsKey(user.uid)) return;
    _profiles[user.uid] = UserProfile(
        uid: user.uid,
        displayName: fallbackProfileName(user),
        languageCode: languageCode);
    _notify();
  }

  /// Deletes a profile, leaving its account signed in (simulates a sign-up
  /// that never wrote the profile).
  @visibleForTesting
  void debugDeleteProfile(String uid) {
    _profiles.remove(uid);
    _notify();
  }

  // ---------------------------------------------------------------- Pair
  String _newCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    String code;
    do {
      code = List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
    } while (_pairs.values.any((p) => p.inviteCode == code));
    return code;
  }

  @override
  Future<Pair> createPair({
    required String uid,
    required String displayName,
    required String startDate,
    required String endDate,
    required List<GoalDef> goals,
  }) async {
    if (_profiles[uid]?.pairId != null) {
      throw const AppException('already-paired');
    }
    final pairId = _id('p');
    final challenge = await createChallenge(
        pairId: pairId, startDate: startDate, endDate: endDate, goals: goals);
    final pair = Pair(
      id: pairId,
      memberUids: [uid],
      memberNames: {uid: displayName},
      inviteCode: _newCode(),
      activeChallengeId: challenge.id,
    );
    _pairs[pairId] = pair;
    _profiles[uid] = _profiles[uid]!.copyWith(pairId: pairId);
    _notify();
    return pair;
  }

  @override
  Future<Pair> joinPair({
    required String uid,
    required String displayName,
    required String code,
  }) async {
    if (_profiles[uid]?.pairId != null) {
      throw const AppException('already-paired');
    }
    final normalized = code.trim().toUpperCase();
    final pair =
        _pairs.values.where((p) => p.inviteCode == normalized).firstOrNull;
    if (pair == null) throw const AppException('invalid-code');
    if (pair.isComplete) throw const AppException('pair-full');
    final joined = Pair(
      id: pair.id,
      memberUids: [...pair.memberUids, uid],
      memberNames: {...pair.memberNames, uid: displayName},
      inviteCode: pair.inviteCode,
      activeChallengeId: pair.activeChallengeId,
    );
    _pairs[pair.id] = joined;
    _profiles[uid] = _profiles[uid]!.copyWith(pairId: pair.id);
    _notify();
    return joined;
  }

  @override
  Stream<Pair?> watchPair(String pairId) => _watch(() => _pairs[pairId]);

  // ----------------------------------------------------------- Challenge
  @override
  Stream<Challenge?> watchActiveChallenge(String pairId) =>
      _watch(() => _challenges[pairId]);

  @override
  Future<Challenge> createChallenge({
    required String pairId,
    required String startDate,
    required String endDate,
    required List<GoalDef> goals,
  }) async {
    final c = Challenge(
      id: _id('c'),
      pairId: pairId,
      startDate: startDate,
      endDate: endDate,
      goals: goals,
    );
    _challenges[pairId] = c;
    final pair = _pairs[pairId];
    if (pair != null) {
      _pairs[pairId] = Pair(
        id: pair.id,
        memberUids: pair.memberUids,
        memberNames: pair.memberNames,
        inviteCode: pair.inviteCode,
        activeChallengeId: c.id,
      );
    }
    _notify();
    return c;
  }

  // ---------------------------------------------------------------- Logs
  String _k(String pairId, String uid, String date) => '$pairId|$uid|$date';

  @override
  Stream<DailyLog> watchDailyLog({
    required String pairId,
    required String uid,
    required String date,
  }) =>
      _watch(() =>
          _logs[_k(pairId, uid, date)] ?? DailyLog(uid: uid, date: date));

  /// Writes never fail here, so this never emits.
  @override
  Stream<AppException> get writeErrors => _writeErrors.stream;
  final _writeErrors = StreamController<AppException>.broadcast();

  /// Applied synchronously, so concurrent calls are naturally serialized.
  @override
  Future<void> setGoalValue({
    required String pairId,
    required String uid,
    required String date,
    required String goalId,
    required num? value,
    required List<GoalDef> dailyGoals,
  }) async {
    final key = _k(pairId, uid, date);
    if (value == null && !_logs.containsKey(key)) return;
    final log =
        (_logs[key] ?? DailyLog(uid: uid, date: date)).withValue(goalId, value);
    _logs[key] = log;
    _summaries[key] = summarizeDay(log, dailyGoals);
    _notify();
  }

  @override
  Stream<DaySummary?> watchDaySummary({
    required String pairId,
    required String uid,
    required String date,
  }) =>
      _watch(() => _summaries[_k(pairId, uid, date)]);

  @override
  Stream<List<DaySummary>> watchSummaries({
    required String pairId,
    required String uid,
    required String from,
    required String to,
  }) =>
      _watch(() => _summaries.values
          .where((s) =>
              s.uid == uid &&
              _summaries.containsKey(_k(pairId, uid, s.date)) &&
              s.date.compareTo(from) >= 0 &&
              s.date.compareTo(to) <= 0)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date)));

  @override
  Stream<List<WorkoutEntry>> watchWorkouts({
    required String pairId,
    required String uid,
    required String from,
    required String to,
  }) =>
      _watch(() => (_workouts[pairId] ?? const <WorkoutEntry>[])
          .where((w) =>
              w.uid == uid &&
              w.date.compareTo(from) >= 0 &&
              w.date.compareTo(to) <= 0)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date)));

  @override
  Future<void> addWorkout({
    required String pairId,
    required WorkoutEntry entry,
  }) async {
    final e = entry.id.isEmpty
        ? WorkoutEntry(
            id: _id('w'),
            uid: entry.uid,
            date: entry.date,
            type: entry.type,
            minutes: entry.minutes)
        : entry;
    (_workouts[pairId] ??= []).add(e);
    _notify();
  }

  @override
  Future<void> deleteWorkout({required String pairId, required String id}) async {
    _workouts[pairId]?.removeWhere((w) => w.id == id);
    _notify();
  }

  // -------------------------------------------------------------- Photos
  final Map<String, List<GoalPhoto>> _photos = {}; // by pairId
  final Map<String, Uint8List> _photoData = {}; // by photoId

  /// Photos matching the [watchPhotos]/[fetchPhotos] filter, in the same
  /// order as the Firestore query: date, then createdAt. Never pending:
  /// writes here are instantly "on the server".
  List<GoalPhoto> _photosIn(
          String pairId, String? uid, String from, String to) =>
      (_photos[pairId] ?? const <GoalPhoto>[])
          .where((p) =>
              (uid == null || p.uid == uid) &&
              p.date.compareTo(from) >= 0 &&
              p.date.compareTo(to) <= 0)
          .toList()
        ..sort((a, b) {
          final byDate = a.date.compareTo(b.date);
          return byDate != 0 ? byDate : a.createdAt.compareTo(b.createdAt);
        });

  @override
  Stream<List<GoalPhoto>> watchPhotos({
    required String pairId,
    String? uid,
    required String from,
    required String to,
  }) =>
      _watch(() => _photosIn(pairId, uid, from, to));

  @override
  Future<List<GoalPhoto>> fetchPhotos({
    required String pairId,
    String? uid,
    required String from,
    required String to,
  }) async =>
      _photosIn(pairId, uid, from, to);

  @override
  Future<Uint8List> loadFullImage({
    required String pairId,
    required String photoId,
  }) async {
    final data = _photoData[photoId];
    if (data == null) throw const AppException('unknown', 'photo not found');
    return data;
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
  }) async {
    if (fullJpeg.length > maxFullPhotoBytes ||
        thumbnailJpeg.length > maxThumbnailBytes) {
      throw const AppException('photo-too-large');
    }
    final list = _photos[pairId] ??= [];
    if (list.where((p) => p.uid == uid && p.date == date).length >=
        maxPhotosPerDay) {
      throw const AppException('photo-limit');
    }
    final photo = GoalPhoto(
      id: _id('ph'),
      uid: uid,
      date: date,
      goalId: goalId,
      createdAt: DateTime.now(),
      thumbnail: thumbnailJpeg,
      width: width,
      height: height,
    );
    list.add(photo);
    _photoData[photo.id] = fullJpeg;
    _notify();
    return photo;
  }

  @override
  Future<void> deletePhoto({
    required String pairId,
    required String photoId,
  }) async {
    _photos[pairId]?.removeWhere((p) => p.id == photoId);
    _photoData.remove(photoId);
    _notify();
  }

  @override
  Future<void> setReaction({
    required String pairId,
    required String photoId,
    required String uid,
    required String? emoji,
  }) async {
    final list = _photos[pairId];
    final i = list?.indexWhere((p) => p.id == photoId) ?? -1;
    if (list == null || i < 0) return;
    final p = list[i];
    final reactions = Map<String, String>.from(p.reactions);
    if (emoji == null) {
      reactions.remove(uid);
    } else {
      reactions[uid] = emoji;
    }
    list[i] = GoalPhoto(
      id: p.id,
      uid: p.uid,
      date: p.date,
      goalId: p.goalId,
      createdAt: p.createdAt,
      thumbnail: p.thumbnail,
      width: p.width,
      height: p.height,
      reactions: reactions,
    );
    _notify();
  }

  // ---------------------------------------------------------------- Demo
  static const demoInviteCode = demo.demoInviteCode;

  void _seed() {
    // Anchor on the logging day (respects dayStartHour), not the raw clock.
    final now = parseDayKey(todayKey());
    const partner = AppUser(uid: 'demo-partner', email: 'noa@demo', displayName: 'Noa');
    _accounts['noa@demo'] = (password: 'demo123', user: partner);
    _profiles[partner.uid] =
        const UserProfile(uid: 'demo-partner', displayName: 'Noa', pairId: 'demo-pair');
    final start = dayKey(now.subtract(const Duration(days: 20)));
    final end = dayKey(now.add(const Duration(days: 69)));
    final challenge = Challenge(
      id: 'demo-challenge',
      pairId: 'demo-pair',
      startDate: start,
      endDate: end,
      goals: defaultGoals,
    );
    _challenges['demo-pair'] = challenge;
    _pairs['demo-pair'] = Pair(
      id: 'demo-pair',
      memberUids: const ['demo-partner'],
      memberNames: const {'demo-partner': 'Noa'},
      inviteCode: demoInviteCode,
      activeChallengeId: challenge.id,
    );
    // Partner history: plausible, deterministic data.
    final rnd = Random(7);
    for (final date in dayKeysBetween(start, dayKey(now))) {
      final isToday = date == dayKey(now);
      final values = <String, num>{
        GoalIds.water: isToday ? 5 : 5 + rnd.nextInt(5),
        GoalIds.steps: isToday ? 6400 : 6000 + rnd.nextInt(7000),
        GoalIds.noSugaryDrinks: rnd.nextInt(10) < 8 ? 1 : 0,
        GoalIds.veggies: rnd.nextInt(10) < 7 ? 1 : 0,
        GoalIds.meals: 2 + rnd.nextInt(2),
        if (!isToday) GoalIds.noMorningSugar: rnd.nextInt(10) < 8 ? 1 : 0,
        if (!isToday) GoalIds.sweets: rnd.nextInt(3),
        if (!isToday) GoalIds.socialMedia: 30 + rnd.nextInt(60),
        if (!isToday) GoalIds.reading: 30 + rnd.nextInt(60),
      };
      final log = DailyLog(uid: partner.uid, date: date, values: values);
      final key = _k('demo-pair', partner.uid, date);
      _logs[key] = log;
      _summaries[key] = summarizeDay(log, challenge.dailyGoals);
    }
    _workouts['demo-pair'] = [
      for (final (i, d) in weekDayKeys(now).take(now.weekday % 7 + 1).indexed)
        if (i.isEven)
          WorkoutEntry(
            id: 'dw$i',
            uid: partner.uid,
            date: d,
            type: i == 0 ? WorkoutType.run : WorkoutType.strength,
            minutes: 40,
          ),
    ];
    _seedPhotos(partner.uid, now);
  }

  /// Noa's photos: a few from today (for the partner card) and some from
  /// earlier days (for the photo diary). The user has none: they have not
  /// joined yet. Images come from [demoPhoto] (rendered once per motif).
  void _seedPhotos(String uid, DateTime today) {
    final clock = DateTime.now();
    // (days ago, goal, minutes after midnight for past days).
    const past = [
      (1, GoalIds.veggies, 13 * 60 + 10),
      (1, GoalIds.reading, 22 * 60 + 5),
      (2, GoalIds.workouts, 7 * 60 + 40),
      (3, GoalIds.water, 16 * 60 + 25),
      (5, GoalIds.veggies, 19 * 60 + 50),
      (5, GoalIds.workouts, 8 * 60 + 15),
    ];
    final photos = [
      for (final (daysAgo, goalId, minutes) in past)
        (
          date: dayKey(today.subtract(Duration(days: daysAgo))),
          goalId: goalId,
          createdAt: today
              .subtract(Duration(days: daysAgo))
              .add(Duration(minutes: minutes)),
        ),
      // Today, oldest first, all in the recent past.
      for (final (i, goalId) in const [
        GoalIds.workouts,
        GoalIds.water,
        GoalIds.veggies,
        GoalIds.reading,
      ].indexed)
        (
          date: dayKey(today),
          goalId: goalId,
          createdAt: clock.subtract(Duration(minutes: 25 + 40 * (3 - i))),
        ),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final list = _photos['demo-pair'] = [];
    for (final (i, p) in photos.indexed) {
      final image = demoPhoto(demoMotifForGoal(p.goalId));
      final photo = GoalPhoto(
        id: 'demo-photo-$i',
        uid: uid,
        date: p.date,
        goalId: p.goalId,
        createdAt: p.createdAt,
        thumbnail: image.thumbnail,
        width: image.width,
        height: image.height,
      );
      list.add(photo);
      _photoData[photo.id] = image.full;
    }
  }
}
