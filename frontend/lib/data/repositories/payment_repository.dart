// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:yefa/app/app_setup.dart';
import 'package:yefa/core/utils/api_result.dart';
import 'package:yefa/data/models/payment_model.dart';
import 'package:yefa/data/services/payment_api_service.dart';
import 'package:yefa/data/services/payment_service.dart';
import 'base_repository.dart';

class PaymentRepository extends BaseRepository {
  final PaymentApiService _apiService = locator<PaymentApiService>();
  final PaymentService _paymentService = locator<PaymentService>();

  Future<ApiResult<PaymentVerificationResponse>> processPayment({
    required String provider,
    required BuildContext context,
  }) async {
    try {
      print('PaymentRepository: Starting payment process for $provider');

      // Step 1: Create payment intent
      final intentResult = await _apiService.createPaymentIntent(
        provider: provider,
      );

      if (!intentResult.isSuccess) {
        return Failure(intentResult.error ?? 'Failed to create payment intent');
      }

      final paymentIntent = intentResult.data!;
      print(
        'PaymentRepository: Payment intent created - ${paymentIntent.paymentId}',
      );

      // Step 2: Process payment based on provider
      bool paymentSuccessful = false;
      String? paymentError;
      String? stripePaymentIntentId;
      String? paystackPaymentReference;

      if (provider == 'stripe') {
        await _paymentService.processStripePayment(
          clientSecret: paymentIntent.clientSecret,
          context: context,
          onResult: (success, error, paymentIntentId) {
            paymentSuccessful = success;
            paymentError = error;
            stripePaymentIntentId = paymentIntentId;
          },
        );
      } else if (provider == 'paystack') {
        if (paymentIntent.paymentUrl == null) {
          return Failure('No payment URL provided for Paystack');
        }

        await _paymentService.processPaystackPayment(
          paymentUrl: paymentIntent.paymentUrl!,
          context: context,
          onResult: (success, error, paymentReference) {
            paymentSuccessful = success;
            paymentError = error;
            paystackPaymentReference = paymentReference;
          },
        );
      } else {
        return Failure('Unsupported payment provider: $provider');
      }

      if (!paymentSuccessful) {
        return Failure(paymentError ?? 'Payment failed');
      }

      print('PaymentRepository: Payment completed successfully');

      // Step 3: Verify payment with backend
      String? paymentIntentIdForVerification;

      if (provider == 'stripe') {
        paymentIntentIdForVerification = stripePaymentIntentId;
      } else if (provider == 'paystack') {
        paymentIntentIdForVerification = paymentIntent.paymentRef;
        print(
          'PaymentRepository: Using Paystack payment_ref: ${paymentIntent.paymentRef}',
        );
      }

      print('PaymentRepository: Verifying payment...');
      print('  - payment_id: ${paymentIntent.paymentId}');
      print('  - payment_intent_id: $paymentIntentIdForVerification');

      final verificationResult = await _apiService.verifyPayment(
        provider: provider,
        paymentId: paymentIntent.paymentId,
        paymentIntentId: paymentIntentIdForVerification,
      );

      if (!verificationResult.isSuccess) {
        return Failure(
          verificationResult.error ?? 'Payment verification failed',
        );
      }

      final verification = verificationResult.data!;

      // Handle different payment statuses
      if (verification.isSuccessful) {
        print('PaymentRepository: Payment verified as successful');
        await _paymentService.updateUserPremiumStatus();
        return Success(verification);
      } else if (verification.isProcessing) {
        print('PaymentRepository: Payment is processing');
        // Don't update premium status yet, but return success with processing status
        return Success(verification);
      } else {
        print(
          'PaymentRepository: Payment verification failed - ${verification.message}',
        );
        return Failure('Payment was not successful: ${verification.message}');
      }
    } catch (e) {
      print('PaymentRepository: Error during payment process - $e');
      return Failure('Payment process failed: $e');
    }
  }

  Future<bool> isUserPremium() async {
    return await _paymentService.isUserPremium();
  }

  Future<ApiResult<void>> restorePremiumStatus() async {
    try {
      final isPremium = await isUserPremium();

      if (isPremium) {
        print('PaymentRepository: User already has premium status');
        return Success(null);
      } else {
        return Failure('No premium status found');
      }
    } catch (e) {
      print('PaymentRepository: Error restoring premium status - $e');
      return Failure('Failed to restore premium status: $e');
    }
  }
}
