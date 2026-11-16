import 'package:flutter_test/flutter_test.dart';
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
  testWidgets('shows members, dates and a disabled edit-goals tile', (
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
    final editGoals = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Edit goals'),
    );
    expect(editGoals.enabled, isFalse);
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

    await tester.scrollUntilVisible(
      find.widgetWithText(ListTile, 'Sign out'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
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
}
