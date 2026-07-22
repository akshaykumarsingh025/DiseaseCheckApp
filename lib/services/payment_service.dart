import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'remote_config_service.dart';

enum PaymentFeature { opdConsult, dietPlan, removeAds }

class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? error;

  PaymentResult.success({this.paymentId, this.orderId})
      : success = true,
        error = null;
  PaymentResult.failure(this.error)
      : success = false,
        paymentId = null,
        orderId = null;
}

class PaymentService {
  static const int opdPrice = 111;
  static const int dietPlanPrice = 299;
  static const int removeAdsPrice = 149;

  // ── FAKE PAYMENT SWITCH ──────────────────────────────────────────────────
  // While true, checkout instantly "succeeds" for free (no Razorpay screen).
  // To go live with REAL payments:
  //   1. Set this to false.
  //   2. Add `razorpay_key_id` (your live/test key) to the Firestore
  //      `config/api_keys` doc — the code below reads it automatically.
  // The full Razorpay flow below is already wired; only the flag + key are
  // needed to enable it.
  //
  // ★ WHEN YOU GET YOUR RAZORPAY KEY ID:
  //   Step 1: Go to Firebase Console > Firestore > config/api_keys doc
  //           Add field: razorpay_key_id = "rzp_test_XXXXX" (or rzp_live_XXXXX)
  //   Step 2: Change the line below from `true` to `false`
  //   Step 3: Test with Razorpay test key + test cards first
  //   Step 4: Switch to live key for production
  static const bool _paymentBypassEnabled = true;

  static Razorpay? _razorpay;
  static Completer<PaymentResult>? _checkoutCompleter;
  static PaymentFeature? _pendingFeature;

  static int getPrice(PaymentFeature feature) {
    switch (feature) {
      case PaymentFeature.opdConsult:
        return opdPrice;
      case PaymentFeature.dietPlan:
        return dietPlanPrice;
      case PaymentFeature.removeAds:
        return removeAdsPrice;
    }
  }

  static String getFeatureName(PaymentFeature feature) {
    switch (feature) {
      case PaymentFeature.opdConsult:
        return 'Online OPD Consultation';
      case PaymentFeature.dietPlan:
        return 'AI Diet Plan';
      case PaymentFeature.removeAds:
        return 'Remove Ads';
    }
  }

  static Future<bool> hasPurchased(PaymentFeature feature) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    if (_paymentBypassEnabled) return true;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('purchases')
          .where('feature', isEqualTo: feature.name)
          .where('status', isEqualTo: 'completed')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('paid_${feature.name}_${user.uid}', true);
        return true;
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('paid_${feature.name}_${user.uid}') ?? false;
    }

    return false;
  }

  static Future<bool> hasRemoveAds() async {
    if (_paymentBypassEnabled) return true;
    final hasRemoveAds = await hasPurchased(PaymentFeature.removeAds);
    if (hasRemoveAds) return true;
    final hasOpd = await hasPurchased(PaymentFeature.opdConsult);
    if (hasOpd) return true;
    final hasDiet = await hasPurchased(PaymentFeature.dietPlan);
    if (hasDiet) return true;
    return false;
  }

  /// Whether the user is ad-free. Unlike [hasRemoveAds] this deliberately
  /// IGNORES the payment bypass: the bypass exists so testers can access paid
  /// features for free, but it must NOT silently disable ads for everyone.
  /// Only a genuine "Remove Ads" purchase makes a user ad-free.
  static Future<bool> isAdFree() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('paid_${PaymentFeature.removeAds.name}_${user.uid}') ?? false) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<void> _markPurchased(
    PaymentFeature feature, {
    String? paymentId,
    String? orderId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('paid_${feature.name}_${user.uid}', true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('purchases')
          .add({
        'feature': feature.name,
        'amount': getPrice(feature),
        'paymentId': paymentId,
        'orderId': orderId,
        'status': 'completed',
        'purchasedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  static Future<PaymentResult> openCheckout(
    BuildContext context,
    PaymentFeature feature,
  ) async {
    if (_paymentBypassEnabled) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final paymentId = 'bypass_$ts';
      final orderId = 'test_order_$ts';

      await _markPurchased(
        feature,
        paymentId: paymentId,
        orderId: orderId,
      );
      return PaymentResult.success(
        paymentId: paymentId,
        orderId: orderId,
      );
    }

    // ── REAL RAZORPAY FLOW (enabled when bypass is off + key is configured) ──
    final keyId = RemoteConfigService.razorpayKeyId;
    if (keyId.isEmpty) {
      return PaymentResult.failure(
        'Payments are not configured yet. Please try again later.',
      );
    }

    // Clean up any previous instance and start a fresh checkout.
    _disposeRazorpay();
    _pendingFeature = feature;
    _checkoutCompleter = Completer<PaymentResult>();

    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final user = FirebaseAuth.instance.currentUser;
    final options = <String, dynamic>{
      'key': keyId,
      'amount': getPrice(feature) * 100, // Razorpay expects paise.
      'currency': 'INR',
      'name': 'DiseaseCheck',
      'description': getFeatureName(feature),
      'prefill': {
        'email': user?.email ?? '',
      },
      'theme': {'color': '#0F3460'},
      'retry': {'enabled': true, 'max_count': 1},
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      _disposeRazorpay();
      return PaymentResult.failure('Could not open payment: $e');
    }

    return _checkoutCompleter!.future;
  }

  static void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final feature = _pendingFeature;
    final completer = _checkoutCompleter;
    // Persist the purchase before completing so callers see it as owned.
    () async {
      if (feature != null) {
        await _markPurchased(
          feature,
          paymentId: response.paymentId,
          orderId: response.orderId,
        );
      }
      if (completer != null && !completer.isCompleted) {
        completer.complete(PaymentResult.success(
          paymentId: response.paymentId,
          orderId: response.orderId,
        ));
      }
      _disposeRazorpay();
    }();
  }

  static void _handlePaymentError(PaymentFailureResponse response) {
    final completer = _checkoutCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(
        PaymentResult.failure(response.message ?? 'Payment failed or was cancelled.'),
      );
    }
    _disposeRazorpay();
  }

  static void _handleExternalWallet(ExternalWalletResponse response) {
    // A wallet was selected; the actual success/error event still follows, so
    // we intentionally leave the completer pending here.
  }

  static void _disposeRazorpay() {
    try {
      _razorpay?.clear();
    } catch (_) {}
    _razorpay = null;
    _pendingFeature = null;
    _checkoutCompleter = null;
  }

  static void dispose() {
    _disposeRazorpay();
  }
}
