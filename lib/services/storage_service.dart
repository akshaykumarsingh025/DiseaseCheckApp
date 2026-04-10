import 'dart:developer' as developer;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/report.dart';
import '../models/health_data.dart';

class StorageService {
  static const String profileBoxName = 'user_profile';
  static const String historyBoxName = 'reports_history';
  static const String healthDataBoxName = 'health_data';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

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
    // Save locally
    await profileBox.put('current_user', profile);

    // Sync to Firestore
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('current')
          .set(profile.toJson());
    }
  }

  static UserProfile? getProfile() {
    return profileBox.get('current_user');
  }

  static Future<void> saveReport(HealthReport report) async {
    // Save locally
    await historyBox.put(report.reportId, report);

    // Sync to Firestore
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reports')
          .doc(report.reportId)
          .set(report.toJson());
    }
  }

  static List<HealthReport> getAllReports() {
    return historyBox.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<HealthReport> getReportsPaginated(
      {int offset = 0, int limit = 20}) {
    final all = getAllReports();
    if (offset >= all.length) return [];
    final end = (offset + limit).clamp(0, all.length);
    return all.sublist(offset, end);
  }

  static int get reportCount => historyBox.length;

  static Future<void> saveHealthData(HealthData data) async {
    // Save locally
    await healthDataBox.add(data);

    // Sync to Firestore
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('health_data')
          .add(data.toJson());
    }
  }

  static List<HealthData> getAllHealthData() {
    return healthDataBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ═══════════════════════════════════════════════════
  // CLOUD FETCH — restore data from Firestore on login
  // ═══════════════════════════════════════════════════

  static Future<void> fetchAllFromCloud(String uid) async {
    await fetchProfileFromCloud(uid);
    await fetchReportsFromCloud(uid);
    await fetchHealthDataFromCloud(uid);
  }

  static Future<void> fetchProfileFromCloud(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('current')
          .get();
      if (doc.exists && doc.data() != null) {
        final profile = UserProfile.fromJson(doc.data()!);
        await profileBox.put('current_user', profile);
      }
    } catch (e, s) {
      developer.log('Failed to fetch profile from cloud for uid=$uid',
          error: e, stackTrace: s, name: 'StorageService');
    }
  }

  static Future<void> fetchReportsFromCloud(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('reports')
          .get();
      // Clear existing local data first to avoid duplicates on re-login
      await historyBox.clear();
      for (var doc in snapshot.docs) {
        final report = HealthReport.fromJson(doc.data());
        await historyBox.put(report.reportId, report);
      }
    } catch (e, s) {
      developer.log('Failed to fetch reports from cloud for uid=$uid',
          error: e, stackTrace: s, name: 'StorageService');
    }
  }

  static Future<void> fetchHealthDataFromCloud(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('health_data')
          .get();
      // Clear existing local data first to avoid duplicates on re-login
      await healthDataBox.clear();
      for (var doc in snapshot.docs) {
        final data = HealthData.fromJson(doc.data());
        await healthDataBox.add(data);
      }
    } catch (e, s) {
      developer.log('Failed to fetch health data from cloud for uid=$uid',
          error: e, stackTrace: s, name: 'StorageService');
    }
  }

  // ═══════════════════════════════════════════════════
  // CLEAR — wipe local data on logout
  // ═══════════════════════════════════════════════════

  static Future<void> clearAllLocalData() async {
    await profileBox.clear();
    await historyBox.clear();
    await healthDataBox.clear();
  }
}
