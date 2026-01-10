import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'api_service.dart';

/// Payment Service for Razorpay Integration
///
/// This service handles all payment-related operations using Razorpay SDK.
/// 
/// Setup Instructions:
/// 1. Android: Set minSdkVersion to 19 in android/app/build.gradle
/// 2. Android: Add INTERNET permission in AndroidManifest.xml (usually already present)
/// 3. iOS: No additional setup required
///
/// Usage:
/// ```dart
/// final paymentService = PaymentService.instance;
/// await paymentService.init(
///   onSuccess: (response) => print('Payment successful: $response'),
///   onError: (response) => print('Payment failed: $response'),
///   onWalletSelected: () => print('External wallet selected'),
/// );
/// 
/// final result = await paymentService.initiatePayment(orderId);
/// if (result.success) {
///   await paymentService.openCheckout(
///     razorpayOrderId: result.razorpayOrderId!,
///     amount: result.amount!,
///     key: result.key!,
///     name: 'Kheti Sahayak',
///   );
/// }
/// ```
class PaymentService {
  static PaymentService? _instance;
  static PaymentService get instance {
    _instance ??= PaymentService._();
    return _instance!;
  }

  PaymentService._();

  /// Razorpay SDK instance
  Razorpay? _razorpay;

  /// Callback handlers
  void Function(Map<String, dynamic>)? onPaymentSuccess;
  void Function(Map<String, dynamic>)? onPaymentError;
  void Function()? onPaymentWalletSelected;

  /// Track if service is initialized
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize payment service with Razorpay SDK
  Future<void> init({
    void Function(Map<String, dynamic>)? onSuccess,
    void Function(Map<String, dynamic>)? onError,
    void Function()? onWalletSelected,
  }) async {
    onPaymentSuccess = onSuccess;
    onPaymentError = onError;
    onPaymentWalletSelected = onWalletSelected;

    // Initialize Razorpay SDK
    _razorpay = Razorpay();
    
    // Set up event listeners
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _isInitialized = true;

    if (kDebugMode) {
      print('PaymentService initialized with Razorpay SDK');
    }
  }

  /// Handle successful payment from Razorpay SDK
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (kDebugMode) {
      print('Payment Success: ${response.paymentId}');
      print('Order ID: ${response.orderId}');
      print('Signature: ${response.signature}');
    }

    final successData = {
      'razorpay_payment_id': response.paymentId ?? '',
      'razorpay_order_id': response.orderId ?? '',
      'razorpay_signature': response.signature ?? '',
    };

