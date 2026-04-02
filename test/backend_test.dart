import 'package:flutter_test/flutter_test.dart';
import 'package:disease_check_app/engine/ocr_parser.dart';
import 'package:disease_check_app/models/health_data.dart';
import 'package:disease_check_app/engine/rule_engine.dart';
import 'package:disease_check_app/engine/report_generator.dart';
import 'package:disease_check_app/utils/test_definitions.dart';

void main() {
  test('Backend OCR and Reporting Engine Headless Verification', () {
    String dummyText = """
    Pelvic and Abdominal Ultrasound Report:
    Liver: Echogenic liver texture consistent with fatty infiltration.
    Gallbladder: No stones seen.
    Kidneys: Bilateral nephrolithiasis noted.
    Uterus & Ovaries: Polycystic morphology observed in both ovaries.
    Prostate: Enlarged prostate gland noted.
    Lungs: Patchy opacities seen in lower lobe.
    """;

    Map<String, dynamic> ocrParsedArgs = OcrParser.analyze(dummyText);

    List<HealthData> ocrDataSession = [];
    final now = DateTime.now();

    ocrParsedArgs.forEach((key, value) {
      if (value == null) return;
      final testDef = getTestDefinition(key);
      if (testDef == null) return;
      final double? numVal = double.tryParse(value.toString());
      if (numVal != null) {
        ocrDataSession.add(HealthData(
          category: 'OCR Extraction',
          testName: testDef.label,
          value: numVal,
          unit: testDef.unit,
          date: now,
        ));
      }
    });

    final analysisResults = RuleEngine.evaluateHealthData(ocrDataSession);
    for (var res in analysisResults) {
      expect(res.disease, isNotEmpty);
      expect(res.riskLevel, isIn(['low', 'moderate', 'high']));
    }

    final report = ReportGenerator.generate(analysisResults);
    final allDiseases = [
      ...report.highRiskDiseases,
      ...report.moderateRiskDiseases,
      ...report.lowRiskDiseases,
    ];
    expect(allDiseases.length, greaterThan(0));

    // Test session combination logic
    List<HealthData> historicalData = [
      HealthData(
          category: 'CBC',
          testName: 'Hemoglobin',
          value: 9.0,
          unit: 'g/dL',
          date: now.subtract(const Duration(days: 30))),
    ];

    List<HealthData> combineTrueData = [...historicalData, ...ocrDataSession];
    List<HealthData> combineFalseData = [...ocrDataSession];

    final resTrue = RuleEngine.evaluateHealthData(combineTrueData);
    final resFalse = RuleEngine.evaluateHealthData(combineFalseData);

    // Combined data should produce at least as many results
    expect(resTrue.length, greaterThanOrEqualTo(resFalse.length));
  });
}
