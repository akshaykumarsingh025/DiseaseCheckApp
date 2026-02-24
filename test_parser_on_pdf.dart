import 'dart:io';

void main() async {
  final file = File('extracted_pdf_text.txt');
  final text = await file.readAsString();

  Map<String, dynamic> results = {};

  // Hardcode a few tests to check matching mechanics quickly
  final testsToCheck = [
    {'key': 'hemoglobin', 'label': 'Hemoglobin'},
    {'key': 'rbc', 'label': 'RBC'},
    {'key': 'platelet_count', 'label': 'Platelet Count'},
    {'key': 'bilirubin_total', 'label': 'Bilirubin-Total'},
    {'key': 'creatinine', 'label': 'Creatinine'},
    {'key': 'uric_acid', 'label': 'Uric Acid'},
  ];

  for (var testDef in testsToCheck) {
    String simplifiedLabel =
        testDef['label']!.replaceAll(RegExp(r'\(.*?\)'), '').trim();

    // The exact regex we currently have in ocr_parser.dart
    final regex = RegExp(
      r'(?:\b|[^a-zA-Z0-9])' +
          RegExp.escape(simplifiedLabel) +
          r'[^\d]{0,15}?(\d+(\.\d+)?)',
      caseSensitive: false,
    );

    final match = regex.firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      final numberStr = match.group(1);
      if (numberStr != null) {
        results[testDef['key']!] = double.tryParse(numberStr);
      }
    }
  }

  print('--- OCR Sandbox Extraction ---');
  results.forEach((k, v) => print('$k: $v'));
}
