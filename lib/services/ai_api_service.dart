import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'remote_config_service.dart';

enum AiApiSource { openRouter, localModel, none }

enum AiMode { online, local, auto }

class AiApiResult {
  final String? text;
  final String? error;
  final bool success;
  final AiApiSource source;
  final bool wasTruncated;

  AiApiResult.success(this.text, {this.source = AiApiSource.none, this.wasTruncated = false})
      : error = null,
        success = true;
  AiApiResult.failure(this.error, {this.source = AiApiSource.none})
      : text = null,
        success = false,
        wasTruncated = false;
}

class AiApiService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 180),
    sendTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  static bool _localEngineReady = false;
  static const MethodChannel _channel = MethodChannel('com.healthcheck.gemma');
  static const String _aiModePref = 'ai_mode';

  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 3);
  static const int _maxTokens = 8192;

  static Future<AiMode> getAiMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_aiModePref) ?? 'online';
    switch (mode) {
      case 'local':
        return AiMode.local;
      case 'auto':
        return AiMode.auto;
      default:
        return AiMode.online;
    }
  }

  static Future<void> setAiMode(AiMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String modeStr;
    switch (mode) {
      case AiMode.local:
        modeStr = 'local';
        break;
      case AiMode.auto:
        modeStr = 'auto';
        break;
      case AiMode.online:
        modeStr = 'online';
        break;
    }
    await prefs.setString(_aiModePref, modeStr);
  }

  static Future<bool> isLocalModelAvailable() async {
    try {
      final path = await _getLocalModelPath();
      final file = File(path);
      if (await file.exists() && await file.length() > 1000000) {
        return true;
      }
      const downloadPath = '/sdcard/Download/gemma-4-E2B-it.litertlm';
      final downloadFile = File(downloadPath);
      if (await downloadFile.exists() && await downloadFile.length() > 1000000) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<AiApiResult> generateText(
    String prompt, {
    String language = 'english',
  }) async {
    final mode = await getAiMode();

    switch (mode) {
      case AiMode.online:
        return _generateOnline(prompt);
      case AiMode.local:
        return _generateLocal(prompt);
      case AiMode.auto:
        final onlineResult = await _generateOnline(prompt);
        if (onlineResult.success) return onlineResult;
        return _generateLocal(prompt);
    }
  }

  static Future<AiApiResult> _generateOnline(String prompt) async {
    // Priority 1: Ollama (only when configured). If it succeeds we return it;
    // otherwise we silently fall through to Groq.
    if (RemoteConfigService.isOllamaConfigured) {
      final ollama = await _callWithRetry(() => _callOllama(prompt));
      if (ollama.success) {
        if (ollama.wasTruncated && ollama.text != null) {
          return _continueTruncated(ollama.text!, AiApiSource.openRouter);
        }
        return ollama;
      }
    }

    // Priority 2: Groq (OpenAI-compatible endpoint).
    var result = await _callWithRetry(() => _callOpenRouter(prompt));
    if (result.success) {
      if (result.wasTruncated && result.text != null) {
        result = await _continueTruncated(result.text!, AiApiSource.openRouter);
      }
      return result;
    }

    // Priority 3: on-device Gemma, if the model is downloaded.
    final localAvailable = await isLocalModelAvailable();
    if (localAvailable) {
      final localResult = await _callLocalModel(prompt);
      if (localResult.success) return localResult;
    }

    return AiApiResult.failure(
      result.error ?? 'Could not generate AI content. Please check your internet connection.',
      source: result.source,
    );
  }

  static Future<AiApiResult> _generateLocal(String prompt) async {
    final localResult = await _callLocalModel(prompt);
    if (localResult.success) return localResult;

    if (localResult.error?.contains('not downloaded') == true) {
      return AiApiResult.failure(
        'Local AI model not downloaded. Please switch to Online AI mode or download the model.',
        source: AiApiSource.localModel,
      );
    }

    // Fall back to online providers (Ollama first, then Groq).
    if (RemoteConfigService.isOllamaConfigured) {
      final ollama = await _callWithRetry(() => _callOllama(prompt));
      if (ollama.success) {
        if (ollama.wasTruncated && ollama.text != null) {
          return _continueTruncated(ollama.text!, AiApiSource.openRouter);
        }
        return ollama;
      }
    }

    final orResult = await _callWithRetry(() => _callOpenRouter(prompt));
    if (orResult.success) {
      if (orResult.wasTruncated && orResult.text != null) {
        return await _continueTruncated(orResult.text!, AiApiSource.openRouter);
      }
      return orResult;
    }

    return AiApiResult.failure(
      localResult.error ?? 'Local AI failed. Please switch to Online AI mode.',
      source: AiApiSource.localModel,
    );
  }

  static Future<AiApiResult> _callWithRetry(
    Future<AiApiResult> Function() apiCall,
  ) async {
    AiApiResult lastResult = AiApiResult.failure('Not attempted');

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      lastResult = await apiCall();

      if (lastResult.success) return lastResult;

      if (!_isRetryableError(lastResult.error)) break;

      if (attempt < _maxRetries - 1) {
        final delay = _baseRetryDelay * (1 << attempt);
        await Future.delayed(delay);
      }
    }

    return lastResult;
  }

  static Future<AiApiResult> _continueTruncated(
    String existingText,
    AiApiSource source,
  ) async {
    if (_looksComplete(existingText)) {
      return AiApiResult.success(existingText, source: source, wasTruncated: false);
    }

    final continuationPrompt =
        'Continue EXACTLY from where you left off. Do NOT repeat anything. Just continue:\n\n'
        '${existingText.length > 2000 ? existingText.substring(existingText.length - 2000) : existingText}\n\n'
        'CONTINUE FROM HERE:';

    final continuation = await _callOpenRouter(continuationPrompt);

    if (continuation.success && continuation.text != null) {
      return AiApiResult.success(
        '$existingText\n${continuation.text}',
        source: source,
        wasTruncated: continuation.wasTruncated,
      );
    }

    return AiApiResult.success(existingText, source: source, wasTruncated: true);
  }

  static Future<AiApiResult> _callOllama(String prompt) async {
    try {
      final baseUrl = RemoteConfigService.ollamaBaseUrl;
      final apiKey = RemoteConfigService.ollamaApiKey;

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (apiKey.isNotEmpty) {
        headers['Authorization'] = 'Bearer $apiKey';
      }

      // Ollama exposes an OpenAI-compatible endpoint at
      // `{baseUrl}/chat/completions` (e.g. base `https://ollama.com/v1`), so we
      // reuse the same request/response shape as Groq.
      final response = await _dio.post(
        '$baseUrl/chat/completions',
        options: Options(headers: headers),
        data: {
          'model': RemoteConfigService.ollamaModel,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': _maxTokens,
          'stream': false,
        },
      );

      return _parseResponse(response, AiApiSource.openRouter);
    } on DioException catch (e) {
      return AiApiResult.failure(_dioErrorToMessage(e), source: AiApiSource.openRouter);
    } catch (e) {
      return AiApiResult.failure('Ollama service error: $e', source: AiApiSource.openRouter);
    }
  }

  static Future<AiApiResult> _callOpenRouter(String prompt) async {
    try {
      final baseUrl = RemoteConfigService.openRouterBaseUrl;
      final isGroq = baseUrl.contains('groq.com');

      final headers = <String, String>{
        'Authorization': 'Bearer ${RemoteConfigService.openRouterApiKey}',
        'Content-Type': 'application/json',
      };
      if (!isGroq) {
        headers['HTTP-Referer'] = 'https://diseasecheck.app';
        headers['X-Title'] = 'DiseaseCheck App';
      }

      final response = await _dio.post(
        '$baseUrl/chat/completions',
        options: Options(headers: headers),
        data: {
          'model': RemoteConfigService.openRouterModel,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': isGroq ? 8192 : _maxTokens,
        },
      );

      return _parseResponse(response, AiApiSource.openRouter);
    } on DioException catch (e) {
      return AiApiResult.failure(_dioErrorToMessage(e), source: AiApiSource.openRouter);
    } catch (e) {
      return AiApiResult.failure('AI service error: $e', source: AiApiSource.openRouter);
    }
  }

  static AiApiResult _parseResponse(Response response, AiApiSource source) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        final json = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
        final choices = json['choices'];
        if (choices is List && choices.isNotEmpty) {
          final choice = choices[0];
          if (choice is Map) {
            final message = choice['message'];
            final finishReason = choice['finish_reason'];

            if (message is Map) {
              var content = message['content'];
              if (content is String && content.trim().isNotEmpty) {
                final wasTruncated = finishReason != null &&
                    finishReason != 'stop' &&
                    finishReason != 'end_turn';

                return AiApiResult.success(
                  content.trim(),
                  source: source,
                  wasTruncated: wasTruncated,
                );
              }
            }
          }
        }
      } catch (e) {
        return AiApiResult.failure('Failed to parse AI response: $e', source: source);
      }
      return AiApiResult.failure('AI returned empty response. Please try again.', source: source);
    }

    if (response.statusCode == 429) {
      return AiApiResult.failure('AI service is busy (rate limited). Retrying...', source: source);
    }

    if (response.statusCode == 402 || response.statusCode == 403) {
      return AiApiResult.failure('AI service quota reached. Please try Local AI mode.', source: source);
    }

    if (response.statusCode == 503 || response.statusCode == 502) {
      return AiApiResult.failure('AI service temporarily unavailable. Retrying...', source: source);
    }

    return AiApiResult.failure(
      'AI service error (${response.statusCode}). Please try again.',
      source: source,
    );
  }

  static String _dioErrorToMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return 'AI service connection timed out. Retrying...';
      case DioExceptionType.receiveTimeout:
        return 'AI service took too long to respond. Retrying...';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 429) {
          return 'AI service is busy (rate limited). Retrying...';
        }
        if (statusCode == 402 || statusCode == 403) {
          return 'AI service quota reached. Please try Local AI mode.';
        }
        if (statusCode == 502 || statusCode == 503) {
          return 'AI service temporarily unavailable. Retrying...';
        }
        final detail = _extractApiError(e.response?.data);
        return 'AI service error ($statusCode): $detail';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badCertificate:
        return 'SSL certificate error. Please check your device date/time.';
      default:
        return 'Connection error: ${e.message ?? e.toString()}';
    }
  }

  static Future<AiApiResult> _callLocalModel(String prompt) async {
    try {
      if (!_localEngineReady) {
        final modelPath = await _getLocalModelPath();
        final file = File(modelPath);
        if (!await file.exists() || await file.length() < 1000000) {
          return AiApiResult.failure('Local model not downloaded', source: AiApiSource.localModel);
        }

        final initResult = await _channel.invokeMethod<bool>('initializeModel', {
          'modelPath': modelPath,
        });
        _localEngineReady = initResult ?? false;
        if (!_localEngineReady) {
          return AiApiResult.failure('Could not initialize local model.', source: AiApiSource.localModel);
        }
      }

      final result = await _channel.invokeMethod<String>('generateText', {
        'prompt': prompt,
      });

      if (result != null && result.trim().isNotEmpty) {
        return AiApiResult.success(result.trim(), source: AiApiSource.localModel);
      }
      return AiApiResult.failure('Local model returned empty response', source: AiApiSource.localModel);
    } on PlatformException catch (e) {
      _localEngineReady = false;
      return AiApiResult.failure('Local model error: ${e.message}', source: AiApiSource.localModel);
    } catch (e) {
      _localEngineReady = false;
      return AiApiResult.failure('Local model error', source: AiApiSource.localModel);
    }
  }

  static Future<String> _getLocalModelPath() async {
    final dir = await getExternalStorageDirectory();
    if (dir != null) {
      return '${dir.path}/ml_models/gemma-4-E2B-it.litertlm';
    }
    final internalDir = await getApplicationDocumentsDirectory();
    return '${internalDir.path}/gemma-4-E2B-it.litertlm';
  }

  static bool _isRetryableError(String? error) {
    if (error == null) return false;
    final lower = error.toLowerCase();
    return lower.contains('rate limit') ||
        lower.contains('429') ||
        lower.contains('busy') ||
        lower.contains('retrying') ||
        lower.contains('timed out') ||
        lower.contains('timeout') ||
        lower.contains('temporarily unavailable') ||
        lower.contains('503') ||
        lower.contains('502') ||
        lower.contains('overloaded');
  }

  static bool _looksComplete(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    if (trimmed.endsWith('.') ||
        trimmed.endsWith('!') ||
        trimmed.endsWith('"') ||
        trimmed.endsWith('*') ||
        trimmed.endsWith('---') ||
        trimmed.endsWith('```') ||
        trimmed.endsWith(':)')) {
      return true;
    }

    if (trimmed.length > 1500) {
      final sectionCount = RegExp(r'\*\*[^*]+\*\*').allMatches(trimmed).length;
      if (sectionCount >= 3) return true;
    }

    return false;
  }

  static String getSourceLabel(AiApiSource source) {
    switch (source) {
      case AiApiSource.openRouter:
        return 'Online AI';
      case AiApiSource.localModel:
        return 'Local AI';
      case AiApiSource.none:
        return 'AI';
    }
  }

  static String _extractApiError(dynamic body) {
    try {
      if (body is Map<String, dynamic>) {
        final err = body['error'];
        if (err is Map && err['message'] is String) return err['message'] as String;
        if (err is String) return err;
        final msg = body['message'];
        if (msg is String) return msg;
      }
      if (body is String) {
        final cleaned = body.replaceAll(RegExp(r'\s+'), ' ').trim();
        return cleaned.substring(0, cleaned.length.clamp(0, 120));
      }
    } catch (_) {}
    return 'unknown error';
  }
}
