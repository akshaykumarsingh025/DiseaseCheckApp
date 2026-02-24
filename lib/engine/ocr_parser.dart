class OcrParser {
  /// Analyzes raw OCR text from a medical report and returns a map of flags.
  /// 1 indicates the condition was found, 0 indicates it was not found or is normal.
  static Map<String, double> analyze(String text) {
    final lowerText = text.toLowerCase();
    Map<String, double> results = {};

    // 1. Fatty Liver (Steatosis)
    // Keywords: fatty liver, fatty infiltration, steatosis, increased echogenicity of the liver, hepatomegaly with fatty changes
    if (lowerText.contains('fatty liver') ||
        lowerText.contains('fatty infiltration') ||
        lowerText.contains('steatosis') ||
        lowerText.contains('increased echogenicity of the liver') ||
        lowerText.contains('diffuse echogenic liver')) {
      results['fatty_liver_flag'] = 1.0;
    } else {
      results['fatty_liver_flag'] = 0.0;
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
    } else {
      results['gallstone_flag'] = 0.0;
    }

    // 3. Kidney Stones (Nephrolithiasis)
    // Keywords: kidney stone, nephrolithiasis, renal calculus, non-obstructing calculus, shadowing in the kidney
    if (lowerText.contains('kidney stone') ||
        lowerText.contains('nephrolithiasis') ||
        lowerText.contains('renal calculus') ||
        lowerText.contains('renal calculi') ||
        (lowerText.contains('kidney') && lowerText.contains('calculus'))) {
      results['kidney_stone_flag'] = 1.0;
    } else {
      results['kidney_stone_flag'] = 0.0;
    }

    // 4. Pneumonia / Lung Consolidation
    // Keywords: consolidation, pneumonia, infiltrate, patchy opacities
    if (lowerText.contains('pneumonia') ||
        lowerText.contains('consolidation') ||
        lowerText.contains('infiltrate') ||
        lowerText.contains('patchy opacity') ||
        lowerText.contains('patchy opacities')) {
      results['pneumonia_flag'] = 1.0;
    } else {
      results['pneumonia_flag'] = 0.0;
    }

    return results;
  }
}
