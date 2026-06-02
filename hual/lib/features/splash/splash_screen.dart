import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_animations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.signal,
      body: Center(
        child: TweenAnimationBuilder<double>(
          duration: AppAnimations.hero,
          tween: Tween(begin: 0.0, end: 1.0),
          curve: AppAnimations.defaultCurve,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Text(
            'HAUL',
            style: AppTypography.displayXL.copyWith(
              color: AppColors.surface,
              letterSpacing: 4.0,
            ),
          ),
        ),
      ),
    );
  }
}
