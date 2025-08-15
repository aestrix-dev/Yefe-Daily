import 'package:dio/dio.dart';
import 'package:yefa/core/utils/api_result.dart';
import 'package:yefa/data/models/payment_model.dart';
import 'base_api_service.dart';

class PaymentApiService extends BaseApiService {
  Future<ApiResult<PaymentIntentResponse>> createPaymentIntent({
    required String provider, // 'stripe' or 'paystack'
    String paymentMethod = 'card',
  }) async {
    try {
      print('💳 PaymentApiService: Creating payment intent for $provider...');

      final response = await dioService.post(
        'v1/payments/intent',
        data: {'payment_method': paymentMethod},
        options: Options(headers: {'X-Payment-Provider': provider}),
      );

      print('💳 Payment intent response: ${response.statusCode}');
      print('💳 Response data: ${response.data}');

      final paymentResponse = PaymentIntentResponse.fromJson(
        response.data['data'],
      );
      return Success(paymentResponse);
    } catch (e) {
      print('❌ PaymentApiService: Error creating payment intent - $e');
      if (e is DioException) {
        print('🔍 DioException Details:');
        print('   - Type: ${e.type}');
        print('   - Message: ${e.message}');
        print('   - Response Status: ${e.response?.statusCode}');
        print('   - Response Data: ${e.response?.data}');
      }
      return Failure('Failed to create payment intent: $e');
    }
  }

  Future<ApiResult<PaymentVerificationResponse>> verifyPayment({
    required String provider, // 'stripe' or 'paystack'
    required String paymentId,
    String? paymentIntentId, // For Stripe
  }) async {
    try {
      print('✅ PaymentApiService: Verifying payment - $paymentId');

      final requestData = {
        'payment_id': paymentId,
        if (paymentIntentId != null) 'payment_intent_id': paymentIntentId,
      };

      final response = await dioService.post(
        'v1/payments/verify',
        data: requestData,
        options: Options(headers: {'X-Payment-Provider': provider}),
      );

      print('✅ Payment verification response: ${response.statusCode}');
      print('✅ Response data: ${response.data}');

      final verificationResponse = PaymentVerificationResponse.fromJson(
        response.data['data'],
      );
      return Success(verificationResponse);
    } catch (e) {
      print('❌ PaymentApiService: Error verifying payment - $e');
      if (e is DioException) {
        print('🔍 DioException Details:');
        print('   - Type: ${e.type}');
        print('   - Message: ${e.message}');
        print('   - Response Status: ${e.response?.statusCode}');
        print('   - Response Data: ${e.response?.data}');
      }
      return Failure('Payment verification failed: $e');
    }
  }
}
