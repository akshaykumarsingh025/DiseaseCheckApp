import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// Provides the single instance of AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Stream provider that listens to auth state changes (logged in or logged out)
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});
