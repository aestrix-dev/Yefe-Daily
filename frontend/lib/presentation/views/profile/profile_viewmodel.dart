import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:yefa/app/app_setup.dart';
import 'package:yefa/core/utils/api_result.dart';
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

  BuildContext? _context;
  bool contextAlreadySet = false;

  // User data
  String _userName = 'Guest';
  final String _avatarUrl = 'assets/images/avatar.png';
  bool _isPremium = false;
  bool _showUpgrade = false;
  bool _isNotificationsEnabled = true;

  // Getters
  String get userName => _userName;
  String get avatarUrl => _avatarUrl;
  bool get isPremium => _isPremium;
  bool get showUpgrade => _showUpgrade;
  bool get isNotificationsEnabled => _isNotificationsEnabled;
  bool get isDarkMode => _themeService.isDarkMode;

  String get userPlan => _isPremium ? 'Yefa +' : 'Free plan';

  void setContext(BuildContext context) {
    if (!contextAlreadySet) {
      _context = context;
      contextAlreadySet = true;
    }
  }

  void onModelReady() {
    _loadUserData();
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

  void navigateToYefaManCave() {
    print('Navigate to WhatsApp group');
    // TODO: Implement navigation
  }

  void navigateToTowelTalk() {
    print('Navigate to Towel Talk');
    // TODO: Implement navigation
  }
}
