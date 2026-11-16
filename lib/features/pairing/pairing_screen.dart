import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/config.dart';
import '../../core/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import 'create_challenge_form.dart';
import '../invite/invite.dart';
import 'join_challenge_form.dart';

enum _PairMode { create, join }

/// Shown after sign-up until the user belongs to a pair: start a new
/// challenge or join the partner's one with a code. Once the profile gets a
/// `pairId` the router redirect moves on to the tabs.
class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  // Opened from an invite link: go straight to "Join with a code".
  late _PairMode? _mode = ref.read(pendingInviteCodeProvider) != null
      ? _PairMode.join
      : null;

  void _setMode(_PairMode? mode) => setState(() => _mode = mode);

  void _signOut() {
    // Keep the current language on the sign-in screen.
    ref
        .read(preLoginLanguageProvider.notifier)
        .set(Localizations.localeOf(context).languageCode);
    ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = ref.watch(profileProvider.select((p) => p.value?.displayName));
    // An invite link that arrives while this screen is open.
    ref.listen(pendingInviteCodeProvider, (_, code) {
      if (code != null) _setMode(_PairMode.join);
    });

    final Widget body = switch (_mode) {
      null => _ModeChoice(onSelected: _setMode),
      _PairMode.create => _ModePanel(
        key: const ValueKey(_PairMode.create),
        title: l.pairCreateTitle,
        onBack: () => _setMode(null),
        child: const CreateChallengeForm(),
      ),
      _PairMode.join => _ModePanel(
        key: const ValueKey(_PairMode.join),
        title: l.pairJoinTitle,
        onBack: () => _setMode(null),
        child: JoinChallengeForm(
          key: ValueKey(ref.watch(pendingInviteCodeProvider)),
        ),
      ),
    };

    return PopScope(
      canPop: _mode == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _setMode(null);
      },
      child: Scaffold(
        // Sign out sits in the top bar, out of the way of the main choice.
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: _signOut,
              icon: const Icon(Icons.logout, size: 18),
              label: Text(l.signOut),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ExcludeSemantics(
                      child: Text(
                        '🎯',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 48),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.pairWelcome(name ?? ''),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.pairIntro,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: body,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeChoice extends ConsumerWidget {
  const _ModeChoice({required this.onSelected});
  final ValueChanged<_PairMode> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChoiceCard(
          emoji: '✨',
          title: l.pairCreateTitle,
          subtitle: l.pairCreateSubtitle,
          onTap: () => onSelected(_PairMode.create),
        ),
        const SizedBox(height: 12),
        _ChoiceCard(
          emoji: '🔑',
          title: l.pairJoinTitle,
          subtitle: l.pairJoinSubtitle,
          onTap: () => onSelected(_PairMode.join),
        ),
        const SizedBox(height: 12),
        // Before there's a challenge: send friends the download link.
        _ChoiceCard(
          key: const ValueKey('invite-download'),
          emoji: '📲',
          title: l.pairInviteTitle,
          subtitle: l.pairInviteSubtitle,
          onTap: () => shareOrCopy(
            ref,
            ScaffoldMessenger.of(context),
            l.pairInviteText('$siteUrl/download'),
            copiedMessage: l.inviteCopied,
          ),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ExcludeSemantics(
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A selected mode: back button + title + the form.
class _ModePanel extends StatelessWidget {
  const _ModePanel({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
  });

  final String title;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8, top: 8),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
