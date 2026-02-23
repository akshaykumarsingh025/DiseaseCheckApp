import 'package:dio/dio.dart';

class IcdApiService {
  final Dio _dio = Dio();
  String? _accessToken;
  DateTime? _tokenExpiry;

  static const String _tokenUrl = 'https://icdaccessmanagement.who.int/connect/token';
  static const String _apiBase = 'https://id.who.int/icd';

  // Replace with credentials from WHO ICD API
  static const String _clientId = 'YOUR_CLIENT_ID';
  static const String _clientSecret = 'YOUR_CLIENT_SECRET';

  Future<String> _getToken() async {
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
    _tokenExpiry = DateTime.now().add(Duration(seconds: response.data['expires_in']));
    return _accessToken!;
  }

  Future<List<Map<String, dynamic>>> searchDisease(String query) async {
    try {
      final token = await _getToken();
      final response = await _dio.get(
        '$_apiBase/entity/search',
        queryParameters: {'q': query, 'subtreeFilterUsesFoundationDescendants': false},
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'API-Version': 'v2',
          'Accept-Language': 'en',
        }),
      );

      final results = response.data['destinationEntities'] as List? ?? [];
      return results.map((e) => {
        'title': e['title'] ?? '',
        'theCode': e['theCode'] ?? '',
        'id': e['id'] ?? '',
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
