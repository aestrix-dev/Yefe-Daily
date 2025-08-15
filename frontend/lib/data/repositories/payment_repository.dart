import 'package:flutter/material.dart';
import 'package:yefa/app/app_setup.dart';
import 'package:yefa/core/utils/api_result.dart';
import 'package:yefa/data/services/payment_api_service.dart';
import 'package:yefa/data/services/payment_service.dart';
import 'base_repository.dart';

class PaymentRepository extends BaseRepository {
  final PaymentApiService _apiService = locator<PaymentApiService>();
  final PaymentService _paymentService = locator<PaymentService>();
  

  Future<ApiResult<void>> processPayment({
    required String provider, 
    required BuildContext context,
  }) async {
    try {
      print('💳 PaymentRepository: Starting payment process for $provider');

      // Step 1: Create payment intent
      final intentResult = await _apiService.createPaymentIntent(
        provider: provider,
      );

      if (!intentResult.isSuccess) {
        return Failure(intentResult.error ?? 'Failed to create payment intent');
      }

      final paymentIntent = intentResult.data!;
      print(
        '💳 PaymentRepository: Payment intent created - ${paymentIntent.paymentId}',
      );

      // Step 2: Process payment based on provider
      bool paymentSuccessful = false;
      String? paymentError;
      String? stripePaymentIntentId;

      if (provider == 'stripe') {
        await _paymentService.processStripePayment(
          clientSecret: paymentIntent.clientSecret,
          context: context,
          onResult: (success, error) {
            paymentSuccessful = success;
            paymentError = error;
            // For Stripe, we might get the payment intent ID from the service
            // This would need to be updated in the service to return it
          },
        );
      } else if (provider == 'paystack') {
        if (paymentIntent.paymentUrl == null) {
          return Failure('No payment URL provided for Paystack');
        }

        await _paymentService.processPaystackPayment(
          paymentUrl: paymentIntent.paymentUrl!,
          context: context,
          onResult: (success, error) {
            paymentSuccessful = success;
            paymentError = error;
          },
        );
      } else {
        return Failure('Unsupported payment provider: $provider');
      }

      if (!paymentSuccessful) {
        return Failure(paymentError ?? 'Payment failed');
      }

      print('💳 PaymentRepository: Payment completed successfully');

      // Step 3: Verify payment with backend
      final verificationResult = await _apiService.verifyPayment(
        provider: provider,
        paymentId: paymentIntent.paymentId,
        paymentIntentId: stripePaymentIntentId,
      );

      if (!verificationResult.isSuccess) {
        return Failure(
          verificationResult.error ?? 'Payment verification failed',
        );
      }

      final verification = verificationResult.data!;
      if (!verification.isSuccessful) {
        return Failure('Payment was not successful: ${verification.message}');
      }

      print('✅ PaymentRepository: Payment verified successfully');

      // Step 4: Update user premium status locally
      await _paymentService.updateUserPremiumStatus();

      return Success(null);
    } catch (e) {
      print('❌ PaymentRepository: Error during payment process - $e');
      return Failure('Payment process failed: $e');
    }
  }

  Future<bool> isUserPremium() async {
    return await _paymentService.isUserPremium();
  }

  Future<ApiResult<void>> restorePremiumStatus() async {
    try {
      // This could be used to restore premium status from backend
      // For now, just check local storage
      final isPremium = await isUserPremium();

      if (isPremium) {
        print('👑 PaymentRepository: User already has premium status');
        return Success(null);
      } else {
        return Failure('No premium status found');
      }
    } catch (e) {
      print('❌ PaymentRepository: Error restoring premium status - $e');
      return Failure('Failed to restore premium status: $e');
    }
  }
}
