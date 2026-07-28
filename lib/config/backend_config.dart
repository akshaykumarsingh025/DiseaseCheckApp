import '../services/remote_config_service.dart';

/// Base URL of the Cloudflare Worker that holds the LiveKit and Groq keys.
///
/// This is a public endpoint URL, not a secret — it is safe in source. The
/// secrets themselves live in Cloudflare Worker secrets (see `worker/README.md`)
/// and never reach the device.
///
/// Firebase Auth and Firestore are unaffected and stay on the free Spark plan.
class BackendConfig {
  const BackendConfig._();

  /// Replace with the URL `wrangler deploy` prints, e.g.
  /// `https://diseasecheck-api.your-subdomain.workers.dev`.
  ///
  /// Can be overridden at runtime via Firestore `config/api_keys` →
  /// `backend_base_url`, so the endpoint can move without an app release.
  static const String _defaultBaseUrl =
      'https://diseasecheck-api.akshay-dev.workers.dev';

  static String get baseUrl {
    final configured = RemoteConfigService.getString('backend_base_url');
    if (configured != null && configured.startsWith('https://')) {
      return _stripTrailingSlash(configured);
    }
    return _stripTrailingSlash(_defaultBaseUrl);
  }

  /// True once a real Worker URL has been set (i.e. the placeholder above was
  /// replaced or a remote override is present).
  static bool get isConfigured => !baseUrl.contains('YOUR-SUBDOMAIN');

  static String get liveKitTokenUrl => '$baseUrl/livekit/token';

  static String get groqChatUrl => '$baseUrl/groq/chat/completions';

  static String _stripTrailingSlash(String url) {
    var result = url.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
