import 'package:flutter_test/flutter_test.dart';
import 'package:disease_check_app/engine/ocr_parser.dart';
import 'package:disease_check_app/models/health_data.dart';
import 'package:disease_check_app/engine/rule_engine.dart';
import 'package:disease_check_app/engine/report_generator.dart';
import 'package:disease_check_app/utils/test_definitions.dart';

void main() {
  test('Backend OCR and Reporting Engine Headless Verification', () {
    print('--- TESTING OCR PARSER ---');
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
    print('Extracted Keys & Values: $ocrParsedArgs');

    print('\\n--- MAPPING TO HEALTH DATA ---');
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
        print('Mapped: ${testDef.label} = $numVal');
      }
    });

    print('\n--- TESTING RULE ENGINE EVALUATION ---');
    final analysisResults = RuleEngine.evaluateHealthData(ocrDataSession);
    print('Analysis Entries: ${analysisResults.length}');
    for (var res in analysisResults) {
      print(
          "- ${res['disease']} -> Risk: ${res['riskLevel']} (${res['riskScore']})");
      print("  Findings: ${(res['findings'] as List).join(', ')}");
    }

    print('\n--- TESTING REPORT GENERATOR ---');
    final report = ReportGenerator.generate(analysisResults);
    print(
        "High Risk Conds: ${report.highRiskDiseases.map((e) => e['disease']).join(', ')}");
    print(
        "Mod Risk Conds: ${report.moderateRiskDiseases.map((e) => e['disease']).join(', ')}");
    print(
        "Low Risk Conds: ${report.lowRiskDiseases.map((e) => e['disease']).join(', ')}");

    print('\n--- TESTING SESSION COMBINATION BUG FIX LOGIC ---');
    print(
        'Scenario: We have historical Hemoglobin data, and we ONLY submit OCR Data for new report.');

    List<HealthData> historicalData = [
      HealthData(
          category: 'CBC',
          testName: 'Hemoglobin',
          value: 9.0,
          unit: 'g/dL',
          date: now.subtract(const Duration(days: 30))),
    ];

    List<HealthData> combineTrueData = [...historicalData, ...ocrDataSession];
    List<HealthData> combineFalseData = [...ocrDataSession]; // History excluded

    final resTrue = RuleEngine.evaluateHealthData(combineTrueData);
    final resFalse = RuleEngine.evaluateHealthData(combineFalseData);

    print(
        "If Combined (Report includes past history): ${resTrue.map((e) => e['disease']).join(', ')}");
    print(
        "If NOT Combined (Report ONLY has session): ${resFalse.map((e) => e['disease']).join(', ')}");

    // Assert logic
    expect(report.highRiskDiseases.length + report.moderateRiskDiseases.length,
        greaterThan(0));
  });
}
