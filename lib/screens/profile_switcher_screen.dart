import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../services/storage_service.dart';

class ProfileSwitcherScreen extends ConsumerStatefulWidget {
  const ProfileSwitcherScreen({super.key});

  @override
  ConsumerState<ProfileSwitcherScreen> createState() =>
      _ProfileSwitcherScreenState();
}

class _ProfileSwitcherScreenState
    extends ConsumerState<ProfileSwitcherScreen> {
  List<UserProfile> _profiles = [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  void _loadProfiles() {
    setState(() {
      _profiles = StorageService.getAllProfiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Switch Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_profiles.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('No profiles yet', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ..._profiles.map((profile) {
            final isCurrent = profile.profileId == currentProfile?.profileId;
            return Card(
              color: isCurrent
                  ? (isDark ? Colors.indigo.shade900.withValues(alpha: 0.3) : Colors.indigo.shade50)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isCurrent
                    ? BorderSide(color: Colors.indigo.shade400, width: 2)
                    : BorderSide.none,
              ),
              child: InkWell(
                onTap: isCurrent
                    ? null
                    : () async {
                        await StorageService.switchProfile(profile.profileId);
                        ref.invalidate(profileProvider);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Switched to ${profile.name}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          context.go('/dashboard');
                        }
                      },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isCurrent
                            ? Colors.indigo.shade100
                            : Colors.grey.shade200,
                        child: Icon(
                          profile.gender == 'Female'
                              ? Icons.female
                              : profile.gender == 'Male'
                                  ? Icons.male
                                  : Icons.person,
                          color: isCurrent ? Colors.indigo : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  profile.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: isCurrent ? Colors.indigo : null,
                                  ),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text('Active',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.white)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${profile.age} yrs, ${profile.gender}${profile.relation != null ? ' — ${profile.relation}' : ''}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      if (!isCurrent)
                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await context.push('/profile-setup');
                _loadProfiles();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Family Member'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_profiles.length > 1) ...[
            const SizedBox(height: 8),
            Text(
              'Long-press a non-active profile to delete it',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
