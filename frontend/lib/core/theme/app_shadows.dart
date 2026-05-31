import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppShadows {
  static List<BoxShadow> none = [];
  static List<BoxShadow> low = [
    BoxShadow(offset: const Offset(0, 2), blurRadius: 8, color: AppColors.ink.withValues(alpha: 0.06)),
  ];
  static List<BoxShadow> mid = [
    BoxShadow(offset: const Offset(0, 4), blurRadius: 16, color: AppColors.ink.withValues(alpha: 0.10)),
  ];
  static List<BoxShadow> high = [
    BoxShadow(offset: const Offset(0, 8), blurRadius: 32, color: AppColors.ink.withValues(alpha: 0.15)),
  ];
}
