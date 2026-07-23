import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/health_data_provider.dart';
import '../providers/profile_provider.dart';
import '../engine/rule_engine.dart';
import '../engine/risk_result.dart';
import '../services/health_news_service.dart';
import '../widgets/health_feed_section.dart';

class WomensHealthScreen extends ConsumerWidget {
  const WomensHealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthData = ref.watch(healthDataProvider);
    final profile = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final womensLabels = {
      'AMH (Anti-Müllerian Hormone)', 'FSH', 'LH', 'Estradiol (E2)', 'Progesterone', 'Prolactin',
      'Total Testosterone', 'DHEAS', 'Fasting Insulin', 'HOMA-IR',
      'Pap Smear Result (0=Normal, 1=ASCUS, 2=LSIL, 3=HSIL)', 'High-Risk HPV (0=Negative, 1=Positive)',
    };

    final Map<String, double> latestVals = {};
    for (var entry in healthData) {
      if (womensLabels.contains(entry.testName)) latestVals[entry.testName] = entry.value;
    }
    for (var entry in healthData) {
      if (entry.testName == 'TSH' || entry.testName == 'Fasting Blood Glucose' || entry.testName == 'Hemoglobin') {
        latestVals[entry.testName] = entry.value;
      }
    }

    final pcosResult = latestVals.containsKey('Total Testosterone') || latestVals.containsKey('DHEAS') || latestVals.containsKey('AMH (Anti-Müllerian Hormone)') || latestVals.containsKey('LH')
        ? RuleEngine.checkPCOS(testosterone: latestVals['Total Testosterone'], dheas: latestVals['DHEAS'], amh: latestVals['AMH (Anti-Müllerian Hormone)'], fastingInsulin: latestVals['Fasting Insulin'], homaIr: latestVals['HOMA-IR'], lh: latestVals['LH'], fsh: latestVals['FSH']) : null;
    final ovrResult = latestVals.containsKey('AMH (Anti-Müllerian Hormone)') || latestVals.containsKey('FSH')
        ? RuleEngine.checkOvarianReserve(amh: latestVals['AMH (Anti-Müllerian Hormone)'], fsh: latestVals['FSH']) : null;
    final pregResult = latestVals.containsKey('AMH (Anti-Müllerian Hormone)') || latestVals.containsKey('TSH') || latestVals.containsKey('Fasting Blood Glucose') || latestVals.containsKey('Hemoglobin')
        ? RuleEngine.checkPregnancyReadiness(amh: latestVals['AMH (Anti-Müllerian Hormone)'], tsh: latestVals['TSH'], fbg: latestVals['Fasting Blood Glucose'], hb: latestVals['Hemoglobin']) : null;
    final menoResult = latestVals.containsKey('FSH') || latestVals.containsKey('Estradiol (E2)')
        ? RuleEngine.checkMenopauseRisk(fsh: latestVals['FSH'], estradiol: latestVals['Estradiol (E2)']) : null;
    final cervResult = latestVals.containsKey('Pap Smear Result (0=Normal, 1=ASCUS, 2=LSIL, 3=HSIL)') || latestVals.containsKey('High-Risk HPV (0=Negative, 1=Positive)')
        ? RuleEngine.checkCervicalCancerRisk(papSmear: latestVals['Pap Smear Result (0=Normal, 1=ASCUS, 2=LSIL, 3=HSIL)'], hpvStatus: latestVals['High-Risk HPV (0=Negative, 1=Positive)']) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Women\'s Health Hub'),
        backgroundColor: isDark ? Colors.pink.shade900 : Colors.pink.shade50,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 80.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(context, isDark),
              if (profile != null) ...[
                const SizedBox(height: 12),
                _buildProfileSnippet(context, profile, isDark),
              ],
              const SizedBox(height: 24),
              const Text('Health Tools', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Interactive assessments & trackers', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 12),
              _buildToolCard(context, isDark, 'PCOS Risk Screener', '10-question assessment based on Rotterdam criteria', Icons.quiz, Colors.purple, '/pcos-screener'),
              const SizedBox(height: 10),
              _buildToolCard(context, isDark, 'Due Date Calculator', 'Calculate your EDD, current week & milestones', Icons.pregnant_woman, Colors.pink, '/due-date-calculator'),
              const SizedBox(height: 10),
              _buildToolCard(context, isDark, 'Period & Ovulation Tracker', 'Find your next period, fertile window & ovulation', Icons.calendar_month, Colors.teal, '/period-tracker'),
              const SizedBox(height: 10),
              _buildToolCard(context, isDark, 'BMI & PCOS Weight Risk', 'BMI with PCOS-specific metabolic risk scoring', Icons.monitor_weight, Colors.deepPurple, '/bmi-pcos-risk'),
              const SizedBox(height: 10),
              _buildToolCard(context, isDark, 'Fertility Score', 'Comprehensive fertility wellness assessment', Icons.favorite, Colors.pinkAccent, '/fertility-score'),
              const SizedBox(height: 24),
              HealthFeedSection(
                title: 'Natural Remedies',
                subtitle: 'Latest natural & herbal remedy updates',
                provider: naturalRemediesProvider,
                fallbackBuilder: naturalRemediesFallback,
                itemIcon: Icons.spa_outlined,
              ),
              const SizedBox(height: 24),
              HealthFeedSection(
                title: 'Women\'s Health News',
                subtitle: 'Live headlines from trusted news sources',
                provider: womensHealthNewsProvider,
                fallbackBuilder: womensHealthNewsFallback,
                itemIcon: Icons.article_outlined,
              ),
              const SizedBox(height: 24),
              const Text('Lab Data Trackers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Based on your uploaded lab reports', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 12),
              _buildTrackerCardWithResult(context, isDark, 'PCOS & Metabolic', 'Track signs of Polycystic Ovary Syndrome', Icons.water_drop, Colors.purple, pcosResult),
              const SizedBox(height: 10),
              _buildTrackerCardWithResult(context, isDark, 'Ovarian Reserve & Fertility', 'Monitor AMH & FSH levels', Icons.child_care, Colors.pink, ovrResult),
              const SizedBox(height: 10),
              _buildTrackerCardWithResult(context, isDark, 'Pregnancy Readiness', 'Check blood stats before conception', Icons.pregnant_woman, Colors.teal, pregResult),
              const SizedBox(height: 10),
              _buildTrackerCardWithResult(context, isDark, 'Menopause Risk', 'Monitor transition indicators', Icons.spa, Colors.orange, menoResult),
              const SizedBox(height: 10),
              _buildTrackerCardWithResult(context, isDark, 'Cervical Screening', 'Pap Smear & HPV tracking', Icons.local_hospital, Colors.redAccent, cervResult),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/data-entry', extra: {
            'categories': ['Pregnancy', 'Hormonal Panel', 'Metabolic Panel (Women\'s Health)', 'Cervical Screening'],
          });
        },
        backgroundColor: Colors.pinkAccent,
        icon: const Icon(Icons.add),
        label: const Text('Add Lab Data'),
      ),
    );
  }

  Widget _buildProfileSnippet(BuildContext context, dynamic profile, bool isDark) {
    final items = <String>[];
    if (profile.cycleRegularity != null) items.add('Cycle: ${profile.cycleRegularity}');
    if (profile.menstrualCycleLength != null) items.add('${profile.menstrualCycleLength} days');
    if (profile.reproductiveHistory != null) items.add(profile.reproductiveHistory);
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: isDark ? Colors.pink.shade900.withValues(alpha: 0.2) : Colors.pink.shade50, borderRadius: BorderRadius.circular(8)),
      child: Text(items.join('  •  '), style: TextStyle(fontSize: 13, color: isDark ? Colors.pink.shade200 : Colors.pink.shade700)),
    );
  }

  Widget _buildHeaderCard(BuildContext context, bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? Colors.pink.shade900.withValues(alpha: 0.3) : Colors.pink.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? Colors.pink.shade700 : Colors.pink.shade200)),
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.monitor_heart, size: 48, color: Colors.pinkAccent),
            SizedBox(height: 12),
            Text('ACOG / RCOG Guidelines', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('All evaluations are based on the latest guidelines from the American College of Obstetricians and Gynecologists.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, bool isDark, String title, String subtitle, IconData icon, Color color, String route) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.08), color.withValues(alpha: 0.03)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('Start', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackerCardWithResult(BuildContext context, bool isDark, String title, String subtitle, IconData icon, Color color, RiskResult? result) {
    final hasData = result != null;
    final riskLevel = hasData ? result.riskLevel : 'no data';
    final riskScore = hasData ? result.riskScore : 0;
    final findings = hasData ? result.findings : <String>[];

    Color riskColor;
    String riskLabel;
    if (!hasData) { riskColor = Colors.grey; riskLabel = 'No data yet'; }
    else if (riskLevel == 'high') { riskColor = Colors.red; riskLabel = 'High Risk ($riskScore%)'; }
    else if (riskLevel == 'moderate') { riskColor = Colors.orange; riskLabel = 'Moderate ($riskScore%)'; }
    else { riskColor = Colors.green; riskLabel = 'Low Risk ($riskScore%)'; }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: riskColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(riskLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: riskColor)),
              ),
            ],
          ),
          children: hasData && findings.isNotEmpty
              ? findings.map((f) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.circle, size: 6, color: riskColor), const SizedBox(width: 8), Expanded(child: Text(f, style: const TextStyle(fontSize: 13)))]))).toList()
              : [Text(hasData ? 'All values within normal range.' : 'Tap the + button below to add lab data.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600))],
        ),
      ),
    );
  }

}
