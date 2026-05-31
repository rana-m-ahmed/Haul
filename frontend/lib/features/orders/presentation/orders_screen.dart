import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/haul_states.dart';
import '../domain/orders_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('MY ORDERS', style: AppTypography.titleLG.copyWith(color: AppColors.ink)),
      ),
      body: (userId == null || userId.startsWith('guest_'))
          ? Center(
              child: HaulEmptyState(
                title: 'Sign in to see your orders',
                message: 'Track, return, or buy items again.',
                actionLabel: 'SIGN IN',
                onAction: () => context.push('/onboarding'),
              ),
            )
          : _buildOrdersList(ref, context),
    );
  }

  Widget _buildOrdersList(WidgetRef ref, BuildContext context) {
    final ordersAsync = ref.watch(ordersNotifierProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: HaulEmptyState(
              title: 'No orders yet',
              message: 'When you place an order, it will show up here.',
              actionLabel: 'START SHOPPING →',
              onAction: () => context.go('/home'),
            ),
          );
        }

        return ListView.separated(
          itemCount: orders.length,
          separatorBuilder: (context, index) => Container(height: 1, color: AppColors.surfaceAlt),
          itemBuilder: (context, index) {
            final order = orders[index];
            final items = (order['items'] as List<dynamic>?) ?? [];
            final String orderId = order['id'] ?? 'UNKNOWN';
            final String status = order['status'] ?? 'processing';
            final String dateStr = order['createdAt'] ?? '';
            String formattedDate = '';
            try {
              if (dateStr.isNotEmpty) {
                formattedDate = DateFormat('MMM d, yyyy').format(DateTime.parse(dateStr));
              }
            } catch (_) {}

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  _buildThumbnails(items),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('#$orderId', style: AppTypography.labelMD.copyWith(color: AppColors.ink)),
                        const SizedBox(height: 4),
                        Text(formattedDate, style: AppTypography.bodySM.copyWith(color: AppColors.stone)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusBadge(status),
                      const SizedBox(height: 8),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {},
                        child: Text('VIEW →', style: AppTypography.labelSM.copyWith(color: AppColors.ink)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.signal)),
      error: (err, _) => Center(child: Text(err.toString())),
    );
  }

  Widget _buildThumbnails(List<dynamic> items) {
    if (items.isEmpty) return const SizedBox(width: 56, height: 56);
    
    if (items.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: items[0]['imageUrl'] ?? 'https://placehold.co/56x56/png',
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          memCacheWidth: 200,
        ),
      );
    }

    return SizedBox(
      width: 64,
      height: 56,
      child: Stack(
        children: [
          Positioned(
            left: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: items[1]['imageUrl'] ?? 'https://placehold.co/56x56/png',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                memCacheWidth: 200,
              ),
            ),
          ),
          Positioned(
            left: 0,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.surface, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: items[0]['imageUrl'] ?? 'https://placehold.co/56x56/png',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  memCacheWidth: 200,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color textColor;
    Color borderColor = Colors.transparent;
    Color bgColor = Colors.transparent;
    
    final s = status.toLowerCase();
    if (s == 'processing' || s == 'confirmed') {
      textColor = AppColors.warningAmber;
      borderColor = AppColors.warningAmber;
    } else if (s == 'shipped') {
      textColor = AppColors.signal;
      borderColor = AppColors.signal;
    } else {
      textColor = AppColors.warmWhite;
      bgColor = AppColors.successForest;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        border: borderColor != Colors.transparent ? Border.all(color: borderColor) : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        s.toUpperCase(),
        style: AppTypography.labelSM.copyWith(color: textColor, fontSize: 10),
      ),
    );
  }
}
