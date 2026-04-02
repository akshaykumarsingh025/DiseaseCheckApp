import 'dart:developer' as developer;
// import 'package:tflite_flutter/tflite_flutter.dart';

class MLEngine {
  // Interpreter? _diabetesModel;
  bool _modelsLoaded = false;

  bool get isReady => _modelsLoaded;

  /// Load all models (call once at app startup).
  /// Returns true if models loaded successfully.
  Future<bool> loadModels() async {
    try {
      // _diabetesModel = await Interpreter.fromAsset('ml_models/diabetes_predictor.tflite');
      // _modelsLoaded = _diabetesModel != null;

      _modelsLoaded = false; // No models available yet
      developer.log(
        'ML models not available — falling back to rule-based engine only',
        name: 'MLEngine',
      );
      return false;
    } catch (e, s) {
      developer.log('Failed to load ML models',
          error: e, stackTrace: s, name: 'MLEngine');
      _modelsLoaded = false;
      return false;
    }
  }

  /// Predict diabetes probability.
  /// Returns a value between 0.0 and 1.0, or null if the model is not loaded.
  double? predictDiabetes({
    required double bmi,
    required double age,
    required double glucose,
    required double hba1c,
    required double bpSystolic,
    required double insulin,
  }) {
    if (!_modelsLoaded) {
      return null;
    }

    // var input = [[bmi / 50, age / 100, glucose / 300, hba1c / 15, bpSystolic / 200, insulin / 300]];
    // var output = List.filled(1, List.filled(1, 0.0));
    // _diabetesModel!.run(input, output);
    // return output[0][0];

    return null;
  }

  void dispose() {
    // _diabetesModel?.close();
    _modelsLoaded = false;
  }
}
