import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class DoctorAccountService {
  static const String doctorEmail = 'drdipikasingh2026@gmail.com';
  static const String doctorPassword = 'DrDeepika@2026';

  static String? _cachedDoctorUid;

  static String? get cachedDoctorUid => _cachedDoctorUid;

  static bool isDoctorEmail(String? email) {
    return email?.toLowerCase() == doctorEmail.toLowerCase();
  }

  static bool get isCurrentUserDoctor {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    if (isDoctorEmail(user.email)) {
      _cachedDoctorUid ??= user.uid;
      return true;
    }
    if (_cachedDoctorUid != null && user.uid == _cachedDoctorUid) {
      return true;
    }
    return false;
  }

  static Future<String?> ensureDoctorAccount() async {
    if (_cachedDoctorUid != null) return _cachedDoctorUid;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && isDoctorEmail(currentUser.email)) {
      _cachedDoctorUid = currentUser.uid;
      await _saveDoctorUidToConfig(currentUser.uid);
      return currentUser.uid;
    }

    try {
      final configDoc = await FirebaseFirestore.instance.doc('config/api_keys').get();
      if (configDoc.exists) {
        final uid = configDoc.data()?['doctor_user_id'] as String?;
        if (uid != null && uid.isNotEmpty) {
          _cachedDoctorUid = uid;
          return uid;
        }
      }
    } catch (_) {}

    try {
      final uid = await _createOrLookupDoctor();
      if (uid != null) {
        _cachedDoctorUid = uid;
        await _saveDoctorUidToConfig(uid);
      }
      return uid;
    } catch (e, s) {
      developer.log('Doctor account setup failed', error: e, stackTrace: s, name: 'DoctorAccountService');
      return null;
    }
  }

  static Future<String?> _createOrLookupDoctor() async {
    final prevUser = FirebaseAuth.instance.currentUser;
    final wasLoggedIn = prevUser != null && !isDoctorEmail(prevUser.email);

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: doctorEmail,
        password: doctorPassword,
      );
      final uid = credential.user?.uid;

      try {
        await credential.user?.sendEmailVerification();
      } catch (_) {}

      if (uid != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'createdAt': FieldValue.serverTimestamp(),
            'email': doctorEmail,
            'role': 'doctor',
            'name': 'Dr. Deepika Singh',
          });
        } catch (_) {}
      }

      await FirebaseAuth.instance.signOut();

      if (wasLoggedIn) {
        // User will re-login through the normal app flow
      }

      return uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: doctorEmail,
            password: doctorPassword,
          );
          final uid = FirebaseAuth.instance.currentUser?.uid;
          await FirebaseAuth.instance.signOut();

          if (wasLoggedIn) {
            // User will re-login through normal app flow
          }

          return uid;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveDoctorUidToConfig(String uid) async {
    try {
      await FirebaseFirestore.instance.doc('config/api_keys').set({
        'doctor_user_id': uid,
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
