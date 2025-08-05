import 'package:stacked/stacked.dart';
import 'models/history_model.dart';

class HistoryViewModel extends BaseViewModel {
  List<HistoryItemModel> _historyItems = [];

  // Getters
  List<HistoryItemModel> get historyItems => _historyItems;

  void onModelReady() {
    _loadHistoryData();
  }

  void _loadHistoryData() async {
    setBusy(true);

    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 500));

    _historyItems = [
      HistoryItemModel(
        id: '1',
        title: 'Morning Reflection + Faith',
        description:
            'Today I choose to be patient with my family and I focus and lay my purpose...',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        type: HistoryType.reflection,
        status: HistoryStatus.completed,
      ),
      HistoryItemModel(
        id: '2',
        title: 'Morning Reflection + Faith',
        description:
            'Grateful for the challenges that shape me into who I\'m becoming.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: HistoryType.reflection,
        status: HistoryStatus.completed,
      ),
      HistoryItemModel(
        id: '3',
        title: 'Evening Reflection',
        description:
            'Grateful for the challenges that shape me into who I\'m becoming.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: HistoryType.reflection,
        status: HistoryStatus.completed,
      ),
      HistoryItemModel(
        id: '4',
        title: 'Morning Reflection + Faith',
        description:
            'Grateful for the challenges that shape me into who I\'m becoming.',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        type: HistoryType.reflection,
        status: HistoryStatus.completed,
      ),
      HistoryItemModel(
        id: '5',
        title: 'Evening Reflection',
        description:
            'Grateful for the challenges that shape me into who I\'m becoming.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: HistoryType.reflection,
        status: HistoryStatus.completed,
      ),
      HistoryItemModel(
        id: '6',
        title: 'Evening Reflection',
        description:
            'Grateful for the challenges that shape me into who I\'m becoming.',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        type: HistoryType.reflection,
        status: HistoryStatus.completed,
      ),
    ];

    setBusy(false);
    notifyListeners();
  }

  void onHistoryItemTap(HistoryItemModel item) {
    print('History item tapped: ${item.title}');
    // TODO: Navigate to detail view or show more info
  }

  String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago, ${_formatTime(timestamp)}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago, ${_formatTime(timestamp)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${_formatTime(timestamp)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago, ${_formatTime(timestamp)}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period';
  }

  void refreshHistory() {
    _loadHistoryData();
  }
}
