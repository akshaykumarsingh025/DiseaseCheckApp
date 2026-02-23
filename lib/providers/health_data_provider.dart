import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_data.dart';
import '../services/storage_service.dart';

final healthDataProvider =
    StateNotifierProvider<HealthDataNotifier, List<HealthData>>((ref) {
      return HealthDataNotifier();
    });

class HealthDataNotifier extends StateNotifier<List<HealthData>> {
  HealthDataNotifier() : super(StorageService.getAllHealthData());

  Future<void> addHealthData(HealthData data) async {
    await StorageService.saveHealthData(data);
    state = [...state, data];
  }

  List<HealthData> getCategoryData(String category) {
    return state.where((d) => d.category == category).toList();
  }
}
