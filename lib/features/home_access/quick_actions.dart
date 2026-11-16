import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quick_actions/quick_actions.dart';

import '../../core/router.dart';
import '../../l10n/gen/app_localizations.dart';

/// Shortcuts on the app icon (long-press on Android): one-tap logging
/// without hunting for the app's screens.
enum QuickAction {
  logWater('log_water'),
  addPhoto('add_photo');

  const QuickAction(this.type);
  final String type;

  static QuickAction? fromType(String type) =>
      values.where((a) => a.type == type).firstOrNull;
}

/// Platform access to the launcher shortcuts; faked in tests.
abstract interface class LauncherShortcuts {
  Future<void> initialize(void Function(String type) onAction);
  Future<void> setItems(List<ShortcutItem> items);
}

class _PluginShortcuts implements LauncherShortcuts {
  final _plugin = const QuickActions();

  @override
  Future<void> initialize(void Function(String type) onAction) =>
      _plugin.initialize(onAction);

  @override
  Future<void> setItems(List<ShortcutItem> items) =>
      _plugin.setShortcutItems(items);
}

/// The launcher shortcuts of this platform, or null where there are none
/// (the web).
final launcherShortcutsProvider = Provider<LauncherShortcuts?>(
  (ref) => kIsWeb ? null : _PluginShortcuts(),
);

/// A shortcut the user tapped that the Today screen hasn't handled yet.
/// Kept here because on a cold start the shortcut arrives before the user,
/// group and challenge are loaded.
final pendingQuickActionProvider =
    NotifierProvider<PendingQuickAction, QuickAction?>(PendingQuickAction.new);

class PendingQuickAction extends Notifier<QuickAction?> {
  @override
  QuickAction? build() => null;

  void set(QuickAction action) => state = action;

  /// Returns the pending action and clears it, so it runs only once.
  QuickAction? take() {
    final action = state;
    state = null;
    return action;
  }
}

/// Registers the launcher shortcuts (with titles in the app's language) and
/// routes taps to the Today screen. Sits right under the MaterialApp.
class QuickActionsBinding extends ConsumerStatefulWidget {
  const QuickActionsBinding({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<QuickActionsBinding> createState() =>
      _QuickActionsBindingState();
}

class _QuickActionsBindingState extends ConsumerState<QuickActionsBinding> {
  String? _registeredLanguage;

  @override
  void initState() {
    super.initState();
    ref.read(launcherShortcutsProvider)?.initialize((type) {
      final action = QuickAction.fromType(type);
      if (action == null) return;
      ref.read(pendingQuickActionProvider.notifier).set(action);
      // The router's redirect sends signed-out users to sign in first.
      ref.read(routerProvider).go(Routes.today);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l = AppLocalizations.of(context);
    if (_registeredLanguage == l.localeName) return;
    _registeredLanguage = l.localeName;
    ref.read(launcherShortcutsProvider)?.setItems([
      ShortcutItem(
        type: QuickAction.logWater.type,
        localizedTitle: l.shortcutLogWater,
        icon: 'ic_shortcut_water',
      ),
      ShortcutItem(
        type: QuickAction.addPhoto.type,
        localizedTitle: l.shortcutAddPhoto,
        icon: 'ic_shortcut_photo',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Opens a sheet to choose which goal a new photo is for.
Future<T?> showGoalChooser<T>(
  BuildContext context, {
  required String title,
  required List<(String icon, String label, T value)> options,
}) => showModalBottomSheet<T>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final (icon, label, value) in options)
            ListTile(
              leading: Text(icon, style: const TextStyle(fontSize: 22)),
              title: Text(label),
              onTap: () => Navigator.of(context).pop(value),
            ),
        ],
      ),
    ),
  ),
);
