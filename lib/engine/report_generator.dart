import 'package:uuid/uuid.dart';
import '../models/report.dart';
import 'risk_result.dart';

class ReportGenerator {
  static HealthReport generate(List<RiskResult> analysisResults) {
    List<RiskResult> high = [];
    List<RiskResult> moderate = [];
    List<RiskResult> low = [];
    List<String> abnormals = [];

    List<Map<String, dynamic>> audit = [];

    for (var res in analysisResults) {
      if (res.riskLevel == 'high') {
        high.add(res);
      } else if (res.riskLevel == 'moderate') {
        moderate.add(res);
      } else {
        low.add(res);
      }

      abnormals.addAll(res.findings);

      audit.add({
        'disease': res.disease,
        'icdCode': res.icdCode,
        'riskScore': res.riskScore,
        'riskLevel': res.riskLevel,
        'findings': res.findings,
        'guideline': res.guideline,
      });
    }

    return HealthReport(
      reportId: const Uuid().v4(),
      date: DateTime.now(),
      highRiskDiseases: high.map((r) => r.toMap()).toList(),
      moderateRiskDiseases: moderate.map((r) => r.toMap()).toList(),
      lowRiskDiseases: low.map((r) => r.toMap()).toList(),
      abnormalValues: abnormals,
      auditTrail: audit,
    );
  }
}
