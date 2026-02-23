import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/report_provider.dart';

class ReportHistoryScreen extends ConsumerWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Past Reports')),
      body: reports.isEmpty
          ? const Center(
              child: Text(
                'No past reports found.\nEnter new data to get a risk assessment.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                // Display latest first
                final report = reports[reports.length - 1 - index];

                String subtitleText = 'Low Risk';
                Color riskColor = Colors.green;

                if (report.highRiskDiseases.isNotEmpty) {
                  subtitleText = 'High Risk: ${report.highRiskDiseases.first}';
                  riskColor = Colors.red;
                } else if (report.moderateRiskDiseases.isNotEmpty) {
                  subtitleText =
                      'Moderate Risk: ${report.moderateRiskDiseases.first}';
                  riskColor = Colors.orange;
                }

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.description, color: riskColor),
                    title: Text(
                      'Report ${report.date.toString().split(' ')[0]}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      subtitleText,
                      style: TextStyle(
                          color: riskColor, fontWeight: FontWeight.w500),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/report', extra: report);
                    },
                  ),
                );
              },
            ),
    );
  }
}
