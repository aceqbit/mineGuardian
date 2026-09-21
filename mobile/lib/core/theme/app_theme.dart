import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MineGuardian App Theme
/// Dark industrial theme with safety amber/orange/cyan colors
class AppTheme {
  // Industrial Safety Palette
  static const Color safetyOrange = Color(0xFFFF6D00); // Primary Safety Orange
  static const Color safetyAmber = Color(0xFFFFB300);  // Caution / Attention Amber
  static const Color safetyGreen = Color(0xFF10B981);  // Verified / Safe Green
  static const Color safetyRed = Color(0xFFEF4444);    // Critical / Emergency Red
  static const Color safetyCyan = Color(0xFF06B6D4);   // Telemetry / Location Cyan

  // Aliases for compatibility
  static const Color primaryAmber = safetyAmber;
  static const Color primaryOrange = safetyOrange;
  static const Color dangerRed = safetyRed;
  static const Color safeGreen = safetyGreen;
  static const Color warningAmber = safetyAmber;

  // Dark Industrial Backgrounds
  static const Color darkBg = Color(0xFF0B0F19);   // Deep obsidian
  static const Color cardBg = Color(0xFF161E2E);   // Elevated Slate
  static const Color bgDark = darkBg;
  static const Color bgCard = cardBg;
  static const Color bgSurface = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: safetyOrange,
        secondary: safetyAmber,
        error: safetyRed,
        surface: cardBg,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: darkBg,
      cardColor: cardBg,
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
          bodySmall: TextStyle(color: textMuted, fontSize: 12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardBg,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
