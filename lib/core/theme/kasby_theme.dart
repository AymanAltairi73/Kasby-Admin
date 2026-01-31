import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kasby_colors.dart';

/// Kasby Admin App Theme
/// Dark mode only with IBM Plex Sans Arabic typography
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

      // Typography - IBM Plex Sans Arabic
      textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(
        const TextTheme(
          // Headings
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: KasbyColors.textPrimary,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: KasbyColors.textPrimary,
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: KasbyColors.textPrimary,
          ),
          // Body
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: KasbyColors.textBody,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: KasbyColors.textBody,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: KasbyColors.textSecondary,
          ),
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
      appBarTheme: AppBarTheme(
        backgroundColor: KasbyColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.ibmPlexSansArabic(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: KasbyColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: KasbyColors.primaryGold),
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
          textStyle: GoogleFonts.ibmPlexSansArabic(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: KasbyColors.primaryGold),
    );
  }
}
