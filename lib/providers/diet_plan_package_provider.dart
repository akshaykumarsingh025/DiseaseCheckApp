import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/diet_plan_package.dart';
import '../services/diet_plan_package_service.dart';

final dietPlansProvider = StreamProvider<List<DietPlanPackage>>((ref) {
  return DietPlanPackageService.getDietPlansStream();
});

final dietPlanDetailProvider = FutureProvider.family<DietPlanPackage?, String>((ref, planId) async {
  return DietPlanPackageService.getDietPlanById(planId);
});

final isDietPlanPurchasedProvider = FutureProvider.family<bool, String>((ref, planId) async {
  return DietPlanPackageService.isPurchased(planId);
});
