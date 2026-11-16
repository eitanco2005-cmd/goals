import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/providers.dart';
import '../../domain/goal_eval.dart';
import '../../domain/models.dart';

/// Day keys (Sunday..Saturday) of the week starting [weekStartKey].
List<String> daysOfWeek(String weekStartKey) =>
    weekDayKeys(parseDayKey(weekStartKey));

/// The Sunday of the week containing the current logging day.
String currentWeekStart([DateTime? now]) =>
    dayKey(weekStart(parseDayKey(todayKey(now))));

/// The week shown on the Week tab (its Sunday), plus the selected day in it.
final selectedWeekProvider =
    NotifierProvider<SelectedWeek, ({String week, String day})>(
      SelectedWeek.new,
    );

class SelectedWeek extends Notifier<({String week, String day})> {
  @override
  ({String week, String day}) build() {
    final today = ref.watch(todayKeyProvider);
    return (week: dayKey(weekStart(parseDayKey(today))), day: today);
  }

  /// Moves by [weeks] (negative = back), never past the current week.
  void shift(int weeks) {
    final today = ref.read(todayKeyProvider);
    final start = parseDayKey(state.week);
    final next = dayKey(
      DateTime(start.year, start.month, start.day + 7 * weeks),
    );
    final current = dayKey(weekStart(parseDayKey(today)));
    if (next.compareTo(current) > 0) return;
    final days = daysOfWeek(next);
    // Keep the same weekday, but never select a future day.
    final index = daysOfWeek(state.week).indexOf(state.day).clamp(0, 6);
    var day = days[index];
    if (day.compareTo(today) > 0) day = today;
    state = (week: next, day: day);
  }

  void selectDay(String day) {
    if (day.compareTo(ref.read(todayKeyProvider)) > 0) return;
    if (!daysOfWeek(state.week).contains(day)) return;
    state = (week: state.week, day: day);
  }
}

/// My private log of one day (any day, not only today).
final myDayLogProvider = StreamProvider.family<DailyLog, String>((ref, date) {
  final uid = ref.watch(authStateProvider.select((a) => a.value?.uid));
  final pairId = ref.watch(profileProvider.select((p) => p.value?.pairId));
  if (uid == null || pairId == null) {
    return Stream.value(DailyLog(uid: uid ?? '', date: date));
  }
  return ref
      .watch(logRepositoryProvider)
      .watchDailyLog(pairId: pairId, uid: uid, date: date);
});

/// My workouts in the week starting [week], oldest first.
final myWeekWorkoutsProvider =
    StreamProvider.family<List<WorkoutEntry>, String>((ref, week) {
      final uid = ref.watch(authStateProvider.select((a) => a.value?.uid));
      final pairId = ref.watch(profileProvider.select((p) => p.value?.pairId));
      if (uid == null || pairId == null) return Stream.value(const []);
      final days = daysOfWeek(week);
      return ref
          .watch(logRepositoryProvider)
          .watchWorkouts(
            pairId: pairId,
            uid: uid,
            from: days.first,
            to: days.last,
          );
    });

/// Totals of my logged values over the week (e.g. junk food), or null while
/// any day is still loading.
final myWeekTotalsProvider = Provider.family<Map<String, num>?, String>((
  ref,
  week,
) {
  final logs = [
    for (final d in daysOfWeek(week)) ref.watch(myDayLogProvider(d)),
  ];
  if (logs.any((l) => !l.hasValue)) return null;
  return sumLogs([for (final l in logs) l.value!]);
});

/// My week summary computed from my private data, or null while loading.
final myWeekSummaryProvider = Provider.family<WeekSummary?, String>((
  ref,
  week,
) {
  final uid = ref.watch(authStateProvider.select((a) => a.value?.uid));
  final challenge = ref.watch(challengeProvider).value;
  final workouts = ref.watch(myWeekWorkoutsProvider(week));
  final totals = ref.watch(myWeekTotalsProvider(week));
  if (uid == null ||
      challenge == null ||
      !workouts.hasValue ||
      totals == null) {
    return null;
  }
  return summarizeWeek(
    uid: uid,
    weekStart: week,
    weeklyGoals: challenge.weeklyGoals,
    workouts: workouts.value!,
    totals: totals,
  );
});

/// Everyone's published week summaries (what the group can see).
final weekSummariesProvider = StreamProvider.family<List<WeekSummary>, String>((
  ref,
  week,
) {
  final pairId = ref.watch(profileProvider.select((p) => p.value?.pairId));
  if (pairId == null) return Stream.value(const []);
  return ref
      .watch(logRepositoryProvider)
      .watchWeekSummaries(pairId: pairId, weekStart: week);
});

/// Keeps my published summary of [week] equal to the one computed from my
/// private data. Watched for the current week by the home shell and for the
/// shown week by the Week tab, so edits from anywhere are published.
final weekSummaryPublisherProvider = Provider.family<void, String>((ref, week) {
  final mine = ref.watch(myWeekSummaryProvider(week));
  final published = ref.watch(weekSummariesProvider(week));
  final pairId = ref.watch(profileProvider.select((p) => p.value?.pairId));
  if (mine == null || pairId == null || !published.hasValue) return;
  final current = published.value!.where((s) => s.uid == mine.uid).firstOrNull;
  if (current == mine) return;
  final repo = ref.watch(logRepositoryProvider);
  final timer = Timer(const Duration(milliseconds: 600), () {
    repo.setWeekSummary(pairId: pairId, summary: mine).catchError((Object e) {
      debugPrint('week summary not saved: $e');
    });
  });
  ref.onDispose(timer.cancel);
});
