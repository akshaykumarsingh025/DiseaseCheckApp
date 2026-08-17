import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  // Groq config. The API key is NOT here and is never sent to the device — it
  // lives in Cloudflare Worker secrets, and the app reaches Groq through the
  // Worker proxy (see `worker/README.md` and `lib/config/backend_config.dart`).
  //
  // Only the model name remains client-side, because it is not a secret. The
  // Worker independently validates it against its own allowlist, so a bad
  // value in Firestore can cause a 400 but cannot redirect our Groq quota.
  static const String _defaultGroqModel = 'llama-3.3-70b-versatile';

  /// Generic accessor for any string value in the Firestore `config/api_keys`
  /// doc. Returns null when the key is missing or not a non-empty string.
  static String? getString(String key) {
    final value = _config[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static String get openRouterModel {
    final configured = _config['groq_model'] as String?;
    if (configured != null && configured.trim().isNotEmpty) {
      return configured;
    }
    return _defaultGroqModel;
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

  // ── Razorpay ───────────────────────────────────────────────────────────
  // Intentionally absent. The app no longer picks the Razorpay key at all:
  // /razorpay/order returns the Key ID alongside the order it created, so the
  // key and the order can never disagree, and switching from the test key to
  // the live key is a Worker secret change with no app release involved.
  //   cd worker && npx wrangler secret put RAZORPAY_KEY_ID

  // ── Ads (AdMob) ────────────────────────────────────────────────────────
  // Remote kill-switch: set `ads_enabled: false` in the Firestore config doc
  // to turn off all ads without shipping a release. Defaults to enabled.
  static bool get adsEnabled => _config['ads_enabled'] as bool? ?? true;

  // Google's official sample ad units. They fill on any device, need no AdMob
  // account, and are the ONLY safe units to develop against: tapping your own
  // live ads is invalid traffic and gets the AdMob account suspended.
  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';

  // Production units, used in release builds when the Firestore config doc has
  // no override. Both can be swapped without a rebuild via `admob_banner_id` /
  // `admob_interstitial_id` on the `config/api_keys` doc.
  //
  // ⚠ Until recently both of these were 8971862214 — one unit cannot serve two
  // formats, so whichever format it is not was silently no-filling.
  static const String _prodBannerId = 'ca-app-pub-7777713890124852/8971862214';
  static const String _prodInterstitialId =
      'ca-app-pub-7777713890124852/1363880642';

  static String get admobBannerId =>
      _adUnitId('admob_banner_id', testBannerId, _prodBannerId);

  static String get admobInterstitialId =>
      _adUnitId('admob_interstitial_id', testInterstitialId, _prodInterstitialId);

  /// Debug builds ALWAYS serve Google's sample ads, whatever the config doc
  /// says. That keeps a developer or tester from ever generating a real
  /// impression — or worse, a real click — on the production units.
  static String _adUnitId(String key, String testId, String prodId) {
    if (kDebugMode) return testId;
    final configured = _config[key] as String?;
    if (configured != null && configured.trim().isNotEmpty) {
      return configured.trim();
    }
    return prodId;
  }

  /// Device IDs that should receive test ads even in a release build. Set
  /// `admob_test_device_ids` on the config doc to a list of strings.
  static List<String> get admobTestDeviceIds {
    final raw = _config['admob_test_device_ids'];
    if (raw is List) {
      return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  static String get doctorUserId =>
      _config['doctor_user_id'] as String? ?? '';

  static bool get isLoaded => _loaded;
}
