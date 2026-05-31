import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/models/product.dart';
import '../../../shared/providers/auth_provider.dart';
import 'models/explain_product_data.dart';

part 'product_provider.g.dart';

class ProductState {
  final Product? product;
  final List<Product> similarProducts;
  final ExplainProductData? explanation;
  final bool isLoading;
  final bool isExplanationLoading;
  final String? error;

  ProductState({
    this.product,
    this.similarProducts = const [],
    this.explanation,
    this.isLoading = true,
    this.isExplanationLoading = false,
    this.error,
  });

  ProductState copyWith({
    Product? product,
    List<Product>? similarProducts,
    ExplainProductData? explanation,
    bool? isLoading,
    bool? isExplanationLoading,
    String? error,
  }) {
    return ProductState(
      product: product ?? this.product,
      similarProducts: similarProducts ?? this.similarProducts,
      explanation: explanation ?? this.explanation,
      isLoading: isLoading ?? this.isLoading,
      isExplanationLoading: isExplanationLoading ?? this.isExplanationLoading,
      error: error ?? this.error,
    );
  }
}

@riverpod
class ProductNotifier extends _$ProductNotifier {
  @override
  ProductState build(String productId) {
    Future.microtask(() => _fetchInitialData());
    return ProductState();
  }

  Future<void> _fetchInitialData() async {
    state = state.copyWith(isLoading: true, isExplanationLoading: true);

    try {
      final results = await Future.wait([
        ApiClient().request<Product>(
          path: '/products/$productId',
          parser: (data) => Product.fromJson(data as Map<String, dynamic>),
        ),
        ApiClient().request<Map<String, dynamic>>(
          path: '/search',
          method: 'POST',
          data: {'sortBy': 'relevance', 'pageSize': 6},
          parser: (data) => data as Map<String, dynamic>,
        ),
      ]);

      final productRes = results[0];
      final similarRes = results[1];

      Product? product;
      List<Product> similarProducts = [];
      String? error;

      if (productRes is ApiSuccess<Product>) {
        product = productRes.data;
      } else if (productRes is ApiFailure<Product>) {
        error = (productRes as ApiFailure).message;
      }

      if (similarRes is ApiSuccess<Map<String, dynamic>>) {
        final items = similarRes.data['products'] ?? [];
        similarProducts = items.map<Product>((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
        similarProducts.removeWhere((p) => p.id == productId);
      }

      state = state.copyWith(
        product: product,
        similarProducts: similarProducts,
        isLoading: false,
        error: error,
      );

      if (product != null) {
        _trackView(product.id);
        _fetchExplanation(product.id);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _fetchExplanation(String pid) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.startsWith('guest_')) {
      state = state.copyWith(isExplanationLoading: false);
      return;
    }

    try {
      final res = await ApiClient().request<ExplainProductData>(
        path: '/explain-product',
        method: 'POST',
        data: {'productId': pid, 'userId': userId},
        parser: (data) => ExplainProductData.fromJson(data as Map<String, dynamic>),
      );

      if (res is ApiSuccess<ExplainProductData>) {
        state = state.copyWith(explanation: res.data, isExplanationLoading: false);
      } else {
        state = state.copyWith(isExplanationLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isExplanationLoading: false);
    }
  }

  void _trackView(String pid) {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    ApiClient().request<dynamic>(
      path: '/events',
      method: 'POST',
      data: {
        'userId': userId,
        'eventType': 'view',
        'productId': pid,
      },
      parser: (data) => data,
    ).catchError((_) => ApiFailure<dynamic>(message: 'error'));
  }
}
