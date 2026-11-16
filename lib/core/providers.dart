import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/repositories.dart';
import '../domain/models.dart';
import 'dates.dart';

// --------------------------------------------------------------------------
// Repositories – overridden in main.dart (Firebase or in-memory demo) and in
// tests (in-memory).
// --------------------------------------------------------------------------
final authRepositoryProvider =
    Provider<AuthRepository>((ref) => throw UnimplementedError());
final profileRepositoryProvider =
    Provider<ProfileRepository>((ref) => throw UnimplementedError());
final pairRepositoryProvider =
    Provider<PairRepository>((ref) => throw UnimplementedError());
final challengeRepositoryProvider =
    Provider<ChallengeRepository>((ref) => throw UnimplementedError());
final logRepositoryProvider =
    Provider<LogRepository>((ref) => throw UnimplementedError());
final photoRepositoryProvider =
    Provider<PhotoRepository>((ref) => throw UnimplementedError());

/// True when running against the in-memory demo backend.
final isDemoModeProvider = Provider<bool>((ref) => false);

// --------------------------------------------------------------------------
// Session state
// --------------------------------------------------------------------------
final authStateProvider = StreamProvider<AppUser?>(
    (ref) => ref.watch(authRepositoryProvider).authStateChanges());

final profileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchProfile(user.uid);
});

final pairProvider = StreamProvider<Pair?>((ref) {
  final pairId = ref.watch(profileProvider.select((p) => p.value?.pairId));
  if (pairId == null) return Stream.value(null);
  return ref.watch(pairRepositoryProvider).watchPair(pairId);
});

final challengeProvider = StreamProvider<Challenge?>((ref) {
  final pairId = ref.watch(profileProvider.select((p) => p.value?.pairId));
  if (pairId == null) return Stream.value(null);
  return ref.watch(challengeRepositoryProvider).watchActiveChallenge(pairId);
});

/// The partner's uid, or null until the partner has joined.
final partnerUidProvider = Provider<String?>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  final pair = ref.watch(pairProvider).value;
  if (uid == null || pair == null) return null;
  return pair.partnerOf(uid);
});

/// Today's logging-day key. Rolls over automatically at [dayStartHour].
final todayKeyProvider = NotifierProvider<TodayKeyNotifier, String>(
    TodayKeyNotifier.new);

class TodayKeyNotifier extends Notifier<String> {
  Timer? _timer;

  @override
  String build() {
    _schedule();
    ref.onDispose(() => _timer?.cancel());
    return todayKey();
  }

  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    final next = nextDayStart(now);
    _timer = Timer(next.difference(now) + const Duration(seconds: 1), () {
      state = todayKey();
      _schedule();
    });
  }

  /// Call when the app returns to the foreground.
  void refresh() {
    final k = todayKey();
    if (k != state) state = k;
  }
}

// --------------------------------------------------------------------------
// Locale – profile language once signed in, otherwise the pre-login choice.
// --------------------------------------------------------------------------
final preLoginLanguageProvider =
    NotifierProvider<PreLoginLanguageNotifier, String>(
        PreLoginLanguageNotifier.new);

class PreLoginLanguageNotifier extends Notifier<String> {
  @override
  String build() => 'he';
  void set(String code) => state = code;
}

final localeProvider = Provider<Locale>((ref) {
  final profileLang =
      ref.watch(profileProvider.select((p) => p.value?.languageCode));
  return Locale(profileLang ?? ref.watch(preLoginLanguageProvider));
});
