import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/widgets/haul_product_card.dart';
import '../../../shared/widgets/haul_skeleton.dart';
import '../../../shared/widgets/haul_states.dart';
import '../domain/search_provider.dart';
import '../domain/search_history_service.dart';
import 'search_sort_sheet.dart';
import 'search_filter_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchNotifierProvider.notifier).updateQuery(widget.initialQuery!);
      });
    }

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
        ref.read(searchNotifierProvider.notifier).fetchNextPage();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const SearchSortSheet(),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SearchFilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchNotifierProvider);
    final history = ref.watch(searchHistoryServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          autofocus: widget.initialQuery == null,
          cursorColor: AppColors.signal,
          style: AppTypography.bodyMD.copyWith(color: AppColors.ink),
          decoration: InputDecoration(
            hintText: 'Search for anything...',
            hintStyle: AppTypography.bodyMD.copyWith(color: AppColors.pebble),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.pebble, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchNotifierProvider.notifier).updateQuery('');
                      _focusNode.requestFocus();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            ref.read(searchNotifierProvider.notifier).updateQuery(val);
            setState(() {});
          },
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterPill(
                        label: 'PRICE',
                        isActive: state.filters.priceMin != null || state.filters.priceMax != null,
                        onTap: _showFilterSheet,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterPill(
                        label: 'CATEGORY',
                        isActive: state.filters.category != null,
                        onTap: _showFilterSheet,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FilterPill(
                        label: 'RATING',
                        isActive: state.filters.minRating != null,
                        onTap: _showFilterSheet,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _showSortSheet,
                  child: Row(
                    children: [
                      Text('SORT ↕', style: AppTypography.labelSM.copyWith(color: AppColors.ink)),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          Expanded(
            child: _buildBody(state, history),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(SearchState state, List<String> history) {
    if (state.filters.query.isEmpty && history.isNotEmpty) {
      return ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final q = history[index];
          return ListTile(
            title: Text(q, style: AppTypography.bodyMD.copyWith(color: AppColors.stone)),
            trailing: const Icon(Icons.north_east, color: AppColors.pebble, size: 16),
            onTap: () {
              _searchController.text = q;
              ref.read(searchNotifierProvider.notifier).updateQuery(q);
              _focusNode.unfocus();
              setState(() {});
            },
          );
        },
      );
    }

    if (state.isLoading) {
      return GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 150 / 220,
        ),
        itemCount: 4,
        itemBuilder: (context, index) => const HaulSkeletonCard(isHorizontal: false),
      );
    }

    if (state.error != null) {
      return Center(
        child: HaulErrorState(
          exception: BackendError(state.error!),
          actionLabel: 'Retry',
          onAction: () => ref.read(searchNotifierProvider.notifier).updateQuery(_searchController.text),
        ),
      );
    }

    if (state.products.isEmpty && state.filters.query.isNotEmpty) {
      return Center(
        child: HaulEmptyState(
          title: 'No Results Found',
          message: 'Try adjusting your search or filters.',
          actionLabel: 'CLEAR FILTERS',
          onAction: () {
             _searchController.clear();
             ref.read(searchNotifierProvider.notifier).updateQuery('');
             setState((){});
          },
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 150 / 220,
      ),
      itemCount: state.products.length + (state.isPaginating ? 2 : 0),
      itemBuilder: (context, index) {
        if (index >= state.products.length) {
          return const HaulSkeletonCard(isHorizontal: false);
        }
        return HaulProductCard(
          product: state.products[index],
          isHorizontal: false,
          heroTagSuffix: 'search',
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterPill({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.signal : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.signal : AppColors.pebble),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelSM.copyWith(
              color: isActive ? AppColors.warmWhite : AppColors.stone,
            ),
          ),
        ),
      ),
    );
  }
}
