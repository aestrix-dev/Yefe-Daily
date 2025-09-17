import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'dart:io' show Platform;

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();

  /// Initialize the local notification service
  Future<void> initialize() async {
    try {
      _logger.i('🔔 Initializing Local Notification Service...');

      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      final DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: false,
        requestProvisionalPermission: false,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
        notificationCategories: [
          DarwinNotificationCategory(
            'yefa_daily_category',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain('view_action', 'View'),
              DarwinNotificationAction.plain('dismiss_action', 'Dismiss'),
            ],
            options: <DarwinNotificationCategoryOption>{
              DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
            },
          ),
        ],
      );

      // Combined initialization settings
      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      // Initialize plugin
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      // Request permissions for Android 13+
      if (Platform.isAndroid) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }

      _logger.i('✅ Local Notification Service initialized successfully');
    } catch (e) {
      _logger.e('❌ Failed to initialize Local Notification Service: $e');
      rethrow;
    }
  }

  /// Handle notification tap response
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    _logger.i('🔔 Notification tapped: ${response.payload}');

    // Handle notification tap based on payload
    if (response.payload != null) {
      _handleNotificationTap(response.payload!);
    }
  }

  /// Handle notification tap navigation
  void _handleNotificationTap(String payload) {
    try {
      // Parse payload and navigate accordingly
      // For now, just log - you can add navigation logic here
      _logger.i('🧭 Handling notification tap with payload: $payload');

      // Example: Navigate based on notification type
      // final data = jsonDecode(payload);
      // final type = data['type'];
      // NavigationService.navigateTo(route);

    } catch (e) {
      _logger.e('❌ Error handling notification tap: $e');
    }
  }

  /// Show a local notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'yefa_daily_channel',
    String channelName = 'Yefa Daily Notifications',
    String channelDescription = 'Daily devotionals, challenges, and reminders',
  }) async {
    try {
      _logger.i('🔔 Showing local notification: $title');

      // Android notification details
      final AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        color: const Color(0xFF374035), // App primary color
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: true,
          contentTitle: title,
          htmlFormatContentTitle: true,
        ),
      );

      // iOS notification details
      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
      );

      // Combined notification details
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      // Show the notification
      await _flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      _logger.i('✅ Local notification shown successfully');
    } catch (e) {
      _logger.e('❌ Failed to show local notification: $e');
    }
  }

  /// Show notification with custom styling for different types
  Future<void> showNotificationByType({
    required int id,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    String payload = '';
    if (data != null) {
      payload = data.toString(); // Simple string conversion, you can use JSON
    }

    // Customize notification based on type
    switch (type) {
      case 'welcome':
        await showNotification(
          id: id,
          title: '👋 $title',
          body: body,
          payload: payload,
          channelId: 'welcome_channel',
          channelName: 'Welcome Messages',
        );
        break;
      case 'daily':
        await showNotification(
          id: id,
          title: '📅 $title',
          body: body,
          payload: payload,
          channelId: 'daily_channel',
          channelName: 'Daily Devotionals',
        );
        break;
      case 'challenge':
        await showNotification(
          id: id,
          title: '🎯 $title',
          body: body,
          payload: payload,
          channelId: 'challenge_channel',
          channelName: 'Daily Challenges',
        );
        break;
      default:
        await showNotification(
          id: id,
          title: title,
          body: body,
          payload: payload,
        );
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
      _logger.i('✅ Notification cancelled: $id');
    } catch (e) {
      _logger.e('❌ Failed to cancel notification $id: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      _logger.i('✅ All notifications cancelled');
    } catch (e) {
      _logger.e('❌ Failed to cancel all notifications: $e');
    }
  }

  /// Generate unique notification ID
  int generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }
}