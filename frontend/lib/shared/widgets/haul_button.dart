import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

enum ButtonVariant { primary, outlined, text }

class HaulButton extends StatelessWidget {
  final ButtonVariant variant;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final bool trailingArrow;

  const HaulButton({
    super.key,
    this.variant = ButtonVariant.primary,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.trailingArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = variant == ButtonVariant.primary ? AppColors.ink : Colors.transparent;
    final textColor = variant == ButtonVariant.primary ? AppColors.warmWhite : AppColors.ink;
    final borderColor = variant == ButtonVariant.outlined ? AppColors.ink : Colors.transparent;
    
    final labelText = trailingArrow ? '$label →' : label;

    Widget child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.signal),
              strokeWidth: 2.5,
            ),
          )
        : Text(
            labelText.toUpperCase(),
            style: AppTypography.labelLG.copyWith(color: textColor),
          );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      minimumSize: Size(isFullWidth ? double.infinity : 0, 48),
    );

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: child,
    );
  }
}
