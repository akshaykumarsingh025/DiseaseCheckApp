class ReferenceRanges {
  static Map<String, dynamic> _ranges = {};

  static Future<void> loadRanges() async {
    try {
      _ranges = _fallbackRanges;
    } catch (e) {
      _ranges = _fallbackRanges;
    }
  }

  static bool isAbnormal(String category, String field, double value) {
    if (_ranges.isEmpty) {
      _ranges = _fallbackRanges;
    }

    if (_ranges.containsKey(category) && _ranges[category].containsKey(field)) {
      final range = _ranges[category][field];
      double min = (range['normal_min'] as num).toDouble();
      double max = (range['normal_max'] as num).toDouble();
      return value < min || value > max;
    }
    return false;
  }

  static Map<String, dynamic> getRange(String category, String field) {
    if (_ranges.isEmpty) {
      _ranges = _fallbackRanges;
    }
    if (_ranges.containsKey(category) && _ranges[category].containsKey(field)) {
      return _ranges[category][field];
    }
    return {};
  }

  static const Map<String, dynamic> _fallbackRanges = {
    "blood_sugar": {
      "fasting_glucose": {"unit": "mg/dL", "normal_min": 70, "normal_max": 99},
      "post_prandial": {"unit": "mg/dL", "normal_min": 0, "normal_max": 139},
      "hba1c": {"unit": "%", "normal_min": 0, "normal_max": 5.6},
      "random_glucose": {"unit": "mg/dL", "normal_min": 0, "normal_max": 139}
    },
    "lipid_panel": {
      "total_cholesterol": {
        "unit": "mg/dL",
        "normal_min": 0,
        "normal_max": 199
      },
      "ldl": {"unit": "mg/dL", "normal_min": 0, "normal_max": 99},
      "hdl": {"unit": "mg/dL", "normal_min": 40, "normal_max": 150},
      "triglycerides": {"unit": "mg/dL", "normal_min": 0, "normal_max": 149}
    },
    "vitals": {
      "systolic_bp": {"unit": "mmHg", "normal_min": 90, "normal_max": 119},
      "diastolic_bp": {"unit": "mmHg", "normal_min": 60, "normal_max": 79},
      "heart_rate": {"unit": "bpm", "normal_min": 60, "normal_max": 100}
    },
    "complete_blood_count": {
      "hemoglobin_male": {
        "unit": "g/dL",
        "normal_min": 13.5,
        "normal_max": 17.5
      },
      "hemoglobin_female": {
        "unit": "g/dL",
        "normal_min": 12.0,
        "normal_max": 15.5
      },
      "hematocrit_male": {"unit": "%", "normal_min": 41, "normal_max": 50},
      "hematocrit_female": {"unit": "%", "normal_min": 36, "normal_max": 44},
      "wbc_count": {
        "unit": "cells/µL",
        "normal_min": 4500,
        "normal_max": 11000
      },
      "platelet_count": {
        "unit": "/µL",
        "normal_min": 150000,
        "normal_max": 400000
      },
      "mcv": {"unit": "fL", "normal_min": 80, "normal_max": 100},
      "mch": {"unit": "pg", "normal_min": 27, "normal_max": 33},
      "mchc": {"unit": "g/dL", "normal_min": 32, "normal_max": 36}
    },
    "kidney_function": {
      "egfr": {"unit": "mL/min/1.73m²", "normal_min": 90, "normal_max": 150},
      "creatinine_male": {
        "unit": "mg/dL",
        "normal_min": 0.7,
        "normal_max": 1.3
      },
      "creatinine_female": {
        "unit": "mg/dL",
        "normal_min": 0.6,
        "normal_max": 1.1
      },
      "bun": {"unit": "mg/dL", "normal_min": 7, "normal_max": 20},
      "uric_acid_male": {"unit": "mg/dL", "normal_min": 3.4, "normal_max": 7.0},
      "uric_acid_female": {
        "unit": "mg/dL",
        "normal_min": 2.4,
        "normal_max": 6.0
      },
      "sodium": {"unit": "mEq/L", "normal_min": 135, "normal_max": 145},
      "potassium": {"unit": "mEq/L", "normal_min": 3.5, "normal_max": 5.0},
      "calcium": {"unit": "mg/dL", "normal_min": 8.5, "normal_max": 10.5}
    },
    "liver_function": {
      "alt": {"unit": "U/L", "normal_min": 7, "normal_max": 56},
      "ast": {"unit": "U/L", "normal_min": 10, "normal_max": 40},
      "alp": {"unit": "U/L", "normal_min": 44, "normal_max": 147},
      "total_bilirubin": {
        "unit": "mg/dL",
        "normal_min": 0.1,
        "normal_max": 1.2
      },
      "direct_bilirubin": {
        "unit": "mg/dL",
        "normal_min": 0.0,
        "normal_max": 0.3
      },
      "albumin": {"unit": "g/dL", "normal_min": 3.5, "normal_max": 5.0},
      "ggt": {"unit": "U/L", "normal_min": 9, "normal_max": 48}
    },
    "thyroid_panel": {
      "tsh": {"unit": "mIU/L", "normal_min": 0.4, "normal_max": 4.0},
      "free_t4": {"unit": "ng/dL", "normal_min": 0.8, "normal_max": 1.8},
      "free_t3": {"unit": "pg/mL", "normal_min": 2.3, "normal_max": 4.2},
      "t3_total": {"unit": "ng/dL", "normal_min": 80, "normal_max": 200},
      "t4_total": {"unit": "µg/dL", "normal_min": 5.0, "normal_max": 12.0}
    },
    "iron_studies": {
      "serum_iron": {"unit": "µg/dL", "normal_min": 60, "normal_max": 170},
      "tibc": {"unit": "µg/dL", "normal_min": 240, "normal_max": 450},
      "ferritin_male": {"unit": "ng/mL", "normal_min": 20, "normal_max": 250},
      "ferritin_female": {"unit": "ng/mL", "normal_min": 10, "normal_max": 150},
      "transferrin_saturation": {
        "unit": "%",
        "normal_min": 20,
        "normal_max": 50
      }
    },
    "vitamins": {
      "vitamin_b12": {"unit": "pg/mL", "normal_min": 200, "normal_max": 900},
      "folate": {"unit": "ng/mL", "normal_min": 3.0, "normal_max": 20.0},
      "vitamin_d_25oh": {"unit": "ng/mL", "normal_min": 30, "normal_max": 100}
    },
    "inflammatory_markers": {
      "crp": {"unit": "mg/L", "normal_min": 0, "normal_max": 3.0},
      "esr": {"unit": "mm/hr", "normal_min": 0, "normal_max": 20},
      "procalcitonin": {"unit": "ng/mL", "normal_min": 0, "normal_max": 0.5}
    },
    "cardiac_markers": {
      "troponin_i": {"unit": "ng/mL", "normal_min": 0, "normal_max": 0.04},
      "troponin_t": {"unit": "ng/mL", "normal_min": 0, "normal_max": 0.01},
      "ck_mb": {"unit": "U/L", "normal_min": 0, "normal_max": 25},
      "bnp": {"unit": "pg/mL", "normal_min": 0, "normal_max": 100},
      "nt_pro_bnp": {"unit": "pg/mL", "normal_min": 0, "normal_max": 300},
      "homocysteine": {"unit": "µmol/L", "normal_min": 5, "normal_max": 15}
    },
    "coagulation": {
      "pt_inr": {"unit": "INR", "normal_min": 0.8, "normal_max": 1.2},
      "aptt": {"unit": "seconds", "normal_min": 25, "normal_max": 35},
      "d_dimer": {"unit": "µg/mL FEU", "normal_min": 0, "normal_max": 0.5}
    },
    "urine_analysis": {
      "urine_ph": {"unit": "", "normal_min": 4.5, "normal_max": 8.0},
      "specific_gravity": {
        "unit": "",
        "normal_min": 1.005,
        "normal_max": 1.030
      },
      "urine_wbc": {"unit": "/HPF", "normal_min": 0, "normal_max": 5},
      "microalbumin": {"unit": "mg/L", "normal_min": 0, "normal_max": 30}
    },
    "tumor_markers": {
      "psa_total": {"unit": "ng/mL", "normal_min": 0, "normal_max": 4.0},
      "ca_125": {"unit": "U/mL", "normal_min": 0, "normal_max": 35},
      "afp": {"unit": "ng/mL", "normal_min": 0, "normal_max": 10},
      "cea": {"unit": "ng/mL", "normal_min": 0, "normal_max": 5.0},
      "ca_19_9": {"unit": "U/mL", "normal_min": 0, "normal_max": 37}
    },
    "hormonal_panel": {
      "amh": {"unit": "ng/mL", "normal_min": 1.0, "normal_max": 4.0},
      "fsh": {"unit": "mIU/mL", "normal_min": 1.5, "normal_max": 10.0},
      "lh": {"unit": "mIU/mL", "normal_min": 1.9, "normal_max": 12.5},
      "estradiol": {"unit": "pg/mL", "normal_min": 30.0, "normal_max": 400.0},
      "progesterone": {"unit": "ng/mL", "normal_min": 0.1, "normal_max": 25.0},
      "prolactin": {"unit": "ng/mL", "normal_min": 2.0, "normal_max": 29.0},
      "testosterone_male": {
        "unit": "ng/dL",
        "normal_min": 300,
        "normal_max": 1000
      },
      "testosterone_female": {
        "unit": "ng/dL",
        "normal_min": 15,
        "normal_max": 70
      },
      "dheas": {"unit": "µg/dL", "normal_min": 35.0, "normal_max": 350.0}
    }
  };
}
