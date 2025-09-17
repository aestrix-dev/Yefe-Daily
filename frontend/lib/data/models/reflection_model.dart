// Import the existing VerseModel for compatibility
import '../../presentation/views/home/models/verse_model.dart';

class ReflectionModel {
  final int id;
  final String passage;
  final String reference;
  final String deeperReflection;
  final DateTime? cachedAt;

  const ReflectionModel({
    required this.id,
    required this.passage,
    required this.reference,
    required this.deeperReflection,
    this.cachedAt,
  });

  factory ReflectionModel.fromJson(Map<String, dynamic> json) {
    return ReflectionModel(
      id: json['id'] as int? ?? 0,
      passage: json['passage'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      deeperReflection: json['deeper_reflection'] as String? ?? '',
      cachedAt: json['cached_at'] != null
          ? DateTime.parse(json['cached_at'] as String)
          : null,
    );
  }

  factory ReflectionModel.fromApiResponse(Map<String, dynamic> json) {
    final reflection = json['reflection'] as Map<String, dynamic>? ?? {};

    return ReflectionModel(
      id: reflection['id'] as int? ?? 0,
      passage: reflection['passage'] as String? ?? '',
      reference: reflection['reference'] as String? ?? '',
      deeperReflection: reflection['deeper_reflection'] as String? ?? '',
      cachedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passage': passage,
      'reference': reference,
      'deeper_reflection': deeperReflection,
      'cached_at': cachedAt?.toIso8601String(),
    };
  }

  ReflectionModel copyWith({
    int? id,
    String? passage,
    String? reference,
    String? deeperReflection,
    DateTime? cachedAt,
  }) {
    return ReflectionModel(
      id: id ?? this.id,
      passage: passage ?? this.passage,
      reference: reference ?? this.reference,
      deeperReflection: deeperReflection ?? this.deeperReflection,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  // Convert to VerseModel for compatibility with existing UI
  VerseModel toVerseModel() {
    return VerseModel(
      text: passage,
      reference: reference,
      date: _formatDate(),
      isBookmarked: false,
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[now.month - 1]} ${now.day} • Daily Reflection';
  }

  // Helper method to check if reflection is fresh (less than 24 hours old)
  bool get isFresh {
    if (cachedAt == null) return false;

    final now = DateTime.now();
    final difference = now.difference(cachedAt!);
    return difference.inHours < 24;
  }

  // Helper method to check if reflection is for today
  bool get isForToday {
    if (cachedAt == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reflectionDate = DateTime(
      cachedAt!.year,
      cachedAt!.month,
      cachedAt!.day,
    );

    return today.isAtSameMomentAs(reflectionDate);
  }

  @override
  String toString() {
    return 'ReflectionModel(id: $id, reference: $reference, passage: ${passage.substring(0, 50)}...)';
  }
}
