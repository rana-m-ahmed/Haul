import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../shared/providers/auth_provider.dart';

part 'profile_provider.g.dart';

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  Future<Map<String, dynamic>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null || userId.startsWith('mock-uid-') || userId.startsWith('guest_')) {
      return {'displayName': 'Guest User', 'email': 'guest@example.com'};
    }

    try {
      final res = await ApiClient().request<Map<String, dynamic>>(
        path: '/users/$userId/profile',
        parser: (data) => data as Map<String, dynamic>,
      );

      if (res is ApiSuccess<Map<String, dynamic>>) {
        return res.data;
      }
    } catch (_) {}

    return {'displayName': 'User', 'email': ''};
  }
}
