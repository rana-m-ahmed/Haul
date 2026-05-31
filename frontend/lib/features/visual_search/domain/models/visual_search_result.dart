import 'package:json_annotation/json_annotation.dart';
import '../../../../shared/models/product.dart';

part 'visual_search_result.g.dart';

@JsonSerializable()
class MatchedProduct extends Product {
  @JsonKey(defaultValue: 0.0)
  final double rating;
  
  @JsonKey(name: 'matchScore', defaultValue: 0.0)
  final double matchScore;
  
  @JsonKey(name: 'matchReason', defaultValue: '')
  final String matchReason;

  MatchedProduct({
    required super.id,
    required super.name,
    required super.price,
    super.imageUrl,
    super.isNew,
    super.isSale,
    super.inStock,
    required this.rating,
    required this.matchScore,
    this.matchReason = '',
  });

  factory MatchedProduct.fromJson(Map<String, dynamic> json) => _$MatchedProductFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$MatchedProductToJson(this);
}

@JsonSerializable()
class GeminiQuery {
  final String category;
  final String subcategory;
  final String color;
  final String material;
  final String style;
  final List<String> keywords;
  final double confidence;

  GeminiQuery({
    this.category = '',
    this.subcategory = '',
    this.color = '',
    this.material = '',
    this.style = '',
    this.keywords = const [],
    this.confidence = 0.0,
  });

  factory GeminiQuery.fromJson(Map<String, dynamic> json) => _$GeminiQueryFromJson(json);
  Map<String, dynamic> toJson() => _$GeminiQueryToJson(this);
}

@JsonSerializable()
class VisualSearchData {
  final GeminiQuery query;
  final List<MatchedProduct> products;
  final int processingTimeMs;
  final String? noResultsReason;

  VisualSearchData({
    required this.query,
    this.products = const [],
    this.processingTimeMs = 0,
    this.noResultsReason,
  });

  factory VisualSearchData.fromJson(Map<String, dynamic> json) => _$VisualSearchDataFromJson(json);
  Map<String, dynamic> toJson() => _$VisualSearchDataToJson(this);
}
