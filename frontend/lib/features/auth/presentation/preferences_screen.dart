import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/haul_button.dart';
import '../../../shared/providers/preferences_provider.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  final Set<String> _selected = {};
  
  final List<Map<String, String>> _categories = [
    {'id': 'fashion', 'label': 'Fashion', 'desc': 'Apparel & clothing'},
    {'id': 'electronics', 'label': 'Electronics', 'desc': 'Gadgets & devices'},
    {'id': 'home', 'label': 'Home', 'desc': 'Decor & furniture'},
    {'id': 'skincare', 'label': 'Skincare', 'desc': 'Beauty & health'},
    {'id': 'fitness', 'label': 'Fitness', 'desc': 'Gear & activewear'},
    {'id': 'accessories', 'label': 'Accessories', 'desc': 'Jewelry & bags'},
  ];

  Future<void> _submit() async {
    await ref.read(preferencesNotifierProvider.notifier).savePreferences(_selected.toList());
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(preferencesNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('what do you shop for?', style: AppTypography.labelLG.copyWith(color: AppColors.stone)),
              const SizedBox(height: AppSpacing.xs),
              Text('Choose at least one category to personalize your feed.', style: AppTypography.bodySM.copyWith(color: AppColors.pebble)),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selected.contains(cat['id']);
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selected.remove(cat['id']);
                          } else {
                            _selected.add(cat['id']!);
                          }
                        });
                      },
                      child: AnimatedScale(
                        scale: isSelected ? 0.95 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.ink : AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                            border: Border.all(
                              color: isSelected ? AppColors.signal : AppColors.pebble,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              if (isSelected)
                                const Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Icon(Icons.check_circle, color: AppColors.warmWhite, size: 20),
                                ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    cat['label']!,
                                    style: AppTypography.titleMD.copyWith(
                                      color: isSelected ? AppColors.warmWhite : AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    cat['desc']!,
                                    style: AppTypography.labelSM.copyWith(
                                      color: isSelected ? AppColors.warmWhite.withValues(alpha: 0.7) : AppColors.stone,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              HaulButton(
                label: 'START SHOPPING',
                trailingArrow: true,
                isFullWidth: true,
                isLoading: isLoading,
                onPressed: _selected.isEmpty ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
