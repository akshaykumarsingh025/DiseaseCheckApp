import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const _pinKey = 'app_lock_pin';
  static const _lockTypeKey = 'app_lock_type';
  static const _lastBackgroundKey = 'last_background_time';
  static const Duration _lockAfter = Duration(minutes: 1);

  static Future<bool> get isDeviceSupported async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> get canCheckBiometrics async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  static Future<List<BiometricType>> get availableBiometrics async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> get isLockEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lockTypeKey) != null;
  }

  static Future<String?> getLockType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lockTypeKey);
  }

  static Future<void> enableBiometricLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lockTypeKey, 'biometric');
  }

  static Future<void> enablePinLock(String pin) async {
    await _secureStorage.write(key: _pinKey, value: pin);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lockTypeKey, 'pin');
  }

  static Future<void> disableLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lockTypeKey);
    await _secureStorage.delete(key: _pinKey);
  }

  static Future<bool> verifyPin(String pin) async {
    final stored = await _secureStorage.read(key: _pinKey);
    return stored == pin;
  }

  static Future<bool> authenticate() async {
    final lockType = await getLockType();
    if (lockType == null) return true;

    if (lockType == 'biometric') {
      try {
        return await _localAuth.authenticate(
          localizedReason: 'Authenticate to access Health Check',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
      } catch (_) {
        return false;
      }
    }

    return false;
  }

  static Future<void> recordBackgroundTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastBackgroundKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<bool> shouldShowLock() async {
    final lockType = await getLockType();
    if (lockType == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastBg = prefs.getInt(_lastBackgroundKey);
    if (lastBg == null) return false;

    final elapsed = DateTime.now().millisecondsSinceEpoch - lastBg;
    return elapsed > _lockAfter.inMilliseconds;
  }

  static Future<void> clearBackgroundTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastBackgroundKey);
  }
}
