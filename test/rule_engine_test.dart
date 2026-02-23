// Quick test to verify all rule engine categories produce valid results.
// Run with: flutter test test/rule_engine_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:disease_check_app/engine/rule_engine.dart';

void main() {
  group('RuleEngine - Diabetes', () {
    test('High FBS + HbA1c = high risk', () {
      final result = RuleEngine.checkDiabetes(fastingGlucose: 150, hba1c: 7.2);
      expect(result['riskLevel'], 'high');
      expect(result['disease'], 'Type 2 Diabetes');
      expect((result['findings'] as List).length, greaterThan(0));
    });
    test('Normal FBS = low risk', () {
      final result = RuleEngine.checkDiabetes(fastingGlucose: 85);
      expect(result['riskLevel'], 'low');
    });
  });

  group('RuleEngine - Hypertension', () {
    test('Stage 2 = high risk', () {
      final result = RuleEngine.checkHypertension(systolic: 155, diastolic: 95);
      expect(result['riskLevel'], 'high');
    });
    test('Normal BP = low risk', () {
      final result = RuleEngine.checkHypertension(systolic: 115, diastolic: 75);
      expect(result['riskLevel'], 'low');
    });
  });

  group('RuleEngine - Cholesterol', () {
    test('High LDL + High Triglycerides = moderate/high risk', () {
      final result = RuleEngine.checkCholesterol(
          ldl: 170, triglycerides: 250, totalCholesterol: 260);
      expect(result['riskLevel'], isNot('low'));
      expect((result['findings'] as List).length, greaterThan(0));
    });
  });

  group('RuleEngine - CBC / Anemia', () {
    test('Low hemoglobin = anemia risk', () {
      final result = RuleEngine.checkAnemia(hemoglobin: 8.5, mcv: 72);
      expect(result['riskLevel'], equals('moderate'));
      expect(result['disease'], 'Anemia');
    });
    test('High WBC = leukocytosis', () {
      final result = RuleEngine.checkWBCAbnormality(wbcCount: 15000);
      expect(result['riskLevel'], equals('moderate'));
    });
  });

  group('RuleEngine - Liver', () {
    test('Elevated ALT + AST + Bilirubin = liver risk', () {
      final result =
          RuleEngine.checkLiverDisease(alt: 85, ast: 62, totalBilirubin: 3.0);
      expect(result['riskLevel'], isNot('low'));
    });
  });

  group('RuleEngine - Kidney', () {
    test('Low eGFR = CKD risk', () {
      final result = RuleEngine.checkKidneyDisease(egfr: 45, creatinine: 2.1);
      expect(result['riskLevel'], equals('moderate'));
    });
    test('Normal kidney values = low risk', () {
      final result = RuleEngine.checkKidneyDisease(egfr: 95, creatinine: 0.9);
      expect(result['riskLevel'], 'low');
    });
  });

  group('RuleEngine - Thyroid', () {
    test('High TSH = hypothyroidism', () {
      final result = RuleEngine.checkThyroid(tsh: 8.5, freeT4: 0.5);
      expect(result['disease'], 'Hypothyroidism');
      expect(result['riskLevel'], 'moderate'); // 40+20=60 → moderate
    });
    test('Low TSH = hyperthyroidism', () {
      final result = RuleEngine.checkThyroid(tsh: 0.1, freeT3: 5.2);
      expect(result['disease'], 'Hyperthyroidism');
      expect(result['riskLevel'], 'moderate'); // 40+20=60 → moderate
    });
  });

  group('RuleEngine - Iron Panel', () {
    test('Low ferritin + low iron = deficiency', () {
      final result = RuleEngine.checkIronDeficiency(
          ferritin: 8, serumIron: 40, transferrinSaturation: 10, tibc: 400);
      expect(result['riskLevel'], 'high'); // 40+20+15+10=85 → high
    });
  });

  group('RuleEngine - Cardiac', () {
    test('Elevated troponin = cardiac risk', () {
      final result =
          RuleEngine.checkCardiacRisk(troponinI: 0.15, bnp: 250, crp: 5.0);
      expect(result['riskLevel'], 'high'); // 40+25+15=80 → high
    });
  });

  group('RuleEngine - Vital Signs', () {
    test('Low SpO2 = hypoxia risk', () {
      final result = RuleEngine.checkVitalSigns(spo2: 88, heartRate: 110);
      expect(result['riskLevel'], 'high');
    });
  });

  group('RuleEngine - Full Pipeline (evaluateHealthData)', () {
    test('Mixed categories produce combined report', () {
      // Simulate HealthData entries (using a simple mock class)
      final entries = [
        _MockHealthData('Fasting Blood Glucose', 142),
        _MockHealthData('HbA1c', 7.1),
        _MockHealthData('Total Cholesterol', 260),
        _MockHealthData('LDL Cholesterol', 175),
        _MockHealthData('ALT (SGPT)', 85),
        _MockHealthData('TSH', 8.5),
        _MockHealthData('Hemoglobin', 9.0),
      ];

      final results = RuleEngine.evaluateHealthData(entries);

      // Should have results for: Diabetes, Cholesterol, Liver, Thyroid, Anemia
      expect(results.length, greaterThanOrEqualTo(4));

      // Verify each category is present
      final diseases = results.map((r) => r['disease'] as String).toList();
      expect(diseases.any((d) => d.contains('Diabetes')), isTrue);
      expect(
          diseases.any((d) =>
              d.contains('Cholesterol') || d.contains('Hypercholesterolemia')),
          isTrue);
      expect(diseases.any((d) => d.contains('Liver')), isTrue);
      expect(diseases.any((d) => d.contains('Hypothyroidism')), isTrue);
      expect(diseases.any((d) => d.contains('Anemia')), isTrue);
    });
  });
}

/// Simple mock to simulate HealthData model objects
class _MockHealthData {
  final String testName;
  final double value;
  _MockHealthData(this.testName, this.value);
}
