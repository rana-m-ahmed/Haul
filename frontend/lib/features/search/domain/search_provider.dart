import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/models/product.dart';
import '../../../core/utils/debouncer.dart';
import 'models/search_filter_state.dart';
import 'search_history_service.dart';

part 'search_provider.g.dart';

class SearchState {
  final SearchFilterState filters;
  final List<Product> products;
  final String? nextPageToken;
  final bool isLoading;
  final bool isPaginating;
  final String? error;

  SearchState({
    required this.filters,
    this.products = const [],
    this.nextPageToken,
    this.isLoading = false,
    this.isPaginating = false,
    this.error,
  });

  SearchState copyWith({
    SearchFilterState? filters,
    List<Product>? products,
    String? nextPageToken,
    bool? clearNextPageToken = false,
    bool? isLoading,
    bool? isPaginating,
    String? error,
    bool clearError = false,
  }) {
    return SearchState(
      filters: filters ?? this.filters,
      products: products ?? this.products,
      nextPageToken: clearNextPageToken == true ? null : (nextPageToken ?? this.nextPageToken),
      isLoading: isLoading ?? this.isLoading,
      isPaginating: isPaginating ?? this.isPaginating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@riverpod
class SearchNotifier extends _$SearchNotifier {
  late final Debouncer _debouncer;

  @override
  SearchState build() {
    _debouncer = Debouncer(milliseconds: 400);
    // Auto-fetch on mount
    Future.microtask(() => _performSearch());
    return SearchState(filters: const SearchFilterState(), isLoading: true);
  }

  void updateQuery(String query) {
    if (query == state.filters.query) return;
    
    state = state.copyWith(
      filters: state.filters.copyWith(query: query),
      products: [],
      clearNextPageToken: true,
      isLoading: true,
      clearError: true,
    );
    
    if (query.trim().isNotEmpty) {
      ref.read(searchHistoryServiceProvider.notifier).addSearch(query.trim());
    }
    
    _debouncer.run(_performSearch);
  }

  void updateFilters({
    String? category,
    double? priceMin,
    double? priceMax,
    double? minRating,
    String? sortBy,
    bool clearCategory = false,
    bool clearPriceMin = false,
    bool clearPriceMax = false,
    bool clearMinRating = false,
  }) {
    final currentFilters = state.filters;
    state = state.copyWith(
      filters: SearchFilterState(
        query: currentFilters.query,
        category: clearCategory ? null : (category ?? currentFilters.category),
        priceMin: clearPriceMin ? null : (priceMin ?? currentFilters.priceMin),
        priceMax: clearPriceMax ? null : (priceMax ?? currentFilters.priceMax),
        minRating: clearMinRating ? null : (minRating ?? currentFilters.minRating),
        sortBy: sortBy ?? currentFilters.sortBy,
      ),
      products: [],
      clearNextPageToken: true,
      isLoading: true,
      clearError: true,
    );
    _performSearch();
  }

  void clearFilters() {
    state = state.copyWith(
      filters: SearchFilterState(query: state.filters.query),
      products: [],
      clearNextPageToken: true,
      isLoading: true,
      clearError: true,
    );
    _performSearch();
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.isPaginating || state.nextPageToken == null) return;
    
    state = state.copyWith(isPaginating: true, clearError: true);
    await _performSearch(isPagination: true);
  }

  Future<void> _performSearch({bool isPagination = false}) async {
    try {
      final payload = state.filters.toJson();
      payload['pageSize'] = 20;
      if (isPagination) {
        payload['pageToken'] = state.nextPageToken;
      }

      final res = await ApiClient().request<Map<String, dynamic>>(
        path: '/search',
        method: 'POST',
        data: payload,
        parser: (data) => data as Map<String, dynamic>,
      );

      if (res is ApiSuccess<Map<String, dynamic>>) {
        final List<dynamic> items = res.data['products'] ?? [];
        final newProducts = items.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
        final String? token = res.data['nextPageToken'];

        state = state.copyWith(
          products: isPagination ? [...state.products, ...newProducts] : newProducts,
          nextPageToken: token,
          clearNextPageToken: token == null,
          isLoading: false,
          isPaginating: false,
        );
      } else if (res is ApiFailure<Map<String, dynamic>>) {
        state = state.copyWith(
          isLoading: false,
          isPaginating: false,
          error: (res as ApiFailure).message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isPaginating: false,
        error: e.toString(),
      );
    }
  }
}
