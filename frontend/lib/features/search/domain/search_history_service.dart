import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_history_service.g.dart';

@riverpod
class SearchHistoryService extends _$SearchHistoryService {
  static const _key = 'search_history';
  static const _maxItems = 10;

  @override
  List<String> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_key) ?? [];
    state = items;
  }

  Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final items = List<String>.from(state);
    
    items.remove(query);
    items.insert(0, query);
    
    if (items.length > _maxItems) {
      items.removeLast();
    }
    
    await prefs.setStringList(_key, items);
    state = items;
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = [];
  }
}
