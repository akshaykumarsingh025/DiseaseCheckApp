import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/report.dart';
import '../models/health_data.dart';

class StorageService {
  static const String profileBoxName = 'user_profile';
  static const String historyBoxName = 'reports_history';
  static const String healthDataBoxName = 'health_data';
  static const _encryptionKeyStorageKey = 'hive_encryption_key';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static Future<Uint8List> _getOrCreateEncryptionKey() async {
    // A read can throw rather than return null — the platform keystore is
    // occasionally unavailable, and an OS-level restore can leave a stored
    // value behind that no longer decrypts. Treat any of that as "no key" and
    // mint a fresh one; _openBox below rebuilds whatever became unreadable.
    try {
      final stored = await _secureStorage.read(key: _encryptionKeyStorageKey);
      if (stored != null) {
        final bytes = stored.split(',').map(int.parse).toList();
        if (bytes.length == 32) return Uint8List.fromList(bytes);
      }
    } catch (e, s) {
      developer.log('Could not read the Hive encryption key',
          error: e, stackTrace: s, name: 'StorageService');
    }

    final key = Hive.generateSecureKey();
    await _secureStorage.write(
      key: _encryptionKeyStorageKey,
      value: key.join(','),
    );
    return Uint8List.fromList(key);
  }

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(0))
      Hive.registerAdapter(UserProfileAdapter());
    if (!Hive.isAdapterRegistered(1))
      Hive.registerAdapter(HealthReportAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(HealthDataAdapter());

    final encryptionKey = await _getOrCreateEncryptionKey();
    final cipher = HiveAesCipher(encryptionKey);

    await _openBox<UserProfile>(profileBoxName, cipher);
    await _openBox<HealthReport>(historyBoxName, cipher);
    await _openBox<HealthData>(healthDataBoxName, cipher);
  }

  /// Opens a box, rebuilding it from scratch if it cannot be read.
  ///
  /// If the cipher key above ever changes, the existing box is undecryptable
  /// and `openBox` throws — which used to strand the user on the "Storage init
  /// failed" screen with a reinstall as the only way out. Dropping the local
  /// box loses nothing permanently: Firestore holds the authoritative copy and
  /// [fetchAllFromCloud] pulls it back on the next launch.
  static Future<void> _openBox<T>(String name, HiveAesCipher cipher) async {
    try {
      await Hive.openBox<T>(name, encryptionCipher: cipher);
    } catch (e, s) {
      developer.log('Rebuilding unreadable Hive box "$name"',
          error: e, stackTrace: s, name: 'StorageService');
      await Hive.deleteBoxFromDisk(name);
      await Hive.openBox<T>(name, encryptionCipher: cipher);
    }
  }

  static Box<UserProfile> get profileBox =>
      Hive.box<UserProfile>(profileBoxName);
  static Box<HealthReport> get historyBox =>
      Hive.box<HealthReport>(historyBoxName);
  static Box<HealthData> get healthDataBox =>
      Hive.box<HealthData>(healthDataBoxName);

  static Future<void> saveProfile(UserProfile profile) async {
    await profileBox.put('current_user', profile);
    await profileBox.put('profile_${profile.profileId}', profile);

    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profiles')
          .doc(profile.profileId)
          .set(profile.toJson());
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

  static List<UserProfile> getAllProfiles() {
    final profiles = <UserProfile>[];
    for (var key in profileBox.keys) {
      if (key is String && key.startsWith('profile_')) {
        final p = profileBox.get(key);
        if (p != null) profiles.add(p);
      }
    }
    return profiles;
  }

  static Future<void> switchProfile(String profileId) async {
    final profile = profileBox.get('profile_$profileId');
    if (profile != null) {
      await profileBox.put('current_user', profile);
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
  }

  static Future<void> deleteProfile(String profileId) async {
    final current = getProfile();
    if (current?.profileId == profileId) return;
    await profileBox.delete('profile_$profileId');
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('profiles')
            .doc(profileId)
            .delete();
      } catch (_) {}
    }
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

  static bool isDuplicateReport(HealthReport report) {
    final recent = getAllReports();
    if (recent.isEmpty) return false;
    final latest = recent.first;
    final timeDiff = latest.date.difference(report.date).inMinutes.abs();
    if (timeDiff > 5) return false;
    final latestHigh = latest.highRiskDiseases.map((e) => e['disease']).toList()..sort();
    final newHigh = report.highRiskDiseases.map((e) => e['disease']).toList()..sort();
    final latestMod = latest.moderateRiskDiseases.map((e) => e['disease']).toList()..sort();
    final newMod = report.moderateRiskDiseases.map((e) => e['disease']).toList()..sort();
    if (latestHigh.length == newHigh.length &&
        latestMod.length == newMod.length &&
        latestHigh.toString() == newHigh.toString() &&
        latestMod.toString() == newMod.toString() &&
        latest.abnormalValues.length == report.abnormalValues.length) {
      return true;
    }
    return false;
  }

  static Future<void> deleteReport(String reportId) async {
    await historyBox.delete(reportId);
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reports')
            .doc(reportId)
            .delete();
      } catch (_) {}
    }
  }

  static Future<void> deleteHealthData(int key) async {
    await healthDataBox.delete(key);
  }

  static Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      final uid = user.uid;
      try {
        final batch = _firestore.batch();

        final reports = await _firestore.collection('users').doc(uid).collection('reports').get();
        for (var doc in reports.docs) batch.delete(doc.reference);

        final healthData = await _firestore.collection('users').doc(uid).collection('health_data').get();
        for (var doc in healthData.docs) batch.delete(doc.reference);

        final profiles = await _firestore.collection('users').doc(uid).collection('profiles').get();
        for (var doc in profiles.docs) batch.delete(doc.reference);

        final profile = await _firestore.collection('users').doc(uid).collection('profile').get();
        for (var doc in profile.docs) batch.delete(doc.reference);

        await batch.commit();

        await _firestore.collection('users').doc(uid).delete();
      } catch (e, s) {
        developer.log('Failed to delete Firestore data for uid=$uid',
            error: e, stackTrace: s, name: 'StorageService');
      }
      await clearAllLocalData();
      await user.delete();
    }
  }

  static Future<void> saveHealthData(HealthData data) async {
    final key = await healthDataBox.add(data);
    data.hiveKey = key;
    await healthDataBox.put(key, data);

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
      final currentDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('current')
          .get();
      if (currentDoc.exists && currentDoc.data() != null) {
        final profile = UserProfile.fromJson(currentDoc.data()!);
        await profileBox.put('current_user', profile);
        await profileBox.put('profile_${profile.profileId}', profile);
      }

      final profilesSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('profiles')
          .get();
      for (var doc in profilesSnapshot.docs) {
        final profile = UserProfile.fromJson(doc.data());
        await profileBox.put('profile_${profile.profileId}', profile);
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
        final key = await healthDataBox.add(data);
        data.hiveKey = key;
        await healthDataBox.put(key, data);
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

  static Future<void> deleteEncryptionKey() async {
    await _secureStorage.delete(key: _encryptionKeyStorageKey);
  }
}
