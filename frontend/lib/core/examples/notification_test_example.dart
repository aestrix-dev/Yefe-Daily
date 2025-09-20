import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
import '../../data/services/firebase_notification_service.dart';

/// Example class showing how to test and use the Firebase notification service
/// with the three supported notification types: welcome, daily, and challenge
class NotificationTestExample {
  static final FirebaseNotificationService _notificationService = 
      FirebaseNotificationService();

  /// Test welcome notification handling
  static void testWelcomeNotification() {

    final Map<String, dynamic> welcomeData = {
      'type': 'welcome',
    };
    
    _notificationService.handleNotificationByType(
      type: 'welcome',
      title: 'Welcome to Yefe Daily!',
      body: 'Your notification preferences have been saved.',
      additionalData: welcomeData,
    );
  }

  /// Test daily motivation notification handling
  static void testDailyNotification() {

    final Map<String, dynamic> dailyData = {
      'type': 'daily',
    };
    
    _notificationService.handleNotificationByType(
      type: 'daily',
      title: 'Daily Motivation',
      body: 'Believe you can and you\'re halfway there.',
      additionalData: dailyData,
    );
  }

  /// Test challenge notification handling
  static void testChallengeNotification() {

    final Map<String, dynamic> challengeData = {
      'type': 'challenge',
      'challengeId': 'daily-journal-001',
    };
    
    _notificationService.handleNotificationByType(
      type: 'challenge',
      title: 'New Daily Challenge!',
      body: 'Today\'s challenge is: The 5-Minute Journal',
      additionalData: challengeData,
    );
  }

  /// Simulate a complete notification flow for testing
  static RemoteMessage createMockNotification({
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? additionalData,
  }) {
    // Create mock RemoteMessage for testing
    final data = <String, dynamic>{
      'type': type,
      ...?additionalData,
    };

    // Note: In real testing, you would need to create a proper RemoteMessage mock
    // This is simplified for demonstration

    // Return a basic RemoteMessage-like structure
    // In actual testing, you'd use a proper mock or test framework
    return RemoteMessage(
      messageId: 'test_${DateTime.now().millisecondsSinceEpoch}',
      data: data,
    );
  }

  /// Run all notification tests
  static void runAllTests() {

    testWelcomeNotification();

    testDailyNotification();

    testChallengeNotification();

  }
}

/// Usage example:
/// 
/// void main() {
///   NotificationTestExample.runAllTests();
/// 
///   // Or test individual types:
///   NotificationTestExample.testWelcomeNotification();
///   NotificationTestExample.testDailyNotification();  
///   NotificationTestExample.testChallengeNotification();
/// }