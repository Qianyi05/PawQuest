import 'package:flutter/material.dart';
import 'package:pawquest/theme/app_palette.dart';

class AppTheme {
  /// Builds a ThemeData from the active palette so that any screen relying on
  /// the global theme (default app bars, scaffolds, cards, buttons, text)
  /// follows the selected theme automatically.
  static ThemeData themeFor(AppPalette p) {
    return ThemeData(
      fontFamily: "SF Pro Rounded",
      scaffoldBackgroundColor: p.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.accent,
        primary: p.primary,
        secondary: p.accent,
        surface: p.surface,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: p.accent,
        foregroundColor: p.text,
        iconTheme: IconThemeData(color: p.text),
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: p.text,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: p.text,
          elevation: 3,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      iconTheme: IconThemeData(color: p.text),
      listTileTheme: ListTileThemeData(
        iconColor: p.primary,
        textColor: p.text,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: p.text),
        bodyMedium: TextStyle(color: p.text),
        titleLarge: TextStyle(
          color: p.text,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
