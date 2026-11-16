import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, TextInputFormatter;
import 'package:material_ui/material_ui.dart';

import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';

/// Icons offered for goals (emoji keep the widget and the web simple).
const goalIcons = [
  '💧',
  '👟',
  '🥤',
  '🥗',
  '🍽️',
  '🌅',
  '🍫',
  '📱',
  '📖',
  '🏋️',
  '🍔',
  '🧘',
  '😴',
  '🚭',
  '🍷',
  '☕',
  '🍎',
  '🥦',
  '🚶',
  '🚴',
  '🏊',
  '🧹',
  '✍️',
  '🎸',
  '💊',
  '🦷',
  '🌞',
  '📵',
  '🙏',
  '💤',
];

/// What the sheet returns: the edited goal, or a deletion.
sealed class GoalFormResult {
  const GoalFormResult();
}

class GoalSaved extends GoalFormResult {
  const GoalSaved(this.goal);
  final GoalDef goal;
}

class GoalDeleted extends GoalFormResult {
  const GoalDeleted();
}

/// The kinds a person can pick for a new goal.
enum GoalKind { yesNo, count, minutes, number }

GoalKind kindOf(GoalDef g) => switch (g.type) {
  GoalType.boolean => GoalKind.yesNo,
  GoalType.minutes => GoalKind.minutes,
  GoalType.number => GoalKind.number,
  GoalType.counter || GoalType.workouts => GoalKind.count,
};

/// Opens the add/edit form. [goal] null = new goal.
Future<GoalFormResult?> showGoalForm(
  BuildContext context, {
  GoalDef? goal,
  required bool canDelete,
}) => showModalBottomSheet<GoalFormResult>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: _GoalForm(goal: goal, canDelete: canDelete),
  ),
);

class _GoalForm extends StatefulWidget {
  const _GoalForm({required this.goal, required this.canDelete});

  final GoalDef? goal;
  final bool canDelete;

  @override
  State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController();
  late final _target = TextEditingController();
  late final _runs = TextEditingController();
  late final _strength = TextEditingController();
  late final _minMinutes = TextEditingController();

  late String _icon;
  late GoalKind _kind;
  late GoalPeriod _period;
  late Comparison _comparison;
  bool _initialized = false;

