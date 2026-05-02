import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _generatePlan();
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

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

**🍎 DIET PLAN**
- Foods to EAT (with Indian options - specify dal, sabzi, fruits etc.)
- Foods to AVOID (explain why for each)
- Sample 1-day meal plan (breakfast, lunch, snack, dinner)

**🏃 EXERCISE PLAN**
- Safe exercises for this patient's condition
- Exercises to avoid
- Daily routine suggestion (morning/evening)

**🏠 HOME REMEDIES**
- 3-5 safe, traditional Indian home remedies that can help
- Remind: these support but don't replace medical treatment

**⚠️ IMPORTANT WARNINGS**
- Lifestyle habits that MUST change
- Things that could make the condition worse

End with: "This is a general guide based on your report. Please consult ${DoctorInfo.name} for a personalized treatment plan. Book appointment: ${DoctorInfo.phoneDisplay}"''';

    final result = await GemmaService.refineReport(prompt, language: language);

    setState(() {
      _isLoading = false;
      if (result.success && result.text != null) {
        _plan = result.text;
      } else {
        _error = result.error ?? 'Could not generate plan. Please try again.';
      }
    });
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
                      _buildDoctorCard(isDark),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _generatePlan,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Regenerate Plan'),
                      ),
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
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
