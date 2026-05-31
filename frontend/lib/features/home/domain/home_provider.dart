import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/models/product.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/recently_viewed_provider.dart';

part 'home_provider.g.dart';

class HomeState {
  final List<Product> recommendations;
  final List<Product> trending;
  final List<Product> recentlyViewed;
  final String? activeCategory;

  const HomeState({
    this.recommendations = const [],
    this.trending = const [],
    this.recentlyViewed = const [],
    this.activeCategory,
  });

  HomeState copyWith({
    List<Product>? recommendations,
    List<Product>? trending,
    List<Product>? recentlyViewed,
    String? activeCategory,
  }) {
    return HomeState(
      recommendations: recommendations ?? this.recommendations,
      trending: trending ?? this.trending,
      recentlyViewed: recentlyViewed ?? this.recentlyViewed,
      activeCategory: activeCategory, // allowing null
    );
  }
}

@riverpod
class HomeNotifier extends _$HomeNotifier {
  @override
  Future<HomeState> build() async {
    final uid = ref.watch(currentUserIdProvider) ?? 'guest';
    _trackViewEvent(uid);
    return _fetchData(uid: uid);
  }

  Future<HomeState> _fetchData({required String uid, String? category}) async {
    // 1. Fetch Recommendations
    Future<List<Product>> fetchRecs() async {
      try {
        final res = await ApiClient().request<Map<String, dynamic>>(
          path: '/recommendations/$uid',
          method: 'GET',
          parser: (data) => data as Map<String, dynamic>,
        );
        if (res is ApiSuccess<Map<String, dynamic>>) {
          final items = res.data['recommendations'] as List<dynamic>? ?? [];
          return items.map((e) {
             final productMap = e['product'] as Map<String, dynamic>?;
             return productMap != null ? Product.fromJson(productMap) : null;
          }).whereType<Product>().toList();
        }
      } catch (_) {}
      return [];
    }

    // 2. Fetch Trending / Category
    Future<List<Product>> fetchTrending() async {
      try {
        final payload = <String, dynamic>{
          'sortBy': 'newest',
          'pageSize': 8,
        };
        if (category != null) {
          payload['category'] = category;
        }
        final res = await ApiClient().request<Map<String, dynamic>>(
          path: '/search',
          method: 'POST',
          data: payload,
          parser: (data) => data as Map<String, dynamic>,
        );
        if (res is ApiSuccess<Map<String, dynamic>>) {
           final products = res.data['products'] as List<dynamic>? ?? [];
           return products.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
      return [];
    }

    // 3. Fetch Recently Viewed
    Future<List<Product>> fetchRecent() async {
       try {
         final recentIds = await ref.read(recentlyViewedNotifierProvider.future);
         if (recentIds.isEmpty) return [];

         final res = await ApiClient().request<Map<String, dynamic>>(
            path: '/products/batch',
            method: 'POST',
            data: {'productIds': recentIds},
            parser: (data) => data as Map<String, dynamic>,
         );
         if (res is ApiSuccess<Map<String, dynamic>>) {
             final products = res.data['products'] as List<dynamic>? ?? [];
             return products.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
         }
       } catch (_) {}
       return [];
    }

    final results = await Future.wait([fetchRecs(), fetchTrending(), fetchRecent()]);
    
    var recs = results[0];
    var trend = results[1];
    var recent = results[2];

    if (recs.isEmpty && trend.isNotEmpty) {
      recs = trend;
    }

    return HomeState(
      recommendations: recs,
      trending: trend,
      recentlyViewed: recent,
      activeCategory: category,
    );
  }

  Future<void> _trackViewEvent(String uid) async {
    try {
      await ApiClient().request<Map<String, dynamic>>(
        path: '/events',
        method: 'POST',
        data: {
          'userId': uid,
          'eventType': 'view',
          'productId': 'home_screen',
        },
        parser: (data) => data as Map<String, dynamic>,
      );
    } catch (_) {}
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final uid = ref.read(currentUserIdProvider) ?? 'guest';
    state = await AsyncValue.guard(() => _fetchData(uid: uid, category: state.valueOrNull?.activeCategory));
  }

  Future<void> setCategory(String? category) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final targetCategory = current.activeCategory == category ? null : category;

    state = const AsyncValue.loading();
    final uid = ref.read(currentUserIdProvider) ?? 'guest';
    state = await AsyncValue.guard(() => _fetchData(uid: uid, category: targetCategory));
  }
}
