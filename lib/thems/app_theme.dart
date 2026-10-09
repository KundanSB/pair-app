import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central palette + theme for Pair. Deliberately soft/dusty rather than
/// saturated Material defaults — the product goal is "calming, couple-
/// friendly, makes you feel loved," not a typical productivity-app look.
class AppTheme {
  static const Color blush = Color(0xFFF7D6E0);
  static const Color coral = Color(0xFFE8837B);   // decorative accent / icons ONLY — see alertText below
  static const Color lavender = Color(0xFFC9B6E4);
  static const Color plum = Color(0xFF7A5C7E);
  static const Color sage = Color(0xFFAFC8AD);
  static const Color cream = Color(0xFFFFF8F3);
  static const Color inkPlum = Color(0xFF3D2C3E);

  /// Accessibility note: `coral` on `cream`/white does NOT meet WCAG AA
  /// contrast (4.5:1) for body text, even though it reads fine as an
  /// icon color or on a saturated background. Use `alertText` for any
  /// actual sentence a user needs to read (errors, "partner left"
  /// notices), and keep `coral` for icons/accents/large decorative text.
  static const Color alertText = Color(0xFFB33A30);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: coral,
        brightness: Brightness.light,
        primary: coral,
        secondary: lavender,
        surface: cream,
      ),
      scaffoldBackgroundColor: cream,
    );
    return base.copyWith(
      textTheme: GoogleFonts.quicksandTextTheme(base.textTheme).apply(
        bodyColor: inkPlum,
        displayColor: inkPlum,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cream,
        foregroundColor: inkPlum,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.quicksand(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: inkPlum,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: coral,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: plum,
          side: const BorderSide(color: lavender, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: blush,
        elevation: 0,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: coral,
        brightness: Brightness.dark,
        primary: coral,
        secondary: lavender,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.quicksandTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
