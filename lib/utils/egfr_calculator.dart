import 'dart:math';

class EgfrCalculator {
  static double calculateCKDEPI(double scr, int age, bool isFemale) {
    if (scr <= 0) return 0.0;
    if (age <= 0 || age > 120) return 0.0;
    if (scr > 25) return 0.0;

    double kappa = isFemale ? 0.7 : 0.9;
    double alpha = isFemale ? -0.241 : -0.302;
    double minPart = min(scr / kappa, 1.0);
    double maxPart = max(scr / kappa, 1.0);

    double egfr =
        142.0 * pow(minPart, alpha) * pow(maxPart, -1.200) * pow(0.9938, age);

    if (isFemale) {
      egfr *= 1.012;
    }

    if (egfr.isNaN || egfr.isInfinite) return 0.0;

    return egfr.clamp(0.0, 300.0);
  }

  static double convertCreatinineUmolToMgDl(double umolL) {
    return umolL / 88.4;
  }

  static double convertCreatinineMgDlToUmol(double mgDl) {
    return mgDl * 88.4;
  }
}
