import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/feature_flags.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/storage_service.dart';
import '../../services/payment_service.dart';
import '../../services/ad_service.dart';
import '../../widgets/nav_tile.dart';

/// The "More" tab: account, preferences and session controls (with a safe,
/// confirmed logout).
class MoreTab extends ConsumerStatefulWidget {
  const MoreTab({super.key});

  @override
  ConsumerState<MoreTab> createState() => _MoreTabState();
}

class _MoreTabState extends ConsumerState<MoreTab> {
  bool _adFree = true;

  @override
  void initState() {
    super.initState();
    _loadAdFree();
  }

  Future<void> _loadAdFree() async {
    final v = await PaymentService.isAdFree();
    if (mounted) setState(() => _adFree = v);
  }

  @override
  Widget build(BuildContext context) {
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
        if (FeatureFlags.healthCoursesEnabled) ...[
          const SizedBox(height: 10),
          NavTile(
            icon: Icons.school,
            color: Colors.indigo,
            title: 'Health Courses',
            subtitle: 'Free & premium health education',
            onTap: () => context.push('/courses'),
          ),
        ],
        if (!_adFree) ...[
          const SizedBox(height: 10),
          NavTile(
            icon: Icons.block,
            color: Colors.orange.shade700,
            title: 'Remove Ads',
            subtitle: 'Enjoy an ad-free experience — one-time ₹149',
            onTap: _buyRemoveAds,
            trailing: const StatusPill('Upgrade', color: Colors.orange),
          ),
        ],
        const SectionHeader('Session'),
        const SizedBox(height: 10),
        NavTile(
          icon: Icons.logout,
          color: Colors.red,
          title: 'Log Out',
          subtitle: 'Sign out of your account',
          onTap: _confirmLogout,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _buyRemoveAds() async {
    final result =
        await PaymentService.openCheckout(context, PaymentFeature.removeAds);
    if (!mounted) return;
    if (result.success) {
      setState(() => _adFree = true);
      AdService.dispose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ads removed. Thank you!'),
            backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result.error ?? 'Purchase failed.'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmLogout() async {
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
