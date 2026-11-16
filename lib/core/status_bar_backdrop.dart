import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';

/// On the installed iPhone web app the page is drawn behind the status bar
/// (black-translucent), whose clock and icons are always white. This paints
/// a strip behind them so they stay readable: the app's deep accent color
/// in light mode, the background color in dark mode. Content itself stays
/// below the strip through SafeArea / app bars. No-op elsewhere.
class StatusBarBackdrop extends StatelessWidget {
  const StatusBarBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    final top = MediaQuery.viewPaddingOf(context).top;
    if (top <= 0) return child;
    final theme = Theme.of(context);
    final color = theme.brightness == Brightness.light
        ? theme.colorScheme.primary
        : theme.scaffoldBackgroundColor;
    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: top,
          child: IgnorePointer(child: ColoredBox(color: color)),
        ),
      ],
    );
  }
}
