import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/gen/app_localizations.dart';
import '../widget/widget_sync.dart';
import 'standalone.dart';

/// Whether the web app runs in a browser tab rather than from the home
/// screen. Overridable in tests.
final runningInBrowserTabProvider = Provider<bool>(
  (ref) => kIsWeb && !runningStandalone,
);

/// Whether this browser is on an iPhone/iPad (install via Safari's Share).
final isIosBrowserProvider = Provider<bool>((ref) => kIsWeb && isIosBrowser);

const _installHintKey = 'home.installHintDismissed';

/// The "add the app to your home screen" card on Today was dismissed.
/// Remembered on this device only.
final installHintDismissedProvider =
    NotifierProvider<InstallHintDismissed, bool>(InstallHintDismissed.new);

class InstallHintDismissed extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_installHintKey) ?? false) state = true;
    } catch (_) {
      // Storage unavailable (private mode): just show the hint.
    }
  }

  Future<void> dismiss() async {
    state = true;
    try {
      await (await SharedPreferences.getInstance()).setBool(
        _installHintKey,
        true,
      );
    } catch (_) {}
  }
}

/// Today-screen card for the web version opened in a browser tab: explains
/// how to put the app on the home screen.
class InstallAppCard extends ConsumerWidget {
  const InstallAppCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(runningInBrowserTabProvider) ||
        ref.watch(installHintDismissedProvider)) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ios = ref.watch(isIosBrowserProvider);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Card(
        color: scheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.add_to_home_screen, color: scheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.homeInstallTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ios ? l.homeInstallIos : l.homeInstallOther,
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l.todayDismiss,
                icon: const Icon(Icons.close),
                color: scheme.onPrimaryContainer,
                onPressed: () =>
                    ref.read(installHintDismissedProvider.notifier).dismiss(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step-by-step dialog for adding the web app to the home screen.
Future<void> showInstallInstructions(
  BuildContext context, {
  required bool ios,
}) {
  final l = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.add_to_home_screen),
      title: Text(l.homeInstallTitle),
      content: Text(
        '${ios ? l.homeInstallIos : l.homeInstallOther}\n\n${l.homeInstallWhy}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.homeGotIt),
        ),
      ],
    ),
  );
}

/// Settings tiles that put the app one tap away: the Android widget and
/// launcher shortcuts, or installing the web app to the home screen.
/// Empty when there is nothing to offer (e.g. an installed web app).
class HomeScreenTiles extends ConsumerWidget {
  const HomeScreenTiles({super.key});

  /// Whether [HomeScreenTiles] has anything to show on this platform.
  static bool hasContent(WidgetRef ref) =>
      ref.watch(widgetStoreProvider) != null ||
      ref.watch(runningInBrowserTabProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final store = ref.watch(widgetStoreProvider);
    final inBrowser = ref.watch(runningInBrowserTabProvider);
    return Column(
      children: [
        if (store != null) ...[
          ListTile(
            leading: const Icon(Icons.widgets_outlined),
            title: Text(l.homeAddWidget),
            subtitle: Text(l.homeAddWidgetSubtitle),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final pinned = await store.requestPin().catchError((_) => false);
              if (!pinned) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l.homeAddWidgetManual),
                    duration: const Duration(seconds: 8),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.touch_app_outlined),
            title: Text(l.homeShortcutsHint),
          ),
        ],
        if (inBrowser)
          ListTile(
            leading: const Icon(Icons.add_to_home_screen),
            title: Text(l.homeInstallTitle),
            subtitle: Text(l.homeInstallWhy),
            onTap: () => showInstallInstructions(
              context,
              ios: ref.read(isIosBrowserProvider),
            ),
          ),
      ],
    );
  }
}
