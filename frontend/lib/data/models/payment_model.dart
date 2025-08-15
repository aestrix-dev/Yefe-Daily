// Payment Models
class PaymentRequest {
  final String paymentMethod;

  PaymentRequest({required this.paymentMethod});

  Map<String, dynamic> toJson() => {'payment_method': paymentMethod};
}

class PaymentResponse {
  final bool success;
  final String message;
  final PaymentData data;
  final String timestamp;

  PaymentResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: PaymentData.fromJson(json['data'] ?? {}),
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class PaymentData {
  final String paymentId;
  final String? clientSecret; 
  final String? paymentRef;
  final String? paymentUrl; 
  final int amount;
  final String currency;
  final String status;

  PaymentData({
    required this.paymentId,
    this.clientSecret,
    this.paymentRef,
    this.paymentUrl,
    required this.amount,
    required this.currency,
    required this.status,
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      paymentId: json['payment_id'] ?? '',
      clientSecret: json['client_secret'],
      paymentRef: json['payment_ref'],
      paymentUrl: json['payment_url'],
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class PaymentStatusResponse {
  final bool success;
  final String message;
  final PaymentStatusData data;

  PaymentStatusResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: PaymentStatusData.fromJson(json['data'] ?? {}),
    );
  }
}

class PaymentStatusData {
  final String paymentId;
  final String status;
  final String message;

  PaymentStatusData({
    required this.paymentId,
    required this.status,
    required this.message,
  });

  factory PaymentStatusData.fromJson(Map<String, dynamic> json) {
    return PaymentStatusData(
      paymentId: json['payment_id'] ?? '',
      status: json['status'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

enum PaymentProvider { stripe, paystack }

enum PaymentStatus { pending, completed, failed, cancelled }
