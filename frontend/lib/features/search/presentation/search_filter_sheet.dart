import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/search_provider.dart';

class SearchFilterSheet extends ConsumerStatefulWidget {
  const SearchFilterSheet({super.key});

  @override
  ConsumerState<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends ConsumerState<SearchFilterSheet> {
  double _priceMin = 0;
  double _priceMax = 1000;
  String? _category;
  double? _minRating;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(searchNotifierProvider).filters;
    _priceMin = filters.priceMin ?? 0;
    _priceMax = filters.priceMax ?? 1000;
    _category = filters.category;
    _minRating = filters.minRating;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.signal,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filters', style: AppTypography.titleMD.copyWith(color: AppColors.ink)),
                  TextButton(
                    onPressed: () {
                      ref.read(searchNotifierProvider.notifier).clearFilters();
                      Navigator.pop(context);
                    },
                    child: Text('Reset', style: AppTypography.labelSM.copyWith(color: AppColors.stone)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Price Range: \$${_priceMin.toInt()} - \$${_priceMax.toInt()}', style: AppTypography.labelMD.copyWith(color: AppColors.ink)),
              RangeSlider(
                values: RangeValues(_priceMin, _priceMax),
                min: 0,
                max: 1000,
                activeColor: AppColors.signal,
                inactiveColor: AppColors.surfaceAlt,
                onChanged: (val) {
                  setState(() {
                    _priceMin = val.start;
                    _priceMax = val.end;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Category', style: AppTypography.labelMD.copyWith(color: AppColors.ink)),
              Wrap(
                spacing: 8,
                children: [
                  'Fashion', 'Electronics', 'Home', 'Beauty'
                ].map((c) => ChoiceChip(
                  label: Text(c),
                  selected: _category == c.toLowerCase(),
                  selectedColor: AppColors.signal,
                  onSelected: (selected) {
                    setState(() => _category = selected ? c.toLowerCase() : null);
                  },
                )).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    ref.read(searchNotifierProvider.notifier).updateFilters(
                      priceMin: _priceMin > 0 ? _priceMin : null,
                      priceMax: _priceMax < 1000 ? _priceMax : null,
                      clearPriceMin: _priceMin == 0,
                      clearPriceMax: _priceMax == 1000,
                      category: _category,
                      clearCategory: _category == null,
                      minRating: _minRating,
                      clearMinRating: _minRating == null,
                    );
                    Navigator.pop(context);
                  },
                  child: Text('Apply Filters', style: AppTypography.labelMD.copyWith(color: AppColors.warmWhite)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
