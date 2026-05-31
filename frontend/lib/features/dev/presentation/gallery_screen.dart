import 'package:flutter/material.dart';
import '../../../shared/widgets/haul_button.dart';
import '../../../shared/widgets/haul_product_card.dart';
import '../../../shared/widgets/haul_skeleton.dart';
import '../../../shared/widgets/haul_ai_badge.dart';
import '../../../shared/widgets/haul_states.dart';
import '../../../shared/models/product.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleProduct1 = Product(
      id: '1',
      name: 'Oversized Vintage Wash Tee',
      price: 34.99,
      isNew: true,
      isSale: true,
    );
    
    final sampleProduct2 = Product(
      id: '2',
      name: 'Cargo Parachute Pants',
      price: 59.99,
      inStock: false,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Widget Gallery')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildSection('Buttons', Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HaulButton(label: 'Primary Button'),
              const SizedBox(height: AppSpacing.sm),
              const HaulButton(label: 'Loading Button', isLoading: true),
              const SizedBox(height: AppSpacing.sm),
              const HaulButton(label: 'Outlined Button', variant: ButtonVariant.outlined),
              const SizedBox(height: AppSpacing.sm),
              const HaulButton(label: 'Text Button', variant: ButtonVariant.text, trailingArrow: true),
              const SizedBox(height: AppSpacing.sm),
              const HaulButton(label: 'Full Width', isFullWidth: true),
            ],
          )),
          _buildSection('Product Cards (Square)', SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                HaulProductCard(product: sampleProduct1),
                const SizedBox(width: AppSpacing.md),
                HaulProductCard(product: sampleProduct2),
              ],
            ),
          )),
          _buildSection('Product Card (Horizontal)', 
            HaulProductCard(product: sampleProduct1, isHorizontal: true)
          ),
          _buildSection('AI Badges', const Row(
            children: [
              HaulAiBadge(size: HaulAiBadgeSize.sm),
              SizedBox(width: AppSpacing.md),
              HaulAiBadge(size: HaulAiBadgeSize.md),
            ],
          )),
          _buildSection('Skeletons', const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HaulSkeletonText(lines: 3),
              SizedBox(height: AppSpacing.md),
              HaulSkeletonBanner(),
              SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    HaulSkeletonCard(),
                    SizedBox(width: AppSpacing.md),
                    HaulSkeletonCard(isHorizontal: true),
                  ],
                ),
              ),
            ],
          )),
          _buildSection('States', const Column(
            children: [
              HaulEmptyState(
                title: 'No items yet',
                message: 'Start adding items to your wishlist.',
                actionLabel: 'Shop Now',
              ),
              SizedBox(height: AppSpacing.xxl),
              HaulErrorState(
                exception: RateLimitError('api'),
                actionLabel: 'Retry',
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleLG.copyWith(color: AppColors.signal)),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
