class UnitConverter {
  // Length
  static double cmToInches(double cm) => cm * 0.393701;
  static double inchesToCm(double inches) => inches * 2.54;

  // Weight
  static double kgToLbs(double kg) => kg * 2.20462;
  static double lbsToKg(double lbs) => lbs / 2.20462;

  // Temperature
  static double celsiusToFahrenheit(double c) => (c * 9 / 5) + 32;
  static double fahrenheitToCelsius(double f) => (f - 32) * 5 / 9;

  // Fasting Blood Sugar / Glucose
  static double mgDlToMmolL(double mgDl) => mgDl / 18.0182;
  static double mmolLToMgDl(double mmolL) => mmolL * 18.0182;

  // Cholesterol / HDL / LDL
  static double cholMgDlToMmolL(double mgDl) => mgDl / 38.67;
  static double cholMmolLToMgDl(double mmolL) => mmolL * 38.67;
}
