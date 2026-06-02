import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/haul_skeleton.dart';
import '../../shared/widgets/animated_wrappers.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Discover',
          style: AppTypography.displaySmall.copyWith(color: AppColors.ink),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (context, index) {
          return StaggeredListWrapper(
            index: index,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HaulSkeleton(
                  width: double.infinity,
                  height: 200,
                  borderRadius: 16,
                ),
                const SizedBox(height: AppSpacing.sm),
                const HaulSkeleton(width: 150, height: 24),
                const SizedBox(height: AppSpacing.xs),
                const HaulSkeleton(width: 80, height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
