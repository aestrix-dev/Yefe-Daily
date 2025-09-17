// Response models
class PaymentIntentResponse {
  final String paymentId;
  final String clientSecret;
  final String? paymentRef;
  final String? paymentUrl;
  final int amount;
  final String currency;
  final String status;

  PaymentIntentResponse({
    required this.paymentId,
    required this.clientSecret,
    this.paymentRef,
    this.paymentUrl,
    required this.amount,
    required this.currency,
    required this.status,
  });

  factory PaymentIntentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentIntentResponse(
      paymentId: json['payment_id'] ?? '',
      clientSecret: json['client_secret'] ?? '',
      paymentRef: json['payment_ref'],
      paymentUrl: json['payment_url'],
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class PaymentVerificationResponse {
  final String paymentId;
  final String status;
  final String? processedAt;
  final String message;

  PaymentVerificationResponse({
    required this.paymentId,
    required this.status,
    this.processedAt,
    required this.message,
  });

  factory PaymentVerificationResponse.fromJson(Map<String, dynamic> json) {
    return PaymentVerificationResponse(
      paymentId: json['payment_id'] ?? '',
      status: json['status'] ?? '',
      processedAt: json['processed_at'],
      message: json['message'] ?? '',
    );
  }

  // Add different status checks
  bool get isSuccessful => status == 'succeeded';
  bool get isProcessing => status == 'processing';
  bool get isFailed => status == 'failed' || status == 'declined';
  bool get isPending => status == 'pending';

  @override
  String toString() {
    return 'PaymentVerificationResponse{paymentId: $paymentId, status: $status, processedAt: $processedAt, message: $message}';
  }
}
