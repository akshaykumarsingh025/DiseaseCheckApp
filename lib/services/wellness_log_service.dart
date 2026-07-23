import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One day's quick wellness log: water (glasses), sleep (hours), steps.
class WellnessEntry {
  final int water;
  final double sleep;
  final int steps;

  const WellnessEntry({this.water = 0, this.sleep = 0, this.steps = 0});

  Map<String, dynamic> toJson() =>
      {'water': water, 'sleep': sleep, 'steps': steps};

  factory WellnessEntry.fromJson(Map<String, dynamic> j) => WellnessEntry(
        water: (j['water'] as num?)?.toInt() ?? 0,
        sleep: (j['sleep'] as num?)?.toDouble() ?? 0,
        steps: (j['steps'] as num?)?.toInt() ?? 0,
      );

  WellnessEntry copyWith({int? water, double? sleep, int? steps}) =>
      WellnessEntry(
        water: water ?? this.water,
        sleep: sleep ?? this.sleep,
        steps: steps ?? this.steps,
      );

  bool get isEmpty => water == 0 && sleep == 0 && steps == 0;
}

/// Stores daily water/sleep/steps logs, goals, and streaks.
class WellnessLogService {
  WellnessLogService._();

  static const _kLogs = 'wellness_logs';
  static const _kWaterGoal = 'wellness_water_goal';
  static const _kSleepGoal = 'wellness_sleep_goal';
  static const _kStepsGoal = 'wellness_steps_goal';
  static const _kReminderEnabled = 'wellness_reminder_enabled';
  static const _kReminderHour = 'wellness_reminder_hour';
  static const _kReminderMinute = 'wellness_reminder_minute';

  static const int defaultWaterGoal = 8;
  static const double defaultSleepGoal = 7;
  static const int defaultStepsGoal = 8000;

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<Map<String, WellnessEntry>> _all() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLogs);
    final map = <String, WellnessEntry>{};
    if (raw != null && raw.isNotEmpty) {
      (jsonDecode(raw) as Map<String, dynamic>).forEach((k, v) {
        map[k] = WellnessEntry.fromJson(v as Map<String, dynamic>);
      });
    }
    return map;
  }

  static Future<void> _save(Map<String, WellnessEntry> map) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String, dynamic>{};
    map.forEach((k, v) => encoded[k] = v.toJson());
    await prefs.setString(_kLogs, jsonEncode(encoded));
  }

  static Future<WellnessEntry> getEntry(DateTime day) async {
    final map = await _all();
    return map[dateKey(day)] ?? const WellnessEntry();
  }

  static Future<void> setEntry(DateTime day, WellnessEntry entry) async {
    final map = await _all();
    final key = dateKey(day);
    if (entry.isEmpty) {
      map.remove(key);
    } else {
      map[key] = entry;
    }
    await _save(map);
  }

  static Future<WellnessEntry> addWater(DateTime day, int delta) async {
    final e = await getEntry(day);
    final next = e.copyWith(water: (e.water + delta).clamp(0, 30));
    await setEntry(day, next);
    return next;
  }

  static Future<WellnessEntry> setSleep(DateTime day, double hours) async {
    final e = await getEntry(day);
    final next = e.copyWith(sleep: hours.clamp(0, 16));
    await setEntry(day, next);
    return next;
  }

  static Future<WellnessEntry> setSteps(DateTime day, int steps) async {
    final e = await getEntry(day);
    final next = e.copyWith(steps: steps.clamp(0, 100000));
    await setEntry(day, next);
    return next;
  }

  /// Last [days] entries, oldest first, each paired with its date.
  static Future<List<(DateTime, WellnessEntry)>> lastDays(int days) async {
    final map = await _all();
    final out = <(DateTime, WellnessEntry)>[];
    final today = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final d = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));
      out.add((d, map[dateKey(d)] ?? const WellnessEntry()));
    }
    return out;
  }

  // --- Goals ---------------------------------------------------------------

  static Future<int> waterGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kWaterGoal) ?? defaultWaterGoal;
  }

  static Future<double> sleepGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kSleepGoal) ?? defaultSleepGoal;
  }

  static Future<int> stepsGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kStepsGoal) ?? defaultStepsGoal;
  }

  static Future<void> setWaterGoal(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWaterGoal, v);
  }

  static Future<void> setSleepGoal(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kSleepGoal, v);
  }

  static Future<void> setStepsGoal(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStepsGoal, v);
  }

  // --- Daily reminder preference -------------------------------------------

  static Future<bool> reminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kReminderEnabled) ?? false;
  }

  static Future<(int, int)> reminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      prefs.getInt(_kReminderHour) ?? 9,
      prefs.getInt(_kReminderMinute) ?? 0,
    );
  }

  static Future<void> setReminder(bool enabled, int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kReminderEnabled, enabled);
    await prefs.setInt(_kReminderHour, hour);
    await prefs.setInt(_kReminderMinute, minute);
  }

  /// Consecutive days (ending today or yesterday) that met the water goal.
  /// Today not yet meeting the goal doesn't break the streak.
  static Future<int> waterStreak() async {
    final map = await _all();
    final goal = await waterGoal();
    int streak = 0;
    var day = DateTime.now();
    for (int i = 0; i < 400; i++) {
      final e = map[dateKey(day)] ?? const WellnessEntry();
      final met = e.water >= goal;
      if (met) {
        streak++;
      } else if (i == 0) {
        // today not done yet — skip without breaking
      } else {
        break;
      }
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
