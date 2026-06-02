import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

class HaulAiBadge extends StatelessWidget {
  final String text;

  const HaulAiBadge({super.key, this.text = 'AI Powered'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.signal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.signal.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 14, color: AppColors.signal),
          const SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: AppTypography.labelLG.copyWith(
              color: AppColors.signal,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
