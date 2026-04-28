import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GemmaRefineResult {
  final String? text;
  final String? error;
  final bool success;

  GemmaRefineResult.success(this.text)
      : error = null,
        success = true;
  GemmaRefineResult.failure(this.error)
      : text = null,
        success = false;
}

class GemmaService {
  static const String _modelReadyPref = 'gemma_model_ready';
  static const String _enabledPref = 'gemma_enabled';
  static const String _modelFileName = 'gemma-4-E2B-it.litertlm';
  static const String _downloadUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm?download=true';
  static const double modelSizeMB = 2500.0;

  static const MethodChannel _channel = MethodChannel('com.healthcheck.gemma');

  static bool _engineReady = false;

  static bool get isReady => _engineReady;

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledPref) ?? false;
  }

  static Future<void> setEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledPref, val);
  }

  static Future<bool> isModelDownloaded() async {
    final path = await _localModelPath();
    final file = File(path);
    if (await file.exists() && await file.length() > 1000000) {
      return true;
    }
    final downloadPath = '/sdcard/Download/$_modelFileName';
    final downloadFile = File(downloadPath);
    if (await downloadFile.exists() && await downloadFile.length() > 1000000) {
      return true;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_modelReadyPref) ?? false;
  }

  static Future<void> _setModelDownloaded(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_modelReadyPref, val);
  }

  static Future<String> _localModelPath() async {
    final dir = await getExternalStorageDirectory();
    if (dir != null) {
      final modelDir = Directory('${dir.path}/ml_models');
      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }
      return '${modelDir.path}/$_modelFileName';
    }
    final internalDir = await getApplicationDocumentsDirectory();
    return '${internalDir.path}/$_modelFileName';
  }

  static Future<String> getModelPath() async {
    final localPath = await _localModelPath();
    final file = File(localPath);
    if (await file.exists() && await file.length() > 1000000) {
      return localPath;
    }
    final downloadPath = '/sdcard/Download/$_modelFileName';
    final downloadFile = File(downloadPath);
    if (await downloadFile.exists() && await downloadFile.length() > 1000000) {
      return downloadPath;
    }
    return localPath;
  }

  static Future<void> downloadModel({
    required void Function(double progress, int received, int total) onProgress,
    required void Function() onComplete,
    required void Function(String error) onError,
  }) async {
    try {
      final localPath = await _localModelPath();
      final tempPath = '$localPath.tmp';

      final existingTmp = File(tempPath);
      if (await existingTmp.exists()) {
        await existingTmp.delete();
      }

      await Dio().download(
        _downloadUrl,
        tempPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(received / total, received, total);
          } else {
            final approxTotal = (modelSizeMB * 1024 * 1024).toInt();
            final progress = (received / approxTotal).clamp(0.0, 0.99);
            onProgress(progress, received, approxTotal);
          }
        },
      );

      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        final localFile = File(localPath);
        if (await localFile.exists()) {
          await localFile.delete();
        }
        await tempFile.rename(localPath);
      }

      await _setModelDownloaded(true);
      await setEnabled(true);

      final engineOk = await initializeModel();
      if (!engineOk) {
        onError('Model downloaded but AI engine failed to start. Try restarting the app.');
        return;
      }

      onComplete();
    } on DioException catch (e) {
      final tmpFile = File(await _localModelPath().then((p) => '$p.tmp'));
      if (await tmpFile.exists()) {
        await tmpFile.delete();
      }
      onError('Download failed: ${e.message ?? "Network error. Please check your connection and try again."}');
    } catch (e) {
      onError('Download failed: ${e.toString()}');
    }
  }

  static Future<bool> initializeModel() async {
    try {
      final modelPath = await getModelPath();
      final file = File(modelPath);
      if (!await file.exists() || await file.length() < 1000000) {
        _engineReady = false;
        return false;
      }

      final result = await _channel.invokeMethod<bool>('initializeModel', {
        'modelPath': modelPath,
      });

      _engineReady = result ?? false;
      if (_engineReady) {
        await _setModelDownloaded(true);
      }
      return _engineReady;
    } catch (e) {
      _engineReady = false;
      return false;
    }
  }

  static Future<GemmaRefineResult> refineReport(String rawReportText) async {
    if (!_engineReady) {
      final ok = await initializeModel();
      if (!ok) {
        return GemmaRefineResult.failure(
            'AI engine could not start. Try restarting the app or re-downloading the model from Settings.');
      }
    }

    try {
      final prompt = '''You are a friendly medical assistant. Rewrite the following clinical health report in simple, easy-to-understand language for a patient.

Rules:
- Use everyday words, avoid medical jargon
- If you must use a medical term, explain it in brackets
- Be warm and reassuring, not alarming
- Explain what each condition means in simple terms
- Suggest what the patient should do next
- Keep the structure organized with bullet points
- Start with a brief summary of overall health
- End with encouraging next steps

Clinical report to simplify:

$rawReportText

Patient-friendly version:''';

      final result = await _channel.invokeMethod<String>('generateText', {
        'prompt': prompt,
      });

      if (result != null && result.trim().isNotEmpty) {
        return GemmaRefineResult.success(result);
      }
      return GemmaRefineResult.failure('AI returned an empty response. Please try again.');
    } on PlatformException catch (e) {
      _engineReady = false;
      if (e.code == 'NOT_INITIALIZED') {
        return GemmaRefineResult.failure(
            'AI engine is not running. Please restart the app.');
      }
      return GemmaRefineResult.failure(
          'AI error: ${e.message ?? "Unknown error"}. Please try again.');
    } catch (e) {
      _engineReady = false;
      return GemmaRefineResult.failure(
          'Unexpected error. Please try again.');
    }
  }

  static Future<void> deleteModel() async {
    try {
      final localPath = await _localModelPath();
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }
      final tmpFile = File('$localPath.tmp');
      if (await tmpFile.exists()) {
        await tmpFile.delete();
      }
    } catch (_) {}

    try {
      await _channel.invokeMethod<void>('closeModel');
    } catch (_) {}

    _engineReady = false;
    await _setModelDownloaded(false);
  }

  static String buildRawReportText(Map<String, dynamic> reportData) {
    final buffer = StringBuffer();

    final high = reportData['highRiskDiseases'] as List? ?? [];
    final moderate = reportData['moderateRiskDiseases'] as List? ?? [];
    final low = reportData['lowRiskDiseases'] as List? ?? [];
    final abnormals = reportData['abnormalValues'] as List? ?? [];

    if (high.isNotEmpty) {
      buffer.writeln('HIGH RISK CONDITIONS:');
      for (var d in high) {
        final map = d as Map<String, dynamic>;
        buffer.writeln('- ${map['disease']} (ICD: ${map['icdCode']}, Risk: ${map['riskScore']}%)');
        final findings = map['findings'] as List? ?? [];
        for (var f in findings) {
          buffer.writeln('  Finding: $f');
        }
      }
      buffer.writeln();
    }

    if (moderate.isNotEmpty) {
      buffer.writeln('MODERATE RISK CONDITIONS:');
      for (var d in moderate) {
        final map = d as Map<String, dynamic>;
        buffer.writeln('- ${map['disease']} (ICD: ${map['icdCode']}, Risk: ${map['riskScore']}%)');
        final findings = map['findings'] as List? ?? [];
        for (var f in findings) {
          buffer.writeln('  Finding: $f');
        }
      }
      buffer.writeln();
    }

    if (low.isNotEmpty) {
      buffer.writeln('LOW RISK CONDITIONS:');
      for (var d in low) {
        final map = d as Map<String, dynamic>;
        buffer.writeln('- ${map['disease']} (ICD: ${map['icdCode']}, Risk: ${map['riskScore']}%)');
      }
      buffer.writeln();
    }

    if (abnormals.isNotEmpty) {
      buffer.writeln('ABNORMAL VALUES:');
      for (var a in abnormals) {
        buffer.writeln('- $a');
      }
    }

    if (high.isEmpty && moderate.isEmpty && low.isEmpty && abnormals.isEmpty) {
      buffer.writeln('All values appear within normal range. No significant risks detected.');
    }

    return buffer.toString();
  }
}
