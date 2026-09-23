import 'package:flutter/material.dart';

/// App color palette based on high-contrast Neo-Brutalist & Swiss poster aesthetics.
class AppColors {
  AppColors._();

  // Core Backgrounds
  static const Color background = Color(0xFF0C0C0E);
  static const Color surface = Color(0xFF141418);
  static const Color surfaceElevated = Color(0xFF1E1E24);
  static const Color surfaceCard = Color(0xFF18181D);

  // Pure Neutrals
  static const Color white = Color(0xFFF7F7F8);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color cream = Color(0xFFF4F0E8);
  static const Color pureBlack = Color(0xFF000000);

  // Text Hierarchy
  static const Color textPrimary = Color(0xFFF7F7F8);
  static const Color textSecondary = Color(0xFFA6A6B2);
  static const Color textMuted = Color(0xFF6E6E7A);

  // Borders & Structural Grid
  static const Color border = Color(0xFF2C2C35);
  static const Color borderSubtle = Color(0xFF202027);
  static const Color borderBold = Color(0xFFF7F7F8);

  // Vivid Acid / Poster Punch Accents
  static const Color acidLime = Color(0xFFD4FF00);       // Ultra neon chartreuse
  static const Color electricPink = Color(0xFFFF2E93);   // Shocking poster pink
  static const Color cobaltBlue = Color(0xFF2640FF);     // Pure Swiss cobalt
  static const Color vermillion = Color(0xFFFF3B30);     // High-voltage red/orange
  static const Color cyberCyan = Color(0xFF00F0FF);      // Electric cyan

  // Active theme accent (default is Acid Lime)
  static const Color primaryAccent = acidLime;
  static const Color onPrimaryAccent = pureBlack;
}
