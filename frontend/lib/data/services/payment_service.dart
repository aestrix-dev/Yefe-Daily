import 'package:flutter/material.dart';
import 'package:yefa/app/app_setup.dart';
import 'package:yefa/data/models/user_model.dart';
import 'package:yefa/data/services/storage_service.dart';
import 'stripe_payment_service.dart';
import 'paystack_webview_service.dart';

class PaymentService {
  final StripePaymentService _stripeService = StripePaymentService();
  final StorageService _storageService = locator<StorageService>();

  Future<void> processStripePayment({
    required String clientSecret,
    required BuildContext context,
    required Function(bool success, String? error, String? paymentIntentId)
    onResult,
  }) async {
    try {

      // First initialize the payment sheet
      final initialized = await _stripeService.initializePaymentSheet(
        clientSecret: clientSecret,
        context: context,
      );

      if (!initialized) {
        onResult(false, 'Failed to initialize payment', null);
        return;
      }

      // Then process the payment
      final result = await _stripeService.processPayment(
        clientSecret: clientSecret,
        context: context,
      );

      if (result.isSuccessful) {

        onResult(true, null, result.paymentIntentId);
      } else if (result.isCancelled) {

        onResult(false, 'Payment was cancelled', null);
      } else {

        onResult(false, result.errorMessage, null);
      }
    } catch (e) {

      onResult(false, 'Payment failed: $e', null);
    }
  }

  Future<void> processPaystackPayment({
    required String paymentUrl,
    required BuildContext context,
    required Function(bool success, String? error, String? paymentReference)
    onResult,
  }) async {
    try {

      // Force garbage collection before heavy WebView operation
      await Future.delayed(const Duration(milliseconds: 100));

      final result = await PaystackWebViewService.processPayment(
        paymentUrl: paymentUrl,
        context: context,
      );

      if (result.isSuccessful) {

        onResult(true, null, result.paymentReference);
      } else if (result.isCancelled) {

        onResult(false, 'Payment was cancelled', null);
      } else {

        onResult(false, result.errorMessage, null);
      }
    } catch (e) {

      onResult(false, 'Payment failed: $e', null);
    }
  }

  Future<void> updateUserPremiumStatus() async {
    try {

      // Get current user
      final user = await _storageService.getUser();
      if (user != null) {
        // Update user's plan to premium
        final updatedUser = UserModel(
          id: user.id,
          email: user.email,
          name: user.name,
          isEmailVerified: user.isEmailVerified,
          isActive: user.isActive,
          createdAt: user.createdAt,
          updatedAt: DateTime.now(),
          lastLoginAt: user.lastLoginAt,
          role: user.role,
          planType: 'premium', // Update to premium
          planName: 'Premium Plan',
          planStartDate: DateTime.now(),
          planEndDate: user.planEndDate,
          planAutoRenew: user.planAutoRenew,
          planStatus: 'active',
        );

        await _storageService.saveUser(updatedUser);

      } else {

      }
    } catch (e) {

    }
  }

  Future<bool> isUserPremium() async {
    try {
      final user = await _storageService.getUser();
      return user?.planType == 'premium';
    } catch (e) {

      return false;
    }
  }
}
