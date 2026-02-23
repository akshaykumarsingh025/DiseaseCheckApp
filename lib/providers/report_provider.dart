import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report.dart';
import '../services/storage_service.dart';

final reportProvider =
    StateNotifierProvider<ReportNotifier, List<HealthReport>>((ref) {
      return ReportNotifier();
    });

class ReportNotifier extends StateNotifier<List<HealthReport>> {
  ReportNotifier() : super(StorageService.getAllReports());

  Future<void> addReport(HealthReport report) async {
    await StorageService.saveReport(report);
    state = [...state, report];
  }
}
