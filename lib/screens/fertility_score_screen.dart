import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FertilityScoreScreen extends ConsumerStatefulWidget {
  const FertilityScoreScreen({super.key});

  @override
  ConsumerState<FertilityScoreScreen> createState() => _FertilityScoreScreenState();
}

class _FertilityScoreScreenState extends ConsumerState<FertilityScoreScreen> {
  int _step = 0;
  final List<int?> _answers = List.filled(12, null);
  bool _showResult = false;

  final List<_FertilityQuestion> _questions = const [
    _FertilityQuestion('Age Group', 'Your age significantly affects fertility.', Icons.cake, [
      'Under 30',
      '30 – 34',
      '35 – 37',
      '38 – 40',
      'Over 40',
    ]),
    _FertilityQuestion('Cycle Regularity', 'Regular cycles indicate consistent ovulation.', Icons.sync, [
      'Very regular (same length ±1 day)',
      'Mostly regular (±2-3 days)',
      'Somewhat irregular (±4-7 days)',
      'Very irregular or absent',
    ]),
    _FertilityQuestion('Average Cycle Length', 'Optimal fertility is around 28 days.', Icons.timeline, [
      '25 – 28 days',
      '29 – 35 days',
      'Less than 25 days',
      'More than 35 days',
      'Unpredictable',
    ]),
    _FertilityQuestion('Period Flow', 'Very light or very heavy periods may indicate issues.', Icons.water_drop, [
      'Normal flow (3-5 days, moderate)',
      'Light flow (1-2 days or very light)',
      'Heavy flow (soaking through in 1-2 hours)',
      'Irregular/variable flow',
    ]),
    _FertilityQuestion('Pain During Periods', 'Severe pain may indicate endometriosis or fibroids.', Icons.healing, [
      'No pain or mild discomfort',
      'Moderate cramps (manageable with OTC meds)',
      'Severe pain (misses work/school, needs prescription)',
    ]),
    _FertilityQuestion('BMI Range', 'Both underweight and overweight affect fertility.', Icons.monitor_weight, [
      'Normal BMI (18.5 – 24.9)',
      'Slightly under/over (17-18.4 or 25-29.9)',
      'Underweight (<17) or Obese (30-34.9)',
      'Severely obese (35+)',
    ]),
    _FertilityQuestion('Lifestyle: Smoking', 'Smoking reduces fertility by up to 50%.', Icons.smoke_free, [
      'Never smoked',
      'Former smoker (quit 1+ year ago)',
      'Current smoker',
    ]),
    _FertilityQuestion('Lifestyle: Alcohol', 'Regular alcohol consumption affects conception.', Icons.local_bar, [
      'None or very rare',
      '1-2 drinks per week',
      '3-6 drinks per week',
      'Daily or binge drinking',
    ]),
    _FertilityQuestion('Lifestyle: Exercise', 'Both too much and too little exercise affect fertility.', Icons.fitness_center, [
      'Moderate exercise (3-5x/week, 30 min)',
      'Light exercise (1-2x/week)',
      'Sedentary (no regular exercise)',
      'Intense/competitive athletics',
    ]),
    _FertilityQuestion('Stress Level', 'Chronic stress disrupts hormonal balance.', Icons.psychology, [
      'Low stress (good work-life balance)',
      'Moderate stress (manageable)',
      'High stress (frequent anxiety/insomnia)',
      'Very high (burnout, chronic anxiety)',
    ]),
    _FertilityQuestion('Previous Pregnancies', 'History of pregnancy (even miscarriage) provides information.', Icons.pregnant_woman, [
      'At least one full-term pregnancy',
      'At least one pregnancy (miscarriage/ectopic)',
      'Trying but never pregnant',
      'Not actively trying before now',
    ]),
    _FertilityQuestion('Known Conditions', 'Certain conditions directly impact fertility.', Icons.medical_information, [
      'None known',
      'PCOS or endometriosis (diagnosed)',
      'Thyroid disorder',
      'Diabetes or insulin resistance',
    ]),
  ];

  int get _score {
    int s = 0;
    for (int i = 0; i < _answers.length; i++) {
      if (_answers[i] == null) continue;
      s += _answers[i]!;
    }
    return s;
  }

  int get _maxScore {
    int m = 0;
    for (var q in _questions) {
      m += q.options.length - 1;
    }
    return m;
  }

  int get _fertilityPercent {
    final riskPct = (_score / _maxScore * 100).round();
    return (100 - riskPct).clamp(0, 100);
  }

