import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color vibrantPurple = Color(0xFFA78BFA);

  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color borderDark = Color(0xFF2A2A2A);

  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color inputLight = Color(0xFFF1F5F9);

  static const List<Color> noteColors = [
    Colors.black,
    Color(0xFF7C3AED), // Primary Purple
    Color(0xFFEF4444), // Red
    Color(0xFF10B981), // Green
    Color(0xFF3B82F6), // Blue
    Color(0xFFF59E0B), // Amber
  ];

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryPurple,
      brightness: Brightness.light,
      primary: primaryPurple,
      surface: cardLight,
      background: backgroundLight,
      outline: borderLight,
      surfaceVariant: inputLight,
    ),
    scaffoldBackgroundColor: backgroundLight,
    cardColor: cardLight,
    dividerColor: borderLight,
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
      bodyColor: const Color(0xFF0F172A),
      displayColor: const Color(0xFF0F172A),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryPurple,
      brightness: Brightness.dark,
      primary: primaryPurple,
      surface: cardDark,
      background: backgroundDark,
      outline: borderDark,
      surfaceVariant: borderDark,
    ),
    scaffoldBackgroundColor: backgroundDark,
    cardColor: cardDark,
    dividerColor: borderDark,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: const Color(0xFFF1F5F9),
      displayColor: const Color(0xFFF1F5F9),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundDark,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}
