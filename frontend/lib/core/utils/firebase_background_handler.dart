import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';

/// Top-level function to handle background messages
/// This must be a top-level function or static method
/// 
/// Handles three types of notifications:
/// - 'welcome': User enables notifications (informational only)
/// - 'daily': Daily motivation at user's scheduled times  
/// - 'challenge': New daily challenge available
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final logger = Logger();
  
  logger.i('🔔 Background message received: ${message.messageId}');
  logger.i('📝 Title: ${message.notification?.title}');
  logger.i('📝 Body: ${message.notification?.body}');
  logger.i('📦 Data: ${message.data}');
  
  // Extract notification type for logging and potential processing
  final String? notificationType = message.data['type'];
  logger.i('🏷️ Notification type: $notificationType');
  
  // Handle background message processing based on type
  switch (notificationType) {
    case 'welcome':
      logger.i('👋 Processing welcome notification in background');
      break;
    case 'daily':
      logger.i('📅 Processing daily motivation notification in background');
      break;
    case 'challenge':
      logger.i('🎯 Processing new daily challenge notification in background');
      break;
    default:
      logger.i('❓ Processing unknown notification type in background');
  }
  
  // Note: UI updates are not possible in background handler
  // You can save notification data to local storage
  // or perform other background tasks here if needed
}