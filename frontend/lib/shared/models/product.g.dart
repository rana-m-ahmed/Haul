// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
      id: json['productId'] as String? ?? '',
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['thumbnailUrl'] as String?,
      isNew: json['isNew'] as bool? ?? false,
      isSale: json['isOnSale'] as bool? ?? false,
      inStock: json['inStock'] as bool? ?? true,
    );

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
      'productId': instance.id,
      'name': instance.name,
      'price': instance.price,
      'thumbnailUrl': instance.imageUrl,
      'isNew': instance.isNew,
      'isOnSale': instance.isSale,
      'inStock': instance.inStock,
    };
