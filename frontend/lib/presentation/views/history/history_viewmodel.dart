import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import '../../../data/models/journal_model.dart';
import '../../../data/repositories/journal_repository.dart';
import '../../../core/utils/api_result.dart';
import '../../../app/app_setup.dart';
import '../../shared/widgets/toast_overlay.dart';

class HistoryViewModel extends BaseViewModel {
  final JournalRepository _journalRepository = locator<JournalRepository>();

  List<JournalModel> _entries = [];
  String? _errorMessage;
  BuildContext? _context;

  // Getters
  List<JournalModel> get historyItems => _entries;
  String? get errorMessage => _errorMessage;
  @override
  bool get hasError => _errorMessage != null;

  void setContext(BuildContext context) {
    if (_context != null) return;
    _context = context;
  }

  void onModelReady() {
    fetchJournalEntries();
  }

  Future<void> fetchJournalEntries() async {
    print('🔄 Fetching journal entries...');
    setBusy(true);
    _errorMessage = null;

    final result = await _journalRepository.getJournalEntries();

    if (result.isSuccess) {
      _entries = result.data ?? [];

      // Debug Logging
      print('🟢 API Call Success');
      print('📊 Entries Count: ${_entries.length}');
      for (var entry in _entries) {
        print('➡️ Entry ID: ${entry.id}');
        print('    Type: ${entry.type}');
        print('    Content: ${entry.content}');
        print('    Tags: ${entry.tags}');
        print('    Created At: ${entry.createdAt}');
      }

      if (_entries.isEmpty) {
        print('⚠️ Entries list is empty!');
      } else {
        print('✅ Entries loaded into ViewModel');
      }
    } else {
      _errorMessage = result.error ?? 'Failed to fetch entries';
      print('❌ API Call Failed: $_errorMessage');
      _showErrorToast(_errorMessage!);
    }

    setBusy(false);
    notifyListeners();
  }

  Future<void> onDeleteEntry(String entryId) async {
    final confirm = await _showDeleteConfirmation();
    if (!confirm) return;

    setBusy(true);
    final result = await _journalRepository.deleteJournalEntry(entryId);

    if (result.isSuccess) {
      _entries.removeWhere((entry) => entry.id == entryId);
      _showSuccessToast('Entry deleted successfully');
    } else {
      _showErrorToast(result.error ?? 'Failed to delete entry');
    }

    setBusy(false);
    notifyListeners();
  }

  Future<bool> _showDeleteConfirmation() async {
    if (_context == null) return false;

    return await showDialog<bool>(
          context: _context!,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete Entry?'),
              content: const Text(
                'Are you sure you want to delete this entry?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showSuccessToast(String message) {
    if (_context != null) {
      ToastOverlay.showSuccess(context: _context!, message: message);
    }
  }

  void _showErrorToast(String message) {
    if (_context != null) {
      ToastOverlay.showError(context: _context!, message: message);
    }
  }

  Future<void> refreshHistory() async {
    await fetchJournalEntries();
  }
}
