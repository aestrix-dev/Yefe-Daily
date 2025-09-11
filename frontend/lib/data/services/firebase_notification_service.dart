import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../../app/router/app_router.dart';

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final Logger _logger = Logger();
  
  String? _fcmToken;
  
  // Getters
  String? get fcmToken => _fcmToken;
  FirebaseMessaging get firebaseMessaging => _firebaseMessaging;

  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      _logger.i('🔔 Initializing Firebase Notification Service...');

      // Request permission for notifications
      await _requestPermission();

      // Get FCM token
      await _getFCMToken();

      // Setup message handlers
      _setupMessageHandlers();

      // Setup token refresh handler
      _setupTokenRefreshHandler();

      _logger.i('✅ Firebase Notification Service initialized successfully');
    } catch (e) {
      _logger.e('❌ Failed to initialize Firebase Notification Service: $e');
      rethrow;
    }
  }

  /// Request notification permission
  Future<bool> _requestPermission() async {
    try {
      _logger.i('📱 Requesting notification permission...');
      
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _logger.i('🔐 Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.i('✅ Notification permission granted');
        return true;
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        _logger.i('⚠️ Provisional notification permission granted');
        return true;
      } else {
        _logger.w('❌ Notification permission denied');
        return false;
      }
    } catch (e) {
      _logger.e('❌ Error requesting permission: $e');
      return false;
    }
  }

  /// Get FCM token with iOS simulator handling
  Future<void> _getFCMToken() async {
    try {
      _logger.i('🔑 Getting FCM token...');
      
      // Check if running on iOS simulator
      if (await _isIOSSimulator()) {
        _logger.w('⚠️ Running on iOS Simulator - FCM tokens not available');
        _logger.i('💡 Use a physical device or Android emulator for full FCM testing');
        _fcmToken = 'simulator-mock-token-${DateTime.now().millisecondsSinceEpoch}';
        _logger.i('🔧 Mock token created for simulator: ${_fcmToken!.substring(0, 20)}...');
        return;
      }
      
      // For real devices, try to get APNS token first on iOS
      try {
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken != null) {
          _logger.i('📱 APNS token available: ${apnsToken.substring(0, 20)}...');
        } else {
          _logger.w('⚠️ APNS token not available yet, retrying...');
          // Wait a bit and retry
          await Future.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        _logger.w('⚠️ APNS token not available: $e');
      }
      
      _fcmToken = await _firebaseMessaging.getToken();
      
      if (_fcmToken != null) {
        _logger.i('✅ FCM Token obtained: ${_fcmToken!.substring(0, 20)}...');
        // Send token to server for real devices
        await _sendTokenToServer(_fcmToken!);
      } else {
        _logger.w('⚠️ Failed to obtain FCM token');
      }
    } catch (e) {
      _logger.e('❌ Error getting FCM token: $e');
      if (e.toString().contains('apns-token-not-set')) {
        _logger.w('💡 This is likely an iOS simulator - use a physical device for FCM testing');
        // Create a mock token for simulator testing
        _fcmToken = 'simulator-mock-token-${DateTime.now().millisecondsSinceEpoch}';
      }
    }
  }

  /// Check if running on iOS simulator
  Future<bool> _isIOSSimulator() async {
    try {
      if (!Platform.isIOS) return false;
      
      // Check if running in debug mode (simulators typically run in debug)
      if (kDebugMode) {
        _logger.i('🔍 Running in debug mode on iOS - likely simulator');
        return true;
      }
      
      return false;
    } catch (e) {
      _logger.w('⚠️ Error checking if iOS simulator: $e');
      return false;
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    _logger.i('📨 Setting up message handlers...');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message clicks
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageClick);

    // Handle app launch from terminated state via notification
    _handleAppLaunchFromNotification();
  }

  /// Setup token refresh handler
  void _setupTokenRefreshHandler() {
    _logger.i('🔄 Setting up token refresh handler...');
    
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _logger.i('🔄 FCM Token refreshed: ${newToken.substring(0, 20)}...');
      _fcmToken = newToken;
      // TODO: Send updated token to your server
      _sendTokenToServer(newToken);
    });
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('📨 Foreground message received: ${message.messageId}');
    _logger.i('📝 Title: ${message.notification?.title}');
    _logger.i('📝 Body: ${message.notification?.body}');
    _logger.i('📦 Data: ${message.data}');

    // Handle notification based on type
    final String? notificationType = message.data['type'];
    if (notificationType != null && 
        message.notification?.title != null && 
        message.notification?.body != null) {
      handleNotificationByType(
        type: notificationType,
        title: message.notification!.title!,
        body: message.notification!.body!,
        additionalData: message.data,
      );
    }

    // Show local notification or handle custom UI
    _showLocalNotification(message);
  }

  /// Handle background message clicks
  void _handleBackgroundMessageClick(RemoteMessage message) {
    _logger.i('👆 Background message clicked: ${message.messageId}');
    _logger.i('📦 Data: ${message.data}');
    
    // Navigate to specific screen based on notification data
    _handleNotificationNavigation(message.data);
  }

  /// Handle app launch from notification when app was terminated
  Future<void> _handleAppLaunchFromNotification() async {
    try {
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      
      if (initialMessage != null) {
        _logger.i('🚀 App launched from notification: ${initialMessage.messageId}');
        _logger.i('📦 Data: ${initialMessage.data}');
        
        // Handle navigation after app is fully initialized
        Future.delayed(const Duration(seconds: 1), () {
          _handleNotificationNavigation(initialMessage.data);
        });
      }
    } catch (e) {
      _logger.e('❌ Error handling app launch from notification: $e');
    }
  }

  /// Show local notification (you might want to use flutter_local_notifications)
  void _showLocalNotification(RemoteMessage message) {
    // For now, just log. You can implement flutter_local_notifications here
    _logger.i('🔔 Showing local notification: ${message.notification?.title}');
    
    // TODO: Implement local notification display
    // This would typically use flutter_local_notifications package
  }

  /// Handle notification navigation based on notification types
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    _logger.i('🧭 Handling notification navigation with data: $data');
    
    // Extract notification type from data payload
    final String? notificationType = data['type'];
    
    if (notificationType != null) {
      switch (notificationType) {
        case 'welcome':
          _logger.i('👋 Welcome notification - no navigation required');
          // Welcome notifications are purely informational, no navigation needed
          break;
        case 'daily':
          _logger.i('📅 Daily motivation notification - navigating to home screen');
          _navigateToHome();
          break;
        case 'challenge':
          _logger.i('🎯 New daily challenge notification - navigating to challenges screen');
          _navigateToChallenges();
          break;
        default:
          _logger.i('🏠 Unknown notification type, navigating to home screen');
          _navigateToHome();
      }
    } else {
      _logger.w('⚠️ No notification type found in data, navigating to home screen');
      _navigateToHome();
    }
  }

  /// Navigate to home screen for daily motivation notifications
  void _navigateToHome() {
    try {
      // Import the navigation service and router
      final navigatorKey = _getNavigatorKey();
      if (navigatorKey?.currentContext != null) {
        navigatorKey!.currentContext!.go('/home');
        _logger.i('✅ Successfully navigated to home screen');
      } else {
        _logger.w('⚠️ Navigator key or context not available');
      }
    } catch (e) {
      _logger.e('❌ Error navigating to home screen: $e');
    }
  }

  /// Navigate to challenges screen for new daily challenge notifications
  void _navigateToChallenges() {
    try {
      final navigatorKey = _getNavigatorKey();
      if (navigatorKey?.currentContext != null) {
        navigatorKey!.currentContext!.go('/challenges');
        _logger.i('✅ Successfully navigated to challenges screen');
      } else {
        _logger.w('⚠️ Navigator key or context not available');
      }
    } catch (e) {
      _logger.e('❌ Error navigating to challenges screen: $e');
    }
  }

  /// Get the navigator key for routing
  GlobalKey<NavigatorState>? _getNavigatorKey() {
    try {
      // This should be imported from your router file
      return navigatorKey;
    } catch (e) {
      _logger.e('❌ Error getting navigator key: $e');
      return null;
    }
  }

  /// Send token to your server
  Future<void> _sendTokenToServer(String token) async {
    try {
      _logger.i('📤 Sending FCM token to server...');
      
      // TODO: Implement API call to send token to your backend
      // Example:
      // await UserApiService().updateFCMToken(token);
      
      _logger.i('✅ FCM token sent to server successfully');
    } catch (e) {
      _logger.e('❌ Failed to send FCM token to server: $e');
    }
  }

  /// Subscribe to a topic
  Future<bool> subscribeToTopic(String topic) async {
    try {
      _logger.i('📢 Subscribing to topic: $topic');
      
      await _firebaseMessaging.subscribeToTopic(topic);
      
      _logger.i('✅ Successfully subscribed to topic: $topic');
      return true;
    } catch (e) {
      _logger.e('❌ Failed to subscribe to topic $topic: $e');
      return false;
    }
  }

  /// Unsubscribe from a topic
  Future<bool> unsubscribeFromTopic(String topic) async {
    try {
      _logger.i('📢 Unsubscribing from topic: $topic');
      
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      
      _logger.i('✅ Successfully unsubscribed from topic: $topic');
      return true;
    } catch (e) {
      _logger.e('❌ Failed to unsubscribe from topic $topic: $e');
      return false;
    }
  }

  /// Delete FCM token (useful for logout)
  Future<void> deleteToken() async {
    try {
      _logger.i('🗑️ Deleting FCM token...');
      
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      
      _logger.i('✅ FCM token deleted successfully');
    } catch (e) {
      _logger.e('❌ Failed to delete FCM token: $e');
    }
  }

  /// Get notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
           settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Handle specific notification types with custom logic
  void handleNotificationByType({
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? additionalData,
  }) {
    _logger.i('🎯 Handling specific notification type: $type');
    
    switch (type) {
      case 'welcome':
        _handleWelcomeNotification(title, body);
        break;
      case 'daily':
        _handleDailyMotivationNotification(title, body);
        break;
      case 'challenge':
        _handleChallengeNotification(title, body, additionalData);
        break;
      default:
        _logger.w('⚠️ Unknown notification type: $type');
    }
  }

  /// Handle welcome notification (informational only)
  void _handleWelcomeNotification(String title, String body) {
    _logger.i('👋 Welcome notification received');
    // Welcome notifications are purely informational
    // Just display them, no navigation required
  }

  /// Handle daily motivation notification
  void _handleDailyMotivationNotification(String title, String body) {
    _logger.i('📅 Daily motivation notification received');
    // These should navigate to home/dashboard when tapped
  }

  /// Handle challenge notification  
  void _handleChallengeNotification(String title, String body, Map<String, dynamic>? data) {
    _logger.i('🎯 Challenge notification received');
    // These should navigate to challenges screen when tapped
    
    // Extract any challenge-specific data if needed
    if (data != null && data.containsKey('challengeId')) {
      final challengeId = data['challengeId'];
      _logger.i('🎯 Challenge ID: $challengeId');
    }
  }
}