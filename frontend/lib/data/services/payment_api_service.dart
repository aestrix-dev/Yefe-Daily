import 'package:dio/dio.dart';
import '../models/payment_model.dart';
import '../../core/utils/api_result.dart';
import 'base_api_service.dart';

class PaymentApiService extends BaseApiService {
  /// Create payment intent with provider-specific header
  Future<ApiResult<PaymentResponse>> createPaymentIntent(
    String provider,
  ) async {
    try {
      print('🔄 PaymentApiService: Creating payment intent for $provider...');

      final request = PaymentRequest(paymentMethod: 'card');

      final Response res = await dioService.post(
        'v1/payment/create', // Adjust endpoint as needed
        data: request.toJson(),
        options: Options(
          headers: {
            'X-Payment-Provider': provider, // stripe or paystack
          },
        ),
      );

      print(
        '✅ PaymentApiService: Payment intent created successfully for $provider',
      );
      final paymentResponse = PaymentResponse.fromJson(res.data);

      return Success(paymentResponse, message: paymentResponse.message);
    } catch (e) {
      print(
        '❌ PaymentApiService: Failed to create payment intent for $provider - $e',
      );
      return Failure(
        'Failed to create payment intent: $e',
        statusCode: e is DioException ? e.response?.statusCode : null,
      );
    }
  }

  /// Check payment status
  Future<ApiResult<PaymentStatusResponse>> checkPaymentStatus(
    String paymentId,
  ) async {
    try {
      print('🔄 PaymentApiService: Checking payment status for $paymentId');

      final Response res = await dioService.get('v1/payment/status/$paymentId');

      print('✅ PaymentApiService: Payment status retrieved');
      final statusResponse = PaymentStatusResponse.fromJson(res.data);

      return Success(statusResponse, message: statusResponse.message);
    } catch (e) {
      print('❌ PaymentApiService: Failed to check payment status - $e');
      return Failure(
        'Failed to check payment status: $e',
        statusCode: e is DioException ? e.response?.statusCode : null,
      );
    }
  }

  /// Verify payment completion (called after successful payment)
  Future<ApiResult<PaymentStatusResponse>> verifyPayment(
    String paymentId,
  ) async {
    try {
      print('🔄 PaymentApiService: Verifying payment $paymentId');

      final Response res = await dioService.post(
        'v1/payment/verify/$paymentId',
      );

      print('✅ PaymentApiService: Payment verified');
      final statusResponse = PaymentStatusResponse.fromJson(res.data);

      return Success(statusResponse, message: statusResponse.message);
    } catch (e) {
      print('❌ PaymentApiService: Failed to verify payment - $e');
      return Failure(
        'Failed to verify payment: $e',
        statusCode: e is DioException ? e.response?.statusCode : null,
      );
    }
  }
}
