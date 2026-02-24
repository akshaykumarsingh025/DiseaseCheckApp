import 'package:flutter/material.dart';

/// A definition for a single lab test input field
class LabTestDefinition {
  final String key;
  final String label;
  final String unit;
  final TextInputType keyboardType;

  const LabTestDefinition({
    required this.key,
    required this.label,
    required this.unit,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
  });
}

/// A master dictionary of all medical categories and their corresponding test fields.
/// This matches the 12 categories outlined in PLAN.md.
const Map<String, List<LabTestDefinition>> medicalTestCategories = {
  'Vitals': [
    LabTestDefinition(
        key: 'heart_rate',
        label: 'Heart Rate (Resting)',
        unit: 'bpm',
        keyboardType: TextInputType.number),
    LabTestDefinition(
        key: 'systolic',
        label: 'Systolic BP',
        unit: 'mmHg',
        keyboardType: TextInputType.number),
    LabTestDefinition(
        key: 'diastolic',
        label: 'Diastolic BP',
        unit: 'mmHg',
        keyboardType: TextInputType.number),
    LabTestDefinition(
        key: 'body_temp_f', label: 'Body Temperature', unit: '°F'),
    LabTestDefinition(
        key: 'respiratory_rate',
        label: 'Respiratory Rate',
        unit: 'breaths/min',
        keyboardType: TextInputType.number),
    LabTestDefinition(
        key: 'spo2',
        label: 'SpO2 (Oxygen Saturation)',
        unit: '%',
        keyboardType: TextInputType.number),
  ],
  'Blood Sugar / Diabetes Panel': [
    LabTestDefinition(
        key: 'fasting_glucose', label: 'Fasting Blood Glucose', unit: 'mg/dL'),
    LabTestDefinition(
        key: 'post_prandial', label: 'Post-Prandial (2hr)', unit: 'mg/dL'),
    LabTestDefinition(key: 'hba1c', label: 'HbA1c', unit: '%'),
    LabTestDefinition(
        key: 'random_glucose', label: 'Random Blood Sugar', unit: 'mg/dL'),
    LabTestDefinition(
        key: 'fasting_insulin', label: 'Fasting Insulin', unit: 'µIU/mL'),
  ],
  'Lipid Panel (Cholesterol)': [
    LabTestDefinition(
        key: 'total_cholesterol', label: 'Total Cholesterol', unit: 'mg/dL'),
    LabTestDefinition(key: 'ldl', label: 'LDL Cholesterol', unit: 'mg/dL'),
    LabTestDefinition(key: 'hdl', label: 'HDL Cholesterol', unit: 'mg/dL'),
    LabTestDefinition(
        key: 'triglycerides', label: 'Triglycerides', unit: 'mg/dL'),
    LabTestDefinition(key: 'vldl', label: 'VLDL Cholesterol', unit: 'mg/dL'),
  ],
  'Complete Blood Count (CBC)': [
    LabTestDefinition(key: 'hemoglobin', label: 'Hemoglobin', unit: 'g/dL'),
    LabTestDefinition(key: 'hematocrit', label: 'Hematocrit (PCV)', unit: '%'),
    LabTestDefinition(key: 'rbc_count', label: 'RBC Count', unit: 'million/µL'),
    LabTestDefinition(key: 'wbc_count', label: 'WBC Count', unit: 'cells/µL'),
    LabTestDefinition(
        key: 'platelet_count', label: 'Platelet Count', unit: '/µL'),
    LabTestDefinition(key: 'mcv', label: 'MCV', unit: 'fL'),
    LabTestDefinition(key: 'mch', label: 'MCH', unit: 'pg'),
    LabTestDefinition(key: 'mchc', label: 'MCHC', unit: 'g/dL'),
    LabTestDefinition(key: 'rdw', label: 'RDW', unit: '%'),
    LabTestDefinition(key: 'esr', label: 'ESR', unit: 'mm/hr'),
  ],
  'Liver Function Tests (LFT)': [
    LabTestDefinition(key: 'alt', label: 'ALT (SGPT)', unit: 'U/L'),
    LabTestDefinition(key: 'ast', label: 'AST (SGOT)', unit: 'U/L'),
    LabTestDefinition(
        key: 'alp', label: 'ALP (Alkaline Phosphatase)', unit: 'U/L'),
    LabTestDefinition(
        key: 'total_bilirubin', label: 'Total Bilirubin', unit: 'mg/dL'),
    LabTestDefinition(
        key: 'direct_bilirubin', label: 'Direct Bilirubin', unit: 'mg/dL'),
    LabTestDefinition(
        key: 'indirect_bilirubin', label: 'Indirect Bilirubin', unit: 'mg/dL'),
    LabTestDefinition(
        key: 'total_protein', label: 'Total Protein', unit: 'g/dL'),
    LabTestDefinition(key: 'albumin', label: 'Albumin', unit: 'g/dL'),
    LabTestDefinition(key: 'globulin', label: 'Globulin', unit: 'g/dL'),
    LabTestDefinition(key: 'ggt', label: 'GGT (Gamma GT)', unit: 'U/L'),
  ],
  'Kidney Function Tests (KFT)': [
    LabTestDefinition(
        key: 'bun', label: 'Blood Urea Nitrogen (BUN)', unit: 'mg/dL'),
    LabTestDefinition(
        key: 'creatinine', label: 'Serum Creatinine', unit: 'mg/dL'),
    LabTestDefinition(key: 'egfr', label: 'eGFR', unit: 'mL/min/1.73m²'),
    LabTestDefinition(key: 'uric_acid', label: 'Uric Acid', unit: 'mg/dL'),
    LabTestDefinition(key: 'sodium', label: 'Sodium (Na)', unit: 'mEq/L'),
    LabTestDefinition(key: 'potassium', label: 'Potassium (K)', unit: 'mEq/L'),
    LabTestDefinition(key: 'chloride', label: 'Chloride (Cl)', unit: 'mEq/L'),
    LabTestDefinition(key: 'calcium', label: 'Calcium', unit: 'mg/dL'),
    LabTestDefinition(key: 'phosphorus', label: 'Phosphorus', unit: 'mg/dL'),
  ],
  'Thyroid Panel': [
    LabTestDefinition(key: 'tsh', label: 'TSH', unit: 'mIU/L'),
    LabTestDefinition(key: 't3_total', label: 'T3 (Total)', unit: 'ng/dL'),
    LabTestDefinition(key: 't4_total', label: 'T4 (Total)', unit: 'µg/dL'),
    LabTestDefinition(key: 'free_t3', label: 'Free T3', unit: 'pg/mL'),
    LabTestDefinition(key: 'free_t4', label: 'Free T4', unit: 'ng/dL'),
  ],
  'Urine Analysis (Urinalysis)': [
    LabTestDefinition(key: 'urine_ph', label: 'pH', unit: ''),
    LabTestDefinition(
        key: 'specific_gravity', label: 'Specific Gravity', unit: ''),
    LabTestDefinition(key: 'urine_wbc', label: 'WBC in Urine', unit: '/HPF'),
    LabTestDefinition(key: 'urine_rbc', label: 'RBC in Urine', unit: '/HPF'),
    LabTestDefinition(key: 'microalbumin', label: 'Microalbumin', unit: 'mg/L'),
  ],
  'Stool Analysis': [
    LabTestDefinition(key: 'stool_ph', label: 'pH', unit: ''),
  ],
  'Pregnancy': [
    LabTestDefinition(key: 'beta_hcg', label: 'Beta-hCG', unit: 'mIU/mL'),
    LabTestDefinition(
        key: 'pregnancy_period',
        label: 'Pregnancy Period',
        unit: 'Weeks',
        keyboardType: TextInputType.number),
  ],
  'Hormonal Panel': [
    LabTestDefinition(
        key: 'amh', label: 'AMH (Anti-Müllerian Hormone)', unit: 'ng/mL'),
    LabTestDefinition(key: 'fsh', label: 'FSH', unit: 'mIU/mL'),
    LabTestDefinition(key: 'lh', label: 'LH', unit: 'mIU/mL'),
    LabTestDefinition(key: 'estradiol', label: 'Estradiol (E2)', unit: 'pg/mL'),
    LabTestDefinition(
        key: 'progesterone', label: 'Progesterone', unit: 'ng/mL'),
    LabTestDefinition(key: 'prolactin', label: 'Prolactin', unit: 'ng/mL'),
    LabTestDefinition(
        key: 'testosterone', label: 'Total Testosterone', unit: 'ng/dL'),
    LabTestDefinition(key: 'dheas', label: 'DHEAS', unit: 'µg/dL'),
  ],
  'Metabolic Panel (Women\'s Health)': [
    LabTestDefinition(
        key: 'fasting_insulin', label: 'Fasting Insulin', unit: 'µIU/mL'),
    LabTestDefinition(
        key: 'homa_ir',
        label: 'HOMA-IR',
        unit: 'Index',
        keyboardType: TextInputType.numberWithOptions(decimal: true)),
  ],
  'Cervical Screening': [
    LabTestDefinition(
        key: 'pap_smear',
        label: 'Pap Smear Result (0=Normal, 1=ASCUS, 2=LSIL, 3=HSIL)',
        unit: 'Score',
        keyboardType: TextInputType.number),
    LabTestDefinition(
        key: 'hpv_status',
        label: 'High-Risk HPV (0=Negative, 1=Positive)',
        unit: 'Score',
        keyboardType: TextInputType.number),
  ],
  'Iron Panel': [
    LabTestDefinition(key: 'serum_iron', label: 'Serum Iron', unit: 'µg/dL'),
    LabTestDefinition(key: 'tibc', label: 'TIBC', unit: 'µg/dL'),
    LabTestDefinition(key: 'ferritin', label: 'Ferritin', unit: 'ng/mL'),
    LabTestDefinition(
        key: 'transferrin_saturation',
        label: 'Transferrin Saturation',
        unit: '%'),
  ],
  'Cardiac Markers': [
    LabTestDefinition(key: 'troponin_i', label: 'Troponin I', unit: 'ng/mL'),
    LabTestDefinition(key: 'troponin_t', label: 'Troponin T', unit: 'ng/mL'),
    LabTestDefinition(key: 'ck_mb', label: 'CK-MB', unit: 'U/L'),
    LabTestDefinition(key: 'bnp', label: 'BNP', unit: 'pg/mL'),
    LabTestDefinition(key: 'nt_pro_bnp', label: 'NT-proBNP', unit: 'pg/mL'),
    LabTestDefinition(
        key: 'crp', label: 'CRP (High Sensitivity)', unit: 'mg/L'),
    LabTestDefinition(
        key: 'homocysteine', label: 'Homocysteine', unit: 'µmol/L'),
  ],
};

/// Get a test definition by its key
LabTestDefinition? getTestDefinition(String key) {
  for (var category in medicalTestCategories.values) {
    for (var def in category) {
      if (def.key == key) return def;
    }
  }
  return null;
}
