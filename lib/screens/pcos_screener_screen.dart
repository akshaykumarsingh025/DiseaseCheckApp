import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PcosScreenerScreen extends ConsumerStatefulWidget {
  const PcosScreenerScreen({super.key});

  @override
  ConsumerState<PcosScreenerScreen> createState() => _PcosScreenerScreenState();
}

class _PcosScreenerScreenState extends ConsumerState<PcosScreenerScreen> {
  int _currentQuestion = 0;
  final List<int?> _answers = List.filled(10, null);
  bool _showResult = false;

  final List<_PcosQuestion> _questions = const [
    _PcosQuestion(
      id: 0,
      question: 'Do you have irregular, infrequent, or absent menstrual periods?',
      description: 'Cycles longer than 35 days, fewer than 8 periods/year, or no periods',
      icon: Icons.calendar_month,
      rotterdam: 'Rotterdam Criterion 1: Oligo/Anovulation',
    ),
    _PcosQuestion(
      id: 1,
      question: 'Do you have excess facial or body hair (hirsutism)?',
      description: 'Hair growth on chin, upper lip, chest, abdomen, or thighs',
      icon: Icons.face,
      rotterdam: 'Rotterdam Criterion 2: Clinical Hyperandrogenism',
    ),
    _PcosQuestion(
      id: 2,
      question: 'Have you experienced significant acne (especially adult acne)?',
      description: 'Persistent acne along jawline, chin, or lower face after teenage years',
      icon: Icons.face_retouching_natural,
      rotterdam: 'Rotterdam Criterion 2: Clinical Hyperandrogenism',
    ),
    _PcosQuestion(
      id: 3,
      question: 'Have you noticed thinning hair or hair loss on your scalp?',
      description: 'Male-pattern baldness, widening part, or overall reduced hair volume',
      icon: Icons.content_cut,
      rotterdam: 'Rotterdam Criterion 2: Clinical Hyperandrogenism',
    ),
    _PcosQuestion(
      id: 4,
      question: 'Have you been told you have polycystic ovaries on ultrasound?',
      description: '12+ follicles in each ovary or enlarged ovaries detected on scan',
      icon: Icons.monitor_heart,
      rotterdam: 'Rotterdam Criterion 3: Polycystic Ovarian Morphology',
    ),
    _PcosQuestion(
      id: 5,
      question: 'Do you have difficulty losing weight or unexplained weight gain?',
      description: 'Especially around the abdomen, despite diet and exercise efforts',
      icon: Icons.monitor_weight,
      rotterdam: 'Supporting: Metabolic Feature',
    ),
    _PcosQuestion(
      id: 6,
      question: 'Do you experience dark patches of skin (acanthosis nigricans)?',
      description: 'Dark, velvety patches on neck, armpits, or groin — a sign of insulin resistance',
      icon: Icons.back_hand,
      rotterdam: 'Supporting: Insulin Resistance Marker',
    ),
    _PcosQuestion(
      id: 7,
      question: 'Do you have intense cravings for carbs or sugar?',
      description: 'Insulin resistance can drive sugar/carbohydrate cravings',
      icon: Icons.cake,
      rotterdam: 'Supporting: Metabolic Feature',
    ),
    _PcosQuestion(
      id: 8,
      question: 'Do you experience mood swings, anxiety, or depression?',
      description: 'Hormonal imbalances and PCOS are strongly linked to mood changes',
      icon: Icons.mood_bad,
      rotterdam: 'Supporting: Hormonal/Quality of Life',
    ),
    _PcosQuestion(
      id: 9,
      question: 'Have you had difficulty conceiving or been diagnosed with infertility?',
      description: 'Irregular ovulation is a leading cause of subfertility in PCOS',
      icon: Icons.child_care,
      rotterdam: 'Supporting: Reproductive Outcome',
    ),
  ];

  bool get _canProceed => _answers[_currentQuestion] != null;

  int get _totalScore {
    int score = 0;
    for (int i = 0; i < _answers.length; i++) {
      if (_answers[i] == null) continue;
      if (i <= 0) score += _answers[i]! * 3;
      else if (i <= 3) score += _answers[i]! * 3;
      else if (i == 4) score += _answers[i]! * 3;
      else score += _answers[i]! * 2;
    }
    return score;
  }

