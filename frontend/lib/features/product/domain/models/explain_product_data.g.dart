// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explain_product_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExplainProductData _$ExplainProductDataFromJson(Map<String, dynamic> json) =>
    ExplainProductData(
      explanation: json['explanation'] as String,
      generatedAt: json['generatedAt'] as String,
      isPersonalized: json['isPersonalized'] as bool,
    );

Map<String, dynamic> _$ExplainProductDataToJson(ExplainProductData instance) =>
    <String, dynamic>{
      'explanation': instance.explanation,
      'generatedAt': instance.generatedAt,
      'isPersonalized': instance.isPersonalized,
    };
