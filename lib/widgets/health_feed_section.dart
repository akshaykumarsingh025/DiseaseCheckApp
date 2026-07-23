import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/health_news_service.dart';

const List<Color> _feedPalette = [
  Colors.blue,
  Colors.green,
  Colors.purple,
  Colors.teal,
  Colors.pinkAccent,
  Colors.orange,
];

/// A self-contained "live feed" section (title + refresh + cards) driven by a
/// [FutureProvider] of [HealthNewsItem]s. Falls back to [fallbackBuilder]
/// (curated static content) while offline or when the feed is empty, so the
/// section is never blank. Reused on the dashboard and the Women's Health hub.
class HealthFeedSection extends ConsumerWidget {
  final String title;
  final String subtitle;
  final AutoDisposeFutureProvider<List<HealthNewsItem>> provider;
  final Widget Function(BuildContext context, bool isDark) fallbackBuilder;
  final IconData itemIcon;
  final int maxItems;
  final bool showHeader;

  const HealthFeedSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.provider,
    required this.fallbackBuilder,
    this.itemIcon = Icons.article_outlined,
    this.maxItems = 6,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final async = ref.watch(provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                tooltip: 'Refresh',
                visualDensity: VisualDensity.compact,
                icon:
                    Icon(Icons.refresh, size: 20, color: Colors.grey.shade600),
                onPressed: () => ref.invalidate(provider),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
        ],
        async.when(
          loading: () => _loading(isDark),
          error: (_, __) => fallbackBuilder(context, isDark),
          data: (items) {
            if (items.isEmpty) return fallbackBuilder(context, isDark);
            final cards = <Widget>[];
            final count = items.length < maxItems ? items.length : maxItems;
            for (var i = 0; i < count; i++) {
              if (i > 0) cards.add(const SizedBox(height: 10));
              final item = items[i];
              final rel = _relativeTime(item.publishedAt);
              final label =
                  rel.isEmpty ? item.source : '${item.source} • $rel';
              cards.add(healthFeedCard(
                context,
                isDark,
                title: item.title,
                summary: item.summary,
                source: label,
                icon: itemIcon,
                color: _feedPalette[i % _feedPalette.length],
                url: item.url,
              ));
            }
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, children: cards);
          },
        ),
      ],
    );
  }

  Widget _loading(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      alignment: Alignment.center,
      child: Column(
        children: [
          const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5)),
          const SizedBox(height: 10),
          Text('Fetching latest updates...',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

String _relativeTime(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inDays >= 1) return '${diff.inDays}d ago';
  if (diff.inHours >= 1) return '${diff.inHours}h ago';
  if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
  return 'just now';
}

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  var opened = false;
  // Open articles inside the app (Chrome Custom Tab / SFSafariViewController)
  // so the user never leaves DiseaseCheck.
  try {
    opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  } catch (_) {
    opened = false;
  }
  // Fall back to the platform default only if the in-app browser is unavailable.
  if (!opened) {
    try {
      opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      opened = false;
    }
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the article.')),
    );
  }
}

/// A single feed card. Tappable (opens the article) when [url] is non-null.
Widget healthFeedCard(
  BuildContext context,
  bool isDark, {
  required String title,
  required String summary,
  required String source,
  required IconData icon,
  required Color color,
  String? url,
}) {
  final content = Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            if (url != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.open_in_new, size: 15, color: Colors.grey.shade500),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(summary,
            style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                height: 1.4)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6)),
          child: Text(source,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ),
      ],
    ),
  );

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    clipBehavior: Clip.antiAlias,
    child: url == null
        ? content
        : InkWell(onTap: () => _openUrl(context, url), child: content),
  );
}

/// Curated women's-health headlines, shown when the live feed is unavailable.
Widget womensHealthNewsFallback(BuildContext context, bool isDark) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      healthFeedCard(context, isDark,
          title: 'WHO Updates Cervical Cancer Screening Guidelines',
          summary:
              'WHO now recommends HPV DNA testing as the primary screening method, replacing visual inspection. Self-collection approved for community programs.',
          source: 'WHO | 2025',
          icon: Icons.verified,
          color: Colors.blue),
      const SizedBox(height: 10),
      healthFeedCard(context, isDark,
          title: 'ACOG Recommends Universal Postpartum Screening',
          summary:
              'ACOG 2025 guidelines mandate postpartum depression screening at 2, 6, and 12 weeks. Early intervention improves maternal outcomes significantly.',
          source: 'ACOG | 2025',
          icon: Icons.verified,
          color: Colors.green),
      const SizedBox(height: 10),
      healthFeedCard(context, isDark,
          title: 'New Oral Progestin for Heavy Menstrual Bleeding',
          summary:
              'FDA-approved relugolix combination therapy shows 70% reduction in heavy menstrual bleeding with a favorable safety profile vs. surgical options.',
          source: 'FDA | 2025',
          icon: Icons.verified,
          color: Colors.purple),
    ],
  );
}

/// Curated evidence-based natural remedies, shown when the live feed is
/// unavailable.
Widget naturalRemediesFallback(BuildContext context, bool isDark) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      healthFeedCard(context, isDark,
          title: 'Ginger for Nausea & Dysmenorrhea',
          summary:
              'Clinical studies show ginger (250mg 3x/day) is as effective as ibuprofen for menstrual pain. Take at onset of symptoms.',
          source: 'Evidence-based',
          icon: Icons.local_cafe,
          color: Colors.amber),
      const SizedBox(height: 10),
      healthFeedCard(context, isDark,
          title: 'Iron-Rich Foods for Anemia',
          summary:
              'Spinach, dates, beetroot, and jaggery help combat iron deficiency anemia — common in women of reproductive age. Pair with vitamin C for absorption.',
          source: 'Evidence-based',
          icon: Icons.grain,
          color: Colors.green),
      const SizedBox(height: 10),
      healthFeedCard(context, isDark,
          title: 'Cinnamon for PCOS Insulin Resistance',
          summary:
              '1.5g cinnamon daily may improve insulin sensitivity and menstrual cyclicity in PCOS. Ceylon cinnamon is preferred (lower coumarin).',
          source: 'Evidence-based',
          icon: Icons.spa,
          color: Colors.brown),
      const SizedBox(height: 10),
      healthFeedCard(context, isDark,
          title: 'Chasteberry (Vitex) for PMS',
          summary:
              'Vitex agnus-castus (20mg daily) is supported by clinical trials for reducing PMS symptoms including breast tenderness and mood changes.',
          source: 'Evidence-based',
          icon: Icons.local_florist,
          color: Colors.purple),
      const SizedBox(height: 10),
      healthFeedCard(context, isDark,
          title: 'Yoga & Pranayama for Menstrual Health',
          summary:
              'Regular yoga practice (3x/week, 30min) has shown improvement in menstrual regularity, pain reduction, and stress management in multiple RCTs.',
          source: 'Evidence-based',
          icon: Icons.self_improvement,
          color: Colors.teal),
    ],
  );
}
