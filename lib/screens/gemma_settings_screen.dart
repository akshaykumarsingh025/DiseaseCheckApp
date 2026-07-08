import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gemma_provider.dart';
import '../services/ai_api_service.dart';
import '../services/storage_service.dart';
import '../models/report.dart';

class GemmaSettingsScreen extends ConsumerStatefulWidget {
  const GemmaSettingsScreen({super.key});

  @override
  ConsumerState<GemmaSettingsScreen> createState() =>
      _GemmaSettingsScreenState();
}

class _GemmaSettingsScreenState extends ConsumerState<GemmaSettingsScreen> {
  AiMode _aiMode = AiMode.online;

  bool _isGenerating = false;
  double _generateProgress = 0;
  String? _generateError;
  String? _generatedReport;
  AiApiSource? _usedSource;

  @override
  void initState() {
    super.initState();
    _loadAiMode();
  }

  Future<void> _loadAiMode() async {
    final mode = await AiApiService.getAiMode();
    if (mounted) setState(() => _aiMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final gemmaState = ref.watch(gemmaProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Report Assistant'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(isDark),
              const SizedBox(height: 16),
              _buildAiModeSection(isDark),
              const SizedBox(height: 16),
              _buildGenerateReportSection(isDark),
              const SizedBox(height: 16),
              _buildLanguageSection(gemmaState, isDark),
              const SizedBox(height: 16),
              _buildDownloadSection(gemmaState, isDark),
              const SizedBox(height: 16),
              if (gemmaState.isDownloaded) _buildDeleteSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? Colors.purple.shade900.withValues(alpha: 0.3) : Colors.purple.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.purple.shade700 : Colors.purple.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(Icons.auto_awesome, size: 36, color: Colors.purple.shade600),
            const SizedBox(height: 8),
            const Text(
              'AI-Powered Report',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Get your health report explained in simple language. '
              'Use online AI (no download needed) or local AI (works offline).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiModeSection(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                const Text('AI Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Choose how AI generates your reports', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 10),
            _buildModeOption(
              mode: AiMode.online,
              icon: Icons.cloud,
              title: 'Online AI (Recommended)',
              subtitle: 'Uses cloud AI — no download needed, works instantly',
              color: Colors.blue,
              isDark: isDark,
            ),
            const SizedBox(height: 6),
            _buildModeOption(
              mode: AiMode.auto,
              icon: Icons.sync,
              title: 'Auto (Online + Local Fallback)',
              subtitle: 'Online first, falls back to local model if offline',
              color: Colors.teal,
              isDark: isDark,
            ),
            const SizedBox(height: 6),
            _buildModeOption(
              mode: AiMode.local,
              icon: Icons.phone_android,
              title: 'Local AI Only',
              subtitle: 'Uses downloaded model — works offline, ~2.5 GB',
              color: Colors.orange,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required AiMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _aiMode == mode;
    return InkWell(
      onTap: () async {
        await AiApiService.setAiMode(mode);
        setState(() => _aiMode = mode);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isSelected ? color : null)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection(GemmaState gemmaState, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.translate, color: Colors.indigo.shade700, size: 20),
                const SizedBox(width: 8),
                const Text('Report Language',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Choose the language for your AI health report',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            _buildLanguageOption(
              value: 'english',
              label: 'English',
              subtitle: 'Report in simple, easy-to-understand English',
              icon: Icons.language,
              gemmaState: gemmaState,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildLanguageOption(
              value: 'hindi',
              label: 'हिन्दी (Hindi)',
              subtitle: 'शुद्ध हिन्दी देवनागरी लिपि में रिपोर्ट',
              icon: Icons.translate,
              gemmaState: gemmaState,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildLanguageOption(
              value: 'hinglish',
              label: 'Hinglish',
              subtitle: 'Hindi-English mix, the way we naturally speak',
              icon: Icons.chat_bubble_outline,
              gemmaState: gemmaState,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String value,
    required String label,
    required String subtitle,
    required IconData icon,
    required GemmaState gemmaState,
    required bool isDark,
  }) {
    final isSelected = gemmaState.language == value;
    return InkWell(
      onTap: () => ref.read(gemmaProvider.notifier).setLanguage(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.indigo.shade900.withValues(alpha: 0.3) : Colors.indigo.shade50)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.indigo.shade400 : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: gemmaState.language,
              onChanged: (v) {
                if (v != null) ref.read(gemmaProvider.notifier).setLanguage(v);
              },
              activeColor: Colors.indigo,
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 20, color: isSelected ? Colors.indigo.shade600 : Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isSelected ? Colors.indigo.shade700 : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.indigo.shade500, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateReportSection(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purple.shade600, size: 20),
                const SizedBox(width: 8),
                const Text('Generate AI Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Generate an AI-powered explanation of your latest health report in simple language',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            if (_isGenerating) ...[
              LinearProgressIndicator(
                value: _generateProgress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
                backgroundColor: isDark ? Colors.purple.shade900 : Colors.purple.shade50,
              ),
              const SizedBox(height: 6),
              Text(
                'Generating your AI report... ${(_generateProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, color: Colors.purple.shade700, fontWeight: FontWeight.w500),
              ),
            ] else if (_generateError != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_generateError!, style: TextStyle(fontSize: 12, color: Colors.red.shade900))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _generateReport,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                    ),
                  ),
                ],
              ),
            ] else if (_generatedReport != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.purple.shade900.withValues(alpha: 0.2) : Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Report Generated${_usedSource != null ? ' via ${AiApiService.getSourceLabel(_usedSource!)}' : ''}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _generatedReport!,
                      style: TextStyle(fontSize: 13, height: 1.6, color: isDark ? Colors.grey.shade200 : Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _generateReport,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Regenerate', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generateReport,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Generate Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generateReport() async {
    final reports = StorageService.getAllReports();
    if (reports.isEmpty) {
      setState(() => _generateError = 'No reports found. Please complete a health check first.');
      return;
    }

    final latestReport = reports.first;
    final gemmaState = ref.read(gemmaProvider);
    final language = gemmaState.language;

    setState(() {
      _isGenerating = true;
      _generateProgress = 0.1;
      _generateError = null;
      _generatedReport = null;
    });

    try {
      final rawText = _buildRawReportText(latestReport);

      setState(() => _generateProgress = 0.3);

      String langInstruction;
      switch (language) {
        case 'hindi':
          langInstruction = 'पूरी रिपोर्ट शुद्ध हिन्दी (देवनागरी लिपि) में लिखें। मेडिकल शब्दों के साथ ब्रैकेट में हिन्दी अर्थ दें।';
          break;
        case 'hinglish':
          langInstruction = 'Write the ENTIRE response in Hinglish — Hindi words in English script. Medical terms stay English but explain in Hinglish.';
          break;
        default:
          langInstruction = 'Write the ENTIRE response in simple, clear English. Short sentences, everyday words. Explain medical terms in brackets.';
      }

      final prompt = '''You are a caring medical assistant explaining a patient's health report. $langInstruction

Follow this structure:

**Overall Health Summary** (2-3 sentences about how their health looks)

Then for EACH disease found:
**[Disease Name]**
1. **What was found**: Simple explanation (1-2 sentences)
2. **Which values are abnormal**: Show actual value vs normal range
3. **How these values connect**: Medical logic simply explained
4. **What this means for daily life**: Honest but not scary
5. **What you should do**: Specific next steps

**Abnormal Values Summary**: All out-of-range values listed

**IMPORTANT**: Please consult your doctor for proper diagnosis and treatment. This report is for awareness only, not a medical diagnosis.

Clinical data:
$rawText

Now write the patient-friendly report:''';

      final result = await AiApiService.generateText(prompt, language: language);

      setState(() => _generateProgress = 0.9);

      if (result.success && result.text != null) {
        latestReport.aiRefinedText = result.text;
        await StorageService.saveReport(latestReport);
        setState(() {
          _generatedReport = result.text;
          _usedSource = result.source;
          _generateProgress = 1.0;
          _isGenerating = false;
        });
      } else {
        setState(() {
          _generateError = result.error ?? 'Could not generate AI report. Please try again.';
          _isGenerating = false;
        });
      }
    } catch (e) {
      setState(() {
        _generateError = e.toString().replaceAll('Exception: ', '');
        _isGenerating = false;
      });
    }
  }

  String _buildRawReportText(HealthReport report) {
    final buffer = StringBuffer();
    if (report.highRiskDiseases.isNotEmpty) {
      buffer.writeln('HIGH RISK:');
      for (var d in report.highRiskDiseases) {
        buffer.writeln('- ${d['disease']} (${d['icdCode']}, Risk: ${d['riskScore']}%)');
        for (var f in (d['findings'] as List?) ?? []) {
          buffer.writeln('  Finding: $f');
        }
      }
    }
    if (report.moderateRiskDiseases.isNotEmpty) {
      buffer.writeln('MODERATE RISK:');
      for (var d in report.moderateRiskDiseases) {
        buffer.writeln('- ${d['disease']} (${d['icdCode']}, Risk: ${d['riskScore']}%)');
      }
    }
    if (report.lowRiskDiseases.isNotEmpty) {
      buffer.writeln('LOW RISK:');
      for (var d in report.lowRiskDiseases) {
        buffer.writeln('- ${d['disease']} (${d['icdCode']}, Risk: ${d['riskScore']}%)');
      }
    }
    if (report.abnormalValues.isNotEmpty) {
      buffer.writeln('ABNORMAL VALUES:');
      for (var a in report.abnormalValues) {
        buffer.writeln('- $a');
      }
    }
    if (report.highRiskDiseases.isEmpty && report.moderateRiskDiseases.isEmpty && report.lowRiskDiseases.isEmpty && report.abnormalValues.isEmpty) {
      buffer.writeln('All values within normal range.');
    }
    return buffer.toString();
  }

  Widget _buildDownloadSection(GemmaState gemmaState, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_download, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                const Text('Download AI Model',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            if (gemmaState.isDownloading) ...[
              LinearProgressIndicator(
                value: gemmaState.downloadProgress,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
              const SizedBox(height: 10),
              Text(
                'Downloading... ${(gemmaState.downloadProgress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                gemmaState.downloadProgressText,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(gemmaProvider.notifier).cancelDownload(),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Cancel Download'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The model is about 2.5 GB. Download runs in background — you can minimize the app or turn off the screen.',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (gemmaState.downloadError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: gemmaState.downloadError!.contains('cancelled')
                      ? Colors.orange.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: gemmaState.downloadError!.contains('cancelled')
                        ? Colors.orange.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      gemmaState.downloadError!.contains('cancelled')
                          ? Icons.warning_amber
                          : Icons.error_outline,
                      color: gemmaState.downloadError!.contains('cancelled')
                          ? Colors.orange.shade700
                          : Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        gemmaState.downloadError!,
                        style: TextStyle(
                          fontSize: 13,
                          color: gemmaState.downloadError!.contains('cancelled')
                              ? Colors.orange.shade900
                              : Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => ref.read(gemmaProvider.notifier).startDownload(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: gemmaState.downloadError!.contains('cancelled')
                      ? const Text('Resume Download')
                      : const Text('Retry Download'),
                ),
              ),
            ] else if (gemmaState.isDownloaded) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI model is ready! Your reports will now be explained in simple, patient-friendly language.',
                        style: TextStyle(fontSize: 13, color: Colors.green.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'The AI model is about 2.5 GB. Download runs in background so you can use other apps or turn off the screen.',
                            style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'What this gives you:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade900),
                    ),
                    const SizedBox(height: 4),
                    _buildFeatureItem('Your report explained in simple words'),
                    _buildFeatureItem('Medical terms translated to plain language'),
                    _buildFeatureItem('Clear next steps for your health'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showDownloadConfirmDialog(),
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: const Text('Download AI Model'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 14, color: Colors.green),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  void _showDownloadConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cloud_download, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('Download AI Model'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The AI model is about 2.5 GB. '
                      'Download runs in background — you can minimize the app. '
                      'Ensure a stable internet connection.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'After download, your health reports will include:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem('Simple explanation of your test results'),
            _buildFeatureItem('Medical terms explained in plain language'),
            _buildFeatureItem('Clear next steps you can take'),
            const SizedBox(height: 12),
            Text(
              'You can delete the model anytime from this page to free up storage.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(gemmaProvider.notifier).startDownload();
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Start Download'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                const Text('Remove AI Model',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Remove the downloaded AI model to free up ~2.5 GB of storage. '
              'You can download it again anytime.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete AI Model?'),
                    content: const Text(
                      'This will remove the AI model (~2.5 GB) from your device. '
                      'You can download it again later.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(gemmaProvider.notifier).deleteModel();
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_forever, size: 18),
              label: const Text('Delete AI Model'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
