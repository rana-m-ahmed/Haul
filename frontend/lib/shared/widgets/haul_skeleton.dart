import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class HaulSkeletonCard extends StatelessWidget {
  final bool isHorizontal;
  
  const HaulSkeletonCard({super.key, this.isHorizontal = false});

  @override
  Widget build(BuildContext context) {
    final width = isHorizontal ? 150.0 : 180.0;
    final height = isHorizontal ? 220.0 : 180.0;
    final radius = isHorizontal ? AppSpacing.radiusLG : AppSpacing.radiusMD;

    return Shimmer.fromColors(
      baseColor: AppColors.warmClay,
      highlightColor: AppColors.surfaceAlt,
      period: const Duration(milliseconds: 1400),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.warmClay,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class HaulSkeletonBanner extends StatelessWidget {
  const HaulSkeletonBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.warmClay,
      highlightColor: AppColors.surfaceAlt,
      period: const Duration(milliseconds: 1400),
      child: Container(
        width: double.infinity,
        height: 180.0,
        color: AppColors.warmClay,
      ),
    );
  }
}

class HaulSkeletonText extends StatelessWidget {
  final int lines;
  const HaulSkeletonText({super.key, this.lines = 1});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.warmClay,
      highlightColor: AppColors.surfaceAlt,
      period: const Duration(milliseconds: 1400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(lines, (index) {
          double widthFactor = 1.0;
          if (index % 3 == 1) widthFactor = 0.8;
          if (index % 3 == 2) widthFactor = 0.6;
          
          return FractionallySizedBox(
            widthFactor: widthFactor,
            child: Container(
              height: 20.0,
              margin: EdgeInsets.only(bottom: index == lines - 1 ? 0 : AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warmClay,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
              ),
            ),
          );
        }),
      ),
    );
  }
}
