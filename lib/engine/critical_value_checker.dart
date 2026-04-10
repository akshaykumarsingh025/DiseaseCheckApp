import 'package:flutter/material.dart';

class CriticalValue {
  final String key;
  final String label;
  final double value;
  final String unit;
  final String message;

  const CriticalValue({
    required this.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.message,
  });
}

class CriticalValueChecker {
  static const Map<String, Map<String, dynamic>> _criticalThresholds = {
    'systolic': {
      'high': 180,
      'message':
          'Seek immediate medical attention! BP ≥180/120 is a hypertensive crisis.'
    },
    'diastolic': {
      'high': 120,
      'message':
          'Seek immediate medical attention! Diastolic BP ≥120 is a hypertensive crisis.'
    },
    'fasting_glucose': {
      'high': 500,
      'message':
          'CRITICAL: Blood glucose >500 mg/dL — risk of hyperosmolar hyperglycemic state. Seek emergency care.'
    },
    'random_glucose': {
      'high': 500,
      'message':
          'CRITICAL: Blood glucose >500 mg/dL — risk of hyperosmolar hyperglycemic state. Seek emergency care.'
    },
    'spo2': {
      'low': 90,
      'message':
          'CRITICAL: SpO2 <90% — severe hypoxia. Call emergency services immediately.'
    },
    'heart_rate': {
      'low': 40,
      'high': 150,
      'message':
          'CRITICAL: Heart rate is dangerously abnormal. Seek emergency care.'
    },
    'hemoglobin': {
      'low': 7,
      'message':
          'CRITICAL: Hemoglobin <7 g/dL — severe anemia. May require blood transfusion.'
    },
    'creatinine': {
      'high': 4.0,
      'message':
          'CRITICAL: Creatinine >4.0 mg/dL — possible acute kidney injury. Seek urgent care.'
    },
    'egfr': {
      'low': 15,
      'message':
          'CRITICAL: eGFR <15 — kidney failure. Requires immediate medical attention.'
    },
    'troponin_i': {
      'high': 1.0,
      'message':
          'CRITICAL: Troponin significantly elevated — possible acute myocardial infarction. Call emergency services.'
    },
    'troponin_t': {
      'high': 0.5,
      'message':
          'CRITICAL: Troponin T significantly elevated — possible heart attack. Call emergency services.'
    },
    'potassium': {
      'low': 2.5,
      'high': 6.5,
      'message':
          'CRITICAL: Potassium level is life-threatening. Seek emergency care immediately.'
    },
    'sodium': {
      'low': 120,
      'high': 160,
      'message':
          'CRITICAL: Sodium level is dangerously abnormal. Seek emergency care.'
    },
    'platelet_count': {
      'low': 50000,
      'message':
          'CRITICAL: Platelets <50,000 — severe thrombocytopenia, bleeding risk.'
    },
    'wbc_count': {
      'low': 1000,
      'message':
          'CRITICAL: WBC <1,000 — severe leukopenia, high infection risk. Seek urgent care.'
    },
  };

  static List<CriticalValue> checkValues(Map<String, double> values) {
    List<CriticalValue> alerts = [];

    for (var entry in values.entries) {
      final key = entry.key;
      final value = entry.value;
      final threshold = _criticalThresholds[key];
      if (threshold == null) continue;

      String? message;
      if (threshold.containsKey('high') &&
          value >= (threshold['high'] as num).toDouble()) {
        message = threshold['message'] as String;
      } else if (threshold.containsKey('low') &&
          value <= (threshold['low'] as num).toDouble()) {
        message = threshold['message'] as String;
      }

      if (message != null) {
        alerts.add(CriticalValue(
          key: key,
          label: _getLabel(key),
          value: value,
          unit: _getUnit(key),
          message: message,
        ));
      }
    }

    return alerts;
  }

  static String _getLabel(String key) {
    const labels = {
      'systolic': 'Systolic BP',
      'diastolic': 'Diastolic BP',
      'fasting_glucose': 'Fasting Glucose',
      'random_glucose': 'Random Glucose',
      'spo2': 'SpO2',
      'heart_rate': 'Heart Rate',
      'hemoglobin': 'Hemoglobin',
      'creatinine': 'Creatinine',
      'egfr': 'eGFR',
      'troponin_i': 'Troponin I',
      'troponin_t': 'Troponin T',
      'potassium': 'Potassium',
      'sodium': 'Sodium',
      'platelet_count': 'Platelet Count',
      'wbc_count': 'WBC Count',
    };
    return labels[key] ?? key;
  }

  static String _getUnit(String key) {
    const units = {
      'systolic': 'mmHg',
      'diastolic': 'mmHg',
      'fasting_glucose': 'mg/dL',
      'random_glucose': 'mg/dL',
      'spo2': '%',
      'heart_rate': 'bpm',
      'hemoglobin': 'g/dL',
      'creatinine': 'mg/dL',
      'egfr': 'mL/min/1.73m²',
      'troponin_i': 'ng/mL',
      'troponin_t': 'ng/mL',
      'potassium': 'mEq/L',
      'sodium': 'mEq/L',
      'platelet_count': '/µL',
      'wbc_count': 'cells/µL',
    };
    return units[key] ?? '';
  }

  static void showCriticalAlert(
      BuildContext context, List<CriticalValue> alerts) {
    if (alerts.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.red, width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.emergency, color: Colors.red.shade700, size: 32),
            const SizedBox(width: 12),
            Text('Critical Values Detected!',
                style: TextStyle(color: Colors.red.shade900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: alerts
              .map((alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${alert.label}: ${alert.value} ${alert.unit}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(alert.message,
                            style: TextStyle(
                                color: Colors.red.shade800, fontSize: 14)),
                      ],
                    ),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }
}
