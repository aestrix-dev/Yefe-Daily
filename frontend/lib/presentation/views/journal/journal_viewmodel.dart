// File: ui/views/journal/journal_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:yefa/core/utils/api_result.dart';
import '../../../data/repositories/journal_repository.dart';
import '../../shared/widgets/payment_provider_sheet.dart';
import '../../shared/widgets/toast_overlay.dart';
import '../../../app/app_setup.dart';

class JournalViewModel extends BaseViewModel {
  final JournalRepository _journalRepository = locator<JournalRepository>();

  int _selectedTabIndex = 0;
  String _journalContent = '';
  final List<String> _selectedTags = [];
  final bool _isPremiumUser = false;
  final bool _hasUpgraded = false;
  bool _isSaving = false;

  BuildContext? _context;
  bool contextAlreadySet = false;

  void setContext(BuildContext context) {
    if (!contextAlreadySet) {
      _context = context;
      contextAlreadySet = true;
    }
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
        onStripeTap: () {
          print('Stripe selected');
          // TODO: implement Stripe payment logic
        },
        onPaystackTap: () {
          print('Paystack selected');
          // TODO: implement Paystack payment logic
        },
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
        return 'wisdom';
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
