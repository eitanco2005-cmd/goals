import 'package:flutter/foundation.dart' show debugPrint;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/repositories.dart';
import '../../domain/goal_eval.dart';
import '../../domain/models.dart';
import '../photos/photo_providers.dart';

/// Who/where/when today's logging applies to. Null until signed in and paired.
typedef TodayScope = ({String pairId, String uid, String date});

final todayScopeProvider = Provider<TodayScope?>((ref) {
  final uid = ref.watch(authStateProvider.select((a) => a.value?.uid));
  final pairId = ref.watch(profileProvider.select((p) => p.value?.pairId));
  final date = ref.watch(todayKeyProvider);
  if (uid == null || pairId == null) return null;
  return (pairId: pairId, uid: uid, date: date);
});

/// My own private log for today, straight from the repository.
final myTodayLogStreamProvider = StreamProvider<DailyLog?>((ref) {
  final scope = ref.watch(todayScopeProvider);
  if (scope == null) return Stream.value(null);
  return ref
      .watch(logRepositoryProvider)
      .watchDailyLog(pairId: scope.pairId, uid: scope.uid, date: scope.date);
});

/// Writes today's values and keeps them as optimistic overrides, so rapid
/// taps never read a stale value and the UI updates on the same frame as the
/// tap.
///
/// An override is dropped as soon as the repository stream shows its value,
/// when its write fails, or, once its write succeeded, on the stream's next
/// emission whatever it contains (so another device's later update is never
/// masked, and a lagging stream never makes the value flicker back).
///
/// State: goalId -> pending value (a `null` value means "being cleared").
final todayLogControllerProvider =
    NotifierProvider<TodayLogController, Map<String, num?>>(
      TodayLogController.new,
    );

class TodayLogController extends Notifier<Map<String, num?>> {
  /// Id of the latest write per goal, so a settling write only touches its
  /// own override (ids are never reused, even across days).
  final _latestWrite = <String, int>{};
  var _writeCounter = 0;

  /// Goals whose latest write succeeded but the stream hasn't caught up yet.
  final _saved = <String>{};

  @override
  Map<String, num?> build() {
    ref.watch(todayScopeProvider); // new day / user => drop pending values
    _saved.clear();
    ref.listen(myTodayLogStreamProvider, (_, next) {
      final log = next.value;
      if (log == null || state.isEmpty) return;
      bool settled(String id, num? v) =>
          _saved.contains(id) || log.valueOf(id) == v;
      if (state.entries.any((e) => settled(e.key, e.value))) {
        state = {...state}..removeWhere(settled);
      }
      _saved.clear();
    });
    return const {};
  }

  /// Sets (or clears, with null) today's value for [goalId].
  Future<void> setValue(String goalId, num? value) async {
    final scope = ref.read(todayScopeProvider);
    final dailyGoals = ref.read(challengeProvider).value?.dailyGoals;
    if (scope == null || dailyGoals == null) return;
    final write = _latestWrite[goalId] = ++_writeCounter;
    _saved.remove(goalId);
    state = {...state, goalId: value};
    try {
      await ref
          .read(logRepositoryProvider)
          .setGoalValue(
            pairId: scope.pairId,
            uid: scope.uid,
            date: scope.date,
            goalId: goalId,
            value: value,
            dailyGoals: dailyGoals,
            photoGoalIds: ref.read(myTodayPhotoGoalIdsProvider),
          );
      if (ref.mounted && _latestWrite[goalId] == write) _saved.add(goalId);
    } catch (_) {
      if (ref.mounted && _latestWrite[goalId] == write) {
        state = {...state}..remove(goalId);
      }
      rethrow;
    }
  }
}

/// Log writes that failed after they were reported as done (e.g. rejected
/// later by the server), to tell the user about.
final logWriteErrorsProvider = StreamProvider<AppException>(
  (ref) => ref.watch(logRepositoryProvider).writeErrors,
);

/// Today's log as the UI should show it: repository data + pending writes.
final todayLogProvider = Provider<AsyncValue<DailyLog?>>((ref) {
  final pending = ref.watch(todayLogControllerProvider);
  return ref.watch(myTodayLogStreamProvider).whenData((log) {
    if (log == null) return null;
    var merged = log;
    for (final e in pending.entries) {
      merged = merged.withValue(e.key, e.value);
    }
    return merged;
  });
});

/// My summary for today, computed live from [todayLogProvider].
final myTodaySummaryProvider = Provider<DaySummary?>((ref) {
  final log = ref.watch(todayLogProvider).value;
  final challenge = ref.watch(challengeProvider).value;
  if (log == null || challenge == null) return null;
  return summarizeDay(
    log,
    challenge.dailyGoals,
    photoGoalIds: ref.watch(myTodayPhotoGoalIdsProvider),
  );
});

/// A group member's PUBLIC summary for today (summary-only visibility: other
/// members' DailyLogs are never read). Null until they log something.
final memberTodaySummaryProvider = StreamProvider.family<DaySummary?, String>((
  ref,
  uid,
) {
  final scope = ref.watch(todayScopeProvider);
  if (scope == null) return Stream.value(null);
  return ref
      .watch(logRepositoryProvider)
      .watchDaySummary(pairId: scope.pairId, uid: uid, date: scope.date);
});

/// Whether the demo-mode banner was dismissed (for this app session).
final demoBannerDismissedProvider = NotifierProvider<DemoBannerDismissed, bool>(
  DemoBannerDismissed.new,
);

class DemoBannerDismissed extends Notifier<bool> {
  @override
  bool build() => false;
  void dismiss() => state = true;
}

/// Keeps my published summary of today in step with my photos: adding or
/// deleting the photo of a goal that requires one changes whether it counts
/// (logging values already writes the summary itself). Watched by the home
/// shell.
final mySummarySyncProvider = Provider<void>((ref) {
  final scope = ref.watch(todayScopeProvider);
  final mine = ref.watch(myTodaySummaryProvider);
  final hasLog = ref.watch(todayLogProvider).hasValue;
  if (scope == null || mine == null || !hasLog) return;
  final stored = ref.watch(memberTodaySummaryProvider(scope.uid));
  if (!stored.hasValue) return;
  final current = stored.value;
  // Nothing logged and nothing published: nothing to correct.
  if (current == null &&
      mine.statuses.values.every((s) => s == GoalStatus.unlogged)) {
    return;
  }
  if (current != null && _sameSummary(current, mine)) return;
  final repo = ref.watch(logRepositoryProvider);
  final timer = Timer(const Duration(milliseconds: 800), () {
    repo
        .writeDaySummary(pairId: scope.pairId, summary: mine)
        .catchError((Object e) => debugPrint('summary not saved: $e'));
  });
  ref.onDispose(timer.cancel);
});

bool _sameSummary(DaySummary a, DaySummary b) =>
    a.percent == b.percent &&
    a.statuses.length == b.statuses.length &&
    a.statuses.entries.every((e) => b.statuses[e.key] == e.value);
