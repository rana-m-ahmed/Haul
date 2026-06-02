import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.syne(
        fontSize: 56,
        fontWeight: FontWeight.bold,
        letterSpacing: -1.5,
        color: AppColors.ink,
      ),
      displayMedium: GoogleFonts.syne(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        letterSpacing: -1.0,
        color: AppColors.ink,
      ),
      displaySmall: GoogleFonts.syne(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: AppColors.ink,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: AppColors.ink,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.ink,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.stone,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.ink,
      ),
    );
  }

  // Quick access to specific styles if needed
  static TextStyle get displayXL => textTheme.displayLarge!;
  static TextStyle get displayLG => textTheme.displayMedium!;
  static TextStyle get titleLG => textTheme.titleLarge!;
  static TextStyle get bodyLG => textTheme.bodyLarge!;
  static TextStyle get labelLG => textTheme.labelLarge!;
  static TextStyle get displaySmall => textTheme.displaySmall!;
  static TextStyle get bodyMedium => textTheme.bodyMedium!;
  static TextStyle get monoMD => GoogleFonts.firaCode(fontSize: 14, color: AppColors.ink);
}
