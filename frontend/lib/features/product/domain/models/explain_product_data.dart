import 'package:json_annotation/json_annotation.dart';

part 'explain_product_data.g.dart';

@JsonSerializable()
class ExplainProductData {
  final String explanation;
  final String generatedAt;
  final bool isPersonalized;

  ExplainProductData({
    required this.explanation,
    required this.generatedAt,
    required this.isPersonalized,
  });

  factory ExplainProductData.fromJson(Map<String, dynamic> json) => _$ExplainProductDataFromJson(json);
  Map<String, dynamic> toJson() => _$ExplainProductDataToJson(this);
}
