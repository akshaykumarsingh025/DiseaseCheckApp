import 'package:flutter_test/flutter_test.dart';
import 'package:disease_check_app/engine/rule_engine.dart';
import 'package:disease_check_app/models/health_data.dart';

void main() {
  test('Women\'s Health Hub rules evaluation', () {
    // 1. Enter random data that overlaps (like TSH) without women's hormonal markers
    final overlapData = [
      HealthData(
          category: 'Thyroid',
          testName: 'TSH',
          value: 3.0,
          unit: 'mIU/L',
          date: DateTime.now()),
      HealthData(
          category: 'Blood Sugar',
          testName: 'Fasting Blood Sugar',
          value: 90.0,
          unit: 'mg/dL',
          date: DateTime.now()),
    ];

    final overlapResults = RuleEngine.evaluateHealthData(overlapData);
    // Should NOT contain Pregnancy Readiness because no actual hormonal data is present
    final hasPreg =
        overlapResults.any((r) => r['disease'] == 'Pregnancy Readiness Flaws');
    expect(hasPreg, isFalse,
        reason: 'Pregnancy readiness should not fire on just TSH/FBS');

    // 2. Add some hormonal data
    final womensData = [
      ...overlapData,
      HealthData(
          category: 'Hormonal Panel',
          testName: 'Total Testosterone',
          value: 80.0, // High (PCOS range)
          unit: 'ng/dL',
          date: DateTime.now()),
      HealthData(
          category: 'Hormonal Panel',
          testName: 'AMH (Anti-Müllerian Hormone)',
          value: 1.2, // Low normal
          unit: 'ng/mL',
          date: DateTime.now()),
    ];

    final womensResults = RuleEngine.evaluateHealthData(womensData);

    // Now PCOS, Ovarian Reserve, and Pregnancy Readiness should fire
    final hasPcos =
        womensResults.any((r) => r['disease'] == 'PCOS Risk Profile');
    final hasOvr = womensResults.any((r) => r['disease'] == 'Ovarian Reserve');
    final hasPregR =
        womensResults.any((r) => r['disease'] == 'Pregnancy Readiness Flaws');

    expect(hasPcos, isTrue);
    expect(hasOvr, isTrue);
    expect(hasPregR, isTrue);
  });
}
