import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/router.dart';
import '../../l10n/gen/app_localizations.dart';

/// Shown while the session is being resolved (see [redirectFor]).
///
/// When the signed-in user's profile is confirmed missing it creates it
/// (`ProfileRepository.ensureProfile`); the router then moves on. If that
/// fails, the profile stream fails, or nothing happens for [stuckAfter], it
/// shows a message with "Try again" and "Sign out" instead of spinning
/// forever.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const stuckAfter = Duration(seconds: 6);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;
  bool _timedOut = false;
  bool _ensuring = false;
  bool _ensureFailed = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    ref.listenManual(profileProvider, (_, profile) {
      if (profileStatusOf(profile) == ProfileStatus.missing) _ensureProfile();
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(SplashScreen.stuckAfter, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  Future<void> _ensureProfile() async {
    final user = ref.read(authStateProvider).value;
    if (user == null || _ensuring) return;
    _ensuring = true;
    try {
      await ref.read(profileRepositoryProvider).ensureProfile(
            user,
            languageCode: ref.read(preLoginLanguageProvider),
          );
    } catch (_) {
      if (mounted) setState(() => _ensureFailed = true);
    } finally {
      _ensuring = false;
    }
  }

  void _retry() {
    setState(() {
      _timedOut = false;
      _ensureFailed = false;
    });
    _startTimer();
    // Re-subscribes; the listener above re-creates a still-missing profile.
    final signedIn = ref.read(authStateProvider).value != null;
    ref.invalidate(signedIn ? profileProvider : authStateProvider);
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(authStateProvider).value != null;
    final profileFailed = signedIn &&
        profileStatusOf(ref.watch(profileProvider)) == ProfileStatus.error;
    if (!_timedOut && !_ensureFailed && !profileFailed) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_outlined,
                    size: 48, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text(l.sessionStuckMessage, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                    onPressed: _retry, child: Text(l.sessionTryAgain)),
                if (signedIn) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        ref.read(authRepositoryProvider).signOut(),
                    child: Text(l.signOut),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
