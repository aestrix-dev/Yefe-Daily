// File: ui/views/journal/journal_viewmodel.dart (fixed to pass context directly)
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:yefa/core/utils/api_result.dart';
import '../../../data/repositories/journal_repository.dart';
import '../../shared/widgets/toast_overlay.dart';
import '../../../app/app_setup.dart';

class JournalViewModel extends BaseViewModel {
  final JournalRepository _journalRepository = locator<JournalRepository>();

  int _selectedTabIndex = 0;
  String _journalContent = '';
  final List<String> _selectedTags = [];
  final bool _isPremiumUser = false;
  bool _hasUpgraded = false;
  bool _isSaving = false;

  // Store context for toast usage
  BuildContext? _context;

  // Getters
  int get selectedTabIndex => _selectedTabIndex;
  String get journalContent => _journalContent;
  List<String> get selectedTags => _selectedTags;
  bool get isPremiumUser => _isPremiumUser;
  bool get hasUpgraded => _hasUpgraded;
  bool get isEveningTabSelected => _selectedTabIndex == 2;
  bool get shouldShowUpgradeCard =>
      isEveningTabSelected && !isPremiumUser && !hasUpgraded;
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

  bool contextAlreadySet = false;

  void setContext(BuildContext context) {
    if (contextAlreadySet) return;
    _context = context;
    contextAlreadySet = true;
  }


  // Methods
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

  void handleUpgrade() {
    _hasUpgraded = true;
    notifyListeners();
    print('User clicked upgrade button - simulating premium access');
  }

  // Save journal entry to API with toast notifications
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
      print('🚀 Saving journal entry...');
      print('📝 Content: ${_journalContent.trim()}');
      print('🏷️ Tags: ${_selectedTags}');
      print('📂 Type: ${_getJournalTypeString()}');

      final result = await _journalRepository.createJournalEntry(
        content: _journalContent.trim(),
        type: _getJournalTypeString(),
        tags: List.from(_selectedTags),
      );

      if (result.isSuccess) {
        print('✅ Journal entry saved successfully!');
        print('📝 Entry ID: ${result.data!.id}');
        print('📅 Created: ${result.data!.createdAt}');

        // Show success toast
        if (_context != null) {
          ToastOverlay.showSuccess(
            context: _context!,
            message: 'Ledger created successfully! 🎉',
          );
        }

        // Clear form after successful save
        _clearForm();
        print('🧹 Form cleared for next entry');
      } else {
        print('❌ Failed to save: ${result.error}');

        // Show error toast
        if (_context != null) {
          ToastOverlay.showError(
            context: _context!,
            message: result.error ?? 'Failed to save journal entry',
          );
        }
      }
    } catch (e) {
      print('❌ Error saving: $e');

      // Show error toast
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

  // Helper methods
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

  @override
  void dispose() {
    super.dispose();
  }
}
