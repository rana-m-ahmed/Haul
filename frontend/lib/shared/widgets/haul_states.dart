import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/errors/app_exception.dart';
import 'haul_button.dart';

class HaulEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HaulEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 48, color: AppColors.pebble),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.titleMD.copyWith(color: AppColors.ink)),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: AppTypography.bodyMD.copyWith(color: AppColors.stone), textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            HaulButton(
              variant: ButtonVariant.outlined,
              label: actionLabel!,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

class HaulErrorState extends StatelessWidget {
  final AppException exception;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HaulErrorState({
    super.key,
    required this.exception,
    this.actionLabel = 'Retry',
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    String title = 'Something went wrong';
    String message = exception.message;

    if (exception is RateLimitError) {
      title = 'Gemini is busy...';
      message = 'Please wait a moment before trying again.';
    } else if (exception is NetworkException) {
      title = 'No Connection';
      message = 'Please check your internet and try again.';
    } else if (exception is NotFoundError) {
      title = 'Not Found';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.pebble),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.titleMD.copyWith(color: AppColors.ink)),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: AppTypography.bodyMD.copyWith(color: AppColors.stone), textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            HaulButton(
              variant: ButtonVariant.outlined,
              label: actionLabel!,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
