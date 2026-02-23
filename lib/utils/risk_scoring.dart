class RiskScoring {
  /// Defines standard risk levels
  static const String riskLow = 'Low';
  static const String riskModerate = 'Moderate';
  static const String riskHigh = 'High';
  static const String riskCritical = 'Critical';

  /// Determines an overall risk level based on the count of abnormal critical values
  static String calculateOverallRisk(int abnormalCount, int criticalCount) {
    if (criticalCount > 1) {
      return riskCritical;
    } else if (criticalCount == 1 || abnormalCount >= 3) {
      return riskHigh;
    } else if (abnormalCount >= 1) {
      return riskModerate;
    } else {
      return riskLow;
    }
  }
}
