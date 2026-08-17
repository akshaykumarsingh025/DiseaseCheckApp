import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/backend_config.dart';
import 'backend_auth.dart';

/// Paid features. Diet plans are deliberately absent: they are free.
///
/// `removeAds` has no purchase path any more — Google Play requires an ad-free
/// upgrade to be sold through Play Billing, so the Worker refuses to price it.
/// The value stays so anyone who bought it previously keeps their entitlement.
enum PaymentFeature { opdConsult, removeAds }

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

/// An order created by the Worker. The amount is whatever the server said it
/// is; nothing here is client-chosen.
class _RazorpayOrder {
  final String orderId;
  final String keyId;
  final int amountPaise;
  final String currency;
  final String description;

  const _RazorpayOrder({
    required this.orderId,
    required this.keyId,
    required this.amountPaise,
    required this.currency,
    required this.description,
  });
}

class PaymentService {
  // Display prices. The Worker holds the authoritative copy and charges from
  // it — these exist only to label buttons, so a mismatch misprices the UI but
  // can never mischarge the user.
  static const int opdPrice = 111;
  static const int removeAdsPrice = 149;

  // ── FAKE PAYMENT SWITCH ──────────────────────────────────────────────────
  // While true, checkout instantly "succeeds" for free (no Razorpay screen).
  // Now false: real Razorpay checkout runs against a server-created order.
  static const bool _paymentBypassEnabled = false;

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      // Handle non-2xx ourselves rather than through exceptions.
      validateStatus: (_) => true,
    ),
  );

  static Razorpay? _razorpay;
  static Completer<PaymentResult>? _checkoutCompleter;
  static PaymentFeature? _pendingFeature;

  static int getPrice(PaymentFeature feature) {
    switch (feature) {
      case PaymentFeature.opdConsult:
        return opdPrice;
      case PaymentFeature.removeAds:
        return removeAdsPrice;
    }
  }

  static String getFeatureName(PaymentFeature feature) {
    switch (feature) {
      case PaymentFeature.opdConsult:
        return 'Online OPD Consultation';
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
    bool recordedByServer = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('paid_${feature.name}_${user.uid}', true);

    // When the Worker has already written the record, writing it again here
    // would duplicate it — and once the Firestore rules are locked to
    // server-only writes, this call fails anyway. Skipping is both correct and
    // forward-compatible.
    if (recordedByServer) return;

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

  /// Asks the Worker to create an order. Throws on any failure.
  static Future<_RazorpayOrder> _createOrder(PaymentFeature feature) async {
    final response = await _dio.post(
      BackendConfig.razorpayOrderUrl,
      options: Options(headers: await BackendAuth.headers()),
      data: {'feature': feature.name},
    );

    final status = response.statusCode ?? 0;
    final data = response.data;
    if (status < 200 || status >= 300 || data is! Map) {
      debugPrint('PaymentService: POST ${BackendConfig.razorpayOrderUrl} '
          '-> $status ${response.data}');
      throw PaymentException(_orderErrorMessage(status, data));
    }

    final orderId = data['orderId'] as String?;
    final keyId = data['keyId'] as String?;
    final amount = data['amount'];
    if (orderId == null || keyId == null || amount is! int) {
      throw const PaymentException(
        'The payment server returned an unexpected response.',
      );
    }

    return _RazorpayOrder(
      orderId: orderId,
      keyId: keyId,
      amountPaise: amount,
      currency: data['currency'] as String? ?? 'INR',
      description: data['description'] as String? ?? 'DiseaseCheck',
    );
  }

  /// Turns a failed order response into something worth putting in front of a
  /// patient.
  ///
  /// A 404 means the deployed Worker has no `/razorpay/order` route — i.e. it
  /// is running a build from before payments moved server-side — and its
  /// literal "Not found." is meaningless to someone staring at a Book button,
  /// so it never reaches the screen. The real cause goes to the log instead.
  static String _orderErrorMessage(int status, dynamic data) {
    if (status == 404) {
      return 'Online payment is temporarily unavailable. '
          'Please try again later.';
    }
    if (status == 401) {
      return 'Your session has expired. Please sign in again.';
    }

    final message = data is Map && data['error'] is Map
        ? data['error']['message'] as String?
        : null;
    if (message != null && message.trim().isNotEmpty) return message.trim();

    return 'Could not start the payment. Please try again.';
  }

  /// Has the Worker check the payment signature against the key secret.
  ///
  /// Returns whether the server also recorded the purchase. Throws if the
  /// payment could not be verified — in which case nothing must be unlocked.
  static Future<bool> _verifyPayment({
    required String? orderId,
    required String? paymentId,
    required String? signature,
  }) async {
    if (orderId == null || paymentId == null || signature == null) {
      throw const PaymentException(
        'The payment response was incomplete and could not be verified.',
      );
    }

    final response = await _dio.post(
      BackendConfig.razorpayVerifyUrl,
      options: Options(headers: await BackendAuth.headers()),
      data: {
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
      },
    );

    final data = response.data;
    final verified = data is Map && data['verified'] == true;
    if (!verified) {
      final message = data is Map && data['error'] is Map
          ? data['error']['message'] as String?
          : null;
      throw PaymentException(message ?? 'Payment could not be verified.');
    }

    return data['recorded'] == true;
  }

  static Future<PaymentResult> openCheckout(
    BuildContext context,
    PaymentFeature feature,
  ) async {
    if (_paymentBypassEnabled) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final paymentId = 'bypass_$ts';
      final orderId = 'test_order_$ts';

      await _markPurchased(feature, paymentId: paymentId, orderId: orderId);
      return PaymentResult.success(paymentId: paymentId, orderId: orderId);
    }

    // ── 1. Server-created order ──────────────────────────────────────────
    // Doing this first means the amount, the product and the owning user are
    // all fixed by the server before checkout opens.
    final _RazorpayOrder order;
    try {
      order = await _createOrder(feature);
    } on BackendAuthException catch (e) {
      return PaymentResult.failure(e.message);
    } on PaymentException catch (e) {
      return PaymentResult.failure(e.message);
    } catch (e) {
      debugPrint('PaymentService: order creation failed: $e');
      return PaymentResult.failure(
        'Could not reach the payment server. Please check your connection.',
      );
    }

    // ── 2. Checkout ──────────────────────────────────────────────────────
    _disposeRazorpay();
    _pendingFeature = feature;
    _checkoutCompleter = Completer<PaymentResult>();

    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final user = FirebaseAuth.instance.currentUser;
    final options = <String, dynamic>{
      'key': order.keyId,
      // Passing the order_id is what makes Razorpay return a signature, which
      // is the only part of the response that cannot be forged.
      'order_id': order.orderId,
      'amount': order.amountPaise,
      'currency': order.currency,
      'name': 'DiseaseCheck',
      'description': order.description,
      'prefill': {'email': user?.email ?? ''},
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

    // ── 3. Verify before unlocking anything ──────────────────────────────
    () async {
      if (feature == null || completer == null) {
        _disposeRazorpay();
        return;
      }

      try {
        final recordedByServer = await _verifyPayment(
          orderId: response.orderId,
          paymentId: response.paymentId,
          signature: response.signature,
        );

        await _markPurchased(
          feature,
          paymentId: response.paymentId,
          orderId: response.orderId,
          recordedByServer: recordedByServer,
        );

        if (!completer.isCompleted) {
          completer.complete(PaymentResult.success(
            paymentId: response.paymentId,
            orderId: response.orderId,
          ));
        }
      } catch (e) {
        debugPrint('PaymentService: verification failed: $e');
        // The user may genuinely have been charged, so the message has to give
        // them something support can trace rather than a flat "failed".
        if (!completer.isCompleted) {
          completer.complete(PaymentResult.failure(
            'We could not confirm your payment. If money was debited, contact '
            'support with payment ID ${response.paymentId ?? "unknown"}.',
          ));
        }
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

/// A payment problem worth showing the user verbatim.
class PaymentException implements Exception {
  const PaymentException(this.message);

  final String message;

  @override
  String toString() => message;
}
