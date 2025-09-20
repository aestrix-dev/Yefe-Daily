// Example showing how to integrate FCM token submission with your auth flow
// This is for demonstration purposes - integrate this logic in your actual auth views

import 'package:flutter/material.dart';
import '../../data/services/firebase_notification_service.dart';

class FCMIntegrationExample {
  final FirebaseNotificationService _fcmService = FirebaseNotificationService();

  /// Call this after successful user registration or login
  Future<void> handlePostAuthFCMSubmission() async {
    try {
      // 1. Ensure FCM service is initialized
      await _fcmService.initialize();

      // 2. Submit the current FCM token to the server
      bool success = await _fcmService.submitTokenToServer();

      if (success) {

        // Show success message to user if needed
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Notifications enabled successfully!'))
        // );
      } else {

        // Handle failure - maybe retry later or show message to user
      }
    } catch (e) {

    }
  }

  /// Alternative approach: Submit FCM token manually when user enables notifications
  /// Call this when user clicks "Enable Notifications" button in settings
  Future<void> enableNotifications(BuildContext context) async {
    try {
      // Check if notifications are already enabled
      bool areEnabled = await _fcmService.areNotificationsEnabled();

      if (!areEnabled) {
        // Show dialog to explain notification benefits
        bool userConsent = await _showNotificationPermissionDialog(context);
        if (!userConsent) return;
      }

      // Initialize FCM service (this will request permissions)
      await _fcmService.initialize();

      // Submit token to server
      bool success = await _fcmService.submitTokenToServer();

      if (success) {
        _showSuccessMessage(context, 'Notifications enabled successfully!');
      } else {
        _showErrorMessage(context, 'Failed to enable notifications. Please try again.');
      }
    } catch (e) {
      _showErrorMessage(context, 'An error occurred while enabling notifications.');
    }
  }

  /// Show dialog to get user consent for notifications
  Future<bool> _showNotificationPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enable Notifications'),
          content: const Text(
            'Would you like to receive daily devotionals, challenges, and reminders? '
            'You can change this setting anytime.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No Thanks'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enable'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Usage example in your login/register flow:
class AuthViewExample extends StatelessWidget {
  final FCMIntegrationExample _fcmIntegration = FCMIntegrationExample();

  AuthViewExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auth Example')),
      body: Column(
        children: [
          // Your existing auth UI...

          ElevatedButton(
            onPressed: () async {
              // After successful registration/login:
              // await handleUserRegistration();

              // Then handle FCM token submission:
              await _fcmIntegration.handlePostAuthFCMSubmission();
            },
            child: const Text('Login/Register'),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () => _fcmIntegration.enableNotifications(context),
            child: const Text('Enable Notifications'),
          ),
        ],
      ),
    );
  }
}