  GoalDef? get _goal => widget.goal;
  bool get _isWorkouts => _goal?.type == GoalType.workouts;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final lang = Localizations.localeOf(context).languageCode;
    final g = _goal;
    _icon = g?.icon ?? goalIcons.first;
    _kind = g == null ? GoalKind.yesNo : kindOf(g);
    _period = g?.period ?? GoalPeriod.daily;
    _comparison = g?.comparison ?? Comparison.atLeast;
    _name.text = g?.title(lang) ?? '';
    _target.text = g == null ? '' : '${g.target.toInt()}';
    _runs.text = '${(g?.requirements['run'] ?? 0).toInt()}';
    _strength.text = '${(g?.requirements['strength'] ?? 0).toInt()}';
    _minMinutes.text = '${(g?.requirements['minMinutes'] ?? 0).toInt()}';
  }

  @override
  void dispose() {
    for (final c in [_name, _target, _runs, _strength, _minMinutes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _positive(AppLocalizations l, String? v) {
    final n = int.tryParse(v ?? '');
    return n == null || n <= 0 ? l.goalsTargetInvalid : null;
  }

  String? _nonNegative(AppLocalizations l, String? v) =>
      int.tryParse(v ?? '') == null ? l.goalsTargetInvalid : null;

  void _save() {
    if (!_form.currentState!.validate()) return;
    final lang = Localizations.localeOf(context).languageCode;
    final name = _name.text.trim();
    final g = _goal;

    // Titles: keep the other language unless it was the same text (a goal
    // created in one language) — then rename both.
    String titleFor(String code) {
      if (g == null || code == lang) return name;
      final other = g.title(code);
      return other == g.title(lang) ? name : other;
    }

    final yesNo = _kind == GoalKind.yesNo;
    final target = yesNo ? 1 : int.parse(_target.text);
    final type = _isWorkouts
        ? GoalType.workouts
        : switch (_kind) {
            GoalKind.yesNo => GoalType.boolean,
            GoalKind.count => GoalType.counter,
            GoalKind.minutes => GoalType.minutes,
            GoalKind.number => GoalType.number,
          };
    final result = GoalDef(
      id: g?.id ?? 'custom_${DateTime.now().microsecondsSinceEpoch}',
      titleHe: titleFor('he'),
      titleEn: titleFor('en'),
      type: type,
      comparison: yesNo || _isWorkouts ? Comparison.atLeast : _comparison,
      target: target,
      period: _isWorkouts ? GoalPeriod.weekly : _period,
      icon: _icon,
      step: switch (type) {
        GoalType.minutes => 15,
        GoalType.number => target >= 1000 ? 1000 : 1,
        _ => 1,
      },
      requirements: _isWorkouts
          ? {
              'run': int.parse(_runs.text),
              'strength': int.parse(_strength.text),
              'minMinutes': int.parse(_minMinutes.text),
            }
          : const {},
    );
    Navigator.of(context).pop(GoalSaved(result));
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.goalsDeleteConfirm(_goal!.title(lang))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.goalsDelete),
          ),
        ],
      ),
    );
    if (ok == true) navigator.pop(const GoalDeleted());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isNew = _goal == null;
    final digits = [FilteringTextInputFormatter.digitsOnly];

    Widget label(String text) => Padding(
      padding: const EdgeInsetsDirectional.only(top: 16, bottom: 8),
      child: Text(text, style: theme.textTheme.labelLarge),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 20),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isNew ? l.goalsNewTitle : l.goalsEditTitle,
                style: theme.textTheme.titleLarge,
              ),
              label(l.goalsIcon),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final icon in goalIcons)
                    ChoiceChip(
                      label: Text(icon, style: const TextStyle(fontSize: 18)),
                      selected: _icon == icon,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _icon = icon),
                    ),
                ],
              ),
              label(l.goalsName),
              TextFormField(
                key: const ValueKey('goal-name'),
                controller: _name,
                maxLength: 60,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l.goalsNameRequired : null,
              ),
              if (isNew) ...[
                label(l.goalsPeriod),
                SegmentedButton<GoalPeriod>(
                  segments: [
                    ButtonSegment(
                      value: GoalPeriod.daily,
                      label: Text(l.goalsDaily),
                    ),
                    ButtonSegment(
                      value: GoalPeriod.weekly,
                      label: Text(l.goalsWeekly),
                    ),
                  ],
                  selected: {_period},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() {
                    _period = s.first;
                    // Weekly goals are counted from daily entries.
                    if (_period == GoalPeriod.weekly) _kind = GoalKind.count;
                  }),
                ),
                label(l.goalsKind),
                SegmentedButton<GoalKind>(
                  segments: [
                    for (final (k, text) in [
                      (GoalKind.yesNo, l.goalsKindYesNo),
                      (GoalKind.count, l.goalsKindCount),
                      (GoalKind.minutes, l.goalsKindMinutes),
                      (GoalKind.number, l.goalsKindNumber),
                    ])
                      ButtonSegment(
                        value: k,
                        label: Text(text),
                        enabled:
                            _period == GoalPeriod.daily || k == GoalKind.count,
                      ),
                  ],
                  selected: {_kind},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _kind = s.first),
                ),
              ],
              if (_isWorkouts) ...[
                label(l.goalsWorkoutsTotal),
                _NumberField(
                  key: const ValueKey('goal-target'),
                  controller: _target,
                  formatters: digits,
                  validator: (v) => _positive(l, v),
                ),
                label(l.goalsWorkoutsRuns),
                _NumberField(
                  controller: _runs,
                  formatters: digits,
                  validator: (v) => _nonNegative(l, v),
                ),
                label(l.goalsWorkoutsStrength),
                _NumberField(
                  controller: _strength,
                  formatters: digits,
                  validator: (v) => _nonNegative(l, v),
                ),
                label(l.goalsWorkoutsMinutes),
                _NumberField(
                  controller: _minMinutes,
                  formatters: digits,
                  validator: (v) => _nonNegative(l, v),
                ),
              ] else if (_kind != GoalKind.yesNo) ...[
                label(l.goalsRule),
                SegmentedButton<Comparison>(
                  segments: [
                    ButtonSegment(
                      value: Comparison.atLeast,
                      label: Text(l.goalsAtLeast),
                    ),
                    ButtonSegment(
                      value: Comparison.atMost,
                      label: Text(l.goalsAtMost),
                    ),
                    ButtonSegment(
                      value: Comparison.exactly,
                      label: Text(l.goalsExactly),
                    ),
                  ],
                  selected: {_comparison},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      setState(() => _comparison = s.first),
                ),
                label(l.goalsTarget),
                _NumberField(
                  key: const ValueKey('goal-target'),
                  controller: _target,
                  formatters: digits,
                  validator: (v) => _positive(l, v),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(onPressed: _save, child: Text(l.goalsSave)),
              if (!isNew && widget.canDelete) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l.goalsDelete),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    super.key,
    required this.controller,
    required this.formatters,
    required this.validator,
  });

  final TextEditingController controller;
  final List<TextInputFormatter> formatters;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: formatters,
    maxLength: 6,
    validator: validator,
    decoration: const InputDecoration(counterText: ''),
  );
}

/// Short rule text: "at least 8", "at most 60 min a week", "Yes / no".
String describeGoal(AppLocalizations l, GoalDef g) {
  if (g.type == GoalType.boolean) return l.goalsSummaryYesNo;
  final value = '${g.target.toInt()}';
  final rule = switch (g.comparison) {
    Comparison.atLeast => l.goalsSummaryAtLeast(value),
    Comparison.atMost => l.goalsSummaryAtMost(value),
    Comparison.exactly => l.goalsSummaryExactly(value),
  };
  return g.period == GoalPeriod.weekly ? l.goalsSummaryPerWeek(rule) : rule;
}
