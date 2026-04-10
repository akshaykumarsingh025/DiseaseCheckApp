class IcdLookupService {
  static const Map<String, Map<String, String>> _icd10Map = {
    'I10': {
      'name': 'Essential (Primary) Hypertension',
      'chapter': 'Circulatory System'
    },
    'I25.1': {
      'name': 'Atherosclerotic Heart Disease',
      'chapter': 'Circulatory System'
    },
    'I48': {
      'name': 'Atrial Fibrillation and Flutter',
      'chapter': 'Circulatory System'
    },
    'I50.9': {
      'name': 'Heart Failure, Unspecified',
      'chapter': 'Circulatory System'
    },
    'I73.9': {
      'name': 'Peripheral Vascular Disease, Unspecified',
      'chapter': 'Circulatory System'
    },
    'I82.9': {
      'name': 'Venous Thrombosis, Unspecified',
      'chapter': 'Circulatory System'
    },
    'E10': {
      'name': 'Type 1 Diabetes Mellitus',
      'chapter': 'Endocrine/Nutritional'
    },
    'E11': {
      'name': 'Type 2 Diabetes Mellitus',
      'chapter': 'Endocrine/Nutritional'
    },
    'O24.4': {
      'name': 'Gestational Diabetes Mellitus',
      'chapter': 'Pregnancy/Childbirth'
    },
    'E88.81': {
      'name': 'Metabolic Syndrome',
      'chapter': 'Endocrine/Nutritional'
    },
    'E03.9': {
      'name': 'Hypothyroidism, Unspecified',
      'chapter': 'Endocrine/Nutritional'
    },
    'E05.9': {
      'name': 'Hyperthyroidism, Unspecified',
      'chapter': 'Endocrine/Nutritional'
    },
    'E55.9': {
      'name': 'Vitamin D Deficiency, Unspecified',
      'chapter': 'Endocrine/Nutritional'
    },
    'E61.1': {'name': 'Iron Deficiency', 'chapter': 'Endocrine/Nutritional'},
    'E29.1': {
      'name': 'Testicular Hypofunction',
      'chapter': 'Endocrine/Nutritional'
    },
    'E28.2': {
      'name': 'Polycystic Ovarian Syndrome',
      'chapter': 'Endocrine/Nutritional'
    },
    'E66.0': {
      'name': 'Obesity due to Excess Calories',
      'chapter': 'Endocrine/Nutritional'
    },
    'E78.0': {
      'name': 'Hypercholesterolemia',
      'chapter': 'Endocrine/Nutritional'
    },
    'N18': {'name': 'Chronic Kidney Disease', 'chapter': 'Genitourinary'},
    'N17.9': {
      'name': 'Acute Kidney Injury, Unspecified',
      'chapter': 'Genitourinary'
    },
    'N04.9': {
      'name': 'Nephrotic Syndrome, Unspecified',
      'chapter': 'Genitourinary'
    },
    'N39.0': {'name': 'Urinary Tract Infection', 'chapter': 'Genitourinary'},
    'N97.9': {
      'name': 'Female Infertility, Unspecified',
      'chapter': 'Genitourinary'
    },
    'N95.1': {'name': 'Menopausal States', 'chapter': 'Genitourinary'},
    'N46': {'name': 'Male Infertility', 'chapter': 'Genitourinary'},
    'N40': {'name': 'Benign Prostatic Hyperplasia', 'chapter': 'Genitourinary'},
    'N20.0': {'name': 'Calculus of Kidney', 'chapter': 'Genitourinary'},
    'N80.9': {'name': 'Endometriosis, Unspecified', 'chapter': 'Genitourinary'},
    'D25.9': {'name': 'Uterine Fibroids, Unspecified', 'chapter': 'Neoplasms'},
    'K76.0': {'name': 'Fatty Liver Disease', 'chapter': 'Digestive'},
    'K80.20': {'name': 'Gallstones', 'chapter': 'Digestive'},
    'K75.81': {
      'name': 'Non-Alcoholic Steatohepatitis (NASH)',
      'chapter': 'Digestive'
    },
    'K70.9': {'name': 'Alcoholic Liver Disease', 'chapter': 'Digestive'},
    'B18.1': {'name': 'Chronic Viral Hepatitis B', 'chapter': 'Infectious'},
    'B18.2': {'name': 'Chronic Viral Hepatitis C', 'chapter': 'Infectious'},
    'A15.9': {'name': 'Respiratory Tuberculosis', 'chapter': 'Infectious'},
    'U07.1': {'name': 'COVID-19', 'chapter': 'Infectious'},
    'Z11.4': {
      'name': 'Encounter for HIV Screening',
      'chapter': 'Factors Influencing Health'
    },
    'J18.9': {'name': 'Pneumonia, Unspecified', 'chapter': 'Respiratory'},
    'D50.9': {'name': 'Iron Deficiency Anemia', 'chapter': 'Blood'},
    'D51.9': {'name': 'Vitamin B12 Deficiency Anemia', 'chapter': 'Blood'},
    'D64.9': {'name': 'Anemia, Unspecified', 'chapter': 'Blood'},
    'D75.9': {'name': 'Blood Cell Abnormality', 'chapter': 'Blood'},
    'C61': {'name': 'Malignant Neoplasm of Prostate', 'chapter': 'Neoplasms'},
    'C18.9': {'name': 'Malignant Neoplasm of Colon', 'chapter': 'Neoplasms'},
    'C22.0': {'name': 'Liver Cell Carcinoma', 'chapter': 'Neoplasms'},
    'M10.9': {'name': 'Gout, Unspecified', 'chapter': 'Musculoskeletal'},
    'M81.0': {'name': 'Age-Related Osteoporosis', 'chapter': 'Musculoskeletal'},
    'F32.9': {
      'name': 'Major Depressive Disorder, Single Episode',
      'chapter': 'Mental Health'
    },
    'F41.1': {
      'name': 'Generalized Anxiety Disorder',
      'chapter': 'Mental Health'
    },
    'F52.2': {
      'name': 'Failure of Genital Response',
      'chapter': 'Mental Health'
    },
    'F53': {'name': 'Postpartum Depression', 'chapter': 'Mental Health'},
    'G47.33': {'name': 'Obstructive Sleep Apnea', 'chapter': 'Nervous System'},
    'G43.9': {'name': 'Migraine, Unspecified', 'chapter': 'Nervous System'},
    'R68.8': {'name': 'Other General Symptoms', 'chapter': 'Symptoms/Signs'},
    'O14.9': {'name': 'Pre-Eclampsia', 'chapter': 'Pregnancy/Childbirth'},
    'O99.28': {
      'name': 'Thyroid Dysfunction in Pregnancy',
      'chapter': 'Pregnancy/Childbirth'
    },
    'Z12.4': {
      'name': 'Encounter for Cervical Cancer Screening',
      'chapter': 'Factors Influencing Health'
    },
    'Z12.11': {
      'name': 'Encounter for Lung Cancer Screening',
      'chapter': 'Factors Influencing Health'
    },
    'Z12.31': {
      'name': 'Encounter for Breast Cancer Screening',
      'chapter': 'Factors Influencing Health'
    },
    'Z31.8': {
      'name': 'Other Procreative Management',
      'chapter': 'Factors Influencing Health'
    },
    'T56.0': {'name': 'Toxic Effect of Lead', 'chapter': 'Injury/Poisoning'},
    'E23.0': {
      'name': 'Hypopituitarism (Growth Hormone Deficiency)',
      'chapter': 'Endocrine/Nutritional'
    },
  };

  static Map<String, String>? lookup(String icd10Code) {
    return _icd10Map[icd10Code];
  }

  static String? getDiseaseName(String icd10Code) {
    return _icd10Map[icd10Code]?['name'];
  }

  static String? getChapter(String icd10Code) {
    return _icd10Map[icd10Code]?['chapter'];
  }

  static List<MapEntry<String, Map<String, String>>> search(String query) {
    final q = query.toLowerCase();
    return _icd10Map.entries
        .where((e) =>
            e.key.toLowerCase().contains(q) ||
            e.value['name']!.toLowerCase().contains(q))
        .toList();
  }
}
