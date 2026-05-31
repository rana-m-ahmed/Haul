import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/providers/auth_provider.dart';

part 'orders_provider.g.dart';

@riverpod
class OrdersNotifier extends _$OrdersNotifier {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null || userId.startsWith('guest_')) return [];

    try {
      final res = await ApiClient().request<Map<String, dynamic>>(
        path: '/orders?userId=$userId',
        parser: (data) => data as Map<String, dynamic>,
      );

      if (res is ApiSuccess<Map<String, dynamic>>) {
        final List<dynamic> orders = res.data['orders'] ?? [];
        return orders.cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    return [];
  }
}
