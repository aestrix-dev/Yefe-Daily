class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final int points;
  final bool isCompleted;
  final DateTime? completedDate;
  final DateTime createdDate;

  const ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.points,
    this.isCompleted = false,
    this.completedDate,
    required this.createdDate,
  });

  // JSON serialization - Convert from API JSON to Dart object
  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: _challengeTypeFromString(json['type'] ?? 'daily'),
      points: json['points'] ?? 0,
      isCompleted: json['is_completed'] ?? json['isCompleted'] ?? false,
      completedDate:
          json['completed_date'] != null || json['completedDate'] != null
          ? DateTime.parse(json['completed_date'] ?? json['completedDate'])
          : null,
      createdDate: DateTime.parse(
        json['created_date'] ??
            json['createdDate'] ??
            json['created_at'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  // Convert Dart object to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': _challengeTypeToString(type),
      'points': points,
      'is_completed': isCompleted,
      'completed_date': completedDate?.toIso8601String(),
      'created_date': createdDate.toIso8601String(),
    };
  }

  ChallengeModel copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeType? type,
    int? points,
    bool? isCompleted,
    DateTime? completedDate,
    DateTime? createdDate,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      points: points ?? this.points,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  // Helper method to convert string to enum
  static ChallengeType _challengeTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'manhood':
        return ChallengeType.manhood;
      case 'daily':
        return ChallengeType.daily;
      case 'spiritual':
        return ChallengeType.spiritual;
      default:
        return ChallengeType.daily; 
    }
  }

  // Helper method to convert enum to string
  static String _challengeTypeToString(ChallengeType type) {
    switch (type) {
      case ChallengeType.manhood:
        return 'manhood';
      case ChallengeType.daily:
        return 'daily';
      case ChallengeType.spiritual:
        return 'spiritual';
    }
  }

  @override
  String toString() {
    return 'ChallengeModel(id: $id, title: $title, type: $type, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChallengeModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum ChallengeType { manhood, daily, spiritual }

// Extension to add display names to enum
extension ChallengeTypeExtension on ChallengeType {
  String get displayName {
    switch (this) {
      case ChallengeType.manhood:
        return 'Manhood';
      case ChallengeType.daily:
        return 'Daily';
      case ChallengeType.spiritual:
        return 'Spiritual';
    }
  }

  String get apiValue {
    switch (this) {
      case ChallengeType.manhood:
        return 'manhood';
      case ChallengeType.daily:
        return 'daily';
      case ChallengeType.spiritual:
        return 'spiritual';
    }
  }
}
