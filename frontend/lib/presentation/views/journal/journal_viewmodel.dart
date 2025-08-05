import 'package:stacked/stacked.dart';
import 'models/journal_entry_model.dart';

class JournalViewModel extends BaseViewModel {
  int _selectedTabIndex = 0;
  String _journalContent = '';
  final List<String> _selectedTags = [];
  final bool _isPremiumUser = false;
  bool _hasUpgraded = false; 

  // Getters
  int get selectedTabIndex => _selectedTabIndex;
  String get journalContent => _journalContent;
  List<String> get selectedTags => _selectedTags;
  bool get isPremiumUser => _isPremiumUser;
  bool get hasUpgraded => _hasUpgraded;
  bool get isEveningTabSelected => _selectedTabIndex == 2;
  bool get shouldShowUpgradeCard =>
      isEveningTabSelected && !isPremiumUser && !hasUpgraded;

  final List<String> availableTags = [
    'Faith',
    'Family',
    'Focus',
    'Rest',
    'Growth',
    'Gratitude',
  ];

  final List<String> tabTitles = ['Morning', 'Evening', 'Wisdom Note'];

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
    // Simulate upgrade process
    _hasUpgraded = true;
    notifyListeners();
    print('User clicked upgrade button - simulating premium access');
  }

  void saveJournalEntry() {
    if (_journalContent.trim().isEmpty) {
      print('Cannot save empty journal entry');
      return;
    }

    final entry = JournalEntryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: _journalContent,
      tags: List.from(_selectedTags),
      type: _getJournalType(),
      createdAt: DateTime.now(),
    );

    // Log to console
    print('=== JOURNAL ENTRY SAVED ===');
    print(entry.toString());
    print('========================');

    // Clear form after saving
    _clearForm();
  }

  JournalType _getJournalType() {
    switch (_selectedTabIndex) {
      case 0:
        return JournalType.morning;
      case 1:
        return JournalType.evening;
      case 2:
        return JournalType.wisdomNote;
      default:
        return JournalType.morning;
    }
  }

  void _clearForm() {
    _journalContent = '';
    _selectedTags.clear();
    notifyListeners();
  }
}
