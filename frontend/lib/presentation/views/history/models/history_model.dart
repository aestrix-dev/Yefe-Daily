enum HistoryType { reflection, prayer, challenge, audio, devotional }

enum HistoryStatus { completed, inProgress, skipped }

class HistoryItemModel {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final HistoryType type;
  final HistoryStatus status;

  const HistoryItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    required this.status,
  });

  HistoryItemModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? timestamp,
    HistoryType? type,
    HistoryStatus? status,
  }) {
    return HistoryItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      status: status ?? this.status,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case HistoryType.reflection:
        return 'Reflection';
      case HistoryType.prayer:
        return 'Prayer';
      case HistoryType.challenge:
        return 'Challenge';
      case HistoryType.audio:
        return 'Audio';
      case HistoryType.devotional:
        return 'Devotional';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case HistoryStatus.completed:
        return 'Completed';
      case HistoryStatus.inProgress:
        return 'In Progress';
      case HistoryStatus.skipped:
        return 'Skipped';
    }
  }
}
