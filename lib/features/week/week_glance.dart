import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/router.dart';
import '../../core/status_ui.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import 'week_providers.dart';

/// "This week" on the Today screen: my weekly goals at a glance; tapping it
/// opens the Week tab.
class WeekGlanceCard extends ConsumerWidget {
  const WeekGlanceCard({super.key, required this.goals});

  final List<GoalDef> goals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (goals.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final summary = ref.watch(myWeekSummaryProvider(currentWeekStart()));
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go(Routes.week),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.todayThisWeek,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    l.weekSeeWeek,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: theme.colorScheme.primary),
                ],
              ),
              const SizedBox(height: 8),
              for (final g in goals)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Builder(
                    builder: (context) {
                      final status =
                          summary?.statuses[g.id] ?? GoalStatus.unlogged;
                      return Row(
                        children: [
                          Text(
                            g.icon,
                            style: const TextStyle(fontSize: 20),
                            textDirection: TextDirection.ltr,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              g.title(lang),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          Text(
                            goalOutcome(g, status, periodOpen: true).label(l),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: goalOutcome(
                                g,
                                status,
                                periodOpen: true,
                              ).color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
