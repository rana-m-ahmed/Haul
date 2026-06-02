import 'package:flutter/material.dart';

enum HaulButtonVariant { primary, outlined, text }

class HaulButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final HaulButtonVariant variant;

  const HaulButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = HaulButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case HaulButtonVariant.primary:
        return ElevatedButton(
          onPressed: onPressed,
          child: Text(label),
        );
      case HaulButtonVariant.outlined:
        return OutlinedButton(
          onPressed: onPressed,
          child: Text(label),
        );
      case HaulButtonVariant.text:
        return TextButton(
          onPressed: onPressed,
          child: Text(label),
        );
    }
  }
}
