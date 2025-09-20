// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:yefa/app/app_setup.dart';
import 'package:yefa/core/utils/api_result.dart';
import 'package:yefa/data/models/payment_model.dart';
import 'package:yefa/data/services/payment_api_service.dart';
import 'package:yefa/data/services/payment_service.dart';
import 'package:yefa/data/services/paystack_webview_service.dart';
import 'base_repository.dart';

class PaymentRepository extends BaseRepository {
  final PaymentApiService _apiService = locator<PaymentApiService>();
  final PaymentService _paymentService = locator<PaymentService>();

  Future<ApiResult<PaymentVerificationResponse>> processPayment({
    required String provider,
    required BuildContext context,
  }) async {
    try {

      // Step 1: Create payment intent
      final intentResult = await _apiService.createPaymentIntent(
        provider: provider,
      );

      if (!intentResult.isSuccess) {
        return Failure(intentResult.error ?? 'Failed to create payment intent');
      }

      final paymentIntent = intentResult.data!;

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

        try {
          // Use simple direct WebView service
          final result = await PaystackWebViewService.processPayment(
            paymentUrl: paymentIntent.paymentUrl!,
            context: context,
          );

          paymentSuccessful = result.isSuccessful;
          paystackPaymentReference = result.paymentReference;

          if (!result.isSuccessful) {
            paymentError = result.errorMessage ?? 'Payment failed';
          }
        } catch (e) {
          paymentSuccessful = false;
          paymentError = 'Payment error: $e';
        }
      } else {
        return Failure('Unsupported payment provider: $provider');
      }

      if (!paymentSuccessful) {
        return Failure(paymentError ?? 'Payment failed');
      }

      // Step 3: Verify payment with backend
      String? paymentIntentIdForVerification;

      if (provider == 'stripe') {
        paymentIntentIdForVerification = stripePaymentIntentId;
      } else if (provider == 'paystack') {
        paymentIntentIdForVerification = paymentIntent.paymentRef;

      }

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

        await _paymentService.updateUserPremiumStatus();
        return Success(verification);
      } else if (verification.isProcessing) {

        // Don't update premium status yet, but return success with processing status
        return Success(verification);
      } else {

        return Failure('Payment was not successful: ${verification.message}');
      }
    } catch (e) {

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

        return Success(null);
      } else {
        return Failure('No premium status found');
      }
    } catch (e) {

      return Failure('Failed to restore premium status: $e');
    }
  }
}
