import 'package:firebase_auth/firebase_auth.dart';
import '../services/remote_config_service.dart';
import '../services/doctor_account_service.dart';

class FeatureFlags {
  const FeatureFlags._();

  static const bool healthCoursesEnabled = false;
  static const bool firebaseTestAccountsEnabled = false;
  static const bool emergencyOpdTestingEnabled = true;

  static bool get isDoctor {
    return DoctorAccountService.isCurrentUserDoctor;
  }

  static String get doctorUserId {
    // Remote value wins so the doctor account can be changed without a release.
    final remote = RemoteConfigService.doctorUserId;
    if (remote.isNotEmpty) return remote;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && DoctorAccountService.isDoctorEmail(user.email)) {
      return user.uid;
    }
    return DoctorAccountService.doctorUid;
  }

  static bool canBypassEmailVerification(String? email) {
    if (DoctorAccountService.isDoctorEmail(email)) return true;
    if (!firebaseTestAccountsEnabled || email == null) return false;
    return false;
  }
}
