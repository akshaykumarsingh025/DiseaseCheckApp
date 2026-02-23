import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/splash_screen.dart';
import 'screens/disclaimer_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/data_category_screen.dart';
import 'screens/data_entry_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/report_screen.dart';
import 'screens/report_history_screen.dart';
import 'models/report.dart';

class DiseaseCheckApp extends StatelessWidget {
  const DiseaseCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Health Check',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F3460),
          primary: const Color(0xFF0F3460),
          secondary: const Color(0xFFE94560),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      routerConfig: _router,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/disclaimer',
      builder: (context, state) => const DisclaimerScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/data-category',
      builder: (context, state) => const DataCategoryScreen(),
    ),
    GoRoute(
      path: '/data-entry',
      builder: (context, state) => const DataEntryScreen(),
    ),
    GoRoute(
      path: '/processing',
      builder: (context, state) => const ProcessingScreen(),
    ),
    GoRoute(
      path: '/report',
      builder: (context, state) {
        final report = state.extra as HealthReport?;
        return ReportScreen(report: report);
      },
    ),
    GoRoute(
      path: '/report-history',
      builder: (context, state) => const ReportHistoryScreen(),
    ),
  ],
);
