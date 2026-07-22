# Graph Report - .  (2026-07-17)

## Corpus Check
- 207 files · ~104,234 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2105 nodes · 2790 edges · 149 communities (128 shown, 21 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 79 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Windows Platform Plugin
- Appointment Providers
- PDF Report Generation
- App Router & Theme
- Gemma AI Provider
- Video Call Screen
- Rule Engine Diseases
- Storage Service
- Gemma ML Service
- Course Providers
- AI API Service
- Diet Plan Screen
- Risk Result Model
- Appointment Service
- Gemma Settings Screen
- Payment Service
- Report Screen
- Report History Screen
- Write Prescription Screen
- Health Data & Profile
- Linux Platform Plugin
- Appointment Model
- Period Tracker Screen
- OCR Scanner Screen
- BMI & PCOS Risk
- Prescription Model
- Diet Plan Package Provider
- Doctor Info Utils
- User Model
- Course Model
- Dashboard Screen
- App Lock Service
- Remote Config Service
- Firebase Dependencies
- Package Dependencies
- Auth & Login Screens
- Due Date Calculator
- Lock Screen
- Fertility Score Screen
- Cloud Functions
- Engine Package Nodes
- PCOS Screener Screen
- Auth Service
- AI Chat Screen
- Health Data Model
- Report Model
- Report Provider & Processing
- Notification Service
- Disease Research Docs
- Data Entry Screen
- Community 50
- Community 51
- Community 52
- Community 53
- Community 54
- Community 55
- Community 56
- Community 57
- Community 58
- Community 59
- Community 60
- Community 61
- Community 62
- Community 63
- Community 64
- Community 65
- Community 66
- Community 67
- Community 68
- Community 69
- Community 70
- Community 71
- Community 72
- Community 73
- Community 74
- Community 75
- Community 76
- Community 77
- Community 78
- Community 79
- Community 80
- Community 81
- Community 82
- Community 83
- Community 84
- Community 85
- Community 86
- Community 87
- Community 88
- Community 89
- Community 90
- Community 91
- Community 92
- Community 93
- Community 94
- Community 95
- Community 96
- Community 97
- Community 98
- Community 99
- Community 100
- Community 101
- Community 102
- Community 103
- Community 104
- Community 105
- Community 106
- Community 107
- Community 108
- Community 109
- Community 110
- Community 111
- Community 112
- Community 113
- Community 114
- Community 115
- Community 116
- Community 117
- Community 118
- Community 119
- Community 120
- Community 121
- Community 122
- Community 123
- Community 124
- Community 125
- Community 126
- Community 127
- Community 128
- Community 132
- Community 133
- Community 134
- Community 135
- Community 136
- Community 137
- Community 138
- Community 139
- Community 140
- Community 141
- Community 142
- Community 143
- Community 144
- Community 145
- Community 146
- Community 148

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 22 edges
2. `build` - 21 edges
3. `Rule Engine` - 19 edges
4. `authServiceProvider` - 15 edges
5. `gemmaProvider` - 15 edges
6. `profileProvider` - 15 edges
7. `MessageHandler` - 12 edges
8. `Pubspec Lock` - 11 edges
9. `FlutterWindow` - 10 edges
10. `Create` - 10 edges

## Surprising Connections (you probably didn't know these)
- `Zero-Cost Constraint` --semantically_similar_to--> `Ad Monetization Strategy`  [INFERRED] [semantically similar]
  UpgradeOption.md → PLAN_IMPROVEMENTS.md
- `ReferenceRanges (Unused)` --conceptually_related_to--> `Rule Engine`  [INFERRED]
  IMPROVEMENTS.md → README.md
- `MLEngine (Stubbed)` --semantically_similar_to--> `Hybrid Detection (Rule + ML)`  [INFERRED] [semantically similar]
  IMPROVEMENTS.md → UpgradeOption.md
- `Linux Root CMakeLists` --semantically_similar_to--> `Windows Root CMakeLists`  [INFERRED] [semantically similar]
  linux/CMakeLists.txt → windows/CMakeLists.txt
- `Linux Flutter CMakeLists` --semantically_similar_to--> `Windows Flutter CMakeLists`  [INFERRED] [semantically similar]
  linux/flutter/CMakeLists.txt → windows/flutter/CMakeLists.txt

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Rule Engine Disease Detection Pipeline** — README_RuleEngine, IMPROVEMENTS_ProcessingScreen, IMPROVEMENTS_ReportGenerator, IMPROVEMENTS_ReferenceRanges [INFERRED 0.85]
- **Offline-First Sync Architecture (Hive + Firestore)** — README_Hive, README_Firestore, IMPROVEMENTS_StorageService, UPGRADE_OfflineFirst [INFERRED 0.80]
- **Ad + Payment Monetization Stack** — PLANIMPROVEMENTS_AdService, PLANIMPROVEMENTS_UsageCounterService, PLAN_PaymentService, SETUP_AdMob, SETUP_Razorpay [EXTRACTED 0.90]
- **Flutter Multi-Platform CMake Build System** — linux_cmake_root, linux_flutter_cmake, linux_runner_cmake, windows_cmake_root, windows_flutter_cmake, windows_runner_cmake [INFERRED 0.85]
- **Firebase Ecosystem Dependencies** — dep_firebase_core, dep_firebase_auth, dep_cloud_firestore, dep_cloud_functions [INFERRED 0.90]
- **PWA Web Icon Set** — web_icon_192, web_icon_512, web_icon_maskable_192, web_icon_maskable_512, web_favicon [INFERRED 0.85]

## Communities (149 total, 21 thin omitted)

### Community 0 - "Windows Platform Plugin"
Cohesion: 0.06
Nodes (53): PluginRegistry, Point, RECT, Size, unique_ptr, RegisterPlugins(), DartProject, HWND (+45 more)

### Community 1 - "Appointment Providers"
Cohesion: 0.05
Nodes (50): activeAppointmentProvider, appointments, appointmentServiceProvider, availableDatesProvider, availableSlotsProvider, getAvailableDates, getAvailableSlots, getUserAppointmentsStream (+42 more)

### Community 2 - "PDF Report Generation"
Cohesion: 0.04
Nodes (48): Font?, _abnormalPurple, _abnormalPurpleBg, _accentBlue, _boldFont, _boldItalicFont, _buildAbnormalTable, _buildAISection (+40 more)

### Community 3 - "App Router & Theme"
Cohesion: 0.04
Nodes (47): GoRouter, authState, build, DiseaseCheckApp, routerProvider, title, themeProvider, package:google_fonts/google_fonts.dart (+39 more)

### Community 4 - "Gemma AI Provider"
Cohesion: 0.04
Nodes (44): double?, cancelDownload, copyWith, deleteModel, downloadedBytes, downloadError, downloadProgress, GemmaNotifier (+36 more)

### Community 5 - "Video Call Screen"
Cohesion: 0.04
Nodes (44): EventsListener, appointment, build, _buildAppointmentInfo, _buildCallHeader, _buildCallView, _buildControlButton, _buildControls (+36 more)

### Community 6 - "Rule Engine Diseases"
Cohesion: 0.05
Nodes (39): _buildResult, checkAlcoholicLiverDisease, checkAnemia, checkB12Deficiency, checkCardiacRisk, checkCervicalCancerRisk, checkCholesterol, checkCKDStaging (+31 more)

### Community 7 - "Storage Service"
Cohesion: 0.05
Nodes (37): _auth, clearAllLocalData, deleteAccount, deleteEncryptionKey, deleteHealthData, deleteProfile, deleteReport, _encryptionKeyStorageKey (+29 more)

### Community 8 - "Gemma ML Service"
Cohesion: 0.05
Nodes (36): buildRawReportText, cancelDownload, cancelGeneration, _cancelled, _channel, deleteModel, _downloadCancelToken, downloadModel (+28 more)

### Community 9 - "Course Providers"
Cohesion: 0.07
Nodes (33): courseDetailProvider, courses, coursesProvider, freeCoursesProvider, getCourseById, getCoursesStream, isEnrolled, isEnrolledProvider (+25 more)

### Community 10 - "AI API Service"
Cohesion: 0.06
Nodes (35): AiApiResult, AiApiService, _aiModePref, _baseRetryDelay, _callLocalModel, _callOllama, _callOpenRouter, _callWithRetry (+27 more)

### Community 11 - "Diet Plan Screen"
Cohesion: 0.06
Nodes (34): _buildCategoryCard, _buildCategorySelection, _buildDoctorCard, _buildErrorState, _buildPlanCard, _buildPlanResult, _categories, color (+26 more)

### Community 12 - "Risk Result Model"
Cohesion: 0.06
Nodes (31): build, disease, findings, guideline, icdCode, riskLevel, RiskResult, riskScore (+23 more)

### Community 13 - "Appointment Service"
Cohesion: 0.06
Nodes (31): _activeBookingStatuses, _appointmentIdFor, cancelAppointment, completeAppointment, confirmPayment, createAppointment, createEmergencyAppointment, _doctorId (+23 more)

### Community 14 - "Gemma Settings Screen"
Cohesion: 0.08
Nodes (30): gemmaProvider, _sendMessage, _generatePlan, _aiMode, build, _buildAiModeSection, _buildDeleteSection, _buildDownloadSection (+22 more)

### Community 15 - "Payment Service"
Cohesion: 0.06
Nodes (30): _checkoutCompleter, dietPlanPrice, dispose, _disposeRazorpay, error, getFeatureName, getPrice, _handleExternalWallet (+22 more)

### Community 16 - "Report Screen"
Cohesion: 0.07
Nodes (29): dart:typed_data, _aiRefinedText, _buildAbnormalitiesSection, _buildActionCard, _buildAIRefinementSection, _buildAuditTrailSection, _buildEmergencyAlert, _buildEmptyState (+21 more)

### Community 17 - "Report History Screen"
Cohesion: 0.07
Nodes (29): _allReports, _applyFilter, build, _buildChip, _buildReportCard, _compareReports, createState, _currentPage (+21 more)

### Community 18 - "Write Prescription Screen"
Cohesion: 0.07
Nodes (27): FormState, _adviceCtrl, appointment, build, _buildPatientCard, _buildSectionTitle, _chiefComplaintCtrl, createState (+19 more)

### Community 19 - "Health Data & Profile"
Cohesion: 0.11
Nodes (22): class, addHealthData, getCategoryData, HealthDataNotifier, ProfileNotifier, saveProfile, addReport, ReportNotifier (+14 more)

### Community 20 - "Linux Platform Plugin"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 21 - "Appointment Model"
Cohesion: 0.07
Nodes (26): joined,
  ongoing,
  completed,
  cancelled,, amount, Appointment, appointmentId, AppointmentStatus, copyWith, createdAt, date (+18 more)

### Community 22 - "Period Tracker Screen"
Cohesion: 0.08
Nodes (25): DateTime? get, build, _buildCalendarPreview, _buildCycleOverviewCard, _buildFertileWindowCard, _buildInputCard, _buildLegend, _buildMiniStat (+17 more)

### Community 23 - "OCR Scanner Screen"
Cohesion: 0.09
Nodes (24): ../engine/ocr_parser.dart, File?, ImagePicker, build, createState, dispose, _image, _isProcessing (+16 more)

### Community 24 - "BMI & PCOS Risk"
Cohesion: 0.08
Nodes (24): _age, _bmiCategory, build, _buildBmiResultCard, _buildBmiScaleCard, _buildInputCard, _buildMetabolicRiskCard, _buildPcosRiskCard (+16 more)

### Community 25 - "Prescription Model"
Cohesion: 0.08
Nodes (23): advice, appointmentDate, appointmentId, appointmentTime, chiefComplaint, createdAt, diagnosis, doctorId (+15 more)

### Community 26 - "Diet Plan Package Provider"
Cohesion: 0.11
Nodes (22): dietPlanDetailProvider, getDietPlanById, getDietPlansStream, isDietPlanPurchasedProvider, isPurchased, build, _buildDoctorCard, _buildFoodList (+14 more)

### Community 27 - "Doctor Info Utils"
Cohesion: 0.09
Nodes (22): address, clinicHoursSunday, clinicHoursWeekday, DoctorInfo, email, emailUrl, experience, facebook (+14 more)

### Community 28 - "User Model"
Cohesion: 0.09
Nodes (21): hashCode, operator, read, typeId, write, age, cycleRegularity, displayName (+13 more)

### Community 29 - "Course Model"
Cohesion: 0.09
Nodes (21): category, content, Course, courseId, CourseLesson, CourseSection, createdAt, description (+13 more)

### Community 30 - "Dashboard Screen"
Cohesion: 0.09
Nodes (21): _adFree, _bannerAd, _bannerLoaded, _buildBmiCard, _buildDashboardCard, _buildRemoveAdsCard, _buildToolCard, _buyRemoveAds (+13 more)

### Community 31 - "App Lock Service"
Cohesion: 0.09
Nodes (21): AppLockService, authenticate, clearBackgroundTime, disableLock, enableBiometricLock, enablePinLock, getLockType, _lastBackgroundKey (+13 more)

### Community 32 - "Remote Config Service"
Cohesion: 0.09
Nodes (21): admobBannerId, admobInterstitialId, adsEnabled, _cacheExpiryHours, _config, _defaultGroqApiKey, _defaultGroqBaseUrl, _defaultGroqModel (+13 more)

### Community 33 - "Firebase Dependencies"
Cohesion: 0.10
Nodes (20): cloud_firestore, cloud_functions, connectivity_plus, device_info_plus, file_picker, file_selector_macos, firebase_auth, firebase_core (+12 more)

### Community 34 - "Package Dependencies"
Cohesion: 0.14
Nodes (20): build_runner 2.4.13, cloud_firestore 5.6.12, cloud_functions 5.6.2, dio 5.9.1, firebase_auth 5.7.0, firebase_core 3.15.2, flutter_riverpod 2.6.1, flutter_secure_storage 9.2.4 (+12 more)

### Community 35 - "Auth & Login Screens"
Cohesion: 0.13
Nodes (19): authServiceProvider, _refreshData, _resendVerification, _sendResetEmail, build, createState, _formKey, _isGoogleLoading (+11 more)

### Community 36 - "Due Date Calculator"
Cohesion: 0.11
Nodes (19): build, _buildCycleLengthCard, _buildEddResultCard, _buildLmpCard, _buildMilestonesCard, _buildPregnancyProgressCard, _buildStatCard, _buildTipsCard (+11 more)

### Community 37 - "Lock Screen"
Cohesion: 0.11
Nodes (19): _authenticate, build, _buildBiometricPrompt, _buildPinPad, _buildPinRows, _checkAndShowLock, _checkInitialLock, child (+11 more)

### Community 38 - "Fertility Score Screen"
Cohesion: 0.11
Nodes (18): Color, IconData, _answers, build, _buildBreakdownCard, _buildQuestionnaire, _buildRecommendationsCard, createState (+10 more)

### Community 39 - "Cloud Functions"
Cohesion: 0.11
Nodes (18): firebase-admin, firebase-functions, dependencies, firebase-admin, firebase-functions, livekit-server-sdk, description, engines (+10 more)

### Community 40 - "Engine Package Nodes"
Cohesion: 0.12
Nodes (15): ../lib/engine/ocr_parser.dart, package:disease_check_app/engine/ocr_parser.dart, package:disease_check_app/engine/report_generator.dart, package:disease_check_app/engine/risk_result.dart, package:disease_check_app/engine/rule_engine.dart, package:disease_check_app/models/health_data.dart, package:disease_check_app/utils/test_definitions.dart, package:flutter_test/flutter_test.dart (+7 more)

### Community 41 - "PCOS Screener Screen"
Cohesion: 0.11
Nodes (18): _answers, build, _buildCriterionRow, _buildQuestionnaire, _canProceed, createState, _currentQuestion, description (+10 more)

### Community 42 - "Auth Service"
Cohesion: 0.11
Nodes (17): FirebaseAuth, GoogleSignIn, _auth, authStateChanges, currentUser, _friendlyError, _googleSignIn, _isDoctorAccount (+9 more)

### Community 43 - "AI Chat Screen"
Cohesion: 0.12
Nodes (17): AiChatScreen, _AiChatScreenState, _buildMessageBubble, _buildQuickQuestions, _ChatMessage, _controller, createState, dispose (+9 more)

### Community 44 - "Health Data Model"
Cohesion: 0.12
Nodes (16): hashCode, operator, read, typeId, write, DateTime, int?, category (+8 more)

### Community 45 - "Report Model"
Cohesion: 0.12
Nodes (16): hashCode, operator, read, typeId, write, int get, abnormalValues, aiRefinedText (+8 more)

### Community 46 - "Report Provider & Processing"
Cohesion: 0.14
Nodes (16): ../engine/report_generator.dart, reportProvider, currentSessionProvider, createState, dispose, _error, initState, _isProcessing (+8 more)

### Community 47 - "Notification Service"
Cohesion: 0.12
Nodes (16): cancelAllReminders, cancelReminder, _channelDesc, _channelId, _channelName, init, NotificationService, _onNotificationTapped (+8 more)

### Community 48 - "Disease Research Docs"
Cohesion: 0.12
Nodes (16): Women Health Hub, Blood & Hematology Diseases (7), Cardiovascular Diseases (4), Kidney Diseases (8), Liver Diseases (3), Metabolic & Diabetes Diseases (2), Thyroid Disorders (2), Vital Signs Abnormalities (7) (+8 more)

### Community 49 - "Data Entry Screen"
Cohesion: 0.13
Nodes (15): ../engine/critical_value_checker.dart, build, _buildDynamicFields, _clearDraft, _combineWithHistory, createState, DataEntryScreen, _DataEntryScreenState (+7 more)

### Community 50 - "Community 50"
Cohesion: 0.14
Nodes (14): FormBuilderState, build, _buildFormView, createState, _emailSent, ForgotPasswordScreen, _ForgotPasswordScreenState, _formKey (+6 more)

### Community 51 - "Community 51"
Cohesion: 0.13
Nodes (15): Future, build, _buildCard, _buildEmptyState, _busy, createState, _download, _future (+7 more)

### Community 52 - "Community 52"
Cohesion: 0.21
Nodes (9): DownloadForegroundService, start(), stop(), updateProgress(), Context, IBinder, Intent, Notification (+1 more)

### Community 53 - "Community 53"
Cohesion: 0.14
Nodes (14): ConsumerWidget, ../engine/risk_result.dart, ../engine/rule_engine.dart, healthDataProvider, build, _submitForm, build, _buildHeaderCard (+6 more)

### Community 54 - "Community 54"
Cohesion: 0.13
Nodes (15): build, _buildResult, Route /app-lock-setup, Route /bmi-pcos-risk, Route /courses, Route /due-date-calculator, Route /fertility-score, Route /my-prescriptions (+7 more)

### Community 55 - "Community 55"
Cohesion: 0.13
Nodes (14): celsiusToFahrenheit, cholMgDlToMmolL, cholMmolLToMgDl, cmToInches, fahrenheitToCelsius, inchesToCm, kgToLbs, lbsToKg (+6 more)

### Community 56 - "Community 56"
Cohesion: 0.27
Nodes (14): APPLICATION_ID com.healthcheck.disease_check_app, Apply Standard Settings Function, BINARY_NAME disease_check_app, C++ Client Wrapper, Flutter Assemble Build Target, Flutter Linux GTK Library, Flutter Windows DLL, GTK3 System Dependency (+6 more)

### Community 57 - "Community 57"
Cohesion: 0.21
Nodes (14): ConsumerState, ConsumerStatefulWidget, profileProvider, BmiPcosRiskScreen, _BmiPcosRiskScreenState, initState, DashboardScreen, _DashboardScreenState (+6 more)

### Community 58 - "Community 58"
Cohesion: 0.15
Nodes (13): AppLockSetupScreen, _AppLockSetupScreenState, build, _confirmPinController, createState, dispose, _enableBiometric, _enablePin (+5 more)

### Community 59 - "Community 59"
Cohesion: 0.14
Nodes (13): _firestore, generatePrescriptionPdf, getDoctorPrescriptions, getPatientPrescriptions, getPrescription, PrescriptionService, savePrescription, sharePrescriptionPdf (+5 more)

### Community 60 - "Community 60"
Cohesion: 0.15
Nodes (12): app.dart, dart:async, firebase_options.dart, build, ensureDoctorAccount, error, init, _initBackgroundServices (+4 more)

### Community 61 - "Community 61"
Cohesion: 0.17
Nodes (12): BannerAd?, _banner, BannerAdWidget, _BannerAdWidgetState, build, createState, dispose, initState (+4 more)

### Community 62 - "Community 62"
Cohesion: 0.15
Nodes (12): ../config/livekit_config.dart, dart:convert, _createAccessToken, endMeeting, generateToken, joinMeeting, startMeeting, updateCallStatus (+4 more)

### Community 63 - "Community 63"
Cohesion: 0.15
Nodes (11): MLEngine, generate, ReportGenerator, evaluateAll, mlEngine, RiskAggregator, ml_engine.dart, ../models/report.dart (+3 more)

### Community 64 - "Community 64"
Cohesion: 0.15
Nodes (12): build, _buildClinicInfo, _buildContactButtons, _buildCredentialItem, _buildCredentials, _buildDoctorCard, _buildInfoRow, _buildSpecializations (+4 more)

### Community 65 - "Community 65"
Cohesion: 0.18
Nodes (12): build, _combineWithHistory, createState, _formKey, initialValues, _isSubmitting, OcrReviewScreen, _OcrReviewScreenState (+4 more)

### Community 66 - "Community 66"
Cohesion: 0.15
Nodes (12): adsAreEnabledForUser, AdService, createBanner, dispose, _interstitial, _loadingInterstitial, loadInterstitial, onSuccessfulGenerationAndMaybeShow (+4 more)

### Community 67 - "Community 67"
Cohesion: 0.15
Nodes (12): _cache, clear, diseases, guidelines, init, _initialized, isInitialized, JsonCacheService (+4 more)

### Community 68 - "Community 68"
Cohesion: 0.18
Nodes (12): Qwen3 (0.6B/0.8B LLM), DiseaseCheckApp, AuthService, StorageService, Firestore Security Rules, Hive Box Encryption, Firestore, Hive (+4 more)

### Community 69 - "Community 69"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 70 - "Community 70"
Cohesion: 0.17
Nodes (11): checkValues, CriticalValue, CriticalValueChecker, _getLabel, _getUnit, key, label, message (+3 more)

### Community 71 - "Community 71"
Cohesion: 0.20
Nodes (12): _goBackToLogin, _buildSuccessView, build, build, build, build, _initializeApp, build (+4 more)

### Community 72 - "Community 72"
Cohesion: 0.31
Nodes (5): MainActivity, Engine, FlutterActivity, FlutterEngine, MethodChannel

### Community 73 - "Community 73"
Cohesion: 0.18
Nodes (10): @JsonSerializable, category, detectionMethod, Disease, fromJson, icd10, id, name (+2 more)

### Community 74 - "Community 74"
Cohesion: 0.18
Nodes (10): _DisabledFeatureScreen, ErrorApp, BookAppointmentScreen, CompareReportsScreen, build, OcrActionScreen, HealthInputForm, Route /data-category (+2 more)

### Community 75 - "Community 75"
Cohesion: 0.20
Nodes (10): _buildChartCard, _buildEmptyState, _buildNotEnoughData, createState, _formatAxisValue, _showDeleteDialog, TrendsScreen, _TrendsScreenState (+2 more)

### Community 76 - "Community 76"
Cohesion: 0.18
Nodes (10): CourseService, enrollFreeCourse, enrollPaidCourse, _firestore, getCourseById, getCourses, getCoursesStream, getEnrolledCourses (+2 more)

### Community 77 - "Community 77"
Cohesion: 0.18
Nodes (10): _cachedDoctorUid, _createOrLookupDoctor, DoctorAccountService, doctorEmail, doctorPassword, ensureDoctorAccount, isDoctorEmail, _saveDoctorUidToConfig (+2 more)

### Community 78 - "Community 78"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 79 - "Community 79"
Cohesion: 0.22
Nodes (10): Disease Check App, Flutter Bootstrap JS, PWA Manifest, iOS LaunchImage README, Web Favicon, Web Icon 192px, Web Icon 512px, Web Maskable Icon 192px (+2 more)

### Community 80 - "Community 80"
Cohesion: 0.20
Nodes (9): _, canBypassEmailVerification, emergencyOpdTestingEnabled, FeatureFlags, firebaseTestAccountsEnabled, healthCoursesEnabled, ../services/doctor_account_service.dart, ../services/remote_config_service.dart (+1 more)

### Community 81 - "Community 81"
Cohesion: 0.20
Nodes (9): GlobalKey, build, child, formKey, onSubmit, submitLabel, package:flutter_form_builder/flutter_form_builder.dart, VoidCallback (+1 more)

### Community 82 - "Community 82"
Cohesion: 0.22
Nodes (9): dietPlansProvider, build, _buildPlanCard, _buildPlanFeature, DietPlansScreen, _getGradientColors, _getIssueIcon, package:go_router/go_router.dart (+1 more)

### Community 83 - "Community 83"
Cohesion: 0.20
Nodes (9): DietPlanPackageService, _firestore, getDietPlanById, getDietPlans, getDietPlansStream, getPurchasedPlans, isPurchased, purchasePlan (+1 more)

### Community 84 - "Community 84"
Cohesion: 0.20
Nodes (9): _everyN, _firstAdAt, incrementGeneration, isAdDue, _key, shouldShowAd, totalGenerations, UsageCounterService (+1 more)

### Community 85 - "Community 85"
Cohesion: 0.25
Nodes (8): ../config/feature_flags.dart, build, createState, _fetchCloudInBackground, initState, SplashScreen, _SplashScreenState, ../providers/profile_provider.dart

### Community 86 - "Community 86"
Cohesion: 0.22
Nodes (8): _fallbackRanges, getRange, isAbnormal, loadRanges, _ranges, ReferenceRanges, static const Map, static Map

### Community 87 - "Community 87"
Cohesion: 0.22
Nodes (8): android, DefaultFirebaseOptions, ios, macos, web, package:firebase_core/firebase_core.dart, package:flutter/foundation.dart, static const FirebaseOptions

### Community 88 - "Community 88"
Cohesion: 0.25
Nodes (8): categories, createState, DataCategoryScreen, _DataCategoryScreenState, initialValues, initState, _selected, Set

### Community 89 - "Community 89"
Cohesion: 0.25
Nodes (8): build, createState, email, EmailVerificationScreen, _EmailVerificationScreenState, _isNavigatingToLogin, _isResending, ../providers/auth_provider.dart

### Community 90 - "Community 90"
Cohesion: 0.25
Nodes (8): build, createState, _formKey, _isGoogleLoading, _isLoading, _obscurePassword, SignupScreen, _SignupScreenState

### Community 91 - "Community 91"
Cohesion: 0.32
Nodes (8): @HiveType, HealthDataAdapter, HealthReportAdapter, UserProfileAdapter, HealthData, HealthReport, UserProfile, TypeAdapter

### Community 92 - "Community 92"
Cohesion: 0.25
Nodes (6): Any, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, AppDelegate, Bool, UIApplication

### Community 93 - "Community 93"
Cohesion: 0.25
Nodes (7): AsyncValue, isDark, _key, _loadPreference, ThemeNotifier, toggle, static const

### Community 94 - "Community 94"
Cohesion: 0.25
Nodes (7): bool get, dart:developer, dispose, isReady, loadModels, _modelsLoaded, predictDiabetes

### Community 95 - "Community 95"
Cohesion: 0.25
Nodes (7): dart:io, Map, file, main, results, testsToCheck, text

### Community 96 - "Community 96"
Cohesion: 0.25
Nodes (7): build, _buildAbnormalComparison, _buildHeader, _buildRiskComparison, _buildScoreChip, report1, report2

### Community 97 - "Community 97"
Cohesion: 0.25
Nodes (8): VideoCallScreen, _VideoCallScreenState, ParticipantConnectedEvent, ParticipantDisconnectedEvent, RoomDisconnectedEvent, StatefulWidget, TrackSubscribedEvent, TrackUnsubscribedEvent

### Community 98 - "Community 98"
Cohesion: 0.25
Nodes (6): build, DisclaimerBanner, text, package:disease_check_app/app.dart, package:flutter/material.dart, main

### Community 99 - "Community 99"
Cohesion: 0.33
Nodes (7): Prescription Enhancement, Ad Monetization Strategy, AdService, UsageCounterService, PaymentService, Google AdMob, Razorpay

### Community 100 - "Community 100"
Cohesion: 0.29
Nodes (6): _, apiKey, apiSecret, LiveKitConfig, url, static const String

### Community 101 - "Community 101"
Cohesion: 0.38
Nodes (4): Flutter, FlutterSceneDelegate, SceneDelegate, UIKit

### Community 102 - "Community 102"
Cohesion: 0.29
Nodes (7): build, build, _buildActionButtons, _buildDoctorCard, Route /ai-chat, Route /book-appointment, Route /diet-plan

### Community 103 - "Community 103"
Cohesion: 0.29
Nodes (6): calculateOverallRisk, riskCritical, riskHigh, riskLow, riskModerate, RiskScoring

### Community 104 - "Community 104"
Cohesion: 0.33
Nodes (6): ICD API Service, feature_flags.dart, Release Signing Config, Security Hardening Phase, Offline-First Architecture, Zero-Cost Constraint

### Community 105 - "Community 105"
Cohesion: 0.47
Nodes (3): Cocoa, FlutterMacOS, XCTest

### Community 106 - "Community 106"
Cohesion: 0.33
Nodes (5): dart:math, calculateCKDEPI, convertCreatinineMgDlToUmol, convertCreatinineUmolToMgDl, EgfrCalculator

### Community 107 - "Community 107"
Cohesion: 0.47
Nodes (4): FlutterAppDelegate, AppDelegate, Bool, NSApplication

### Community 108 - "Community 108"
Cohesion: 0.33
Nodes (5): FlutterPluginRegistry, FlutterViewController, RegisterGeneratedPlugins(), MainFlutterWindow, NSWindow

### Community 109 - "Community 109"
Cohesion: 0.33
Nodes (5): authService, authStateProvider, AuthService, package:firebase_auth/firebase_auth.dart, ../services/auth_service.dart

### Community 110 - "Community 110"
Cohesion: 0.33
Nodes (5): getChapter, getDiseaseName, IcdLookupService, lookup, search

### Community 111 - "Community 111"
Cohesion: 0.33
Nodes (5): AbnormalValueBadge, build, label, normalRange, value

### Community 112 - "Community 112"
Cohesion: 0.33
Nodes (5): build, description, diseaseName, RiskCard, riskLevel

### Community 113 - "Community 113"
Cohesion: 0.50
Nodes (5): Imaging (OCR-based) Diseases (3), MLEngine (Stubbed), RiskAggregator (Dead Code), TensorFlow Lite, Hybrid Detection (Rule + ML)

### Community 114 - "Community 114"
Cohesion: 0.40
Nodes (3): RunnerTests, RunnerTests, XCTestCase

### Community 115 - "Community 115"
Cohesion: 0.83
Nodes (4): Android App Icon, macOS App Icon, iOS App Icon, iOS Launch Image

### Community 116 - "Community 116"
Cohesion: 0.50
Nodes (3): getLiveKitToken, LIVEKIT_API_KEY, LIVEKIT_API_SECRET

### Community 117 - "Community 117"
Cohesion: 0.50
Nodes (3): analyze, OcrParser, ../utils/test_definitions.dart

### Community 118 - "Community 118"
Cohesion: 0.50
Nodes (4): _buildDoctorDashboardCard, _buildResult, _buildEndedCard, Route /online-opd

### Community 119 - "Community 119"
Cohesion: 0.50
Nodes (3): build, DisclaimerScreen, package:shared_preferences/shared_preferences.dart

### Community 120 - "Community 120"
Cohesion: 0.50
Nodes (3): BmiCalculator, calculateBmi, getBmiCategory

### Community 121 - "Community 121"
Cohesion: 0.67
Nodes (3): PdfReportService, ProcessingScreen, ReportGenerator (Dead Code)

### Community 122 - "Community 122"
Cohesion: 0.67
Nodes (3): ReferenceRanges (Unused), test_definitions.dart, Demographic-Specific Reference Ranges

### Community 123 - "Community 123"
Cohesion: 0.67
Nodes (3): Online OPD (â‚¹199), Serverless Video Calling, LiveKit

## Knowledge Gaps
- **1260 isolated node(s):** `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`, `getLiveKitToken`, `name`, `description` (+1255 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **21 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `HealthReport` connect `Community 91` to `Community 96`, `Storage Service`, `Diet Plan Screen`, `AI Chat Screen`, `Report Model`, `Report Screen`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **Why does `Appointment` connect `Appointment Model` to `Write Prescription Screen`, `Appointment Service`, `Video Call Screen`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Why does `build` connect `Community 54` to `App Router & Theme`, `Auth & Login Screens`, `Community 102`, `Community 71`, `Community 74`, `Community 118`, `Community 57`, `Dashboard Screen`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **What connects `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`, `getLiveKitToken` to the rest of the system?**
  _1260 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Windows Platform Plugin` be split into smaller, more focused modules?**
  _Cohesion score 0.0597567424643046 - nodes in this community are weakly interconnected._
- **Should `Appointment Providers` be split into smaller, more focused modules?**
  _Cohesion score 0.05224963715529753 - nodes in this community are weakly interconnected._
- **Should `PDF Report Generation` be split into smaller, more focused modules?**
  _Cohesion score 0.04081632653061224 - nodes in this community are weakly interconnected._