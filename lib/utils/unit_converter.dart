class UnitConverter {
  static double cmToInches(double cm) => cm * 0.393701;
  static double inchesToCm(double inches) => inches * 2.54;

  static double kgToLbs(double kg) => kg * 2.20462;
  static double lbsToKg(double lbs) => lbs / 2.20462;

  static double celsiusToFahrenheit(double c) => (c * 9 / 5) + 32;
  static double fahrenheitToCelsius(double f) => (f - 32) * 5 / 9;

  static double mgDlToMmolL(double mgDl) => mgDl / 18.0182;
  static double mmolLToMgDl(double mmolL) => mmolL * 18.0182;

  static double cholMgDlToMmolL(double mgDl) => mgDl / 38.67;
  static double cholMmolLToMgDl(double mmolL) => mmolL * 38.67;

  static const Map<String, (double min, double max)> _sanityBounds = {
    'glucose': (10, 1000),
    'cholesterol': (50, 800),
    'triglycerides': (20, 3000),
    'creatinine': (0.1, 25),
    'bun': (1, 200),
    'potassium': (1, 10),
    'sodium': (100, 170),
    'calcium': (5, 15),
    'hemoglobin': (2, 25),
    'tsh': (0.01, 100),
    'bilirubin': (0.05, 30),
  };

  static String? validateBeforeConversion(String category, double value) {
    final bounds = _sanityBounds[category];
    if (bounds == null) return null;
    if (value < bounds.$1 || value > bounds.$2) {
      return 'Value $value is outside plausible range (${bounds.$1}-${bounds.$2}). Please verify.';
    }
    return null;
  }

  static double? safeConvertGlucose(double mgDl) {
    final error = validateBeforeConversion('glucose', mgDl);
    if (error != null) return null;
    return mgDlToMmolL(mgDl);
  }

  static double? safeConvertCholesterol(double mgDl) {
    final error = validateBeforeConversion('cholesterol', mgDl);
    if (error != null) return null;
    return cholMgDlToMmolL(mgDl);
  }
}
