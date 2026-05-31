import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.warmWhite,
      primaryColor: AppColors.signal,
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMD)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.warmWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        titleTextStyle: AppTypography.titleLG.copyWith(color: AppColors.ink),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayXL.copyWith(color: AppColors.ink),
        displayMedium: AppTypography.displayLG.copyWith(color: AppColors.ink),
        displaySmall: AppTypography.displayMD.copyWith(color: AppColors.ink),
        headlineMedium: AppTypography.displaySM.copyWith(color: AppColors.ink),
        titleLarge: AppTypography.titleLG.copyWith(color: AppColors.ink),
        titleMedium: AppTypography.titleMD.copyWith(color: AppColors.ink),
        titleSmall: AppTypography.titleSM.copyWith(color: AppColors.ink),
        bodyLarge: AppTypography.bodyLG.copyWith(color: AppColors.ink),
        bodyMedium: AppTypography.bodyMD.copyWith(color: AppColors.ink),
        bodySmall: AppTypography.bodySM.copyWith(color: AppColors.ink),
        labelLarge: AppTypography.labelLG.copyWith(color: AppColors.ink),
        labelMedium: AppTypography.labelMD.copyWith(color: AppColors.ink),
        labelSmall: AppTypography.labelSM.copyWith(color: AppColors.ink),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.signal,
        secondary: AppColors.stone,
        surface: AppColors.warmWhite,
        error: AppColors.errorCrimson,
        onPrimary: AppColors.warmWhite,
        onSecondary: AppColors.warmWhite,
        onSurface: AppColors.ink,
        onError: AppColors.warmWhite,
      ),
    );
  }
}
