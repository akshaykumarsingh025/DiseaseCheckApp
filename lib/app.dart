import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/feature_flags.dart';
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
import 'screens/main_shell.dart';
import 'screens/health_feed_screen.dart';
import 'services/health_news_service.dart';
import 'widgets/health_feed_section.dart';
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
import 'screens/book_appointment_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/diet_plan_screen.dart';
import 'screens/compare_reports_screen.dart';
import 'screens/online_opd_screen.dart';
import 'screens/doctor_opd_screen.dart';
import 'screens/video_call_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/diet_plans_screen.dart';
import 'screens/diet_plan_detail_screen.dart';
import 'screens/profile_switcher_screen.dart';
import 'screens/app_lock_setup_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/pcos_screener_screen.dart';
import 'screens/due_date_calculator_screen.dart';
import 'screens/period_tracker_screen.dart';
import 'screens/bmi_pcos_risk_screen.dart';
import 'screens/fertility_score_screen.dart';
import 'screens/write_prescription_screen.dart';
import 'screens/my_prescriptions_screen.dart';
import 'screens/medications_screen.dart';
import 'screens/wellness_screen.dart';
import 'screens/symptom_checker_screen.dart';
import 'screens/weekly_digest_screen.dart';
import 'models/report.dart';
import 'models/appointment.dart';

/// Notifies GoRouter that `redirect` should re-run.
///
/// Deliberately not a `ref.watch` on the auth state: watching would rebuild the
/// whole GoRouter on every sign-in/sign-out, tearing down the live Navigator
/// mid-frame and blanking the screen. Refreshing re-runs the redirect against
/// the same router instead.
class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(authStateProvider, (_, __) => refresh.ping());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      if (authState.isLoading) return null;

      final user = authState.valueOrNull;
      final isAuth = user != null;
      final isEmailVerified = user?.emailVerified == true ||
          FeatureFlags.canBypassEmailVerification(user?.email);
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

        // Authenticated + verified + no profile → profile-setup (skip for doctor)
        if (isAuth && isEmailVerified) {
          final isDoctor = FeatureFlags.isDoctor;
          final hasProfile = StorageService.getProfile() != null;
          if (!isDoctor && !hasProfile && state.matchedLocation != '/profile-setup') {
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
          final isAuth = ref.read(authStateProvider).valueOrNull != null;
          if (!isAuth) return const LoginScreen();
          return const ProfileSetupScreen();
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/womens-health-news',
        builder: (context, state) => HealthFeedScreen(
          title: "Women's Health News",
          subtitle: 'Live headlines from trusted news sources',
          provider: womensHealthNewsProvider,
          fallbackBuilder: womensHealthNewsFallback,
          itemIcon: Icons.article_outlined,
        ),
      ),
      GoRoute(
        path: '/natural-remedies',
        builder: (context, state) => HealthFeedScreen(
          title: 'Natural Remedies',
          subtitle: 'Latest natural & herbal remedy updates',
          provider: naturalRemediesProvider,
          fallbackBuilder: naturalRemediesFallback,
          itemIcon: Icons.spa_outlined,
        ),
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
        path: '/book-appointment',
        builder: (context, state) => const BookAppointmentScreen(),
      ),
      GoRoute(
        path: '/ai-chat',
        builder: (context, state) {
          final report = state.extra as HealthReport?;
          return AiChatScreen(
              report: report ??
                  HealthReport(
                      reportId: '',
                      date: DateTime.now(),
                      highRiskDiseases: [],
                      moderateRiskDiseases: [],
                      lowRiskDiseases: [],
                      abnormalValues: []));
        },
      ),
      GoRoute(
        path: '/diet-plan',
        builder: (context, state) {
          final report = state.extra as HealthReport?;
          return DietPlanScreen(
              report: report ??
                  HealthReport(
                      reportId: '',
                      date: DateTime.now(),
                      highRiskDiseases: [],
                      moderateRiskDiseases: [],
                      lowRiskDiseases: [],
                      abnormalValues: []));
        },
      ),
      GoRoute(
        path: '/compare-reports',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CompareReportsScreen(
            report1: extra?['report1'] as HealthReport,
            report2: extra?['report2'] as HealthReport,
          );
        },
      ),
      GoRoute(
        path: '/online-opd',
        builder: (context, state) =>
            FeatureFlags.isDoctor ? const DoctorOpdScreen() : const OnlineOpdScreen(),
      ),
      GoRoute(
        path: '/video-call',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final appointment = extra?['appointment'] as Appointment?;
          if (appointment == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Video Call')),
              body: const Center(child: Text('No appointment data found.')),
            );
          }
          return VideoCallScreen(appointment: appointment);
        },
      ),
      GoRoute(
        path: '/courses',
        builder: (context, state) => FeatureFlags.healthCoursesEnabled
            ? const CoursesScreen()
            : const _DisabledFeatureScreen(title: 'Health Courses'),
      ),
      GoRoute(
        path: '/course-detail',
        builder: (context, state) {
          if (!FeatureFlags.healthCoursesEnabled) {
            return const _DisabledFeatureScreen(title: 'Health Courses');
          }
          final extra = state.extra as Map<String, dynamic>?;
          final courseId = extra?['courseId'] as String? ?? '';
          return CourseDetailScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/diet-plans',
        builder: (context, state) => const DietPlansScreen(),
      ),
      GoRoute(
        path: '/profile-switcher',
        builder: (context, state) => const ProfileSwitcherScreen(),
      ),
      GoRoute(
        path: '/app-lock-setup',
        builder: (context, state) => const AppLockSetupScreen(),
      ),
      GoRoute(
        path: '/diet-plan-detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final planId = extra?['planId'] as String? ?? '';
          return DietPlanDetailScreen(planId: planId);
        },
      ),
      GoRoute(
        path: '/pcos-screener',
        builder: (context, state) => const PcosScreenerScreen(),
      ),
      GoRoute(
        path: '/due-date-calculator',
        builder: (context, state) => const DueDateCalculatorScreen(),
      ),
      GoRoute(
        path: '/period-tracker',
        builder: (context, state) => const PeriodTrackerScreen(),
      ),
      GoRoute(
        path: '/bmi-pcos-risk',
        builder: (context, state) => const BmiPcosRiskScreen(),
      ),
      GoRoute(
        path: '/fertility-score',
        builder: (context, state) => const FertilityScoreScreen(),
      ),
      GoRoute(
        path: '/write-prescription',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final appointment = extra?['appointment'] as Appointment?;
          if (appointment == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Write Prescription')),
              body: const Center(child: Text('No appointment data found.')),
            );
          }
          return WritePrescriptionScreen(appointment: appointment);
        },
      ),
      GoRoute(
        path: '/my-prescriptions',
        builder: (context, state) => const MyPrescriptionsScreen(),
      ),
      GoRoute(
        path: '/medications',
        builder: (context, state) => const MedicationsScreen(),
      ),
      GoRoute(
        path: '/wellness',
        builder: (context, state) => const WellnessScreen(),
      ),
      GoRoute(
        path: '/symptom-checker',
        builder: (context, state) => const SymptomCheckerScreen(),
      ),
      GoRoute(
        path: '/weekly-digest',
        builder: (context, state) => const WeeklyDigestScreen(),
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

    return LockScreen(
      child: MaterialApp.router(
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
    ),
    );
  }
}

class _DisabledFeatureScreen extends StatelessWidget {
  final String title;

  const _DisabledFeatureScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'This section is temporarily unavailable.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
