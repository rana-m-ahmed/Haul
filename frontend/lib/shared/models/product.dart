import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable()
class Product {
  @JsonKey(name: 'productId', defaultValue: '')
  final String id;
  final String name;
  final double price;
  @JsonKey(name: 'thumbnailUrl')
  final String? imageUrl;
  @JsonKey(defaultValue: false)
  final bool isNew;
  @JsonKey(name: 'isOnSale', defaultValue: false)
  final bool isSale;
  @JsonKey(defaultValue: true)
  final bool inStock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.isNew = false,
    this.isSale = false,
    this.inStock = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
