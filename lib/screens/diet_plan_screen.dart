import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/gemma_provider.dart';
import '../services/gemma_service.dart';
import '../models/report.dart';
import '../utils/doctor_info.dart';

class DietPlanScreen extends ConsumerStatefulWidget {
  final HealthReport report;
  const DietPlanScreen({super.key, required this.report});

  @override
  ConsumerState<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends ConsumerState<DietPlanScreen> {
  String? _plan;
  bool _isLoading = false;
  bool _isCancelled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedPlan();
  }

  @override
  void dispose() {
    if (_isLoading) {
      _isCancelled = true;
      GemmaService.cancelGeneration();
    }
    super.dispose();
  }

  Future<void> _loadSavedPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('diet_plan_${widget.report.reportId}');
    if (saved != null && mounted) {
      setState(() => _plan = saved);
    } else {
      _generatePlan();
    }
  }

  Future<void> _savePlan() async {
    if (_plan == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('diet_plan_${widget.report.reportId}', _plan!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diet plan saved!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isLoading = true;
      _isCancelled = false;
      _error = null;
    });

    _showLoadingDialog();

    final reportContext = GemmaService.buildRawReportText(widget.report.toJson());
    final language = ref.read(gemmaProvider).language;

    String langInstruction;
    switch (language) {
      case 'hindi':
        langInstruction = 'पूरी योजना शुद्ध हिन्दी (देवनागरी) में लिखें। भारतीय खाने के विकल्प दें।';
        break;
      case 'hinglish':
        langInstruction = 'Poori plan Hinglish mein likhein. Indian food options dein like dal, roti, sabzi etc.';
        break;
      default:
        langInstruction = 'Write the plan in simple English. Use Indian food options.';
    }

    final prompt = '''You are a caring medical assistant and nutrition expert. Based on the patient's health report, create a personalized diet and lifestyle plan. $langInstruction

Patient's health report:
$reportContext

Create a detailed plan with these sections:

** DIET PLAN **
- Foods to EAT (with Indian options - specify dal, sabzi, fruits etc.)
- Foods to AVOID (explain why for each)
- Sample 1-day meal plan (breakfast, lunch, snack, dinner)

** EXERCISE PLAN **
- Safe exercises for this patient's condition
- Exercises to avoid
- Daily routine suggestion (morning/evening)

** HOME REMEDIES **
- 3-5 safe, traditional Indian home remedies that can help
- Remind: these support but don't replace medical treatment

** IMPORTANT WARNINGS **
- Lifestyle habits that MUST change
- Things that could make the condition worse

End with: "This is a general guide based on your report. Please consult ${DoctorInfo.name} for a personalized treatment plan. Book appointment: ${DoctorInfo.phoneDisplay}"''';

    final result = await GemmaService.refineReport(prompt, language: language);

    if (_isCancelled || !mounted) return;

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    setState(() {
      _isLoading = false;
      if (result.success && result.text != null) {
        _plan = result.text;
      } else {
        _error = result.error ?? 'Could not generate plan. Please try again.';
      }
    });

    if (result.success) {
      await _savePlan();
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
              const SizedBox(height: 20),
              const Text(
                'Generating your personalized diet & lifestyle plan...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'This may take 1-2 minutes. Please wait...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _isCancelled = true;
                    GemmaService.cancelGeneration();
                    Navigator.pop(ctx);
                    setState(() {
                      _isLoading = false;
                      _error = 'Plan generation was cancelled.';
                    });
                    GemmaService.reinitializeIfReady();
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
        title: const Text('Diet & Lifestyle Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_hospital),
            tooltip: 'Book Doctor',
            onPressed: () => context.push('/book-appointment'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI is preparing your personalized plan...'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _generatePlan, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        color: isDark ? Colors.green.shade900.withValues(alpha: 0.2) : Colors.green.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.green.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _plan ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.7,
                              color: isDark ? Colors.grey.shade200 : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _savePlan,
                              icon: const Icon(Icons.save),
                              label: const Text('Save Plan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _generatePlan,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Regenerate'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDoctorCard(isDark),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDoctorCard(bool isDark) {
    return Card(
      color: isDark ? Colors.pink.shade900.withValues(alpha: 0.2) : Colors.pink.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.pink.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.local_hospital, size: 32, color: Colors.pink.shade600),
            const SizedBox(height: 8),
            Text(
              'Need personalized medical advice?',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.pink.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              'Book appointment with ${DoctorInfo.name}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _launchUrl('tel:${DoctorInfo.phone}'),
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _launchUrl(DoctorInfo.whatsappUrl),
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
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
