import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/diet_plan_package_provider.dart';
import '../models/diet_plan_package.dart';
import '../utils/doctor_info.dart';
import '../widgets/banner_ad_widget.dart';

/// Diet plans are free and ad-supported — every section is fully unlocked and
/// a banner ad carries the screen instead of a purchase.
class DietPlanDetailScreen extends ConsumerWidget {
  final String planId;
  const DietPlanDetailScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(dietPlanDetailProvider(planId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return planAsync.when(
      data: (plan) {
        if (plan == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Diet Plan')),
            body: const Center(child: Text('Plan not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(plan.title)),
          bottomNavigationBar: const SafeArea(child: BannerAdWidget()),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlanHeader(plan, isDark),
                const SizedBox(height: 20),
                if (plan.mealPlans.isNotEmpty) ...[
                  Text('Meal Plans', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...plan.mealPlans.map((meal) => _buildMealCard(meal, isDark)),
                  const SizedBox(height: 20),
                ],
                Text('Foods to Eat', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildFoodList(plan.foodsToEat, Colors.green),
                const SizedBox(height: 20),
                Text('Foods to Avoid', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildFoodList(plan.foodsToAvoid, Colors.red),
                const SizedBox(height: 20),
                Text('Lifestyle Tips', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildTipsList(plan.lifestyleTips),
                const SizedBox(height: 24),
                _buildDoctorCard(isDark),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Diet Plan')),
        body: const Center(child: Text('Failed to load plan')),
      ),
    );
  }

  Widget _buildPlanHeader(DietPlanPackage plan, bool isDark) {
    return Card(
      color: isDark ? Colors.green.shade900.withValues(alpha: 0.2) : Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant_menu, size: 32, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('For ${plan.targetIssue} | ${plan.duration}', style: TextStyle(color: Colors.green.shade700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(plan.description, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(DietMealPlan meal, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(meal.day, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          _buildMealRow('Breakfast', meal.breakfast, Icons.free_breakfast),
          _buildMealRow('Mid-Morning', meal.midMorning, Icons.coffee),
          _buildMealRow('Lunch', meal.lunch, Icons.lunch_dining),
          _buildMealRow('Evening Snack', meal.eveningSnack, Icons.cookie),
          _buildMealRow('Dinner', meal.dinner, Icons.dinner_dining),
        ],
      ),
    );
  }

  Widget _buildMealRow(String label, String value, IconData icon) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: Colors.grey.shade600),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
      subtitle: Text(value, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildFoodList(List<String> foods, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ...foods.map((food) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(color == Colors.green ? Icons.check_circle : Icons.cancel, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(food, style: const TextStyle(fontSize: 13))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsList(List<String> tips) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ...tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tip, style: const TextStyle(fontSize: 13))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(bool isDark) {
    return Card(
      color: isDark ? Colors.pink.shade900.withValues(alpha: 0.2) : Colors.pink.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.pink.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.local_hospital, size: 28, color: Colors.pink.shade600),
            const SizedBox(height: 8),
            Text('Need personalized dietary advice?', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.pink.shade700)),
            const SizedBox(height: 4),
            Text('Book online consultation with ${DoctorInfo.name} for ₹111'),
          ],
        ),
      ),
    );
  }
}
