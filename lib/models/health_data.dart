import 'package:hive/hive.dart';

part 'health_data.g.dart';

@HiveType(typeId: 2)
class HealthData {
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

  @HiveField(5)
  int? hiveKey;

  HealthData({
    required this.category,
    required this.testName,
    required this.value,
    required this.unit,
    required this.date,
    this.hiveKey,
  });

  factory HealthData.fromJson(Map<String, dynamic> json) {
    return HealthData(
      category: json['category'] as String,
      testName: json['testName'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      date: DateTime.parse(json['date'] as String),
      hiveKey: json['hiveKey'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'testName': testName,
      'value': value,
      'unit': unit,
      'date': date.toIso8601String(),
      'hiveKey': hiveKey,
    };
  }
}
