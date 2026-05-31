import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import 'auth_provider.dart';

part 'preferences_provider.g.dart';

@Riverpod(keepAlive: true)
class PreferencesNotifier extends _$PreferencesNotifier {
  @override
  Future<List<String>> build() async {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return [];

    final response = await ApiClient().request<Map<String, dynamic>>(
      path: '/users/$uid/preferences',
      method: 'GET',
      parser: (data) => data as Map<String, dynamic>,
    );

    if (response is ApiSuccess<Map<String, dynamic>>) {
      final categories = response.data['categories'] as List<dynamic>? ?? [];
      return categories.map((e) => e.toString()).toList();
    }
    return [];
  }

  Future<void> savePreferences(List<String> categories) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    state = const AsyncValue.loading();
    try {
      final response = await ApiClient().request<Map<String, dynamic>>(
        path: '/users/$uid/preferences',
        method: 'POST',
        data: {'categories': categories},
        parser: (data) => data as Map<String, dynamic>,
      );

      if (response is ApiSuccess<Map<String, dynamic>>) {
        state = AsyncValue.data(categories);
      } else if (response is ApiFailure<Map<String, dynamic>>) {
        state = AsyncValue.error(response.message, StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
