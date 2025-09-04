import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yefa/app/app_setup.dart';
import 'package:yefa/core/utils/api_result.dart';
import 'package:yefa/data/models/challenge_stats_model.dart';
import 'package:yefa/data/repositories/challenge_repository.dart';
import 'package:yefa/data/repositories/payment_repository.dart';
import 'package:yefa/data/services/payment_service.dart';
import 'package:yefa/data/services/storage_service.dart';
import 'package:yefa/data/services/theme_service.dart';
import 'package:yefa/presentation/shared/widgets/payment_provider_sheet.dart';
import 'package:yefa/presentation/shared/widgets/toast_overlay.dart';
import 'widgets/upgrade_popup.dart';

class ProfileViewModel extends BaseViewModel {
  final _themeService = locator<ThemeService>();
  final _storageService = locator<StorageService>();
  final PaymentRepository _paymentRepository = locator<PaymentRepository>();
  final PaymentService _paymentService = locator<PaymentService>();
  final ChallengeRepository _challengeRepository =
      locator<ChallengeRepository>();

  BuildContext? _context;
  bool contextAlreadySet = false;

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
        print('✅ ProfileViewModel: Stripe payment successful!');

        // Update premium status
        _isPremium = true;
        notifyListeners();

        // Show success message
        ToastOverlay.showSuccess(
          context: _context!,
          message: 'Welcome to Yefa Plus! 🎉👑',
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
        print('✅ ProfileViewModel: Paystack payment successful!');

        // Update premium status
        _isPremium = true;
        notifyListeners();

        // Show success message
        ToastOverlay.showSuccess(
          context: _context!,
          message: 'Welcome to Yefa Plus! 🎉👑',
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

  void toggleNotifications() {
    _isNotificationsEnabled = !_isNotificationsEnabled;
    _storageService.setBool('isNotificationsEnabled', _isNotificationsEnabled);

    print('=== NOTIFICATIONS TOGGLED ===');
    print('Notifications enabled: $_isNotificationsEnabled');
    print('============================');

    notifyListeners();
  }

  void navigateToVerseLanguage() {
    print('Navigate to Verse Language settings');
    // TODO: Implement navigation
  }

  Future<void> navigateToYefaManCave() async {
    try {
      // WhatsApp group invite link - replace with your actual group link
      const whatsappGroupUrl = 'https://chat.whatsapp.com/HwQ2Gq8D3FkKBlp85qKRio?mode=ems_copy_t';
      
      // Try to open WhatsApp directly first
      final whatsappAppUrl = Uri.parse('whatsapp://send?text=Hello');
      final whatsappWebUrl = Uri.parse(whatsappGroupUrl);
      
      // Check if WhatsApp app is installed
      if (await canLaunchUrl(whatsappAppUrl)) {
        // WhatsApp is installed, try to open the group link
        if (await canLaunchUrl(whatsappWebUrl)) {
          await launchUrl(
            whatsappWebUrl,
            mode: LaunchMode.externalApplication,
          );
          print('✅ Opened WhatsApp group successfully');
        } else {
          _showUrlError('Could not open WhatsApp group');
        }
      } else {
        // WhatsApp not installed, open in browser or app store
        await _handleAppNotInstalled('WhatsApp', whatsappWebUrl);
      }
    } catch (e) {
      print('❌ Error opening WhatsApp: $e');
      _showUrlError('Failed to open WhatsApp');
    }
  }

  Future<void> navigateToTowelTalk() async {
    try {
      // Telegram channel/group link - replace with your actual channel
      const telegramChannelUrl = 'https://t.me/yefadaily';
      
      // Try to open Telegram directly first
      final telegramAppUrl = Uri.parse('tg://msg');
      final telegramWebUrl = Uri.parse(telegramChannelUrl);
      
      // Check if Telegram app is installed
      if (await canLaunchUrl(telegramAppUrl)) {
        // Telegram is installed, try to open the channel link
        if (await canLaunchUrl(telegramWebUrl)) {
          await launchUrl(
            telegramWebUrl,
            mode: LaunchMode.externalApplication,
          );
          print('✅ Opened Telegram channel successfully');
        } else {
          _showUrlError('Could not open Telegram channel');
        }
      } else {
        // Telegram not installed, open in browser or app store
        await _handleAppNotInstalled('Telegram', telegramWebUrl);
      }
    } catch (e) {
      print('❌ Error opening Telegram: $e');
      _showUrlError('Failed to open Telegram');
    }
  }

  Future<void> _handleAppNotInstalled(String appName, Uri fallbackUrl) async {
    if (_context == null) return;
    
    // Show dialog asking user to install the app or open in browser
    final shouldInstall = await showDialog<bool>(
      context: _context!,
      builder: (context) => AlertDialog(
        title: Text('$appName Not Installed'),
        content: Text(
          '$appName is not installed on your device. Would you like to install it or open the link in your browser?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Open in Browser'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Install App'),
          ),
        ],
      ),
    );

    if (shouldInstall == true) {
      // Open app store
      final appStoreUrl = appName == 'WhatsApp'
          ? Uri.parse('https://wa.me/') // WhatsApp download page
          : Uri.parse('https://telegram.org/'); // Telegram download page
      
      await launchUrl(appStoreUrl, mode: LaunchMode.externalApplication);
    } else if (shouldInstall == false) {
      // Open in browser
      await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
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
