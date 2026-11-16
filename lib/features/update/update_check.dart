import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../l10n/gen/app_localizations.dart';
import 'version_fetch_stub.dart' if (dart.library.io) 'version_fetch_io.dart';

/// Where CI publishes the latest Android build number.
final latestVersionUrl = Uri.parse('$siteUrl/download/version.json');

/// APKs are published as the 'android' GitHub release (Firebase Hosting's
/// free plan doesn't allow APK files).
final latestApkUrl = Uri.parse(
  'https://github.com/eitanco2005-cmd/goals/releases/download/android/goals.apk',
);

/// The newest published build number, or null when unknown. Overridden in
/// tests.
final latestBuildProvider = FutureProvider<int?>((ref) async {
  // Only the Android app is installed from an APK; the web app updates
  // itself. Local builds (appBuild 0) don't nag.
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
  if (appBuild == 0) return null;
  return fetchLatestBuild(latestVersionUrl);
});

/// This app's build number (overridable in tests).
final currentBuildProvider = Provider<int>((ref) => appBuild);

/// Whether a newer Android build is published.
final updateAvailableProvider = Provider<bool>((ref) {
  final latest = ref.watch(latestBuildProvider).value;
  final current = ref.watch(currentBuildProvider);
  return latest != null && current > 0 && latest > current;
});

/// "Later" was tapped (this app session only).
final updateDismissedProvider = NotifierProvider<UpdateDismissed, bool>(
  UpdateDismissed.new,
);

class UpdateDismissed extends Notifier<bool> {
  @override
  bool build() => false;
  void dismiss() => state = true;
}

/// Opens the new APK in the browser, which downloads it; installing it
/// replaces the app and keeps everything (data lives in the cloud).
final openUpdateProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    await launchUrl(latestApkUrl, mode: LaunchMode.externalApplication);
  },
);

/// Banner on the Today screen when a new Android version is out.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(updateAvailableProvider) ||
        ref.watch(updateDismissedProvider)) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Card(
        color: scheme.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
          child: Row(
            children: [
              Icon(Icons.system_update, color: scheme.onTertiaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.updateAvailable,
                  style: TextStyle(
                    color: scheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
                onPressed: () => ref.read(openUpdateProvider)(),
                child: Text(l.updateInstall),
              ),
              IconButton(
                tooltip: l.todayDismiss,
                icon: const Icon(Icons.close),
                color: scheme.onTertiaryContainer,
                onPressed: () =>
                    ref.read(updateDismissedProvider.notifier).dismiss(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
