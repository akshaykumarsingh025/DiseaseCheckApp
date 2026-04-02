import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/report_provider.dart';
import '../engine/rule_engine.dart';
import '../engine/report_generator.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _processData();
  }

  Future<void> _processData() async {
    try {
      // Artificial delay for UX
      await Future.delayed(const Duration(seconds: 2));

      final session = ref.read(currentSessionProvider.notifier);
      final healthDataList = ref.read(currentSessionProvider);

      // Process health data through the Rule Engine
      final analysisResults = RuleEngine.evaluateHealthData(healthDataList);

      // Generate report using ReportGenerator
      final newReport = ReportGenerator.generate(analysisResults);

      await ref.read(reportProvider.notifier).addReport(newReport);

      // Clear the session so the next report starts fresh unless combined
      session.clearSession();

      if (mounted) {
        context.go('/report', extra: newReport);
      }
    } catch (e) {
      if (mounted) {
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
