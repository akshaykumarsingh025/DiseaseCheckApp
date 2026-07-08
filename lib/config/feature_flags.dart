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
    final cached = DoctorAccountService.cachedDoctorUid;
    if (cached != null && cached.isNotEmpty) return cached;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && DoctorAccountService.isDoctorEmail(user.email)) {
      return user.uid;
    }
    return RemoteConfigService.doctorUserId;
  }

  static bool canBypassEmailVerification(String? email) {
    if (DoctorAccountService.isDoctorEmail(email)) return true;
    if (!firebaseTestAccountsEnabled || email == null) return false;
    return false;
  }
}