    if (onPaymentSuccess != null) {
      onPaymentSuccess!(successData);
    }
  }

  /// Handle payment error from Razorpay SDK
  void _handlePaymentError(PaymentFailureResponse response) {
    if (kDebugMode) {
      print('Payment Error: ${response.code} - ${response.message}');
    }

    final errorData = {
      'code': response.code ?? 0,
      'message': response.message ?? 'Payment failed',
    };

    if (onPaymentError != null) {
      onPaymentError!(errorData);
    }
  }

  /// Handle external wallet selection from Razorpay SDK
  void _handleExternalWallet(ExternalWalletResponse response) {
    if (kDebugMode) {
      print('External Wallet Selected: ${response.walletName}');
    }

    if (onPaymentWalletSelected != null) {
      onPaymentWalletSelected!();
    }
  }

  /// Initiate payment for an order by creating Razorpay order on backend
  Future<PaymentInitResult> initiatePayment(String orderId) async {
    try {
      final response = await ApiService.post(
        'payments/initiate',
        {'order_id': orderId},
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
      if (kDebugMode) {
        print('Error initiating payment: $e');
      }
      return PaymentInitResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Open Razorpay checkout UI
  /// 
  /// This opens the native Razorpay payment sheet where users can select
  /// their preferred payment method (UPI, Card, Net Banking, Wallet, etc.)
  Future<void> openCheckout({
    required String razorpayOrderId,
    required int amount,
    required String key,
    required String name,
    String? description,
    String? email,
    String? contact,
    String? currency,
    Map<String, String>? notes,
    Map<String, String>? prefill,
    Map<String, dynamic>? theme,
  }) async {
    if (!_isInitialized || _razorpay == null) {
      throw Exception('PaymentService not initialized. Call init() first.');
    }

    final options = <String, dynamic>{
      'key': key,
      'amount': amount, // Amount in paise (e.g., 10000 = ₹100)
      'order_id': razorpayOrderId,
      'name': name,
      'description': description ?? 'Order Payment',
      'currency': currency ?? 'INR',
      'prefill': prefill ?? {
        'email': email ?? '',
        'contact': contact ?? '',
      },
      'theme': theme ?? {
        'color': '#4CAF50', // Green for agricultural theme
      },
      'retry': {
        'enabled': true,
        'max_count': 3,
      },
      'send_sms_hash': true,
      'remember_customer': true,
    };

    // Add notes if provided
    if (notes != null && notes.isNotEmpty) {
      options['notes'] = notes;
    }

    if (kDebugMode) {
      print('Opening Razorpay checkout with options: $options');
    }

    // Open Razorpay checkout
    _razorpay!.open(options);
  }

  /// Verify payment on backend after successful payment
  /// 
  /// This should be called after receiving success callback from Razorpay
  /// to verify the payment signature on the server side.
  Future<PaymentVerifyResult> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await ApiService.post(
        'payments/verify',
        {
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        },
      );

      if (response['success'] == true) {
        return PaymentVerifyResult(
          success: true,
          orderId: response['order_id'],
          paymentId: response['payment_id'],
        );
      }

      return PaymentVerifyResult(
        success: false,
        error: response['error'] ?? 'Payment verification failed',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying payment: $e');
      }
      return PaymentVerifyResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Get payment history for the current user
  Future<List<Map<String, dynamic>>> getPaymentHistory({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await ApiService.get(
        'payments',
        queryParams: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      if (response['success'] == true && response['payments'] != null) {
        return List<Map<String, dynamic>>.from(response['payments']);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting payment history: $e');
      }
    }

    return [];
  }

  /// Get payment details by payment ID
  Future<Map<String, dynamic>?> getPaymentDetails(String paymentId) async {
    try {
      final response = await ApiService.get('payments/$paymentId');

      if (response['success'] == true && response['payment'] != null) {
        return response['payment'];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting payment details: $e');
      }
    }

    return null;
  }

  /// Request refund for a payment
  Future<RefundResult> requestRefund(
    String paymentId, {
    double? amount,
    String? reason,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (amount != null) body['amount'] = amount;
      if (reason != null) body['reason'] = reason;

      final response = await ApiService.post(
        'payments/$paymentId/refund',
        body,
      );

      if (response['success'] == true) {
        return RefundResult(
          success: true,
          refundId: response['refund_id'],
          amount: response['amount']?.toDouble(),
        );
      }

      return RefundResult(
        success: false,
        error: response['error'] ?? 'Refund request failed',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting refund: $e');
      }
      return RefundResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Check payment status for an order
  Future<PaymentStatusResult> checkPaymentStatus(String orderId) async {
    try {
      final response = await ApiService.get('payments/status/$orderId');

      if (response['success'] == true) {
        return PaymentStatusResult(
          success: true,
          status: response['status'] ?? PaymentStatus.pending,
          paymentId: response['payment_id'],
          amount: response['amount']?.toDouble(),
        );
      }

      return PaymentStatusResult(
        success: false,
        error: response['error'] ?? 'Failed to check payment status',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error checking payment status: $e');
      }
      return PaymentStatusResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Dispose resources and clear Razorpay instance
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _isInitialized = false;
    onPaymentSuccess = null;
    onPaymentError = null;
    onPaymentWalletSelected = null;

    if (kDebugMode) {
      print('PaymentService disposed');
    }
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

  @override
  String toString() {
    return 'PaymentInitResult(success: $success, razorpayOrderId: $razorpayOrderId, amount: $amount, currency: $currency, error: $error)';
  }
}

/// Result of payment verification
class PaymentVerifyResult {
  final bool success;
  final String? orderId;
  final String? paymentId;
  final String? error;

  PaymentVerifyResult({
    required this.success,
    this.orderId,
    this.paymentId,
    this.error,
  });

  @override
  String toString() {
    return 'PaymentVerifyResult(success: $success, orderId: $orderId, paymentId: $paymentId, error: $error)';
  }
}

/// Result of refund request
class RefundResult {
  final bool success;
  final String? refundId;
  final double? amount;
  final String? error;

  RefundResult({
    required this.success,
    this.refundId,
    this.amount,
    this.error,
  });

  @override
  String toString() {
    return 'RefundResult(success: $success, refundId: $refundId, amount: $amount, error: $error)';
  }
}

/// Result of payment status check
class PaymentStatusResult {
  final bool success;
  final String? status;
  final String? paymentId;
  final double? amount;
  final String? error;

  PaymentStatusResult({
    required this.success,
    this.status,
    this.paymentId,
    this.amount,
    this.error,
  });

  @override
  String toString() {
    return 'PaymentStatusResult(success: $success, status: $status, paymentId: $paymentId, amount: $amount, error: $error)';
  }
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

  /// Check if payment is successful
  static bool isSuccessful(String status) {
    return status == captured || status == authorized;
  }

  /// Check if payment is pending
  static bool isPending(String status) {
    return status == pending || status == created;
  }

  /// Check if payment failed
  static bool isFailed(String status) {
    return status == failed;
  }

  /// Get human-readable status text
  static String getDisplayText(String status) {
    switch (status) {
      case pending:
        return 'Payment Pending';
      case created:
        return 'Payment Initiated';
      case authorized:
        return 'Payment Authorized';
      case captured:
        return 'Payment Successful';
      case failed:
        return 'Payment Failed';
      case refunded:
        return 'Payment Refunded';
      case partiallyRefunded:
        return 'Partially Refunded';
      default:
        return 'Unknown Status';
    }
  }
}
