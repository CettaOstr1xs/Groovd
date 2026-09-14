import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Bold & exaggerated typography system inspired by Swiss brutalist concert posters.
class AppTypography {
  AppTypography._();

  // Mega Hero / Poster Display
  static TextStyle displayMassive({Color color = AppColors.textPrimary, double? fontSize}) =>
      GoogleFonts.syne(
        fontSize: fontSize ?? 46,
        fontWeight: FontWeight.w900,
        letterSpacing: -2.0,
        height: 0.95,
        color: color,
      );

  static TextStyle displayHero({Color color = AppColors.textPrimary, double? fontSize}) =>
      GoogleFonts.syne(
        fontSize: fontSize ?? 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        height: 1.0,
        color: color,
      );

  static TextStyle displayMedium({Color color = AppColors.textPrimary, double? fontSize}) =>
      GoogleFonts.syne(
        fontSize: fontSize ?? 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        height: 1.1,
        color: color,
      );

  static TextStyle displaySmall({Color color = AppColors.textPrimary, double? fontSize}) =>
      GoogleFonts.syne(
        fontSize: fontSize ?? 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.15,
        color: color,
      );

  // Big Impact Numbers (Ratings, Badges, Ranks)
  static TextStyle scoreGiant({Color color = AppColors.pureBlack}) =>
      GoogleFonts.archivoBlack(
        fontSize: 54,
        fontWeight: FontWeight.w900,
        letterSpacing: -2.5,
        height: 0.9,
        color: color,
      );

  static TextStyle scoreLarge({Color color = AppColors.textPrimary}) =>
      GoogleFonts.archivoBlack(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.5,
        height: 0.95,
        color: color,
      );

  static TextStyle scoreMedium({Color color = AppColors.textPrimary}) =>
      GoogleFonts.archivoBlack(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: color,
      );

  // Zine / Monospaced Editorial Metadata
  static TextStyle monoLabel({
    Color color = AppColors.textSecondary,
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 1.8,
  }) =>
      GoogleFonts.spaceMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle monoBadge({
    Color color = AppColors.pureBlack,
    double fontSize = 10,
  }) =>
      GoogleFonts.spaceMono(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: color,
      );

  // Readable Editorial Body & Reviews
  static TextStyle headline({Color color = AppColors.textPrimary}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.25,
        color: color,
      );

  static TextStyle bodyLarge({Color color = AppColors.textPrimary}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        height: 1.45,
        color: color,
      );

  static TextStyle bodyMedium({Color color = AppColors.textSecondary}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        height: 1.4,
        color: color,
      );

  static TextStyle bodySmall({Color color = AppColors.textMuted}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.35,
        color: color,
      );

  // Punchy Button Labels
  static TextStyle buttonLabel({
    Color color = AppColors.pureBlack,
    double fontSize = 13,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: color,
      );
}
