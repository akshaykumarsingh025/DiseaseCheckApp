import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/diet_plan_package_provider.dart';
import '../models/diet_plan_package.dart';

class DietPlansScreen extends ConsumerWidget {
  const DietPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(dietPlansProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Diet Plans - ₹299')),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No diet plans available yet', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              return _buildPlanCard(context, plans[index], isDark);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              const Text('Failed to load diet plans'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(dietPlansProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, DietPlanPackage plan, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        onTap: () => context.push('/diet-plan-detail', extra: {'planId': plan.planId}),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getGradientColors(plan.targetIssue),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIssueIcon(plan.targetIssue),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'For ${plan.targetIssue}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (plan.isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Popular',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.description,
                    style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildPlanFeature(Icons.schedule, plan.duration),
                      const SizedBox(width: 16),
                      _buildPlanFeature(Icons.restaurant, '${plan.mealPlans.length} day plans'),
                      const SizedBox(width: 16),
                      _buildPlanFeature(Icons.checklist, '${plan.foodsToEat.length} foods to eat'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${plan.price}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F3460),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => context.push('/diet-plan-detail', extra: {'planId': plan.planId}),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F3460),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('View Plan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanFeature(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  List<Color> _getGradientColors(String issue) {
    switch (issue.toLowerCase()) {
      case 'diabetes':
      case 'pcos':
        return [Colors.pink.shade400, Colors.pink.shade600];
      case 'thyroid':
        return [Colors.purple.shade400, Colors.purple.shade600];
      case 'anemia':
        return [Colors.red.shade400, Colors.red.shade600];
      case 'weight loss':
      case 'obesity':
        return [Colors.orange.shade400, Colors.orange.shade600];
      case 'heart health':
        return [Colors.red.shade300, Colors.red.shade500];
      case 'pregnancy':
        return [Colors.pink.shade300, Colors.pink.shade500];
      default:
        return [Colors.green.shade400, Colors.green.shade600];
    }
  }

  IconData _getIssueIcon(String issue) {
    switch (issue.toLowerCase()) {
      case 'diabetes':
        return Icons.bloodtype;
      case 'pcos':
        return Icons.female;
      case 'thyroid':
        return Icons.medication;
      case 'anemia':
        return Icons.opacity;
      case 'weight loss':
      case 'obesity':
        return Icons.monitor_weight;
      case 'heart health':
        return Icons.favorite;
      case 'pregnancy':
        return Icons.pregnant_woman;
      default:
        return Icons.restaurant_menu;
    }
  }
}
