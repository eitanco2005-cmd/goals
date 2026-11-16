import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';

/// Shows the pair's invite code with a copy action.
/// Used on the pairing screen, the Today screen (while waiting for the
/// partner) and in Settings.
class InviteCodeCard extends StatelessWidget {
  const InviteCodeCard({super.key, required this.code});
  final String code;

  Future<void> _copy(BuildContext context) async {
    final message = AppLocalizations.of(context).pairCopied;
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.favorite_outline, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.pairInviteTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l.pairInviteExplain,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    // Codes are Latin – always render LTR, even in Hebrew.
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: SelectableText(
                          code,
                          semanticsLabel: code.split('').join(' '),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontFamilyFallback: const ['Courier', 'Menlo'],
                            fontWeight: FontWeight.w700,
                            letterSpacing: 6,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => _copy(context),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(l.pairCopy, semanticsLabel: l.pairCopyCode),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
