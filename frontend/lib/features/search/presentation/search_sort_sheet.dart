import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/search_provider.dart';

class SearchSortSheet extends ConsumerWidget {
  const SearchSortSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchNotifierProvider);
    final sortBy = state.filters.sortBy;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Text('Sort By', style: AppTypography.titleMD.copyWith(color: AppColors.ink)),
            const SizedBox(height: AppSpacing.md),
            _buildRadio(context, ref, 'relevance', 'Relevance', sortBy),
            _buildRadio(context, ref, 'price_asc', 'Price: Low to High', sortBy),
            _buildRadio(context, ref, 'price_desc', 'Price: High to Low', sortBy),
            _buildRadio(context, ref, 'newest', 'Newest', sortBy),
            _buildRadio(context, ref, 'rating', 'Top Rated', sortBy),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildRadio(BuildContext context, WidgetRef ref, String value, String label, String groupValue) {
    return RadioListTile<String>(
      value: value,
      // ignore: deprecated_member_use
      groupValue: groupValue,
      activeColor: AppColors.signal,
      title: Text(label, style: AppTypography.bodyMD.copyWith(color: AppColors.ink)),
      // ignore: deprecated_member_use
      onChanged: (val) {
        if (val != null) {
          ref.read(searchNotifierProvider.notifier).updateFilters(sortBy: val);
          Navigator.pop(context);
        }
      },
    );
  }
}
