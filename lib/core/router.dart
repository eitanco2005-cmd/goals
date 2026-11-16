import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/auth/sign_in_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/board/board_screen.dart';
import '../features/pairing/pairing_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/home_shell.dart';
import '../features/shell/splash_screen.dart';
import '../features/today/today_screen.dart';
import '../features/week/week_screen.dart';
import '../domain/models.dart';
import 'providers.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const signIn = '/signin';
  static const signUp = '/signup';
  static const pair = '/pair';
  static const today = '/today';
  static const week = '/week';
  static const board = '/board';
  static const settings = '/settings';
}

/// Where the signed-in user's profile stands.
enum ProfileStatus {
  /// Not received yet.
  loading,

  /// Confirmed missing: the account exists but its profile was never
  /// written (see `ProfileRepository.ensureProfile`).
  missing,

  /// The profile stream failed.
  error,

  /// Loaded.
  ready,
}

/// Classifies the profile provider's state for a signed-in user. A loaded
/// profile stays [ProfileStatus.ready] through a later refresh or error.
ProfileStatus profileStatusOf(AsyncValue<UserProfile?> profile) {
  if (profile.value != null) return ProfileStatus.ready;
  if (profile.hasError) return ProfileStatus.error;
  // While loading, `value` may still hold the previous (signed-out) null.
  if (profile.isLoading || !profile.hasValue) return ProfileStatus.loading;
  return ProfileStatus.missing;
}

/// Decides where the user must be based on auth/profile state.
/// Pure function so it can be unit-tested.
///
/// Until the profile is [ProfileStatus.ready] a signed-in user stays on the
/// splash screen, which creates a missing profile and offers "Try again" /
/// "Sign out" when stuck or failed. [hasPair] is only read once ready.
String? redirectFor({
  required String location,
  required bool authLoading,
  required bool signedIn,
  required ProfileStatus profile,
  required bool hasPair,
}) {
  const authPages = {Routes.signIn, Routes.signUp};
  if (authLoading) return location == Routes.splash ? null : Routes.splash;
  if (!signedIn) return authPages.contains(location) ? null : Routes.signIn;
  if (profile != ProfileStatus.ready) {
    return location == Routes.splash ? null : Routes.splash;
  }
  if (!hasPair) return location == Routes.pair ? null : Routes.pair;
  if (authPages.contains(location) ||
      location == Routes.pair ||
      location == Routes.splash) {
    return Routes.today;
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.listen(profileProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final profile = ref.read(profileProvider);
      final signedIn = auth.value != null;
      return redirectFor(
        location: state.matchedLocation,
        authLoading: auth.isLoading && !auth.hasValue,
        signedIn: signedIn,
        profile: profileStatusOf(profile),
        hasPair: profile.value?.pairId != null,
      );
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: Routes.signUp, builder: (_, _) => const SignUpScreen()),
      GoRoute(path: Routes.pair, builder: (_, _) => const PairingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.today,
                builder: (_, _) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.week, builder: (_, _) => const WeekScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.board,
                builder: (_, _) => const BoardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
