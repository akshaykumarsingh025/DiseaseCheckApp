import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../providers/health_data_provider.dart';
import '../providers/report_provider.dart';
import '../engine/rule_engine.dart';
import '../models/report.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  @override
  void initState() {
    super.initState();
    _processData();
  }

  Future<void> _processData() async {
    // Artificial delay for UX
    await Future.delayed(const Duration(seconds: 2));

    final healthDataList = ref.read(healthDataProvider);

    // Process health data through the Rule Engine
    final analysisResults = RuleEngine.evaluateHealthData(healthDataList);

    List<String> high = [];
    List<String> moderate = [];
    List<String> low = [];
    List<String> abnormalities = [];

    for (var result in analysisResults) {
      String disease = result['disease'];
      String level = result['riskLevel'];
      List<String> findings = List<String>.from(result['findings'] ?? []);
      int score = result['riskScore'] ?? 0;

      String label = '$disease — Risk: $score%';

      if (level == 'high' || level == 'critical') {
        high.add(label);
      } else if (level == 'moderate') {
        moderate.add(label);
      } else {
        low.add(label);
      }
      abnormalities.addAll(findings);
    }

    // In a real scenario, we might merge RuleEngine with ML Engine results here.

    final newReport = HealthReport(
      reportId: const Uuid().v4(),
      date: DateTime.now(),
      highRiskDiseases: high,
      moderateRiskDiseases: moderate,
      lowRiskDiseases: low,
      abnormalValues: abnormalities,
    );

    await ref.read(reportProvider.notifier).addReport(newReport);

    if (mounted) {
      // Navigate to report screen passing the newly created report ID
      context.go('/report', extra: newReport);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('Analyzing data with AI Models...'),
            SizedBox(height: 8),
            Text('Checking clinical guidelines...'),
          ],
        ),
      ),
    );
  }
}
