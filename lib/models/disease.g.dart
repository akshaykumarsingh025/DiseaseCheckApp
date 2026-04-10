// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disease.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Disease _$DiseaseFromJson(Map<String, dynamic> json) => Disease(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      icd10: json['icd10'] as String,
      detectionMethod: json['detectionMethod'] as String,
    );

Map<String, dynamic> _$DiseaseToJson(Disease instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'icd10': instance.icd10,
      'detectionMethod': instance.detectionMethod,
    };
