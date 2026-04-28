import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final disclaimerAccepted = prefs.getBool('disclaimer_accepted') ?? false;

    if (!disclaimerAccepted) {
      context.go('/disclaimer');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    // If email not verified, send to verify-email info page (user stays authenticated)
    if (!user.emailVerified) {
      context.go('/verify-email');
      return;
    }

    final lastSyncUid = prefs.getString('last_sync_uid');

    if (lastSyncUid != user.uid) {
      await StorageService.clearAllLocalData();
      await prefs.setString('last_sync_uid', user.uid);
    }

    try {
      await StorageService.fetchAllFromCloud(user.uid);
    } catch (_) {
      // Ignore fetch errors (offline mode falls back to Hive cache)
    }

    if (!mounted) return;

    // Refresh the profile provider so it reads the newly fetched profile
    ref.invalidate(profileProvider);

    final profile = StorageService.getProfile();
    if (profile == null) {
      context.go('/profile-setup');
    } else {
      context.go('/dashboard');
    }
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
