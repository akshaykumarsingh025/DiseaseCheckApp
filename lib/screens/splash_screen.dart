import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/feature_flags.dart';
import '../providers/profile_provider.dart';
import '../services/storage_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    final disclaimerAccepted = prefs.getBool('disclaimer_accepted') ?? false;

    if (!mounted) return;

    if (!disclaimerAccepted) {
      context.go('/disclaimer');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    if (!user.emailVerified &&
        !FeatureFlags.canBypassEmailVerification(user.email)) {
      context.go('/verify-email');
      return;
    }

    final lastSyncUid = prefs.getString('last_sync_uid');

    if (lastSyncUid != user.uid) {
      await StorageService.clearAllLocalData();
      await prefs.setString('last_sync_uid', user.uid);
    }

    if (!mounted) return;
    ref.invalidate(profileProvider);

    final profile = StorageService.getProfile();
    if (profile == null) {
      context.go('/profile-setup');
    } else {
      context.go('/dashboard');
    }

    _fetchCloudInBackground(user.uid);
  }

  void _fetchCloudInBackground(String uid) {
    StorageService.fetchAllFromCloud(uid).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.health_and_safety, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Health Check AI',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            CircularProgressIndicator(color: Color(0xFFE94560)),
          ],
        ),
      ),
    );
  }
}
