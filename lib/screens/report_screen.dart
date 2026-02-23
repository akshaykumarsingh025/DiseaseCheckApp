import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/report.dart';
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
                _buildAbnormalitiesSection(report!.abnormalValues),
              const SizedBox(height: 32),
            ],
          ),
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

  Widget _buildAbnormalitiesSection(List<String> findings) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.blueGrey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Clinical Findings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ...findings.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.blueGrey),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(e, style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
