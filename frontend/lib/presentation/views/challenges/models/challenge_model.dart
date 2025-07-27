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

  ChallengeModel copyWith({bool? isCompleted, DateTime? completedDate}) {
    return ChallengeModel(
      id: id,
      title: title,
      description: description,
      type: type,
      points: points,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      createdDate: createdDate,
    );
  }
}

enum ChallengeType { manhood, daily, spiritual }
