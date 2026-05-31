import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../shared/widgets/haul_product_card.dart';
import '../../../shared/widgets/haul_states.dart';
import '../../../shared/widgets/haul_ai_badge.dart';
import '../domain/visual_search_provider.dart';

class VisualSearchResultsSheet extends ConsumerWidget {
  const VisualSearchResultsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visualSearchNotifierProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.30,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: AppShadows.mid,
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.signal,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _buildContent(context, ref, state),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, VisualSearchState state) {
    if (state.status == VisualSearchStatus.processing || state.status == VisualSearchStatus.capturing) {
      return const SizedBox.shrink(); 
    }

    if (state.status == VisualSearchStatus.failed) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            HaulErrorState(
              exception: state.error!,
              actionLabel: 'TRY AGAIN →',
              onAction: () {
                ref.read(visualSearchNotifierProvider.notifier).reset();
                context.pop(); 
              },
            ),
          ],
        ),
      );
    }

    final data = state.data;
    if (data == null || data.products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: HaulEmptyState(
          title: 'No Matches Found',
          message: data?.noResultsReason ?? 'We couldn\'t find any exact matches for this item.',
          actionLabel: 'TRY AGAIN →',
          onAction: () {
            ref.read(visualSearchNotifierProvider.notifier).reset();
            context.pop();
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Text('WE FOUND THESE', style: AppTypography.labelMD.copyWith(color: AppColors.stone)),
              const SizedBox(width: AppSpacing.xs),
              const HaulAiBadge(size: HaulAiBadgeSize.sm),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: data.products.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final product = data.products[index];
              return Stack(
                children: [
                  HaulProductCard(product: product, isHorizontal: true),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(product.matchScore * 100).toInt()}% MATCH',
                        style: AppTypography.labelSM.copyWith(color: AppColors.warmWhite, fontSize: 8),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: TextButton(
            onPressed: () {
              final query = data.query.keywords.join(' ');
              context.push('/search?q=$query');
            },
            child: Text(
              'BROWSE ALL RESULTS →',
              style: AppTypography.labelSM.copyWith(color: AppColors.ink),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
