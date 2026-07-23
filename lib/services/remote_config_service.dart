import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteConfigService {
  static const String _prefsKey = 'remote_config_cache';
  static const int _cacheExpiryHours = 24;

  static Map<String, dynamic> _config = {};
  static bool _loaded = false;

  static Future<void> load() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('api_keys')
          .get();

      if (doc.exists && doc.data() != null) {
        _config = doc.data()!;
        _loaded = true;
        await _saveToCache(_config);
        return;
      }
    } catch (_) {}

    await _loadFromCache();
  }

  static Future<void> _saveToCache(Map<String, dynamic> config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cache = jsonEncode({
        'data': config,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await prefs.setString(_prefsKey, cache);
    } catch (_) {}
  }

  static Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;

      final cache = jsonDecode(raw) as Map<String, dynamic>;
      final timestamp = cache['timestamp'] as int? ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;

      if (age < _cacheExpiryHours * 3600 * 1000) {
        _config = Map<String, dynamic>.from(cache['data'] as Map? ?? {});
        _loaded = true;
      }
    } catch (_) {}
  }

  // Groq config. The API key is loaded at runtime from Firestore
  // `config/api_keys` -> `groq_api_key` and must NEVER be hardcoded here
  // (GitHub secret scanning blocks committed keys, and a committed key is
  // public). We only accept a remote key if it is a real Groq key (prefixed
  // `gsk_`); if none is configured, AI features stay disabled until one is set.
  // The model/base URL keep authoritative non-secret defaults below: a stale
  // value in Firestore must not send a non-Groq key to Groq (which would 401
  // and break AI), so a remote base URL is only accepted if it points at Groq.
  static const String _defaultGroqApiKey = '';
  static const String _defaultGroqModel = 'llama-3.3-70b-versatile';
  static const String _defaultGroqBaseUrl = 'https://api.groq.com/openai/v1';

  /// Generic accessor for any string value in the Firestore `config/api_keys`
  /// doc. Returns null when the key is missing or not a non-empty string.
  static String? getString(String key) {
    final value = _config[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static String get openRouterApiKey {
    final configured = _config['groq_api_key'] as String?;
    if (configured != null && configured.startsWith('gsk_')) {
      return configured;
    }
    return _defaultGroqApiKey;
  }

  static String get openRouterModel {
    final configured = _config['groq_model'] as String?;
    if (configured != null && configured.trim().isNotEmpty) {
      return configured;
    }
    return _defaultGroqModel;
  }

  static String get openRouterBaseUrl {
    final configured = _config['groq_base_url'] as String?;
    if (configured != null && configured.contains('groq.com')) {
      return configured;
    }
    return _defaultGroqBaseUrl;
  }

  // ── Ollama (first-priority online provider) ────────────────────────────
  // Ollama is tried before Groq. It is only used when both a base URL and a
  // model are configured (either in the Firestore config doc or via the
  // hardcoded defaults below). Leave the defaults blank to disable Ollama and
  // fall straight through to Groq.
  static const String _defaultOllamaBaseUrl = '';
  static const String _defaultOllamaApiKey = '';
  static const String _defaultOllamaModel = '';

  static String get ollamaBaseUrl {
    final configured = _config['ollama_base_url'] as String?;
    if (configured != null && configured.trim().isNotEmpty) {
      return configured.trim();
    }
    return _defaultOllamaBaseUrl;
  }

  static String get ollamaApiKey {
    final configured = _config['ollama_api_key'] as String?;
    if (configured != null && configured.trim().isNotEmpty) {
      return configured.trim();
    }
    return _defaultOllamaApiKey;
  }

  static String get ollamaModel {
    final configured = _config['ollama_model'] as String?;
    if (configured != null && configured.trim().isNotEmpty) {
      return configured.trim();
    }
    return _defaultOllamaModel;
  }

  /// Ollama is only usable when it has both an endpoint and a model.
  static bool get isOllamaConfigured =>
      ollamaBaseUrl.isNotEmpty && ollamaModel.isNotEmpty;

  static String get razorpayKeyId =>
      _config['razorpay_key_id'] as String? ?? '';

  // ── Ads (AdMob) ────────────────────────────────────────────────────────
  // Remote kill-switch: set `ads_enabled: false` in the Firestore config doc
  // to turn off all ads without shipping a release. Defaults to enabled.
  static bool get adsEnabled => _config['ads_enabled'] as bool? ?? true;

  // Ad unit IDs. Defaults are Google's official TEST unit IDs — replace with
  // your production unit IDs (via config doc or these defaults) before launch.
  static String get admobInterstitialId =>
      _config['admob_interstitial_id'] as String? ??
      'ca-app-pub-7777713890124852/8971862214';

  static String get admobBannerId =>
      _config['admob_banner_id'] as String? ??
      'ca-app-pub-7777713890124852/8971862214';

  static String get doctorUserId =>
      _config['doctor_user_id'] as String? ?? '';

  static bool get isLoaded => _loaded;
}
