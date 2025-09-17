import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:stacked/stacked.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yefa/app/app_setup.dart';
import 'package:yefa/core/constants/app_routes.dart';
import 'package:yefa/core/utils/api_result.dart';
import 'package:yefa/data/models/challenge_stats_model.dart';
import 'package:yefa/data/repositories/challenge_repository.dart';
import 'package:yefa/data/repositories/payment_repository.dart';
import 'package:yefa/data/services/payment_service.dart';
import 'package:yefa/data/services/storage_service.dart';
import 'package:yefa/data/services/theme_service.dart';
import 'package:yefa/data/services/firebase_notification_service.dart';
import 'package:yefa/data/services/premium_status_service.dart';
import 'package:yefa/presentation/shared/widgets/payment_provider_sheet.dart';
import 'package:yefa/presentation/shared/widgets/toast_overlay.dart';
import 'widgets/upgrade_popup.dart';
import 'widgets/notification_popup.dart';

class ProfileViewModel extends BaseViewModel {
  final _themeService = locator<ThemeService>();
  final _storageService = locator<StorageService>();
  final PaymentRepository _paymentRepository = locator<PaymentRepository>();
  final PaymentService _paymentService = locator<PaymentService>();
  final ChallengeRepository _challengeRepository =
      locator<ChallengeRepository>();
  final _fcmService = FirebaseNotificationService();
  final _premiumStatusService = locator<PremiumStatusService>();

  BuildContext? _context;
  bool contextAlreadySet = false;
  StreamSubscription<PremiumStatusUpdate>? _premiumStatusSubscription;

  // User data
  String _userName = 'Guest';
  final String _avatarUrl = 'assets/images/avatar.png';
  bool _isPremium = false;
  final bool _showUpgrade = false;
  bool _isNotificationsEnabled = true;

  // Challenge stats
  ChallengeStatsModel _challengeStats = ChallengeStatsModel(
    userId: '',
    totalChallenges: 0,
    completedCount: 0,
    totalPoints: 0,
    currentStreak: 0,
    longestStreak: 0,
    sevenDaysProgress: 0,
    numberOfBadges: 0,
  );

  // Getters
  String get userName => _userName;
  String get avatarUrl => _avatarUrl;
  bool get isPremium => _isPremium;
  bool get showUpgrade => _showUpgrade;
  bool get isNotificationsEnabled => _isNotificationsEnabled;
  bool get isDarkMode => _themeService.isDarkMode;
  ChallengeStatsModel get challengeStats => _challengeStats;

  String get userPlan => _isPremium ? 'Yefa +' : 'Free plan';

  void setContext(BuildContext context) {
    if (!contextAlreadySet) {
      _context = context;
      contextAlreadySet = true;
    }
  }

  void onModelReady() {
    _loadUserData();
    _loadChallengeStats();
    _checkForPremiumStatusUpdates();
    _setupPremiumStatusListener();
  }

  @override
  void dispose() {
    _premiumStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = await _storageService.getUser();
    _userName = user?.name ?? 'Guest';

    // Check premium status using payment service
    _isPremium = await _paymentService.isUserPremium();
    _isNotificationsEnabled =
        _storageService.getBool('isNotificationsEnabled') ?? true;

    print('👤 User loaded: $_userName');
    print('👑 Premium status: $_isPremium');
    notifyListeners();
  }

