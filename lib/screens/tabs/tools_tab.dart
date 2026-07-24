import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/profile_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/nav_tile.dart';

/// The "Tools" tab: occasional checkers, calculators and data entry, grouped
/// away from the daily-use flow.
class ToolsTab extends ConsumerWidget {
  const ToolsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final isFemale = profile?.gender == 'Female';

    final tiles = <Widget>[
      ToolGridTile(
        icon: Icons.psychology_alt,
        color: Colors.deepPurple,
        title: 'Symptom Checker',
        subtitle: 'AI guidance',
        onTap: () => context.push('/symptom-checker'),
      ),
      ToolGridTile(
        icon: Icons.monitor_heart,
        color: Colors.pink,
        title: 'PCOS Screener',
        subtitle: 'Risk questionnaire',
        onTap: () => context.push('/pcos-screener'),
      ),
      ToolGridTile(
        icon: Icons.speed,
        color: Colors.blue,
        title: 'BMI & Risk',
        subtitle: 'Body metrics',
        onTap: () => context.push('/bmi-pcos-risk'),
      ),
      if (isFemale)
        ToolGridTile(
          icon: Icons.child_friendly,
          color: Colors.pinkAccent,
          title: 'Due-Date Calc',
          subtitle: 'Pregnancy dates',
          onTap: () => context.push('/due-date-calculator'),
        ),
      if (isFemale)
        ToolGridTile(
          icon: Icons.favorite,
          color: Colors.redAccent,
          title: 'Fertility Score',
          subtitle: 'Conception window',
          onTap: () => context.push('/fertility-score'),
        ),
      ToolGridTile(
        icon: Icons.document_scanner,
        color: Colors.deepPurpleAccent,
        title: 'Scan Report',
        subtitle: 'Camera OCR',
        onTap: () => context.push('/ocr-scanner'),
      ),
      ToolGridTile(
        icon: Icons.restaurant_menu,
        color: Colors.orange,
        title: 'AI Diet Plan',
        subtitle: 'Personalized meals',
        onTap: () => _openDietPlan(context),
      ),
      ToolGridTile(
        icon: Icons.bloodtype,
        color: Colors.red,
        title: 'Blood Donation',
        subtitle: 'Eligibility check',
        onTap: () => _showBloodDonationCheck(context, ref),
      ),
      ToolGridTile(
        icon: Icons.edit_document,
        color: Colors.blueAccent,
        title: 'Enter New Data',
        subtitle: 'Labs & vitals',
        onTap: () => context.push('/data-category'),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isFemale) ...[
          NavTile(
            icon: Icons.female,
            color: Colors.pinkAccent,
            title: "Women's Health Hub",
            subtitle: 'PCOS, Pregnancy, Menopause & more',
            onTap: () => context.push('/womens-health'),
          ),
          const SizedBox(height: 14),
        ],
        const SectionHeader('Checkers & calculators'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: tiles,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _openDietPlan(BuildContext context) {
    final reports = StorageService.getAllReports();
    if (reports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No reports found. Please complete a health check first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    context.push('/diet-plan', extra: reports.first);
  }

  void _showBloodDonationCheck(BuildContext context, WidgetRef ref) {
    final profile = ref.read(profileProvider);
    final healthData = StorageService.getAllHealthData();
    final latestVals = <String, double>{};
    for (var entry in healthData) {
      latestVals[entry.testName] = entry.value;
    }

    final issues = <String>[];
    final checks = <String>[];

    final age = profile?.age ?? 0;
    final weight = profile?.weight ?? 0;
    final gender = profile?.gender ?? '';

    if (age > 0) {
      if (age >= 18 && age <= 65) {
        checks.add('Age ($age): Eligible');
      } else {
        issues.add('Age ($age): Must be 18-65 years');
      }
    } else {
      checks.add('Age: Not set in profile');
    }

    if (weight > 0) {
      if (weight >= 50) {
        checks.add('Weight (${weight}kg): Eligible');
      } else {
        issues.add('Weight (${weight}kg): Must be at least 50kg');
      }
    } else {
      checks.add('Weight: Not set in profile');
    }

    final hb = latestVals['Hemoglobin'];
    if (hb != null) {
      final minHb = gender == 'Female' ? 12.0 : 13.0;
      if (hb >= minHb) {
        checks.add('Hemoglobin ($hb g/dL): Eligible');
      } else {
        issues.add(
            'Hemoglobin ($hb g/dL): Must be ${minHb.toStringAsFixed(0)}+ g/dL');
      }
    } else {
      checks.add('Hemoglobin: Not tested yet');
    }

    final fbg = latestVals['Fasting Blood Glucose'];
    if (fbg != null) {
      if (fbg < 126) {
        checks.add('Fasting Sugar ($fbg mg/dL): Eligible');
      } else {
        issues.add('Fasting Sugar ($fbg mg/dL): Too high for donation');
      }
    }

    final bpSys = latestVals['Systolic BP'];
    if (bpSys != null) {
      if (bpSys >= 100 && bpSys <= 180) {
        checks.add('Systolic BP ($bpSys mmHg): Eligible');
      } else {
        issues.add(
            'Systolic BP ($bpSys mmHg): Outside eligible range (100-180)');
      }
    }

    final eligible = issues.isEmpty;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(eligible ? Icons.check_circle : Icons.warning,
              color: eligible ? Colors.green : Colors.orange),
          const SizedBox(width: 8),
          Text(eligible ? 'Eligible!' : 'Not Eligible'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (checks.isNotEmpty) ...[
              const Text('Checks:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...checks.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(children: [
                    const Icon(Icons.check, size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(c, style: const TextStyle(fontSize: 13)))
                  ]))),
            ],
            if (issues.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Issues:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 4),
              ...issues.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(children: [
                    const Icon(Icons.close, size: 14, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(i, style: const TextStyle(fontSize: 13)))
                  ]))),
            ],
            const SizedBox(height: 8),
            Text(
                'Based on latest lab data in your profile. Consult a doctor for final clearance.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
        ],
      ),
    );
  }
}
