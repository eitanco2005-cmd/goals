/// Date helpers. Days are identified everywhere by a `yyyy-MM-dd` key in the
/// user's local time zone, so "today" matches what the person sees.
library;

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDayKey(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String todayKey([DateTime? now]) => dayKey(now ?? DateTime.now());

/// Start of the week containing [d]. Weeks start on Sunday (Israeli week).
DateTime weekStart(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday % 7));
}

/// All day keys of the week containing [d], Sunday..Saturday.
List<String> weekDayKeys(DateTime d) {
  final s = weekStart(d);
  return [for (var i = 0; i < 7; i++) dayKey(DateTime(s.year, s.month, s.day + i))];
}

/// Inclusive list of day keys between two keys.
List<String> dayKeysBetween(String from, String to) {
  final start = parseDayKey(from);
  final end = parseDayKey(to);
  final out = <String>[];
  for (var d = start; !d.isAfter(end); d = DateTime(d.year, d.month, d.day + 1)) {
    out.add(dayKey(d));
  }
  return out;
}
