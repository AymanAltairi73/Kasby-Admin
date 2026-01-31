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

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFCF6679);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textBody = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color textDisabled = Color(0xFF707070);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGold, primaryGoldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
