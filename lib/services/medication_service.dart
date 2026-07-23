import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

/// A medication or supplement the user wants to be reminded about.
class Medication {
  final String id;
  final String name;
  final String dosage; // e.g. "1 tablet", "5000 IU"
  final List<String> times; // "HH:mm" 24h
  final bool enabled;

  const Medication({
    required this.id,
    required this.name,
    this.dosage = '',
    this.times = const [],
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dosage': dosage,
        'times': times,
        'enabled': enabled,
      };

  factory Medication.fromJson(Map<String, dynamic> j) => Medication(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        dosage: (j['dosage'] as String?) ?? '',
        times:
            (j['times'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        enabled: (j['enabled'] as bool?) ?? true,
      );

  Medication copyWith({
    String? name,
    String? dosage,
    List<String>? times,
    bool? enabled,
  }) =>
      Medication(
        id: id,
        name: name ?? this.name,
        dosage: dosage ?? this.dosage,
        times: times ?? this.times,
        enabled: enabled ?? this.enabled,
      );

  /// Stable notification-id base derived from the id (kept < 2^31).
  int get notifBase => (id.hashCode & 0x00FFFFFF) * 8 + 200000000;
}

/// Manages the user's medication/supplement list, "taken" log, streaks, and
/// the daily repeating reminder notifications.
class MedicationService {
  MedicationService._();

  static const _kMeds = 'med_list';
  static const _kTaken = 'med_taken'; // {date: [ "medId@HH:mm", ... ]}

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // --- CRUD ----------------------------------------------------------------

  static Future<List<Medication>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMeds);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Medication.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> _saveAll(List<Medication> meds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMeds, jsonEncode(meds.map((m) => m.toJson()).toList()));
  }

  static Future<List<Medication>> upsert(Medication med) async {
    final meds = await getAll();
    final idx = meds.indexWhere((m) => m.id == med.id);
    if (idx >= 0) {
      meds[idx] = med;
    } else {
      meds.add(med);
    }
    await _saveAll(meds);
    await _rescheduleFor(med);
    return meds;
  }

  static Future<List<Medication>> delete(String id) async {
    final meds = await getAll();
    final med = meds.where((m) => m.id == id).toList();
    meds.removeWhere((m) => m.id == id);
    await _saveAll(meds);
    if (med.isNotEmpty) await _cancelFor(med.first);
    return meds;
  }

  // --- Notifications -------------------------------------------------------

  static Future<void> _rescheduleFor(Medication med) async {
    await _cancelFor(med);
    if (!med.enabled) return;
    for (int i = 0; i < med.times.length; i++) {
      final parts = med.times[i].split(':');
      if (parts.length != 2) continue;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) continue;
      await NotificationService.scheduleDailyMedReminder(
        id: med.notifBase + i,
        title: 'Time for ${med.name} 💊',
        body: med.dosage.isNotEmpty
            ? 'Take ${med.dosage}. Tap to mark it as taken.'
            : 'Tap to mark it as taken.',
        hour: h,
        minute: m,
      );
    }
  }

  static Future<void> _cancelFor(Medication med) async {
    for (int i = 0; i < 12; i++) {
      await NotificationService.cancelById(med.notifBase + i);
    }
  }

  /// Reschedule every medication's reminders (call once at app start).
  static Future<void> rescheduleAll() async {
    final meds = await getAll();
    for (final m in meds) {
      await _rescheduleFor(m);
    }
  }

  // --- Taken log -----------------------------------------------------------

  static Future<Map<String, List<String>>> _takenMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTaken);
    final map = <String, List<String>>{};
    if (raw != null && raw.isNotEmpty) {
      (jsonDecode(raw) as Map<String, dynamic>).forEach((k, v) {
        map[k] = (v as List).map((e) => e.toString()).toList();
      });
    }
    return map;
  }

  static Future<void> _saveTaken(Map<String, List<String>> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTaken, jsonEncode(map));
  }

  static String _slot(String medId, String time) => '$medId@$time';

  static Future<Set<String>> takenOn(DateTime day) async {
    final map = await _takenMap();
    return (map[dateKey(day)] ?? const []).toSet();
  }

  static Future<void> setTaken(
      String medId, String time, DateTime day, bool taken) async {
    final map = await _takenMap();
    final key = dateKey(day);
    final list = map[key] ?? <String>[];
    final slot = _slot(medId, time);
    if (taken) {
      if (!list.contains(slot)) list.add(slot);
    } else {
      list.remove(slot);
    }
    if (list.isEmpty) {
      map.remove(key);
    } else {
      map[key] = list;
    }
    await _saveTaken(map);
  }

  static bool isSlotTaken(Set<String> takenSet, String medId, String time) =>
      takenSet.contains(_slot(medId, time));

  /// How many doses were scheduled and taken on [day].
  static Future<(int taken, int total)> adherenceOn(DateTime day) async {
    final meds = await getAll();
    final taken = await takenOn(day);
    int t = 0, total = 0;
    for (final m in meds.where((m) => m.enabled)) {
      for (final time in m.times) {
        total++;
        if (taken.contains(_slot(m.id, time))) t++;
      }
    }
    return (t, total);
  }

  /// Consecutive days (ending today or yesterday) where every scheduled dose
  /// was taken. Days with no scheduled doses don't break the streak.
  static Future<int> currentStreak() async {
    final meds = (await getAll()).where((m) => m.enabled).toList();
    if (meds.isEmpty) return 0;
    final takenMap = await _takenMap();

    int streak = 0;
    var day = DateTime.now();
    // Allow today to be "not yet complete" without breaking the streak.
    bool todayCounts = true;
    for (int i = 0; i < 400; i++) {
      final key = dateKey(day);
      final taken = (takenMap[key] ?? const []).toSet();
      int total = 0, got = 0;
      for (final m in meds) {
        for (final time in m.times) {
          total++;
          if (taken.contains(_slot(m.id, time))) got++;
        }
      }
      final complete = total == 0 || got >= total;
      if (i == 0 && !complete) {
        // Today not finished yet — don't count it, but keep going to yesterday.
        todayCounts = false;
      } else if (complete) {
        streak++;
      } else {
        break;
      }
      day = day.subtract(const Duration(days: 1));
    }
    // If today wasn't complete we started counting from yesterday; that's fine.
    return todayCounts ? streak : streak;
  }
}
