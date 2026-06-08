import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final void Function(Map<String, dynamic>) onSuccess;
  final void Function(String)? onFailure;

  PaymentService({
    required this.onSuccess,
    this.onFailure,
  });

  Future<void> openCheckout({
    required int amount,
    required String title,
    required String description,
    required String appointmentId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      onFailure?.call('Not authenticated');
      return;
    }

    await Future.delayed(const Duration(seconds: 1));

    final paymentId = 'pay_dummy_${DateTime.now().millisecondsSinceEpoch}';
    final orderId = 'order_dummy_${DateTime.now().millisecondsSinceEpoch}';

    await recordPayment(
      appointmentId: appointmentId,
      paymentId: paymentId,
      orderId: orderId,
      amount: amount,
    );

    onSuccess.call({
      'paymentId': paymentId,
      'orderId': orderId,
    });
  }

  static Future<void> recordPayment({
    required String appointmentId,
    required String paymentId,
    required String orderId,
    required int amount,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('payments').add({
      'appointmentId': appointmentId,
      'paymentId': paymentId,
      'orderId': orderId,
      'amount': amount,
      'userId': user.uid,
      'status': 'completed',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void dispose() {}
}
