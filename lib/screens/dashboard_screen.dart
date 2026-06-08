import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/feature_flags.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';
import '../utils/bmi_calculator.dart';
import '../utils/doctor_info.dart';
import '../widgets/disclaimer_banner.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isOffline = false;
  String _lastSynced = '';

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadLastSynced();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      setState(() => _isOffline = result.contains(ConnectivityResult.none));
      Connectivity().onConnectivityChanged.listen((results) {
        if (mounted) {
          setState(() => _isOffline = results.contains(ConnectivityResult.none));
        }
      });
    } catch (_) {}
  }

  Future<void> _loadLastSynced() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString('last_synced');
    if (lastSync != null && mounted) {
      setState(() => _lastSynced = lastSync);
    }
  }

  Future<void> _refreshData() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      try {
        await StorageService.fetchAllFromCloud(user.uid);
        ref.invalidate(profileProvider);
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now().toString().split('.')[0];
        await prefs.setString('last_synced', now);
        setState(() => _lastSynced = now);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
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
            if (_isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: Colors.orange.shade100,
                child: Row(
                  children: [
                    Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text('Offline — changes will sync when connected', style: TextStyle(fontSize: 12, color: Colors.orange.shade900)),
                  ],
                ),
              ),
            if (_lastSynced.isNotEmpty && !_isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: Colors.green.shade50,
                child: Row(
                  children: [
                    Icon(Icons.cloud_done, size: 14, color: Colors.green.shade600),
                    const SizedBox(width: 6),
                    Text('Last synced: $_lastSynced', style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
                  ],
                ),
              ),
            const DisclaimerBanner(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
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
                      _buildDashboardCard(
                        context,
                        'Blood Donation Check',
                        'Check if you\'re eligible to donate blood',
                        Icons.bloodtype,
                        Colors.redAccent,
                        () => _showBloodDonationCheck(),
                      ),
                      const SizedBox(height: 16),
                      _buildDashboardCard(
                        context,
                        'Online OPD - ₹199',
                        'Video consultation with Dr. Deepika',
                        Icons.videocam,
                        const Color(0xFF0F3460),
                        () => context.push('/online-opd'),
                      ),
                      const SizedBox(height: 16),
                      if (FeatureFlags.healthCoursesEnabled) ...[
                        _buildDashboardCard(
                          context,
                          'Health Courses',
                          'Free & premium health education',
                          Icons.school,
                          Colors.indigo,
                          () => context.push('/courses'),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildDashboardCard(
                        context,
                        'Diet Plans - ₹299',
                        'Customized diet plans for your health issues',
                        Icons.restaurant_menu,
                        Colors.orange,
                        () => context.push('/diet-plans'),
                      ),
                      const SizedBox(height: 16),
                      _buildDoctorDashboardCard(context),
                    ],
                  ),
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
        onTap: () => context.push('/online-opd'),
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
                    Text('Online OPD ₹199 | ${DoctorInfo.phoneDisplay}',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: () => context.push('/online-opd'),
                    icon: const Icon(Icons.videocam, color: Colors.white),
                    tooltip: 'Video Consultation',
                    style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.2)),
                  ),
                  const SizedBox(height: 4),
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

  void _showBloodDonationCheck() {
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
        checks.add('Hemoglobin (${hb} g/dL): Eligible');
      } else {
        issues.add('Hemoglobin (${hb} g/dL): Must be ${minHb.toStringAsFixed(0)}+ g/dL');
      }
    } else {
      checks.add('Hemoglobin: Not tested yet');
    }

    final fbg = latestVals['Fasting Blood Glucose'];
    if (fbg != null) {
      if (fbg < 126) {
        checks.add('Fasting Sugar (${fbg} mg/dL): Eligible');
      } else {
        issues.add('Fasting Sugar (${fbg} mg/dL): Too high for donation');
      }
    }

    final bpSys = latestVals['Systolic BP'];
    if (bpSys != null) {
      if (bpSys >= 100 && bpSys <= 180) {
        checks.add('Systolic BP (${bpSys} mmHg): Eligible');
      } else {
        issues.add('Systolic BP (${bpSys} mmHg): Outside eligible range (100-180)');
      }
    }

    final eligible = issues.isEmpty;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(eligible ? Icons.check_circle : Icons.warning, color: eligible ? Colors.green : Colors.orange),
          const SizedBox(width: 8),
          Text(eligible ? 'Eligible!' : 'Not Eligible'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (checks.isNotEmpty) ...[
              const Text('Checks:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...checks.map((c) => Padding(padding: const EdgeInsets.only(bottom: 2), child: Row(children: [Icon(Icons.check, size: 14, color: Colors.green), const SizedBox(width: 6), Expanded(child: Text(c, style: const TextStyle(fontSize: 13)))]))),
            ],
            if (issues.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Issues:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 4),
              ...issues.map((i) => Padding(padding: const EdgeInsets.only(bottom: 2), child: Row(children: [Icon(Icons.close, size: 14, color: Colors.red), const SizedBox(width: 6), Expanded(child: Text(i, style: const TextStyle(fontSize: 13)))]))),
            ],
            const SizedBox(height: 8),
            Text('Based on latest lab data in your profile. Consult a doctor for final clearance.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
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
