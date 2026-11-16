import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';

/// Placeholder – to be implemented.
class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Text(AppLocalizations.of(context).comingSoon)),
  );
}
