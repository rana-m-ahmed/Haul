import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppElevation {
  static List<BoxShadow> get low => [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get mid => [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get high => [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
}
