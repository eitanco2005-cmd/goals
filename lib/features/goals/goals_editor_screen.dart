import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/errors.dart';
import '../../core/providers.dart';
import '../../data/repositories.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../pairing/create_challenge_form.dart';
import 'goal_form_sheet.dart';

/// Edits the active challenge's goals for the whole group. Changes stay
/// local until "Save"; leaving with unsaved changes asks first.
class GoalsEditorScreen extends ConsumerStatefulWidget {
  const GoalsEditorScreen({super.key, required this.challenge});

  final Challenge challenge;

  @override
  ConsumerState<GoalsEditorScreen> createState() => _GoalsEditorScreenState();
}

class _GoalsEditorScreenState extends ConsumerState<GoalsEditorScreen> {
  late final List<GoalDef> _goals = [...widget.challenge.goals];
  bool _dirty = false;
  bool _saving = false;

  int get _dailyCount =>
      _goals.where((g) => g.period == GoalPeriod.daily).length;

  Future<void> _edit(GoalDef? goal) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (goal == null && _goals.length >= maxGoals) {
      messenger.showSnackBar(SnackBar(content: Text(l.goalsTooMany(maxGoals))));
      return;
    }
    final canDelete =
        goal != null && !(goal.period == GoalPeriod.daily && _dailyCount <= 1);
    final result = await showGoalForm(
      context,
      goal: goal,
      canDelete: canDelete,
    );
    if (result == null || !mounted) return;
    setState(() {
      _dirty = true;
      switch (result) {
        case GoalSaved(goal: final saved):
          final i = _goals.indexWhere((g) => g.id == saved.id);
          if (i >= 0) {
            _goals[i] = saved;
          } else {
            _goals.add(saved);
          }
        case GoalDeleted():
          _goals.removeWhere((g) => g.id == goal!.id);
      }
    });
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (_dailyCount == 0) {
      messenger.showSnackBar(SnackBar(content: Text(l.goalsNeedOneDaily)));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(challengeRepositoryProvider)
          .updateGoals(
            pairId: widget.challenge.pairId,
            challengeId: widget.challenge.id,
            goals: _goals,
          );
      _dirty = false;
      messenger.showSnackBar(SnackBar(content: Text(l.goalsSaved)));
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(l, e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    final l = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l.goalsDiscardTitle),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l.goalsKeepEditing),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l.goalsDiscard),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    Widget section(String title, GoalPeriod period) {
      final goals = _goals.where((g) => g.period == period).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 16, 4, 8),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                for (final g in goals)
                  ListTile(
                    key: ValueKey('edit-${g.id}'),
                    leading: Text(
                      g.icon,
                      style: const TextStyle(fontSize: 24),
                      textDirection: TextDirection.ltr,
                    ),
                    title: Text(g.title(lang)),
                    subtitle: Text(describeGoal(l, g)),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _edit(g),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard()) {
          _dirty = false;
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.goalsTitle),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
                onPressed: _dirty && !_saving ? _save : null,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.goalsSave),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _edit(null),
          icon: const Icon(Icons.add),
          label: Text(l.goalsAdd),
        ),
        body: SafeArea(
          child: Align(
            alignment: AlignmentDirectional.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 96),
                children: [
                  Card(
                    color: theme.colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.group_outlined,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l.goalsInfo,
                              style: TextStyle(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  section(l.goalsDaily, GoalPeriod.daily),
                  section(l.goalsWeekly, GoalPeriod.weekly),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Starts the next round of the group's challenge: new dates, same goals.
class NewRoundScreen extends ConsumerWidget {
  const NewRoundScreen({super.key, required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // The new round replaces the current one right away, so it starts
    // today by default (a later date leaves a gap with nothing to log).
    final start = parseDayKey(ref.watch(todayKeyProvider));

    return Scaffold(
      appBar: AppBar(title: Text(l.roundTitle)),
      body: SafeArea(
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  l.roundInfo,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                CreateChallengeForm(
                  goals: challenge.goals,
                  initialStart: start,
                  submitLabel: l.roundStart,
                  onSubmit: (startDate, endDate) async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    await ref
                        .read(challengeRepositoryProvider)
                        .createChallenge(
                          pairId: challenge.pairId,
                          startDate: startDate,
                          endDate: endDate,
                          goals: challenge.goals,
                        );
                    messenger.showSnackBar(
                      SnackBar(content: Text(l.roundStarted)),
                    );
                    navigator.pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
