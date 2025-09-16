import 'dart:async';
import 'package:logger/logger.dart';

/// Service to manage premium status updates across the app
/// This service provides a centralized way to notify the UI when premium status changes
class PremiumStatusService {
  static final PremiumStatusService _instance = PremiumStatusService._internal();
  factory PremiumStatusService() => _instance;
  PremiumStatusService._internal();

  final Logger _logger = Logger();

  // Stream controller to broadcast premium status changes
  final StreamController<PremiumStatusUpdate> _premiumStatusController =
      StreamController<PremiumStatusUpdate>.broadcast();

  /// Stream of premium status updates
  Stream<PremiumStatusUpdate> get premiumStatusUpdates => _premiumStatusController.stream;

  /// Notify listeners that premium status has been updated
  void notifyPremiumStatusUpdate({
    required bool isPremium,
    required String updateType,
    String? paymentId,
  }) {
    _logger.i('🔔 Broadcasting premium status update: isPremium=$isPremium, type=$updateType');

    final update = PremiumStatusUpdate(
      isPremium: isPremium,
      updateType: updateType,
      paymentId: paymentId,
      timestamp: DateTime.now(),
    );

    _premiumStatusController.add(update);
  }

  /// Dispose the service
  void dispose() {
    _premiumStatusController.close();
  }
}

/// Model for premium status updates
class PremiumStatusUpdate {
  final bool isPremium;
  final String updateType; // 'success', 'failed', 'manual'
  final String? paymentId;
  final DateTime timestamp;

  const PremiumStatusUpdate({
    required this.isPremium,
    required this.updateType,
    this.paymentId,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'PremiumStatusUpdate(isPremium: $isPremium, updateType: $updateType, paymentId: $paymentId, timestamp: $timestamp)';
  }
}