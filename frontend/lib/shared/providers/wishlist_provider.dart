import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import 'auth_provider.dart';

part 'wishlist_provider.g.dart';

@riverpod
class WishlistNotifier extends _$WishlistNotifier {
  static const _wishlistKey = 'user_wishlist';

  @override
  Set<String> build() {
    _loadWishlist();
    return {};
  }

  Future<void> _loadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_wishlistKey);
    if (data != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(data);
        state = Set<String>.from(jsonList.cast<String>());
      } catch (_) {
        state = {};
      }
    } else {
      _fetchFromBackend();
    }
  }

  Future<void> _fetchFromBackend() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.startsWith('guest_')) return;

    try {
      final res = await ApiClient().request<Map<String, dynamic>>(
        path: '/users/$userId/wishlist',
        parser: (data) => data as Map<String, dynamic>,
      );

      if (res is ApiSuccess<Map<String, dynamic>>) {
        final List<dynamic> ids = res.data['product_ids'] ?? [];
        state = Set<String>.from(ids.cast<String>());
        _saveToLocal(state);
      }
    } catch (_) {}
  }

  Future<void> _saveToLocal(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wishlistKey, jsonEncode(ids.toList()));
  }

  Future<void> _syncToBackend(Set<String> ids) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.startsWith('guest_')) return;

    try {
      await ApiClient().request<Map<String, dynamic>>(
        path: '/users/$userId/wishlist',
        method: 'POST',
        data: {'product_ids': ids.toList()},
        parser: (data) => data as Map<String, dynamic>,
      );
    } catch (_) {}
  }

  void toggle(String productId) {
    final newSet = Set<String>.from(state);
    if (newSet.contains(productId)) {
      newSet.remove(productId);
    } else {
      newSet.add(productId);
    }
    state = newSet;
    _saveToLocal(newSet);
    _syncToBackend(newSet);
  }

  void clearWishlist() {
    state = {};
    _saveToLocal({});
  }
}
