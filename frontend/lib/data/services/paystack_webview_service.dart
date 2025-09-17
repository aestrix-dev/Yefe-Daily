import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PaystackWebViewService {
  static Future<PaystackPaymentResult> processPayment({
    required String paymentUrl,
    required BuildContext context,
  }) async {
    // Just open in external browser - much more reliable
    try {
      final Uri uri = Uri.parse(paymentUrl);

      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback to in-app browser
        launched = await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView,
        );
      }

      if (launched) {
        // Show completion dialog since we can't track external browser
        return await _showCompletionDialog(context);
      } else {
        return PaystackPaymentResult.failed('Could not open payment page');
      }
    } catch (e) {
      return PaystackPaymentResult.failed('Error: $e');
    }
  }

  static Future<PaystackPaymentResult> _showCompletionDialog(BuildContext context) async {
    return await showDialog<PaystackPaymentResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Payment Status'),
        content: const Text(
          'Did you complete the payment successfully in your browser?\n\n'
          'You will receive a confirmation notification when the payment is processed.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(
                PaystackPaymentResult.failed('Payment cancelled by user')
              );
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(
                PaystackPaymentResult.success()
              );
            },
            child: const Text('Completed'),
          ),
        ],
      ),
    ) ?? PaystackPaymentResult.cancelled();
  }
}

class PaystackPaymentResult {
  final PaystackPaymentStatus status;
  final String? errorMessage;
  final String? paymentReference;

  PaystackPaymentResult._({
    required this.status,
    this.errorMessage,
    this.paymentReference,
  });

  factory PaystackPaymentResult.success({String? paymentReference}) {
    return PaystackPaymentResult._(
      status: PaystackPaymentStatus.succeeded,
      paymentReference: paymentReference,
    );
  }

  factory PaystackPaymentResult.failed(String errorMessage) {
    return PaystackPaymentResult._(
      status: PaystackPaymentStatus.failed,
      errorMessage: errorMessage,
    );
  }

  factory PaystackPaymentResult.cancelled() {
    return PaystackPaymentResult._(status: PaystackPaymentStatus.cancelled);
  }

  bool get isSuccessful => status == PaystackPaymentStatus.succeeded;
  bool get isCancelled => status == PaystackPaymentStatus.cancelled;
  bool get isFailed => status == PaystackPaymentStatus.failed;
}

enum PaystackPaymentStatus { succeeded, failed, cancelled }