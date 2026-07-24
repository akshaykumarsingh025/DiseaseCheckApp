import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/profile_provider.dart';
import '../../widgets/nav_tile.dart';

/// The "Track" tab groups all logging and history tools: cycle, daily habits,
/// and history/insights.
class TrackTab extends ConsumerWidget {
  const TrackTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final isFemale = profile?.gender == 'Female';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isFemale) ...[
          const SectionHeader('Cycle'),
          const SizedBox(height: 10),
          NavTile(
            icon: Icons.calendar_month,
            color: Colors.pink,
            title: 'Period & Ovulation',
            subtitle: 'Log flow, symptoms, mood & get reminders',
            onTap: () => context.push('/period-tracker'),
          ),
        ],
        const SectionHeader('Daily habits'),
        const SizedBox(height: 10),
        NavTile(
          icon: Icons.water_drop,
          color: Colors.blue,
          title: 'Daily Wellness',
          subtitle: 'Water, sleep & steps with streaks',
          onTap: () => context.push('/wellness'),
        ),
        const SizedBox(height: 10),
        NavTile(
          icon: Icons.medication,
          color: Colors.teal,
          title: 'Medications & Supplements',
          subtitle: 'Reminders and daily adherence streaks',
          onTap: () => context.push('/medications'),
        ),
        const SectionHeader('History & insights'),
        const SizedBox(height: 10),
        NavTile(
          icon: Icons.show_chart,
          color: Colors.teal,
          title: 'Health Trends',
          subtitle: 'Track your vitals over time',
          onTap: () => context.push('/trends'),
        ),
        const SizedBox(height: 10),
        NavTile(
          icon: Icons.history,
          color: Colors.green,
          title: 'Past Reports',
          subtitle: 'Check your wellness history',
          onTap: () => context.push('/report-history'),
        ),
        const SizedBox(height: 10),
        NavTile(
          icon: Icons.summarize,
          color: Colors.purple,
          title: 'Weekly Health Digest',
          subtitle: 'Your week in one summary',
          onTap: () => context.push('/weekly-digest'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
