import 'package:json_annotation/json_annotation.dart';
import '../../../../shared/models/product.dart';

part 'cart_item.g.dart';

@JsonSerializable()
class CartItem {
  final String id;
  final Product product;
  final int quantity;
  final String? variant;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.variant,
  });

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    String? variant,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      variant: variant ?? this.variant,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) => _$CartItemFromJson(json);
  Map<String, dynamic> toJson() => _$CartItemToJson(this);
}
