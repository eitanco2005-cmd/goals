import 'package:material_ui/material_ui.dart';

import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';

/// Dismissible "demo mode" info banner.
class DemoModeBanner extends StatelessWidget {
  const DemoModeBanner({
    super.key,
    required this.code,
    required this.onDismiss,
  });

  final String code;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 4, 4),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: scheme.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l.demoModeBanner(code),
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
              ),
            ),
            IconButton(
              tooltip: l.todayDismiss,
              onPressed: onDismiss,
              icon: Icon(Icons.close, color: scheme.onTertiaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

/// Teaser for the weekly goals (the Week screen comes in milestone 2).
class WeeklyTeaserCard extends StatelessWidget {
  const WeeklyTeaserCard({super.key, required this.goals});

  final List<GoalDef> goals;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      color: theme.colorScheme.surface.withValues(alpha: 0.6),
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
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l.comingSoon,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final g in goals)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
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
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Centered icon + title + body, for empty / error states.
class TodayMessage extends StatelessWidget {
  const TodayMessage({
    super.key,
    required this.emoji,
    required this.title,
    this.body,
  });

  final String emoji;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (body case final body?) ...[
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
