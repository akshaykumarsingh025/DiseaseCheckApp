import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';
import '../utils/bmi_calculator.dart';
import '../utils/doctor_info.dart';
import '../widgets/disclaimer_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final themeState = ref.watch(themeProvider);
    final isDark = themeState.valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile-setup'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await StorageService.clearAllLocalData();
              ref.invalidate(profileProvider);
              ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const DisclaimerBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (profile != null) ...[
                      Text(
                        'Welcome, ${profile.name}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (profile.height != null && profile.weight != null) ...[
                        _buildBmiCard(
                            context, profile.weight!, profile.height!),
                      ],
                      const SizedBox(height: 24),
                      if (profile.gender == 'Female') ...[
                        _buildDashboardCard(
                          context,
                          'Women\'s Health Hub',
                          'PCOS, Pregnancy, Menopause & More',
                          Icons.female,
                          Colors.pinkAccent,
                          () => context.push('/womens-health'),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                    _buildDashboardCard(
                      context,
                      'Enter New Data',
                      'Input lab reports and vitals manually',
                      Icons.edit_document,
                      Colors.blueAccent,
                      () => context.push('/data-category'),
                    ),
                    const SizedBox(height: 16),
                    _buildDashboardCard(
                      context,
                      'Scan Medical Report',
                      'Auto-extract data from your X-Ray or Ultrasound via Camera',
                      Icons.document_scanner,
                      Colors.deepPurpleAccent,
                      () => context.push('/ocr-scanner'),
                    ),
                    const SizedBox(height: 16),
                    _buildDashboardCard(
                      context,
                      'Health Trends',
                      'Track your vitals over time',
                      Icons.show_chart,
                      Colors.teal,
                      () => context.push('/trends'),
                    ),
                    const SizedBox(height: 16),
                    _buildDashboardCard(
                      context,
                      'View Past Reports',
                      'Check your wellness history',
                      Icons.history,
                      Colors.green,
                      () => context.push('/report-history'),
                    ),
                    const SizedBox(height: 16),
                    _buildDashboardCard(
                      context,
                      'AI Report Assistant',
                      'Download AI to explain reports in simple words',
                      Icons.auto_awesome,
                      Colors.purple,
                      () => context.push('/ai-settings'),
                    ),
                    const SizedBox(height: 16),
                    _buildDoctorDashboardCard(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBmiCard(BuildContext context, double weight, double height) {
    double bmi = BmiCalculator.calculateBmi(weight, height);
    String category = BmiCalculator.getBmiCategory(bmi);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color:
          isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current BMI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    )),
                Text(category,
                    style: TextStyle(
                      color:
                          isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    )),
              ],
            ),
            Text(
              bmi.toStringAsFixed(1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: isDark ? Colors.blue.shade300 : Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title,
      String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        )),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorDashboardCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/book-appointment'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.pink.shade400, Colors.pink.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                child: const Icon(Icons.local_hospital, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DoctorInfo.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(DoctorInfo.qualification,
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9))),
                    const SizedBox(height: 4),
                    Text('${DoctorInfo.experience} Exp | ${DoctorInfo.phoneDisplay}',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: () => _launchUrl('tel:${DoctorInfo.phone}'),
                    icon: const Icon(Icons.phone, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.2)),
                  ),
                  const SizedBox(height: 4),
                  IconButton(
                    onPressed: () => _launchUrl(DoctorInfo.whatsappUrl),
                    icon: const Icon(Icons.chat, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.2)),
                  ),
                ],
              ),
            ],
          ),
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
