import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/app.dart';
import 'package:goals_challenge/core/providers.dart';
import 'package:goals_challenge/data/memory/memory_backend.dart';
import 'package:goals_challenge/domain/default_goals.dart';
import 'package:material_ui/material_ui.dart';

List<Override> memoryOverrides(MemoryBackend b, {bool demo = false}) => [
      isDemoModeProvider.overrideWithValue(demo),
      authRepositoryProvider.overrideWithValue(b),
      profileRepositoryProvider.overrideWithValue(b),
      pairRepositoryProvider.overrideWithValue(b),
      challengeRepositoryProvider.overrideWithValue(b),
      logRepositoryProvider.overrideWithValue(b),
      photoRepositoryProvider.overrideWithValue(b),
    ];

/// Pumps the full app (router included) on top of [backend].
Future<void> pumpApp(WidgetTester tester, MemoryBackend backend,
    {Size size = const Size(400, 860)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
      overrides: memoryOverrides(backend), child: const GoalsApp()));
  await tester.pumpAndSettle();
}

/// A backend where 'me@x.com' is signed in and paired with the demo partner.
Future<MemoryBackend> signedInPairedBackend({String languageCode = 'en'}) async {
  final b = MemoryBackend(seedDemo: true);
  final u = await b.signUp(
      email: 'me@x.com',
      password: 'secret1',
      displayName: 'Me',
      languageCode: languageCode);
  await b.joinPair(
      uid: u.uid, displayName: 'Me', code: MemoryBackend.demoInviteCode);
  return b;
}

/// A signed-in user with their own (not yet joined) pair.
Future<MemoryBackend> signedInSoloBackend({String languageCode = 'en'}) async {
  final b = MemoryBackend();
  final u = await b.signUp(
      email: 'me@x.com',
      password: 'secret1',
      displayName: 'Me',
      languageCode: languageCode);
  await b.createPair(
      uid: u.uid,
      displayName: 'Me',
      startDate: '2026-01-01',
      endDate: '2026-12-31',
      goals: defaultGoals);
  return b;
}
