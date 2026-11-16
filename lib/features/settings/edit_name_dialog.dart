import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import '../auth/validators.dart';

/// Asks for a new display name. Returns the trimmed name, or null when
/// cancelled.
Future<String?> showEditNameDialog(BuildContext context, String current) =>
    showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(initial: current),
    );

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initial});
  final String initial;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ml = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(l.settingsEditName),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.name],
          decoration: InputDecoration(labelText: l.displayName),
          validator: (v) => AuthValidators.name(l, v),
          onFieldSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(ml.cancelButtonLabel),
        ),
        TextButton(onPressed: _save, child: Text(ml.saveButtonLabel)),
      ],
    );
  }
}