  String get _fertilityLevel {
    final p = _fertilityPercent;
    if (p >= 80) return 'Excellent';
    if (p >= 60) return 'Good';
    if (p >= 40) return 'Fair';
    if (p >= 20) return 'Concerning';
    return 'Low';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fertility Score'),
        backgroundColor: isDark ? Colors.teal.shade900 : Colors.teal.shade50,
      ),
      body: SafeArea(
        child: _showResult ? _buildResult(isDark) : _buildQuestionnaire(isDark),
      ),
    );
  }

  Widget _buildQuestionnaire(bool isDark) {
    final q = _questions[_step];
    final progress = (_step + 1) / _questions.length;

    return Column(
      children: [
        LinearProgressIndicator(value: progress, backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200, color: Colors.teal, minHeight: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_step + 1}/${_questions.length}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.teal)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.teal.shade400, Colors.teal.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(q.icon, size: 36, color: Colors.white),
                      const SizedBox(height: 10),
                      Text(q.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 6),
                      Text(q.description, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)), textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...q.options.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final label = entry.value;
                  final isSelected = _answers[_step] == idx;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      elevation: isSelected ? 2 : 0,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => setState(() => _answers[_step] = idx),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.teal.withValues(alpha: 0.1) : (isDark ? Colors.grey.shade800 : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? Colors.teal : (isDark ? Colors.grey.shade700 : Colors.grey.shade300), width: isSelected ? 2 : 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? Colors.teal : Colors.transparent,
                                  border: Border.all(color: isSelected ? Colors.teal : Colors.grey),
                                ),
                                child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? Colors.teal : null))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(child: OutlinedButton(onPressed: () => setState(() => _step--), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Back'))),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _answers[_step] != null
                        ? () {
                            if (_step < _questions.length - 1) {
                              setState(() => _step++);
                            } else {
                              setState(() => _showResult = true);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text(_step < _questions.length - 1 ? 'Next' : 'See Score'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult(bool isDark) {
    final pct = _fertilityPercent;
    final level = _fertilityLevel;

    Color scoreColor;
    if (pct >= 80) scoreColor = Colors.green;
    else if (pct >= 60) scoreColor = Colors.teal;
    else if (pct >= 40) scoreColor = Colors.orange;
    else if (pct >= 20) scoreColor = Colors.deepOrange;
    else scoreColor = Colors.red;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [scoreColor.withValues(alpha: 0.7), scoreColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.favorite, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text('Your Fertility Score', style: TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 8),
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(value: pct / 100, strokeWidth: 10, backgroundColor: Colors.white.withValues(alpha: 0.2), valueColor: const AlwaysStoppedAnimation<Color>(Colors.white)),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$pct', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                            const Text('/ 100', style: TextStyle(fontSize: 12, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(level, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildBreakdownCard(isDark),
          const SizedBox(height: 16),
          _buildRecommendationsCard(isDark, pct),
          const SizedBox(height: 16),
          Card(
            color: isDark ? Colors.red.shade900.withValues(alpha: 0.2) : Colors.red.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.medical_services, color: Colors.red.shade700),
                  const SizedBox(width: 10),
                  Expanded(child: Text('This is a wellness assessment, not a medical diagnosis. Consult a fertility specialist for comprehensive evaluation including AMH, FSH, and antral follicle count.', style: TextStyle(fontSize: 12, color: Colors.red.shade900))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _showResult = false;
                    _step = 0;
                    for (int i = 0; i < _answers.length; i++) _answers[i] = null;
                  }),
                  icon: const Icon(Icons.refresh), label: const Text('Retake'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/womens-health'),
                  icon: const Icon(Icons.monitor_heart), label: const Text('Women\'s Health Hub'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(bool isDark) {
    final categories = <String, int>{};
    categories['Age'] = _answers[0] ?? 0;
    categories['Cycle'] = ((_answers[1] ?? 0) + (_answers[2] ?? 0)) ~/ 2;
    categories['Period Health'] = (_answers[3] ?? 0) + (_answers[4] ?? 0);
    categories['BMI & Lifestyle'] = (_answers[5] ?? 0) + (_answers[6] ?? 0) + (_answers[7] ?? 0) + (_answers[8] ?? 0);
    categories['Stress & History'] = (_answers[9] ?? 0) + (_answers[10] ?? 0) + (_answers[11] ?? 0);

    final maxPerCat = <String, int>{};
    maxPerCat['Age'] = 4;
    maxPerCat['Cycle'] = 3;
    maxPerCat['Period Health'] = 5;
    maxPerCat['BMI & Lifestyle'] = 10;
    maxPerCat['Stress & History'] = 8;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.teal.shade700),
                const SizedBox(width: 8),
                const Text('Score Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            ...categories.entries.map((e) {
              final score = e.value;
              final max = maxPerCat[e.key] ?? 5;
              final pct = ((max - score) / max * 100).round().clamp(0, 100);
              Color color;
              if (pct >= 70) color = Colors.green;
              else if (pct >= 40) color = Colors.orange;
              else color = Colors.red;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        Text('$pct%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: pct / 100, minHeight: 6, backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(color)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(bool isDark, int pct) {
    final recs = <String>[];
    if (_answers[0] != null && _answers[0]! >= 3) recs.add('Age is a significant fertility factor. Consider consulting a fertility specialist sooner rather than later.');
    if (_answers[1] != null && _answers[1]! >= 2) recs.add('Irregular cycles suggest irregular ovulation. Track ovulation with OPKs or BBT charting.');
    if (_answers[5] != null && _answers[5]! >= 2) recs.add('BMI outside the normal range affects ovulation. Even small changes in weight can improve fertility.');
    if (_answers[6] != null && _answers[6]! >= 1) recs.add('Quit smoking — it accelerates egg loss and reduces IVF success rates by up to 50%.');
    if (_answers[8] != null && _answers[8]! >= 2) recs.add('Both too much and too little exercise can disrupt ovulation. Aim for moderate, consistent activity.');
    if (_answers[9] != null && _answers[9]! >= 2) recs.add('Stress management (yoga, meditation, counseling) can improve hormonal balance and ovulation regularity.');
    if (_answers[11] != null && _answers[11]! >= 1) recs.add('Known conditions like PCOS or thyroid issues need medical management for optimal fertility.');
    if (recs.isEmpty) recs.add('Your fertility wellness looks good! Continue maintaining a healthy lifestyle and track your cycle regularly.');
    recs.add('For a complete fertility assessment, request AMH, FSH, LH, and antral follicle count from your gynecologist.');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.recommend, color: Colors.teal.shade700),
                const SizedBox(width: 8),
                const Text('Recommendations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            ...recs.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Expanded(child: Text(r, style: const TextStyle(fontSize: 13))),
              ]),
            )),
          ],
        ),
      ),
    );
  }
}

class _FertilityQuestion {
  final String title;
  final String description;
  final IconData icon;
  final List<String> options;
  const _FertilityQuestion(this.title, this.description, this.icon, this.options);
}
