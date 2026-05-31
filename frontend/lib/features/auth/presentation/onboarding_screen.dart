import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/haul_button.dart';
import '../../../shared/providers/auth_provider.dart';
import 'sign_up_sheet.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _openSignUpSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SignUpSheet(),
    );
  }

  Future<void> _continueAsGuest() async {
    await ref.read(authNotifierProvider.notifier).signInAsGuest();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildPage1(),
          _buildPage2(),
        ],
      ),
    );
  }

  Widget _buildPage1() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 55,
              child: Stack(
                children: [
                  Positioned(
                    top: 40,
                    left: 0,
                    child: Transform.rotate(
                      angle: -0.0349, // roughly -2 degrees
                      child: Text(
                        'SEE',
                        style: AppTypography.displayXL.copyWith(fontSize: 72, color: AppColors.signal),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 48,
                    left: 140, // offset right
                    child: Text(
                      'IT.',
                      style: AppTypography.displayXL.copyWith(fontSize: 72, color: AppColors.ink),
                    ),
                  ),
                  Positioned(
                    top: 130,
                    left: 0,
                    child: Text(
                      'FIND',
                      style: AppTypography.displayXL.copyWith(fontSize: 52, color: AppColors.stone),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 45,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(width: 60, height: 1, color: AppColors.signal),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Point your camera at anything. Haul finds it.',
                    style: AppTypography.bodyLG.copyWith(color: AppColors.stone),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    children: [
                      Container(width: 24, height: 2, color: AppColors.signal),
                      const SizedBox(width: AppSpacing.xs),
                      Container(width: 8, height: 2, color: AppColors.signalLight),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  HaulButton(
                    label: 'NEXT',
                    trailingArrow: true,
                    isFullWidth: true,
                    onPressed: _nextPage,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage2() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOUR', style: AppTypography.displayXL.copyWith(fontSize: 48, color: AppColors.ink)),
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Text('TASTE.', style: AppTypography.displayXL.copyWith(fontSize: 48, color: AppColors.signal)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 64),
                      child: Text('YOUR', style: AppTypography.displayXL.copyWith(fontSize: 48, color: AppColors.ink)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 96),
                      child: Text('FEED.', style: AppTypography.displayXL.copyWith(fontSize: 48, color: AppColors.signal)),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                HaulButton(
                  label: 'GET STARTED',
                  isFullWidth: true,
                  onPressed: _openSignUpSheet,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: _continueAsGuest,
                  child: Text(
                    'or continue as guest',
                    style: AppTypography.bodyMD.copyWith(color: AppColors.stone),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
