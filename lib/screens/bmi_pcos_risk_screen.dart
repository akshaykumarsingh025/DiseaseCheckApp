import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../utils/bmi_calculator.dart';

class BmiPcosRiskScreen extends ConsumerStatefulWidget {
  const BmiPcosRiskScreen({super.key});

  @override
  ConsumerState<BmiPcosRiskScreen> createState() => _BmiPcosRiskScreenState();
}

class _BmiPcosRiskScreenState extends ConsumerState<BmiPcosRiskScreen> {
  double? _weight;
  double? _height;
  double? _waist;
  int? _age;
  String? _gender;
  bool _showResult = false;

  late TextEditingController _weightCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _waistCtrl;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    if (profile != null) {
      _weight = profile.weight;
      _height = profile.height;
      _age = profile.age;
      _gender = profile.gender;
    }
    _weightCtrl = TextEditingController(text: _weight?.toStringAsFixed(1) ?? '');
    _heightCtrl = TextEditingController(text: _height?.toStringAsFixed(1) ?? '');
    _waistCtrl = TextEditingController(text: _waist?.toStringAsFixed(1) ?? '');
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _waistCtrl.dispose();
    super.dispose();
  }

  double get _bmi {
    if (_weight == null || _height == null || _height! <= 0) return 0;
    return BmiCalculator.calculateBmi(_weight!, _height!);
  }

  String get _bmiCategory => BmiCalculator.getBmiCategory(_bmi);

  String get _pcosRiskLevel {
    if (_bmi < 18.5) return 'Low (but underweight risks exist)';
    if (_bmi < 25) return 'Low';
    if (_bmi < 30) return 'Moderate';
    return 'High';
  }

  double get _metabolicRiskScore {
    double score = 0;
    if (_bmi >= 25 && _bmi < 30) score += 25;
    if (_bmi >= 30) score += 40;
    if (_bmi >= 35) score += 15;
    if (_waist != null && _gender == 'Female' && _waist! >= 80) score += 20;
    if (_waist != null && _gender == 'Female' && _waist! >= 88) score += 10;
    if (_waist != null && _gender == 'Male' && _waist! >= 94) score += 20;
    if (_waist != null && _gender == 'Male' && _waist! >= 102) score += 10;
    if (_age != null && _age! > 35) score += 5;
    return score.clamp(0, 100);
  }

  String get _metabolicRiskLevel {
    final s = _metabolicRiskScore;
    if (s >= 70) return 'High';
    if (s >= 40) return 'Moderate';
    return 'Low';
  }

  List<String> get _recommendations {
    final recs = <String>[];
    if (_bmi < 18.5) {
      recs.add('You are underweight. This can disrupt ovulation and hormone balance. Focus on nutrient-dense foods and consult a dietitian.');
    } else if (_bmi >= 25 && _bmi < 30) {
      recs.add('A 5-10% weight loss can significantly improve PCOS symptoms, restore regular ovulation, and reduce insulin resistance.');
      recs.add('Combine cardio (30 min/day) with strength training (2-3x/week) for best results.');
    } else if (_bmi >= 30) {
      recs.add('Weight management is the most effective treatment for PCOS at your BMI. Even modest weight loss restores menstrual regularity in many women.');
      recs.add('Ask your doctor about metformin — it can improve insulin sensitivity and assist with weight loss.');
      recs.add('Consider a low-GI diet: replace refined carbs with whole grains, lean protein, and healthy fats.');
    } else {
      recs.add('Your BMI is in a healthy range. Maintain your current lifestyle with regular exercise and balanced nutrition.');
    }
    if (_waist != null && _gender == 'Female' && _waist! >= 80) {
      recs.add('Waist circumference ≥80cm indicates central obesity. Abdominal fat drives insulin resistance, the core metabolic issue in PCOS.');
    }
    if (_waist != null && _gender == 'Female' && _waist! >= 88) {
      recs.add('Your waist measurement places you at significantly elevated risk for metabolic syndrome. Request fasting insulin and HOMA-IR tests.');
    }
    recs.add('Schedule regular monitoring of fasting glucose, HbA1c, and lipid profile — PCOS increases long-term diabetes and cardiovascular risk.');
    return recs;
  }

  void _onCheckRisk() {
    // Range validation before showing results.
    if (_weight == null || _weight! < 2 || _weight! > 400) {
      _showRangeError('Please enter a valid weight between 2 and 400 kg.');
      return;
    }
    if (_height == null || _height! < 50 || _height! > 250) {
      _showRangeError('Please enter a valid height between 50 and 250 cm.');
      return;
    }
    if (_waist != null && (_waist! < 30 || _waist! > 200)) {
      _showRangeError('Please enter a valid waist between 30 and 200 cm, or leave it blank.');
      return;
    }
    setState(() => _showResult = true);
  }

  void _showRangeError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI & PCOS Weight Risk'),
        backgroundColor: isDark ? Colors.purple.shade900 : Colors.purple.shade50,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.purple.shade300, Colors.pink.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.monitor_weight, size: 48, color: Colors.white),
                    SizedBox(height: 8),
                    Text('BMI & PCOS Risk Calculator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 4),
                    Text('PCOS-specific metabolic risk scoring', style: TextStyle(fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildInputCard(isDark),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (_weight != null && _height != null && _weight! > 0 && _height! > 0)
                    ? _onCheckRisk
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Check Risk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              if (_showResult && _weight != null && _height != null) ...[
                const SizedBox(height: 20),
                _buildBmiResultCard(isDark),
                const SizedBox(height: 16),
                if (_waist != null) _buildMetabolicRiskCard(isDark),
                if (_waist != null) const SizedBox(height: 16),
                _buildPcosRiskCard(isDark),
                const SizedBox(height: 16),
                _buildRecommendationsCard(isDark),
                const SizedBox(height: 16),
                _buildBmiScaleCard(isDark),
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
            const Text('Your Measurements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Weight (kg)',
                      helperText: '2–400',
                      prefixIcon: const Icon(Icons.monitor_weight_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    controller: _weightCtrl,
                    onChanged: (v) => setState(() => _weight = double.tryParse(v)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Height (cm)',
                      helperText: '50–250',
                      prefixIcon: const Icon(Icons.height),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    controller: _heightCtrl,
                    onChanged: (v) => setState(() => _height = double.tryParse(v)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Waist Circumference (cm) — Optional',
                prefixIcon: const Icon(Icons.straighten),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                helperText: 'Measure at navel level. Key indicator for PCOS metabolic risk.',
              ),
              controller: _waistCtrl,
              onChanged: (v) => setState(() => _waist = double.tryParse(v)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBmiResultCard(bool isDark) {
    Color bmiColor;
    if (_bmi < 18.5) {
      bmiColor = Colors.blue;
    } else if (_bmi < 25) {
      bmiColor = Colors.green;
    } else if (_bmi < 30) {
      bmiColor = Colors.orange;
    } else {
      bmiColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [bmiColor.withValues(alpha: 0.7), bmiColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('Your BMI', style: TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(_bmi.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Text(_bmiCategory, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetabolicRiskCard(bool isDark) {
    final score = _metabolicRiskScore;
    final level = _metabolicRiskLevel;
    Color riskColor;
    if (level == 'High') {
      riskColor = Colors.red;
    } else if (level == 'Moderate') {
      riskColor = Colors.orange;
    } else {
      riskColor = Colors.green;
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
                Icon(Icons.warning_amber, color: riskColor),
                const SizedBox(width: 8),
                const Text('PCOS Metabolic Risk Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 10,
                        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${score.round()}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: riskColor)),
                            Text('/ 100', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: riskColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('$level Risk', style: TextStyle(fontWeight: FontWeight.bold, color: riskColor)),
              ),
            ),
            const SizedBox(height: 12),
            if (_waist != null && _gender == 'Female')
              Text('Waist circumference of ${_waist!.toStringAsFixed(0)}cm is ${_waist! >= 88 ? "above" : _waist! >= 80 ? "borderline" : "below"} the PCOS risk threshold (≥80cm borderline, ≥88cm high risk).',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildPcosRiskCard(bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                const Text('PCOS Weight-Related Risk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Text(_pcosRiskLevel, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: _pcosRiskLevel.startsWith('Low') ? Colors.green : (_pcosRiskLevel.startsWith('Moderate') ? Colors.orange : Colors.red))),
            const SizedBox(height: 8),
            Text('Insulin resistance worsens with higher BMI, creating a cycle: PCOS → weight gain → worse insulin resistance → worse PCOS symptoms.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.recommend, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text('Personalized Advice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(),
            ..._recommendations.map((r) => Padding(
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

  Widget _buildBmiScaleCard(bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BMI Scale (WHO)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            _buildScaleRow('Underweight', '< 18.5', Colors.blue, _bmi < 18.5),
            _buildScaleRow('Normal', '18.5 — 24.9', Colors.green, _bmi >= 18.5 && _bmi < 25),
            _buildScaleRow('Overweight', '25.0 — 29.9', Colors.orange, _bmi >= 25 && _bmi < 30),
            _buildScaleRow('Obese Class I', '30.0 — 34.9', Colors.red.shade400, _bmi >= 30 && _bmi < 35),
            _buildScaleRow('Obese Class II', '35.0 — 39.9', Colors.red.shade600, _bmi >= 35 && _bmi < 40),
            _buildScaleRow('Obese Class III', '≥ 40.0', Colors.red.shade900, _bmi >= 40),
            const SizedBox(height: 12),
            Text('PCOS Note: Even women with "normal" BMI can have PCOS (lean PCOS). Insulin resistance and hormonal panels are essential regardless of weight.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildScaleRow(String label, String range, Color color, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: isActive ? 20 : 14,
            height: isActive ? 20 : 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? color : null,
            )),
          ),
          Text(range, style: TextStyle(fontSize: 12, color: isActive ? color : Colors.grey.shade600)),
        ],
      ),
    );
  }
}
