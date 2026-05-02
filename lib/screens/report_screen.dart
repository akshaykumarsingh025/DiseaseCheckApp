import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../models/report.dart';
import '../services/pdf_report_service.dart';
import '../services/storage_service.dart';
import '../services/gemma_service.dart';
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

  @override
  void initState() {
    super.initState();
    _aiRefinedText = widget.report?.aiRefinedText;
  }

  @override
  void dispose() {
    if (_isRefining) {
      GemmaService.cancelGeneration();
    }
    super.dispose();
  }

  Future<void> _refineWithAI() async {
    if (widget.report == null) return;

    final gemmaState = ref.read(gemmaProvider);
    if (!gemmaState.isDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI model not downloaded. Go to Settings to download it first.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isRefining = true;
      _refineProgress = 0.1;
      _refineError = null;
    });

    try {
      final rawText = GemmaService.buildRawReportText(widget.report!.toJson());

      setState(() => _refineProgress = 0.3);

      final result = await GemmaService.refineReport(rawText, language: gemmaState.language);

      setState(() {
        _refineProgress = 0.9;
      });

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
        ],
      ),
      body: SafeArea(
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
    );
  }

  Widget _buildAIRefinementSection(BuildContext context) {
    final gemmaState = ref.watch(gemmaProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.purple.shade700 : Colors.purple.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purple.shade600, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'AI Simplified Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Get this report explained in simple, patient-friendly language',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),

            if (gemmaState.isDownloaded) _buildLanguagePicker(gemmaState, isDark),
            if (gemmaState.isDownloaded) const SizedBox(height: 12),

            if (_isRefining) ...[
              LinearProgressIndicator(
                value: _refineProgress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                backgroundColor: isDark ? Colors.purple.shade900 : Colors.purple.shade50,
              ),
              const SizedBox(height: 8),
              Text(
                'AI is analyzing your report... ${(_refineProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.purple.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'This may take a moment. Please wait...',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ] else if (_refineError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_refineError!,
                          style: TextStyle(fontSize: 13, color: Colors.red.shade900)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _refineWithAI,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ] else if (_aiRefinedText != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.purple.shade900.withValues(alpha: 0.2)
                      : Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _aiRefinedText!,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark ? Colors.grey.shade200 : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _refineWithAI,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('Regenerate in ${GemmaService.getLanguageLabel(gemmaState.language)}'),
              ),
            ] else ...[
              if (!gemmaState.isDownloaded) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Download the AI model from Settings to enable this feature.',
                          style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                 OutlinedButton.icon(
                   onPressed: () => context.push('/ai-settings'),
                   icon: const Icon(Icons.settings, size: 18),
                   label: const Text('Go to AI Settings'),
                 ),
               ] else ...[
                 ElevatedButton.icon(
                   onPressed: _refineWithAI,
                   icon: const Icon(Icons.auto_awesome, size: 18),
                   label: Text('Explain in ${GemmaService.getLanguageLabel(gemmaState.language)}'),
                   style: ElevatedButton.styleFrom(
                     padding: const EdgeInsets.symmetric(vertical: 14),
                   ),
                 ),
               ],
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
