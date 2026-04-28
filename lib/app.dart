import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'services/storage_service.dart';
import 'screens/splash_screen.dart';
import 'screens/disclaimer_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/data_category_screen.dart';
import 'screens/data_entry_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/report_screen.dart';
import 'screens/report_history_screen.dart';
import 'screens/trends_screen.dart';
import 'screens/womens_health_screen.dart';
import 'screens/ocr_scanner_screen.dart';
import 'screens/ocr_review_screen.dart';
import 'screens/ocr_action_screen.dart';
import 'screens/gemma_settings_screen.dart';
import 'models/report.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isAuth = authState.valueOrNull != null;
      final isEmailVerified = authState.valueOrNull?.emailVerified ?? false;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/verify-email';
      final isInitializing = state.matchedLocation == '/' ||
          state.matchedLocation == '/disclaimer';

      if (!isInitializing) {
        // Unauthenticated users can only access login/signup/verify-email
        if (!isAuth && !isLoggingIn) return '/login';

        // Authenticated but unverified — shouldn't happen since we sign out
        // unverified users, but guard just in case
        if (isAuth && !isEmailVerified && !isLoggingIn) {
          return '/verify-email';
        }

        // Authenticated + verified users shouldn't sit on login/signup/verify-email
        if (isAuth && isEmailVerified && isLoggingIn) {
          final hasProfile = StorageService.getProfile() != null;
          return hasProfile ? '/dashboard' : '/profile-setup';
        }

        // Authenticated + verified + no profile → profile-setup
        if (isAuth && isEmailVerified) {
          final hasProfile = StorageService.getProfile() != null;
          if (!hasProfile && state.matchedLocation != '/profile-setup') {
            return '/profile-setup';
          }
        }
      }
      return null;
    },
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
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String?;
          return EmailVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) {
          final isAuth = authState.valueOrNull != null;
          if (!isAuth) return const LoginScreen();
          return const ProfileSetupScreen();
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/data-category',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return DataCategoryScreen(initialValues: extra);
        },
      ),
      GoRoute(
        path: '/data-entry',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          final categories =
              (args['categories'] as List<dynamic>?)?.cast<String>() ?? [];
          final initialValues = args['initialValues'] as Map<String, dynamic>?;
          return DataEntryScreen(
            selectedCategories: categories,
            initialValues: initialValues,
          );
        },
      ),
      GoRoute(
        path: '/processing',
        builder: (context, state) => const ProcessingScreen(),
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) {
          final report = state.extra as HealthReport?;
          if (report == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Risk Assessment Report')),
              body: const Center(
                  child: Text(
                      'No report data found. Please generate a report first.')),
            );
          }
          return ReportScreen(report: report);
        },
      ),
      GoRoute(
        path: '/report-history',
        builder: (context, state) => const ReportHistoryScreen(),
      ),
      GoRoute(
        path: '/trends',
        builder: (context, state) => const TrendsScreen(),
      ),
      GoRoute(
        path: '/womens-health',
        builder: (context, state) => const WomensHealthScreen(),
      ),
      GoRoute(
        path: '/ocr-scanner',
        builder: (context, state) => const OcrScannerScreen(),
      ),
      GoRoute(
        path: '/ocr-review',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final initialValues = extra['values'] as Map<String, dynamic>? ?? {};
          final rawText = extra['rawText'] as String? ?? '';
          return OcrReviewScreen(
              initialValues: initialValues, rawText: rawText);
        },
      ),
      GoRoute(
        path: '/ocr-action',
        builder: (context, state) => const OcrActionScreen(),
      ),
      GoRoute(
        path: '/ai-settings',
        builder: (context, state) => const GemmaSettingsScreen(),
      ),
    ],
  );
});

class DiseaseCheckApp extends ConsumerWidget {
  const DiseaseCheckApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeProvider);

    // While theme is loading from SharedPreferences, show a brief splash
    // to prevent the red error screen flash
    final isDark = themeState.when(
      data: (value) => value,
      loading: () => false, // default to light while loading
      error: (_, __) => false,
    );

    return MaterialApp.router(
      title: 'Health Check',
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F3460),
          primary: const Color(0xFF0F3460),
          secondary: const Color(0xFFE94560),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: Brightness.light).textTheme,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F3460),
          primary: const Color(0xFF4A90D9),
          secondary: const Color(0xFFE94560),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      ),
      routerConfig: router,
    );
  }
}
