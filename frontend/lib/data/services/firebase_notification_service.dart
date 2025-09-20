import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../../app/router/app_router.dart';
import '../../app/app_setup.dart';
import '../repositories/auth_repository.dart';
import '../../core/utils/api_result.dart';
import 'local_notification_service.dart';
import 'storage_service.dart';
import 'premium_status_service.dart';
import '../models/user_model.dart';

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final Logger _logger = Logger();
  final LocalNotificationService _localNotificationService = LocalNotificationService();

  String? _fcmToken;
  
  // Getters
  String? get fcmToken => _fcmToken;
  FirebaseMessaging get firebaseMessaging => _firebaseMessaging;

  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      _logger.i('🔔 Initializing Firebase Notification Service...');

      // Initialize local notifications first
      await _localNotificationService.initialize();

      // Request permission for notifications
      await _requestPermission();

      // Get FCM token (with timeout to prevent hanging)
      await _getFCMToken().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          _logger.w('⏰ FCM token request timed out - continuing without token');
        },
      );

      // Setup message handlers
      _setupMessageHandlers();

      // Setup token refresh handler
      _setupTokenRefreshHandler();

      _logger.i('✅ Firebase Notification Service initialized successfully');
    } catch (e) {
      _logger.e('❌ Failed to initialize Firebase Notification Service: $e');
      _logger.w('📱 App will continue without push notifications');
      // Don't rethrow to prevent app crash
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

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _logger.i('🔑 Getting FCM token...');

      // For iOS devices, try to wait for APNS token but don't block
      if (Platform.isIOS) {
        bool apnsAvailable = await _waitForAPNSToken();
        if (!apnsAvailable) {
          _logger.w('⚠️ APNS token not available - push notifications may not work');
          _logger.w('📱 Make sure:');
          _logger.w('   1. Push Notifications capability is enabled in Xcode');
          _logger.w('   2. App is properly signed with valid provisioning profile');
          _logger.w('   3. Running on real device (not simulator)');
          _logger.w('   4. Device is connected to internet');
          // Continue anyway - FCM might still work for some scenarios
        }
      }

      _fcmToken = await _firebaseMessaging.getToken();

      if (_fcmToken != null) {
        _logger.i('✅ FCM Token obtained: ${_fcmToken!.substring(0, 20)}...');
        // Send token to server
        await _sendTokenToServer(_fcmToken!);
      } else {
        _logger.w('⚠️ Failed to obtain FCM token - check APNS configuration');
      }
    } catch (e) {
      if (e.toString().contains('apns-token-not-set')) {
        _logger.e('❌ APNS token not available - push notifications will not work');
        _logger.e('🔧 To fix this:');
        _logger.e('   1. Open ios/Runner.xcworkspace in Xcode');
        _logger.e('   2. Select Runner target > Signing & Capabilities');
        _logger.e('   3. Add "Push Notifications" capability');
        _logger.e('   4. Ensure proper code signing with valid provisioning profile');
        _logger.e('   5. Test on real device, not simulator');
      } else {
        _logger.e('❌ Error getting FCM token: $e');
      }
    }
  }

  /// Wait for APNS token on iOS with retries
  Future<bool> _waitForAPNSToken() async {
    const maxRetries = 5;
    const retryDelay = Duration(seconds: 2);

    for (int i = 0; i < maxRetries; i++) {
      try {
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken != null) {
          _logger.i('📱 APNS token available: ${apnsToken.substring(0, 20)}...');
          return true;
        } else {
          _logger.w('⚠️ APNS token not available yet, attempt ${i + 1}/$maxRetries');
          if (i < maxRetries - 1) {
            await Future.delayed(retryDelay);
          }
        }
      } catch (e) {
        _logger.w('⚠️ APNS token error (attempt ${i + 1}/$maxRetries): $e');
        if (i < maxRetries - 1) {
          await Future.delayed(retryDelay);
        }
      }
    }

    _logger.w('⚠️ Could not get APNS token after $maxRetries attempts, proceeding anyway...');
    return false;
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
      // Send updated token to server
      _sendTokenToServer(newToken);
    });
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('📨 Foreground message received: ${message.messageId}');
    _logger.i('📝 Title: ${message.notification?.title}');
    _logger.i('📝 Body: ${message.notification?.body}');
    _logger.i('📦 Data: ${message.data}');

    // Show local notification immediately for foreground messages
    _showLocalNotification(message);

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

  /// Show local notification for foreground messages
  void _showLocalNotification(RemoteMessage message) {
    _logger.i('🔔 Showing local notification: ${message.notification?.title}');

    try {
      // Extract notification details
      final String? title = message.notification?.title;
      final String? body = message.notification?.body;
      final String? type = message.data['type'];

      if (title != null && body != null) {
        // Generate unique notification ID
        final int notificationId = _localNotificationService.generateNotificationId();

        // Show local notification based on type
        if (type != null) {
          _localNotificationService.showNotificationByType(
            id: notificationId,
            title: title,
            body: body,
            type: type,
            data: message.data,
          );
        } else {
          // Show default notification
          _localNotificationService.showNotification(
            id: notificationId,
            title: title,
            body: body,
            payload: message.data.toString(),
          );
        }

        _logger.i('✅ Local notification displayed successfully');
      } else {
        _logger.w('⚠️ Notification missing title or body, skipping display');
      }
    } catch (e) {
      _logger.e('❌ Error showing local notification: $e');
    }
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
        case 'payment_success':
          _logger.i('💰 Payment success notification - updating premium status');
          _handlePaymentSuccessNotification(data);
          break;
        case 'payment_failed':
          _logger.i('❌ Payment failed notification - updating premium status');
          _handlePaymentFailedNotification(data);
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

  /// Send current FCM token to server (public method for manual calls)
  Future<bool> submitTokenToServer() async {
    if (_fcmToken != null && _fcmToken!.isNotEmpty) {
      return await _sendTokenToServer(_fcmToken!);
    } else {
      _logger.w('⚠️ No FCM token available to submit');
      return false;
    }
  }

  /// Send token to your server (private method)
  Future<bool> _sendTokenToServer(String token) async {
    try {
      _logger.i('📤 Sending FCM token to server...');

      // Check if services are ready (GetIt is initialized)
      try {
        final authRepository = AuthRepository();
        final result = await authRepository.acceptNotifications(token);

        if (result.isSuccess) {
          _logger.i('✅ FCM token sent to server successfully: ${result.data!.message}');
          return true;
        } else {
          _logger.w('⚠️ Failed to send FCM token to server: ${result.error}');
          return false;
        }
      } catch (dependencyError) {
        _logger.w('⚠️ Services not ready yet, will retry later: $dependencyError');
        // Store token for later manual submission
        return false;
      }
    } catch (e) {
      _logger.e('❌ Failed to send FCM token to server: $e');
      return false;
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
      case 'payment_success':
        _handlePaymentSuccessNotificationForeground(title, body, additionalData);
        break;
      case 'payment_failed':
        _handlePaymentFailedNotificationForeground(title, body, additionalData);
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

  /// Handle payment success notification (foreground)
  void _handlePaymentSuccessNotificationForeground(String title, String body, Map<String, dynamic>? data) {
    _logger.i('💰 Payment success notification received in foreground');
    _updatePremiumStatus(true, data);
  }

  /// Handle payment failed notification (foreground)
  void _handlePaymentFailedNotificationForeground(String title, String body, Map<String, dynamic>? data) {
    _logger.i('❌ Payment failed notification received in foreground');
    _updatePremiumStatus(false, data);
  }

  /// Handle payment success notification (background/tap)
  void _handlePaymentSuccessNotification(Map<String, dynamic> data) {
    _logger.i('💰 Payment success notification tapped');
    _updatePremiumStatus(true, data);
    // Navigate to payment confirmation or home
    _navigateToHome();
  }

  /// Handle payment failed notification (background/tap)
  void _handlePaymentFailedNotification(Map<String, dynamic> data) {
    _logger.i('❌ Payment failed notification tapped');
    _updatePremiumStatus(false, data);
    // Navigate to payment screen to retry
    _navigateToHome();
  }

  /// Update premium status based on payment notification
  Future<void> _updatePremiumStatus(bool isSuccess, Map<String, dynamic>? data) async {
    try {
      _logger.i('👑 Updating premium status: success=$isSuccess');

      final storageService = locator<StorageService>();
      final premiumStatusService = locator<PremiumStatusService>();

      // Get current user
      final user = await storageService.getUser();
      if (user == null) {
        _logger.w('⚠️ No user found to update premium status');
        return;
      }

      // Extract payment information if available
      final paymentId = data?['payment_id'];
      _logger.i('💳 Payment ID: $paymentId');

      // Update user's premium status
      final updatedUser = UserModel(
        id: user.id,
        email: user.email,
        name: user.name,
        isEmailVerified: user.isEmailVerified,
        isActive: user.isActive,
        createdAt: user.createdAt,
        updatedAt: DateTime.now(),
        lastLoginAt: user.lastLoginAt,
        role: user.role,
        planType: isSuccess ? 'premium' : 'free',
        planName: isSuccess ? 'Yefa +' : 'Free',
        planStartDate: isSuccess ? DateTime.now() : user.planStartDate,
        planEndDate: isSuccess ? null : user.planEndDate, // No end date for premium
        planAutoRenew: user.planAutoRenew,
        planStatus: isSuccess ? 'active' : 'inactive',
      );

      // Save updated user to storage
      await storageService.saveUser(updatedUser);

      _logger.i('✅ Premium status updated successfully: ${isSuccess ? 'PREMIUM' : 'FREE'}');

      // Store a flag for UI updates (keeping for backwards compatibility)
      await storageService.setBool('premium_status_updated', true);
      await storageService.setString('premium_update_type', isSuccess ? 'success' : 'failed');

      // NEW: Broadcast the premium status change to all listeners
      premiumStatusService.notifyPremiumStatusUpdate(
        isPremium: isSuccess,
        updateType: isSuccess ? 'success' : 'failed',
        paymentId: paymentId,
      );

      _logger.i('🔔 Premium status update broadcasted to all listeners');

    } catch (e) {
      _logger.e('❌ Error updating premium status: $e');
    }
  }
}