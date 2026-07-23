import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/health_news_service.dart';
import '../widgets/health_feed_section.dart';

/// Full-screen list for a single health feed (news or remedies), opened from a
/// dashboard button. Pull-to-refresh and an app-bar refresh both reload it.
class HealthFeedScreen extends ConsumerWidget {
  final String title;
  final String subtitle;
  final AutoDisposeFutureProvider<List<HealthNewsItem>> provider;
  final Widget Function(BuildContext context, bool isDark) fallbackBuilder;
  final IconData itemIcon;

  const HealthFeedScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.provider,
    required this.fallbackBuilder,
    this.itemIcon = Icons.article_outlined,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(provider),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(provider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                HealthFeedSection(
                  title: title,
                  subtitle: subtitle,
                  provider: provider,
                  fallbackBuilder: fallbackBuilder,
                  itemIcon: itemIcon,
                  showHeader: false,
                  maxItems: 20,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
