import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import 'today_format.dart';
import 'value_entry_dialog.dart';

/// The input control for one goal, chosen by [GoalDef.type].
class GoalControl extends StatelessWidget {
  const GoalControl({
    super.key,
    required this.goal,
    required this.title,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final GoalDef goal;

  /// Localized goal title (for dialogs and semantics).
  final String title;
  final num? value;
  final ValueChanged<num?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final change = enabled ? onChanged : null;
    return switch (goal.type) {
      GoalType.counter => CounterControl(
        goal: goal,
        title: title,
        value: value,
        onChanged: change,
      ),
      GoalType.number || GoalType.minutes => MeasureControl(
        goal: goal,
        title: title,
        value: value,
        onChanged: change,
      ),
      GoalType.boolean => YesNoControl(value: value, onChanged: change),
      GoalType.workouts => const SizedBox.shrink(),
    };
  }
}

/// − / value / + with a one-tap "None today" for limit goals (sweets).
class CounterControl extends StatelessWidget {
  const CounterControl({
    super.key,
    required this.goal,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final GoalDef goal;
  final String title;
  final num? value;
  final ValueChanged<num?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final v = value;
    final change = onChanged;
    final showNone = goal.comparison == Comparison.atMost && v == null;
    final text = v == null
        ? null
        : GoalFormatter(l, _locale(context)).number(v);
    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: l.todayDecrease(title),
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          // At 0 (or after a mistaken "None today") − returns to "not logged".
          onPressed: change == null || v == null
              ? null
              : () => change(v <= 0 ? null : v - 1),
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 56,
          child: Semantics(
            label: '$title: ${text ?? l.statusUnlogged}',
            excludeSemantics: true,
            child: _AnimatedValue(text: text ?? '–', muted: v == null),
          ),
        ),
        IconButton.filledTonal(
          tooltip: l.todayIncrease(title),
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          onPressed: change == null ? null : () => change((v ?? 0) + 1),
          icon: const Icon(Icons.add),
        ),
        if (showNone) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 14,
                  ),
                  foregroundColor: AppColors.met,
                  backgroundColor: AppColors.met.withValues(alpha: 0.12),
                ),
                onPressed: change == null ? null : () => change(0),
                child: Text(
                  l.todayNoneToday,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// −step / tappable value / +step for steps and minutes. Tapping the value
/// opens a precise numeric entry dialog.
class MeasureControl extends StatelessWidget {
  const MeasureControl({
    super.key,
    required this.goal,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final GoalDef goal;
  final String title;
  final num? value;
  final ValueChanged<num?>? onChanged;

  Future<void> _enterValue(BuildContext context, String? unit) async {
    final result = await showValueEntryDialog(
      context,
      title: title,
      initial: value,
      unit: unit,
    );
    if (result != null && result.value != value) onChanged?.call(result.value);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fmt = GoalFormatter(l, _locale(context));
    final theme = Theme.of(context);
    final v = value;
    final change = onChanged;
    final unit = fmt.unit(goal);
    final step = fmt.number(goal.step);
    return Row(
      children: [
        _StepTextButton(
          text: '−$step',
          tooltip: l.todayDecrease(title),
          onPressed: change == null || v == null || v <= 0
              ? null
              : () => change(math.max<num>(0, v - goal.step)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            button: true,
            hint: l.todayTapToEdit,
            child: Material(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.6,
              ),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: change == null ? null : () => _enterValue(context, unit),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 8,
                    ),
                    // Scale down rather than clip big numbers on narrow phones.
                    child: Semantics(
                      label: v == null
                          ? '$title: ${l.statusUnlogged}'
                          : '$title: ${[fmt.number(v), ?unit].join(' ')}',
                      excludeSemantics: true,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _AnimatedValue(
                              text: v == null ? '–' : fmt.number(v),
                              muted: v == null,
                            ),
                            if (unit != null && v != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                unit,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(width: 6),
                            Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _StepTextButton(
          text: '+$step',
          tooltip: l.todayIncrease(title),
          onPressed: change == null ? null : () => change((v ?? 0) + goal.step),
        ),
      ],
    );
  }
}

/// Two clear choices for yes/no goals; tapping the selected one clears it.
class YesNoControl extends StatelessWidget {
  const YesNoControl({super.key, required this.value, required this.onChanged});

  final num? value;
  final ValueChanged<num?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final change = onChanged;
    ValueChanged<bool>? tap(num choice) =>
        change == null ? null : (selected) => change(selected ? null : choice);
    return Row(
      children: [
        Expanded(
          child: _ChoiceButton(
            label: l.todayKeptIt,
            selected: value == 1,
            color: AppColors.met,
            onTap: tap(1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ChoiceButton(
            label: l.todayDidnt,
            selected: value == 0,
            color: AppColors.notMet,
            onTap: tap(0),
          ),
        ),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;

  /// Called with the current selection state.
  final ValueChanged<bool>? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: selected ? color : theme.colorScheme.outlineVariant,
        width: 1.5,
      ),
    );
    final onTap = this.onTap;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? color : Colors.transparent,
        shape: shape,
        animationDuration: const Duration(milliseconds: 200),
        child: InkWell(
          customBorder: shape,
          onTap: onTap == null ? null : () => onTap(selected),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Center(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepTextButton extends StatelessWidget {
  const _StepTextButton({
    required this.text,
    required this.tooltip,
    required this.onPressed,
  });

  final String text;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: FilledButton.tonal(
      style: FilledButton.styleFrom(
        minimumSize: const Size(56, 48),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
      ),
      onPressed: onPressed,
      // Keep "+1,000" readable as a signed number in RTL too.
      child: Text(text, textDirection: TextDirection.ltr),
    ),
  );
}

/// A number that pops when it changes.
class _AnimatedValue extends StatelessWidget {
  const _AnimatedValue({required this.text, required this.muted});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: Tween(begin: 0.6, end: 1.0).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Text(
        text,
        key: ValueKey(text),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: muted
              ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();
