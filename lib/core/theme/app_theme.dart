import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core Brand Colors (Modern SaaS Violet)
  static const Color primaryPurple = Color(0xFF6366F1); // Indigo 500
  static const Color vibrantPurple = Color(0xFF818CF8); // Indigo 400

  // Semantic Accents (Refined & Slightly desaturated)
  static const List<Color> accentColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFFF43F5E), // Rose (Red)
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald (Green)
    Color(0xFF3B82F6), // Blue
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFF84CC16), // Lime
  ];

  // Dark Mode Palette (Slate)
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color sidebarDark = Color(0xFF1E293B); // Slate 800
  static const Color cardDark = Color(0xFF1E293B); // Slate 800
  static const Color borderDark = Color(0xFF334155); // Slate 700

  // Light Mode Palette (Slate)
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color inputLight = Color(0xFFF1F5F9); // Slate 100

  static const List<Color> noteColors = [
    Colors.black,
    Colors.white,
    Color(0xFFF43F5E), // Rose
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Blue
    Color(0xFFF59E0B), // Amber
  ];

  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
      ),
      bodyLarge: GoogleFonts.inter(letterSpacing: 0.15, height: 1.5),
      bodyMedium: GoogleFonts.inter(letterSpacing: 0.1, height: 1.5),
      labelLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  static ThemeData lightTheme(Color seedColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      primary: seedColor,
      surface: cardLight,
      outline: borderLight,
      surfaceContainerHighest: inputLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundLight,
      cardColor: cardLight,
      dividerColor: borderLight,
      textTheme: _buildTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: const Color(0xFF0F172A), // Slate 900
        displayColor: const Color(0xFF0F172A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: seedColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  static ThemeData darkTheme(Color seedColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      primary: seedColor,
      surface: cardDark,
      outline: borderDark,
      surfaceContainerHighest: borderDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundDark,
      cardColor: cardDark,
      dividerColor: borderDark,
      textTheme: _buildTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: const Color(0xFFF1F5F9), // Slate 100
        displayColor: const Color(0xFFF1F5F9),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF334155), // Slate 700
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: seedColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
