import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/diet_plan_package.dart';

class DietPlanPackageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<DietPlanPackage>> getDietPlans() async {
    final snapshot = await _firestore
        .collection('diet_plans')
        .orderBy('targetIssue')
        .get();

    return snapshot.docs.map((doc) => DietPlanPackage.fromJson(doc.data())).toList();
  }

  static Stream<List<DietPlanPackage>> getDietPlansStream() {
    return _firestore
        .collection('diet_plans')
        .orderBy('targetIssue')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => DietPlanPackage.fromJson(doc.data())).toList());
  }

  static Future<DietPlanPackage?> getDietPlanById(String planId) async {
    final doc = await _firestore.collection('diet_plans').doc(planId).get();
    if (!doc.exists) return null;
    return DietPlanPackage.fromJson(doc.data()!);
  }

  static Future<bool> isPurchased(String planId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('purchased_diet_plans')
        .doc(planId)
        .get();

    return doc.exists;
  }

  static Future<void> purchasePlan(String planId, String paymentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('purchased_diet_plans')
        .doc(planId)
        .set({
      'planId': planId,
      'purchasedAt': FieldValue.serverTimestamp(),
      'paymentId': paymentId,
    });
  }

  static Future<List<DietPlanPackage>> getPurchasedPlans() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final purchasedSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('purchased_diet_plans')
        .get();

    final planIds = purchasedSnapshot.docs.map((doc) => doc.id).toList();
    if (planIds.isEmpty) return [];

    final plans = <DietPlanPackage>[];
    for (var id in planIds) {
      final doc = await _firestore.collection('diet_plans').doc(id).get();
      if (doc.exists) {
        plans.add(DietPlanPackage.fromJson(doc.data()!));
      }
    }
    return plans;
  }
}
