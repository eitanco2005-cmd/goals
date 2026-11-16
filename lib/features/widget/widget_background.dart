import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show Locale;
import 'package:workmanager/workmanager.dart';

import '../../core/config.dart';
import '../../core/dates.dart';
import '../../data/firebase/firebase_backend.dart';
import '../../data/firebase/firebase_setup.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../reminders/reminder_plan.dart';
import '../reminders/reminders.dart';
import 'widget_snapshot.dart';
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

/// Loads the group's day from Firebase and updates the widget. Does
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
  final challenge = await backend
      .watchActiveChallenge(pairId)
      .first
      .timeout(wait);
  if (pair == null || challenge == null) return;
  final today = todayKey();
  final others = pair.othersOf(user.uid);
  if (others.isEmpty) {
    // Nobody else to show on the widget; reminders still matter.
    await _replanReminders(
      backend: backend,
      uid: user.uid,
      pairId: pairId,
      today: today,
      challenge: challenge,
      languageCode: profile.languageCode,
    );
    return;
  }
  final photos = await backend
      .fetchPhotos(pairId: pairId, from: today, to: today)
      .timeout(wait);
  final members = [
    for (final uid in others)
      WidgetMember(
        uid: uid,
        name: pair.memberNames[uid] ?? '',
        summary: await backend
            .watchDaySummary(pairId: pairId, uid: uid, date: today)
            .first
            .timeout(wait),
      ),
  ];

  await _replanReminders(
    backend: backend,
    uid: user.uid,
    pairId: pairId,
    today: today,
    challenge: challenge,
    languageCode: profile.languageCode,
  );

  await syncGroupWidget(
    store: HomeWidgetStore(),
    photoRepo: backend,
    pairId: pairId,
    l: lookupAppLocalizations(Locale(profile.languageCode)),
    members: members,
    goals: challenge.goals,
    photos: photos,
  );
}

/// Keeps the next week of reminders scheduled even when the app isn't
/// opened, with today's check naming the goals still open.
Future<void> _replanReminders({
  required FirebaseBackend backend,
  required String uid,
  required String pairId,
  required String today,
  required Challenge challenge,
  required String languageCode,
}) async {
  final settings = await loadReminderSettings();
  if (settings == null) return;
  final l = lookupAppLocalizations(Locale(languageCode));
  try {
    final log = await backend
        .watchDailyLog(pairId: pairId, uid: uid, date: today)
        .first
        .timeout(const Duration(seconds: 20));
    final plan = planReminders(
      settings: settings,
      now: DateTime.now(),
      openToday: [
        for (final g in challenge.dailyGoals)
          if (log.valueOf(g.id) == null) g.title(languageCode),
      ],
      challengeEnd: challenge.endDate,
    );
    await LocalNotificationsScheduler(channelName: l.remindersChannel)
        .replaceAll(renderReminders(l, plan));
  } catch (e) {
    debugPrint('reminders: background re-plan failed: $e');
  }
}
