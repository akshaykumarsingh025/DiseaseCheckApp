import 'package:firebase_auth/firebase_auth.dart';

/// Thrown when there is no signed-in user to authenticate a backend call with.
class BackendAuthException implements Exception {
  const BackendAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Builds the `Authorization` header for calls to the Cloudflare Worker.
///
/// The Worker verifies this Firebase ID token server-side, which is what
/// replaces the `request.auth` the Firebase callable used to provide for free.
class BackendAuth {
  const BackendAuth._();

  /// Returns a current Firebase ID token.
  ///
  /// `getIdToken()` refreshes automatically when the cached token is close to
  /// expiry, so callers do not need to track the 1-hour lifetime.
  static Future<String> idToken({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const BackendAuthException(
        'Please sign in again to continue.',
      );
    }

    final token = await user.getIdToken(forceRefresh);
    if (token == null || token.isEmpty) {
      throw const BackendAuthException(
        'Could not verify your session. Please sign in again.',
      );
    }
    return token;
  }

  static Future<Map<String, String>> headers({bool forceRefresh = false}) async {
    return {
      'Authorization': 'Bearer ${await idToken(forceRefresh: forceRefresh)}',
      'Content-Type': 'application/json',
    };
  }
}
