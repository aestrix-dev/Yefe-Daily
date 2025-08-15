import '../../app/app_setup.dart';
import '../../core/utils/api_result.dart';
import '../models/payment_model.dart';
import '../services/payment_api_service.dart';
import '../services/storage_service.dart';

class PaymentRepository {
  final PaymentApiService _paymentApiService = locator<PaymentApiService>();
  final StorageService _storageService = locator<StorageService>();

  /// Create payment intent with provider
  Future<ApiResult<PaymentResponse>> createPaymentIntent(
    String provider,
  ) async {
    print('💳 PaymentRepository: Creating payment intent for $provider...');
    return await _paymentApiService.createPaymentIntent(provider);
  }

  /// Verify payment and update premium status
  Future<ApiResult<bool>> verifyAndUpdatePremiumStatus(String paymentId) async {
    print(
      '💳 PaymentRepository: Verifying payment and updating premium status...',
    );

    try {
      // Verify payment with backend
      final verificationResult = await _paymentApiService.verifyPayment(
        paymentId,
      );

      if (verificationResult is Success<PaymentStatusResponse>) {
        final response = verificationResult.data;

        if (response.data.status == 'completed' ||
            response.data.status == 'successful') {
          // Payment successful - update premium status using your method
          await _storageService.setBool('isPremium', true);
          print('✅ PaymentRepository: Premium status updated successfully');

          return Success(
            true,
            message: 'Payment verified and premium activated',
          );
        } else {
          print(
            '❌ PaymentRepository: Payment not completed - ${response.data.status}',
          );
          return Failure('Payment not completed: ${response.data.status}');
        }
      } else if (verificationResult is Failure) {
        return Failure('error occurred while verifying payment: ');
      }

      return Failure('Unknown verification result');
    } catch (e) {
      print('❌ PaymentRepository: Error verifying payment - $e');
      return Failure('Failed to verify payment: $e');
    }
  }

  /// Get current premium status using your storage method
  Future<bool> isPremiumUser() async {
    return await _storageService.getBool('isPremium') ?? false;
  }

  /// Update premium status using your storage method
  Future<void> updatePremiumStatus(bool isPremium) async {
    await _storageService.setBool('isPremium', isPremium);
    print('💳 PaymentRepository: Premium status updated to $isPremium');
  }
}
