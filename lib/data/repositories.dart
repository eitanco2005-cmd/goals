import '../domain/models.dart';

/// Repository contracts. Two implementations exist:
///  * `data/memory/` – in-memory demo backend (no Firebase needed, used in
///    tests and when the app is built without `--dart-define=USE_FIREBASE=true`)
///  * `data/firebase/` – Firebase Auth + Cloud Firestore.
///
/// Firestore layout (see firestore.rules):
///   users/{uid}                                     UserProfile
///   pairs/{pairId}                                  Pair
///   pairs/{pairId}/challenges/{challengeId}         Challenge
///   pairs/{pairId}/logs/{uid}/days/{date}           DailyLog   (owner only)
///   pairs/{pairId}/summaries/{uid}_{date}           DaySummary (both members)
///   pairs/{pairId}/workouts/{workoutId}             WorkoutEntry
///   inviteCodes/{code}                              {pairId, open, createdBy}
///     (`open` is cleared when the partner joins, so a full pair can be
///     reported as 'pair-full' without outsiders reading the pair doc)
///   Every Firestore write also stores a server `updatedAt` (debug only).

/// Maximum length of a display name (mirrors `isName` in firestore.rules).
const maxNameLength = 100;

/// Display name for a profile created from the auth account alone (see
/// [ProfileRepository.ensureProfile]): the account's name, else the local
/// part of its email, clipped to [maxNameLength] characters.
String fallbackProfileName(AppUser user) {
  final name = user.displayName?.trim() ?? '';
  final base = name.isNotEmpty ? name : (user.email ?? '').split('@').first;
  return String.fromCharCodes(base.runes.take(maxNameLength));
}

/// Thrown by repositories with a stable [code] the UI maps to a localized
/// message (see `errorMessage()` in core/errors.dart).
class AppException implements Exception {
  const AppException(this.code, [this.details]);

  /// One of: 'invalid-credentials', 'email-in-use', 'weak-password',
  /// 'invalid-email', 'invalid-code', 'pair-full', 'already-paired',
  /// 'network', 'unknown'.
  final String code;
  final Object? details;

  @override
  String toString() => 'AppException($code${details == null ? '' : ': $details'})';
}

abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;

  /// Creates the account AND its [UserProfile] document.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
    required String languageCode,
  });
  Future<AppUser> signIn({required String email, required String password});
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}

abstract interface class ProfileRepository {
  Stream<UserProfile?> watchProfile(String uid);
  Future<void> setLanguage(String uid, String languageCode);
  Future<void> setDisplayName(String uid, String displayName);

  /// Creates [user]'s profile if it does not exist yet; no-op otherwise.
  ///
  /// Recovers accounts whose sign-up stopped between creating the auth user
  /// and writing the profile (network failure, app killed). The name comes
  /// from [fallbackProfileName]. Waits for a sign-up still in flight on this
  /// repository, so it never overwrites the profile that sign-up writes.
  Future<void> ensureProfile(AppUser user, {required String languageCode});
}

abstract interface class PairRepository {
  /// Creates a pair with [uid] as the only member, a unique 6-character
  /// invite code, and an active challenge built from [goals] spanning
  /// [startDate]..[endDate]. Also sets `pairId` on the user's profile.
  Future<Pair> createPair({
    required String uid,
    required String displayName,
    required String startDate,
    required String endDate,
    required List<GoalDef> goals,
  });

  /// Joins an existing pair by invite code (case-insensitive).
  /// Throws AppException('invalid-code' | 'pair-full' | 'already-paired').
  Future<Pair> joinPair({
    required String uid,
    required String displayName,
    required String code,
  });

  Stream<Pair?> watchPair(String pairId);
}

abstract interface class ChallengeRepository {
  Stream<Challenge?> watchActiveChallenge(String pairId);
  Future<Challenge> createChallenge({
    required String pairId,
    required String startDate,
    required String endDate,
    required List<GoalDef> goals,
  });
}

abstract interface class LogRepository {
  /// Failures of writes that were already reported as done.
  ///
  /// Plain writes (e.g. [setGoalValue], workouts) return once applied
  /// locally, after at most a short wait for the server (they keep syncing
  /// in the background, which is what makes logging work offline). If the
  /// server later rejects one, the error is emitted here so the UI can tell
  /// the user (e.g. with a snackbar). Broadcast; never closes.
  Stream<AppException> get writeErrors;

  /// Emits an empty log if nothing was logged that day.
  Stream<DailyLog> watchDailyLog({
    required String pairId,
    required String uid,
    required String date,
  });

  /// Sets (or clears, when [value] is null) one goal value AND atomically
  /// rewrites the public [DaySummary] computed with `summarizeDay`.
  ///
  /// Calls for the same (pairId, uid, date) are applied in call order, each
  /// on top of the previous one, so firing several without awaiting never
  /// leaves a stale summary. Clearing a value of a day without a log is a
  /// no-op.
  Future<void> setGoalValue({
    required String pairId,
    required String uid,
    required String date,
    required String goalId,
    required num? value,
    required List<GoalDef> dailyGoals,
  });

  /// Summary of one user's day (null when nothing logged).
  Stream<DaySummary?> watchDaySummary({
    required String pairId,
    required String uid,
    required String date,
  });

  /// Summaries of one user for an inclusive date range (for the board).
  Stream<List<DaySummary>> watchSummaries({
    required String pairId,
    required String uid,
    required String from,
    required String to,
  });

  Stream<List<WorkoutEntry>> watchWorkouts({
    required String pairId,
    required String uid,
    required String from,
    required String to,
  });
  Future<void> addWorkout({required String pairId, required WorkoutEntry entry});
  Future<void> deleteWorkout({required String pairId, required String id});
}
