import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/diet_plan_package_provider.dart';
import '../models/diet_plan_package.dart';
import '../services/diet_plan_package_service.dart';
import '../services/payment_service.dart';
import '../utils/doctor_info.dart';

class DietPlanDetailScreen extends ConsumerStatefulWidget {
  final String planId;
  const DietPlanDetailScreen({super.key, required this.planId});

  @override
  ConsumerState<DietPlanDetailScreen> createState() => _DietPlanDetailScreenState();
}

class _DietPlanDetailScreenState extends ConsumerState<DietPlanDetailScreen> {
  bool _isPurchasing = false;

  @override
  void dispose() {
    PaymentService.dispose();
    super.dispose();
  }

  Future<void> _purchase() async {
    setState(() => _isPurchasing = true);

    final result = await PaymentService.openCheckout(
      context,
      PaymentFeature.dietPlan,
    );
    if (!mounted) return;

    if (result.success) {
      await DietPlanPackageService.purchasePlan(
        widget.planId,
        result.paymentId ?? '',
      );
      ref.invalidate(isDietPlanPurchasedProvider(widget.planId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diet plan purchased!'), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${result.error}'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isPurchasing = false);
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(dietPlanDetailProvider(widget.planId));
    final isPurchasedAsync = ref.watch(isDietPlanPurchasedProvider(widget.planId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return planAsync.when(
      data: (plan) {
        if (plan == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Diet Plan')),
            body: const Center(child: Text('Plan not found')),
          );
        }

        final isPurchased = isPurchasedAsync.valueOrNull ?? false;

        return Scaffold(
          appBar: AppBar(title: Text(plan.title)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlanHeader(plan, isDark),
                const SizedBox(height: 20),
                if (isPurchased || plan.mealPlans.isNotEmpty) ...[
                  Text('Meal Plans', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...plan.mealPlans.map((meal) => _buildMealCard(meal, isDark, isPurchased)),
                  const SizedBox(height: 20),
                ],
                Text('Foods to Eat', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildFoodList(plan.foodsToEat, Colors.green, isPurchased),
                const SizedBox(height: 20),
                Text('Foods to Avoid', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildFoodList(plan.foodsToAvoid, Colors.red, isPurchased),
                const SizedBox(height: 20),
                Text('Lifestyle Tips', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildTipsList(plan.lifestyleTips, isPurchased),
                const SizedBox(height: 24),
                if (!isPurchased)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPurchasing ? null : _purchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F3460),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isPurchasing
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Purchase Plan - ₹299', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (isPurchased)
                  Card(
                    color: Colors.green.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.green.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(child: Text('You have access to this plan. Follow it consistently for best results.')),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
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

  Widget _buildMealCard(DietMealPlan meal, bool isDark, bool isPurchased) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(meal.day, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          if (isPurchased) ...[
            _buildMealRow('Breakfast', meal.breakfast, Icons.free_breakfast),
            _buildMealRow('Mid-Morning', meal.midMorning, Icons.coffee),
            _buildMealRow('Lunch', meal.lunch, Icons.lunch_dining),
            _buildMealRow('Evening Snack', meal.eveningSnack, Icons.cookie),
            _buildMealRow('Dinner', meal.dinner, Icons.dinner_dining),
          ] else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.lock, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Purchase to unlock this meal plan', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
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

  Widget _buildFoodList(List<String> foods, Color color, bool isPurchased) {
    final displayFoods = isPurchased ? foods : foods.take(3).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ...displayFoods.map((food) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(color == Colors.green ? Icons.check_circle : Icons.cancel, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(food, style: const TextStyle(fontSize: 13))),
                ],
              ),
            )),
            if (!isPurchased && foods.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('+ ${foods.length - 3} more (purchase to see all)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsList(List<String> tips, bool isPurchased) {
    final displayTips = isPurchased ? tips : tips.take(2).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ...displayTips.map((tip) => Padding(
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
            if (!isPurchased && tips.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('+ ${tips.length - 2} more tips (purchase to see all)', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ),
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
