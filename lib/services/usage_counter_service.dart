import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Counts successful AI generations (reports + diet plans, combined) per user
/// and decides when an interstitial ad is due.
///
/// Balanced frequency rule:
///  - Generations 1–4: no ads.
///  - 5th generation: first interstitial.
///  - After that: every 3rd generation (5, 8, 11, 14 …).
class UsageCounterService {
  static const int _firstAdAt = 5;
  static const int _everyN = 3;

  static String _key() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    return 'ai_generation_count_$uid';
  }

  /// Call ONLY after a report or diet plan is successfully produced.
  static Future<void> incrementGeneration() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key();
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  static Future<int> totalGenerations() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key()) ?? 0;
  }

  /// Whether the current generation count lands on an ad slot.
  static bool isAdDue(int count) {
    if (count < _firstAdAt) return false;
    return (count - _firstAdAt) % _everyN == 0;
  }

  /// Convenience: reads the stored count and evaluates the rule.
  static Future<bool> shouldShowAd() async {
    final count = await totalGenerations();
    return isAdDue(count);
  }
}
