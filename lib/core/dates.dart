/// Date helpers. Days are identified everywhere by a `yyyy-MM-dd` key in the
/// user's local time zone, so "today" matches what the person sees.
library;

import '../domain/models.dart';

/// Hour (local time) at which a new logging day begins.
///
/// Until 04:00 "today" is still the previous calendar date, so logging
/// reading in bed at 00:30 counts for the evening it belongs to. Only
/// [todayKey] (and the rollover in `TodayKeyNotifier`) apply this offset;
/// [dayKey] and the week helpers stay pure calendar-date functions.
const dayStartHour = 4;

/// Pure `yyyy-MM-dd` formatter for the calendar date of [d].
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDayKey(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

/// The logging day at [now] (default: the current time): the calendar date,
/// or the previous one before [dayStartHour].
String todayKey([DateTime? now]) {
  final n = now ?? DateTime.now();
  return dayKey(DateTime(n.year, n.month, n.day, n.hour - dayStartHour));
}

/// The next moment (strictly after [now]) a new logging day starts.
DateTime nextDayStart(DateTime now) {
  final sameDay = DateTime(now.year, now.month, now.day, dayStartHour);
  return sameDay.isAfter(now)
      ? sameDay
      : DateTime(now.year, now.month, now.day + 1, dayStartHour);
}

/// Start of the week containing [d]. Weeks start on Sunday (Israeli week).
DateTime weekStart(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday % 7));
}

/// All day keys of the week containing [d], Sunday..Saturday.
List<String> weekDayKeys(DateTime d) {
  final s = weekStart(d);
  return [
    for (var i = 0; i < 7; i++) dayKey(DateTime(s.year, s.month, s.day + i)),
  ];
}

/// Inclusive list of day keys between two keys.
List<String> dayKeysBetween(String from, String to) {
  final start = parseDayKey(from);
  final end = parseDayKey(to);
  final out = <String>[];
  for (
    var d = start;
    !d.isAfter(end);
    d = DateTime(d.year, d.month, d.day + 1)
  ) {
    out.add(dayKey(d));
  }
  return out;
}

/// Where a given day falls inside a challenge's date range.
class ChallengeDay {
  const ChallengeDay({required this.day, required this.total});

  /// 1-based index of the day. `< 1` before the start, `> total` after the end.
  final int day;

  /// Number of days in the challenge (inclusive range).
  final int total;

  bool get notStarted => day < 1;
  bool get ended => day > total;
  bool get inProgress => !notStarted && !ended;

  /// Days left until day 1 (only meaningful when [notStarted]).
  int get daysUntilStart => 1 - day;

  @override
  bool operator ==(Object other) =>
      other is ChallengeDay && other.day == day && other.total == total;

  @override
  int get hashCode => Object.hash(day, total);

  @override
  String toString() => 'ChallengeDay($day/$total)';
}

/// Computes "day X of Y" from `yyyy-MM-dd` keys. Uses UTC day ordinals so
/// daylight-saving transitions never skew the count.
ChallengeDay challengeDay({
  required String startDate,
  required String endDate,
  required String today,
}) {
  int ordinal(String key) {
    final d = parseDayKey(key);
    return DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  final start = ordinal(startDate);
  return ChallengeDay(
    day: ordinal(today) - start + 1,
    total: ordinal(endDate) - start + 1,
  );
}

/// Where [today] falls inside [challenge].
ChallengeDay challengeProgress(Challenge challenge, String today) =>
    challengeDay(
      startDate: challenge.startDate,
      endDate: challenge.endDate,
      today: today,
    );
