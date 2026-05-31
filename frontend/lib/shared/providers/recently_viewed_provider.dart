import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'recently_viewed_provider.g.dart';

@Riverpod(keepAlive: true)
class RecentlyViewedNotifier extends _$RecentlyViewedNotifier {
  static const _key = 'recently_viewed_ids';

  @override
  Future<List<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> addViewedProduct(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    var current = prefs.getStringList(_key) ?? [];
    
    current.remove(productId);
    current.insert(0, productId);
    
    if (current.length > 6) {
      current = current.sublist(0, 6);
    }
    
    await prefs.setStringList(_key, current);
    state = AsyncValue.data(current);
  }
}
