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
}
