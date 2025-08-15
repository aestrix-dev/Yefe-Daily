import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class StripePaymentService {
  Future<StripePaymentResult> processPayment({
    required String clientSecret,
    required BuildContext context,
  }) async {
    try {
      print(
        '💳 Starting Stripe payment with client secret: ${clientSecret.substring(0, 20)}...',
      );

      // Present Stripe payment sheet to user (this handles card input)
      await Stripe.instance.presentPaymentSheet();

      print('✅ Payment completed successfully');
      return StripePaymentResult.success(
        paymentIntentId:
            'completed', // We'll get the actual ID from verification
        status: 'succeeded',
      );
    } on StripeException catch (e) {
      print('❌ Stripe error: ${e.error.localizedMessage}');

      // Handle user cancellation
      if (e.error.localizedMessage?.contains('canceled') == true ||
          e.error.localizedMessage?.contains('cancelled') == true) {
        return StripePaymentResult.cancelled();
      }

      // Handle other errors
      final errorMessage = e.error.localizedMessage ?? 'Payment failed';
      return StripePaymentResult.failed(errorMessage);
    } catch (e) {
      print('❌ Unexpected error during Stripe payment: $e');
      return StripePaymentResult.failed('Unexpected error occurred');
    }
  }

  // Initialize payment sheet before presenting it
  Future<bool> initializePaymentSheet({
    required String clientSecret,
    required BuildContext context,
  }) async {
    try {
      print('💳 Initializing Stripe payment sheet...');

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Yefa Daily',
          style: ThemeMode.system,
          billingDetails: const BillingDetails(name: 'Yefa User'),
        ),
      );

      print('✅ Payment sheet initialized successfully');
      return true;
    } catch (e) {
      print('❌ Error initializing payment sheet: $e');
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
