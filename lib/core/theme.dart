import 'package:material_ui/material_ui.dart';

/// Warm palette inspired by the couple's notes (soft peach background).
abstract final class AppColors {
  static const seed = Color(0xFFE07A5F); // terracotta
  static const peach = Color(0xFFF3E3D9);

  /// Status colors – used consistently for ✔ / ✘ / not-logged everywhere.
  static const met = Color(0xFF2E9E6A);
  static const notMet = Color(0xFFD1495B);
  static const unlogged = Color(0xFFB8B0A8);

  /// "Me" vs "partner" accents, used on the board and partner strip.
  static const me = Color(0xFFE07A5F);
  static const partner = Color(0xFF3D7DD8);
}

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: brightness,
    surface: brightness == Brightness.light ? const Color(0xFFFFF8F4) : null,
  );
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
  );
  return base.copyWith(
    scaffoldBackgroundColor:
        brightness == Brightness.light ? AppColors.peach : scheme.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
