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
      print('💳 PaymentService: Starting Stripe payment...');

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
        print('✅ PaymentService: Stripe payment successful');
        onResult(true, null, result.paymentIntentId);
      } else if (result.isCancelled) {
        print('⚠️ PaymentService: Stripe payment cancelled');
        onResult(false, 'Payment was cancelled', null);
      } else {
        print(
          '❌ PaymentService: Stripe payment failed - ${result.errorMessage}',
        );
        onResult(false, result.errorMessage, null);
      }
    } catch (e) {
      print('❌ PaymentService: Stripe payment error - $e');
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
      print('💳 PaymentService: Starting Paystack payment...');

      // Force garbage collection before heavy WebView operation
      await Future.delayed(const Duration(milliseconds: 100));

      final result = await PaystackWebViewService.processPayment(
        paymentUrl: paymentUrl,
        context: context,
      );

      if (result.isSuccessful) {
        print('✅ PaymentService: Paystack payment successful');
        onResult(true, null, result.paymentReference);
      } else if (result.isCancelled) {
        print('⚠️ PaymentService: Paystack payment cancelled');
        onResult(false, 'Payment was cancelled', null);
      } else {
        print(
          '❌ PaymentService: Paystack payment failed - ${result.errorMessage}',
        );
        onResult(false, result.errorMessage, null);
      }
    } catch (e) {
      print('❌ PaymentService: Paystack payment error - $e');
      onResult(false, 'Payment failed: $e', null);
    }
  }

  Future<void> updateUserPremiumStatus() async {
    try {
      print('👑 PaymentService: Updating user premium status...');

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
        print('✅ PaymentService: User premium status updated successfully');
      } else {
        print('❌ PaymentService: No user found to update premium status');
      }
    } catch (e) {
      print('❌ PaymentService: Error updating user premium status - $e');
    }
  }

  Future<bool> isUserPremium() async {
    try {
      final user = await _storageService.getUser();
      return user?.planType == 'premium';
    } catch (e) {
      print('❌ PaymentService: Error checking premium status - $e');
      return false;
    }
  }
}
