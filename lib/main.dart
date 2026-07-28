import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/storage_service.dart';
import 'services/remote_config_service.dart';
import 'services/notification_service.dart';
import 'services/medication_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      runApp(ErrorApp(error: 'Firebase init failed: $e'));
      return;
    }

    try {
      await Hive.initFlutter();
      await StorageService.init();
    } catch (e) {
      runApp(ErrorApp(error: 'Storage init failed: $e'));
      return;
    }

    runApp(
      const ProviderScope(
        child: DiseaseCheckApp(),
      ),
    );
    _appStarted = true;

    _initBackgroundServices();
  }, (error, stack) {
    // Once the app is on screen, a late async error must not replace it with
    // the error screen — the user would lose whatever they were doing.
    if (_appStarted) {
      developer.log('Unhandled async error', error: error, stackTrace: stack, name: 'main');
      return;
    }
    runApp(ErrorApp(error: 'Unhandled: $error'));
  });
}

bool _appStarted = false;

/// Runs after the first frame. Every step is isolated so one failing service
/// cannot stop the rest — and cannot surface as an unhandled zone error.
Future<void> _initBackgroundServices() async {
  Future<void> step(String name, Future<void> Function() action) async {
    try {
      await action();
    } catch (e, s) {
      developer.log('$name failed', error: e, stackTrace: s, name: 'startup');
    }
  }

  await step('RemoteConfig', RemoteConfigService.load);
  await step('Notifications', NotificationService.init);
  await step('MedicationReschedule', MedicationService.rescheduleAll);
  await step('MobileAds', () => MobileAds.instance.initialize());
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                const Text('App Error', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SelectableText(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
