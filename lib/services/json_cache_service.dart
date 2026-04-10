import 'dart:convert';
import 'package:flutter/services.dart';

class JsonCacheService {
  static final Map<String, dynamic> _cache = {};
  static bool _initialized = false;

  static Map<String, dynamic> get diseases => _cache['diseases'] ?? {};
  static Map<String, dynamic> get referenceRanges =>
      _cache['reference_ranges'] ?? {};
  static Map<String, dynamic> get guidelines => _cache['guidelines'] ?? {};

  static bool get isInitialized => _initialized;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      final diseasesJson =
          await rootBundle.loadString('lib/data/diseases.json');
      _cache['diseases'] = jsonDecode(diseasesJson);

      final rangesJson =
          await rootBundle.loadString('lib/data/reference_ranges.json');
      _cache['reference_ranges'] = jsonDecode(rangesJson);

      final guidelinesJson =
          await rootBundle.loadString('lib/data/guidelines.json');
      _cache['guidelines'] = jsonDecode(guidelinesJson);

      _initialized = true;
    } catch (e) {
      _initialized = false;
    }
  }

  static dynamic get(String key) => _cache[key];

  static void clear() {
    _cache.clear();
    _initialized = false;
  }
}
