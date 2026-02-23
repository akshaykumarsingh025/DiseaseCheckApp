import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// StateNotifier that manages the dark mode toggle and persists it via SharedPreferences.
class ThemeNotifier extends StateNotifier<AsyncValue<bool>> {
  ThemeNotifier() : super(const AsyncValue.loading()) {
    _loadPreference();
  }

  static const _key = 'dark_mode_enabled';

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    state = AsyncValue.data(prefs.getBool(_key) ?? false);
  }

  Future<void> toggle() async {
    final current = state.valueOrNull ?? false;
    final newValue = !current;
    state = AsyncValue.data(newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, newValue);
  }

  bool get isDark => state.valueOrNull ?? false;
}

/// Riverpod provider for the dark mode state.
final themeProvider =
    StateNotifierProvider<ThemeNotifier, AsyncValue<bool>>((ref) {
  return ThemeNotifier();
});
