import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/errors.dart';
import '../../core/providers.dart';
import '../../domain/default_goals.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/auth_widgets.dart';

/// Preset challenge lengths, in days.
const challengeLengthPresets = [30, 66, 90];

/// Start date + length picker, a preview of the default goals and the
/// "create" button.
/// Dates + goal preview for a challenge. Without [onSubmit] it starts a new
/// group (pairing screen); with it, the caller decides what to create (e.g.
/// a new round of an existing group's challenge).
class CreateChallengeForm extends ConsumerStatefulWidget {
  const CreateChallengeForm({
    super.key,
    this.goals = defaultGoals,
    this.initialStart,
    this.submitLabel,
    this.onSubmit,
  });

  /// Goals the new challenge will have (shown as a preview).
  final List<GoalDef> goals;

  /// First day; defaults to today.
  final DateTime? initialStart;

  /// Button label; defaults to "Create challenge".
  final String? submitLabel;

  /// Creates the challenge for the chosen inclusive day keys. Throws an
  /// AppException on failure (shown under the form).
  final Future<void> Function(String startDate, String endDate)? onSubmit;

  @override
  ConsumerState<CreateChallengeForm> createState() =>
      _CreateChallengeFormState();
}

class _CreateChallengeFormState extends ConsumerState<CreateChallengeForm> {
  late DateTime _start =
      widget.initialStart ?? parseDayKey(ref.read(todayKeyProvider));

  /// A preset length, or null when [_customEnd] is used.
  int? _presetDays = challengeLengthPresets.first;
  DateTime? _customEnd;
  bool _loading = false;
  String? _error;

  DateTime get _end => _presetDays != null
      ? DateTime(_start.year, _start.month, _start.day + _presetDays! - 1)
      : _customEnd!;

  int get _totalDays => dayKeysBetween(dayKey(_start), dayKey(_end)).length;

  Future<void> _pickStart() async {
    final today = parseDayKey(ref.read(todayKeyProvider));
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(today.year - 1, today.month, today.day),
      lastDate: DateTime(today.year + 2, today.month, today.day),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _start = picked;
      // Keep a custom end valid.
      if (_customEnd != null && _customEnd!.isBefore(picked)) {
        _customEnd = picked;
      }
    });
  }

  Future<void> _pickCustomEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: _start,
      lastDate: DateTime(_start.year + 3, _start.month, _start.day),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _presetDays = null;
      _customEnd = picked;
    });
  }

  Future<void> _create() async {
    if (_loading) return;
    final l = AppLocalizations.of(context);
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final name =
        ref.read(profileProvider).value?.displayName ?? user.displayName ?? '';
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.onSubmit case final submit?) {
        await submit(dayKey(_start), dayKey(_end));
        return;
      }
      await ref
          .read(pairRepositoryProvider)
          .createPair(
            uid: user.uid,
            displayName: name,
            startDate: dayKey(_start),
            endDate: dayKey(_end),
            goals: defaultGoals,
          );
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(l, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final format = DateFormat.yMMMEd(locale.toLanguageTag());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DateRow(
          icon: Icons.play_circle_outline,
          label: l.pairStartDate,
          value: format.format(_start),
          onTap: _pickStart,
        ),
        const SizedBox(height: 16),
        Text(l.pairLength, style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final days in challengeLengthPresets)
              ChoiceChip(
                label: Text(l.pairDays(days)),
                selected: _presetDays == days,
                onSelected: (_) => setState(() {
                  _presetDays = days;
                  _customEnd = null;
                }),
              ),
            ChoiceChip(
              avatar: const Icon(Icons.edit_calendar_outlined, size: 18),
              label: Text(l.pairCustomLength),
              selected: _presetDays == null,
              onSelected: (_) => _pickCustomEnd(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DateRow(
          icon: Icons.flag_outlined,
          label: l.pairEndDate,
          value: '${format.format(_end)} · ${l.pairDays(_totalDays)}',
          onTap: _pickCustomEnd,
        ),
        const SizedBox(height: 20),
        _GoalsPreview(languageCode: locale.languageCode, goals: widget.goals),
        const SizedBox(height: 20),
        if (_error != null) ...[
          FormErrorText(_error!),
          const SizedBox(height: 12),
        ],
        LoadingButton(
          label: widget.submitLabel ?? l.pairCreateButton,
          loading: _loading,
          onPressed: _create,
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        minTileHeight: 56,
        leading: Icon(icon, color: scheme.primary),
        title: Text(label),
        subtitle: Text(value),
        trailing: const Icon(Icons.calendar_month_outlined),
        onTap: onTap,
      ),
    );
  }
}

class _GoalsPreview extends StatelessWidget {
  const _GoalsPreview({required this.languageCode, required this.goals});
  final String languageCode;
  final List<GoalDef> goals;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final daily = goals.where((g) => g.period == GoalPeriod.daily).toList();
    final weekly = goals.where((g) => g.period == GoalPeriod.weekly).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.pairGoalsIncluded,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _GoalGroup(title: l.pairDailyGoals, goals: daily, lang: languageCode),
        const SizedBox(height: 8),
        _GoalGroup(title: l.pairWeeklyGoals, goals: weekly, lang: languageCode),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.edit_note,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l.pairGoalsEditLater,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GoalGroup extends StatelessWidget {
  const _GoalGroup({
    required this.title,
    required this.goals,
    required this.lang,
  });

  final String title;
  final List<GoalDef> goals;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final g in goals)
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 10, 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(
                    alpha: 0.6,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${g.icon} ${g.title(lang)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
