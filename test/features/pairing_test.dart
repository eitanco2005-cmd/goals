import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/data/memory/memory_backend.dart';
import 'package:goals_challenge/features/pairing/invite_code_card.dart';
import 'package:goals_challenge/features/pairing/pairing_screen.dart';
import 'package:goals_challenge/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

/// A signed-in user ('en') without a pair, so the app shows pairing.
Future<MemoryBackend> _unpairedBackend({bool seedDemo = false}) async {
  final b = MemoryBackend(seedDemo: seedDemo);
  await b.signUp(
      email: 'me@x.com',
      password: 'secret1',
      displayName: 'Me',
      languageCode: 'en');
  return b;
}

void main() {
  testWidgets('create a challenge → app shows the tabs (Today)',
      (tester) async {
    final backend = await _unpairedBackend();
    await pumpApp(tester, backend);
    expect(find.byType(PairingScreen), findsOneWidget);

    await tester.tap(find.text('Start a new challenge'));
    await tester.pumpAndSettle();
    expect(find.text('💧 8 glasses of water'), findsOneWidget);
    expect(find.text('You can edit the goals later.'), findsOneWidget);

    await tester.tap(find.text('90 days'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create challenge'));
    await tester.tap(find.text('Create challenge'));
    await tester.pumpAndSettle();

    expect(find.byType(PairingScreen), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Today'), findsWidgets);

    final profile = await backend.watchProfile(backend.currentUser!.uid).first;
    final challenge =
        await backend.watchActiveChallenge(profile!.pairId!).first;
    expect(challenge!.goals, isNotEmpty);
    final days = DateTime.parse(challenge.endDate)
            .difference(DateTime.parse(challenge.startDate))
            .inDays +
        1;
    expect(days, 90);
  });

  testWidgets('join with DEMO42 pairs with the demo partner', (tester) async {
    final backend = await _unpairedBackend(seedDemo: true);
    await pumpApp(tester, backend);

    await tester.tap(find.text('Join with a code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'demo42');
    await tester.pump();
    expect(find.text('DEMO42'), findsOneWidget); // auto uppercased

    await tester.tap(find.text('Join challenge'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    final pair = await backend.watchPair('demo-pair').first;
    expect(pair!.memberUids, contains(backend.currentUser!.uid));
  });

  testWidgets('invalid or short code shows a localized error', (tester) async {
    final backend = await _unpairedBackend(seedDemo: true);
    await pumpApp(tester, backend);
    await tester.tap(find.text('Join with a code'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'ABC');
    await tester.tap(find.text('Join challenge'));
    await tester.pumpAndSettle();
    expect(find.text('The code has 6 characters'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'ZZZZZZ');
    await tester.tap(find.text('Join challenge'));
    await tester.pumpAndSettle();
    expect(find.text('No challenge found with this code'), findsOneWidget);
    expect(find.byType(PairingScreen), findsOneWidget);
  });

  testWidgets('back from a mode returns to the two choices', (tester) async {
    await pumpApp(tester, await _unpairedBackend());
    await tester.tap(find.text('Join with a code'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Start a new challenge'), findsOneWidget);
    expect(find.text('Join with a code'), findsOneWidget);
  });

  testWidgets('pairing screen fits a narrow phone in Hebrew', (tester) async {
    final b = MemoryBackend();
    await b.signUp(
        email: 'me@x.com',
        password: 'secret1',
        displayName: 'Me',
        languageCode: 'he');
    await pumpApp(tester, b, size: const Size(360, 640));
    await tester.tap(find.text('פתיחת אתגר חדש'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('🥗 ירקות בכל ארוחה'), findsOneWidget);
  });

  testWidgets('InviteCodeCard copies the code to the clipboard',
      (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: InviteCodeCard(code: 'AB12CD')),
    ));
    expect(find.text('AB12CD'), findsOneWidget);
    await tester.tap(find.text('Copy'));
    await tester.pump();
    expect(copied, 'AB12CD');
    expect(find.text('Code copied'), findsOneWidget);
  });
}
