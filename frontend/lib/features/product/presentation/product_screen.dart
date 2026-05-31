import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/providers/wishlist_provider.dart';
import '../../../shared/widgets/haul_product_card.dart';
import '../../../shared/widgets/haul_skeleton.dart';
import '../../../shared/widgets/haul_states.dart';
import '../../../shared/widgets/haul_ai_badge.dart';
import '../domain/product_provider.dart';

class ProductScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 50),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _addToCart() {
    final product = ref.read(productNotifierProvider(widget.productId)).product;
    if (product != null) {
      ref.read(cartNotifierProvider.notifier).addItem(product, variant: _selectedColor);
      _bounceController.forward(from: 0.0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to cart'), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productNotifierProvider(widget.productId));
    final isWishlisted = ref.watch(wishlistNotifierProvider).contains(widget.productId);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator(color: AppColors.signal)),
      );
    }

    if (state.error != null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: HaulErrorState(
            exception: BackendError(state.error!),
            actionLabel: 'Go Back',
            onAction: () => context.pop(),
          ),
        ),
      );
    }

    final product = state.product;
    if (product == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product no longer available')),
        );
      });
      return const Scaffold(backgroundColor: AppColors.surface);
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.55,
            pinned: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.warmWhite.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: AppColors.ink),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.warmWhite.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isWishlisted ? Icons.favorite : Icons.favorite_border,
                      color: isWishlisted ? AppColors.signal : AppColors.ink,
                    ),
                    onPressed: () {
                      ref.read(wishlistNotifierProvider.notifier).toggle(widget.productId);
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: RepaintBoundary(
                child: Hero(
                  tag: 'product-image-${product.id}',
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl ?? 'https://placehold.co/600x800/png',
                    fit: BoxFit.cover,
                    memCacheWidth: 600,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CATEGORY', style: AppTypography.labelMD.copyWith(color: AppColors.stone)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(product.name, style: AppTypography.displayLG.copyWith(color: AppColors.ink)),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text('\$${product.price.toStringAsFixed(2)}', style: AppTypography.monoMD.copyWith(color: AppColors.signal, fontSize: 20)),
                      if (product.isSale) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text('\$${(product.price * 1.2).toStringAsFixed(2)}', style: AppTypography.monoMD.copyWith(
                          color: AppColors.pebble,
                          decoration: TextDecoration.lineThrough,
                        )),
                      ]
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: () {}, // would map to reviews
                    child: Text('4.8 ★ (127 reviews)', style: AppTypography.bodySM.copyWith(color: AppColors.stone)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(height: 1, color: AppColors.surfaceAlt),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Variants
                  Text('Color', style: AppTypography.labelMD.copyWith(color: AppColors.ink)),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: ['Red', 'Blue', 'Black'].map((c) {
                      final isSelected = _selectedColor == c;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = c),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c == 'Red' ? Colors.red : (c == 'Blue' ? Colors.blue : Colors.black),
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected ? Border.all(color: AppColors.signal, width: 2) : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // AI Explanation
                  _buildExplanation(state),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // You May Also Like
                  if (state.similarProducts.isNotEmpty) ...[
                    Text('YOU MAY ALSO LIKE', style: AppTypography.labelMD.copyWith(color: AppColors.ink)),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.similarProducts.length,
                        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) => HaulProductCard(
                          product: state.similarProducts[index],
                          isHorizontal: true,
                          heroTagSuffix: 'similar',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Mock Reviews
                  Text('REVIEWS', style: AppTypography.labelMD.copyWith(color: AppColors.ink)),
                  const SizedBox(height: AppSpacing.md),
                  _buildMockReview('AS', 'Alice Smith', '2 days ago', 'Absolutely love this! The quality is amazing and it fits perfectly.'),
                  const SizedBox(height: AppSpacing.md),
                  _buildMockReview('JD', 'John Doe', '1 week ago', 'Great product, but shipping took a bit longer than expected.'),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: Text('See all 127 reviews →', style: AppTypography.labelSM.copyWith(color: AppColors.ink)),
                    ),
                  ),
                  const SizedBox(height: 100), // padding for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildStickyBar(),
    );
  }

  Widget _buildExplanation(ProductState state) {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.startsWith('guest_')) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('WHY YOU\'LL LOVE THIS', style: AppTypography.labelMD.copyWith(color: AppColors.stone)),
              const SizedBox(width: AppSpacing.xs),
              const HaulAiBadge(size: HaulAiBadgeSize.sm),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.isExplanationLoading)
            const HaulSkeletonText(lines: 3)
          else if (state.explanation != null)
            Text(
              state.explanation!.explanation,
              style: AppTypography.bodyMD.copyWith(color: AppColors.stone),
            )
          else
            Text('We think this is a great match for you.', style: AppTypography.bodyMD.copyWith(color: AppColors.stone)),
        ],
      ),
    );
  }

  Widget _buildMockReview(String initials, String name, String date, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.surfaceAlt,
              child: Text(initials, style: AppTypography.labelSM.copyWith(color: AppColors.stone)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(name, style: AppTypography.bodyMD.copyWith(color: AppColors.ink, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(date, style: AppTypography.bodySM.copyWith(color: AppColors.pebble)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: List.generate(5, (index) => const Icon(Icons.star, color: AppColors.signal, size: 14)),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(text, style: AppTypography.bodyMD.copyWith(color: AppColors.stone)),
      ],
    );
  }

  Widget _buildStickyBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        border: Border(top: BorderSide(color: AppColors.surfaceAlt)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ScaleTransition(
              scale: _bounceAnimation,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.signal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _addToCart,
                child: Text('ADD TO CART', style: AppTypography.labelMD.copyWith(color: AppColors.signal)),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                _addToCart();
                // context.push('/cart'); // later
              },
              child: Text('BUY NOW', style: AppTypography.labelMD.copyWith(color: AppColors.warmWhite)),
            ),
          ),
        ],
      ),
    );
  }
}