  Future<void> _loadChallengeStats() async {
    try {
      final result = await _challengeRepository.getChallengeStats();

      if (result.isSuccess) {
        _challengeStats = result.data!;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading challenge stats in profile: $e');
    }
  }

  /// Check if premium status was updated from payment notifications
  Future<void> _checkForPremiumStatusUpdates() async {
    try {
      final wasUpdated = _storageService.getBool('premium_status_updated') ?? false;

      if (wasUpdated) {
        print('👑 Premium status was updated from notification, refreshing UI...');

        // Clear the update flag
        await _storageService.remove('premium_status_updated');

        // Get the update type
        final updateType = _storageService.getString('premium_update_type') ?? 'unknown';
        await _storageService.remove('premium_update_type');

        // Reload user data to get latest premium status
        await _loadUserData();

        // Show appropriate message to user if context is available
        if (_context != null) {
          if (updateType == 'success') {
            ToastOverlay.showSuccess(
              context: _context!,
              message: 'Welcome to Yefa Plus! Your payment was successful 🎉👑',
            );
          } else if (updateType == 'failed') {
            ToastOverlay.showError(
              context: _context!,
              message: 'Payment failed. Please try again or contact support.',
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error checking premium status updates: $e');
    }
  }

  /// Set up listener for premium status updates from notifications
  void _setupPremiumStatusListener() {
    _premiumStatusSubscription = _premiumStatusService.premiumStatusUpdates.listen(
      (update) {
        print('🔔 Premium status update received: $update');

        // Update the premium status immediately
        _isPremium = update.isPremium;

        // Show toast message to user if context is available
        if (_context != null) {
          if (update.updateType == 'success') {
            ToastOverlay.showSuccess(
              context: _context!,
              message: 'Welcome to Yefa Plus! Your payment was successful 🎉👑',
            );
          } else if (update.updateType == 'failed') {
            ToastOverlay.showError(
              context: _context!,
              message: 'Payment failed. Please try again or contact support.',
            );
          }
        }

        // Notify UI to rebuild
        notifyListeners();

        print('👑 Premium status updated in UI: $_isPremium');
      },
      onError: (error) {
        print('❌ Error listening to premium status updates: $error');
      },
    );
  }

  /// Public method to refresh premium status (can be called from other parts of the app)
  Future<void> refreshPremiumStatus() async {
    await _loadUserData();
  }

  void showUpgradeCard() {
    // This method shows the popup (called from profile header)
    if (_context == null) return;

    if (!isPremium) {
      showDialog(
        context: _context!,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.7),
        builder: (context) => UpgradePopup(
          onUpgrade: () {
            Navigator.of(context).pop(); // Close popup first
            upgradeToPremium(); // Then show payment providers
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      );
    }
  }

  void upgradeToPremium() {
    // This method is called from the popup's upgrade button
    if (_context == null) return;

    showModalBottomSheet(
      context: _context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentProviderSheet(
        onStripeTap: () async {
          Navigator.of(context).pop(); // Close provider sheet
          await _handleStripePayment();
        },
        onPaystackTap: () async {
          Navigator.of(context).pop(); // Close provider sheet
          await _handlePaystackPayment();
        },
      ),
    );
  }

  Future<void> _handleStripePayment() async {
    if (_context == null) return;

    try {
      print('💳 ProfileViewModel: Processing Stripe payment...');

      // Show loading dialog
      _showLoadingDialog('Processing payment...');

      final result = await _paymentRepository.processPayment(
        provider: 'stripe',
        context: _context!,
      );

      // Hide loading dialog
      Navigator.of(_context!).pop();

      if (result.isSuccess) {
        print('✅ ProfileViewModel: Stripe payment initiated successfully!');

        // DO NOT update premium status here - wait for payment notification
        // _isPremium = true; // REMOVED - only update from notification

        // Show processing message
        ToastOverlay.showSuccess(
          context: _context!,
          message: 'Payment initiated! You\'ll be notified when complete.',
        );
      } else {
        print('❌ ProfileViewModel: Stripe payment failed: ${result.error}');
        ToastOverlay.showError(
          context: _context!,
          message: result.error ?? 'Payment failed',
        );
      }
    } catch (e) {
      // Hide loading if still showing
      if (Navigator.canPop(_context!)) {
        Navigator.of(_context!).pop();
      }

      print('❌ ProfileViewModel: Stripe payment error: $e');
      ToastOverlay.showError(context: _context!, message: 'Payment failed: $e');
    }
  }

  Future<void> _handlePaystackPayment() async {
    if (_context == null) return;

    try {
      print('💳 ProfileViewModel: Processing Paystack payment...');

      // Show loading dialog
      _showLoadingDialog('Processing payment...');

      final result = await _paymentRepository.processPayment(
        provider: 'paystack',
        context: _context!,
      );

      // Hide loading dialog
      Navigator.of(_context!).pop();

      if (result.isSuccess) {
        print('✅ ProfileViewModel: Paystack payment initiated successfully!');

        // DO NOT update premium status here - wait for payment notification
        // _isPremium = true; // REMOVED - only update from notification

        // Show processing message
        ToastOverlay.showSuccess(
          context: _context!,
          message: 'Payment initiated! You\'ll be notified when complete.',
        );
      } else {
        print('❌ ProfileViewModel: Paystack payment failed: ${result.error}');
        ToastOverlay.showError(
          context: _context!,
          message: result.error ?? 'Payment failed',
        );
      }
    } catch (e) {
      // Hide loading if still showing
      if (Navigator.canPop(_context!)) {
        Navigator.of(_context!).pop();
      }

      print('❌ ProfileViewModel: Paystack payment error: $e');
      ToastOverlay.showError(context: _context!, message: 'Payment failed: $e');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void toggleTheme() {
    _themeService.toggleTheme();
    notifyListeners();
  }

  Future<void> showNotificationDialog() async {
    if (_context == null) return;

    // Show the notification popup
    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (context) => NotificationPopup(
        isEnabled: _isNotificationsEnabled,
        onEnable: () async {
          await _handleNotificationToggle();
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _handleNotificationToggle() async {
    _isNotificationsEnabled = !_isNotificationsEnabled;
    _storageService.setBool('isNotificationsEnabled', _isNotificationsEnabled);

    print('=== NOTIFICATIONS TOGGLED ===');
    print('Notifications enabled: $_isNotificationsEnabled');

    if (_isNotificationsEnabled) {
      print('📤 Attempting to submit FCM token manually...');

      try {
        // Try to submit FCM token to server
        bool success = await _fcmService.submitTokenToServer();

        if (success) {
          print('✅ FCM token submitted successfully');
          if (_context != null) {
            Navigator.of(_context!).pop(); // Close popup
            ToastOverlay.showSuccess(
              context: _context!,
              message: 'Notifications enabled successfully! 🔔',
            );
          }
        } else {
          print('⚠️ FCM token submission failed');
          if (_context != null) {
            Navigator.of(_context!).pop(); // Close popup
            ToastOverlay.showError(
              context: _context!,
              message: 'Failed to enable notifications. Please try again.',
            );
          }
        }
      } catch (e) {
        print('❌ Error submitting FCM token: $e');
        if (_context != null) {
          Navigator.of(_context!).pop(); // Close popup
          ToastOverlay.showError(
            context: _context!,
            message: 'Network error. Please try again.',
          );
        }
      }
    } else {
      print('🔕 Notifications disabled');
      if (_context != null) {
        Navigator.of(_context!).pop(); // Close popup
        ToastOverlay.showSuccess(
          context: _context!,
          message: 'Notifications disabled',
        );
      }
    }

    print('============================');
    notifyListeners();
  }

  void navigateToMoodAnalytics() {
    if (_context != null) {
      // Navigate to sleep journal first, which then has button to analytics
      _context!.go(AppRoutes.sleepJournal);
    }
  }

  Future<void> navigateToYefaManCave() async {
    try {
      // WhatsApp group invite link - replace with your actual group link
      const whatsappGroupUrl = 'https://chat.whatsapp.com/HwQ2Gq8D3FkKBlp85qKRio?mode=ems_copy_t';
      
      final whatsappWebUrl = Uri.parse(whatsappGroupUrl);
      
      // Try multiple approaches to open WhatsApp
      bool opened = false;
      
      // 1. Try to open with external application (will open WhatsApp if installed)
      try {
        opened = await launchUrl(
          whatsappWebUrl,
          mode: LaunchMode.externalApplication,
        );
        if (opened) {
          print('✅ Opened WhatsApp group with external app');
          return;
        }
      } catch (e) {
        print('External app launch failed: $e');
      }
      
      // 2. Try with platformDefault mode
      try {
        opened = await launchUrl(
          whatsappWebUrl,
          mode: LaunchMode.platformDefault,
        );
        if (opened) {
          print('✅ Opened WhatsApp group with platform default');
          return;
        }
      } catch (e) {
        print('Platform default launch failed: $e');
      }
      
      // 3. Final fallback - open in web browser
      await launchUrl(
        whatsappWebUrl,
        mode: LaunchMode.inAppWebView,
      );
      print('✅ Opened WhatsApp group in browser');
      
    } catch (e) {
      print('❌ Error opening WhatsApp: $e');
      _showUrlError('Failed to open WhatsApp. Please check your internet connection.');
    }
  }

  Future<void> navigateToTowelTalk() async {
    try {
      // Telegram channel/group link - replace with your actual channel
      const telegramChannelUrl = 'https://t.me/yefadaily';
      
      final telegramWebUrl = Uri.parse(telegramChannelUrl);
      
      // Try multiple approaches to open Telegram
      bool opened = false;
      
      // 1. Try to open with external application (will open Telegram if installed)
      try {
        opened = await launchUrl(
          telegramWebUrl,
          mode: LaunchMode.externalApplication,
        );
        if (opened) {
          print('✅ Opened Telegram channel with external app');
          return;
        }
      } catch (e) {
        print('External app launch failed: $e');
      }
      
      // 2. Try with platformDefault mode
      try {
        opened = await launchUrl(
          telegramWebUrl,
          mode: LaunchMode.platformDefault,
        );
        if (opened) {
          print('✅ Opened Telegram channel with platform default');
          return;
        }
      } catch (e) {
        print('Platform default launch failed: $e');
      }
      
      // 3. Final fallback - open in web browser
      await launchUrl(
        telegramWebUrl,
        mode: LaunchMode.inAppWebView,
      );
      print('✅ Opened Telegram channel in browser');
      
    } catch (e) {
      print('❌ Error opening Telegram: $e');
      _showUrlError('Failed to open Telegram. Please check your internet connection.');
    }
  }


  void _showUrlError(String message) {
    if (_context == null) return;
    
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
