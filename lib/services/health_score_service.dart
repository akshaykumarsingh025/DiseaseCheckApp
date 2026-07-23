import 'cycle_log_service.dart';
import 'medication_service.dart';
import 'storage_service.dart';
import 'wellness_log_service.dart';

class HealthScoreBreakdown {
  final String label;
  final int earned;
  final int max;
  final String hint;
  const HealthScoreBreakdown(this.label, this.earned, this.max, this.hint);

  bool get complete => earned >= max;
}

class HealthScore {
  final int total; // 0-100
  final List<HealthScoreBreakdown> parts;
  const HealthScore(this.total, this.parts);

  String get grade {
    if (total >= 85) return 'Excellent';
    if (total >= 70) return 'Great';
    if (total >= 50) return 'Good';
    if (total >= 30) return 'Fair';
    return 'Getting started';
  }

  /// The most impactful incomplete habit to nudge the user toward.
  String get topSuggestion {
    final incomplete = parts.where((p) => !p.complete).toList()
      ..sort((a, b) => (b.max - b.earned).compareTo(a.max - a.earned));
    return incomplete.isEmpty
        ? 'You\'re doing everything right today — keep it up! 🎉'
        : incomplete.first.hint;
  }
}

/// Computes a daily 0-100 "health engagement" score from the user's logged
/// habits. It rewards consistent tracking, not medical outcomes.
class HealthScoreService {
  HealthScoreService._();

  static Future<HealthScore> compute() async {
    final parts = <HealthScoreBreakdown>[];
    final now = DateTime.now();

    // 1. Profile completeness (15)
    final profile = StorageService.getProfile();
    final profileComplete =
        profile != null && profile.height != null && profile.weight != null;
    parts.add(HealthScoreBreakdown('Profile', profileComplete ? 15 : 0, 15,
        'Add your height and weight in your profile.'));

    // 2. Cycle tracking (20) — a period start in the last 40 days or a day log
    //    in the last 7 days.
    final starts = await CycleLogService.getPeriodStarts();
    final logs = await CycleLogService.getDayLogs();
    final recentStart = starts.isNotEmpty &&
        now.difference(starts.last).inDays <= 40;
    final recentLog = logs.keys.any((k) {
      final d = DateTime.tryParse(k);
      return d != null && now.difference(d).inDays <= 7;
    });
    final cycleScore = (recentStart ? 12 : 0) + (recentLog ? 8 : 0);
    parts.add(HealthScoreBreakdown('Cycle tracking', cycleScore, 20,
        'Log your period and how you feel in the tracker.'));

    // 3. Medication adherence today (15)
    final (medTaken, medTotal) = await MedicationService.adherenceOn(now);
    final medScore = medTotal == 0 ? 15 : ((medTaken / medTotal) * 15).round();
    parts.add(HealthScoreBreakdown('Medicines', medScore, 15,
        'Mark your medicines as taken today.'));

    // 4. Water (15)
    final entry = await WellnessLogService.getEntry(now);
    final waterGoal = await WellnessLogService.waterGoal();
    final waterScore =
        waterGoal == 0 ? 15 : ((entry.water / waterGoal).clamp(0, 1) * 15).round();
    parts.add(HealthScoreBreakdown('Hydration', waterScore, 15,
        'Drink and log your water for today.'));

    // 5. Sleep (15)
    final sleepGoal = await WellnessLogService.sleepGoal();
    final sleepScore = entry.sleep <= 0
        ? 0
        : ((entry.sleep / sleepGoal).clamp(0, 1) * 15).round();
    parts.add(HealthScoreBreakdown('Sleep', sleepScore, 15,
        'Log last night\'s sleep in Daily Wellness.'));

    // 6. Steps (10)
    final stepsGoal = await WellnessLogService.stepsGoal();
    final stepsScore = stepsGoal == 0
        ? 10
        : ((entry.steps / stepsGoal).clamp(0, 1) * 10).round();
    parts.add(HealthScoreBreakdown('Activity', stepsScore, 10,
        'Log your steps for today.'));

    // 7. Consistency (10) — an active hydration streak.
    final streak = await WellnessLogService.waterStreak();
    final streakScore = streak <= 0 ? 0 : (streak >= 3 ? 10 : streak * 3);
    parts.add(HealthScoreBreakdown('Consistency', streakScore, 10,
        'Build a streak by logging water daily.'));

    final total =
        parts.fold<int>(0, (s, p) => s + p.earned).clamp(0, 100);
    return HealthScore(total, parts);
  }
}
