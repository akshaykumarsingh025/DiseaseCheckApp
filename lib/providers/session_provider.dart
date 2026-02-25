import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_data.dart';

final currentSessionProvider =
    StateNotifierProvider<CurrentSessionNotifier, List<HealthData>>((ref) {
  return CurrentSessionNotifier();
});

class CurrentSessionNotifier extends StateNotifier<List<HealthData>> {
  CurrentSessionNotifier() : super([]);

  void addData(HealthData data) {
    state = [...state, data];
  }

  void addMultipleData(List<HealthData> dataList) {
    state = [...state, ...dataList];
  }

  void clearSession() {
    state = [];
  }
}
