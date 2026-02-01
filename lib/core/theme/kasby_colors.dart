import 'package:flutter/material.dart';

/// Kasby Brand Color Palette
/// Strict adherence to brand identity
class KasbyColors {
  KasbyColors._();

  // Primary Gold
  static const Color primaryGold = Color(0xFFC9A24D);
  static const Color primaryGoldLight = Color(0xFFE5C173);

  // Backgrounds
  static const Color background = Color(0xFF0E0E11);
  static const Color surface = Color(0xFF1A1A1F);
  static const Color glassBackground = Color(0x1AFFFFFF);

  // Premium Light Mode Palette
  static const Color backgroundLight = Color(
    0xFFF9FAFB,
  ); // Very light gray-blue
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Glow Colors for Stats
  static const Color glowGold = Color(0xFFFFD700);
  static const Color glowGreen = Color(0xFF00FF88);
  static const Color glowBlue = Color(0xFF00D1FF);
  static const Color glowOrange = Color(0xFFFF9D00);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFCF6679);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Text Colors - Dark Mode
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textBody = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color textDisabled = Color(0xFF707070);

  // Text Colors - Light Mode
  static const Color textPrimaryLight = Color(0xFF111827); // Deep Slate
  static const Color textBodyLight = Color(0xFF374151); // Medium Slate
  static const Color textSecondaryLight = Color(0xFF6B7280); // Muted Slate
  static const Color textDisabledLight = Color(0xFF9CA3AF);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGold, primaryGoldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
