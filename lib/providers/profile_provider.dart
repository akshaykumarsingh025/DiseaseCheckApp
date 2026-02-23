import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile?>((
  ref,
) {
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<UserProfile?> {
  ProfileNotifier() : super(StorageService.getProfile());

  Future<void> saveProfile(UserProfile profile) async {
    await StorageService.saveProfile(profile);
    state = profile;
  }
}
