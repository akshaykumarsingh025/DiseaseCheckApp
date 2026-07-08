import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/report_provider.dart';
import '../providers/gemma_provider.dart';
import '../engine/rule_engine.dart';
import '../engine/report_generator.dart';
import '../services/gemma_service.dart';
import '../services/ai_api_service.dart';
import '../services/ad_service.dart';
import '../services/storage_service.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  String? _error;
  double _progress = 0.0;
  String _statusText = 'Initializing analysis...';
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _processData();
  }

  @override
  void dispose() {
    _isProcessing = false;
    GemmaService.cancelGeneration();
    super.dispose();
  }

  Future<void> _processData() async {
    try {
      setState(() {
        _progress = 0.1;
        _statusText = 'Reading your health data...';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      final session = ref.read(currentSessionProvider.notifier);
      final healthDataList = ref.read(currentSessionProvider);

      setState(() {
        _progress = 0.3;
        _statusText = 'Running clinical rule engine...';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      final analysisResults = RuleEngine.evaluateHealthData(healthDataList);

      setState(() {
        _progress = 0.5;
        _statusText = 'Generating risk assessment report...';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      final newReport = ReportGenerator.generate(analysisResults);

      if (StorageService.isDuplicateReport(newReport)) {
        if (_isProcessing && mounted) {
          setState(() {
            _progress = 1.0;
            _statusText = 'Similar report already exists!';
          });
          await Future.delayed(const Duration(milliseconds: 500));
          if (_isProcessing && mounted) {
            context.go('/report', extra: StorageService.getAllReports().first);
          }
        }
        return;
      }

      setState(() {
        _progress = 0.65;
        _statusText = 'Saving report...';
      });

      await ref.read(reportProvider.notifier).addReport(newReport);

      session.clearSession();

      final gemmaState = ref.read(gemmaProvider);
      if (gemmaState.isDownloaded && gemmaState.isEnabled && _isProcessing && mounted) {
        setState(() {
          _progress = 0.75;
          _statusText = 'AI is simplifying your report in easy words...';
        });

        try {
          final rawText = GemmaService.buildRawReportText(newReport.toJson());
          final language = gemmaState.language;

          String langInstruction;
          switch (language) {
            case 'hindi':
              langInstruction = 'Write in Hindi (Devanagari).';
              break;
            case 'hinglish':
              langInstruction = 'Write in Hinglish.';
              break;
            default:
              langInstruction = 'Write in simple English.';
          }

          final prompt = '''You are a caring medical assistant explaining a patient's health report. $langInstruction

Follow this structure:

**Overall Health Summary** (2-3 sentences)

Then for EACH disease found:
**[Disease Name]**
1. **What was found**: Simple explanation
2. **Which values are abnormal**: Show value vs normal range
3. **How these values connect**: Medical logic simply explained
4. **What this means for daily life**: Honest but not scary
5. **What you should do**: Specific next steps

**Abnormal Values Summary**: All out-of-range values listed

**IMPORTANT**: Please consult your doctor for proper diagnosis.

Clinical data:
$rawText

Now write the patient-friendly report:''';

          final aiResult = await AiApiService.generateText(prompt, language: language);

          if (!_isProcessing || !mounted) return;
          if (aiResult.success && aiResult.text != null) {
            newReport.aiRefinedText = aiResult.text;
            await ref.read(reportProvider.notifier).addReport(newReport);
          }
        } catch (_) {}

        setState(() => _progress = 0.95);
      } else if (_isProcessing && mounted) {
        setState(() {
          _progress = 0.75;
          _statusText = 'AI is simplifying your report in easy words...';
        });

        try {
          final rawText = GemmaService.buildRawReportText(newReport.toJson());
          final prompt = '''You are a caring medical assistant explaining a patient's health report in simple English.

Follow this structure:

**Overall Health Summary** (2-3 sentences)

Then for EACH disease found:
**[Disease Name]**
1. **What was found**: Simple explanation
2. **Which values are abnormal**: Show value vs normal range
3. **How these values connect**: Medical logic simply explained
4. **What this means for daily life**: Honest but not scary
5. **What you should do**: Specific next steps

**Abnormal Values Summary**: All out-of-range values listed

**IMPORTANT**: Please consult your doctor for proper diagnosis.

Clinical data:
$rawText

Now write the patient-friendly report:''';

          final aiResult = await AiApiService.generateText(prompt);

          if (!_isProcessing || !mounted) return;
          if (aiResult.success && aiResult.text != null) {
            newReport.aiRefinedText = aiResult.text;
            await ref.read(reportProvider.notifier).addReport(newReport);
          }
        } catch (_) {}

        setState(() => _progress = 0.95);
      } else {
        setState(() => _progress = 0.9);
      }

      setState(() {
        _progress = 1.0;
        _statusText = 'Done!';
      });

      await Future.delayed(const Duration(milliseconds: 300));

      // Count this successful report and show an interstitial if due, before
      // navigating to the result. Ad-free/paid users never see one.
      await AdService.onSuccessfulGenerationAndMaybeShow();

      if (_isProcessing && mounted) {
        context.go('/report', extra: newReport);
      }
    } catch (e) {
      if (_isProcessing && mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                const Text(
                  'Analysis Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Back to Dashboard'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                  backgroundColor: Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _statusText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
