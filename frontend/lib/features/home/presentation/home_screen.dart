import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/haul_product_card.dart';
import '../../../shared/widgets/haul_skeleton.dart';
import '../../../shared/widgets/haul_ai_badge.dart';
import '../../../shared/widgets/haul_states.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<String> _categories = [
    'FASHION', 'ELECTRONICS', 'HOME', 'SKINCARE', 'FITNESS', 'ACCESSORIES'
  ];

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: homeState.when(
        data: (state) => RefreshIndicator(
          color: AppColors.signal,
          onRefresh: () => ref.read(homeNotifierProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              _buildSearchBar(context),
              const SizedBox(height: AppSpacing.xl),
              _buildForYouSection(state),
              const SizedBox(height: AppSpacing.xl),
              _buildCategoryChips(state),
              const SizedBox(height: AppSpacing.xl),
              _buildFeaturedBanner(),
              const SizedBox(height: AppSpacing.xl),
              _buildTrendingSection(state),
              const SizedBox(height: 80),
            ],
          ),
        ),
        loading: () => ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            _buildSearchBar(context),
            const SizedBox(height: AppSpacing.xl),
            const HaulSkeletonBanner(),
            const SizedBox(height: AppSpacing.xl),
            const Center(child: CircularProgressIndicator(color: AppColors.signal)),
          ],
        ),
        error: (err, _) => Center(
          child: HaulErrorState(
            exception: err is AppException ? err : BackendError(err.toString()), 
            actionLabel: 'Retry', 
            onAction: () => ref.read(homeNotifierProvider.notifier).refresh()
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.warmWhite,
      elevation: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Text('haul', style: AppTypography.titleLG.copyWith(color: AppColors.ink)),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: AppColors.ink),
          onPressed: () {},
        ),
        const Padding(
          padding: EdgeInsets.only(right: 16.0, left: 8.0),
          child: CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.ink,
            child: Text('U', style: TextStyle(color: AppColors.warmWhite, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: GestureDetector(
        onTap: () => context.go('/search'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.pebble),
              const SizedBox(width: AppSpacing.sm),
              Text('search or scan...', style: AppTypography.bodySM.copyWith(color: AppColors.pebble)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/scan'),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.signal,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.warmWhite, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _staggeredCard(int index, Widget child) {
    return FutureBuilder(
      future: Future.delayed(Duration(milliseconds: index * 55)),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Opacity(opacity: 0, child: child);
        }
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 12.0, end: 0.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, value, animChild) {
            return Transform.translate(
              offset: Offset(0, value),
              child: Opacity(
                opacity: 1.0 - (value / 12.0).clamp(0.0, 1.0),
                child: animChild,
              ),
            );
          },
          child: child,
        );
      },
    );
  }

  Widget _buildForYouSection(HomeState state) {
    if (state.recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Text('FOR YOU', style: AppTypography.labelMD.copyWith(color: AppColors.stone)),
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
            itemCount: state.recommendations.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final product = state.recommendations[index];
              return _staggeredCard(
                index,
                HaulProductCard(
                  product: product,
                  isHorizontal: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(HomeState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = state.activeCategory == cat.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => ref.read(homeNotifierProvider.notifier).setCategory(cat.toLowerCase()),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.signal : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isSelected ? AppColors.warmWhite : AppColors.stone,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeaturedBanner() {
    return GestureDetector(
      onTap: () => context.go('/search?category=fashion'),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.surfaceAlt,
          image: DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1445205170230-053b83016050?q=80&w=1000'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 48,
              width: double.infinity,
              color: AppColors.ink.withValues(alpha: 0.8),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Text('SUMMER COLLECTION', style: AppTypography.labelSM.copyWith(color: AppColors.pebble)),
                  const Spacer(),
                  const Icon(Icons.arrow_forward, color: AppColors.signal, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection(HomeState state) {
    if (state.trending.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TRENDING NOW', style: AppTypography.labelMD.copyWith(color: AppColors.stone)),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 150 / 220,
            ),
            itemCount: state.trending.length,
            itemBuilder: (context, index) {
              final product = state.trending[index];
              return _staggeredCard(
                index,
                HaulProductCard(
                  product: product,
                  isHorizontal: false,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
