import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/providers.dart';
import '../../data/repositories.dart';
import '../../l10n/gen/app_localizations.dart';
import '../invite/invite.dart';
import '../auth/auth_widgets.dart';

/// Length of a pair invite code.
const inviteCodeLength = 6;

/// Invite-code field + "join" button.
class JoinChallengeForm extends ConsumerStatefulWidget {
  const JoinChallengeForm({super.key});

  @override
  ConsumerState<JoinChallengeForm> createState() => _JoinChallengeFormState();
}

class _JoinChallengeFormState extends ConsumerState<JoinChallengeForm> {
  final _formKey = GlobalKey<FormState>();
  // Pre-filled when the app was opened from an invite link.
  late final _code = TextEditingController(
    text: ref.read(pendingInviteCodeProvider) ?? '',
  );
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (_loading) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final name =
        ref.read(profileProvider).value?.displayName ?? user.displayName ?? '';
    setState(() => _loading = true);
    try {
      await ref
          .read(pairRepositoryProvider)
          .joinPair(uid: user.uid, displayName: name, code: _code.text);
      ref.read(pendingInviteCodeProvider.notifier).set(null);
      refreshSession(ref);
    } catch (e) {
      if (e is AppException && e.code == 'already-paired') {
        // Usually an earlier attempt went through but its update didn't
        // arrive: reload the profile and continue instead of failing.
        refreshSession(ref);
      } else if (mounted) {
        setState(() => _error = errorMessage(l, e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _code,
            autofocus: true,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.go,
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(inviteCodeLength),
              const _UpperCaseFormatter(),
            ],
            validator: (v) =>
                (v ?? '').length == inviteCodeLength ? null : l.pairCodeLength,
            onFieldSubmitted: (_) => _join(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: 'monospace',
              fontFamilyFallback: const ['Courier', 'Menlo'],
              fontWeight: FontWeight.w700,
              letterSpacing: 6,
            ),
            decoration: InputDecoration(
              labelText: l.pairCodeLabel,
              helperText: l.pairCodeHint,
              prefixIcon: const Icon(Icons.key_outlined),
            ),
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            FormErrorText(_error!),
            const SizedBox(height: 12),
          ],
          LoadingButton(
            label: l.pairJoinButton,
            loading: _loading,
            onPressed: _join,
          ),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  const _UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
