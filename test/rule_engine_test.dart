import 'package:flutter_test/flutter_test.dart';
import 'package:disease_check_app/engine/rule_engine.dart';
import 'package:disease_check_app/engine/reference_ranges.dart';
import 'package:disease_check_app/models/health_data.dart';

void main() {
  group('RuleEngine Tests', () {
    test('checkDiabetes returns high risk for high FBS and HbA1c', () {
      final result =
          RuleEngine.checkDiabetes(fastingGlucose: 130.0, hba1c: 7.0);
      expect(result['riskLevel'], 'high');
      expect(result['disease'], 'Type 2 Diabetes');
    });

    test('checkDiabetes returns low risk for normal FBS', () {
      final result = RuleEngine.checkDiabetes(fastingGlucose: 90.0);
      expect(result['riskLevel'], 'low');
    });

    test('checkHypertension returns high risk for Stage 2', () {
      final result =
          RuleEngine.checkHypertension(systolic: 145.0, diastolic: 95.0);
      expect(result['riskLevel'], 'high');
      expect(result['disease'], contains('Stage 2'));
    });

    test('evaluateHealthData processes HealthData objects', () {
      final data = [
        HealthData(
          category: 'vitals',
          testName: 'systolic',
          value: 150.0,
          unit: 'mmHg',
          date: DateTime.now(),
        ),
        HealthData(
          category: 'vitals',
          testName: 'diastolic',
          value: 95.0,
          unit: 'mmHg',
          date: DateTime.now(),
        ),
      ];

      final reports = RuleEngine.evaluateHealthData(data);
      expect(reports.length, 1);
      expect(reports.first['disease'], contains('Hypertension'));
      expect(reports.first['riskLevel'], 'high');
    });
  });

  group('ReferenceRanges Tests', () {
    test('isAbnormal dynamically flags out-of-range values', () {
      ReferenceRanges.loadRanges();
      // Normal fasting glucose is 70 to 99
      expect(
          ReferenceRanges.isAbnormal('blood_sugar', 'fasting_glucose', 110.0),
          true);
      expect(ReferenceRanges.isAbnormal('blood_sugar', 'fasting_glucose', 85.0),
          false);
      expect(ReferenceRanges.isAbnormal('blood_sugar', 'fasting_glucose', 65.0),
          true);
    });

    test('getRange returns correct boundary map', () {
      ReferenceRanges.loadRanges();
      final range = ReferenceRanges.getRange('vitals', 'heart_rate');
      expect(range['normal_min'], 60);
      expect(range['normal_max'], 100);
      expect(range['unit'], 'bpm');
    });
  });
}
