import 'package:flutter/material.dart';

/// Central light/dark theme for the whole app plus a set of semantic colour
/// getters so screens never have to hardcode `Colors.white` / `Colors.black`
/// again. Flip the theme with `UserSession.darkMode` and every screen that
/// reads these getters follows along automatically.
class AppTheme {
  // Brand greens.
  static const Color _brandLight = Color(0xFF1E4D3B);
  static const Color _brandDark = Color(0xFF7FC9A6);

  // Page backgrounds.
  static const Color _bgLight = Color(0xFFF5F5F0);
  static const Color _bgDark = Color(0xFF121212);

  // Card / surface backgrounds.
  static const Color _surfaceLight = Colors.white;
  static const Color _surfaceDark = Color(0xFF1E1E1E);

  static final ThemeData light = _build(
    brightness: Brightness.light,
    brand: _brandLight,
    onBrand: Colors.white,
    background: _bgLight,
    surface: _surfaceLight,
    onSurface: const Color(0xFF1A1A1A),
    onSurfaceVariant: const Color(0xFF5F5F5F),
    hairline: const Color(0xFFE2E2DC),
  );

  static final ThemeData dark = _build(
    brightness: Brightness.dark,
    brand: _brandDark,
    onBrand: const Color(0xFF07140E),
    background: _bgDark,
    surface: _surfaceDark,
    onSurface: const Color(0xFFECECEC),
    onSurfaceVariant: const Color(0xFFABABAB),
    hairline: const Color(0xFF333333),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color brand,
    required Color onBrand,
    required Color background,
    required Color surface,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color hairline,
  }) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: brand,
          brightness: brightness,
        ).copyWith(
          primary: brand,
          onPrimary: onBrand,
          surface: surface,
          onSurface: onSurface,
          onSurfaceVariant: onSurfaceVariant,
        );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'serif',
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: surface,
      cardColor: surface,
      dividerColor: hairline,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface),
      dialogTheme: DialogThemeData(backgroundColor: surface),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
      ),
    );
  }
}

/// Semantic colour shortcuts resolved from the active theme.
///
/// Use these instead of literal colours so widgets react to dark mode:
///   `color: context.surface`, `style: TextStyle(color: context.textMuted)`.
extension AppColors on BuildContext {
  ColorScheme get _scheme => Theme.of(this).colorScheme;

  /// Brand green (primary).
  Color get brand => _scheme.primary;

  /// Readable colour to place on top of [brand].
  Color get onBrand => _scheme.onPrimary;

  /// Scaffold / page background.
  Color get pageBg => Theme.of(this).scaffoldBackgroundColor;

  /// Card / elevated surface background.
  Color get surface => Theme.of(this).cardColor;

  /// Primary text / icon colour.
  Color get textStrong => _scheme.onSurface;

  /// Secondary / muted text colour.
  Color get textMuted => _scheme.onSurfaceVariant;

  /// Divider / border colour.
  Color get hairline => Theme.of(this).dividerColor;
}
