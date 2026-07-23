import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

import 'remote_config_service.dart';

/// A single women's-health news headline.
class HealthNewsItem {
  final String title;
  final String summary;
  final String source;
  final String url;
  final DateTime? publishedAt;

  const HealthNewsItem({
    required this.title,
    required this.summary,
    required this.source,
    required this.url,
    this.publishedAt,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'summary': summary,
        'source': source,
        'url': url,
        'publishedAt': publishedAt?.toIso8601String(),
      };

  factory HealthNewsItem.fromJson(Map<String, dynamic> json) => HealthNewsItem(
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        source: json['source'] as String? ?? '',
        url: json['url'] as String? ?? '',
        publishedAt: (json['publishedAt'] as String?) != null
            ? DateTime.tryParse(json['publishedAt'] as String)
            : null,
      );
}

/// Fetches live women's-health content from keyless Google News RSS feeds and
/// caches the result. No API key is required, so it keeps working in a shipped
/// build. Each feed URL can be overridden from Firestore (`config/api_keys`) to
/// tune the query without an app update:
///   - `womens_health_news_url`
///   - `natural_remedies_url`
class HealthNewsService {
  HealthNewsService._();

  static const String _newsCacheKey = 'womens_health_news_cache_v1';
  static const String _remediesCacheKey = 'natural_remedies_cache_v1';

  // Keyless Google News RSS search, scoped to women's health, last ~14 days.
  static const String _defaultNewsUrl =
      'https://news.google.com/rss/search?q=%22women%27s+health%22+OR+gynaecology+OR+%22reproductive+health%22+when:14d&hl=en-IN&gl=IN&ceid=IN:en';

  // Natural / herbal remedies relevant to women's health, last ~30 days.
  static const String _defaultRemediesUrl =
      'https://news.google.com/rss/search?q=(%22natural+remedies%22+OR+%22herbal+medicine%22+OR+ayurveda)+(women+OR+menstrual+OR+PCOS+OR+pregnancy)+when:30d&hl=en-IN&gl=IN&ceid=IN:en';

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 12),
      responseType: ResponseType.plain,
      headers: const {'User-Agent': 'DiseaseCheckApp/1.0 (news)'},
    ),
  );

  /// Latest women's-health headlines.
  static Future<List<HealthNewsItem>> fetchWomensHealthNews({int limit = 8}) {
    return _fetchFeed(
      _resolveUrl('womens_health_news_url', _defaultNewsUrl),
      _newsCacheKey,
      limit,
    );
  }

  /// Latest natural / herbal remedy articles for women's health.
  static Future<List<HealthNewsItem>> fetchNaturalRemedies({int limit = 8}) {
    return _fetchFeed(
      _resolveUrl('natural_remedies_url', _defaultRemediesUrl),
      _remediesCacheKey,
      limit,
    );
  }

  /// Returns the latest items for a feed. On any network/parse failure it falls
  /// back to the last cached list (empty list if nothing was ever cached, so
  /// the UI can show its static fallback).
  static Future<List<HealthNewsItem>> _fetchFeed(
      String feedUrl, String cacheKey, int limit) async {
    try {
      final res = await _dio.get<String>(feedUrl);
      final body = res.data;
      if (body != null && body.trim().isNotEmpty) {
        final items = _parseRss(body, limit);
        if (items.isNotEmpty) {
          await _saveCache(cacheKey, items);
          return items;
        }
      }
    } catch (_) {
      // Fall through to the cached copy.
    }
    return _loadCache(cacheKey);
  }

  static String _resolveUrl(String configKey, String fallback) {
    final configured = RemoteConfigService.getString(configKey);
    if (configured != null && configured.startsWith('http')) return configured;
    return fallback;
  }

  static List<HealthNewsItem> _parseRss(String xmlBody, int limit) {
    final doc = XmlDocument.parse(xmlBody);
    final items = <HealthNewsItem>[];

    for (final node in doc.findAllElements('item')) {
      final rawTitle = _childText(node, 'title');
      if (rawTitle.isEmpty) continue;

      final link = _childText(node, 'link');
      if (link.isEmpty) continue;

      final published = _parseDate(_childText(node, 'pubDate'));

      // Prefer the explicit <source> element for the publisher name.
      String source = '';
      final sourceEl = node.findElements('source');
      if (sourceEl.isNotEmpty) source = sourceEl.first.innerText.trim();

      // Google News titles are usually "Headline - Source".
      String title = rawTitle;
      if (source.isNotEmpty && title.endsWith(' - $source')) {
        title = title.substring(0, title.length - source.length - 3).trim();
      } else if (source.isEmpty) {
        final idx = title.lastIndexOf(' - ');
        if (idx > 20) {
          source = title.substring(idx + 3).trim();
          title = title.substring(0, idx).trim();
        }
      }

      var summary = _stripHtml(_childText(node, 'description'));
      if (summary.length < 20) {
        summary =
            'Tap to read the full article${source.isNotEmpty ? ' from $source' : ''}.';
      } else if (summary.length > 180) {
        summary = '${summary.substring(0, 177)}...';
      }

      items.add(HealthNewsItem(
        title: title,
        summary: summary,
        source: source.isEmpty ? 'Google News' : source,
        url: link,
        publishedAt: published,
      ));
      if (items.length >= limit) break;
    }
    return items;
  }

  static String _childText(XmlElement parent, String tag) {
    final el = parent.findElements(tag);
    if (el.isEmpty) return '';
    return el.first.innerText.trim();
  }

  static String _stripHtml(String input) {
    final noTags = input.replaceAll(RegExp(r'<[^>]*>'), ' ');
    final unescaped = noTags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    return unescaped.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    // RFC-822, e.g. "Wed, 16 Jul 2025 10:00:00 GMT".
    try {
      var s = raw;
      final comma = s.indexOf(',');
      if (comma != -1) s = s.substring(comma + 1).trim();
      final parts = s.split(RegExp(r'\s+'));
      if (parts.length >= 4) {
        final dmy = '${parts[0]} ${parts[1]} ${parts[2]} ${parts[3]}';
        return DateFormat('dd MMM yyyy HH:mm:ss', 'en_US').parseUtc(dmy);
      }
    } catch (_) {}
    return DateTime.tryParse(raw);
  }

  static Future<void> _saveCache(
      String cacheKey, List<HealthNewsItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        cacheKey,
        jsonEncode({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'items': items.map((e) => e.toJson()).toList(),
        }),
      );
    } catch (_) {}
  }

  static Future<List<HealthNewsItem>> _loadCache(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(cacheKey);
      if (raw == null) return const [];
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final list = (decoded['items'] as List?) ?? const [];
      return list
          .map((e) => HealthNewsItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

/// Live women's-health news. Auto-disposes when no longer watched; invalidate
/// it to force a refresh.
final womensHealthNewsProvider =
    FutureProvider.autoDispose<List<HealthNewsItem>>((ref) {
  return HealthNewsService.fetchWomensHealthNews();
});

/// Live natural / herbal remedy articles for women's health.
final naturalRemediesProvider =
    FutureProvider.autoDispose<List<HealthNewsItem>>((ref) {
  return HealthNewsService.fetchNaturalRemedies();
});
