import 'package:material_ui/material_ui.dart';

/// Shows the pair's invite code with copy/share actions.
/// Used on the pairing screen, the Today screen (while waiting for the
/// partner) and in Settings. STUB – implemented by the pairing feature.
class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SelectableText(code),
        ),
      );
}
