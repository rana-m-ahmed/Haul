import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

enum HaulAiBadgeSize { sm, md }

class HaulAiBadge extends StatelessWidget {
  final HaulAiBadgeSize size;

  const HaulAiBadge({super.key, this.size = HaulAiBadgeSize.sm});

  @override
  Widget build(BuildContext context) {
    final isSm = size == HaulAiBadgeSize.sm;
    final padding = isSm 
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 4);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
        border: Border.all(color: AppColors.signal, width: 1),
      ),
      child: Text(
        'AI',
        style: AppTypography.labelSM.copyWith(color: AppColors.signal),
      ),
    );
  }
}
