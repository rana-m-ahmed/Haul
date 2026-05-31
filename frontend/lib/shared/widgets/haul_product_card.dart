import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_animations.dart';
import '../models/product.dart';
import '../providers/wishlist_provider.dart';

class HaulProductCard extends ConsumerWidget {
  final Product product;
  final bool isHorizontal;
  final String? heroTagSuffix;
  final VoidCallback? onTap;

  const HaulProductCard({
    super.key,
    required this.product,
    this.isHorizontal = false,
    this.heroTagSuffix,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = isHorizontal ? 150.0 : 180.0;
    final height = isHorizontal ? 220.0 : 180.0;
    final radius = isHorizontal ? AppSpacing.radiusLG : AppSpacing.radiusMD;
    
    final isWishlisted = ref.watch(wishlistNotifierProvider).contains(product.id);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 12.0, end: 0.0),
      duration: reveal,
      curve: easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Opacity(
            opacity: 1.0 - (value / 12.0).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: Hero(
                  tag: 'product-image-${product.id}${heroTagSuffix ?? ''}',
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl ?? 'https://placehold.co/400x600/png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    memCacheWidth: 200,
                    placeholder: (context, url) => Container(color: AppColors.warmClay),
                    errorWidget: (context, url, error) => Container(color: AppColors.warmClay, child: const Icon(Icons.error)),
                  ),
                ),
              ),
              if (!product.inStock)
                Container(
                  color: AppColors.ink.withValues(alpha: 0.5),
                  alignment: Alignment.center,
                  child: Text(
                    'OUT OF STOCK',
                    style: AppTypography.labelSM.copyWith(color: AppColors.warmWhite),
                  ),
                ),
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.isNew) _buildBadge('NEW', AppColors.signal),
                    if (product.isNew && product.isSale) const SizedBox(height: 4),
                    if (product.isSale) _buildBadge('SALE', AppColors.errorCrimson),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => ref.read(wishlistNotifierProvider.notifier).toggle(product.id),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.warmWhite,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isWishlisted ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: isWishlisted ? AppColors.signal : AppColors.stone,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: AppSpacing.sm,
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTypography.labelSM.copyWith(
                        color: product.inStock ? AppColors.warmWhite : AppColors.warmWhite.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: AppTypography.titleSM.copyWith(
                        color: product.inStock ? AppColors.warmWhite : AppColors.warmWhite.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
      ),
      child: Text(
        text,
        style: AppTypography.labelSM.copyWith(color: AppColors.warmWhite),
      ),
    );
  }
}
