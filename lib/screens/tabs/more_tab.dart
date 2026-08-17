import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/nav_tile.dart';

/// The "More" tab: account, preferences and session controls (with a safe,
/// confirmed logout).
///
/// There is deliberately no "Remove Ads" entry here. Google Play requires an
/// ad-free upgrade to be sold through Play Billing, not Razorpay, so the option
/// is withheld until that is wired up. `PaymentFeature.removeAds` is kept in
/// [PaymentService] so anyone who already bought it stays ad-free.
class MoreTab extends ConsumerWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final isDark = ref.watch(themeProvider).valueOrNull ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader('Account'),
        const SizedBox(height: 10),
        NavTile(
          icon: Icons.person,
          color: Colors.pink,
          title: profile?.name ?? 'Your Profile',
          subtitle: 'Edit profile & health information',
          onTap: () => context.push('/profile-setup'),
        ),
        const SizedBox(height: 10),
        NavTile(
          icon: Icons.people,
          color: Colors.deepPurple,
          title: 'Switch Profile',
          subtitle: 'Manage family members',
          onTap: () => context.push('/profile-switcher'),
        ),
        const SectionHeader('Preferences'),
        const SizedBox(height: 10),
        NavTile(
          icon: isDark ? Icons.dark_mode : Icons.light_mode,
          color: Colors.amber.shade700,
          title: 'Dark Mode',
          subtitle: isDark ? 'On' : 'Off',
          onTap: () => ref.read(themeProvider.notifier).toggle(),
          trailing: Switch(
            value: isDark,
            onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
          ),
        ),
        const SizedBox(height: 10),
        NavTile(
          icon: Icons.lock_outline,
          color: Colors.indigo,
          title: 'App Lock',
          subtitle: 'Secure app with PIN or biometric',
          onTap: () => context.push('/app-lock-setup'),
        ),
        const SectionHeader('Session'),
        const SizedBox(height: 10),
        NavTile(
          icon: Icons.logout,
          color: Colors.red,
          title: 'Log Out',
          subtitle: 'Sign out of your account',
          onTap: () => _confirmLogout(context, ref),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
            'You will be signed out and local data on this device will be cleared. Your cloud data stays safe.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await StorageService.clearAllLocalData();
    ref.invalidate(profileProvider);
    ref.read(authServiceProvider).signOut();
  }
}
