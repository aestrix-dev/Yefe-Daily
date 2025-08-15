import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaystackWebViewService {
  static Future<PaystackPaymentResult> processPayment({
    required String paymentUrl,
    required BuildContext context,
  }) async {
    print('💳 Starting Paystack payment with URL: $paymentUrl');

    return await showModalBottomSheet<PaystackPaymentResult>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: false, // Prevent dismissing without explicit action
          builder: (context) => PaystackWebViewSheet(paymentUrl: paymentUrl),
        ) ??
        PaystackPaymentResult.cancelled();
  }
}

class PaystackWebViewSheet extends StatefulWidget {
  final String paymentUrl;

  const PaystackWebViewSheet({super.key, required this.paymentUrl});

  @override
  State<PaystackWebViewSheet> createState() => _PaystackWebViewSheetState();
}

class _PaystackWebViewSheetState extends State<PaystackWebViewSheet> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('💳 Page started loading: $url');
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (String url) {
            print('💳 Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });

            // Check if this page load indicates payment completion
            final result = _checkPaymentResult(url);
            if (result != null && !_paymentCompleted) {
              _paymentCompleted = true;
              Navigator.of(context).pop(result);
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ WebView error: ${error.description}');
            setState(() {
              _isLoading = false;
              _errorMessage = 'Failed to load payment page';
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('💳 Navigation request: ${request.url}');

            // Check for success/failure URLs
            final result = _checkPaymentResult(request.url);
            if (result != null && !_paymentCompleted) {
              _paymentCompleted = true;
              // Close the sheet and return result
              Navigator.of(context).pop(result);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  PaystackPaymentResult? _checkPaymentResult(String url) {
    print('🔍 Checking URL for payment result: $url');

    // More comprehensive Paystack URL patterns
    // Paystack typically redirects to URLs containing these patterns

    // Success patterns
    if (url.contains('success') ||
        url.contains('successful') ||
        url.contains('completed') ||
        url.contains('payment-successful') ||
        url.contains('status=success') ||
        url.contains('trxref=') || // Paystack transaction reference
        url.contains('reference=')) {
      print('✅ Payment successful detected from URL: $url');
      return PaystackPaymentResult.success();
    }

    // Failure patterns
    if (url.contains('failed') ||
        url.contains('failure') ||
        url.contains('cancelled') ||
        url.contains('canceled') ||
        url.contains('declined') ||
        url.contains('error') ||
        url.contains('status=failed') ||
        url.contains('status=cancelled') ||
        url.contains('status=canceled')) {
      print('❌ Payment failed/cancelled detected from URL: $url');
      return PaystackPaymentResult.failed('Payment was declined or cancelled');
    }

    // Check for redirect patterns that might indicate completion
    if (url.startsWith('http') &&
        !url.contains('checkout.paystack.com') &&
        !url.contains('about:blank')) {
      print('🔄 Possible redirect detected, might be success: $url');
      // This could be a success redirect - you might need to adjust based on your backend
      return PaystackPaymentResult.success();
    }

    return null;
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Payment Status'),
        content: const Text('Did you complete the payment successfully?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(
                context,
              ).pop(PaystackPaymentResult.failed('Payment cancelled by user'));
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(PaystackPaymentResult.success());
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.8,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            // Header with close button
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF2E3B2C),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Row(
                children: [
                  // Payment completed button (for manual confirmation)
                  if (!_isLoading)
                    GestureDetector(
                      onTap: () {
                        _showCompletionDialog();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'Completed?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                  Expanded(
                    child: Text(
                      'Complete Payment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(
                        context,
                      ).pop(PaystackPaymentResult.cancelled());
                    },
                    child: Icon(Icons.close, color: Colors.white, size: 24.sp),
                  ),
                ],
              ),
            ),

            // WebView content
            Expanded(
              child: Stack(
                children: [
                  if (_errorMessage != null)
                    // Error state
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48.sp,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton(
                            onPressed: () {
                              _initializeWebView();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else
                    // WebView
                    WebViewWidget(controller: _controller),

                  // Loading indicator
                  if (_isLoading)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF0FA958),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Loading payment page...',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Result class for Paystack payments
class PaystackPaymentResult {
  final PaystackPaymentStatus status;
  final String? errorMessage;

  PaystackPaymentResult._({required this.status, this.errorMessage});

  factory PaystackPaymentResult.success() {
    return PaystackPaymentResult._(status: PaystackPaymentStatus.succeeded);
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
