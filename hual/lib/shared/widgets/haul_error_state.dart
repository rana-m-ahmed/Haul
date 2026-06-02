import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import 'haul_button.dart';

class HaulErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const HaulErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.errorCrimson,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyLG.copyWith(color: AppColors.ink),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              HaulButton(
                label: 'Try Again',
                onPressed: onRetry!,
                variant: HaulButtonVariant.outlined,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
