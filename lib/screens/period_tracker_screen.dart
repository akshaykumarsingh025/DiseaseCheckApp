import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/cycle_log_service.dart';
import '../services/notification_service.dart';

class PeriodTrackerScreen extends StatefulWidget {
  const PeriodTrackerScreen({super.key});

  @override
  State<PeriodTrackerScreen> createState() => _PeriodTrackerScreenState();
}

class _PeriodTrackerScreenState extends State<PeriodTrackerScreen> {
  List<DateTime> _periodStarts = [];
  Map<String, DayLog> _dayLogs = {};

  int _manualCycleLength = 28;
  int _periodLength = 5;

  bool _remindersEnabled = false;
  int _daysBefore = 2;
  bool _logReminderEnabled = false;
  int _logHour = 20;
  int _logMinute = 0;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final starts = await CycleLogService.getPeriodStarts();
    final logs = await CycleLogService.getDayLogs();
    final manualCycle = await CycleLogService.getCycleLength();
    final periodLen = await CycleLogService.getPeriodLength();
    final remEnabled = await CycleLogService.remindersEnabled();
    final daysBefore = await CycleLogService.daysBefore();
    final logEnabled = await CycleLogService.logReminderEnabled();
    final (h, m) = await CycleLogService.logReminderTime();
    if (!mounted) return;
    setState(() {
      _periodStarts = starts;
      _dayLogs = logs;
      _manualCycleLength = manualCycle;
      _periodLength = periodLen;
      _remindersEnabled = remEnabled;
      _daysBefore = daysBefore;
      _logReminderEnabled = logEnabled;
      _logHour = h;
      _logMinute = m;
      _loading = false;
    });
  }

  // --- Derived cycle data ----------------------------------------------------

  DateTime? get _lastPeriodStart =>
      _periodStarts.isNotEmpty ? _periodStarts.last : null;

  bool get _cycleAuto => _periodStarts.length >= 2;

  int get _cycleLength => _cycleAuto
      ? CycleLogService.averageCycleLength(_periodStarts,
          fallback: _manualCycleLength)
      : _manualCycleLength;

  DateTime? get _nextPeriod => _lastPeriodStart?.add(Duration(days: _cycleLength));
  DateTime? get _ovulationDay =>
      _lastPeriodStart?.add(Duration(days: _cycleLength - 14));
  DateTime? get _fertileStart => _ovulationDay?.subtract(const Duration(days: 5));
  DateTime? get _fertileEnd => _ovulationDay?.add(const Duration(days: 1));
  DateTime? get _nextPeriodEnd => _nextPeriod?.add(Duration(days: _periodLength));

  String get _phaseToday {
    if (_lastPeriodStart == null) return 'Unknown';
    final today = DateTime.now();
    final dayOfCycle = today.difference(_lastPeriodStart!).inDays % _cycleLength;
    if (dayOfCycle < _periodLength) return 'Menstrual Phase';
    if (dayOfCycle < 13) return 'Follicular Phase';
    if (dayOfCycle >= _cycleLength - 19 && dayOfCycle <= _cycleLength - 12) {
      return 'Ovulation Phase';
    }
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
    return now.isAfter(_fertileStart!.subtract(const Duration(days: 1))) &&
        now.isBefore(_fertileEnd!.add(const Duration(days: 1)));
  }

  // --- Actions ---------------------------------------------------------------

  Future<void> _reschedule() async {
    await NotificationService.cancelPeriodReminders();
    if (_remindersEnabled && _lastPeriodStart != null) {
      await NotificationService.schedulePeriodReminders(
        nextPeriod: _nextPeriod,
        fertileStart: _fertileStart,
        ovulationDay: _ovulationDay,
        daysBeforePeriod: _daysBefore,
      );
    }
    if (_logReminderEnabled) {
      await NotificationService.scheduleDailyLogReminder(
          hour: _logHour, minute: _logMinute);
    } else {
      await NotificationService.cancelDailyLogReminder();
    }
  }

  Future<void> _markPeriodStart(DateTime date) async {
    final starts = await CycleLogService.addPeriodStart(date);
    setState(() => _periodStarts = starts);
    await _reschedule();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Period start logged for ${DateFormat('dd MMM').format(date)}')),
      );
    }
  }

  Future<void> _removePeriodStart(DateTime date) async {
    final starts = await CycleLogService.removePeriodStart(date);
    setState(() => _periodStarts = starts);
    await _reschedule();
  }

  Future<void> _pickAndLogPeriodStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      await _markPeriodStart(DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _openLogSheet([DateTime? forDate]) async {
    final date = forDate ?? DateTime.now();
    final existing = _dayLogs[CycleLogService.dateKey(date)] ??
        DayLog(date: CycleLogService.dateKey(date));
    final result = await showModalBottomSheet<DayLog>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _LogSheet(date: date, initial: existing),
    );
    if (result != null) {
      await CycleLogService.saveDayLog(result);
      // Reload (saving flow may have added a period start automatically).
      final logs = await CycleLogService.getDayLogs();
      final starts = await CycleLogService.getPeriodStarts();
      if (!mounted) return;
      setState(() {
        _dayLogs = logs;
        _periodStarts = starts;
      });
      await _reschedule();
    }
  }

  Future<void> _toggleReminders(bool v) async {
    setState(() => _remindersEnabled = v);
    await CycleLogService.setRemindersEnabled(v);
    await _reschedule();
  }

  Future<void> _setDaysBefore(int v) async {
    setState(() => _daysBefore = v);
    await CycleLogService.setDaysBefore(v);
    await _reschedule();
  }

  Future<void> _toggleLogReminder(bool v) async {
    setState(() => _logReminderEnabled = v);
    await CycleLogService.setLogReminder(v, _logHour, _logMinute);
    await _reschedule();
  }

  Future<void> _pickLogTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _logHour, minute: _logMinute),
    );
    if (picked != null) {
      setState(() {
        _logHour = picked.hour;
        _logMinute = picked.minute;
      });
      await CycleLogService.setLogReminder(
          _logReminderEnabled, _logHour, _logMinute);
      await _reschedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Period & Ovulation Tracker')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Period & Ovulation Tracker'),
        backgroundColor: isDark ? Colors.pink.shade900 : Colors.pink.shade50,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openLogSheet(),
        backgroundColor: Colors.pink,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Log today', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTodayLogCard(isDark),
              const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                _buildRemindersCard(isDark),
                const SizedBox(height: 16),
                _buildHistoryCard(isDark),
              ] else ...[
                const SizedBox(height: 24),
                Icon(Icons.calendar_month, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text('Track your cycle with confidence',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                    'Log the day your period starts to see predictions for your next period, fertile window and ovulation. The more you log, the smarter it gets.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _pickAndLogPeriodStart,
                  style: FilledButton.styleFrom(backgroundColor: Colors.pink),
                  icon: const Icon(Icons.water_drop),
                  label: const Text('Log period start date'),
                ),
              ],
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayLogCard(bool isDark) {
    final today = _dayLogs[CycleLogService.dateKey(DateTime.now())];
    final logged = today != null && !today.isEmpty;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openLogSheet(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.pink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(logged ? Icons.check_circle : Icons.edit_note,
                    color: Colors.pink, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(logged ? "Today's log" : 'How are you feeling today?',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      logged ? _summariseLog(today) : 'Tap to log flow, symptoms & mood',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _summariseLog(DayLog log) {
    final parts = <String>[];
    if (log.flow != 'none') parts.add('Flow: ${log.flow}');
    if (log.mood.isNotEmpty) parts.add('Mood: ${log.mood}');
    if (log.symptoms.isNotEmpty) parts.add(log.symptoms.join(', '));
    if (log.note.isNotEmpty) parts.add('“${log.note}”');
    return parts.isEmpty ? 'Tap to edit' : parts.join(' · ');
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
                  decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.edit_calendar,
                      color: Colors.pink.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Your Cycle Info',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickAndLogPeriodStart,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.pink.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: isDark
                      ? Colors.pink.shade900.withValues(alpha: 0.2)
                      : Colors.pink.shade50,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.water_drop, color: Colors.pink.shade400),
                    const SizedBox(width: 10),
                    Text(
                      _lastPeriodStart != null
                          ? 'Last period: ${DateFormat('dd MMM yyyy').format(_lastPeriodStart!)}'
                          : 'Tap to log period start',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _lastPeriodStart != null ? null : Colors.grey),
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
                      Row(
                        children: [
                          Text('Cycle: $_cycleLength days',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          if (_cycleAuto) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(6)),
                              child: const Text('AUTO',
                                  style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      Slider(
                        value: _cycleLength.toDouble().clamp(21, 40),
                        min: 21,
                        max: 40,
                        divisions: 19,
                        activeColor: Colors.pink,
                        onChanged: _cycleAuto
                            ? null
                            : (v) {
                                setState(() => _manualCycleLength = v.round());
                                CycleLogService.setCycleLength(v.round());
                                _reschedule();
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Period: $_periodLength days',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      Slider(
                        value: _periodLength.toDouble(),
                        min: 2,
                        max: 8,
                        divisions: 6,
                        activeColor: Colors.red,
                        onChanged: (v) {
                          setState(() => _periodLength = v.round());
                          CycleLogService.setPeriodLength(v.round());
                          _reschedule();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_cycleAuto)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Cycle length is learned from your ${_periodStarts.length} logged periods.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
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
        gradient: LinearGradient(
            colors: [Colors.pink.shade300, Colors.pink.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('Day', style: TextStyle(fontSize: 14, color: Colors.white70)),
          Text('$_dayInCycle',
              style: const TextStyle(
                  fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
          Text('of your cycle',
              style: TextStyle(
                  fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMiniStat('$_cycleLength', 'Day Cycle'),
              _buildMiniStat('$_periodLength', 'Day Period'),
              _buildMiniStat(_daysUntilNext > 0 ? '${_daysUntilNext}d' : 'Today!',
                  'Until Next'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
        phaseDesc =
            'Your period is here. Rest, stay hydrated, and use heat for cramps. Iron-rich foods help replenish blood loss.';
        break;
      case 'Follicular Phase':
        phaseColor = Colors.green;
        phaseIcon = Icons.eco;
        phaseDesc =
            'Energy is rising! Estrogen is building. Great time for exercise, social activities, and starting new projects.';
        break;
      case 'Ovulation Phase':
        phaseColor = Colors.purple;
        phaseIcon = Icons.auto_awesome;
        phaseDesc =
            'Peak fertility! You\'re most likely to conceive in this window. Libido and energy are at their highest.';
        break;
      default:
        phaseColor = Colors.orange;
        phaseIcon = Icons.nights_stay;
        phaseDesc =
            'Progesterone is dominant. You may experience PMS symptoms. Focus on self-care, gentle exercise, and mood management.';
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
                  decoration: BoxDecoration(
                      color: phaseColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(phaseIcon, color: phaseColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Phase',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(phase,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: phaseColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(phaseDesc,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
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
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isSoon || isToday
              ? BorderSide(color: Colors.red.shade300)
              : BorderSide.none),
      color: isSoon || isToday
          ? (isDark ? Colors.red.shade900.withValues(alpha: 0.2) : Colors.red.shade50)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: (isSoon || isToday ? Colors.red : Colors.pink)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(
                  isToday
                      ? Icons.circle
                      : (isSoon ? Icons.notifications_active : Icons.event),
                  color: isToday
                      ? Colors.red
                      : (isSoon ? Colors.orange : Colors.pink),
                  size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Next Period',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  if (_nextPeriod != null)
                    Text(DateFormat('dd MMM yyyy').format(_nextPeriod!),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  if (isToday)
                    const Text('Expected today!',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w600))
                  else if (isSoon)
                    Text('In $daysLeft days — get ready!',
                        style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 12))
                  else if (daysLeft > 0)
                    Text('In $daysLeft days',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            if (_nextPeriodEnd != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Ends',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(DateFormat('dd MMM').format(_nextPeriodEnd!),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
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
              decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.auto_awesome,
                  color: isClose
                      ? Colors.purple
                      : (isPast ? Colors.grey : Colors.purple.shade300),
                  size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ovulation Day',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  if (_ovulationDay != null)
                    Text(DateFormat('dd MMM yyyy').format(_ovulationDay!),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  if (isPast)
                    const Text('Passed this cycle',
                        style: TextStyle(fontSize: 12, color: Colors.grey))
                  else if (isClose)
                    const Text('Ovulation is very close!',
                        style: TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.w600,
                            fontSize: 12))
                  else
                    Text('In $daysUntil days',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
        side: _inFertileWindow
            ? BorderSide(color: Colors.green.shade400, width: 2)
            : BorderSide.none,
      ),
      color: _inFertileWindow
          ? (isDark ? Colors.green.shade900.withValues(alpha: 0.2) : Colors.green.shade50)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite,
                    color: _inFertileWindow ? Colors.green : Colors.pink),
                const SizedBox(width: 8),
                Text('Fertile Window',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _inFertileWindow ? Colors.green : null)),
                if (_inFertileWindow) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('ACTIVE NOW',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (_fertileStart != null && _fertileEnd != null)
              Text(
                  '${DateFormat('dd MMM').format(_fertileStart!)} — ${DateFormat('dd MMM yyyy').format(_fertileEnd!)}',
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

  Widget _buildRemindersCard(bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.pink.shade400),
                const SizedBox(width: 10),
                const Text('Reminders',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: Colors.pink,
              title: const Text('Period & fertile alerts'),
              subtitle: const Text(
                  'Get notified before your period, and on fertile/ovulation days'),
              value: _remindersEnabled,
              onChanged: _toggleReminders,
            ),
            if (_remindersEnabled)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    const Text('Remind me', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _daysBefore,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 day before')),
                        DropdownMenuItem(value: 2, child: Text('2 days before')),
                        DropdownMenuItem(value: 3, child: Text('3 days before')),
                      ],
                      onChanged: (v) {
                        if (v != null) _setDaysBefore(v);
                      },
                    ),
                  ],
                ),
              ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: Colors.pink,
              title: const Text('Daily log reminder'),
              subtitle: Text(
                  'Nudge me to log at ${TimeOfDay(hour: _logHour, minute: _logMinute).format(context)}'),
              value: _logReminderEnabled,
              onChanged: _toggleLogReminder,
            ),
            if (_logReminderEnabled)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickLogTime,
                  icon: const Icon(Icons.access_time, size: 18),
                  label: const Text('Change time'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(bool isDark) {
    final recent = _periodStarts.reversed.take(8).toList();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.pink.shade400),
                const SizedBox(width: 10),
                const Text('Period History',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Text('${_periodStarts.length} logged',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              Text('No periods logged yet.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600))
            else
              ...List.generate(recent.length, (i) {
                final d = recent[i];
                // Gap to the previous (older) start, if any.
                final idx = _periodStarts.indexOf(d);
                final gap = idx > 0
                    ? d.difference(_periodStarts[idx - 1]).inDays
                    : null;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.water_drop,
                      color: Colors.red, size: 20),
                  title: Text(DateFormat('EEE, dd MMM yyyy').format(d)),
                  subtitle:
                      gap != null ? Text('$gap-day cycle') : const Text('First logged'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: Colors.grey,
                    onPressed: () => _removePeriodStart(d),
                  ),
                );
              }),
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
    final loggedDays = <int>{};

    // Actual logged period-start days this month.
    for (final s in _periodStarts) {
      for (int d = 0; d < _periodLength; d++) {
        final day = s.add(Duration(days: d));
        if (day.month == now.month && day.year == now.year) {
          periodDays.add(day.day);
        }
      }
    }

    // Predicted cycles based on the most recent start.
    if (_lastPeriodStart != null) {
      for (int cycle = 0; cycle <= 3; cycle++) {
        final cycleStart =
            _lastPeriodStart!.add(Duration(days: _cycleLength * cycle));
        for (int d = 0; d < _periodLength; d++) {
          final day = cycleStart.add(Duration(days: d));
          if (day.month == now.month && day.year == now.year) {
            periodDays.add(day.day);
          }
        }
        final ov = cycleStart.add(Duration(days: _cycleLength - 14));
        if (ov.month == now.month && ov.year == now.year) {
          ovulationDay.add(ov.day);
        }
        for (int d = -5; d <= 1; d++) {
          final day = ov.add(Duration(days: d));
          if (day.month == now.month && day.year == now.year) {
            fertileDays.add(day.day);
          }
        }
      }
    }

    // Days with any symptom/mood log this month.
    _dayLogs.forEach((k, log) {
      final d = DateTime.tryParse(k);
      if (d != null && d.month == now.month && d.year == now.year) {
        loggedDays.add(d.day);
      }
    });

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('MMMM yyyy').format(now),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map((d) => Expanded(
                      child: Center(
                          child: Text(d,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600)))))
                  .toList(),
            ),
            const SizedBox(height: 4),
            ...List.generate((daysInMonth + firstWeekday + 6) ~/ 7, (week) {
              return Row(
                children: List.generate(7, (dow) {
                  final dayNum = week * 7 + dow - firstWeekday + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 40));
                  }
                  final isPeriod = periodDays.contains(dayNum);
                  final isFertile = fertileDays.contains(dayNum);
                  final isOvulation = ovulationDay.contains(dayNum);
                  final isLogged = loggedDays.contains(dayNum);
                  final isToday = dayNum == now.day;

                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _openLogSheet(
                          DateTime(now.year, now.month, dayNum)),
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isPeriod
                              ? Colors.red.shade100
                              : (isOvulation
                                  ? Colors.purple.shade100
                                  : (isFertile ? Colors.green.shade50 : null)),
                          borderRadius: BorderRadius.circular(8),
                          border: isToday
                              ? Border.all(color: Colors.pink, width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$dayNum',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      isToday ? FontWeight.bold : FontWeight.normal,
                                  color: isPeriod
                                      ? Colors.red.shade700
                                      : (isOvulation
                                          ? Colors.purple.shade700
                                          : (isFertile
                                              ? Colors.green.shade700
                                              : null)),
                                )),
                            if (isLogged)
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: const BoxDecoration(
                                    color: Colors.pink, shape: BoxShape.circle),
                              ),
                          ],
                        ),
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
                _buildLegend(Colors.pink, 'Logged'),
              ],
            ),
            const SizedBox(height: 4),
            Text('Tap any day to add or edit a log.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }
}

/// Bottom sheet for logging one day's flow, symptoms, mood and a note.
class _LogSheet extends StatefulWidget {
  final DateTime date;
  final DayLog initial;
  const _LogSheet({required this.date, required this.initial});

  @override
  State<_LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends State<_LogSheet> {
  late String _flow;
  late Set<String> _symptoms;
  late String _mood;
  late TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _flow = widget.initial.flow;
    _symptoms = widget.initial.symptoms.toSet();
    _mood = widget.initial.mood;
    _note = TextEditingController(text: widget.initial.note);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  IconData _flowIcon(String f) {
    switch (f) {
      case 'spotting':
        return Icons.circle;
      case 'light':
        return Icons.water_drop_outlined;
      case 'medium':
        return Icons.water_drop;
      case 'heavy':
        return Icons.opacity;
      default:
        return Icons.block;
    }
  }

  IconData _moodIcon(String m) {
    switch (m) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'calm':
        return Icons.sentiment_satisfied;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'anxious':
        return Icons.sentiment_neutral;
      case 'irritable':
        return Icons.sentiment_very_dissatisfied;
      case 'energetic':
        return Icons.bolt;
      default:
        return Icons.mood;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('EEEE, dd MMM yyyy').format(widget.date),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Flow', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: CycleLogService.flows.map((f) {
                final selected = _flow == f;
                return ChoiceChip(
                  avatar: Icon(_flowIcon(f),
                      size: 16,
                      color: selected ? Colors.white : Colors.red.shade400),
                  label: Text(f[0].toUpperCase() + f.substring(1)),
                  selected: selected,
                  selectedColor: Colors.red.shade400,
                  labelStyle:
                      TextStyle(color: selected ? Colors.white : null, fontSize: 12),
                  onSelected: (_) => setState(() => _flow = f),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Symptoms', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: CycleLogService.symptomOptions.map((s) {
                final selected = _symptoms.contains(s);
                return FilterChip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  selectedColor: Colors.pink.shade100,
                  checkmarkColor: Colors.pink.shade700,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _symptoms.add(s);
                    } else {
                      _symptoms.remove(s);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Mood', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: CycleLogService.moodOptions.map((m) {
                final selected = _mood == m;
                return ChoiceChip(
                  avatar: Icon(_moodIcon(m),
                      size: 16,
                      color: selected ? Colors.white : Colors.purple.shade400),
                  label: Text(m[0].toUpperCase() + m.substring(1)),
                  selected: selected,
                  selectedColor: Colors.purple.shade400,
                  labelStyle:
                      TextStyle(color: selected ? Colors.white : null, fontSize: 12),
                  onSelected: (_) =>
                      setState(() => _mood = selected ? '' : m),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Anything else you want to remember...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.pink),
                onPressed: () {
                  Navigator.pop(
                    context,
                    DayLog(
                      date: CycleLogService.dateKey(widget.date),
                      flow: _flow,
                      symptoms: _symptoms.toList(),
                      mood: _mood,
                      note: _note.text.trim(),
                    ),
                  );
                },
                child: const Text('Save log'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
