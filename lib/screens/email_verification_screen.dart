import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String? email;

  const EmailVerificationScreen({super.key, this.email});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isResending = false;
  bool _isNavigatingToLogin = false;

  @override
  Widget build(BuildContext context) {
    final email = widget.email;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.mark_email_read_outlined,
                    size: 80, color: Theme.of(context).primaryColor),
                const SizedBox(height: 32),
                const Text(
                  'Verify Your Email',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  email != null
                      ? 'We\'ve sent a verification link to $email. Please check your inbox and verify your email address.'
                      : 'We\'ve sent a verification link to your email. Please check your inbox and verify your email address.',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'After verifying your email, come back and sign in to continue.',
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _isNavigatingToLogin ? null : _goBackToLogin,
                  icon: _isNavigatingToLogin
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.login),
                  label: Text(_isNavigatingToLogin
                      ? 'Signing out...'
                      : 'Go Back to Login'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _isResending ? null : _resendVerification,
                  icon: _isResending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_isResending
                      ? 'Sending...'
                      : 'Resend Verification Email'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _goBackToLogin() async {
    setState(() => _isNavigatingToLogin = true);
    try {
      // Sign out first, then navigate to login
      await StorageService.clearAllLocalData();
      await ref.read(authServiceProvider).signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        // If sign-out fails for some reason, navigate anyway
        context.go('/login');
      }
    }
  }

  Future<void> _resendVerification() async {
    setState(() => _isResending = true);
    try {
      await ref.read(authServiceProvider).resendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email resent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not resend: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }
}
