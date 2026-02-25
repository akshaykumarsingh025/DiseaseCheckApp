import '../utils/test_definitions.dart';

class OcrParser {
  /// Analyzes raw OCR text from a medical report and returns a map of flags and extracted values.
  /// 1.0 indicates a condition was found, 0.0 indicates it was not found or is normal.
  /// For structured lab tests, it returns the extracted numeric value.
  static Map<String, dynamic> analyze(String text) {
    final lowerText = text.toLowerCase();
    Map<String, dynamic> results = {};

    // 1. Fatty Liver (Steatosis)
    // Keywords: fatty liver, fatty infiltration, steatosis, increased echogenicity of the liver, hepatomegaly with fatty changes
    if (lowerText.contains('fatty liver') ||
        lowerText.contains('fatty infiltration') ||
        lowerText.contains('steatosis') ||
        lowerText.contains('increased echogenicity of the liver') ||
        lowerText.contains('diffuse echogenic liver')) {
      results['fatty_liver_flag'] = 1.0;
    }

    // 2. Gallstones (Cholelithiasis)
    // Keywords: gallstone, cholelithiasis, calculi in the gallbladder, echogenic focus with shadowing
    if (lowerText.contains('gallstone') ||
        lowerText.contains('cholelithiasis') ||
        lowerText.contains('calculi in the gallbladder') ||
        lowerText.contains('calculus in the gallbladder') ||
        (lowerText.contains('gallbladder') &&
            lowerText.contains('shadowing'))) {
      results['gallstone_flag'] = 1.0;
    }

    // 3. Kidney Stones (Nephrolithiasis)
    // Keywords: kidney stone, nephrolithiasis, renal calculus, non-obstructing calculus, shadowing in the kidney
    if (lowerText.contains('kidney stone') ||
        lowerText.contains('nephrolithiasis') ||
        lowerText.contains('renal calculus') ||
        lowerText.contains('renal calculi') ||
        (lowerText.contains('kidney') && lowerText.contains('calculus'))) {
      results['kidney_stone_flag'] = 1.0;
    }

    // 4. Pneumonia / Lung Consolidation
    // Keywords: consolidation, pneumonia, infiltrate, patchy opacities
    if (lowerText.contains('pneumonia') ||
        lowerText.contains('consolidation') ||
        lowerText.contains('infiltrate') ||
        lowerText.contains('patchy opacity') ||
        lowerText.contains('patchy opacities')) {
      results['pneumonia_flag'] = 1.0;
    }

    // 5. Polycystic Ovaries / PCOS Morphology (Pelvic Ultrasound)
    if (lowerText.contains('polycystic morphology') ||
        lowerText.contains('polycystic ovaries') ||
        lowerText.contains('multiple follicles') ||
        lowerText.contains('pcom') ||
        lowerText.contains('string of pearls')) {
      results['pcos_imaging_flag'] = 1.0;
    }

    // 6. Enlarged Prostate / BPH (Pelvic/Transrectal Ultrasound)
    if (lowerText.contains('enlarged prostate') ||
        lowerText.contains('prostatomegaly') ||
        lowerText.contains('bph') ||
        lowerText.contains('benign prostatic hyperplasia') ||
        lowerText.contains('significant post void residual')) {
      results['prostate_enlarged_flag'] = 1.0;
    }

    // 7. Dynamic extraction for all other standard lab tests
    // Look for the test label followed by a number (e.g., "Hemoglobin: 14.5")
    for (var category in medicalTestCategories.values) {
      for (var testDef in category) {
        // Skip flag-based tests as we handled them above
        if (testDef.unit == 'Flag' || testDef.unit == 'Score') continue;

        // Simplify label to prevent Regex breakage (e.g., "AMH (Anti-Müllerian)" -> "AMH")
        String simplifiedLabel =
            testDef.label.replaceAll(RegExp(r'\(.*?\)'), '').trim();
        if (simplifiedLabel.isEmpty) simplifiedLabel = testDef.label;

        List<String> searchTerms = [simplifiedLabel, ...testDef.ocrAliases];

        for (var term in searchTerms) {
          // E.g., match "AMH: 1.0" or "Hemoglobin = 14.5"
          final regex = RegExp(
            r'(?:\b|[^a-zA-Z0-9])' +
                RegExp.escape(term) +
                r'[^\d]{0,15}?(\d+(\.\d+)?)',
            caseSensitive: false,
          );

          final match = regex.firstMatch(text);
          if (match != null && match.groupCount >= 1) {
            final numberStr = match.group(1);
            if (numberStr != null) {
              final val = double.tryParse(numberStr);
              if (val != null) {
                results[testDef.key] = val;
                break; // Stop checking aliases once we find a match
              }
            }
          }
        }
      }
    }

    return results;
  }
}
