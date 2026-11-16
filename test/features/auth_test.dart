import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/app.dart';
import 'package:goals_challenge/data/memory/memory_backend.dart';
import 'package:goals_challenge/features/auth/sign_in_screen.dart';
import 'package:goals_challenge/features/auth/sign_up_screen.dart';
import 'package:goals_challenge/features/pairing/pairing_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

TextDirection _direction(WidgetTester tester) =>
    Directionality.of(tester.element(find.byType(SignInScreen)));

void main() {
  testWidgets('starts in Hebrew (RTL) and the switch flips to English (LTR)',
      (tester) async {
    await pumpApp(tester, MemoryBackend());

    expect(find.text('טוב שחזרתם'), findsOneWidget);
    expect(_direction(tester), TextDirection.rtl);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(_direction(tester), TextDirection.ltr);

    await tester.tap(find.text('עברית'));
    await tester.pumpAndSettle();
    expect(_direction(tester), TextDirection.rtl);
  });

  testWidgets('sign-up flow lands on the pairing screen with chosen language',
      (tester) async {
    final backend = MemoryBackend();
    await pumpApp(tester, backend);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpScreen), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Your name'), 'Dana');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'dana@x.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'secret1');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.byType(PairingScreen), findsOneWidget);
    expect(find.text("Hi Dana! Let's get started"), findsOneWidget);
    final uid = backend.currentUser!.uid;
    final profile = await backend.watchProfile(uid).first;
    expect(profile!.languageCode, 'en');
  });

  testWidgets('sign-up validates fields with localized messages',
      (tester) async {
    await pumpApp(tester, MemoryBackend());
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'not-an-email');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Invalid email address'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    expect(find.byType(SignUpScreen), findsOneWidget);
  });

  testWidgets('sign-up rejects names longer than 100 characters',
      (tester) async {
    final backend = MemoryBackend();
    await pumpApp(tester, backend);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Your name'), 'a' * 101);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'dana@x.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'secret1');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Name can be at most 100 characters'), findsOneWidget);
    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(backend.currentUser, isNull);
  });

  testWidgets('wrong password shows a localized error (Hebrew)',
      (tester) async {
    final backend = MemoryBackend();
    await backend.signUp(
        email: 'me@x.com',
        password: 'secret1',
        displayName: 'Me',
        languageCode: 'he');
    await backend.signOut();
    await pumpApp(tester, backend);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'אימייל'), 'me@x.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'סיסמה'), 'wrong-pass');
    await tester.tap(find.widgetWithText(FilledButton, 'התחברות'));
    await tester.pumpAndSettle();

    expect(find.text('אימייל או סיסמה שגויים'), findsOneWidget);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('correct sign-in of a paired user lands on Today',
      (tester) async {
    final backend = await signedInPairedBackend();
    await backend.signOut();
    await pumpApp(tester, backend);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'me@x.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'), 'secret1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
  });

  testWidgets('forgot password needs an email, then confirms', (tester) async {
    await pumpApp(tester, MemoryBackend());
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot password?'));
    await tester.pump();
    expect(find.textContaining('Enter a valid email above'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'me@x.com');
    await tester.tap(find.text('Forgot password?'));
    await tester.pump();
    expect(find.text('We sent a password reset link to me@x.com'),
        findsOneWidget);
  });

  testWidgets('demo banner is shown in demo mode', (tester) async {
    final backend = MemoryBackend(seedDemo: true);
    await tester.pumpWidget(ProviderScope(
        overrides: memoryOverrides(backend, demo: true),
        child: const GoalsApp()));
    await tester.pumpAndSettle();
    expect(find.textContaining(MemoryBackend.demoInviteCode), findsOneWidget);
  });

  testWidgets('auth screens fit a narrow phone without overflow',
      (tester) async {
    await pumpApp(tester, MemoryBackend(), size: const Size(360, 640));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('צרו חשבון'));
    await tester.tap(find.text('צרו חשבון'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(SignUpScreen), findsOneWidget);
  });
}
