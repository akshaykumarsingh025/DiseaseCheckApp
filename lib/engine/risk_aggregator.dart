import 'rule_engine.dart';
import 'ml_engine.dart';

class RiskAggregator {
  final MLEngine mlEngine;

  RiskAggregator(this.mlEngine);

  List<Map<String, dynamic>> evaluateAll(Map<String, dynamic> userData) {
    List<Map<String, dynamic>> results = [];

    // Evaluate Diabetes
    if (userData.containsKey('fbs') || userData.containsKey('hba1c')) {
      final diabetesRisk = RuleEngine.checkDiabetes(
        fastingGlucose: double.tryParse(userData['fbs']?.toString() ?? ''),
        hba1c: double.tryParse(userData['hba1c']?.toString() ?? ''),
      );
      results.add(diabetesRisk);
    }

    // Evaluate Hypertension
    if (userData.containsKey('systolic') && userData.containsKey('diastolic')) {
      final bpRisk = RuleEngine.checkHypertension(
        systolic: double.tryParse(userData['systolic']?.toString() ?? '120') ?? 120,
        diastolic: double.tryParse(userData['diastolic']?.toString() ?? '80') ?? 80,
      );
      results.add(bpRisk);
    }

    return results;
  }
}
