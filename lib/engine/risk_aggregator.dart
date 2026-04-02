import 'rule_engine.dart';
import 'ml_engine.dart';
import 'risk_result.dart';

class RiskAggregator {
  final MLEngine mlEngine;

  RiskAggregator(this.mlEngine);

  List<RiskResult> evaluateAll(Map<String, dynamic> userData) {
    List<RiskResult> results = [];

    // Evaluate Diabetes (rule-based)
    if (userData.containsKey('fbs') || userData.containsKey('hba1c')) {
      results.add(RuleEngine.checkDiabetes(
        fastingGlucose:
            double.tryParse(userData['fbs']?.toString() ?? ''),
        hba1c: double.tryParse(userData['hba1c']?.toString() ?? ''),
      ));
    }

    // Augment with ML prediction if available
    if (mlEngine.isReady) {
      final mlProb = mlEngine.predictDiabetes(
        bmi: double.tryParse(userData['bmi']?.toString() ?? '') ?? 0,
        age: double.tryParse(userData['age']?.toString() ?? '') ?? 0,
        glucose: double.tryParse(userData['fbs']?.toString() ?? '') ?? 0,
        hba1c: double.tryParse(userData['hba1c']?.toString() ?? '') ?? 0,
        bpSystolic:
            double.tryParse(userData['systolic']?.toString() ?? '') ?? 0,
        insulin:
            double.tryParse(userData['insulin']?.toString() ?? '') ?? 0,
      );
      if (mlProb != null) {
        results.add(RiskResult.build(
          disease: 'Type 2 Diabetes (ML)',
          icdCode: 'E11',
          score: mlProb * 100,
          findings: [
            'ML model predicts ${(mlProb * 100).toStringAsFixed(1)}% diabetes probability'
          ],
          guideline: 'ML Model Prediction',
        ));
      }
    }

    // Evaluate Hypertension
    if (userData.containsKey('systolic') &&
        userData.containsKey('diastolic')) {
      results.add(RuleEngine.checkHypertension(
        systolic:
            double.tryParse(userData['systolic']?.toString() ?? '120') ??
                120,
        diastolic:
            double.tryParse(userData['diastolic']?.toString() ?? '80') ??
                80,
      ));
    }

    return results;
  }
}
