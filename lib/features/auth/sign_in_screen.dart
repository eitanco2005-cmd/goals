import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/providers.dart';
import '../../core/router.dart';
import '../../l10n/gen/app_localizations.dart';
import 'auth_widgets.dart';
import 'validators.dart';

/// Email + password sign-in. On success the router redirect takes over.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final l = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text.trim(), password: _password.text);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(l, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final l = AppLocalizations.of(context);
    final email = _email.text.trim();
    if (!AuthValidators.isValidEmail(email)) {
      showAuthSnack(context, l.authResetNeedsEmail);
      return;
    }
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (mounted) showAuthSnack(context, l.authResetSent(email));
    } catch (e) {
      if (mounted) showAuthSnack(context, errorMessage(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AuthScaffold(
      title: l.authSignInTitle,
      form: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                validator: (v) => AuthValidators.email(l, v),
                decoration: InputDecoration(
                  labelText: l.authEmailLabel,
                  prefixIcon: const Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: _password,
                autofillHint: AutofillHints.password,
                validator: (v) => AuthValidators.password(l, v),
                onSubmitted: _submit,
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: _loading ? null : _forgotPassword,
                  child: Text(l.authForgotPassword),
                ),
              ),
              if (_error != null) ...[
                FormErrorText(_error!),
                const SizedBox(height: 12),
              ],
              LoadingButton(
                label: l.authSignInButton,
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
      footer: AuthFooterLink(
        prompt: l.authNoAccount,
        action: l.authGoToSignUp,
        onPressed: () => context.go(Routes.signUp),
      ),
    );
  }
}
