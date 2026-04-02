import 'dart:developer' as developer;
import 'package:dio/dio.dart';

class IcdApiService {
  IcdApiService({Dio? dio, String? clientId, String? clientSecret})
      : _dio = dio ?? Dio(),
        _clientId = clientId ??
            const String.fromEnvironment('WHO_ICD_CLIENT_ID'),
        _clientSecret = clientSecret ??
            const String.fromEnvironment('WHO_ICD_CLIENT_SECRET');

  final Dio _dio;
  final String _clientId;
  final String _clientSecret;
  String? _accessToken;
  DateTime? _tokenExpiry;

  static const String _tokenUrl =
      'https://icdaccessmanagement.who.int/connect/token';
  static const String _apiBase = 'https://id.who.int/icd';

  bool get isConfigured =>
      _clientId.isNotEmpty && _clientSecret.isNotEmpty;

  Future<String> _getToken() async {
    if (!isConfigured) {
      throw StateError(
          'WHO ICD API credentials not configured. '
          'Pass --dart-define=WHO_ICD_CLIENT_ID=<id> --dart-define=WHO_ICD_CLIENT_SECRET=<secret> at build time.',
      );
    }

    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    final response = await _dio.post(
      _tokenUrl,
      data: {
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'grant_type': 'client_credentials',
        'scope': 'icdapi_access',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    _accessToken = response.data['access_token'];
    _tokenExpiry =
        DateTime.now().add(Duration(seconds: response.data['expires_in']));
    return _accessToken!;
  }

  Future<List<Map<String, dynamic>>> searchDisease(String query) async {
    try {
      final token = await _getToken();
      final response = await _dio.get(
        '$_apiBase/entity/search',
        queryParameters: {
          'q': query,
          'subtreeFilterUsesFoundationDescendants': false
        },
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'API-Version': 'v2',
          'Accept-Language': 'en',
        }),
      );

      final results = response.data['destinationEntities'] as List? ?? [];
      return results
          .map((e) => {
                'title': e['title'] ?? '',
                'theCode': e['theCode'] ?? '',
                'id': e['id'] ?? '',
              })
          .toList();
    } on StateError {
      rethrow;
    } catch (e, s) {
      developer.log('ICD API search failed for "$query"',
          error: e, stackTrace: s, name: 'IcdApiService');
      return [];
    }
  }
}
