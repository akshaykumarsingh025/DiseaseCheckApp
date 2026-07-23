import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/notification_service.dart';
import '../services/wellness_log_service.dart';

class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  WellnessEntry _today = const WellnessEntry();
  int _waterGoal = WellnessLogService.defaultWaterGoal;
  double _sleepGoal = WellnessLogService.defaultSleepGoal;
  int _stepsGoal = WellnessLogService.defaultStepsGoal;
  int _streak = 0;
  List<(DateTime, WellnessEntry)> _week = [];

  bool _reminderEnabled = false;
  int _reminderHour = 9;
  int _reminderMinute = 0;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = await WellnessLogService.getEntry(DateTime.now());
    final wg = await WellnessLogService.waterGoal();
    final sg = await WellnessLogService.sleepGoal();
    final stg = await WellnessLogService.stepsGoal();
    final streak = await WellnessLogService.waterStreak();
    final week = await WellnessLogService.lastDays(7);
    final rem = await WellnessLogService.reminderEnabled();
    final (h, m) = await WellnessLogService.reminderTime();
    if (!mounted) return;
    setState(() {
      _today = today;
      _waterGoal = wg;
      _sleepGoal = sg;
      _stepsGoal = stg;
      _streak = streak;
      _week = week;
      _reminderEnabled = rem;
      _reminderHour = h;
      _reminderMinute = m;
      _loading = false;
    });
  }

  Future<void> _refreshDerived() async {
    final streak = await WellnessLogService.waterStreak();
    final week = await WellnessLogService.lastDays(7);
    if (!mounted) return;
    setState(() {
      _streak = streak;
      _week = week;
    });
  }

  Future<void> _addWater(int delta) async {
    final next = await WellnessLogService.addWater(DateTime.now(), delta);
    setState(() => _today = next);
    await _refreshDerived();
  }

  Future<void> _setSleep(double h) async {
    final next = await WellnessLogService.setSleep(DateTime.now(), h);
    setState(() => _today = next);
    await _refreshDerived();
  }

  Future<void> _editSteps() async {
    final controller =
        TextEditingController(text: _today.steps > 0 ? '${_today.steps}' : '');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log steps'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'e.g. 6500', suffixText: 'steps'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(controller.text.trim()) ?? 0),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      final next = await WellnessLogService.setSteps(DateTime.now(), result);
      setState(() => _today = next);
      await _refreshDerived();
    }
  }

  Future<void> _toggleReminder(bool v) async {
    setState(() => _reminderEnabled = v);
    await WellnessLogService.setReminder(v, _reminderHour, _reminderMinute);
    if (v) {
      await NotificationService.scheduleDailyWellnessReminder(
          hour: _reminderHour, minute: _reminderMinute);
    } else {
      await NotificationService.cancelDailyWellnessReminder();
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute));
    if (picked != null) {
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinute = picked.minute;
      });
      await WellnessLogService.setReminder(
          _reminderEnabled, _reminderHour, _reminderMinute);
      if (_reminderEnabled) {
        await NotificationService.scheduleDailyWellnessReminder(
            hour: _reminderHour, minute: _reminderMinute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Wellness')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Wellness')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _streakBanner(),
            const SizedBox(height: 16),
            _waterCard(),
            const SizedBox(height: 16),
            _sleepCard(),
            const SizedBox(height: 16),
            _stepsCard(),
            const SizedBox(height: 16),
            _weeklyCard(),
            const SizedBox(height: 16),
            _reminderCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _streakBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.cyan.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department,
              color: Colors.orangeAccent, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_streak-day hydration streak',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(
                    _streak == 0
                        ? 'Hit your water goal today to start a streak!'
                        : 'Keep it going — log your water every day.',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _waterCard() {
    final pct = _waterGoal == 0 ? 0.0 : (_today.water / _waterGoal).clamp(0, 1);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Water',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Text('${_today.water} / $_waterGoal glasses',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct.toDouble(),
                minHeight: 10,
                backgroundColor: Colors.blue.shade50,
                valueColor: const AlwaysStoppedAnimation(Colors.blue),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _roundBtn(Icons.remove, () => _addWater(-1)),
                const SizedBox(width: 24),
                Text('${_today.water}',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(width: 24),
                _roundBtn(Icons.add, () => _addWater(1)),
              ],
            ),
            if (_today.water >= _waterGoal)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Goal reached! 💧',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.blue.shade50,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.blue, size: 24),
        ),
      ),
    );
  }

  Widget _sleepCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bedtime, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text('Sleep',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Text('${_today.sleep.toStringAsFixed(1)} h',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
            Slider(
              value: _today.sleep.clamp(0, 16),
              min: 0,
              max: 16,
              divisions: 32,
              activeColor: Colors.indigo,
              label: '${_today.sleep.toStringAsFixed(1)} h',
              onChanged: (v) => setState(
                  () => _today = _today.copyWith(sleep: v)),
              onChangeEnd: _setSleep,
            ),
            Text(
              _today.sleep >= _sleepGoal
                  ? 'Well rested! Goal is ${_sleepGoal.toStringAsFixed(0)} h.'
                  : 'Aim for ${_sleepGoal.toStringAsFixed(0)} hours of sleep.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepsCard() {
    final pct = _stepsGoal == 0 ? 0.0 : (_today.steps / _stepsGoal).clamp(0, 1);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _editSteps,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_walk, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text('Steps',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  Text('${_today.steps} / $_stepsGoal',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct.toDouble(),
                  minHeight: 10,
                  backgroundColor: Colors.green.shade50,
                  valueColor: const AlwaysStoppedAnimation(Colors.green),
                ),
              ),
              const SizedBox(height: 8),
              Text('Tap to log your step count for today.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weeklyCard() {
    final maxWater = _week.fold<int>(
        1, (m, e) => e.$2.water > m ? e.$2.water : m);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This week — water',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _week.map((e) {
                  final ratio = e.$2.water / maxWater;
                  final met = e.$2.water >= _waterGoal;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${e.$2.water}',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade600)),
                        const SizedBox(height: 2),
                        Container(
                          height: (ratio * 80).clamp(4, 80),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: met ? Colors.blue : Colors.blue.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(DateFormat('E').format(e.$1).substring(0, 1),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reminderCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            SwitchListTile(
              activeThumbColor: Colors.blue,
              title: const Text('Daily wellness reminder'),
              subtitle: Text(
                  'Remind me to log at ${TimeOfDay(hour: _reminderHour, minute: _reminderMinute).format(context)}'),
              value: _reminderEnabled,
              onChanged: _toggleReminder,
            ),
            if (_reminderEnabled)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickReminderTime,
                  icon: const Icon(Icons.access_time, size: 18),
                  label: const Text('Change time'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
