import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goals_challenge/app.dart';
import 'package:goals_challenge/core/router.dart';
import 'package:goals_challenge/data/memory/memory_backend.dart';
import 'package:goals_challenge/data/repositories.dart';
import 'package:goals_challenge/domain/models.dart';
import 'package:goals_challenge/features/auth/sign_in_screen.dart';
import 'package:goals_challenge/features/pairing/pairing_screen.dart';
import 'package:goals_challenge/features/shell/splash_screen.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

/// ensureProfile always fails (e.g. offline, rules rejecting the write).
class _FailingEnsure extends MemoryBackend {
  @override
  Future<void> ensureProfile(AppUser user, {required String languageCode}) =>
      Future.error(const AppException('network'));
}

/// The profile never arrives.
class _HangingProfile extends MemoryBackend {
  @override
  Stream<UserProfile?> watchProfile(String uid) =>
      StreamController<UserProfile?>().stream;
}

void main() {
  group('redirectFor', () {
    String? go(
      String location, {
      bool authLoading = false,
      bool signedIn = true,
      ProfileStatus profile = ProfileStatus.ready,
      bool hasPair = true,
    }) => redirectFor(
      location: location,
      authLoading: authLoading,
      signedIn: signedIn,
      profile: profile,
      hasPair: hasPair,
    );

    test('auth loading -> splash', () {
      expect(
        go(Routes.today, authLoading: true, signedIn: false),
        Routes.splash,
      );
      expect(go(Routes.splash, authLoading: true, signedIn: false), isNull);
    });

    test('signed out -> sign in, auth pages allowed', () {
      for (final loc in [Routes.splash, Routes.today, Routes.pair]) {
        expect(go(loc, signedIn: false), Routes.signIn, reason: loc);
      }
      expect(go(Routes.signIn, signedIn: false), isNull);
      expect(go(Routes.signUp, signedIn: false), isNull);
    });

    test('profile loading / missing / error -> splash', () {
      for (final status in [
        ProfileStatus.loading,
        ProfileStatus.missing,
        ProfileStatus.error,
      ]) {
        for (final loc in [Routes.signUp, Routes.pair, Routes.today]) {
          expect(go(loc, profile: status), Routes.splash, reason: '$status');
        }
        expect(go(Routes.splash, profile: status), isNull, reason: '$status');
      }
    });

    test('ready without pair -> pairing', () {
      for (final loc in [Routes.splash, Routes.signUp, Routes.today]) {
        expect(go(loc, hasPair: false), Routes.pair, reason: loc);
      }
      expect(go(Routes.pair, hasPair: false), isNull);
    });

    test('ready with pair -> today, app pages allowed', () {
      for (final loc in [
        Routes.splash,
        Routes.signIn,
        Routes.signUp,
        Routes.pair,
      ]) {
        expect(go(loc), Routes.today, reason: loc);
      }
      for (final loc in [
        Routes.today,
        Routes.week,
        Routes.board,
        Routes.settings,
      ]) {
        expect(go(loc), isNull, reason: loc);
      }
    });
  });

  group('profileStatusOf', () {
    const profile = UserProfile(uid: 'u', displayName: 'U');

    test('classifies the provider state', () {
      expect(profileStatusOf(const AsyncLoading()), ProfileStatus.loading);
      expect(profileStatusOf(const AsyncData(null)), ProfileStatus.missing);
      expect(profileStatusOf(const AsyncData(profile)), ProfileStatus.ready);
      expect(
        profileStatusOf(AsyncError('x', StackTrace.empty)),
        ProfileStatus.error,
      );
    });
  });

  group('splash recovery', () {
    Future<void> pumpOnSplash(WidgetTester tester, MemoryBackend b) async {
      await tester.pumpWidget(
        ProviderScope(overrides: memoryOverrides(b), child: const GoalsApp()),
      );
      await tester.pump();
      await tester.pump();
    }

    Future<AppUser> signUpWithoutProfile(MemoryBackend b) async {
      final u = await b.signUp(
        email: 'dana@x.com',
        password: 'secret1',
        displayName: 'Dana',
        languageCode: 'en',
      );
      b.debugDeleteProfile(u.uid);
      return u;
    }

    testWidgets('a missing profile is created and the user reaches /pair', (
      tester,
    ) async {
      final b = MemoryBackend();
      final u = await signUpWithoutProfile(b);
      await pumpApp(tester, b);

      expect(find.byType(PairingScreen), findsOneWidget);
      final profile = (await b.watchProfile(u.uid).first)!;
      expect(profile.displayName, 'Dana');
      expect(profile.languageCode, 'he'); // the pre-login language
    });

    testWidgets('failing recovery offers Sign out', (tester) async {
      final b = _FailingEnsure();
      await signUpWithoutProfile(b);
      await pumpOnSplash(tester, b);

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('לנסות שוב'), findsOneWidget);
      await tester.tap(find.text('התנתקות'));
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('a profile that never loads shows Try again after a while', (
      tester,
    ) async {
      final b = _HangingProfile();
      await b.signUp(
        email: 'dana@x.com',
        password: 'secret1',
        displayName: 'Dana',
        languageCode: 'he',
      );
      await pumpOnSplash(tester, b);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('לנסות שוב'), findsNothing);

      await tester.pump(SplashScreen.stuckAfter);
      expect(find.text('לנסות שוב'), findsOneWidget);

      await tester.tap(find.text('לנסות שוב'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Unmount so the restarted timer is cancelled.
      await tester.pumpWidget(const SizedBox());
    });
  });
}
