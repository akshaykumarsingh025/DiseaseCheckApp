import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One day's cycle log entry (flow + symptoms + mood + optional note).
class DayLog {
  final String date; // yyyy-MM-dd
  final String flow; // none | spotting | light | medium | heavy
  final List<String> symptoms;
  final String mood; // '', happy, calm, sad, anxious, irritable, energetic
  final String note;

  const DayLog({
    required this.date,
    this.flow = 'none',
    this.symptoms = const [],
    this.mood = '',
    this.note = '',
  });

  bool get isEmpty =>
      flow == 'none' && symptoms.isEmpty && mood.isEmpty && note.isEmpty;

  Map<String, dynamic> toJson() => {
        'flow': flow,
        'symptoms': symptoms,
        'mood': mood,
        'note': note,
      };

  factory DayLog.fromJson(String date, Map<String, dynamic> j) => DayLog(
        date: date,
        flow: (j['flow'] as String?) ?? 'none',
        symptoms:
            (j['symptoms'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        mood: (j['mood'] as String?) ?? '',
        note: (j['note'] as String?) ?? '',
      );

  DayLog copyWith({
    String? flow,
    List<String>? symptoms,
    String? mood,
    String? note,
  }) =>
      DayLog(
        date: date,
        flow: flow ?? this.flow,
        symptoms: symptoms ?? this.symptoms,
        mood: mood ?? this.mood,
        note: note ?? this.note,
      );
}

/// Stores period-start history and per-day symptom logs, and learns the user's
/// average cycle length from their real logged data.
///
/// Backwards compatible with the older single-date keys (`pt_last_period`,
/// `pt_cycle_length`, `pt_period_length`) used by the first version of the
/// period tracker.
class CycleLogService {
  CycleLogService._();

  static const _kPeriodStarts = 'pt_period_starts';
  static const _kDayLogs = 'pt_day_logs';
  static const _kLastPeriod = 'pt_last_period';
  static const _kCycleLength = 'pt_cycle_length';
  static const _kPeriodLength = 'pt_period_length';
  static const _kRemindersEnabled = 'pt_reminders_enabled';
  static const _kDaysBefore = 'pt_remind_days_before';
  static const _kLogReminderEnabled = 'pt_log_reminder_enabled';
  static const _kLogReminderHour = 'pt_log_reminder_hour';
  static const _kLogReminderMinute = 'pt_log_reminder_minute';

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _parseKey(String k) {
    final p = k.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  // --- Period starts -------------------------------------------------------

  static Future<List<DateTime>> getPeriodStarts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPeriodStarts);
    final list = <DateTime>[];
    if (raw != null && raw.isNotEmpty) {
      for (final s in (jsonDecode(raw) as List)) {
        list.add(_parseKey(s.toString()));
      }
    } else {
      // Migrate from the older single-date key if present.
      final legacy = prefs.getString(_kLastPeriod);
      if (legacy != null) list.add(DateTime.parse(legacy));
    }
    list.sort();
    return list;
  }

  static Future<void> _saveStarts(List<DateTime> starts) async {
    final prefs = await SharedPreferences.getInstance();
    starts.sort();
    await prefs.setString(
        _kPeriodStarts, jsonEncode(starts.map(dateKey).toList()));
    if (starts.isNotEmpty) {
      await prefs.setString(_kLastPeriod, starts.last.toIso8601String());
    }
  }

  static Future<List<DateTime>> addPeriodStart(DateTime date) async {
    final d = DateTime(date.year, date.month, date.day);
    final starts = await getPeriodStarts();
    if (!starts.any((s) => dateKey(s) == dateKey(d))) starts.add(d);
    await _saveStarts(starts);
    return starts;
  }

  static Future<List<DateTime>> removePeriodStart(DateTime date) async {
    final starts = await getPeriodStarts();
    starts.removeWhere((s) => dateKey(s) == dateKey(date));
    await _saveStarts(starts);
    return starts;
  }

  /// Average cycle length learned from logged starts (clamped 21–40). Falls
  /// back to the stored/manual value when there aren't enough data points.
  static int averageCycleLength(List<DateTime> starts, {int fallback = 28}) {
    if (starts.length < 2) return fallback;
    final sorted = [...starts]..sort();
    // Use up to the last 6 intervals for a recent-but-stable average.
    final intervals = <int>[];
    for (int i = sorted.length - 1; i > 0 && intervals.length < 6; i--) {
      final gap = sorted[i].difference(sorted[i - 1]).inDays;
      if (gap >= 15 && gap <= 60) intervals.add(gap);
    }
    if (intervals.isEmpty) return fallback;
    final avg = intervals.reduce((a, b) => a + b) / intervals.length;
    return avg.round().clamp(21, 40);
  }

  // --- Cycle / period length (manual defaults) -----------------------------

  static Future<int> getCycleLength() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kCycleLength) ?? 28;
  }

  static Future<int> getPeriodLength() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kPeriodLength) ?? 5;
  }

  static Future<void> setCycleLength(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCycleLength, v);
  }

  static Future<void> setPeriodLength(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPeriodLength, v);
  }

  // --- Day logs ------------------------------------------------------------

  static Future<Map<String, DayLog>> getDayLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDayLogs);
    final map = <String, DayLog>{};
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((k, v) {
        map[k] = DayLog.fromJson(k, v as Map<String, dynamic>);
      });
    }
    return map;
  }

  static Future<DayLog?> getDayLog(DateTime date) async {
    final logs = await getDayLogs();
    return logs[dateKey(date)];
  }

  static Future<void> saveDayLog(DayLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final logs = await getDayLogs();
    if (log.isEmpty) {
      logs.remove(log.date);
    } else {
      logs[log.date] = log;
    }
    final encoded = <String, dynamic>{};
    logs.forEach((k, v) => encoded[k] = v.toJson());
    await prefs.setString(_kDayLogs, jsonEncode(encoded));

    // Logging a "heavy" or "medium" flow on a day with no nearby recorded
    // start is a strong signal a new period began — capture it so predictions
    // and cycle-length learning improve automatically.
    if (log.flow == 'medium' || log.flow == 'heavy') {
      final d = _parseKey(log.date);
      final starts = await getPeriodStarts();
      final hasNearby = starts.any((s) => (s.difference(d).inDays).abs() <= 10);
      if (!hasNearby) await addPeriodStart(d);
    }
  }

  // --- Reminder preferences ------------------------------------------------

  static Future<bool> remindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRemindersEnabled) ?? false;
  }

  static Future<int> daysBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kDaysBefore) ?? 2;
  }

  static Future<void> setRemindersEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRemindersEnabled, v);
  }

  static Future<void> setDaysBefore(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDaysBefore, v);
  }

  static Future<bool> logReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLogReminderEnabled) ?? false;
  }

  static Future<(int, int)> logReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      prefs.getInt(_kLogReminderHour) ?? 20,
      prefs.getInt(_kLogReminderMinute) ?? 0,
    );
  }

  static Future<void> setLogReminder(bool enabled, int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLogReminderEnabled, enabled);
    await prefs.setInt(_kLogReminderHour, hour);
    await prefs.setInt(_kLogReminderMinute, minute);
  }

  // --- Symptom & mood catalogues (shared with the UI) ----------------------

  static const List<String> flows = [
    'none',
    'spotting',
    'light',
    'medium',
    'heavy'
  ];

  static const List<String> symptomOptions = [
    'Cramps',
    'Headache',
    'Bloating',
    'Fatigue',
    'Mood swings',
    'Acne',
    'Tender breasts',
    'Nausea',
    'Back pain',
    'Cravings',
    'Insomnia',
    'Discharge',
  ];

  static const List<String> moodOptions = [
    'happy',
    'calm',
    'sad',
    'anxious',
    'irritable',
    'energetic',
  ];
}
