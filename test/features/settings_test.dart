import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/features/pairing/pairing_screen.dart';
import 'package:goals_challenge/data/repositories.dart';
import 'package:goals_challenge/features/auth/sign_in_screen.dart';
import 'package:goals_challenge/features/pairing/invite_code_card.dart';
import 'package:goals_challenge/features/settings/settings_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pumpAndSettle();
  expect(find.byType(SettingsScreen), findsOneWidget);
}

void main() {
  testWidgets('shows members, dates, goal editing and new round', (
    tester,
  ) async {
    await pumpApp(tester, await signedInPairedBackend());
    await _openSettings(tester);

    expect(find.text('Me'), findsOneWidget);
    expect(find.text('Members (2/8)'), findsOneWidget);
    expect(find.text('Noa'), findsOneWidget);
    // The group has room, so the code to invite more people stays visible.
    expect(find.byType(InviteCodeCard), findsOneWidget);
    expect(find.textContaining('Day 21 of 90'), findsOneWidget);
    await scrollToCenter(tester, find.text('Start a new round'));
    expect(find.widgetWithText(ListTile, 'Edit goals'), findsOneWidget);
  });

  testWidgets('solo pair shows waiting state and the invite code', (
    tester,
  ) async {
    final backend = await signedInSoloBackend();
    await pumpApp(tester, backend);
    await _openSettings(tester);

    expect(find.text('No one else has joined yet'), findsOneWidget);
    expect(find.text('Members (1/8)'), findsOneWidget);
    expect(find.byType(InviteCodeCard), findsWidgets);
    expect(find.text('Jan 1, 2026 – Dec 31, 2026'), findsOneWidget);
  });

  testWidgets('language switch flips the app to Hebrew RTL and back', (
    tester,
  ) async {
    final backend = await signedInPairedBackend();
    await pumpApp(tester, backend);
    await _openSettings(tester);
    TextDirection dir() =>
        Directionality.of(tester.element(find.byType(SettingsScreen)));
    expect(dir(), TextDirection.ltr);

    await tester.tap(find.text('עברית'));
    await tester.pumpAndSettle();
    expect(dir(), TextDirection.rtl);
    expect(find.text('הגדרות'), findsWidgets);
    final profile = await backend.watchProfile(backend.currentUser!.uid).first;
    expect(profile!.languageCode, 'he');

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(dir(), TextDirection.ltr);
  });

  testWidgets('edit display name via dialog', (tester) async {
    final backend = await signedInPairedBackend();
    await pumpApp(tester, backend);
    await _openSettings(tester);

    await tester.tap(find.byTooltip('Edit name'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Dana');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Dana'), findsOneWidget);
    final profile = await backend.watchProfile(backend.currentUser!.uid).first;
    expect(profile!.displayName, 'Dana');
  });

  testWidgets('sign out asks for confirmation and returns to sign-in', (
    tester,
  ) async {
    await pumpApp(tester, await signedInPairedBackend());
    await _openSettings(tester);

    await scrollToCenter(tester, find.widgetWithText(ListTile, 'Sign out'));
    await tester.tap(find.widgetWithText(ListTile, 'Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);

    // Cancel keeps the user signed in.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, 'Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    // The language chosen in the profile survives sign-out.
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('make a new invite code; the old one stops working', (
    tester,
  ) async {
    final b = await signedInPairedBackend();
    await pumpApp(tester, b);
    await _openSettings(tester);
    expect(find.text('DEMO42'), findsOneWidget);
    await scrollToCenter(tester, find.text('Make a new invite code'));
    await tester.tap(find.text('Make a new invite code'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make new code'));
    await tester.pumpAndSettle();

    final code = (await b.watchPair('demo-pair').first)!.inviteCode;
    expect(code, isNot('DEMO42'));
    expect(find.text('New invite code: $code'), findsOneWidget);

    final other = await b.signUp(
      email: 'x@x.com',
      password: 'secret1',
      displayName: 'X',
      languageCode: 'en',
    );
    await expectLater(
      b.joinPair(uid: other.uid, displayName: 'X', code: 'DEMO42'),
      throwsA(isA<AppException>()),
    );
  });

  testWidgets('leave the challenge (with confirmation)', (tester) async {
    final b = await signedInPairedBackend();
    final me = b.currentUser!.uid;
    await pumpApp(tester, b);
    await _openSettings(tester);
    await scrollToCenter(tester, find.text('Leave the challenge'));
    await tester.tap(find.text('Leave the challenge'));
    await tester.pumpAndSettle();
    expect(find.text('Leave the challenge?'), findsOneWidget);
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(find.byType(PairingScreen), findsOneWidget);
    final pair = (await b.watchPair('demo-pair').first)!;
    expect(pair.memberUids, isNot(contains(me)));
    expect((await b.watchProfile(me).first)!.pairId, isNull);
  });
}
