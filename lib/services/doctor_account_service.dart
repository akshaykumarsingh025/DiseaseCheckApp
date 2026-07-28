import 'package:firebase_auth/firebase_auth.dart';

class DoctorAccountService {
  static const String doctorEmail = 'drdipikasingh2026@gmail.com';

  /// The doctor's Firebase UID.
  ///
  /// Not a secret — it is already stored on every appointment document, and
  /// Firestore rules, not this value, are what protect the data.
  ///
  /// This replaces a startup routine that signed in as the doctor (using a
  /// hardcoded password) purely to discover this UID, then signed straight back
  /// out again. That fired two auth-state changes on every cold start, which
  /// rebuilt the router underneath the running app.
  static const String doctorUid = 'kBOP1hs4eXOUWuBEk7TH7dVF1oL2';

  static bool isDoctorEmail(String? email) {
    return email?.toLowerCase() == doctorEmail.toLowerCase();
  }

  static bool get isCurrentUserDoctor {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return isDoctorEmail(user.email) || user.uid == doctorUid;
  }
}
