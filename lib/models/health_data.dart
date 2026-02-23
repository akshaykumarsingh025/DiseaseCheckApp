import 'package:hive/hive.dart';

part 'health_data.g.dart';

@HiveType(typeId: 2)
class HealthData extends HiveObject {
  @HiveField(0)
  final String category;

  @HiveField(1)
  final String testName;

  @HiveField(2)
  final double value;

  @HiveField(3)
  final String unit;

  @HiveField(4)
  final DateTime date;

  HealthData({
    required this.category,
    required this.testName,
    required this.value,
    required this.unit,
    required this.date,
  });
}
