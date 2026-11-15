import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';

/// Result of [showValueEntryDialog]: the new value, or null to clear it.
typedef ValueEntry = ({int? value});

/// Asks for a precise whole-number value. Returns null when cancelled.
Future<ValueEntry?> showValueEntryDialog(
  BuildContext context, {
  required String title,
  required num? initial,
  String? unit,
}) => showDialog<ValueEntry>(
  context: context,
  builder: (_) => _ValueEntryDialog(title: title, initial: initial, unit: unit),
);

class _ValueEntryDialog extends StatefulWidget {
  const _ValueEntryDialog({required this.title, this.initial, this.unit});

  final String title;
  final num? initial;
  final String? unit;

  @override
  State<_ValueEntryDialog> createState() => _ValueEntryDialogState();
}

class _ValueEntryDialogState extends State<_ValueEntryDialog> {
  late final _controller = TextEditingController(
    text: widget.initial?.round().toString() ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 0) {
      setState(() => _error = AppLocalizations.of(context).todayInvalidNumber);
      return;
    }
    Navigator.of(context).pop<ValueEntry>((value: value));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: Theme.of(context).textTheme.headlineSmall,
        decoration: InputDecoration(
          labelText: l.todayEnterValueLabel,
          suffixText: widget.unit,
          errorText: _error,
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        if (widget.initial != null)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop<ValueEntry>((value: null)),
            child: Text(l.todayClear),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.todayCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: _save,
          child: Text(l.todaySave),
        ),
      ],
    );
  }
}
