import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../l10n/gen/app_localizations.dart';
import 'progress_ring.dart';

/// Greeting, date, challenge day and today's progress ring.
class TodayHeader extends StatelessWidget {
  const TodayHeader({
    super.key,
    required this.greeting,
    required this.name,
    required this.dateText,
    required this.dayLabel,
    required this.percent,
    required this.met,
    required this.total,
  });

  final String greeting;
  final String name;
  final String dateText;
  final String dayLabel;
  final int percent;
  final int met;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? greeting : '$greeting,',
                style: theme.textTheme.titleMedium?.copyWith(color: muted),
              ),
              if (name.isNotEmpty)
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                dateText,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Chip(text: dayLabel, color: AppColors.me),
                  _Chip(
                    text: l.todayMetCount(met, total),
                    color: percent >= 100 ? AppColors.met : muted,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ProgressRing(
          percent: percent,
          size: 100,
          strokeWidth: 11,
          celebrate: true,
          semanticsLabel: l.todayProgressSemantics(percent),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: color, fontWeight: FontWeight.w700),
    ),
  );
}
