import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show Locale;
import 'package:workmanager/workmanager.dart';

import '../../core/config.dart';
import '../../core/dates.dart';
import '../../data/firebase/firebase_backend.dart';
import '../../data/firebase/firebase_setup.dart';
import '../../l10n/gen/app_localizations.dart';
import 'widget_sync.dart';

/// Unique name of the periodic widget refresh (one per install).
const widgetRefreshWork = 'partner-widget-refresh';
const _widgetRefreshTask = 'partnerWidgetRefresh';

/// Android allows periodic background work at most every 15 minutes.
const widgetRefreshInterval = Duration(minutes: 15);

/// Schedules the periodic background refresh of the home-screen widget.
/// Only on Android with a real backend: demo data lives in the app's memory
/// and can't be read by a background job. Safe to call on every start.
Future<void> scheduleWidgetRefresh() async {
  if (!platformHasWidget || !useFirebase) return;
  try {
    await Workmanager().initialize(widgetCallbackDispatcher);
    await Workmanager().registerPeriodicTask(
      widgetRefreshWork,
      _widgetRefreshTask,
      frequency: widgetRefreshInterval,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  } catch (e) {
    debugPrint('widget: could not schedule background refresh: $e');
  }
}

/// Entry point of the background isolate started by WorkManager.
@pragma('vm:entry-point')
void widgetCallbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    try {
      await refreshWidgetInBackground();
    } catch (e) {
      debugPrint('widget: background refresh failed: $e');
    }
    // Always "success": a failed refresh is retried by the next period
    // anyway, and WorkManager's backoff would only delay it.
    return true;
  });
}

/// Loads the partner's day from Firebase and updates the widget. Does
/// nothing when signed out or not paired yet.
Future<void> refreshWidgetInBackground() async {
  if (!useFirebase) return;
  final FirebaseBackend backend = await initFirebaseBackend();
  const wait = Duration(seconds: 20);

  // Auth restores the signed-in user asynchronously after start-up.
  final user = await backend.authStateChanges().first.timeout(wait);
  if (user == null) return;
  final profile = await backend.watchProfile(user.uid).first.timeout(wait);
  final pairId = profile?.pairId;
  if (profile == null || pairId == null) return;
  final pair = await backend.watchPair(pairId).first.timeout(wait);
  final partnerUid = pair?.partnerOf(user.uid);
  if (pair == null || partnerUid == null) return;
  final challenge = await backend
      .watchActiveChallenge(pairId)
      .first
      .timeout(wait);
  if (challenge == null) return;

  final today = todayKey();
  final photos = await backend
      .fetchPhotos(pairId: pairId, uid: partnerUid, from: today, to: today)
      .timeout(wait);
  final summary = await backend
      .watchDaySummary(pairId: pairId, uid: partnerUid, date: today)
      .first
      .timeout(wait);

  await syncPartnerWidget(
    store: HomeWidgetStore(),
    photoRepo: backend,
    pairId: pairId,
    l: lookupAppLocalizations(Locale(profile.languageCode)),
    partnerName: pair.memberNames[partnerUid] ?? '',
    summary: summary,
    goals: challenge.goals,
    partnerPhotos: photos,
  );
}
