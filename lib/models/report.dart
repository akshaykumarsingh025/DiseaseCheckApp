import 'package:hive/hive.dart';

part 'report.g.dart';

@HiveType(typeId: 1)
class HealthReport extends HiveObject {
  @HiveField(0)
  final String reportId;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final List<dynamic> highRiskDiseases;

  @HiveField(3)
  final List<dynamic> moderateRiskDiseases;

  @HiveField(4)
  final List<dynamic> lowRiskDiseases;

  @HiveField(5)
  final List<String> abnormalValues;

  HealthReport({
    required this.reportId,
    required this.date,
    required this.highRiskDiseases,
    required this.moderateRiskDiseases,
    required this.lowRiskDiseases,
    required this.abnormalValues,
  });

  factory HealthReport.fromJson(Map<String, dynamic> json) {
    return HealthReport(
      reportId: json['reportId'] as String,
      date: DateTime.parse(json['date'] as String),
      highRiskDiseases: List<dynamic>.from(json['highRiskDiseases'] ?? []),
      moderateRiskDiseases:
          List<dynamic>.from(json['moderateRiskDiseases'] ?? []),
      lowRiskDiseases: List<dynamic>.from(json['lowRiskDiseases'] ?? []),
      abnormalValues: List<String>.from(json['abnormalValues'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'date': date.toIso8601String(),
      'highRiskDiseases': highRiskDiseases,
      'moderateRiskDiseases': moderateRiskDiseases,
      'lowRiskDiseases': lowRiskDiseases,
      'abnormalValues': abnormalValues,
    };
  }
}
