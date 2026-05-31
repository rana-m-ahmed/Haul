import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/preferences_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _wordmarkOpacity;
  late Animation<double> _wordmarkSlide;
  late Animation<double> _taglineOpacity;
  late Animation<double> _taglineSlide;
  late Animation<double> _hairlineWidth;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    _wordmarkOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.444, curve: Curves.easeOutCubic)),
    );
    _wordmarkSlide = Tween<double>(begin: 12, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.444, curve: Curves.easeOutCubic)),
    );

    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.333, 0.666, curve: Curves.easeOutCubic)),
    );
    _taglineSlide = Tween<double>(begin: 12, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.333, 0.666, curve: Curves.easeOutCubic)),
    );

    _hairlineWidth = Tween<double>(begin: 0, end: 48).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.777, 1.0, curve: Curves.easeOutCubic)),
    );

    _controller.forward();
    _startAnimationAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startAnimationAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    
    if (!mounted) return;
    
    final authState = await ref.read(authNotifierProvider.future);
    
    if (!mounted) return;
    
    if (authState.status == AuthState.authenticated && authState.uid != null) {
      if (authState.isGuest) {
         context.go('/home');
         return;
      }
      
      final prefs = await ref.read(preferencesNotifierProvider.future);
      if (!mounted) return;

      if (prefs.isEmpty) {
        context.go('/preferences');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: Offset(0, _wordmarkSlide.value),
                  child: Opacity(
                    opacity: _wordmarkOpacity.value,
                    child: Text(
                      'haul',
                      style: AppTypography.displayXL.copyWith(
                        fontSize: 48,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Transform.translate(
                  offset: Offset(0, _taglineSlide.value),
                  child: Opacity(
                    opacity: _taglineOpacity.value,
                    child: const Text(
                      'shop what you see',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                        color: AppColors.stone,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: _hairlineWidth.value,
                  height: 1,
                  color: AppColors.signal,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
