import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/cycle_log_service.dart';
import '../services/medication_service.dart';
import '../services/wellness_log_service.dart';

class WeeklyDigestScreen extends StatefulWidget {
  const WeeklyDigestScreen({super.key});

  @override
  State<WeeklyDigestScreen> createState() => _WeeklyDigestScreenState();
}

class _WeeklyDigestScreenState extends State<WeeklyDigestScreen> {
  bool _loading = true;

  double _avgWater = 0;
  int _waterGoalDays = 0;
  double _avgSleep = 0;
  int _totalSteps = 0;
  int _medTaken = 0;
  int _medTotal = 0;
  int _daysLogged = 0;
  Map<String, int> _symptomCounts = {};
  DateTime? _nextPeriod;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();

    // Wellness (last 7 days)
    final week = await WellnessLogService.lastDays(7);
    final waterGoal = await WellnessLogService.waterGoal();
    int waterSum = 0, goalDays = 0, stepsSum = 0;
    double sleepSum = 0;
    int sleepDays = 0;
    for (final (_, e) in week) {
      waterSum += e.water;
      if (e.water >= waterGoal) goalDays++;
      stepsSum += e.steps;
      if (e.sleep > 0) {
        sleepSum += e.sleep;
        sleepDays++;
      }
    }

    // Medication adherence (last 7 days)
    int mt = 0, mtot = 0;
    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      final (t, total) = await MedicationService.adherenceOn(d);
      mt += t;
      mtot += total;
    }

    // Cycle logs (last 7 days)
    final logs = await CycleLogService.getDayLogs();
    final symptomCounts = <String, int>{};
    int daysLogged = 0;
    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      final log = logs[CycleLogService.dateKey(d)];
      if (log != null && !log.isEmpty) {
        daysLogged++;
        for (final s in log.symptoms) {
          symptomCounts[s] = (symptomCounts[s] ?? 0) + 1;
        }
      }
    }

    // Next period prediction
    final starts = await CycleLogService.getPeriodStarts();
    DateTime? next;
    if (starts.isNotEmpty) {
      final cycle = CycleLogService.averageCycleLength(starts,
          fallback: await CycleLogService.getCycleLength());
      next = starts.last.add(Duration(days: cycle));
    }

    if (!mounted) return;
    setState(() {
      _avgWater = waterSum / 7;
      _waterGoalDays = goalDays;
      _avgSleep = sleepDays == 0 ? 0 : sleepSum / sleepDays;
      _totalSteps = stepsSum;
      _medTaken = mt;
      _medTotal = mtot;
      _daysLogged = daysLogged;
      _symptomCounts = symptomCounts;
      _nextPeriod = next;
      _loading = false;
    });
  }

  String get _topSymptom {
    if (_symptomCounts.isEmpty) return '—';
    final sorted = _symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return '${sorted.first.key} (${sorted.first.value}×)';
  }

  String get _headline {
    final bits = <String>[];
    if (_medTotal > 0) {
      final pct = (_medTaken / _medTotal * 100).round();
      bits.add('$pct% of your medicine doses');
    }
    if (_waterGoalDays > 0) {
      bits.add('hit your water goal on $_waterGoalDays day${_waterGoalDays == 1 ? '' : 's'}');
    }
    if (bits.isEmpty) {
      return 'Start logging your habits this week to see your personalised digest here.';
    }
    return 'This week you took ${bits.join(' and ')}. Keep building the habit!';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 6));
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Health Digest')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                      '${DateFormat('dd MMM').format(from)} – ${DateFormat('dd MMM yyyy').format(now)}',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.purple.shade400, Colors.pink.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_headline,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _statTile(Icons.water_drop, Colors.blue, 'Avg water',
                          _avgWater.toStringAsFixed(1), 'glasses/day'),
                      _statTile(Icons.bedtime, Colors.indigo, 'Avg sleep',
                          _avgSleep == 0 ? '—' : _avgSleep.toStringAsFixed(1),
                          'hours/night'),
                      _statTile(Icons.directions_walk, Colors.green,
                          'Total steps', _fmtInt(_totalSteps), 'this week'),
                      _statTile(
                          Icons.medication,
                          Colors.teal,
                          'Medicines',
                          _medTotal == 0
                              ? '—'
                              : '${(_medTaken / _medTotal * 100).round()}%',
                          'doses taken'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _cycleCard(),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  String _fmtInt(int v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return '$v';
  }

  Widget _statTile(
      IconData icon, Color color, String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600)),
          Text(sub,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _cycleCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.female, color: Colors.pink.shade400),
                const SizedBox(width: 8),
                const Text('Cycle & symptoms',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            _digestRow('Days logged', '$_daysLogged / 7'),
            _digestRow('Most common symptom', _topSymptom),
            _digestRow(
                'Next period',
                _nextPeriod == null
                    ? 'Log a period to predict'
                    : DateFormat('EEE, dd MMM').format(_nextPeriod!)),
          ],
        ),
      ),
    );
  }

  Widget _digestRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
