import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DueDateCalculatorScreen extends StatefulWidget {
  const DueDateCalculatorScreen({super.key});

  @override
  State<DueDateCalculatorScreen> createState() => _DueDateCalculatorScreenState();
}

class _DueDateCalculatorScreenState extends State<DueDateCalculatorScreen> {
  DateTime? _lmpDate;
  int _cycleLength = 28;
  bool _showResult = false;

  DateTime get _edd {
    if (_lmpDate == null) return DateTime.now();
    return _lmpDate!.add(Duration(days: _cycleLength - 21 + 280));
  }

  int get _currentWeek {
    if (_lmpDate == null) return 0;
    final diff = DateTime.now().difference(_lmpDate!).inDays;
    return (diff / 7).floor();
  }

  int get _currentDay {
    if (_lmpDate == null) return 0;
    return DateTime.now().difference(_lmpDate!).inDays;
  }

  int get _daysRemaining {
    if (_lmpDate == null) return 0;
    return _edd.difference(DateTime.now()).inDays;
  }

  String get _trimester {
    final w = _currentWeek;
    if (w <= 13) return 'First Trimester';
    if (w <= 27) return 'Second Trimester';
    return 'Third Trimester';
  }

  List<_Milestone> get _milestones {
    return [
      _Milestone(6, 'Heartbeat detectable', Icons.favorite, Colors.red),
      _Milestone(8, 'Embryo becomes fetus', Icons.child_care, Colors.pink),
      _Milestone(12, 'End of first trimester — risk of miscarriage drops significantly', Icons.check_circle, Colors.green),
      _Milestone(16, 'May feel first movements (quickening)', Icons.waves, Colors.blue),
      _Milestone(20, 'Anatomy scan ultrasound', Icons.monitor_heart, Colors.purple),
      _Milestone(24, 'Viability milestone — baby can survive with NICU care', Icons.local_hospital, Colors.orange),
      _Milestone(28, 'Third trimester begins', Icons.flag, Colors.teal),
      _Milestone(32, 'Baby practices breathing movements', Icons.air, Colors.cyan),
      _Milestone(36, 'Lungs nearly mature — early term', Icons.air, Colors.indigo),
      _Milestone(37, 'Full term — ready for birth', Icons.celebration, Colors.green),
      _Milestone(40, 'Due date!', Icons.baby_changing_station, Colors.pink),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Due Date Calculator'),
        backgroundColor: isDark ? Colors.pink.shade900 : Colors.pink.shade50,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLmpCard(isDark),
              const SizedBox(height: 16),
              _buildCycleLengthCard(isDark),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _lmpDate == null
                    ? null
                    : () => setState(() => _showResult = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Calculate Due Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              if (_showResult && _lmpDate != null) ...[
                const SizedBox(height: 20),
                _buildEddResultCard(isDark),
                const SizedBox(height: 16),
                _buildPregnancyProgressCard(isDark),
                const SizedBox(height: 16),
                _buildMilestonesCard(isDark),
                const SizedBox(height: 16),
                _buildTipsCard(isDark),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLmpCard(bool isDark) {
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_today, color: Colors.pink.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('First Day of Last Period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Select the first day of your last menstrual period (LMP)', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _lmpDate ?? DateTime.now().subtract(const Duration(days: 30)),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) setState(() => _lmpDate = picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _lmpDate != null ? Colors.pink : (isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month, color: _lmpDate != null ? Colors.pink : Colors.grey),
                    const SizedBox(width: 10),
                    Text(
                      _lmpDate != null ? DateFormat('dd MMMM yyyy').format(_lmpDate!) : 'Tap to select date',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _lmpDate != null ? null : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleLengthCard(bool isDark) {
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
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.sync, color: Colors.blue.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Average Cycle Length', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _cycleLength.toDouble(),
                    min: 21,
                    max: 40,
                    divisions: 19,
                    activeColor: Colors.pink,
                    label: '$_cycleLength days',
                    onChanged: (val) => setState(() => _cycleLength = val.round()),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$_cycleLength days', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
                ),
              ],
            ),
            Text('Standard cycle is 28 days. Adjust if yours is shorter or longer.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEddResultCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade400, Colors.pink.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.baby_changing_station, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          const Text('Estimated Due Date', style: TextStyle(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(DateFormat('dd MMMM yyyy').format(_edd), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Week', '$_currentWeek', Icons.calendar_view_week),
              _buildStatCard('Day', '$_currentDay', Icons.today),
              _buildStatCard('Left', '${_daysRemaining > 0 ? _daysRemaining : 0}d', Icons.hourglass_bottom),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_trimester, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _buildPregnancyProgressCard(bool isDark) {
    final progress = (_currentWeek / 40).clamp(0.0, 1.0);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pregnancy Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress < 0.33 ? Colors.blue : (progress < 0.66 ? Colors.green : Colors.orange),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Week 0', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                Text('${(progress * 100).round()}% complete', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.pink)),
                Text('Week 40', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesCard(bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                const Text('Key Milestones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            ..._milestones.map((m) {
              final reached = _currentWeek >= m.week;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: reached ? m.color.withValues(alpha: 0.2) : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                            shape: BoxShape.circle,
                            border: reached ? Border.all(color: m.color, width: 2) : null,
                          ),
                          child: Icon(reached ? m.icon : Icons.circle, size: reached ? 14 : 8, color: reached ? m.color : Colors.grey),
                        ),
                        if (m != _milestones.last)
                          Container(width: 2, height: 20, color: reached ? m.color.withValues(alpha: 0.3) : Colors.grey.shade300),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Week ${m.week}', style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: reached ? m.color : Colors.grey,
                          )),
                          Text(m.label, style: TextStyle(
                            fontSize: 13,
                            color: reached ? null : Colors.grey.shade500,
                            decoration: reached ? null : TextDecoration.lineThrough,
                          )),
                        ],
                      ),
                    ),
                    if (reached) Icon(Icons.check_circle, size: 18, color: m.color),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard(bool isDark) {
    final week = _currentWeek;
    final tips = <String>[];
    if (week <= 13) {
      tips.addAll(['Start taking folic acid (400mcg daily)', 'Avoid alcohol, smoking, and raw fish', 'Schedule your first prenatal visit', 'Stay hydrated and get plenty of rest']);
    } else if (week <= 27) {
      tips.addAll(['Continue prenatal vitamins with iron', 'Start gentle pregnancy exercises', 'Plan your anomaly scan around week 20', 'Track fetal movements daily']);
    } else {
      tips.addAll(['Count kicks — 10 movements in 2 hours', 'Pack your hospital bag', 'Prepare birth plan and share with doctor', 'Watch for signs of preterm labor']);
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
                Icon(Icons.lightbulb, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Text('Tips for $_trimester', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            ...tips.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Expanded(child: Text(t, style: const TextStyle(fontSize: 13))),
              ]),
            )),
          ],
        ),
      ),
    );
  }
}

class _Milestone {
  final int week;
  final String label;
  final IconData icon;
  final Color color;
  const _Milestone(this.week, this.label, this.icon, this.color);
}
