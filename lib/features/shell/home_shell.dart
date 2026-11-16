import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../reminders/reminders.dart';
import '../today/today_providers.dart';
import '../week/week_providers.dart';
import '../widget/widget_sync.dart';

/// Bottom navigation between the four main tabs.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // Keeps the Android home-screen widget in sync while the app runs.
    ref.watch(groupWidgetSyncProvider);
    // Keeps on-device reminders (Android) in step with today's log.
    ref.watch(reminderSyncProvider);
    // Photos can complete goals that require one: republish my summary.
    ref.watch(mySummarySyncProvider);
    // Keeps my weekly summary (what the group sees) up to date.
    ref.watch(weekSummaryPublisherProvider(currentWeekStart()));
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: l.navToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.view_week_outlined),
            selectedIcon: const Icon(Icons.view_week),
            label: l.navWeek,
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view),
            label: l.navBoard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l.navSettings,
          ),
        ],
      ),
    );
  }
}
