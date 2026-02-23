import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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

    // 1. First launch — show disclaimer
    if (!disclaimerAccepted) {
      context.go('/disclaimer');
      return;
    }

    // 2. Check if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    // 3. User is logged in — fetch cloud data and go to dashboard
    try {
      await StorageService.fetchAllFromCloud(user.uid);
    } catch (_) {
      // Ignore fetch errors (offline mode falls back to Hive cache)
    }

    // 4. Check if user has a profile
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
