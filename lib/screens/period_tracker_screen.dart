import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PeriodTrackerScreen extends StatefulWidget {
  const PeriodTrackerScreen({super.key});

  @override
  State<PeriodTrackerScreen> createState() => _PeriodTrackerScreenState();
}

class _PeriodTrackerScreenState extends State<PeriodTrackerScreen> {
  DateTime? _lastPeriodStart;
  int _cycleLength = 28;
  int _periodLength = 5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final lps = prefs.getString('pt_last_period');
      if (lps != null) _lastPeriodStart = DateTime.parse(lps);
      _cycleLength = prefs.getInt('pt_cycle_length') ?? 28;
      _periodLength = prefs.getInt('pt_period_length') ?? 5;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastPeriodStart != null) {
      await prefs.setString('pt_last_period', _lastPeriodStart!.toIso8601String());
    }
    await prefs.setInt('pt_cycle_length', _cycleLength);
    await prefs.setInt('pt_period_length', _periodLength);
  }

  DateTime? get _nextPeriod => _lastPeriodStart?.add(Duration(days: _cycleLength));
  DateTime? get _ovulationDay => _lastPeriodStart?.add(Duration(days: _cycleLength - 14));
  DateTime? get _fertileStart => _ovulationDay?.subtract(const Duration(days: 5));
  DateTime? get _fertileEnd => _ovulationDay?.add(const Duration(days: 1));
  DateTime? get _nextPeriodEnd => _nextPeriod?.add(Duration(days: _periodLength));

  String get _phaseToday {
    if (_lastPeriodStart == null) return 'Unknown';
    final today = DateTime.now();
    final dayOfCycle = today.difference(_lastPeriodStart!).inDays % _cycleLength;
    if (dayOfCycle < _periodLength) return 'Menstrual Phase';
    if (dayOfCycle < 13) return 'Follicular Phase';
    if (dayOfCycle >= _cycleLength - 19 && dayOfCycle <= _cycleLength - 12) return 'Ovulation Phase';
    return 'Luteal Phase';
  }

  int get _dayInCycle {
    if (_lastPeriodStart == null) return 0;
    return DateTime.now().difference(_lastPeriodStart!).inDays % _cycleLength + 1;
  }

  int get _daysUntilNext {
    if (_nextPeriod == null) return 0;
    return _nextPeriod!.difference(DateTime.now()).inDays;
  }

  int get _daysUntilOvulation {
    if (_ovulationDay == null) return 0;
    return _ovulationDay!.difference(DateTime.now()).inDays;
  }

  bool get _inFertileWindow {
    if (_fertileStart == null || _fertileEnd == null) return false;
    final now = DateTime.now();
    return now.isAfter(_fertileStart!.subtract(const Duration(days: 1))) && now.isBefore(_fertileEnd!.add(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Period & Ovulation Tracker'),
        backgroundColor: isDark ? Colors.pink.shade900 : Colors.pink.shade50,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputCard(isDark),
              if (_lastPeriodStart != null) ...[
                const SizedBox(height: 16),
                _buildCycleOverviewCard(isDark),
                const SizedBox(height: 16),
                _buildPhaseCard(isDark),
                const SizedBox(height: 16),
                _buildNextPeriodCard(isDark),
                const SizedBox(height: 16),
                _buildOvulationCard(isDark),
                const SizedBox(height: 16),
                _buildFertileWindowCard(isDark),
                const SizedBox(height: 16),
                _buildCalendarPreview(isDark),
              ] else ...[
                const SizedBox(height: 32),
                Icon(Icons.calendar_month, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text('Track your cycle with confidence', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Enter your last period date to see predictions for your next period, fertile window, and ovulation day.',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.edit_calendar, color: Colors.pink.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Your Cycle Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _lastPeriodStart ?? DateTime.now().subtract(const Duration(days: 14)),
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) {
                  setState(() => _lastPeriodStart = picked);
                  _saveData();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.pink.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: isDark ? Colors.pink.shade900.withValues(alpha: 0.2) : Colors.pink.shade50,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month, color: Colors.pink.shade400),
                    const SizedBox(width: 10),
                    Text(
                      _lastPeriodStart != null ? 'Last Period: ${DateFormat('dd MMM yyyy').format(_lastPeriodStart!)}' : 'Tap to enter last period date',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _lastPeriodStart != null ? null : Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cycle: $_cycleLength days', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Slider(value: _cycleLength.toDouble(), min: 21, max: 40, divisions: 19, activeColor: Colors.pink,
                        onChanged: (v) { setState(() => _cycleLength = v.round()); _saveData(); }),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Period: $_periodLength days', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Slider(value: _periodLength.toDouble(), min: 2, max: 8, divisions: 6, activeColor: Colors.red,
                        onChanged: (v) { setState(() => _periodLength = v.round()); _saveData(); }),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleOverviewCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.pink.shade300, Colors.pink.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('Day', style: TextStyle(fontSize: 14, color: Colors.white70)),
          Text('$_dayInCycle', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
          Text('of your cycle', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniStat('$_cycleLength', 'Day Cycle'),
              _buildMiniStat('$_periodLength', 'Day Period'),
              _buildMiniStat(_daysUntilNext > 0 ? '${_daysUntilNext}d' : 'Today!', 'Until Next'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  Widget _buildPhaseCard(bool isDark) {
    final phase = _phaseToday;
    Color phaseColor;
    IconData phaseIcon;
    String phaseDesc;

    switch (phase) {
      case 'Menstrual Phase':
        phaseColor = Colors.red;
        phaseIcon = Icons.water_drop;
        phaseDesc = 'Your period is here. Rest, stay hydrated, and use heat for cramps. Iron-rich foods help replenish blood loss.';
        break;
      case 'Follicular Phase':
        phaseColor = Colors.green;
        phaseIcon = Icons.eco;
        phaseDesc = 'Energy is rising! Estrogen is building. Great time for exercise, social activities, and starting new projects.';
        break;
      case 'Ovulation Phase':
        phaseColor = Colors.purple;
        phaseIcon = Icons.auto_awesome;
        phaseDesc = 'Peak fertility! You\'re most likely to conceive in this window. Libido and energy are at their highest.';
        break;
      default:
        phaseColor = Colors.orange;
        phaseIcon = Icons.nights_stay;
        phaseDesc = 'Progesterone is dominant. You may experience PMS symptoms. Focus on self-care, gentle exercise, and mood management.';
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: phaseColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(phaseIcon, color: phaseColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Phase', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(phase, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: phaseColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(phaseDesc, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildNextPeriodCard(bool isDark) {
    final daysLeft = _daysUntilNext;
    final isSoon = daysLeft <= 5 && daysLeft > 0;
    final isToday = daysLeft <= 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: isSoon || isToday ? BorderSide(color: Colors.red.shade300) : BorderSide.none),
      color: isSoon || isToday ? (isDark ? Colors.red.shade900.withValues(alpha: 0.2) : Colors.red.shade50) : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: (isSoon || isToday ? Colors.red : Colors.pink).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(isToday ? Icons.circle : (isSoon ? Icons.notifications_active : Icons.event), color: isToday ? Colors.red : (isSoon ? Colors.orange : Colors.pink), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Next Period', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  if (_nextPeriod != null)
                    Text(DateFormat('dd MMM yyyy').format(_nextPeriod!), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (isToday)
                    const Text('Expected today!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600))
                  else if (isSoon)
                    Text('In $daysLeft days — get ready!', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w500, fontSize: 12))
                  else if (daysLeft > 0)
                    Text('In $daysLeft days', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            if (_nextPeriodEnd != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Ends', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(DateFormat('dd MMM').format(_nextPeriodEnd!), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOvulationCard(bool isDark) {
    final daysUntil = _daysUntilOvulation;
    final isClose = daysUntil >= 0 && daysUntil <= 2;
    final isPast = daysUntil < 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.auto_awesome, color: isClose ? Colors.purple : (isPast ? Colors.grey : Colors.purple.shade300), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ovulation Day', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  if (_ovulationDay != null)
                    Text(DateFormat('dd MMM yyyy').format(_ovulationDay!), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (isPast)
                    const Text('Passed this cycle', style: TextStyle(fontSize: 12, color: Colors.grey))
                  else if (isClose)
                    const Text('Ovulation is very close!', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.w600, fontSize: 12))
                  else
                    Text('In $daysUntil days', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFertileWindowCard(bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: _inFertileWindow ? BorderSide(color: Colors.green.shade400, width: 2) : BorderSide.none,
      ),
      color: _inFertileWindow ? (isDark ? Colors.green.shade900.withValues(alpha: 0.2) : Colors.green.shade50) : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: _inFertileWindow ? Colors.green : Colors.pink),
                const SizedBox(width: 8),
                Text('Fertile Window', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _inFertileWindow ? Colors.green : null)),
                if (_inFertileWindow) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(6)),
                    child: const Text('ACTIVE NOW', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (_fertileStart != null && _fertileEnd != null)
              Text('${DateFormat('dd MMM').format(_fertileStart!)} — ${DateFormat('dd MMM yyyy').format(_fertileEnd!)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(
              _inFertileWindow
                  ? 'You are in your fertile window! The best chance of conception is today.'
                  : 'Your fertile window is the 5 days before ovulation plus ovulation day itself.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarPreview(bool isDark) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = startOfMonth.weekday % 7;

    final periodDays = <int>{};
    final fertileDays = <int>{};
    final ovulationDay = <int>{};

    if (_lastPeriodStart != null) {
      for (int cycle = -2; cycle <= 3; cycle++) {
        final cycleStart = _lastPeriodStart!.add(Duration(days: _cycleLength * cycle));
        for (int d = 0; d < _periodLength; d++) {
          final day = cycleStart.add(Duration(days: d));
          if (day.month == now.month && day.year == now.year) periodDays.add(day.day);
        }
        final ov = cycleStart.add(Duration(days: _cycleLength - 14));
        if (ov.month == now.month && ov.year == now.year) ovulationDay.add(ov.day);
        for (int d = -5; d <= 1; d++) {
          final day = ov.add(Duration(days: d));
          if (day.month == now.month && day.year == now.year) fertileDays.add(day.day);
        }
      }
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('MMMM yyyy').format(now), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) =>
                Expanded(child: Center(child: Text(d, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600))))).toList(),
            ),
            const SizedBox(height: 4),
            ...List.generate((daysInMonth + firstWeekday + 6) ~/ 7, (week) {
              return Row(
                children: List.generate(7, (dow) {
                  final dayNum = week * 7 + dow - firstWeekday + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) return const Expanded(child: SizedBox(height: 36));
                  final isPeriod = periodDays.contains(dayNum);
                  final isFertile = fertileDays.contains(dayNum);
                  final isOvulation = ovulationDay.contains(dayNum);
                  final isToday = dayNum == now.day;

                  return Expanded(
                    child: Container(
                      height: 36,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isPeriod ? Colors.red.shade100 : (isOvulation ? Colors.purple.shade100 : (isFertile ? Colors.green.shade50 : null)),
                        borderRadius: BorderRadius.circular(8),
                        border: isToday ? Border.all(color: Colors.pink, width: 2) : null,
                      ),
                      child: Center(
                        child: Text('$dayNum', style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isPeriod ? Colors.red.shade700 : (isOvulation ? Colors.purple.shade700 : (isFertile ? Colors.green.shade700 : null)),
                        )),
                      ),
                    ),
                  );
                }),
              );
            }),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _buildLegend(Colors.red, 'Period'),
                _buildLegend(Colors.green, 'Fertile'),
                _buildLegend(Colors.purple, 'Ovulation'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }
}
