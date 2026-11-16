import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/providers.dart';
import '../../core/router.dart';
import '../../l10n/gen/app_localizations.dart';
import 'auth_widgets.dart';
import 'validators.dart';

/// Account creation. On success the router redirect moves on to pairing.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
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
          .signUp(
            email: _email.text.trim(),
            password: _password.text,
            displayName: _name.text.trim(),
            languageCode: ref.read(preLoginLanguageProvider),
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
    return AuthScaffold(
      title: l.authSignUpTitle,
      form: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (v) => AuthValidators.name(l, v),
                decoration: InputDecoration(
                  labelText: l.displayName,
                  helperText: l.authNameHint,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
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
                autofillHint: AutofillHints.newPassword,
                helperText: l.authPasswordHint,
                validator: (v) =>
                    AuthValidators.password(l, v, checkLength: true),
                onSubmitted: _submit,
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                FormErrorText(_error!),
                const SizedBox(height: 12),
              ],
              LoadingButton(
                label: l.authSignUpButton,
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
      footer: AuthFooterLink(
        prompt: l.authHaveAccount,
        action: l.authGoToSignIn,
        onPressed: () => context.go(Routes.signIn),
      ),
    );
  }
}