  int get _maxScore {
    int max = 0;
    for (int i = 0; i < 10; i++) {
      if (i <= 0) max += 9;
      else if (i <= 4) max += 9;
      else max += 6;
    }
    return max;
  }

  String get _riskLevel {
    final pct = (_totalScore / _maxScore * 100).round();
    if (pct >= 70) return 'High';
    if (pct >= 40) return 'Moderate';
    return 'Low';
  }

  int get _rotterdamCount {
    int count = 0;
    if (_answers[0] != null && _answers[0]! >= 2) count++;
    if ((_answers[1] != null && _answers[1]! >= 2) ||
        (_answers[2] != null && _answers[2]! >= 2) ||
        (_answers[3] != null && _answers[3]! >= 2)) count++;
    if (_answers[4] != null && _answers[4]! >= 2) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PCOS Risk Screener'),
        backgroundColor: isDark ? Colors.purple.shade900 : Colors.purple.shade50,
        foregroundColor: isDark ? Colors.white : Colors.purple.shade900,
      ),
      body: SafeArea(
        child: _showResult ? _buildResult(isDark) : _buildQuestionnaire(isDark),
      ),
    );
  }

  Widget _buildQuestionnaire(bool isDark) {
    final q = _questions[_currentQuestion];
    final progress = (_currentQuestion + 1) / _questions.length;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          color: Colors.purple,
          minHeight: 4,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question ${_currentQuestion + 1} of ${_questions.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text('${(progress * 100).round()}% complete',
                  style: TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.w600)),
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
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.pink.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(q.icon, size: 40, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(q.question,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(q.description,
                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.science, size: 14, color: Colors.purple.shade700),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(q.rotterdam,
                            style: TextStyle(fontSize: 10, color: Colors.purple.shade700, fontStyle: FontStyle.italic)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ...[0, 1, 2, 3].map((option) {
                  final labels = ['Never / Not at all', 'Mildly / Occasionally', 'Moderately / Noticeable', 'Severely / Very much'];
                  final icons = [Icons.close, Icons.remove, Icons.trending_flat, Icons.warning];
                  final colors = [Colors.green, Colors.lightGreen, Colors.orange, Colors.red];
                  final isSelected = _answers[_currentQuestion] == option;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      elevation: isSelected ? 2 : 0,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => setState(() => _answers[_currentQuestion] = option),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors[option].withValues(alpha: 0.1)
                                : (isDark ? Colors.grey.shade800 : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? colors[option] : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(icons[option], size: 20, color: isSelected ? colors[option] : Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(labels[option],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: isSelected ? colors[option] : null,
                                    )),
                              ),
                              if (isSelected) Icon(Icons.check_circle, color: colors[option], size: 20),
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
                if (_currentQuestion > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentQuestion--),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentQuestion > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _canProceed
                        ? () {
                            if (_currentQuestion < _questions.length - 1) {
                              setState(() => _currentQuestion++);
                            } else {
                              setState(() => _showResult = true);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_currentQuestion < _questions.length - 1 ? 'Next' : 'See Results'),
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
    final pct = (_totalScore / _maxScore * 100).round();
    final risk = _riskLevel;
    final rotterdamMet = _rotterdamCount;
    final likelyPcos = rotterdamMet >= 2;

    Color riskColor;
    IconData riskIcon;
    if (risk == 'High') {
      riskColor = Colors.red;
      riskIcon = Icons.warning;
    } else if (risk == 'Moderate') {
      riskColor = Colors.orange;
      riskIcon = Icons.info;
    } else {
      riskColor = Colors.green;
      riskIcon = Icons.check_circle;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [riskColor.withValues(alpha: 0.8), riskColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(riskIcon, size: 56, color: Colors.white),
                const SizedBox(height: 12),
                const Text('Your PCOS Risk Assessment', style: TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 4),
                Text('$risk Risk', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('$pct% risk score', style: const TextStyle(fontSize: 18, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.science, color: Colors.purple.shade700),
                      const SizedBox(width: 8),
                      const Text('Rotterdam Criteria Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const Divider(),
                  _buildCriterionRow('Oligo/Anovulation', rotterdamMet >= 1 && (_answers[0] ?? 0) >= 2),
                  _buildCriterionRow('Hyperandrogenism', rotterdamMet >= 2 || ((_answers[1] ?? 0) >= 2 || (_answers[2] ?? 0) >= 2 || (_answers[3] ?? 0) >= 2)),
                  _buildCriterionRow('PCOM on Ultrasound', (_answers[4] ?? 0) >= 2),
                  const Divider(),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: likelyPcos ? Colors.orange.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(likelyPcos ? Icons.info : Icons.check, color: likelyPcos ? Colors.orange : Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            likelyPcos
                                ? '$rotterdamMet of 3 Rotterdam criteria met — PCOS diagnosis likely. See a gynecologist for confirmation.'
                                : '$rotterdamMet of 3 Rotterdam criteria met — PCOS diagnosis less likely based on your responses.',
                            style: TextStyle(fontSize: 13, color: likelyPcos ? Colors.orange.shade900 : Colors.green.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.recommend, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text('Personalized Recommendations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const Divider(),
                  ..._getRecommendations().map((r) => Padding(
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
          ),
          const SizedBox(height: 12),
          Card(
            color: isDark ? Colors.red.shade900.withValues(alpha: 0.2) : Colors.red.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.medical_services, color: Colors.red.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This is a screening tool, not a diagnosis. Only a qualified gynecologist can diagnose PCOS using blood tests, ultrasound, and clinical evaluation.',
                      style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                    ),
                  ),
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
                    _currentQuestion = 0;
                    for (int i = 0; i < _answers.length; i++) _answers[i] = null;
                  }),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retake'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/online-opd'),
                  icon: const Icon(Icons.videocam),
                  label: const Text('Consult Doctor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCriterionRow(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(met ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20, color: met ? Colors.green : Colors.grey),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(
            fontWeight: met ? FontWeight.w600 : FontWeight.normal,
            color: met ? null : Colors.grey,
          )),
          const Spacer(),
          if (met)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Met', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  List<String> _getRecommendations() {
    final recs = <String>[];
    if ((_answers[0] ?? 0) >= 2) {
      recs.add('Track your menstrual cycles regularly. Irregular cycles are the #1 sign to discuss with your doctor.');
    }
    if ((_answers[1] ?? 0) >= 2 || (_answers[2] ?? 0) >= 2) {
      recs.add('Ask your doctor about checking total testosterone, free testosterone, and DHEAS levels.');
    }
    if ((_answers[4] ?? 0) >= 2) {
      recs.add('You have polycystic ovaries on ultrasound. Combine this with hormonal tests for a definitive diagnosis.');
    }
    if ((_answers[5] ?? 0) >= 2) {
      recs.add('Weight management is key: even 5-10% weight loss can significantly improve PCOS symptoms and restore ovulation.');
    }
    if ((_answers[6] ?? 0) >= 2) {
      recs.add('Acanthosis nigricans suggests insulin resistance. Request fasting insulin, HOMA-IR, and a glucose tolerance test.');
    }
    if ((_answers[7] ?? 0) >= 2) {
      recs.add('Low glycemic index (GI) diet and regular exercise can help manage cravings driven by insulin resistance.');
    }
    if ((_answers[8] ?? 0) >= 2) {
      recs.add('PCOS is linked to mood disorders. Consider counseling and discuss with your gynecologist or endocrinologist.');
    }
    if ((_answers[9] ?? 0) >= 2) {
      recs.add('Fertility treatment options are available. Early consultation with a reproductive endocrinologist is recommended.');
    }
    if (recs.isEmpty) {
      recs.add('Your responses suggest low PCOS risk. Continue maintaining a healthy lifestyle with regular checkups.');
      recs.add('If you develop any symptoms in the future, retake this screener or consult your doctor.');
    }
    recs.add('Schedule an appointment with Dr. Deepika for a professional evaluation and personalized care plan.');
    return recs;
  }
}

class _PcosQuestion {
  final int id;
  final String question;
  final String description;
  final IconData icon;
  final String rotterdam;

  const _PcosQuestion({
    required this.id,
    required this.question,
    required this.description,
    required this.icon,
    required this.rotterdam,
  });
}
