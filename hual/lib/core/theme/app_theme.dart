import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radius.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: AppColors.warmWhite,
      colorScheme: const ColorScheme.light(
        primary: AppColors.signal,
        onPrimary: AppColors.surface,
        secondary: AppColors.ink,
        onSecondary: AppColors.surface,
        surface: AppColors.surface,
        error: AppColors.errorCrimson,
        onError: AppColors.surface,
      ),
      textTheme: AppTypography.textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.signal,
          foregroundColor: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.labelLG,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.warmWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLG,
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.signal,
        unselectedItemColor: AppColors.pebble,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
