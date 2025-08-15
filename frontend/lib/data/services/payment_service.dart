import 'package:flutter/material.dart';
import '../../app/app_setup.dart';
import '../../core/utils/api_result.dart';
import '../models/payment_model.dart';
import '../repositories/payment_repository.dart';
// import '../widgets/payment_webview_dialog.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final PaymentRepository _paymentRepository = locator<PaymentRepository>();

  /// Simple method to start payment with a specific provider
  static Future<bool> startPayment({
    required BuildContext context,
    required String provider, // 'stripe' or 'paystack'
    required VoidCallback onSuccess,
    VoidCallback? onFailure,
  }) async {
    return await PaymentService()._handlePayment(
      context: context,
      provider: provider,
      onSuccess: onSuccess,
      onFailure: onFailure,
    );
  }

  /// Check if user is premium
  static Future<bool> isPremiumUser() async {
    return await PaymentService()._paymentRepository.isPremiumUser();
  }

  /// Internal payment handler
  Future<bool> _handlePayment({
    required BuildContext context,
    required String provider,
    required VoidCallback onSuccess,
    VoidCallback? onFailure,
  }) async {
    try {
      print('💳 PaymentService: Starting $provider payment...');

      // Check if already premium
      final isPremium = await _paymentRepository.isPremiumUser();
      if (isPremium) {
        _showMessage(
          context,
          'You already have premium access!',
          isError: false,
        );
        return true;
      }

      // Show loading
      _showLoadingDialog(context);

      // Call backend with provider header
      final paymentResult = await _paymentRepository.createPaymentIntent(
        provider,
      );
      Navigator.of(context).pop(); 

      if (paymentResult is Success<PaymentResponse>) {
        final paymentData = paymentResult.data.data;

        if (provider == 'stripe') {
          // Stripe - use SDK (for now, simulate)
          return await _handleStripePayment(
            context,
            paymentData,
            onSuccess,
            onFailure,
          );
        } else if (provider == 'paystack') {
          // Paystack - use WebView
          return await _handlePaystackPayment(
            context,
            paymentData,
            onSuccess,
            onFailure,
          );
        }
      } else if (paymentResult is Failure) {
        _showMessage(context, 'error is happening', isError: true);
        onFailure?.call();
      }

      return false;
    } catch (e) {
      print('❌ PaymentService: Payment error - $e');
      _showMessage(context, 'Payment failed: $e', isError: true);
      onFailure?.call();
      return false;
    }
  }

  /// Handle Stripe payment (SDK - for now simulate)
  Future<bool> _handleStripePayment(
    BuildContext context,
    PaymentData paymentData,
    VoidCallback onSuccess,
    VoidCallback? onFailure,
  ) async {
    try {
      print('💳 PaymentService: Processing Stripe payment...');

      // TODO: Implement Stripe SDK here
      // For now, simulate successful payment
      _showMessage(
        context,
        'Stripe SDK coming soon! Simulating success...',
        isError: false,
      );

      await Future.delayed(const Duration(seconds: 2));

      // Update premium status directly for testing
      await _paymentRepository.updatePremiumStatus(true);

      _showMessage(
        context,
        'Payment successful! Premium activated.',
        isError: false,
      );
      onSuccess();
      return true;
    } catch (e) {
      print('❌ PaymentService: Stripe payment error - $e');
      _showMessage(context, 'Stripe payment failed: $e', isError: true);
      onFailure?.call();
      return false;
    }
  }

  /// Handle Paystack payment (WebView)
  Future<bool> _handlePaystackPayment(
    BuildContext context,
    PaymentData paymentData,
    VoidCallback onSuccess,
    VoidCallback? onFailure,
  ) async {
    try {
      print('💳 PaymentService: Processing Paystack payment...');

      if (paymentData.paymentUrl == null) {
        throw Exception('No payment URL provided for Paystack');
      }

      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PaymentWebViewDialog(
          paymentUrl: paymentData.paymentUrl!,
          paymentId: paymentData.paymentId,
        ),
      );

      if (result == 'success') {
        print('💳 PaymentService: Paystack payment completed');

        // Verify payment and update premium status
        final verificationResult = await _paymentRepository
            .verifyAndUpdatePremiumStatus(paymentData.paymentId);

        if (verificationResult is Success<bool>) {
          _showMessage(
            context,
            'Payment successful! Premium activated.',
            isError: false,
          );
          onSuccess();
          return true;
        } else {
          _showMessage(context, 'Payment verification failed', isError: true);
          onFailure?.call();
          return false;
        }
      } else {
        print('💳 PaymentService: Paystack payment cancelled/failed');
        _showMessage(context, 'Payment cancelled', isError: false);
        return false;
      }
    } catch (e) {
      print('❌ PaymentService: Paystack payment error - $e');
      _showMessage(context, 'Payment failed: $e', isError: true);
      onFailure?.call();
      return false;
    }
  }

  /// Utility methods
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showMessage(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
