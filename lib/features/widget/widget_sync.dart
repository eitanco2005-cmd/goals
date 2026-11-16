import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:material_ui/material_ui.dart' show Locale;
import 'package:path_provider/path_provider.dart';

import '../../core/providers.dart';
import '../../data/repositories.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../photos/photo_providers.dart';
import '../today/today_providers.dart';
import 'widget_snapshot.dart';

/// Where the widget's data lives on the device. The Android implementation
/// is [HomeWidgetStore]; tests use a fake.
abstract interface class WidgetStore {
  /// Absolute path of the stored photo [id], or null if not stored yet.
  Future<String?> photoPath(String id);

  /// Stores a photo's JPEG bytes and returns its absolute path.
  Future<String> savePhoto(String id, Uint8List jpeg);

  /// Deletes stored photos whose id is not in [keep].
  Future<void> prune(Set<String> keep);

  /// Hands [snapshot] to the native widget and asks it to redraw.
  Future<void> publish(WidgetSnapshot snapshot);
}

/// SharedPreferences key the Kotlin widget reads (see PartnerWidgetProvider).
const widgetSnapshotKey = 'partner_snapshot';

/// Fully-qualified name of the Android AppWidgetProvider.
const androidWidgetProvider =
    'app.goalschallenge.goals_challenge.PartnerWidgetProvider';

/// Photos in the app's support directory + snapshot JSON in the
/// home_widget SharedPreferences, read by the native Android widget.
class HomeWidgetStore implements WidgetStore {
  Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}/widget_photos').create(recursive: true);
  }

  File _file(Directory dir, String id) => File('${dir.path}/$id.jpg');

  @override
  Future<String?> photoPath(String id) async {
    final f = _file(await _dir(), id);
    return await f.exists() ? f.path : null;
  }

  @override
  Future<String> savePhoto(String id, Uint8List jpeg) async {
    final f = _file(await _dir(), id);
    // Write then rename, so the widget never reads a half-written file.
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsBytes(jpeg, flush: true);
    await tmp.rename(f.path);
    return f.path;
  }

  @override
  Future<void> prune(Set<String> keep) async {
    await for (final e in (await _dir()).list()) {
      final name = e.uri.pathSegments.last;
      final id = name.endsWith('.jpg')
          ? name.substring(0, name.length - 4)
          : null;
      if (e is File && (id == null || !keep.contains(id))) await e.delete();
    }
  }

  @override
  Future<void> publish(WidgetSnapshot snapshot) async {
    await HomeWidget.saveWidgetData<String>(
      widgetSnapshotKey,
      snapshot.encode(),
    );
    await HomeWidget.updateWidget(qualifiedAndroidName: androidWidgetProvider);
  }
}

/// Whether this platform has the home-screen widget (Android app only).
bool get platformHasWidget =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Refreshes the widget with the partner's photos of today.
///
/// Shared by the running app and the background job. Downloads full images
/// only for photos not stored yet, keeps at most [maxWidgetPhotos], and
/// deletes older files. Photos that fail to download are skipped (the next
/// sync retries them).
Future<WidgetSnapshot> syncPartnerWidget({
  required WidgetStore store,
  required PhotoRepository photoRepo,
  required String pairId,
  required AppLocalizations l,
  required String partnerName,
  required DaySummary? summary,
  required List<GoalDef> goals,
  required List<GoalPhoto> partnerPhotos,
}) async {
  final newest = [...partnerPhotos]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final shown = newest.take(maxWidgetPhotos).toList();
  final paths = <String, String>{};
  for (final p in shown) {
    try {
      paths[p.id] =
          await store.photoPath(p.id) ??
          await store.savePhoto(
            p.id,
            await photoRepo.loadFullImage(pairId: pairId, photoId: p.id),
          );
    } catch (e) {
      debugPrint('widget: could not store photo ${p.id}: $e');
    }
  }
  final snapshot = buildWidgetSnapshot(
    l: l,
    partnerName: partnerName,
    summary: summary,
    goals: goals,
    photos: shown,
    paths: paths,
  );
  await store.publish(snapshot);
  await store.prune(paths.keys.toSet());
  return snapshot;
}

/// The widget store for this platform, or null where there is no widget.
final widgetStoreProvider = Provider<WidgetStore?>(
  (ref) => platformHasWidget ? HomeWidgetStore() : null,
);

/// While the app runs, keeps the widget in sync with the partner's day.
/// Watched by the home shell; changes are debounced into one sync.
final partnerWidgetSyncProvider = Provider<void>((ref) {
  final store = ref.watch(widgetStoreProvider);
  if (store == null) return;
  final pair = ref.watch(pairProvider).value;
  final myUid = ref.watch(authStateProvider.select((a) => a.value?.uid));
  final partnerUid = ref.watch(partnerUidProvider);
  final challenge = ref.watch(challengeProvider).value;
  final photos = ref.watch(partnerTodayPhotosProvider);
  final summary = ref.watch(partnerTodaySummaryProvider).value;
  final locale = ref.watch(localeProvider);
  if (pair == null ||
      myUid == null ||
      partnerUid == null ||
      challenge == null) {
    return;
  }
  final repo = ref.watch(photoRepositoryProvider);
  final timer = Timer(widgetSyncDebounce, () async {
    try {
      await syncPartnerWidget(
        store: store,
        photoRepo: repo,
        pairId: pair.id,
        l: lookupAppLocalizations(Locale(locale.languageCode)),
        partnerName: pair.memberNames[partnerUid] ?? '',
        summary: summary,
        goals: challenge.goals,
        partnerPhotos: photos,
      );
    } catch (e) {
      debugPrint('widget sync failed: $e');
    }
  });
  ref.onDispose(timer.cancel);
});

/// Delay before syncing, so a burst of changes produces one sync.
const widgetSyncDebounce = Duration(seconds: 2);
