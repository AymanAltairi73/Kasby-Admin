import 'package:flutter/material.dart';
import 'kasby_colors.dart';

/// Kasby Theme
/// Dark theme with Kasby brand colors and IBM Plex Sans Arabic font
class KasbyTheme {
  KasbyTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: KasbyColors.background,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: KasbyColors.primaryGold,
        secondary: KasbyColors.primaryGoldLight,
        surface: KasbyColors.surface,
        error: KasbyColors.error,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: KasbyColors.textPrimary,
        onError: Colors.white,
      ),

      // Text Theme - IBM Plex Sans Arabic from local assets
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: KasbyColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: KasbyColors.textPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: KasbyColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: KasbyColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: KasbyColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: KasbyColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 16,
          color: KasbyColors.textBody,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 14,
          color: KasbyColors.textBody,
        ),
        bodySmall: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 12,
          color: KasbyColors.textSecondary,
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: KasbyColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: KasbyColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: KasbyColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: KasbyColors.primaryGold),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KasbyColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: KasbyColors.primaryGold,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: KasbyColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: KasbyColors.textSecondary),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KasbyColors.primaryGold,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: KasbyColors.primaryGold),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: KasbyColors.backgroundLight,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: KasbyColors.primaryGold,
        secondary: KasbyColors.primaryGoldLight,
        surface: KasbyColors.surfaceLight,
        error: KasbyColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: KasbyColors.textPrimaryLight,
        onError: Colors.white,
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: KasbyColors.textPrimaryLight,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 16,
          color: KasbyColors.textBodyLight,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 14,
          color: KasbyColors.textBodyLight,
        ),
        bodySmall: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 12,
          color: KasbyColors.textSecondaryLight,
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: KasbyColors.surfaceLight,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: KasbyColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'IBMPlexSansArabic',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: KasbyColors.textPrimaryLight,
        ),
        iconTheme: IconThemeData(color: KasbyColors.primaryGold),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: KasbyColors.primaryGold,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: KasbyColors.textSecondaryLight),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KasbyColors.primaryGold,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      iconTheme: const IconThemeData(color: KasbyColors.primaryGold),
    );
  }
}
