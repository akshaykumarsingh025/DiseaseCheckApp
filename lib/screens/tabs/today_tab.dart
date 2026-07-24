import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/profile_provider.dart';
import '../../services/wellness_log_service.dart';
import '../../services/medication_service.dart';
import '../../services/cycle_log_service.dart';
import '../../utils/bmi_calculator.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/daily_tip_card.dart';
import '../../widgets/health_score_card.dart';
import '../../widgets/nav_tile.dart';

/// The "Today" home tab: greeting, daily tip, health score, quick-log actions,
/// a consult prompt and a lightweight week snapshot.
class TodayTab extends ConsumerStatefulWidget {
  const TodayTab({super.key});

  @override
  ConsumerState<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends ConsumerState<TodayTab> {
  double? _avgWater;
  int? _medPct;
  int? _daysLogged;

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    try {
      final now = DateTime.now();
      final week = await WellnessLogService.lastDays(7);
      final waterSum = week.fold<int>(0, (s, e) => s + e.$2.water);

      int mt = 0, mtot = 0;
      for (int i = 0; i < 7; i++) {
        final (t, total) =
            await MedicationService.adherenceOn(now.subtract(Duration(days: i)));
        mt += t;
        mtot += total;
      }

      final logs = await CycleLogService.getDayLogs();
      int logged = 0;
      for (int i = 0; i < 7; i++) {
        final log = logs[CycleLogService.dateKey(now.subtract(Duration(days: i)))];
        if (log != null && !log.isEmpty) logged++;
      }

      if (!mounted) return;
      setState(() {
        _avgWater = waterSum / 7;
        _medPct = mtot == 0 ? null : (mt / mtot * 100).round();
        _daysLogged = logged;
      });
    } catch (_) {
      // Snapshot is best-effort; leave placeholders on failure.
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final isFemale = profile?.gender == 'Female';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return RefreshIndicator(
      onRefresh: _loadSnapshot,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const DisclaimerBanner(),
          const SizedBox(height: 8),
          if (profile != null)
            Text('$greeting,',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          if (profile != null)
            Text(profile.name,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          const DailyTipCard(),
          const SizedBox(height: 12),
          const HealthScoreCard(),
          const SizedBox(height: 12),
          if (profile?.height != null && profile?.weight != null) ...[
            _bmiCard(context, profile!.weight!, profile.height!),
            const SizedBox(height: 12),
          ],
          const Padding(
            padding: EdgeInsets.only(left: 2, top: 4, bottom: 8),
            child: Text('QUICK LOG',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Colors.grey)),
          ),
          Row(
            children: [
              if (isFemale) ...[
                Expanded(
                  child: QuickActionTile(
                    icon: Icons.calendar_month,
                    color: Colors.pink,
                    label: 'Period',
                    onTap: () => context.push('/period-tracker'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: QuickActionTile(
                  icon: Icons.water_drop,
                  color: Colors.blue,
                  label: 'Water',
                  onTap: () => context.push('/wellness'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuickActionTile(
                  icon: Icons.medication,
                  color: Colors.teal,
                  label: 'Meds',
                  onTap: () => context.push('/medications'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuickActionTile(
                  icon: Icons.psychology_alt,
                  color: Colors.deepPurple,
                  label: 'Symptom',
                  onTap: () => context.push('/symptom-checker'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _consultBanner(context),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 8),
            child: Text('THIS WEEK',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Colors.grey)),
          ),
          Row(
            children: [
              Expanded(
                child: _statCard(
                    Colors.blue,
                    _avgWater == null ? '—' : _avgWater!.toStringAsFixed(1),
                    'avg glasses'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(Colors.teal,
                    _medPct == null ? '—' : '$_medPct%', 'meds taken'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(Colors.pink,
                    _daysLogged == null ? '—' : '$_daysLogged', 'days logged'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _statCard(Color color, String value, String label) {
    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 21, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _consultBanner(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/online-opd'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF12496B), Color(0xFF0F3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: const Icon(Icons.local_hospital, color: Colors.white),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Consult Dr. Deepika',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('Online OPD · ₹111 video consultation',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text('Book',
                  style: TextStyle(
                      color: Color(0xFF0F3460),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bmiCard(BuildContext context, double weight, double height) {
    final bmi = BmiCalculator.calculateBmi(weight, height);
    final category = BmiCalculator.getBmiCategory(bmi);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark
          ? Colors.blue.shade900.withValues(alpha: 0.3)
          : Colors.blue.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: isDark ? Colors.blue.shade700 : Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current BMI',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87)),
                Text(category,
                    style: TextStyle(
                        color:
                            isDark ? Colors.grey.shade300 : Colors.grey.shade700)),
              ],
            ),
            Text(bmi.toStringAsFixed(1),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: isDark ? Colors.blue.shade300 : Colors.blue)),
          ],
        ),
      ),
    );
  }
}
