import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import '../models/report.dart';
import '../models/health_data.dart';

class StorageService {
  static const String profileBoxName = 'user_profile';
  static const String historyBoxName = 'reports_history';
  static const String healthDataBoxName = 'health_data';

  static Future<void> init() async {
    // Register adapters
    if (!Hive.isAdapterRegistered(0))
      Hive.registerAdapter(UserProfileAdapter());
    if (!Hive.isAdapterRegistered(1))
      Hive.registerAdapter(HealthReportAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(HealthDataAdapter());

    // Open boxes
    await Hive.openBox<UserProfile>(profileBoxName);
    await Hive.openBox<HealthReport>(historyBoxName);
    await Hive.openBox<HealthData>(healthDataBoxName);
  }

  static Box<UserProfile> get profileBox =>
      Hive.box<UserProfile>(profileBoxName);
  static Box<HealthReport> get historyBox =>
      Hive.box<HealthReport>(historyBoxName);
  static Box<HealthData> get healthDataBox =>
      Hive.box<HealthData>(healthDataBoxName);

  static Future<void> saveProfile(UserProfile profile) async {
    await profileBox.put('current_user', profile);
  }

  static UserProfile? getProfile() {
    return profileBox.get('current_user');
  }

  static Future<void> saveReport(HealthReport report) async {
    await historyBox.put(report.reportId, report);
  }

  static List<HealthReport> getAllReports() {
    return historyBox.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveHealthData(HealthData data) async {
    await healthDataBox.add(data);
  }

  static List<HealthData> getAllHealthData() {
    return healthDataBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
