import 'package:flutter/material.dart';
import '../models/report.dart';

class CompareReportsScreen extends StatelessWidget {
  final HealthReport report1;
  final HealthReport report2;
  const CompareReportsScreen({super.key, required this.report1, required this.report2});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d1 = report1.date.toString().split(' ')[0];
    final d2 = report2.date.toString().split(' ')[0];

    return Scaffold(
      appBar: AppBar(title: const Text('Compare Reports')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(isDark, d1, d2),
            const SizedBox(height: 16),
            _buildRiskComparison('High Risk', Colors.red, report1.highRiskDiseases, report2.highRiskDiseases, isDark),
            const SizedBox(height: 10),
            _buildRiskComparison('Moderate Risk', Colors.orange, report1.moderateRiskDiseases, report2.moderateRiskDiseases, isDark),
            const SizedBox(height: 10),
            _buildRiskComparison('Low Risk', Colors.green, report1.lowRiskDiseases, report2.lowRiskDiseases, isDark),
            const SizedBox(height: 10),
            _buildAbnormalComparison(isDark),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, String d1, String d2) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Text(d1, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.compare_arrows)),
            Expanded(child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(8)), child: Text(d2, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskComparison(String title, Color color, List<Map<String, dynamic>> r1, List<Map<String, dynamic>> r2, bool isDark) {
    final allDiseases = <String>{};
    for (var d in r1) { allDiseases.add(d['disease']?.toString() ?? ''); }
    for (var d in r2) { allDiseases.add(d['disease']?.toString() ?? ''); }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(),
            if (allDiseases.isEmpty)
              Text('No risks in either report', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))
            else
              ...allDiseases.map((disease) {
                final in1 = r1.any((d) => d['disease'] == disease);
                final in2 = r2.any((d) => d['disease'] == disease);
                final score1 = in1 ? r1.firstWhere((d) => d['disease'] == disease)['riskScore'] ?? 0 : null;
                final score2 = in2 ? r2.firstWhere((d) => d['disease'] == disease)['riskScore'] ?? 0 : null;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(disease, style: const TextStyle(fontSize: 13))),
                      Expanded(child: _buildScoreChip(score1, Colors.blue)),
                      Expanded(child: _buildScoreChip(score2, Colors.pink)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChip(dynamic score, Color color) {
    if (score == null) return Text('—', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontSize: 12));
    final s = score is int ? score : (score as num).toInt();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text('$s%', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildAbnormalComparison(bool isDark) {
    final vals1 = report1.abnormalValues;
    final vals2 = report2.abnormalValues;
    final allVals = <String>{...vals1, ...vals2};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Abnormal Values', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(),
            if (allVals.isEmpty)
              Text('No abnormal values in either report', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))
            else
              ...allVals.map((v) {
                final in1 = vals1.contains(v);
                final in2 = vals2.contains(v);
                Color tagColor;
                String tag;
                if (in1 && in2) { tagColor = Colors.red; tag = 'Both'; }
                else if (in1) { tagColor = Colors.blue; tag = 'Report 1'; }
                else { tagColor = Colors.pink; tag = 'Report 2'; }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Expanded(child: Text(v, style: const TextStyle(fontSize: 12))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: tagColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(tag, style: TextStyle(fontSize: 10, color: tagColor, fontWeight: FontWeight.w600))),
                  ]),
                );
              }),
          ],
        ),
      ),
    );
  }
}
