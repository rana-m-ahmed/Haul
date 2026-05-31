// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visual_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchedProduct _$MatchedProductFromJson(Map<String, dynamic> json) =>
    MatchedProduct(
      id: json['productId'] as String? ?? '',
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['thumbnailUrl'] as String?,
      isNew: json['isNew'] as bool? ?? false,
      isSale: json['isOnSale'] as bool? ?? false,
      inStock: json['inStock'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
      matchReason: json['matchReason'] as String? ?? '',
    );

Map<String, dynamic> _$MatchedProductToJson(MatchedProduct instance) =>
    <String, dynamic>{
      'productId': instance.id,
      'name': instance.name,
      'price': instance.price,
      'thumbnailUrl': instance.imageUrl,
      'isNew': instance.isNew,
      'isOnSale': instance.isSale,
      'inStock': instance.inStock,
      'rating': instance.rating,
      'matchScore': instance.matchScore,
      'matchReason': instance.matchReason,
    };

GeminiQuery _$GeminiQueryFromJson(Map<String, dynamic> json) => GeminiQuery(
      category: json['category'] as String? ?? '',
      subcategory: json['subcategory'] as String? ?? '',
      color: json['color'] as String? ?? '',
      material: json['material'] as String? ?? '',
      style: json['style'] as String? ?? '',
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$GeminiQueryToJson(GeminiQuery instance) =>
    <String, dynamic>{
      'category': instance.category,
      'subcategory': instance.subcategory,
      'color': instance.color,
      'material': instance.material,
      'style': instance.style,
      'keywords': instance.keywords,
      'confidence': instance.confidence,
    };

VisualSearchData _$VisualSearchDataFromJson(Map<String, dynamic> json) =>
    VisualSearchData(
      query: GeminiQuery.fromJson(json['query'] as Map<String, dynamic>),
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => MatchedProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      processingTimeMs: (json['processingTimeMs'] as num?)?.toInt() ?? 0,
      noResultsReason: json['noResultsReason'] as String?,
    );

Map<String, dynamic> _$VisualSearchDataToJson(VisualSearchData instance) =>
    <String, dynamic>{
      'query': instance.query,
      'products': instance.products,
      'processingTimeMs': instance.processingTimeMs,
      'noResultsReason': instance.noResultsReason,
    };
