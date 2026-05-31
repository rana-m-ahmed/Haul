import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/providers/cart_provider.dart';
import '../../../shared/widgets/haul_states.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showHint = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showHint = false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartNotifierProvider);
    final cartNotifier = ref.read(cartNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Text('MY CART', style: AppTypography.titleLG.copyWith(color: AppColors.ink)),
            const SizedBox(width: AppSpacing.sm),
            Text('(${cartNotifier.itemCount})', style: AppTypography.titleLG.copyWith(color: AppColors.stone)),
          ],
        ),
      ),
      body: cartItems.isEmpty
          ? Center(
              child: HaulEmptyState(
                title: 'Your cart is empty',
                message: 'Looks like you haven\'t added anything yet.',
                actionLabel: 'START SHOPPING →',
                onAction: () => context.go('/home'),
              ),
            )
          : Column(
              children: [
                if (_showHint)
                  AnimatedOpacity(
                    opacity: _showHint ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('swipe to remove →', style: AppTypography.labelSM.copyWith(color: AppColors.pebble)),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    itemCount: cartItems.length,
                    separatorBuilder: (context, index) => Container(height: 1, color: AppColors.surfaceAlt),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: AppColors.signal,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: AppSpacing.md),
                          child: const Icon(Icons.delete, color: AppColors.warmWhite),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Remove item?', style: AppTypography.titleMD.copyWith(color: AppColors.ink)),
                              content: Text('Are you sure you want to remove this item from your cart?', style: AppTypography.bodyMD.copyWith(color: AppColors.stone)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Cancel', style: AppTypography.labelMD.copyWith(color: AppColors.stone)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Remove', style: AppTypography.labelMD.copyWith(color: AppColors.signal)),
                                ),
                              ],
                            ),
                          ) ?? false;
                        },
                        onDismissed: (direction) {
                          cartNotifier.removeItem(item.id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: item.product.imageUrl ?? 'https://placehold.co/72x72/png',
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 200,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name, style: AppTypography.titleMD.copyWith(color: AppColors.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    if (item.variant != null)
                                      Text(item.variant!, style: AppTypography.bodySM.copyWith(color: AppColors.stone)),
                                    const SizedBox(height: AppSpacing.sm),
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () => cartNotifier.updateQuantity(item.id, item.quantity - 1),
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            alignment: Alignment.center,
                                            child: Text('−', style: AppTypography.labelMD.copyWith(color: AppColors.signal)),
                                          ),
                                        ),
                                        Text('${item.quantity}', style: AppTypography.labelMD.copyWith(color: AppColors.ink)),
                                        GestureDetector(
                                          onTap: () => cartNotifier.updateQuantity(item.id, item.quantity + 1),
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            alignment: Alignment.center,
                                            child: Text('+', style: AppTypography.labelMD.copyWith(color: AppColors.signal)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text('\$${(item.product.price * item.quantity).toStringAsFixed(2)}', style: AppTypography.monoMD.copyWith(color: AppColors.ink)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warmWhite,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('SUBTOTAL', style: AppTypography.labelSM.copyWith(color: AppColors.stone)),
                                Text('\$${cartNotifier.subtotal.toStringAsFixed(2)}', style: AppTypography.monoMD.copyWith(color: AppColors.ink)),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('SHIPPING', style: AppTypography.labelSM.copyWith(color: AppColors.stone)),
                                Text('Calculated at checkout', style: AppTypography.bodySM.copyWith(color: AppColors.stone)),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('TOTAL', style: AppTypography.labelMD.copyWith(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('\$${cartNotifier.subtotal.toStringAsFixed(2)}', style: AppTypography.monoMD.copyWith(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ink,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            context.push('/checkout');
                          },
                          child: Text('PROCEED TO CHECKOUT →', style: AppTypography.labelMD.copyWith(color: AppColors.warmWhite)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
