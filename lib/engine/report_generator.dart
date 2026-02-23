import '../models/report.dart';

class ReportGenerator {
  static HealthReport generate(List<Map<String, dynamic>> analysisResults) {
    List<dynamic> high = [];
    List<dynamic> moderate = [];
    List<dynamic> low = [];
    List<String> abnormals = [];

    for (var res in analysisResults) {
      if (res['riskLevel'] == 'high') {
        high.add(res);
      } else if (res['riskLevel'] == 'moderate') {
        moderate.add(res);
      } else {
        low.add(res);
      }
      
      if (res['findings'] != null) {
        abnormals.addAll(List<String>.from(res['findings']));
      }
    }

    return HealthReport(
      reportId: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      highRiskDiseases: high,
      moderateRiskDiseases: moderate,
      lowRiskDiseases: low,
      abnormalValues: abnormals,
    );
  }
}
