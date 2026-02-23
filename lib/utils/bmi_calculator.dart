class BmiCalculator {
  /// Calculates BMI given weight in kg and height in cm.
  static double calculateBmi(double weightKg, double heightCm) {
    if (heightCm <= 0 || weightKg <= 0) return 0.0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Returns the BMI category based on WHO guidelines.
  static String getBmiCategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi >= 18.5 && bmi < 25.0) {
      return 'Normal weight';
    } else if (bmi >= 25.0 && bmi < 30.0) {
      return 'Overweight';
    } else if (bmi >= 30.0) {
      return 'Obese';
    }
    return 'Unknown';
  }
}
