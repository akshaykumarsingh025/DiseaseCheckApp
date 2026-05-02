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
  static const String _langPref = 'gemma_language';
  static const String _modelFileName = 'gemma-4-E2B-it.litertlm';
  static const String _downloadUrl =
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm?download=true';
  static const double modelSizeMB = 2500.0;

  static const MethodChannel _channel = MethodChannel('com.healthcheck.gemma');

  static bool _engineReady = false;
  static bool _cancelled = false;

  static bool get isReady => _engineReady;

  static void cancelGeneration() {
    _cancelled = true;
    _engineReady = false;
    try {
      _channel.invokeMethod<void>('closeModel');
    } catch (_) {}
  }

  static Future<void> reinitializeIfReady() async {
    if (await isModelDownloaded()) {
      await initializeModel();
    }
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledPref) ?? false;
  }

  static Future<void> setEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledPref, val);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_langPref) ?? 'english';
  }

  static Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langPref, lang);
  }

  static String getLanguageLabel(String code) {
    switch (code) {
      case 'hindi':
        return 'हिन्दी (Hindi)';
      case 'hinglish':
        return 'Hinglish';
      default:
        return 'English';
    }
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
      await _channel.invokeMethod('startForegroundDownload');

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
            final pct = (received / total * 100).toInt();
            final receivedMB = (received / (1024 * 1024)).toStringAsFixed(0);
            final totalMB = (total / (1024 * 1024)).toStringAsFixed(0);
            _updateForegroundProgress(pct, '$receivedMB / $totalMB MB');
          } else {
            final approxTotal = (modelSizeMB * 1024 * 1024).toInt();
            final progress = (received / approxTotal).clamp(0.0, 0.99);
            onProgress(progress, received, approxTotal);
            final receivedMB = (received / (1024 * 1024)).toStringAsFixed(0);
            _updateForegroundProgress((progress * 100).toInt(), '$receivedMB MB / ~2,500 MB');
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
    } finally {
      try {
        await _channel.invokeMethod('stopForegroundDownload');
      } catch (_) {}
    }
  }

  static void _updateForegroundProgress(int progress, String text) {
    try {
      _channel.invokeMethod('updateForegroundProgress', {
        'progress': progress,
        'text': text,
      });
    } catch (_) {}
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

  static Future<GemmaRefineResult> refineReport(String rawReportText, {String language = 'english'}) async {
    if (_cancelled) {
      _cancelled = false;
      return GemmaRefineResult.failure('Generation cancelled.');
    }

    if (!_engineReady) {
      final ok = await initializeModel();
      if (!ok) {
        return GemmaRefineResult.failure(
            'AI engine could not start. Try restarting the app or re-downloading the model from Settings.');
      }
    }

    String langInstruction;
    String closingLine;

    switch (language) {
      case 'hindi':
        langInstruction = '''पूरी रिपोर्ट शुद्ध हिन्दी (देवनागरी लिपि) में लिखें। आम बोलचाल की हिन्दी का इस्तेमाल करें ताकि मरीज आसानी से समझ सके। मेडिकल शब्दों के साथ ब्रैकेट में हिन्दी अर्थ जरूर दें। उदाहरण: "आपका फास्टिंग ब्लड शुगर (खाली पेट शर्करा) 250 mg/dL है, जो सामान्य (70-100) से बहुत ज्यादा है।"''';
        closingLine = 'कृपया अपने डॉक्टर से अभी मिलें। यह रिपोर्ट केवल जानकारी के लिए है, चिकित्सा निदान नहीं है।';
        break;
      case 'hinglish':
        langInstruction = '''Write the ENTIRE response in Hinglish — Hindi words written in English script, the way Indians naturally speak. Example: "Aapka fasting blood sugar 250 mg/dL hai, jo normal range (70-100) se bahut zyada hai. Iska matlab hai ki aapko diabetes ho sakta hai." Medical terms can stay in English but explain them in Hinglish. Example: "Creatinine (kidey ka ek test) 2.5 hai, normal 0.6-1.2 hota hai."''';
        closingLine = 'Please apne doctor se abhi milein. Yeh report sirf jaankari ke liye hai, medical diagnosis nahi hai.';
        break;
      default:
        langInstruction = '''Write the ENTIRE response in simple, clear English. Use short sentences and everyday words that anyone can understand. If you use a medical term, explain it in brackets right after. Example: "Your fasting blood sugar is 250 mg/dL (normal is 70-100 mg/dL), which is very high."''';
        closingLine = 'Please consult your doctor now for proper diagnosis and treatment. This report is for awareness only, not a medical diagnosis.';
    }

    try {
      final prompt = '''You are a caring, thorough medical assistant explaining a patient's health report to them. $langInstruction

You MUST follow this exact structure for the report:

---

**Overall Health Summary** (2-3 sentences about how their health looks overall)

---

Then for EACH disease or risk condition found, create a section with these 5 parts:

**[Disease Name]**

1. **What was found**: Say the condition name in simple words. (1-2 sentences)

2. **Which values are abnormal**: List EVERY abnormal test value that points to this disease. Show the actual value vs the normal range. Examples:
   - "Fasting Blood Sugar: 250 mg/dL (normal: 70-100 mg/dL) — VERY HIGH"
   - "Platelets: 80,000 (normal: 1,50,000-4,00,000) — LOW"
   - "HbA1c: 9.2% (normal: below 5.7%) — VERY HIGH"

3. **How these values connect to this disease**: Explain the medical logic simply. Example: "When blood sugar stays above 200 for a long time, it starts damaging the small blood vessels in your kidneys. That is why your creatinine is also rising — your kidneys are not filtering waste properly anymore."

4. **What this means for your daily life**: How this could affect the patient's day-to-day life. Be honest but not scary.

5. **What you should do**: Clear, specific next steps. Include lifestyle tips AND medical advice.

---

**Abnormal Values Summary**: A quick table or list of ALL values that are outside normal range, with their actual value and normal range side by side.

---

**IMPORTANT**: $closingLine

---

Clinical data from the patient's report:

$rawReportText

Now write the patient-friendly report:''';

      final result = await _channel.invokeMethod<String>('generateText', {
        'prompt': prompt,
      });

      if (_cancelled) {
        _cancelled = false;
        return GemmaRefineResult.failure('Generation cancelled.');
      }

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
