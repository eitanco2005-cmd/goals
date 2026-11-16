import 'dart:typed_data';

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
///   pairs/{pairId}/workouts/{workoutId}             WorkoutEntry (owner only)
///   pairs/{pairId}/weekSummaries/{uid}_{weekStart}  WeekSummary (all members)
///   pairs/{pairId}/photos/{photoId}                GoalPhoto metadata + thumbnail (both members)
///   pairs/{pairId}/photoData/{photoId}             {uid, date, data: full JPEG bytes} (both members)
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
  /// 'network', 'photo-too-large', 'photo-limit', 'photo-unreadable',
  /// 'unknown'.
  final String code;
  final Object? details;

  @override
  String toString() =>
      'AppException($code${details == null ? '' : ': $details'})';
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

  /// Leaves the group: removes [uid] from it and clears their profile's
  /// pairId (the app then shows the start/join screen). Leaving a full
  /// group reopens its invite code. Needs a connection.
  Future<void> leavePair({required String uid, required String pairId});

  /// Replaces the group's invite code (the old one stops working) and
  /// returns the new code. Needs a connection.
  Future<String> renewInviteCode({required String uid, required String pairId});
}

/// Most goals a challenge can have (mirrors `validChallenge` in the rules).
const maxGoals = 30;

abstract interface class ChallengeRepository {
  Stream<Challenge?> watchActiveChallenge(String pairId);

  /// Replaces the goals of challenge [challengeId] (any member may edit;
  /// the change applies to the whole group from now on).
  Future<void> updateGoals({
    required String pairId,
    required String challengeId,
    required List<GoalDef> goals,
  });

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
  Future<void> addWorkout({
    required String pairId,
    required WorkoutEntry entry,
  });
  Future<void> deleteWorkout({required String pairId, required String id});

  /// Every member's public summary of the week starting [weekStart].
  Stream<List<WeekSummary>> watchWeekSummaries({
    required String pairId,
    required String weekStart,
  });

  /// Stores the caller's own week summary (computed with `summarizeWeek`).
  Future<void> setWeekSummary({
    required String pairId,
    required WeekSummary summary,
  });
}

/// Size limits for photos (Firestore documents are capped at 1 MiB).
const maxFullPhotoBytes = 800 * 1024;
const maxThumbnailBytes = 60 * 1024;

/// Max photos one person can add per logging day (keeps storage bounded).
const maxPhotosPerDay = 20;

/// Long-side pixel sizes the client resizes to before upload.
const fullPhotoMaxSide = 1080;
const thumbnailMaxSide = 320;

abstract interface class PhotoRepository {
  /// Photos of the pair in an inclusive date range, oldest first.
  /// When [uid] is given, only that person's photos.
  Stream<List<GoalPhoto>> watchPhotos({
    required String pairId,
    String? uid,
    required String from,
    required String to,
  });

  /// One-shot read with the same filter and order as [watchPhotos], for
  /// callers without a UI listener (e.g. a background job feeding the home
  /// screen widget). Reads from the server, falling back to the local cache
  /// when the network is unreachable.
  Future<List<GoalPhoto>> fetchPhotos({
    required String pairId,
    String? uid,
    required String from,
    required String to,
  });

  /// Full-size JPEG bytes for a photo (cached after the first load).
  Future<Uint8List> loadFullImage({
    required String pairId,
    required String photoId,
  });

  /// Stores a photo. [fullJpeg]/[thumbnailJpeg] must already be resized
  /// (see [fullPhotoMaxSide]/[thumbnailMaxSide]).
  /// Throws AppException('photo-too-large' | 'photo-limit').
  Future<GoalPhoto> addPhoto({
    required String pairId,
    required String uid,
    required String date,
    required String goalId,
    required Uint8List fullJpeg,
    required Uint8List thumbnailJpeg,
    required int width,
    required int height,
  });

  /// Deletes one of the caller's own photos (metadata and full image).
  Future<void> deletePhoto({required String pairId, required String photoId});

  /// Sets ([emoji] one of [photoReactions]) or removes (null) [uid]'s
  /// reaction on a partner's photo.
  Future<void> setReaction({
    required String pairId,
    required String photoId,
    required String uid,
    required String? emoji,
  });
}
