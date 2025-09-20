import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripePaymentService {
  Future<StripePaymentResult> processPayment({
    required String clientSecret,
    required BuildContext context,
  }) async {
    try {

      await Stripe.instance.presentPaymentSheet();

      // Extract payment intent ID from client secret
      final paymentIntentId = _extractPaymentIntentId(clientSecret);

      return StripePaymentResult.success(
        paymentIntentId: paymentIntentId,
        status: 'succeeded',
      );
    } on StripeException catch (e) {

      // Handle user cancellation
      if (e.error.localizedMessage?.contains('canceled') == true ||
          e.error.localizedMessage?.contains('cancelled') == true) {
        return StripePaymentResult.cancelled();
      }

      // Handle other errors
      final errorMessage = e.error.localizedMessage ?? 'Payment failed';
      return StripePaymentResult.failed(errorMessage);
    } catch (e) {

      return StripePaymentResult.failed('Unexpected error occurred');
    }
  }

  // Extract payment intent ID from client secret
  String _extractPaymentIntentId(String clientSecret) {
    // Client secret format: pi_1234567890_secret_abcdefghijk
    // We need: pi_1234567890
    if (clientSecret.contains('_secret_')) {
      return clientSecret.split('_secret_')[0];
    }
    // Fallback - return the whole thing if format is unexpected
    return clientSecret;
  }

  // Initialize payment sheet before presenting it
  Future<bool> initializePaymentSheet({
    required String clientSecret,
    required BuildContext context,
  }) async {
    try {

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Yefa Daily',
          style: ThemeMode.system,
          billingDetails: const BillingDetails(name: 'Yefa User'),
        ),
      );

      return true;
    } catch (e) {

      return false;
    }
  }
}

// Result class for Stripe payments
class StripePaymentResult {
  final StripePaymentStatus status;
  final String? paymentIntentId;
  final String? statusString;
  final String? errorMessage;

  StripePaymentResult._({
    required this.status,
    this.paymentIntentId,
    this.statusString,
    this.errorMessage,
  });

  factory StripePaymentResult.success({
    required String paymentIntentId,
    required String status,
  }) {
    return StripePaymentResult._(
      status: StripePaymentStatus.succeeded,
      paymentIntentId: paymentIntentId,
      statusString: status,
    );
  }

  factory StripePaymentResult.failed(String errorMessage) {
    return StripePaymentResult._(
      status: StripePaymentStatus.failed,
      errorMessage: errorMessage,
    );
  }

  factory StripePaymentResult.cancelled() {
    return StripePaymentResult._(status: StripePaymentStatus.cancelled);
  }

  bool get isSuccessful => status == StripePaymentStatus.succeeded;
  bool get isCancelled => status == StripePaymentStatus.cancelled;
  bool get isFailed => status == StripePaymentStatus.failed;
}

enum StripePaymentStatus { succeeded, failed, cancelled }
