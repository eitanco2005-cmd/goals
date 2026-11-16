import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/data/memory/memory_backend.dart';
import 'package:goals_challenge/data/repositories.dart';
import 'package:goals_challenge/domain/default_goals.dart';
import 'package:goals_challenge/domain/models.dart';

void main() {
  test('sign up, create pair, partner joins, logs sync to summaries', () async {
    final b = MemoryBackend();
    final a = await b.signUp(
        email: 'a@x.com', password: 'secret1', displayName: 'A', languageCode: 'he');
    final pair = await b.createPair(
        uid: a.uid,
        displayName: 'A',
        startDate: '2026-11-15',
        endDate: '2026-12-14',
        goals: defaultGoals);
    expect(pair.inviteCode, hasLength(6));
    expect(pair.isComplete, isFalse);

    await b.signOut();
    final c = await b.signUp(
        email: 'c@x.com', password: 'secret1', displayName: 'C', languageCode: 'en');
    await expectLater(
        b.joinPair(uid: c.uid, displayName: 'C', code: 'nope00'),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'invalid-code')));
    final joined = await b.joinPair(
        uid: c.uid, displayName: 'C', code: pair.inviteCode.toLowerCase());
    expect(joined.isComplete, isTrue);
    expect(joined.partnerOf(c.uid), a.uid);

    final challenge = (await b.watchActiveChallenge(pair.id).first)!;
    await b.setGoalValue(
        pairId: pair.id,
        uid: c.uid,
        date: '2026-11-15',
        goalId: GoalIds.water,
        value: 8,
        dailyGoals: challenge.dailyGoals);
    final summary = await b
        .watchDaySummary(pairId: pair.id, uid: c.uid, date: '2026-11-15')
        .first;
    expect(summary!.statuses[GoalIds.water], GoalStatus.met);
    expect(summary.percent, 11);
  });

  test('demo seed lets a new user join DEMO42', () async {
    final b = MemoryBackend(seedDemo: true);
    final u = await b.signUp(
        email: 'me@x.com', password: 'secret1', displayName: 'Me', languageCode: 'he');
    final pair = await b.joinPair(
        uid: u.uid, displayName: 'Me', code: MemoryBackend.demoInviteCode);
    expect(pair.isComplete, isTrue);
    final partnerToday = await b.watchSummaries(
            pairId: pair.id, uid: 'demo-partner', from: '2000-01-01', to: '2100-01-01')
        .first;
    expect(partnerToday.length, greaterThan(10));
  });

  test('renaming updates the name the partner sees', () async {
    final b = MemoryBackend(seedDemo: true);
    final u = await b.signUp(
        email: 'me@x.com', password: 'secret1', displayName: 'Me', languageCode: 'he');
    final pair = await b.joinPair(
        uid: u.uid, displayName: 'Me', code: MemoryBackend.demoInviteCode);
    await b.setDisplayName(u.uid, 'Eitan');
    final updated = await b.watchPair(pair.id).first;
    expect(updated!.memberNames[u.uid], 'Eitan');
  });

  test('concurrent setGoalValue calls all land in the summary', () async {
    final b = MemoryBackend();
    const goals = defaultGoals;
    final daily = goals.where((g) => g.period == GoalPeriod.daily).toList();
    Future<void> set(String goalId, num? v) => b.setGoalValue(
        pairId: 'p', uid: 'u', date: '2026-11-15',
        goalId: goalId, value: v, dailyGoals: daily);
    await Future.wait([
      set(GoalIds.water, 8),
      set(GoalIds.reading, 60),
      set(GoalIds.reading, null),
      set(GoalIds.veggies, 1),
    ]);
    final summary = (await b
        .watchDaySummary(pairId: 'p', uid: 'u', date: '2026-11-15')
        .first)!;
    expect(summary.statuses[GoalIds.water], GoalStatus.met);
    expect(summary.statuses[GoalIds.veggies], GoalStatus.met);
    expect(summary.statuses[GoalIds.reading], GoalStatus.unlogged);
  });

  test('clearing a value of a day without a log writes nothing', () async {
    final b = MemoryBackend();
    await b.setGoalValue(
        pairId: 'p', uid: 'u', date: '2026-11-15',
        goalId: GoalIds.water, value: null, dailyGoals: defaultGoals);
    expect(
        await b.watchDaySummary(pairId: 'p', uid: 'u', date: '2026-11-15').first,
        isNull);
  });

  test('sign-up emits the user before the profile exists (like Firebase)',
      () async {
    final b = MemoryBackend();
    final profileWhenSignedIn = b
        .authStateChanges()
        .firstWhere((u) => u != null)
        .then((u) => b.watchProfile(u!.uid).first);
    final u = await b.signUp(
        email: 'a@x.com', password: 'secret1', displayName: 'A', languageCode: 'he');
    expect(await profileWhenSignedIn, isNull);
    expect((await b.watchProfile(u.uid).first)!.displayName, 'A');
  });

  test('ensureProfile re-creates a missing profile', () async {
    final b = MemoryBackend();
    final u = await b.signUp(
        email: 'dana@x.com', password: 'secret1', displayName: 'Dana', languageCode: 'he');
    await b.ensureProfile(u, languageCode: 'en');
    expect((await b.watchProfile(u.uid).first)!.languageCode, 'he');
    b.debugDeleteProfile(u.uid);
    await b.ensureProfile(u, languageCode: 'en');
    final p = (await b.watchProfile(u.uid).first)!;
    expect(p.displayName, 'Dana');
    expect(p.languageCode, 'en');
  });
}
