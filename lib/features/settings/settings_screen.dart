import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/dates.dart';
import '../../core/errors.dart';
import '../../core/providers.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../auth/language_switch.dart';
import '../goals/goals_editor_screen.dart';
import '../home_access/home_access_ui.dart';
import '../pairing/invite_code_card.dart';
import 'edit_name_dialog.dart';
import 'settings_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        // Same large bold header as the Today screen.
        title: Text(
          l.settingsTitle,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 24),
              children: [
                SettingsSection(
                  title: l.settingsProfile,
                  children: const [_ProfileTile()],
                ),
                SettingsSection(
                  title: l.language,
                  children: const [_LanguageTile()],
                ),
                SettingsSection(
                  title: l.settingsChallenge,
                  children: const [_ChallengeTiles()],
                ),
                if (HomeScreenTiles.hasContent(ref))
                  SettingsSection(
                    title: l.homeSection,
                    children: const [HomeScreenTiles()],
                  ),
                SettingsSection(
                  title: l.settingsAccount,
                  children: const [_SignOutTile()],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Runs [action] and shows a localized snackbar if it fails.
Future<void> _guard(
  BuildContext context,
  Future<void> Function() action,
) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(errorMessage(l, e))));
  }
}

class _ProfileTile extends ConsumerWidget {
  const _ProfileTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider).value;
    final email = ref.watch(authStateProvider).value?.email;
    final name = profile?.displayName ?? '';
    return ListTile(
      leading: CircleAvatar(
        child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase()),
      ),
      title: Text(name),
      subtitle: email == null ? null : Text(email),
      trailing: IconButton(
        tooltip: l.settingsEditName,
        icon: const Icon(Icons.edit_outlined),
        onPressed: profile == null
            ? null
            : () async {
                final next = await showEditNameDialog(context, name);
                if (next == null || next == name || !context.mounted) return;
                await _guard(
                  context,
                  () => ref
                      .read(profileRepositoryProvider)
                      .setDisplayName(profile.uid, next),
                );
              },
      ),
    );
  }
}

class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final code = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: LanguageSwitch(
          languageCode: code,
          onChanged: (next) {
            if (profile == null || next == code) return;
            // Keep the choice after signing out too.
            ref.read(preLoginLanguageProvider.notifier).set(next);
            _guard(
              context,
              () => ref
                  .read(profileRepositoryProvider)
                  .setLanguage(profile.uid, next),
            );
          },
        ),
      ),
    );
  }
}

class _ChallengeTiles extends ConsumerWidget {
  const _ChallengeTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final pair = ref.watch(pairProvider).value;
    final challenge = ref.watch(challengeProvider).value;
    final others = ref.watch(otherMemberUidsProvider);
    final names = [for (final uid in others) pair?.memberNames[uid] ?? '']
        .where((n) => n.isNotEmpty)
        .toList();

    return Column(
      children: [
        if (pair != null)
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: Text(
              l.settingsMembers(pair.memberUids.length, maxGroupMembers),
            ),
            subtitle: Text(
              names.isEmpty ? l.settingsWaitingForPartner : names.join(', '),
            ),
          ),
        if (pair != null && !pair.isFull)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 12),
            child: InviteCodeCard(code: pair.inviteCode),
          ),
        if (challenge != null) _DatesTile(challenge: challenge),
        if (challenge != null) ...[
          ListTile(
            leading: const Icon(Icons.checklist_rtl),
            title: Text(l.settingsEditGoals),
            subtitle: Text(
              l.goalsInfo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => GoalsEditorScreen(challenge: challenge),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: Text(l.roundTitle),
            subtitle: Text(l.roundSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NewRoundScreen(challenge: challenge),
              ),
            ),
          ),
        ],
        if (pair != null) ...[
          ListTile(
            leading: const Icon(Icons.autorenew),
            title: Text(l.groupNewCode),
            onTap: () => _renewCode(context, ref, pair.id),
          ),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l.groupLeave,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _leave(context, ref, pair.id),
          ),
        ],
      ],
    );
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _renewCode(
    BuildContext context,
    WidgetRef ref,
    String pairId,
  ) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    if (!await _confirm(
      context,
      title: l.groupNewCode,
      body: l.groupNewCodeBody,
      action: l.groupNewCodeConfirm,
    )) {
      return;
    }
    try {
      final code = await ref
          .read(pairRepositoryProvider)
          .renewInviteCode(uid: uid, pairId: pairId);
      messenger.showSnackBar(SnackBar(content: Text(l.groupNewCodeDone(code))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(l, e))));
    }
  }

  Future<void> _leave(
    BuildContext context,
    WidgetRef ref,
    String pairId,
  ) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    if (!await _confirm(
      context,
      title: l.groupLeaveTitle,
      body: l.groupLeaveBody,
      action: l.groupLeaveConfirm,
    )) {
      return;
    }
    try {
      // The router moves to the start/join screen once the profile updates.
      await ref
          .read(pairRepositoryProvider)
          .leavePair(uid: uid, pairId: pairId);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage(l, e))));
    }
  }
}

class _DatesTile extends ConsumerWidget {
  const _DatesTile({required this.challenge});
  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final today = ref.watch(todayKeyProvider);
    final format = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final start = parseDayKey(challenge.startDate);
    final end = parseDayKey(challenge.endDate);
    final progress = challengeProgress(challenge, today);

    return ListTile(
      leading: const Icon(Icons.date_range_outlined),
      title: Text(l.settingsDates),
      subtitle: Text(
        l.settingsDateRange(format.format(start), format.format(end)),
      ),
      trailing: !progress.inProgress
          ? null
          : Text(
              l.settingsDayOf(progress.day, progress.total),
              style: Theme.of(context).textTheme.labelMedium,
            ),
    );
  }
}

class _SignOutTile extends ConsumerWidget {
  const _SignOutTile();

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final ml = MaterialLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsSignOutConfirmTitle),
        content: Text(l.settingsSignOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ml.cancelButtonLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.signOut),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    // Keep the current language on the sign-in screen.
    ref
        .read(preLoginLanguageProvider.notifier)
        .set(Localizations.localeOf(context).languageCode);
    await _guard(context, () => ref.read(authRepositoryProvider).signOut());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.logout, color: scheme.error),
      title: Text(
        AppLocalizations.of(context).signOut,
        style: TextStyle(color: scheme.error),
      ),
      onTap: () => _confirm(context, ref),
    );
  }
}
