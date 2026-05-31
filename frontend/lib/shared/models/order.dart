import 'package:json_annotation/json_annotation.dart';
import 'cart_item.dart';

part 'order.g.dart';

@JsonSerializable()
class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);
}
