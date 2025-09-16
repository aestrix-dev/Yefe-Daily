import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:yefa/core/utils/api_result.dart';
import '../../../data/repositories/journal_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/services/payment_service.dart';
import '../../../data/services/premium_status_service.dart';
import '../../shared/widgets/payment_provider_sheet.dart';
import '../../shared/widgets/toast_overlay.dart';
import '../../../app/app_setup.dart';

class JournalViewModel extends BaseViewModel {
  final JournalRepository _journalRepository = locator<JournalRepository>();
  final PaymentRepository _paymentRepository = locator<PaymentRepository>();
  final PaymentService _paymentService = locator<PaymentService>();
  final PremiumStatusService _premiumStatusService = locator<PremiumStatusService>();

  int _selectedTabIndex = 0;
  String _journalContent = '';
  final List<String> _selectedTags = [];
  bool _isPremiumUser = false;
  final bool _hasUpgraded = false;
  bool _isSaving = false;
  StreamSubscription<PremiumStatusUpdate>? _premiumStatusSubscription;

  BuildContext? _context;
  bool contextAlreadySet = false;

  void setContext(BuildContext context) {
    if (!contextAlreadySet) {
      _context = context;
      contextAlreadySet = true;
      _checkPremiumStatus();
      _setupPremiumStatusListener();
    }
  }

  // Check premium status when context is set
  Future<void> _checkPremiumStatus() async {
    _isPremiumUser = await _paymentService.isUserPremium();
    notifyListeners();
  }

  /// Set up listener for premium status updates from notifications
  void _setupPremiumStatusListener() {
    _premiumStatusSubscription = _premiumStatusService.premiumStatusUpdates.listen(
      (update) {
        print('🔔 Premium status update received in JournalView: $update');

        // Update the premium status immediately
        _isPremiumUser = update.isPremium;

        // Show toast message to user if context is available
        if (_context != null) {
          if (update.updateType == 'success') {
            ToastOverlay.showSuccess(
              context: _context!,
              message: 'Welcome to Yefa Plus! Evening journaling is now unlocked 📝👑',
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

        print('👑 Premium status updated in JournalView UI: $_isPremiumUser');
      },
      onError: (error) {
        print('❌ Error listening to premium status updates in JournalView: $error');
      },
    );
  }

  @override
  void dispose() {
    _premiumStatusSubscription?.cancel();
    super.dispose();
  }

  // Getters
  int get selectedTabIndex => _selectedTabIndex;
  String get journalContent => _journalContent;
  List<String> get selectedTags => _selectedTags;
  bool get isPremiumUser => _isPremiumUser;
  bool get hasUpgraded => _hasUpgraded;
  bool get isEveningTabSelected => _selectedTabIndex == 1;
  bool get shouldShowUpgradeCard =>
      isEveningTabSelected && !_isPremiumUser && !_hasUpgraded;
  bool get isSaving => _isSaving;

  final List<String> availableTags = [
    'Faith',
    'Family',
    'Focus',
    'Rest',
    'Growth',
    'Gratitude',
  ];

  final List<String> tabTitles = ['Morning', 'Evening', 'Wisdom Note'];

  void selectTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void updateJournalContent(String content) {
    _journalContent = content;
    notifyListeners();
  }

  void toggleTag(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    notifyListeners();
  }

  void showPaymentSheet() {
    if (_context == null) return;

    showModalBottomSheet(
      context: _context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentProviderSheet(
        onStripeTap: () async {
          Navigator.of(context).pop(); 
          await _handleStripePayment();
        },
        onPaystackTap: () async {
          Navigator.of(context).pop(); 
          await _handlePaystackPayment();
        },
      ),
    );
  }

 Future<void> _handleStripePayment() async {
    if (_context == null) return;

    try {
      print('JournalViewModel: Processing Stripe payment...');

      // Show loading dialog
      _showLoadingDialog('Processing payment...');

      final result = await _paymentRepository.processPayment(
        provider: 'stripe',
        context: _context!,
      );

      // Hide loading dialog
      Navigator.of(_context!).pop();

      if (result.isSuccess) {
        final verification = result.data!;

        if (verification.isSuccessful) {
          print('JournalViewModel: Stripe payment successful!');
          _isPremiumUser = true;
          notifyListeners();

          ToastOverlay.showSuccess(
            context: _context!,
            message: 'Payment successful! You now have premium access 🎉',
          );
        } else if (verification.isProcessing) {
          print('JournalViewModel: Stripe payment is processing...');

          ToastOverlay.showWarning(
            context: _context!,
            message:
                'Payment is being processed. You will be notified when complete.',
          );
        }
      } else {
        print('JournalViewModel: Stripe payment failed: ${result.error}');
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

      print('JournalViewModel: Stripe payment error: $e');
      ToastOverlay.showError(context: _context!, message: 'Payment failed: $e');
    }
  }

  Future<void> _handlePaystackPayment() async {
    if (_context == null) return;

    try {
      print('JournalViewModel: Processing Paystack payment...');

      // Show loading dialog
      _showLoadingDialog('Processing payment...');

      final result = await _paymentRepository.processPayment(
        provider: 'paystack',
        context: _context!,
      );

      // Hide loading dialog
      Navigator.of(_context!).pop();

      if (result.isSuccess) {
        final verification = result.data!;

        if (verification.isSuccessful) {
          print('JournalViewModel: Paystack payment successful!');
          _isPremiumUser = true;
          notifyListeners();

          ToastOverlay.showSuccess(
            context: _context!,
            message: 'Payment successful! You now have premium access 🎉',
          );
        } else if (verification.isProcessing) {
          print('JournalViewModel: Paystack payment is processing...');

          ToastOverlay.showWarning(
            context: _context!,
            message:
                'Payment is being processed. You will be notified when complete.',
          );
        }
      } else {
        print('JournalViewModel: Paystack payment failed: ${result.error}');
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

      print('JournalViewModel: Paystack payment error: $e');
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

  Future<void> saveJournalEntry() async {
    if (_journalContent.trim().isEmpty) {
      if (_context != null) {
        ToastOverlay.showError(
          context: _context!,
          message: 'Cannot save empty journal entry',
        );
      }
      return;
    }

    _setSaving(true);

    try {
      final result = await _journalRepository.createJournalEntry(
        content: _journalContent.trim(),
        type: _getJournalTypeString(),
        tags: List.from(_selectedTags),
      );

      if (result.isSuccess) {
        if (_context != null) {
          ToastOverlay.showSuccess(
            context: _context!,
            message: 'Ledger created successfully! 🎉',
          );
        }

        _clearForm();
      } else {
        if (_context != null) {
          ToastOverlay.showError(
            context: _context!,
            message: result.error ?? 'Failed to save journal entry',
          );
        }
      }
    } catch (e) {
      if (_context != null) {
        ToastOverlay.showError(
          context: _context!,
          message: 'An unexpected error occurred while saving',
        );
      }
    } finally {
      _setSaving(false);
    }
  }

  String _getJournalTypeString() {
    switch (_selectedTabIndex) {
      case 0:
        return 'morning';
      case 1:
        return 'evening';
      case 2:
        return 'wisdom_note';
      default:
        return 'morning';
    }
  }

  void _clearForm() {
    _journalContent = '';
    _selectedTags.clear();
    notifyListeners();
  }

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }
}
