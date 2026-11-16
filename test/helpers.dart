import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/app.dart';
import 'package:goals_challenge/core/providers.dart';
import 'package:goals_challenge/data/memory/memory_backend.dart';
import 'package:goals_challenge/domain/default_goals.dart';
import 'package:goals_challenge/features/goals/translator.dart';
import 'package:goals_challenge/features/home_access/quick_actions.dart';
import 'package:goals_challenge/features/invite/invite.dart';
import 'package:goals_challenge/features/reminders/reminders.dart';
import 'package:goals_challenge/features/update/update_check.dart';
import 'package:goals_challenge/features/widget/widget_sync.dart';
import 'package:material_ui/material_ui.dart';

List<Override> memoryOverrides(
  MemoryBackend b, {
  bool demo = false,
  WidgetStore? widgetStore,
  LauncherShortcuts? shortcuts,
  ReminderScheduler? reminders,
  IncomingLinks? links,
  int? latestBuild,
  Translator? translator,
}) => [
  isDemoModeProvider.overrideWithValue(demo),
  authRepositoryProvider.overrideWithValue(b),
  profileRepositoryProvider.overrideWithValue(b),
  pairRepositoryProvider.overrideWithValue(b),
  challengeRepositoryProvider.overrideWithValue(b),
  logRepositoryProvider.overrideWithValue(b),
  photoRepositoryProvider.overrideWithValue(b),
  // No native home-screen widget under test (tests run as Android).
  widgetStoreProvider.overrideWithValue(widgetStore),
  launcherShortcutsProvider.overrideWithValue(shortcuts),
  reminderSchedulerProvider.overrideWithValue(reminders),
  // No network in tests.
  latestBuildProvider.overrideWith((ref) async => latestBuild),
  incomingLinksProvider.overrideWithValue(links),
  // No network in tests: goal names aren't translated unless a test says so.
  translatorProvider.overrideWithValue(translator ?? const NoTranslator()),
];

/// A translator that never translates (as if offline).
class NoTranslator implements Translator {
  const NoTranslator();
  @override
  Future<String?> translate(
    String text, {
    required String from,
    required String to,
  }) async => null;
}

/// Translates from a fixed table, recording what it was asked.
class FakeTranslator implements Translator {
  FakeTranslator(this.table);
  final Map<String, String> table;
  final asked = <String>[];
  @override
  Future<String?> translate(
    String text, {
    required String from,
    required String to,
  }) async {
    asked.add('$from>$to:$text');
    return table[text];
  }
}

/// Pumps the full app (router included) on top of [backend].
Future<void> pumpApp(
  WidgetTester tester,
  MemoryBackend backend, {
  Size size = const Size(400, 860),
  Translator? translator,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: memoryOverrides(backend, translator: translator),
      child: const GoalsApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// A backend where 'me@x.com' is signed in and paired with the demo partner.
Future<MemoryBackend> signedInPairedBackend({
  String languageCode = 'en',
}) async {
  final b = MemoryBackend(seedDemo: true);
  final u = await b.signUp(
    email: 'me@x.com',
    password: 'secret1',
    displayName: 'Me',
    languageCode: languageCode,
  );
  await b.joinPair(
    uid: u.uid,
    displayName: 'Me',
    code: MemoryBackend.demoInviteCode,
  );
  return b;
}

/// A signed-in user with their own (not yet joined) pair.
Future<MemoryBackend> signedInSoloBackend({String languageCode = 'en'}) async {
  final b = MemoryBackend();
  final u = await b.signUp(
    email: 'me@x.com',
    password: 'secret1',
    displayName: 'Me',
    languageCode: languageCode,
  );
  await b.createPair(
    uid: u.uid,
    displayName: 'Me',
    startDate: '2026-01-01',
    endDate: '2026-12-31',
    goals: defaultGoals,
  );
  return b;
}

/// Scrolls [finder] into the middle of its scrollable (so taps don't land
/// under the bottom navigation), building lazily-built list items first.
Future<void> scrollToCenter(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(finder.first), alignment: 0.5);
  await tester.pumpAndSettle();
}
