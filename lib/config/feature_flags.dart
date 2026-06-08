import 'package:firebase_auth/firebase_auth.dart';

class FeatureFlags {
  const FeatureFlags._();

  static const bool healthCoursesEnabled = false;
  static const bool firebaseTestAccountsEnabled = true;
  static const bool emergencyOpdTestingEnabled = true;

  static const String doctorUserId = 'pvqEOm1BeybUSycUhhhUmSZoZnP2';

  static const Set<String> emailVerificationBypassEmails = {
    'doctor.opd.test@diseasecheck.app',
    'patient.opd.test@diseasecheck.app',
  };

  /// Whether the currently logged-in user is the doctor.
  static bool get isDoctor {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.uid == doctorUserId;
  }

  static bool canBypassEmailVerification(String? email) {
    if (!firebaseTestAccountsEnabled || email == null) return false;
    return emailVerificationBypassEmails.contains(email.toLowerCase().trim());
  }
}
