import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';

/// Compact עברית / English toggle. Used on the auth screens (pre-login
/// language) and in Settings (profile language).
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({
    super.key,
    required this.languageCode,
    required this.onChanged,
  });

  /// 'he' or 'en'.
  final String languageCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      label: l.language,
      container: true,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: 'he', label: Text(l.languageHebrew)),
          ButtonSegment(value: 'en', label: Text(l.languageEnglish)),
        ],
        selected: {languageCode},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}
