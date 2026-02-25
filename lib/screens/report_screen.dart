import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/report.dart';
import '../services/pdf_report_service.dart';
import '../services/storage_service.dart';
import '../widgets/disclaimer_banner.dart';

class ReportScreen extends StatelessWidget {
  final HealthReport? report;

  const ReportScreen({super.key, this.report});

  @override
  Widget build(BuildContext context) {
    if (report == null) {
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
              if (report!.highRiskDiseases.isNotEmpty)
                _buildRiskSection('High / Critical Risk', Colors.red,
                    report!.highRiskDiseases.cast<String>()),
              const SizedBox(height: 8),
              if (report!.moderateRiskDiseases.isNotEmpty)
                _buildRiskSection('Moderate Risk', Colors.orange,
                    report!.moderateRiskDiseases.cast<String>()),
              const SizedBox(height: 8),
              if (report!.lowRiskDiseases.isNotEmpty)
                _buildRiskSection('Low Risk', Colors.green,
                    report!.lowRiskDiseases.cast<String>()),
              const SizedBox(height: 8),
              if (report!.abnormalValues.isNotEmpty)
                _buildAbnormalitiesSection(context, report!.abnormalValues),
              if (report!.highRiskDiseases.isEmpty &&
                  report!.moderateRiskDiseases.isEmpty &&
                  report!.lowRiskDiseases.isEmpty &&
                  report!.abnormalValues.isEmpty)
                _buildEmptyState(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    await _sharePdf(
        context); // Alias download to share since we removed printing
  }

  Future<void> _sharePdf(BuildContext context) async {
    final profile = StorageService.getProfile();
    final pdfBytes = await PdfReportService.generateReport(
      report: report!,
      profile: profile,
    );

    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/health_report_${report!.reportId.substring(0, 8)}.pdf');
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

  Widget _buildRiskSection(String title, Color color, List<String> items) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withOpacity(0.5), width: 2),
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
            ...items.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning, size: 18, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(e, style: const TextStyle(fontSize: 16))),
                    ],
                  ),
                )),
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
          ? Colors.blueGrey.shade900.withOpacity(0.5)
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
}
