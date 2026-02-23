import 'package:json_annotation/json_annotation.dart';

part 'disease.g.dart';

@JsonSerializable()
class Disease {
  final String id;
  final String name;
  final String category;
  final String icdCode;
  final String detectionMethod;

  Disease({
    required this.id,
    required this.name,
    required this.category,
    required this.icdCode,
    required this.detectionMethod,
  });

  factory Disease.fromJson(Map<String, dynamic> json) => _$DiseaseFromJson(json);
  Map<String, dynamic> toJson() => _$DiseaseToJson(this);
}
