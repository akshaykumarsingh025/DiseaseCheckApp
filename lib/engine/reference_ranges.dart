class ReferenceRanges {
  static Map<String, dynamic> _ranges = {};

  /// Loads reference ranges from a JSON string or asset.
  /// For simplicity, we define the ranges directly here as a fallback or
  /// load them synchronously during app startup via another mechanism.
  static Future<void> loadRanges() async {
    try {
      // In a real app we'd load this from an asset
      // String jsonString = await rootBundle.loadString('assets/data/reference_ranges.json');
      // _ranges = jsonDecode(jsonString);

      // Since it's currently in lib/data we'll hardcode the fallback for immediate sync access.
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
    return false; // Safely ignore unknown fields
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
      "hdl": {"unit": "mg/dL", "normal_min": 60, "normal_max": 150},
      "triglycerides": {"unit": "mg/dL", "normal_min": 0, "normal_max": 149}
    },
    "vitals": {
      "systolic_bp": {"unit": "mmHg", "normal_min": 90, "normal_max": 119},
      "diastolic_bp": {"unit": "mmHg", "normal_min": 60, "normal_max": 79},
      "heart_rate": {"unit": "bpm", "normal_min": 60, "normal_max": 100}
    },
    "kidney_function": {
      "egfr": {"unit": "mL/min/1.73m²", "normal_min": 90, "normal_max": 150},
      "creatinine": {"unit": "mg/dL", "normal_min": 0.6, "normal_max": 1.2}
    },
    "liver_function": {
      "alt": {"unit": "U/L", "normal_min": 7, "normal_max": 56},
      "ast": {"unit": "U/L", "normal_min": 10, "normal_max": 40}
    }
  };
}
