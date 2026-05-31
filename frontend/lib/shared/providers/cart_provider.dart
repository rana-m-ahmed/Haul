import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/cart/domain/models/cart_item.dart';
import '../models/product.dart';

part 'cart_provider.g.dart';

@riverpod
class CartNotifier extends _$CartNotifier {
  static const _cartKey = 'user_cart';

  @override
  List<CartItem> build() {
    _loadCart();
    return [];
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_cartKey);
    if (data != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(data);
        state = jsonList.map((e) => CartItem.fromJson(e)).toList();
      } catch (e) {
        state = [];
      }
    }
  }

  Future<void> _saveCart(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_cartKey, data);
  }

  void addItem(Product product, {String? variant}) {
    final items = List<CartItem>.from(state);
    final id = '${product.id}_${variant ?? "default"}';
    
    final existingIndex = items.indexWhere((i) => i.id == id);
    if (existingIndex >= 0) {
      items[existingIndex] = items[existingIndex].copyWith(
        quantity: items[existingIndex].quantity + 1,
      );
    } else {
      items.add(CartItem(
        id: id,
        product: product,
        quantity: 1,
        variant: variant,
      ));
    }
    
    state = items;
    _saveCart(items);
  }

  void removeItem(String id) {
    final items = List<CartItem>.from(state)..removeWhere((i) => i.id == id);
    state = items;
    _saveCart(items);
  }

  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeItem(id);
      return;
    }
    
    final items = List<CartItem>.from(state);
    final index = items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      items[index] = items[index].copyWith(quantity: quantity);
      state = items;
      _saveCart(items);
    }
  }

  void clearCart() {
    state = [];
    _saveCart([]);
  }

  double get subtotal => state.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);
}
