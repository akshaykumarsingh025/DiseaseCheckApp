/// Comprehensive Rule Engine that evaluates health data against clinical
/// guidelines for all 12 medical categories.
///
/// Each check method returns a Map with:
///   - disease: String (disease name)
///   - riskLevel: String ('low', 'moderate', 'high')
///   - riskScore: int (0-100)
///   - findings: List<String> (human-readable clinical findings)
///   - guideline: String (source guideline name)
class RuleEngine {
  // ═══════════════════════════════════════════════════════════════
  // 1. DIABETES (ADA Standards of Care)
  // ═══════════════════════════════════════════════════════════════
  static Map<String, dynamic> checkDiabetes({
    double? fastingGlucose,
    double? hba1c,
    double? postPrandial,
    double? randomGlucose,
    double? fastingInsulin,
  }) {
    double riskScore = 0;
    List<String> findings = [];

    if (fastingGlucose != null) {
      if (fastingGlucose >= 126) {
        riskScore += 40;
        findings.add('FBS $fastingGlucose mg/dL (Diabetic: ≥126)');
      } else if (fastingGlucose >= 100) {
        riskScore += 20;
        findings.add('FBS $fastingGlucose mg/dL (Pre-diabetic: 100-125)');
      }
    }
    if (hba1c != null) {
      if (hba1c >= 6.5) {
        riskScore += 40;
        findings.add('HbA1c $hba1c% (Diabetic: ≥6.5%)');
      } else if (hba1c >= 5.7) {
        riskScore += 20;
        findings.add('HbA1c $hba1c% (Pre-diabetic: 5.7-6.4%)');
      }
    }
    if (postPrandial != null) {
      if (postPrandial >= 200) {
        riskScore += 20;
        findings.add('PP $postPrandial mg/dL (Diabetic: ≥200)');
      } else if (postPrandial >= 140) {
        riskScore += 10;
        findings.add('PP $postPrandial mg/dL (Pre-diabetic: 140-199)');
      }
    }
    if (randomGlucose != null && randomGlucose >= 200) {
      riskScore += 20;
      findings.add('Random Glucose $randomGlucose mg/dL (Diabetic: ≥200)');
    }

    return _buildResult(
        'Type 2 Diabetes', 'E11', riskScore, findings, 'ADA Standards of Care');
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. HYPERTENSION (AHA/ACC Guidelines)
  // ═══════════════════════════════════════════════════════════════
  static Map<String, dynamic> checkHypertension({
    required double systolic,
    required double diastolic,
  }) {
    double riskScore = 0;
    List<String> findings = [];
    String category;

    if (systolic >= 180 || diastolic >= 120) {
      category = 'Hypertensive Crisis';
      riskScore = 100;
    } else if (systolic >= 140 || diastolic >= 90) {
      category = 'Hypertension Stage 2';
      riskScore = 80;
    } else if (systolic >= 130 || diastolic >= 80) {
      category = 'Hypertension Stage 1';
      riskScore = 55;
    } else if (systolic >= 120) {
      category = 'Elevated BP';
      riskScore = 35;
    } else {
      category = 'Normal';
      riskScore = 5;
    }
    findings.add('BP: $systolic/$diastolic mmHg — $category');

    return _buildResult('Hypertension ($category)', 'I10', riskScore, findings,
        'AHA/ACC BP Guidelines');
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. LIPID PANEL (ATP III / AHA Guidelines)
  // ═══════════════════════════════════════════════════════════════
  static Map<String, dynamic> checkCholesterol({
    double? totalCholesterol,
    double? ldl,
    double? hdl,
    double? triglycerides,
    double? vldl,
  }) {
    double riskScore = 0;
    List<String> findings = [];

    if (totalCholesterol != null) {
      if (totalCholesterol >= 240) {
        riskScore += 25;
        findings.add('Total Cholesterol $totalCholesterol mg/dL (High: ≥240)');
      } else if (totalCholesterol >= 200) {
        riskScore += 12;
        findings.add(
            'Total Cholesterol $totalCholesterol mg/dL (Borderline: 200-239)');
      }
    }
    if (ldl != null) {
      if (ldl >= 160) {
        riskScore += 25;
        findings.add('LDL $ldl mg/dL (High: ≥160)');
      } else if (ldl >= 130) {
        riskScore += 15;
        findings.add('LDL $ldl mg/dL (Borderline High: 130-159)');
      } else if (ldl >= 100) {
        riskScore += 5;
        findings.add('LDL $ldl mg/dL (Above Optimal: 100-129)');
      }
    }
    if (hdl != null && hdl < 40) {
      riskScore += 20;
      findings.add('HDL $hdl mg/dL (Low: <40, cardiovascular risk)');
    }
    if (triglycerides != null) {
      if (triglycerides >= 500) {
        riskScore += 30;
        findings.add('Triglycerides $triglycerides mg/dL (Very High: ≥500)');
      } else if (triglycerides >= 200) {
        riskScore += 20;
        findings.add('Triglycerides $triglycerides mg/dL (High: 200-499)');
      } else if (triglycerides >= 150) {
        riskScore += 10;
        findings
            .add('Triglycerides $triglycerides mg/dL (Borderline: 150-199)');
      }
    }

    return _buildResult('Hypercholesterolemia', 'E78.0', riskScore, findings,
        'NCEP ATP III Guidelines');
  }

  // ═══════════════════════════════════════════════════════════════
  // 4. CBC — Complete Blood Count (WHO Anemia & Infection Criteria)
  // ═══════════════════════════════════════════════════════════════
  static Map<String, dynamic> checkAnemia({
    double? hemoglobin,
    double? hematocrit,
    double? mcv,
    double? mch,
    double? ferritin,
  }) {
    double riskScore = 0;
    List<String> findings = [];

    if (hemoglobin != null) {
      if (hemoglobin < 7) {
        riskScore += 50;
        findings.add('Hemoglobin $hemoglobin g/dL (Severe Anemia: <7)');
      } else if (hemoglobin < 10) {
        riskScore += 30;
        findings.add('Hemoglobin $hemoglobin g/dL (Moderate Anemia: <10)');
      } else if (hemoglobin < 12) {
        riskScore += 15;
        findings.add('Hemoglobin $hemoglobin g/dL (Mild Anemia: <12)');
      }
    }
    if (mcv != null) {
      if (mcv < 80) {
        riskScore += 10;
        findings.add('MCV $mcv fL (Microcytic — possible iron deficiency)');
      } else if (mcv > 100) {
        riskScore += 10;
        findings
            .add('MCV $mcv fL (Macrocytic — possible B12/folate deficiency)');
      }
    }

    return _buildResult(
        'Anemia', 'D64.9', riskScore, findings, 'WHO Anemia Grading');
  }

  static Map<String, dynamic> checkWBCAbnormality({
    double? wbcCount,
    double? plateletCount,
  }) {
    double riskScore = 0;
    List<String> findings = [];

    if (wbcCount != null) {
      if (wbcCount > 11000) {
        riskScore += 30;
        findings.add('WBC $wbcCount cells/µL (Leukocytosis: >11,000)');
      } else if (wbcCount < 4000) {
        riskScore += 30;
        findings.add('WBC $wbcCount cells/µL (Leukopenia: <4,000)');
      }
    }
    if (plateletCount != null) {
      if (plateletCount < 150000) {
        riskScore += 30;
        findings
            .add('Platelets $plateletCount /µL (Thrombocytopenia: <150,000)');
      } else if (plateletCount > 400000) {
        riskScore += 20;
        findings.add('Platelets $plateletCount /µL (Thrombocytosis: >400,000)');
      }
    }

    return _buildResult('Blood Cell Abnormality', 'D75.9', riskScore, findings,
        'WHO CBC Guidelines');
  }

  // ═══════════════════════════════════════════════════════════════
  // 5. LIVER FUNCTION TESTS (NAFLD / Hepatitis / Jaundice)
  // ═══════════════════════════════════════════════════════════════
  static Map<String, dynamic> checkLiverDisease({
    double? alt,
    double? ast,
    double? alp,
    double? totalBilirubin,
    double? directBilirubin,
    double? albumin,
    double? ggt,
  }) {
    double riskScore = 0;
    List<String> findings = [];

    if (alt != null && alt > 56) {
      riskScore += 20;
      findings.add('ALT $alt U/L (Elevated: Normal 7-56)');
    }
    if (ast != null && ast > 40) {
      riskScore += 20;
      findings.add('AST $ast U/L (Elevated: Normal 10-40)');
    }
    if (alp != null && alp > 147) {
      riskScore += 15;
      findings.add('ALP $alp U/L (Elevated: Normal 44-147)');
    }
    if (totalBilirubin != null && totalBilirubin > 1.2) {
      riskScore += 15;
      findings.add(
          'Total Bilirubin $totalBilirubin mg/dL (Elevated: Normal 0.1-1.2)');
      if (totalBilirubin > 2.5) {
        riskScore += 15;
        findings.add('Bilirubin $totalBilirubin mg/dL (Jaundice likely: >2.5)');
      }
    }
    if (albumin != null && albumin < 3.5) {
      riskScore += 15;
      findings.add('Albumin $albumin g/dL (Low: Normal 3.5-5.0)');
    }
    if (ggt != null && ggt > 48) {
      riskScore += 10;
      findings.add('GGT $ggt U/L (Elevated: Normal 9-48)');
    }

    return _buildResult('Liver Disease Risk', 'K76.0', riskScore, findings,
        'Liver Function Guidelines');
  }

  // ═══════════════════════════════════════════════════════════════
  // 6. KIDNEY FUNCTION TESTS (KDIGO CKD Staging)
  // ═══════════════════════════════════════════════════════════════
  static Map<String, dynamic> checkKidneyDisease({
    double? bun,
    double? creatinine,
    double? egfr,
    double? uricAcid,
    double? sodium,
    double? potassium,
    double? calcium,
  }) {
    double riskScore = 0;
    List<String> findings = [];

    if (egfr != null) {
      if (egfr < 15) {
        riskScore += 50;
        findings.add('eGFR $egfr (Stage 5 — Kidney Failure)');
      } else if (egfr < 30) {
        riskScore += 40;
        findings.add('eGFR $egfr (Stage 4 — Severe)');
      } else if (egfr < 60) {
        riskScore += 25;
        findings.add('eGFR $egfr (Stage 3 — Moderate CKD)');
      } else if (egfr < 90) {
        riskScore += 10;
        findings.add('eGFR $egfr (Stage 2 — Mild)');
      }
    }
    if (creatinine != null && creatinine > 1.2) {
      riskScore += 15;
      findings.add('Creatinine $creatinine mg/dL (Elevated: Normal 0.6-1.2)');
    }
    if (bun != null && bun > 20) {
      riskScore += 10;
      findings.add('BUN $bun mg/dL (Elevated: Normal 7-20)');
    }
    if (uricAcid != null && uricAcid > 7.0) {
      riskScore += 15;
      findings.add('Uric Acid $uricAcid mg/dL (Elevated: >7.0, Gout risk)');
    }
    if (potassium != null) {
      if (potassium > 5.0) {
        riskScore += 15;
        findings.add('Potassium $potassium mEq/L (Hyperkalemia: >5.0)');
      } else if (potassium < 3.5) {
        riskScore += 15;
        findings.add('Potassium $potassium mEq/L (Hypokalemia: <3.5)');
      }
    }
    if (sodium != null) {
      if (sodium > 145) {
        riskScore += 10;
        findings.add('Sodium $sodium mEq/L (Hypernatremia: >145)');
      } else if (sodium < 135) {
        riskScore += 10;
        findings.add('Sodium $sodium mEq/L (Hyponatremia: <135)');
      }
    }
    if (calcium != null && calcium < 8.5) {
      riskScore += 10;
      findings.add('Calcium $calcium mg/dL (Low: <8.5)');
    }

    return _buildResult('Kidney Disease (CKD)', 'N18', riskScore, findings,
        'KDIGO CKD Guidelines');
  }

  // ═══════════════════════════════════════════════════════════════
  // 7. THYROID PANEL
  // ═══════════════════════════════════════════════════════════════
  static Map<String, dynamic> checkThyroid({
    double? tsh,
    double? freeT3,
    double? freeT4,
  }) {
    double riskScore = 0;
    List<String> findings = [];

    if (tsh != null) {
      if (tsh > 4.0) {
        riskScore += 40;
        findings.add('TSH $tsh mIU/L (High: >4.0 — Hypothyroidism likely)');
        if (freeT4 != null && freeT4 < 0.8) {
          riskScore += 20;
          findings
              .add('Free T4 $freeT4 ng/dL (Low: <0.8 — confirms hypothyroid)');
        }
      } else if (tsh < 0.4) {
        riskScore += 40;
        findings.add('TSH $tsh mIU/L (Low: <0.4 — Hyperthyroidism likely)');
        if (freeT3 != null && freeT3 > 4.4) {
          riskScore += 20;
          findings.add(
              'Free T3 $freeT3 pg/mL (High: >4.4 — confirms hyperthyroid)');
        }
      }
    }

    String disease = 'Thyroid Normal';
    if (riskScore > 0) {
      if (tsh != null && tsh > 4.0) {
        disease = 'Hypothyroidism';
      } else {
        disease = 'Hyperthyroidism';
      }
    }

    return _buildResult(
        disease, 'E03', riskScore, findings, 'Thyroid Function Guidelines');
  }

  // ═══════════════════════════════════════════════════════════════
  // 8. IRON PANEL
  // ═══════════════════════════════════════════════════════════════
  static Map<String, dynamic> checkIronDeficiency({
    double? serumIron,
    double? tibc,
    double? ferritin,
    double? transferrinSaturation,
  }) {
    double riskScore = 0;
    List<String> findings = [];

    if (ferritin != null && ferritin < 12) {
      riskScore += 40;
      findings.add('Ferritin $ferritin ng/mL (Low: <12 — Iron deficiency)');
    } else if (ferritin != null && ferritin < 30) {
      riskScore += 20;
      findings.add('Ferritin $ferritin ng/mL (Borderline low: <30)');
    }
    if (serumIron != null && serumIron < 60) {
      riskScore += 20;
      findings.add('Serum Iron $serumIron µg/dL (Low: <60)');
    }
    if (tibc != null && tibc > 370) {
      riskScore += 10;
      findings.add(
          'TIBC $tibc µg/dL (High: >370 — compensating for iron deficiency)');
    }
    if (transferrinSaturation != null && transferrinSaturation < 20) {
      riskScore += 15;
      findings.add('Transferrin Sat. $transferrinSaturation% (Low: <20%)');
    }

    return _buildResult(
        'Iron Deficiency', 'E61.1', riskScore, findings, 'WHO Iron Guidelines');
  }

  // ═══════════════════════════════════════════════════════════════
  // 9. CARDIAC MARKERS
  // ═══════════════════════════════════════════════════════════════
  static Map<String, dynamic> checkCardiacRisk({
    double? troponinI,
    double? troponinT,
    double? ckMb,
    double? bnp,
    double? ntProBnp,
    double? crp,
    double? homocysteine,
  }) {
    double riskScore = 0;
    List<String> findings = [];

    if (troponinI != null && troponinI > 0.04) {
      riskScore += 40;
      findings.add(
          'Troponin I $troponinI ng/mL (Elevated: >0.04 — Myocardial injury)');
    }
    if (troponinT != null && troponinT > 0.01) {
      riskScore += 40;
      findings.add('Troponin T $troponinT ng/mL (Elevated: >0.01)');
    }
    if (ckMb != null && ckMb > 25) {
      riskScore += 20;
      findings.add('CK-MB $ckMb U/L (Elevated: >25)');
    }
    if (bnp != null && bnp > 100) {
      riskScore += 25;
      findings.add('BNP $bnp pg/mL (Elevated: >100 — Heart failure risk)');
    }
    if (ntProBnp != null && ntProBnp > 300) {
      riskScore += 25;
      findings.add('NT-proBNP $ntProBnp pg/mL (Elevated: >300)');
    }
    if (crp != null && crp > 3.0) {
      riskScore += 15;
      findings.add('hs-CRP $crp mg/L (High risk: >3.0)');
    }
    if (homocysteine != null && homocysteine > 15) {
      riskScore += 10;
      findings.add('Homocysteine $homocysteine µmol/L (Elevated: >15)');
    }

    return _buildResult(
        'Cardiac Risk', 'I25.1', riskScore, findings, 'AHA Cardiac Guidelines');
  }

  // ═══════════════════════════════════════════════════════════════
  // 10. PREGNANCY & WOMEN'S HEALTH (ACOG)
  // ═══════════════════════════════════════════════════════════════
  static Map<String, dynamic> checkPregnancyRisk({
    double? betaHcg,
    double? pregnancyPeriod,
    double? bpSystolic,
    double? urineProtein,
  }) {
    double riskScore = 0;
    List<String> findings = [];

    if (bpSystolic != null &&
        bpSystolic >= 140 &&
        pregnancyPeriod != null &&
        pregnancyPeriod >= 20) {
      riskScore += 40;
      findings.add(
          'Systolic BP $bpSystolic mmHg at ${pregnancyPeriod}wk (Pre-eclampsia risk: ≥140 after 20wk)');
    }

    return _buildResult('Pregnancy Complication Risk', 'O14.9', riskScore,
        findings, 'ACOG Guidelines');
  }

  // ═══════════════════════════════════════════════════════════════
  // 11. URINE ANALYSIS
  // ═══════════════════════════════════════════════════════════════
  static Map<String, dynamic> checkUrineAnalysis({
    double? urineWbc,
    double? microalbumin,
    double? urinePh,
  }) {
    double riskScore = 0;
    List<String> findings = [];

    if (urineWbc != null && urineWbc > 5) {
      riskScore += 30;
      findings.add('Urine WBC $urineWbc /HPF (UTI likely: >5)');
    }
    if (microalbumin != null && microalbumin >= 30) {
      riskScore += 25;
      findings.add(
          'Microalbumin $microalbumin mg/L (Elevated: ≥30 — kidney damage indicator)');
    }

    return _buildResult('Urinary Tract Risk', 'N39.0', riskScore, findings,
        'Urinalysis Guidelines');
  }

  // ═══════════════════════════════════════════════════════════════
  // 12. VITALS — SpO2, Heart Rate, Temperature, Respiratory Rate
  // ═══════════════════════════════════════════════════════════════
  static Map<String, dynamic> checkVitalSigns({
    double? heartRate,
    double? spo2,
    double? bodyTemp,
    double? respiratoryRate,
  }) {
    double riskScore = 0;
    List<String> findings = [];

    if (heartRate != null) {
      if (heartRate > 100) {
        riskScore += 20;
        findings.add('Heart Rate $heartRate bpm (Tachycardia: >100)');
      } else if (heartRate < 60) {
        riskScore += 15;
        findings.add('Heart Rate $heartRate bpm (Bradycardia: <60)');
      }
    }
    if (spo2 != null && spo2 < 95) {
      riskScore += 30;
      findings.add('SpO2 $spo2% (Low: <95% — Hypoxia risk)');
      if (spo2 < 90) {
        riskScore += 20;
        findings.add('SpO2 $spo2% (Critical: <90%)');
      }
    }
    if (bodyTemp != null) {
      if (bodyTemp > 100.4) {
        riskScore += 20;
        findings.add('Temperature $bodyTemp°F (Fever: >100.4°F)');
      } else if (bodyTemp < 97.0) {
        riskScore += 15;
        findings.add('Temperature $bodyTemp°F (Hypothermia: <97°F)');
      }
    }
    if (respiratoryRate != null) {
      if (respiratoryRate > 20) {
        riskScore += 15;
        findings.add('Respiratory Rate $respiratoryRate b/m (Tachypnea: >20)');
      } else if (respiratoryRate < 12) {
        riskScore += 15;
        findings.add('Respiratory Rate $respiratoryRate b/m (Bradypnea: <12)');
      }
    }

    return _buildResult('Vital Signs Abnormality', 'R68.8', riskScore, findings,
        'Clinical Vital Sign Guidelines');
  }

  // ═══════════════════════════════════════════════════════════════
  // MASTER EVALUATOR — processes all HealthData entries
  // ═══════════════════════════════════════════════════════════════
  static List<Map<String, dynamic>> evaluateHealthData(
      List<dynamic> dataEntries) {
    List<Map<String, dynamic>> reports = [];

    // Build a flat lookup map from the data entries: key → value
    Map<String, double> vals = {};
    for (var entry in dataEntries) {
      // Store by the key used in test_definitions.dart
      // The testName now stores the label, and category stores the category name
      // We need to map labels back to keys
      String label = entry.testName.toString();
      double value = entry.value;
      vals[label] = value;
    }

    // Helper to find a value by checking both the label and key
    double? v(String label) => vals[label];

    // --- VITALS ---
    double? heartRate = v('Heart Rate (Resting)');
    double? systolic = v('Systolic BP');
    double? diastolic = v('Diastolic BP');
    double? bodyTemp = v('Body Temperature');
    double? respRate = v('Respiratory Rate');
    double? spo2 = v('SpO2 (Oxygen Saturation)');

    if (systolic != null && diastolic != null) {
      reports.add(checkHypertension(systolic: systolic, diastolic: diastolic));
    }
    if (heartRate != null ||
        spo2 != null ||
        bodyTemp != null ||
        respRate != null) {
      var r = checkVitalSigns(
          heartRate: heartRate,
          spo2: spo2,
          bodyTemp: bodyTemp,
          respiratoryRate: respRate);
      reports.add(r);
    }

    // --- BLOOD SUGAR ---
    double? fbs = v('Fasting Blood Glucose');
    double? hba1c = v('HbA1c');
    double? pp = v('Post-Prandial (2hr)');
    double? rg = v('Random Blood Sugar');
    double? fi = v('Fasting Insulin');
    if (fbs != null || hba1c != null || pp != null || rg != null) {
      reports.add(checkDiabetes(
          fastingGlucose: fbs,
          hba1c: hba1c,
          postPrandial: pp,
          randomGlucose: rg,
          fastingInsulin: fi));
    }

    // --- LIPID PANEL ---
    double? tc = v('Total Cholesterol');
    double? ldl = v('LDL Cholesterol');
    double? hdl = v('HDL Cholesterol');
    double? tg = v('Triglycerides');
    double? vldl = v('VLDL Cholesterol');
    if (tc != null || ldl != null || hdl != null || tg != null) {
      reports.add(checkCholesterol(
          totalCholesterol: tc,
          ldl: ldl,
          hdl: hdl,
          triglycerides: tg,
          vldl: vldl));
    }

    // --- CBC ---
    double? hb = v('Hemoglobin');
    double? hct = v('Hematocrit (PCV)');
    double? mcv = v('MCV');
    double? mch = v('MCH');
    double? wbc = v('WBC Count');
    double? platelets = v('Platelet Count');
    if (hb != null || mcv != null) {
      reports.add(
          checkAnemia(hemoglobin: hb, hematocrit: hct, mcv: mcv, mch: mch));
    }
    if (wbc != null || platelets != null) {
      reports.add(checkWBCAbnormality(wbcCount: wbc, plateletCount: platelets));
    }

    // --- LFT ---
    double? alt = v('ALT (SGPT)');
    double? ast = v('AST (SGOT)');
    double? alp = v('ALP (Alkaline Phosphatase)');
    double? tbil = v('Total Bilirubin');
    double? dbil = v('Direct Bilirubin');
    double? albm = v('Albumin');
    double? ggt = v('GGT (Gamma GT)');
    if (alt != null ||
        ast != null ||
        alp != null ||
        tbil != null ||
        albm != null ||
        ggt != null) {
      reports.add(checkLiverDisease(
          alt: alt,
          ast: ast,
          alp: alp,
          totalBilirubin: tbil,
          directBilirubin: dbil,
          albumin: albm,
          ggt: ggt));
    }

    // --- KFT ---
    double? bun = v('Blood Urea Nitrogen (BUN)');
    double? creat = v('Serum Creatinine');
    double? egfr = v('eGFR');
    double? uricAcid = v('Uric Acid');
    double? na = v('Sodium (Na)');
    double? k = v('Potassium (K)');
    double? ca = v('Calcium');
    if (bun != null ||
        creat != null ||
        egfr != null ||
        uricAcid != null ||
        na != null ||
        k != null) {
      reports.add(checkKidneyDisease(
          bun: bun,
          creatinine: creat,
          egfr: egfr,
          uricAcid: uricAcid,
          sodium: na,
          potassium: k,
          calcium: ca));
    }

    // --- THYROID ---
    double? tsh = v('TSH');
    double? ft3 = v('Free T3');
    double? ft4 = v('Free T4');
    if (tsh != null || ft3 != null || ft4 != null) {
      reports.add(checkThyroid(tsh: tsh, freeT3: ft3, freeT4: ft4));
    }

    // --- IRON PANEL ---
    double? sIron = v('Serum Iron');
    double? tibc = v('TIBC');
    double? ferritin = v('Ferritin');
    double? tSat = v('Transferrin Saturation');
    if (sIron != null || ferritin != null || tibc != null || tSat != null) {
      reports.add(checkIronDeficiency(
          serumIron: sIron,
          tibc: tibc,
          ferritin: ferritin,
          transferrinSaturation: tSat));
    }

    // --- CARDIAC MARKERS ---
    double? tropI = v('Troponin I');
    double? tropT = v('Troponin T');
    double? ckMb = v('CK-MB');
    double? bnp = v('BNP');
    double? ntBnp = v('NT-proBNP');
    double? crpC = v('CRP (High Sensitivity)');
    double? hcy = v('Homocysteine');
    if (tropI != null ||
        tropT != null ||
        ckMb != null ||
        bnp != null ||
        ntBnp != null ||
        crpC != null ||
        hcy != null) {
      reports.add(checkCardiacRisk(
          troponinI: tropI,
          troponinT: tropT,
          ckMb: ckMb,
          bnp: bnp,
          ntProBnp: ntBnp,
          crp: crpC,
          homocysteine: hcy));
    }

    // --- PREGNANCY ---
    double? bhcg = v('Beta-hCG');
    double? pregWeeks = v('Pregnancy Period');
    if (bhcg != null || pregWeeks != null) {
      reports.add(checkPregnancyRisk(
          betaHcg: bhcg, pregnancyPeriod: pregWeeks, bpSystolic: systolic));
    }

    // --- URINE ANALYSIS ---
    double? urWbc = v('WBC in Urine');
    double? microAlb = v('Microalbumin');
    double? urPh = v('pH');
    if (urWbc != null || microAlb != null) {
      reports.add(checkUrineAnalysis(
          urineWbc: urWbc, microalbumin: microAlb, urinePh: urPh));
    }

    return reports;
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER — builds a standardized result Map
  // ═══════════════════════════════════════════════════════════════
  static Map<String, dynamic> _buildResult(
    String disease,
    String icdCode,
    double score,
    List<String> findings,
    String guideline,
  ) {
    score = score.clamp(0, 100);
    String riskLevel;
    if (score >= 70) {
      riskLevel = 'high';
    } else if (score >= 30) {
      riskLevel = 'moderate';
    } else {
      riskLevel = 'low';
    }

    return {
      'disease': disease,
      'icdCode': icdCode,
      'riskScore': score.toInt(),
      'riskLevel': riskLevel,
      'findings': findings,
      'guideline': guideline,
    };
  }
}
