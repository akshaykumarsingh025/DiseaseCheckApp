import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/gemma_provider.dart';
import '../services/ai_api_service.dart';
import '../services/ad_service.dart';
import '../services/gemma_service.dart';
import '../models/report.dart';
import '../utils/doctor_info.dart';

class DietPlanCategory {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String promptSuffix;

  const DietPlanCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.promptSuffix,
  });
}

class DietPlanScreen extends ConsumerStatefulWidget {
  final HealthReport report;
  const DietPlanScreen({super.key, required this.report});

  @override
  ConsumerState<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends ConsumerState<DietPlanScreen> {
  String? _plan;
  bool _isLoading = false;
  String? _error;
  AiApiSource? _usedSource;
  DietPlanCategory? _selectedCategory;

  String? _userHeight;
  String? _userWeight;
  bool _isDiabetic = false;
  String? _userAge;
  String? _userGender;

  static const _categories = <DietPlanCategory>[
    DietPlanCategory(
      id: 'overall',
      title: 'Overall Health Plan',
      subtitle: 'Based on your complete report',
      icon: Icons.favorite,
      color: Colors.pink,
      promptSuffix: 'Create a comprehensive diet and lifestyle plan based on ALL conditions found in the report.',
    ),
    DietPlanCategory(
      id: 'diabetes',
      title: 'Diabetes Diet Plan',
      subtitle: 'Control blood sugar naturally',
      icon: Icons.bloodtype,
      color: Colors.blue,
      promptSuffix: 'Focus on diabetes management. Create a low-glycemic Indian diet plan with foods that control blood sugar. Include specific meal timing advice.',
    ),
    DietPlanCategory(
      id: 'heart',
      title: 'Heart Health Plan',
      subtitle: 'Lower cholesterol & BP',
      icon: Icons.monitor_heart,
      color: Colors.red,
      promptSuffix: 'Focus on cardiovascular health. Create a heart-healthy diet plan that lowers cholesterol and blood pressure. Include DASH-style recommendations with Indian foods.',
    ),
    DietPlanCategory(
      id: 'kidney',
      title: 'Kidney Health Plan',
      subtitle: 'Protect kidney function',
      icon: Icons.water_drop,
      color: Colors.teal,
      promptSuffix: 'Focus on kidney health. Create a renal-friendly diet plan with controlled protein, potassium, and phosphorus. Include specific Indian food swaps.',
    ),
    DietPlanCategory(
      id: 'liver',
      title: 'Liver Health Plan',
      subtitle: 'Support liver recovery',
      icon: Icons.healing,
      color: Colors.green,
      promptSuffix: 'Focus on liver health. Create a liver-friendly diet plan with foods that support liver regeneration. Avoid alcohol, processed foods, and high-fat items.',
    ),
    DietPlanCategory(
      id: 'weight_loss',
      title: 'Weight Loss Plan',
      subtitle: 'Sustainable fat loss diet',
      icon: Icons.trending_down,
      color: Colors.orange,
      promptSuffix: 'Focus on sustainable weight loss. Create a calorie-controlled Indian diet plan for healthy weight reduction. Include portion sizes and daily calorie targets.',
    ),
    DietPlanCategory(
      id: 'weight_gain',
      title: 'Weight Gain Plan',
      subtitle: 'Healthy mass building',
      icon: Icons.trending_up,
      color: Colors.brown,
      promptSuffix: 'Focus on healthy weight gain. Create a high-calorie nutritious Indian diet plan with protein-rich foods. Include muscle-building meal suggestions.',
    ),
    DietPlanCategory(
      id: 'anemia',
      title: 'Anemia Recovery Plan',
      subtitle: 'Boost iron & hemoglobin',
      icon: Icons.opacity,
      color: Colors.deepPurple,
      promptSuffix: 'Focus on anemia recovery. Create an iron-rich Indian diet plan with vitamin C combinations for better absorption. Include specific hemoglobin-boosting foods.',
    ),
    DietPlanCategory(
      id: 'pcos',
      title: 'PCOS/PCOD Plan',
      subtitle: 'Hormonal balance diet',
      icon: Icons.female,
      color: Colors.purple,
      promptSuffix: 'Focus on PCOS/PCOD management. Create an anti-inflammatory Indian diet plan that supports hormonal balance. Include insulin resistance management tips.',
    ),
    DietPlanCategory(
      id: 'thyroid',
      title: 'Thyroid Health Plan',
      subtitle: 'Support thyroid function',
      icon: Icons.bolt,
      color: Colors.indigo,
      promptSuffix: 'Focus on thyroid health. Create a thyroid-supportive Indian diet plan with selenium, iodine, and zinc-rich foods. Include goitrogen avoidance tips.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedPlan();
  }

  Future<void> _loadSavedPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('diet_plan_${widget.report.reportId}');
    if (saved != null && mounted) {
      setState(() => _plan = saved);
    }
  }

  Future<void> _savePlan() async {
    if (_plan == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _selectedCategory != null
        ? 'diet_plan_${widget.report.reportId}_${_selectedCategory!.id}'
        : 'diet_plan_${widget.report.reportId}';
    await prefs.setString(key, _plan!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diet plan saved!'), backgroundColor: Colors.green),
      );
    }
  }

  void _showUserInfoDialog(DietPlanCategory category) {
    final heightCtrl = TextEditingController(text: _userHeight ?? '');
    final weightCtrl = TextEditingController(text: _userWeight ?? '');
    final ageCtrl = TextEditingController(text: _userAge ?? '');
    String selectedGender = _userGender ?? 'Male';
    bool isDiabetic = _isDiabetic;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(category.icon, color: category.color, size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: Text(category.title, style: const TextStyle(fontSize: 16))),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Help us personalize your diet plan',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: heightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Height (cm)',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.height, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: weightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.monitor_weight_outlined, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ageCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              border: OutlineInputBorder(),
                              isDense: true,
                              prefixIcon: Icon(Icons.cake, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedGender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Male', child: Text('Male')),
                              DropdownMenuItem(value: 'Female', child: Text('Female')),
                              DropdownMenuItem(value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (v) {
                              if (v != null) setDialogState(() => selectedGender = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDiabetic ? Colors.red.shade50 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDiabetic ? Colors.red.shade300 : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bloodtype,
                            color: isDiabetic ? Colors.red.shade600 : Colors.grey,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Are you diabetic?',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDiabetic ? Colors.red.shade900 : Colors.black87,
                              ),
                            ),
                          ),
                          Switch(
                            value: isDiabetic,
                            activeColor: Colors.red,
                            onChanged: (v) => setDialogState(() => isDiabetic = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _userHeight = heightCtrl.text.trim().isEmpty ? null : heightCtrl.text.trim();
                    _userWeight = weightCtrl.text.trim().isEmpty ? null : weightCtrl.text.trim();
                    _userAge = ageCtrl.text.trim().isEmpty ? null : ageCtrl.text.trim();
                    _userGender = selectedGender;
                    _isDiabetic = isDiabetic;
                    _generatePlan(category);
                  },
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Generate Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: category.color,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _generatePlan(DietPlanCategory category) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedCategory = category;
    });

    _showLoadingDialog();

    final reportContext = GemmaService.buildRawReportText(widget.report.toJson());
    final language = ref.read(gemmaProvider).language;

    String langInstruction;
    switch (language) {
      case 'hindi':
        langInstruction = 'Write in Hindi (Devanagari). Use Indian food options.';
        break;
      case 'hinglish':
        langInstruction = 'Write in Hinglish. Use Indian food options like dal, roti, sabzi etc.';
        break;
      default:
        langInstruction = 'Write in simple English. Use Indian food options.';
    }

    final userBioBuffer = StringBuffer();
    if (_userHeight != null) userBioBuffer.writeln('- Height: $_userHeight cm');
    if (_userWeight != null) userBioBuffer.writeln('- Weight: $_userWeight kg');
    if (_userAge != null) userBioBuffer.writeln('- Age: $_userAge years');
    if (_userGender != null) userBioBuffer.writeln('- Gender: $_userGender');
    if (_isDiabetic) userBioBuffer.writeln('- Diabetic: YES — must follow a diabetic-friendly diet');
    final userBio = userBioBuffer.isEmpty ? '' : '\nPatient profile:\n$userBioBuffer';

    final prompt = '''You are a caring medical assistant and nutrition expert. Based on the patient's health report and personal details, create a personalized diet and lifestyle plan. $langInstruction
$userBio
Patient's health report:
$reportContext

${category.promptSuffix}

Create a detailed plan with these sections:

** DIET PLAN **
- Foods to EAT (with Indian options - specify dal, sabzi, fruits etc.)
- Foods to AVOID (explain why for each)
- Sample 1-day meal plan (breakfast, mid-morning, lunch, evening snack, dinner)
- Hydration tips (how much water, what fluids to drink/avoid)

** EXERCISE PLAN **
- Safe exercises for this patient's condition
- Exercises to avoid
- Daily routine suggestion (morning/evening)

** HOME REMEDIES **
- 3-5 safe, traditional Indian home remedies that can help
- Remind: these support but don't replace medical treatment

** LIFESTYLE TIPS **
- Sleep recommendations
- Stress management tips
- Daily habits that improve this condition

** IMPORTANT WARNINGS **
- Lifestyle habits that MUST change
- Things that could make the condition worse

End with: "This is a general guide based on your report. Please consult ${DoctorInfo.name} for a personalized treatment plan. Book appointment: ${DoctorInfo.phoneDisplay}"''';

    final result = await AiApiService.generateText(prompt, language: language);

    if (!mounted) return;
    if (Navigator.canPop(context)) Navigator.pop(context);

    setState(() {
      _isLoading = false;
      _usedSource = result.success ? result.source : null;
      if (result.success && result.text != null) {
        _plan = result.text;
      } else {
        _error = result.error ?? 'Could not generate plan. Please try again.';
      }
    });

    if (result.success) {
      await _savePlan();
      // Count this successful generation and show an interstitial if due
      // (balanced rule; paid/ad-free users are never shown ads).
      await AdService.onSuccessfulGenerationAndMaybeShow();
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Generating your personalized AI diet plan...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Trying online service, please wait...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _isLoading = false;
                      _error = 'Plan generation was cancelled.';
                    });
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Diet & Lifestyle Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_hospital),
            tooltip: 'Book Doctor',
            onPressed: () => context.push('/book-appointment'),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('AI is preparing your plan...', style: TextStyle(fontSize: 13)),
                  ],
                ),
              )
            : _error != null
                ? _buildErrorState(isDark)
                : _plan != null
                    ? _buildPlanResult(isDark)
                    : _buildCategorySelection(isDark),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            if (_selectedCategory != null)
              ElevatedButton(
                onPressed: () => _generatePlan(_selectedCategory!),
                child: const Text('Retry'),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() { _error = null; _selectedCategory = null; }),
              child: const Text('Choose Different Plan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelection(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: isDark ? Colors.blue.shade900.withValues(alpha: 0.2) : Colors.blue.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.blue.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.blue.shade600, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI-Powered Diet Plans', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('Choose a category to generate a personalized plan using AI',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Choose Your Plan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              return ActionChip(
                avatar: Icon(cat.icon, size: 16, color: cat.color),
                label: Text(cat.title, style: const TextStyle(fontSize: 12)),
                onPressed: () => _showUserInfoDialog(cat),
                side: BorderSide(color: cat.color.withValues(alpha: 0.4)),
                backgroundColor: cat.color.withValues(alpha: 0.08),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Detailed Categories', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._categories.map((cat) => _buildCategoryCard(cat, isDark)),
          const SizedBox(height: 16),
          if (_plan != null) ...[
            const Divider(),
            const SizedBox(height: 8),
            const Text('Previously Generated Plan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildPlanCard(isDark),
            const SizedBox(height: 16),
          ],
          _buildDoctorCard(isDark),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(DietPlanCategory cat, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _showUserInfoDialog(cat),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(cat.icon, size: 20, color: cat.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(cat.subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanResult(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_selectedCategory != null)
            Card(
              color: _selectedCategory!.color.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: _selectedCategory!.color.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(_selectedCategory!.icon, size: 18, color: _selectedCategory!.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedCategory!.title,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _selectedCategory!.color),
                      ),
                    ),
                    if (_usedSource != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AiApiService.getSourceLabel(_usedSource!),
                          style: TextStyle(fontSize: 9, color: Colors.green.shade700),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          _buildPlanCard(isDark),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _savePlan,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save Plan', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _plan = null;
                      _selectedCategory = null;
                    });
                  },
                  icon: const Icon(Icons.category, size: 18),
                  label: const Text('New Plan', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDoctorCard(isDark),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPlanCard(bool isDark) {
    return Card(
      color: isDark ? Colors.green.shade900.withValues(alpha: 0.2) : Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          _plan ?? '',
          style: TextStyle(
            fontSize: 13,
            height: 1.7,
            color: isDark ? Colors.grey.shade200 : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(bool isDark) {
    return Card(
      color: isDark ? Colors.pink.shade900.withValues(alpha: 0.2) : Colors.pink.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.pink.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(Icons.local_hospital, size: 24, color: Colors.pink.shade600),
            const SizedBox(height: 6),
            Text(
              'Need personalized medical advice?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.pink.shade700),
            ),
            const SizedBox(height: 2),
            Text(
              'Book appointment with ${DoctorInfo.name}',
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _launchUrl('tel:${DoctorInfo.phone}'),
                  icon: const Icon(Icons.phone, size: 14),
                  label: const Text('Call', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _launchUrl(DoctorInfo.whatsappUrl),
                  icon: const Icon(Icons.chat, size: 14),
                  label: const Text('WhatsApp', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (_) {}
    }
  }
}
