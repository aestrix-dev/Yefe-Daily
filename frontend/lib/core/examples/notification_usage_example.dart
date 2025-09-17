/// Example usage of FirebaseNotificationService
/// 
/// This file shows how to use the Firebase notification service
/// in your ViewModels or other parts of the app

import 'package:get_it/get_it.dart';
import '../../../data/services/firebase_notification_service.dart';

class NotificationUsageExample {
  final FirebaseNotificationService _notificationService = 
      GetIt.instance<FirebaseNotificationService>();

  /// Example: Get FCM token (useful for sending targeted notifications)
  Future<String?> getFCMToken() async {
    return _notificationService.fcmToken;
  }

  /// Example: Subscribe to daily devotional notifications
  Future<void> subscribeToDailyDevotionals() async {
    await _notificationService.subscribeToTopic('daily_devotionals');
  }

  /// Example: Subscribe to challenge notifications
  Future<void> subscribeToChallengeUpdates() async {
    await _notificationService.subscribeToTopic('challenges');
  }

  /// Example: Unsubscribe from notifications (useful for user preferences)
  Future<void> unsubscribeFromAllNotifications() async {
    await _notificationService.unsubscribeFromTopic('daily_devotionals');
    await _notificationService.unsubscribeFromTopic('challenges');
  }

  /// Example: Check if user has enabled notifications
  Future<bool> checkNotificationPermission() async {
    return await _notificationService.areNotificationsEnabled();
  }

  /// Example: Delete token on logout
  Future<void> handleLogout() async {
    await _notificationService.deleteToken();
  }

  /// Example: Send token to your backend for targeted notifications
  Future<void> registerDeviceForNotifications(String userId) async {
    final token = _notificationService.fcmToken;
    if (token != null) {
      // TODO: Call your API to associate token with user
      // await UserApiService().registerFCMToken(userId, token);
    }
  }
}