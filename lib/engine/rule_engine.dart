class RuleEngine {
  /// Check diabetes risk based on ADA criteria
  static Map<String, dynamic> checkDiabetes({
    double? fastingGlucose,
    double? hba1c,
    double? postPrandial,
    double? randomGlucose,
  }) {
    double riskScore = 0;
    String riskLevel = 'low';
    List<String> findings = [];

    // ADA Criteria: Fasting Blood Glucose
    if (fastingGlucose != null) {
      if (fastingGlucose >= 126) {
        riskScore += 40;
        findings.add('FBS ${fastingGlucose} mg/dL (Diabetic range: ≥126)');
      } else if (fastingGlucose >= 100) {
        riskScore += 20;
        findings.add('FBS ${fastingGlucose} mg/dL (Pre-diabetic: 100-125)');
      }
    }

    // ADA Criteria: HbA1c
    if (hba1c != null) {
      if (hba1c >= 6.5) {
        riskScore += 40;
        findings.add('HbA1c ${hba1c}% (Diabetic range: ≥6.5%)');
      } else if (hba1c >= 5.7) {
        riskScore += 20;
        findings.add('HbA1c ${hba1c}% (Pre-diabetic: 5.7-6.4%)');
      }
    }

    // Determine risk level
    if (riskScore >= 70) {
      riskLevel = 'high';
    } else if (riskScore >= 30) {
      riskLevel = 'moderate';
    }

    return {
      'disease': 'Type 2 Diabetes',
      'icdCode': 'E11',
      'riskScore': riskScore.clamp(0, 100).toInt(),
      'riskLevel': riskLevel,
      'findings': findings,
      'guideline': 'ADA Standards of Care 2024',
    };
  }

  /// Check hypertension based on AHA/ACC guidelines
  static Map<String, dynamic> checkHypertension({
    required double systolic,
    required double diastolic,
  }) {
    String category;
    String riskLevel;
    int riskScore;

    if (systolic >= 180 || diastolic >= 120) {
      category = 'Hypertensive Crisis';
      riskLevel = 'high';
      riskScore = 100;
    } else if (systolic >= 140 || diastolic >= 90) {
      category = 'Hypertension Stage 2';
      riskLevel = 'high';
      riskScore = 80;
    } else if (systolic >= 130 || diastolic >= 80) {
      category = 'Hypertension Stage 1';
      riskLevel = 'moderate';
      riskScore = 55;
    } else {
      category = 'Normal / Elevated';
      riskLevel = 'low';
      riskScore = 10;
    }

    return {
      'disease': 'Hypertension ($category)',
      'icdCode': 'I10',
      'riskScore': riskScore,
      'riskLevel': riskLevel,
      'findings': ['BP: $systolic/$diastolic mmHg — $category'],
      'guideline': 'AHA/ACC Blood Pressure Guidelines',
    };
  }

  /// Evaluates a list of health data points against predefined rules.
  static List<Map<String, dynamic>> evaluateHealthData(
      List<dynamic> dataEntries) {
    List<Map<String, dynamic>> reports = [];

    double? fbs;
    double? hba1c;
    double? postPrandial;
    double? randomGluc;

    double? systolic;
    double? diastolic;

    // Parse data safely, assuming it's from the Hive HealthData model
    for (var entry in dataEntries) {
      String testName = entry.testName.toLowerCase();
      double value = entry.value;

      if (testName.contains('fasting glucose') ||
          testName == 'fasting_glucose') {
        fbs = value;
      } else if (testName == 'hba1c') {
        hba1c = value;
      } else if (testName.contains('post prandial') ||
          testName == 'post_prandial') {
        postPrandial = value;
      } else if (testName.contains('random glucose') ||
          testName == 'random_glucose') {
        randomGluc = value;
      } else if (testName.contains('systolic')) {
        systolic = value;
      } else if (testName.contains('diastolic')) {
        diastolic = value;
      }
    }

    // Diabetes Check
    if (fbs != null ||
        hba1c != null ||
        postPrandial != null ||
        randomGluc != null) {
      var diabetesReport = checkDiabetes(
        fastingGlucose: fbs,
        hba1c: hba1c,
        postPrandial: postPrandial,
        randomGlucose: randomGluc,
      );
      if (diabetesReport['riskLevel'] != 'low') {
        reports.add(diabetesReport);
      }
    }

    // Hypertension Check
    if (systolic != null && diastolic != null) {
      var htnReport =
          checkHypertension(systolic: systolic, diastolic: diastolic);
      if (htnReport['riskLevel'] != 'low') {
        reports.add(htnReport);
      }
    }

    return reports;
  }
}
