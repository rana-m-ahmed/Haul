import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_radius.dart';

class HaulProductCard extends StatelessWidget {
  final Widget child;
  
  const HaulProductCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppElevation.low,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: child,
      ),
    );
  }
}
