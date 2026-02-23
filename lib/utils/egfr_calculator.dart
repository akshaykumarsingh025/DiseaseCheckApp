import 'dart:math';

class EgfrCalculator {
  /// Calculates eGFR using the CKD-EPI 2021 equation (race-free).
  /// [scr] is Serum Creatinine in mg/dL
  /// [age] in years
  /// [isFemale] true if female, false if male
  static double calculateCKDEPI(double scr, int age, bool isFemale) {
    if (scr <= 0 || age <= 0) return 0.0;

    double kappa = isFemale ? 0.7 : 0.9;
    double alpha = isFemale ? -0.241 : -0.302;
    double minPart = min(scr / kappa, 1.0);
    double maxPart = max(scr / kappa, 1.0);

    double egfr =
        142.0 * pow(minPart, alpha) * pow(maxPart, -1.200) * pow(0.9938, age);

    if (isFemale) {
      egfr *= 1.012;
    }

    return egfr;
  }
}
