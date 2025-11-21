import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'auth_service.dart';

/// Payment Service for Razorpay Integration
///
/// Setup Instructions for production:
/// 1. Add razorpay_flutter to pubspec.yaml:
///    ```yaml
///    dependencies:
///      razorpay_flutter: ^1.3.5
///    ```
/// 2. Configure Android minSdkVersion to 19 in android/app/build.gradle
/// 3. Add INTERNET permission in AndroidManifest.xml
///
/// For development, this uses mock payment flow.
class PaymentService {
  static PaymentService? _instance;
  static PaymentService get instance {
    _instance ??= PaymentService._();
    return _instance!;
  }

  PaymentService._();

  /// Callback handlers
  void Function(Map<String, dynamic>)? onPaymentSuccess;
  void Function(Map<String, dynamic>)? onPaymentError;
  void Function()? onPaymentWalletSelected;

  /// Initialize payment service
  Future<void> init({
    void Function(Map<String, dynamic>)? onSuccess,
    void Function(Map<String, dynamic>)? onError,
    void Function()? onWalletSelected,
  }) async {
    onPaymentSuccess = onSuccess;
    onPaymentError = onError;
    onPaymentWalletSelected = onWalletSelected;

    // In production, initialize Razorpay SDK here:
    // _razorpay = Razorpay();
    // _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    // _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    // _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    if (kDebugMode) {
      print('PaymentService initialized (mock mode)');
    }
  }

  /// Initiate payment for an order
  Future<PaymentInitResult> initiatePayment(String orderId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return PaymentInitResult(
          success: false,
          error: 'User not logged in',
        );
      }

      final response = await ApiService.post(
        '/payments/initiate',
        {'order_id': orderId},
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['success'] == true && response['payment'] != null) {
        return PaymentInitResult(
          success: true,
          razorpayOrderId: response['payment']['razorpay_order_id'],
          amount: response['payment']['amount'],
          currency: response['payment']['currency'] ?? 'INR',
          key: response['payment']['key'],
        );
      }

      return PaymentInitResult(
        success: false,
        error: response['error'] ?? 'Failed to initiate payment',
      );
    } catch (e) {
      return PaymentInitResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Open Razorpay checkout
  Future<void> openCheckout({
    required String razorpayOrderId,
    required int amount,
    required String key,
    required String name,
    String? description,
    String? email,
    String? contact,
    String? currency,
  }) async {
    final options = {
      'key': key,
      'amount': amount,
      'order_id': razorpayOrderId,
      'name': name,
      'description': description ?? 'Order Payment',
      'currency': currency ?? 'INR',
      'prefill': {
        'email': email ?? '',
        'contact': contact ?? '',
      },
      'theme': {
        'color': '#4CAF50', // Green for agricultural theme
      },
    };

    if (kDebugMode) {
      print('Opening Razorpay checkout with options: $options');
      // Simulate successful payment in debug mode
      await Future.delayed(const Duration(seconds: 2));
      _handleMockPaymentSuccess(razorpayOrderId);
      return;
    }

    // In production, call:
    // _razorpay.open(options);
  }

  /// Verify payment on backend
  Future<PaymentVerifyResult> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return PaymentVerifyResult(
          success: false,
          error: 'User not logged in',
        );
      }

      final response = await ApiService.post(
        '/payments/verify',
        {
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        },
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['success'] == true) {
        return PaymentVerifyResult(
          success: true,
          orderId: response['order_id'],
        );
      }

      return PaymentVerifyResult(
        success: false,
        error: response['error'] ?? 'Payment verification failed',
      );
    } catch (e) {
      return PaymentVerifyResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return [];

      final response = await ApiService.get(
        '/payments?page=$page&limit=$limit',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['success'] == true && response['payments'] != null) {
        return List<Map<String, dynamic>>.from(response['payments']);
      }
    } catch (e) {
      print('Error getting payment history: $e');
    }

    return [];
  }

  /// Get payment details
  Future<Map<String, dynamic>?> getPaymentDetails(String paymentId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await ApiService.get(
        '/payments/$paymentId',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response['success'] == true && response['payment'] != null) {
        return response['payment'];
      }
    } catch (e) {
      print('Error getting payment details: $e');
    }

    return null;
  }

  /// Request refund
  Future<bool> requestRefund(String paymentId, {double? amount, String? reason}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final body = <String, dynamic>{};
      if (amount != null) body['amount'] = amount;
      if (reason != null) body['reason'] = reason;

      final response = await ApiService.post(
        '/payments/$paymentId/refund',
        body,
        headers: {'Authorization': 'Bearer $token'},
      );

      return response['success'] == true;
    } catch (e) {
      print('Error requesting refund: $e');
      return false;
    }
  }

  // Mock payment success handler for development
  void _handleMockPaymentSuccess(String razorpayOrderId) {
    final mockResponse = {
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': 'pay_mock_${DateTime.now().millisecondsSinceEpoch}',
      'razorpay_signature': 'mock_signature_${DateTime.now().millisecondsSinceEpoch}',
    };

    if (onPaymentSuccess != null) {
      onPaymentSuccess!(mockResponse);
    }
  }

  /// Dispose resources
  void dispose() {
    // In production:
    // _razorpay.clear();
    onPaymentSuccess = null;
    onPaymentError = null;
    onPaymentWalletSelected = null;
  }
}

/// Result of payment initiation
class PaymentInitResult {
  final bool success;
  final String? razorpayOrderId;
  final int? amount;
  final String? currency;
  final String? key;
  final String? error;

  PaymentInitResult({
    required this.success,
    this.razorpayOrderId,
    this.amount,
    this.currency,
    this.key,
    this.error,
  });
}

/// Result of payment verification
class PaymentVerifyResult {
  final bool success;
  final String? orderId;
  final String? error;

  PaymentVerifyResult({
    required this.success,
    this.orderId,
    this.error,
  });
}

/// Payment status constants
class PaymentStatus {
  static const String pending = 'pending';
  static const String created = 'created';
  static const String authorized = 'authorized';
  static const String captured = 'captured';
  static const String failed = 'failed';
  static const String refunded = 'refunded';
  static const String partiallyRefunded = 'partially_refunded';
}
