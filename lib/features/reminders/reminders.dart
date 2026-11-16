import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:material_ui/material_ui.dart' show Locale;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../today/today_providers.dart';
import 'reminder_plan.dart';

/// One notification ready to schedule.
typedef ScheduledReminder = ({int id, DateTime at, String title, String body});

/// Schedules device notifications; faked in tests.
abstract interface class ReminderScheduler {
  /// Asks for permission to notify (Android 13+). True when allowed.
  Future<bool> requestPermission();

  /// Cancels every reminder this app scheduled and schedules [reminders].
  Future<void> replaceAll(List<ScheduledReminder> reminders);
}

/// [ReminderScheduler] on top of flutter_local_notifications (Android).
class LocalNotificationsScheduler implements ReminderScheduler {
  LocalNotificationsScheduler({required this.channelName});

  /// Shown in the phone's notification settings.
  final String channelName;
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  Future<void> _init() => _ready ??= () async {
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      debugPrint('reminders: unknown time zone, using UTC: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_notify'),
      ),
    );
  }();

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> requestPermission() async {
    await _init();
    return await _android?.requestNotificationsPermission() ?? true;
  }

  @override
  Future<void> replaceAll(List<ScheduledReminder> reminders) async {
    await _init();
    for (final id in allReminderIds) {
      await _plugin.cancel(id: id);
    }
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        channelName,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        styleInformation: const BigTextStyleInformation(''),
      ),
    );
    for (final r in reminders) {
      await _plugin.zonedSchedule(
        id: r.id,
        scheduledDate: tz.TZDateTime.from(r.at, tz.local),
        notificationDetails: details,
        // Inexact: no special alarm permission; a few minutes late is fine.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: r.title,
        body: r.body,
      );
    }
  }
}

/// Whether this platform gets reminders (the Android app; the web version
/// would need a push server).
bool get platformHasReminders =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// The scheduler of this platform, or null where reminders aren't offered.
final reminderSchedulerProvider = Provider<ReminderScheduler?>((ref) {
  if (!platformHasReminders) return null;
  final l = lookupAppLocalizations(ref.watch(localeProvider));
  return LocalNotificationsScheduler(channelName: l.remindersChannel);
});

const _prefsKey = 'reminders.v1';

/// Reads this device's saved reminder settings (null if never saved).
/// Also used by the background job, which has no Riverpod container.
Future<ReminderSettings?> loadReminderSettings() async {
  try {
    final v = (await SharedPreferences.getInstance()).getStringList(_prefsKey);
    if (v == null || v.length != 4) return null;
    return ReminderSettings(
      eveningEnabled: v[0] == '1',
      eveningMinutes: int.parse(v[1]),
      middayEnabled: v[2] == '1',
      middayMinutes: int.parse(v[3]),
    );
  } catch (_) {
    return null;
  }
}

/// Reminder settings of this device (stored locally).
final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
      ReminderSettingsNotifier.new,
    );

class ReminderSettingsNotifier extends Notifier<ReminderSettings> {
  @override
  ReminderSettings build() {
    _load();
    return const ReminderSettings();
  }

  Future<void> _load() async {
    final saved = await loadReminderSettings();
    if (saved != null) state = saved;
  }

  Future<void> update(ReminderSettings next) async {
    state = next;
    try {
      await (await SharedPreferences.getInstance()).setStringList(_prefsKey, [
        next.eveningEnabled ? '1' : '0',
        '${next.eveningMinutes}',
        next.middayEnabled ? '1' : '0',
        '${next.middayMinutes}',
      ]);
    } catch (_) {}
  }
}

/// Turns a plan into texts in the app's language.
List<ScheduledReminder> renderReminders(
  AppLocalizations l,
  List<PlannedReminder> plan,
) => [
  for (final p in plan)
    (
      id: p.id,
      at: p.at,
      title: switch (p.kind) {
        ReminderKind.evening => l.reminderEveningTitle,
        ReminderKind.midday => l.reminderMiddayTitle,
      },
      body: switch ((p.kind, p.openGoals)) {
        (ReminderKind.evening, final open?) => l.reminderEveningBody(
          open.join(', '),
        ),
        (ReminderKind.midday, final open?) => l.reminderMiddayBody(
          open.length,
          open.join(', '),
        ),
        (ReminderKind.evening, null) => l.reminderEveningGeneric,
        (ReminderKind.midday, null) => l.reminderMiddayGeneric,
      },
    ),
];

/// While the app runs, keeps the scheduled reminders in step with the
/// settings and today's log (so the evening check names what's still open).
/// Watched by the home shell; debounced.
final reminderSyncProvider = Provider<void>((ref) {
  final scheduler = ref.watch(reminderSchedulerProvider);
  if (scheduler == null) return;
  final settings = ref.watch(reminderSettingsProvider);
  final challenge = ref.watch(challengeProvider).value;
  final log = ref.watch(todayLogProvider).value;
  final locale = ref.watch(localeProvider);
  if (challenge == null) return;
  final lang = locale.languageCode;
  final open = [
    for (final g in challenge.dailyGoals)
      if (log?.valueOf(g.id) == null) g.title(lang),
  ];
  final timer = Timer(const Duration(seconds: 1), () async {
    try {
      final plan = planReminders(
        settings: settings,
        now: DateTime.now(),
        openToday: open,
        challengeEnd: challenge.endDate,
      );
      await scheduler.replaceAll(
        renderReminders(lookupAppLocalizations(Locale(lang)), plan),
      );
    } catch (e) {
      debugPrint('reminders: could not schedule: $e');
    }
  });
  ref.onDispose(timer.cancel);
});
