import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/repositories.dart';
import '../../domain/models.dart';
import '../today/today_providers.dart';
import 'photo_processing.dart';

/// All of the pair's photos for today (both partners), oldest first.
///
/// One listener feeds every derived provider below.
final todayPhotosProvider = StreamProvider<List<GoalPhoto>>((ref) {
  final scope = ref.watch(todayScopeProvider);
  if (scope == null) return Stream.value(const []);
  return ref
      .watch(photoRepositoryProvider)
      .watchPhotos(pairId: scope.pairId, from: scope.date, to: scope.date);
});

/// Today's photos of [uid], oldest first.
final userTodayPhotosProvider = Provider.family<List<GoalPhoto>, String>(
  (ref, uid) => [
    for (final p in ref.watch(todayPhotosProvider).value ?? const <GoalPhoto>[])
      if (p.uid == uid) p,
  ],
);

/// My own photos for one goal today, oldest first (as shown on its card).
final myGoalPhotosProvider = Provider.family<List<GoalPhoto>, String>((
  ref,
  goalId,
) {
  final uid = ref.watch(authStateProvider.select((a) => a.value?.uid));
  if (uid == null) return const [];
  return [
    for (final p in ref.watch(userTodayPhotosProvider(uid)))
      if (p.goalId == goalId) p,
  ];
});

/// The partner's photos today, newest first. Empty until they joined.
final partnerTodayPhotosProvider = Provider<List<GoalPhoto>>((ref) {
  final partner = ref.watch(partnerUidProvider);
  if (partner == null) return const [];
  return ref.watch(userTodayPhotosProvider(partner)).reversed.toList();
});

/// Full-size JPEG of a photo of the current pair (the repository caches it).
final fullPhotoProvider = FutureProvider.autoDispose.family<Uint8List, String>((
  ref,
  photoId,
) async {
  final pairId = ref.watch(profileProvider.select((p) => p.value?.pairId));
  if (pairId == null) throw const AppException('unknown', 'not paired');
  return ref
      .watch(photoRepositoryProvider)
      .loadFullImage(pairId: pairId, photoId: photoId);
});

/// Resizes/encodes picked bytes. Overridden in tests to run synchronously.
final photoProcessorProvider =
    Provider<Future<ProcessedPhoto> Function(Uint8List bytes)>(
      (ref) => processPhotoInBackground,
    );

/// Goals with a photo upload in progress (to show a spinner on their card).
final photoUploadsProvider = NotifierProvider<PhotoUploads, Set<String>>(
  PhotoUploads.new,
);

class PhotoUploads extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  /// Whether I already added the maximum number of photos today.
  bool get limitReached {
    final uid = ref.read(todayScopeProvider)?.uid;
    if (uid == null) return false;
    return ref.read(userTodayPhotosProvider(uid)).length >= maxPhotosPerDay;
  }

  /// Processes [bytes] and stores them as today's photo for [goalId].
  /// Throws [AppException] on failure.
  Future<GoalPhoto?> upload(String goalId, Uint8List bytes) async {
    final scope = ref.read(todayScopeProvider);
    if (scope == null) return null;
    state = {...state, goalId};
    try {
      final photo = await ref.read(photoProcessorProvider)(bytes);
      return await ref
          .read(photoRepositoryProvider)
          .addPhoto(
            pairId: scope.pairId,
            uid: scope.uid,
            date: scope.date,
            goalId: goalId,
            fullJpeg: photo.full,
            thumbnailJpeg: photo.thumbnail,
            width: photo.width,
            height: photo.height,
          );
    } finally {
      if (ref.mounted) state = {...state}..remove(goalId);
    }
  }
}

/// A reaction the partner added or changed on one of my photos.
typedef PartnerReaction = ({GoalPhoto photo, String reactorUid, String emoji});

/// Reactions that are new in [next] compared to [previous], on photos owned
/// by [myUid] made by someone else. Photos missing from [previous] are
/// skipped, so the first load (or a new day) never reports anything.
List<PartnerReaction> newPartnerReactions(
  List<GoalPhoto> previous,
  List<GoalPhoto> next,
  String myUid,
) {
  final before = {for (final p in previous) p.id: p};
  return [
    for (final p in next)
      if (p.uid == myUid)
        if (before[p.id] case final old?)
          for (final e in p.reactions.entries)
            if (e.key != myUid && old.reactions[e.key] != e.value)
              (photo: p, reactorUid: e.key, emoji: e.value),
  ];
}
