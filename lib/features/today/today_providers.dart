import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../domain/goal_eval.dart';
import '../../domain/models.dart';

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

/// Writes today's values and keeps them as optimistic overrides until the
/// repository stream confirms them, so rapid taps never read a stale value
/// and the UI updates on the same frame as the tap.
///
/// State: goalId -> pending value (a `null` value means "being cleared").
final todayLogControllerProvider =
    NotifierProvider<TodayLogController, Map<String, num?>>(
      TodayLogController.new,
    );

class TodayLogController extends Notifier<Map<String, num?>> {
  @override
  Map<String, num?> build() {
    ref.watch(todayScopeProvider); // new day / user => drop pending values
    ref.listen(myTodayLogStreamProvider, (_, next) {
      final log = next.value;
      if (log == null || state.isEmpty) return;
      bool confirmed(String id, num? v) => log.valueOf(id) == v;
      if (state.entries.any((e) => confirmed(e.key, e.value))) {
        state = {...state}..removeWhere(confirmed);
      }
    });
    return const {};
  }

  /// Sets (or clears, with null) today's value for [goalId].
  Future<void> setValue(String goalId, num? value) async {
    final scope = ref.read(todayScopeProvider);
    final dailyGoals = ref.read(challengeProvider).value?.dailyGoals;
    if (scope == null || dailyGoals == null) return;
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
          );
    } catch (_) {
      if (ref.mounted && state.containsKey(goalId) && state[goalId] == value) {
        state = {...state}..remove(goalId);
      }
      rethrow;
    }
  }
}

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
  return summarizeDay(log, challenge.dailyGoals);
});

/// The partner's PUBLIC summary for today (summary-only visibility: the
/// partner's DailyLog is never read). Null if they haven't joined or logged.
final partnerTodaySummaryProvider = StreamProvider<DaySummary?>((ref) {
  final partnerUid = ref.watch(partnerUidProvider);
  final scope = ref.watch(todayScopeProvider);
  if (partnerUid == null || scope == null) return Stream.value(null);
  return ref
      .watch(logRepositoryProvider)
      .watchDaySummary(pairId: scope.pairId, uid: partnerUid, date: scope.date);
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
