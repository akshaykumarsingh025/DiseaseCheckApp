import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/report.dart';
import '../services/pdf_report_service.dart';
import '../services/storage_service.dart';
import '../services/ai_api_service.dart';
import '../providers/gemma_provider.dart';
import '../utils/doctor_info.dart';
import '../widgets/disclaimer_banner.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final HealthReport? report;

  const ReportScreen({super.key, this.report});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  String? _aiRefinedText;
  bool _isRefining = false;
  double _refineProgress = 0;
  String? _refineError;

  String? _selectedLanguage;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _aiRefinedText = widget.report?.aiRefinedText;
    _selectedLanguage = 'english';
  }

  Future<void> _refineWithAI({String? language}) async {
    if (widget.report == null) return;

    final lang = language ?? _selectedLanguage ?? 'english';

    setState(() {
      _isRefining = true;
      _refineProgress = 0.1;
      _refineError = null;
    });

    try {
      final rawText = _buildRawReportText(widget.report!);

      setState(() => _refineProgress = 0.3);

      String langInstruction;
      switch (lang) {
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
2. **Which values are abnormal**: Show actual value vs normal range. Example: "Fasting Blood Sugar: 250 mg/dL (normal: 70-100) — VERY HIGH"
3. **How these values connect**: Medical logic simply explained
4. **What this means for daily life**: Honest but not scary
5. **What you should do**: Specific next steps

**Abnormal Values Summary**: All out-of-range values listed

**IMPORTANT**: Please consult your doctor for proper diagnosis and treatment. This report is for awareness only, not a medical diagnosis.

Clinical data:
$rawText

Now write the patient-friendly report:''';

      final result = await AiApiService.generateText(prompt, language: lang);

      setState(() => _refineProgress = 0.9);

      if (result.success && result.text != null) {
        widget.report!.aiRefinedText = result.text;
        await StorageService.saveReport(widget.report!);
        setState(() {
          _aiRefinedText = result.text;
          _refineProgress = 1.0;
          _isRefining = false;
        });
      } else {
        setState(() {
          _refineError = result.error ?? 'Could not generate AI explanation. Please try again.';
          _isRefining = false;
        });
      }
    } catch (e) {
      setState(() {
        _refineError = e.toString().replaceAll('Exception: ', '');
        _isRefining = false;
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

  @override
  Widget build(BuildContext context) {
    if (widget.report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Risk Assessment Report')),
        body: const Center(child: Text('No report data found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Assessment Report'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download / Print PDF',
            onPressed: () => _downloadPdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share PDF',
            onPressed: () => _sharePdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: 'Share as Image',
            onPressed: () => _shareAsImage(context),
          ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DisclaimerBanner(),
              const SizedBox(height: 16),
              if (widget.report!.highRiskDiseases.isNotEmpty)
                _buildEmergencyAlert(context),
              if (widget.report!.highRiskDiseases.isNotEmpty)
                const SizedBox(height: 12),
              if (widget.report!.highRiskDiseases.isNotEmpty)
                _buildRiskSection('High / Critical Risk', Colors.red,
                    widget.report!.highRiskDiseases),
              const SizedBox(height: 8),
              if (widget.report!.moderateRiskDiseases.isNotEmpty)
                _buildRiskSection('Moderate Risk', Colors.orange,
                    widget.report!.moderateRiskDiseases),
              const SizedBox(height: 8),
              if (widget.report!.lowRiskDiseases.isNotEmpty)
                _buildRiskSection('Low Risk', Colors.green,
                    widget.report!.lowRiskDiseases),
              const SizedBox(height: 8),
              if (widget.report!.abnormalValues.isNotEmpty)
                _buildAbnormalitiesSection(context, widget.report!.abnormalValues),
              if (widget.report!.auditTrail.isNotEmpty)
                _buildAuditTrailSection(context),
              if (widget.report!.highRiskDiseases.isEmpty &&
                  widget.report!.moderateRiskDiseases.isEmpty &&
                  widget.report!.lowRiskDiseases.isEmpty &&
                  widget.report!.abnormalValues.isEmpty)
                _buildEmptyState(),
              const SizedBox(height: 16),
              _buildAIRefinementSection(context),
              const SizedBox(height: 16),
              _buildActionButtons(context),
              const SizedBox(height: 16),
              _buildDoctorCard(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildAIRefinementSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languages = [
      ('english', 'English', Icons.language),
      ('hindi', 'हिन्दी', Icons.translate),
      ('hinglish', 'Hinglish', Icons.chat_bubble_outline),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.purple.shade700 : Colors.purple.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purple.shade600, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'AI Simplified Report',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Generate this report in simple, patient-friendly language — unlimited times',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),

            Text('Choose Language', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: languages.map((lang) {
                final code = lang.$1;
                final label = lang.$2;
                final icon = lang.$3;
                final isSelected = (_selectedLanguage ?? 'english') == code;
                return ChoiceChip(
                  avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.indigo.shade600),
                  label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
                  selected: isSelected,
                  selectedColor: Colors.indigo,
                  onSelected: (_) => setState(() => _selectedLanguage = code),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            if (_isRefining) ...[
              LinearProgressIndicator(
                value: _refineProgress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
                backgroundColor: isDark ? Colors.purple.shade900 : Colors.purple.shade50,
              ),
              const SizedBox(height: 6),
              Text(
                'AI is analyzing your report... ${(_refineProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, color: Colors.purple.shade700, fontWeight: FontWeight.w500),
              ),
            ] else if (_refineError != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_refineError!, style: TextStyle(fontSize: 12, color: Colors.red.shade900))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _refineWithAI(language: _selectedLanguage),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
              ),
            ] else if (_aiRefinedText != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.purple.shade900.withValues(alpha: 0.2) : Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _aiRefinedText!,
                  style: TextStyle(fontSize: 13, height: 1.6, color: isDark ? Colors.grey.shade200 : Colors.black87),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _refineWithAI(language: _selectedLanguage),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text('Regenerate in ${_selectedLanguage == 'hindi' ? 'हिन्दी' : _selectedLanguage == 'hinglish' ? 'Hinglish' : 'English'}'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _refineWithAI(language: _selectedLanguage),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text('Explain in ${_selectedLanguage == 'hindi' ? 'हिन्दी' : _selectedLanguage == 'hinglish' ? 'Hinglish' : 'English'}'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagePicker(GemmaState gemmaState, bool isDark) {
    final languages = [
      ('english', 'English', Icons.language),
      ('hindi', 'हिन्दी (Hindi)', Icons.translate),
      ('hinglish', 'Hinglish', Icons.chat_bubble_outline),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report Language',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: languages.map((lang) {
            final code = lang.$1;
            final label = lang.$2;
            final icon = lang.$3;
            final isSelected = gemmaState.language == code;
            return ChoiceChip(
              avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.indigo.shade600),
              label: Text(label, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : null)),
              selected: isSelected,
              selectedColor: Colors.indigo,
              onSelected: (_) => ref.read(gemmaProvider.notifier).setLanguage(code),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      final profile = StorageService.getProfile();
      final pdfBytes = await PdfReportService.generateReport(
        report: widget.report!,
        profile: profile,
      );

      final fileName = 'health_report_${widget.report!.reportId.substring(0, 8)}.pdf';
      final downloadDir = Directory('/sdcard/Download');
      final filePath = '${downloadDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to Downloads/$fileName'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PDF: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    final profile = StorageService.getProfile();
    final pdfBytes = await PdfReportService.generateReport(
      report: widget.report!,
      profile: profile,
    );

    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/health_report_${widget.report!.reportId.substring(0, 8)}.pdf');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'My Health Assessment Report',
    );
  }

  Future<void> _shareAsImage(BuildContext context) async {
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: 3.0,
      );
      if (imageBytes == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/health_report_${widget.report!.reportId.substring(0, 8)}.png');
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Health Assessment Report',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share image: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 16),
            const Text(
              'All values appear within normal range!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No significant risks were detected from your input data.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskSection(
      String title, Color color, List<Map<String, dynamic>> items) {
    final previousReports = StorageService.getAllReports();
    Map<String, int> prevScores = {};
    if (previousReports.length > 1) {
      for (var r in previousReports) {
        if (r.reportId != widget.report!.reportId) {
          for (var d in [...r.highRiskDiseases, ...r.moderateRiskDiseases, ...r.lowRiskDiseases]) {
            prevScores[d['disease']?.toString() ?? ''] = d['riskScore'] as int? ?? 0;
          }
          break;
        }
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.5), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ...items.map((e) {
              final diseaseName = e['disease'] as String? ?? 'Unknown';
              final icdCode = e['icdCode'] as String? ?? '';
              final score = e['riskScore'] as int? ?? 0;
              final findings = e['findings'] as List? ?? [];
              final prevScore = prevScores[diseaseName];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning, size: 18, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$diseaseName${icdCode.isNotEmpty ? ' ($icdCode)' : ''} — $score% risk',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (prevScore != null) _buildTrendBadge(score, prevScore),
                      ],
                    ),
                    if (findings.isNotEmpty)
                      ...findings.map((f) => Padding(
                            padding: const EdgeInsets.only(left: 26, top: 2),
                            child: Text('• $f',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700)),
                          )),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAbnormalitiesSection(
      BuildContext context, List<String> findings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isDark
          ? Colors.blueGrey.shade900.withValues(alpha: 0.5)
          : Colors.blueGrey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.blueGrey.shade700 : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Clinical Findings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.blueGrey.shade100
                      : Colors.blueGrey.shade900,
                )),
            Divider(color: isDark ? Colors.blueGrey.shade700 : null),
            ...findings.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle,
                          size: 8,
                          color: isDark
                              ? Colors.blueGrey.shade300
                              : Colors.blueGrey),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(e,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.black87,
                              ))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditTrailSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: const Text('Rule Engine Audit Trail',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Tap to see which rules fired and why',
            style: TextStyle(fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.report!.auditTrail.map((entry) {
                final riskColor = entry['riskLevel'] == 'high'
                    ? Colors.red
                    : entry['riskLevel'] == 'moderate'
                        ? Colors.orange
                        : Colors.green;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: riskColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${entry['disease']} (${entry['icdCode']})',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('Score: ${entry['riskScore']}%',
                              style: TextStyle(
                                  color: riskColor,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Guideline: ${entry['guideline']}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      if ((entry['findings'] as List).isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ...(entry['findings'] as List).map((f) => Padding(
                              padding: const EdgeInsets.only(left: 20, top: 2),
                              child: Text('• $f',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.grey.shade300
                                        : Colors.black87,
                                  )),
                            )),
                      ],
                      const Divider(height: 24),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyAlert(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'URGENT: Critical values detected!',
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your report shows high-risk conditions that need immediate medical attention. Please consult a doctor as soon as possible.',
            style: TextStyle(color: Colors.red.shade800, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl('tel:${DoctorInfo.phone}'),
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('Call Doctor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl(DoctorInfo.whatsappUrl),
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'What would you like to do?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                Icons.chat_bubble_outline,
                'Ask AI',
                'Chat about\nyour report',
                Colors.purple,
                () => context.push('/ai-chat', extra: widget.report),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionCard(
                context,
                Icons.restaurant_menu,
                'Diet Plan',
                'Get personalized\ndiet & exercise',
                Colors.green,
                () => context.push('/diet-plan', extra: widget.report),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionCard(
                context,
                Icons.local_hospital,
                'Book Doctor',
                'Appointment with\nDr. Deepika',
                Colors.pink,
                () => context.push('/book-appointment'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
              const SizedBox(height: 2),
              Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.pink.shade100,
                  child: Icon(Icons.local_hospital, color: Colors.pink.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DoctorInfo.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(DoctorInfo.qualification, style: TextStyle(fontSize: 11, color: Colors.pink.shade700)),
                      Text('${DoctorInfo.experience} Exp | ${DoctorInfo.patients} Patients',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Need expert medical advice? Book an appointment for proper diagnosis and treatment.',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
            ),
             const SizedBox(height: 10),
             Row(
               children: [
                 Expanded(
                   child: OutlinedButton.icon(
                     onPressed: () => _launchUrl('tel:${DoctorInfo.phone}'),
                     icon: const Icon(Icons.phone, size: 16),
                     label: Text(DoctorInfo.phoneDisplay, style: const TextStyle(fontSize: 11)),
                   ),
                 ),
                 const SizedBox(width: 8),
                 Expanded(
                   child: OutlinedButton.icon(
                     onPressed: () => _launchUrl(DoctorInfo.whatsappUrl),
                     icon: const Icon(Icons.chat, size: 16),
                     label: const Text('WhatsApp', style: TextStyle(fontSize: 11)),
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 6),
             Row(
               children: [
                 Expanded(
                   child: OutlinedButton.icon(
                     onPressed: () => _launchUrl(DoctorInfo.emailUrl),
                     icon: const Icon(Icons.email, size: 16),
                     label: const Text('Email', style: TextStyle(fontSize: 11)),
                   ),
                 ),
                 const SizedBox(width: 8),
                 Expanded(
                   child: OutlinedButton.icon(
                     onPressed: () => context.push('/book-appointment'),
                     icon: const Icon(Icons.calendar_today, size: 16),
                     label: const Text('Book', style: TextStyle(fontSize: 11)),
                   ),
                 ),
               ],
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendBadge(int current, int previous) {
    if (current == previous) {
      return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)), child: const Text('No change', style: TextStyle(fontSize: 10, color: Colors.grey)));
    }
    final up = current > previous;
    final diff = (current - previous).abs();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: up ? Colors.red.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(up ? Icons.trending_up : Icons.trending_down, size: 12, color: up ? Colors.red : Colors.green),
        const SizedBox(width: 2),
        Text('${up ? '+' : '-'}$diff%', style: TextStyle(fontSize: 10, color: up ? Colors.red : Colors.green, fontWeight: FontWeight.w600)),
      ]),
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
