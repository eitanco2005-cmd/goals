import '../../core/dates.dart';

/// Device-local reminder settings (each phone decides its own).
class ReminderSettings {
  const ReminderSettings({
    this.eveningEnabled = false,
    this.eveningMinutes = 21 * 60 + 30,
    this.middayEnabled = false,
    this.middayMinutes = 13 * 60,
  });

  /// End-of-day check (the "וידוא"): lists what's still unlogged.
  final bool eveningEnabled;

  /// Minutes after midnight.
  final int eveningMinutes;

  /// A midday nudge with how many goals are still open.
  final bool middayEnabled;
  final int middayMinutes;

  ReminderSettings copyWith({
    bool? eveningEnabled,
    int? eveningMinutes,
    bool? middayEnabled,
    int? middayMinutes,
  }) => ReminderSettings(
    eveningEnabled: eveningEnabled ?? this.eveningEnabled,
    eveningMinutes: eveningMinutes ?? this.eveningMinutes,
    middayEnabled: middayEnabled ?? this.middayEnabled,
    middayMinutes: middayMinutes ?? this.middayMinutes,
  );

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.eveningEnabled == eveningEnabled &&
      other.eveningMinutes == eveningMinutes &&
      other.middayEnabled == middayEnabled &&
      other.middayMinutes == middayMinutes;

  @override
  int get hashCode =>
      Object.hash(eveningEnabled, eveningMinutes, middayEnabled, middayMinutes);
}

enum ReminderKind { evening, midday }

/// One notification to schedule.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.kind,
    required this.at,
    required this.dayKey,
    required this.openGoals,
  });

  /// Stable per kind and day slot, so re-planning replaces it.
  final int id;
  final ReminderKind kind;

  /// Local wall-clock time.
  final DateTime at;

  /// The logging day it is about.
  final String dayKey;

  /// Titles of goals still unlogged — known only for today (later days are
  /// planned without, and refreshed when the app runs).
  final List<String>? openGoals;

  @override
  String toString() => 'PlannedReminder($id, $kind, $at, $openGoals)';
}

/// How many days ahead reminders are scheduled. Opening the app (or the
/// background refresh) re-plans, so they keep coming.
const reminderDaysAhead = 7;

/// Notification ids per kind: base + day slot (0..[reminderDaysAhead]-1).
const eveningIdBase = 100;
const middayIdBase = 200;

/// All ids this feature may use (to cancel before re-planning).
List<int> get allReminderIds => [
  for (var i = 0; i < reminderDaysAhead; i++) ...[
    eveningIdBase + i,
    middayIdBase + i,
  ],
];

/// Plans the next [reminderDaysAhead] days of reminders.
///
/// Today's reminders mention [openToday] (titles of goals still unlogged);
/// when today is already fully logged, today's reminders are skipped. Times
/// already past are skipped. [now] is local time.
List<PlannedReminder> planReminders({
  required ReminderSettings settings,
  required DateTime now,
  required List<String> openToday,
  String? challengeEnd,
}) {
  final out = <PlannedReminder>[];
  final today = todayKey(now);
  final base = parseDayKey(today);
  for (var i = 0; i < reminderDaysAhead; i++) {
    final day = DateTime(base.year, base.month, base.day + i);
    final key = dayKey(day);
    if (challengeEnd != null && key.compareTo(challengeEnd) > 0) break;
    final isToday = key == today;
    if (isToday && openToday.isEmpty) continue;
    for (final (kind, enabled, minutes, idBase) in [
      (
        ReminderKind.midday,
        settings.middayEnabled,
        settings.middayMinutes,
        middayIdBase,
      ),
      (
        ReminderKind.evening,
        settings.eveningEnabled,
        settings.eveningMinutes,
        eveningIdBase,
      ),
    ]) {
      if (!enabled) continue;
      // Times before the day start (e.g. 01:00) belong to the next calendar
      // date of the same logging day.
      final wall = DateTime(
        day.year,
        day.month,
        day.day + (minutes < dayStartHour * 60 ? 1 : 0),
        minutes ~/ 60,
        minutes % 60,
      );
      if (!wall.isAfter(now)) continue;
      out.add(
        PlannedReminder(
          id: idBase + i,
          kind: kind,
          at: wall,
          dayKey: key,
          openGoals: isToday ? openToday : null,
        ),
      );
    }
  }
  return out;
}
