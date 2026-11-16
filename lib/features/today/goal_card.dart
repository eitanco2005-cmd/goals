import 'package:flutter/services.dart' show HapticFeedback;
import 'package:material_ui/material_ui.dart';

import '../../core/status_ui.dart';
import '../../domain/goal_eval.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import 'goal_controls.dart';
import 'today_format.dart';

/// One daily goal: icon, title, target and its input control.
///
/// The card's accent follows the goal's status: muted while not logged,
/// red when logged but not met, green (with a little pop) once met.
class GoalCard extends StatefulWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.photoAction,
    this.photos,
    this.hasPhoto = false,
  });

  final GoalDef goal;
  final num? value;
  final ValueChanged<num?> onChanged;
  final bool enabled;

  /// Shown at the end of the controls row (the 📷 button).
  final Widget? photoAction;

  /// Shown under the controls (today's photos for this goal).
  final Widget? photos;

  /// Whether I attached a photo to this goal today (for goals that require
  /// one: they only count with a photo).
  final bool hasPhoto;

  GoalStatus get status => dayGoalStatus(
    goal,
    DailyLog(uid: '', date: '', values: {goal.id: ?value}),
    photoGoalIds: hasPhoto ? {goal.id} : const {},
  );

  bool get needsPhoto =>
      waitingForPhoto(goal, value, hasPhoto ? {goal.id} : const {});

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void didUpdateWidget(GoalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final was = oldWidget.status;
    final now = widget.status;
    if (now == GoalStatus.met && was != GoalStatus.met) {
      HapticFeedback.lightImpact();
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final goal = widget.goal;
    final title = goal.title(Localizations.localeOf(context).languageCode);
    final status = widget.status;
    final needsPhoto = widget.needsPhoto;
    final unlogged = status == GoalStatus.unlogged;
    final target = GoalFormatter(
      l,
      Localizations.localeOf(context).toLanguageTag(),
    ).target(goal, widget.value);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: switch (status) {
          GoalStatus.met => Color.alphaBlend(
            status.color.withValues(alpha: 0.08),
            scheme.surface,
          ),
          GoalStatus.notMet => scheme.surface,
          GoalStatus.unlogged => scheme.surface.withValues(alpha: 0.7),
        },
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1.5,
          color: unlogged
              ? Colors.transparent
              : status.color.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _GoalIcon(icon: goal.icon, status: status, pop: _pop),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: unlogged
                            ? scheme.onSurface.withValues(alpha: 0.75)
                            : scheme.onSurface,
                      ),
                    ),
                    if (target != null)
                      Text(
                        target,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: unlogged
                              ? scheme.onSurfaceVariant
                              : status.color,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(
                status: status,
                label: needsPhoto ? l.todayNeedsPhotoShort : status.label(l),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GoalControl(
                  goal: goal,
                  title: title,
                  value: widget.value,
                  enabled: widget.enabled,
                  onChanged: widget.onChanged,
                ),
              ),
              if (widget.photoAction case final action?) ...[
                const SizedBox(width: 4),
                action,
              ],
            ],
          ),
          if (needsPhoto)
            Padding(
              key: const ValueKey('needs-photo'),
              padding: const EdgeInsetsDirectional.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 18,
                    color: GoalStatus.notMet.color,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l.todayNeedsPhoto,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: GoalStatus.notMet.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (goal.requiresPhoto && !widget.hasPhoto)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 8),
              child: Text(
                l.todayPhotoRequiredNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ?widget.photos,
        ],
      ),
    );
  }
}

class _GoalIcon extends StatelessWidget {
  const _GoalIcon({
    required this.icon,
    required this.status,
    required this.pop,
  });

  final String icon;
  final GoalStatus status;
  final Animation<double> pop;

  static final _popScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.3,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.3,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 70,
    ),
  ]);

  @override
  Widget build(BuildContext context) {
    final unlogged = status == GoalStatus.unlogged;
    return ScaleTransition(
      scale: _popScale.animate(pop),
      child: SizedBox.square(
        dimension: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: status.color.withValues(alpha: unlogged ? 0.18 : 0.16),
              ),
              alignment: Alignment.center,
              child: Opacity(
                opacity: unlogged ? 0.55 : 1,
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
            if (!unlogged)
              PositionedDirectional(
                end: -2,
                bottom: -2,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, a) =>
                      ScaleTransition(scale: a, child: child),
                  child: Container(
                    key: ValueKey(status),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: status.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      status == GoalStatus.met ? Icons.check : Icons.close,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.label});

  final GoalStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlogged = status == GoalStatus.unlogged;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: unlogged ? 0.14 : 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: unlogged ? theme.colorScheme.onSurfaceVariant : status.color,
        ),
      ),
    );
  }
}
