class ChallengeStatsModel {
  final String userId;
  final int totalChallenges;
  final int completedCount;
  final int totalPoints;
  final int currentStreak;
  final int longestStreak;
  final int sevenDaysProgress;
  final int numberOfBadges;

  ChallengeStatsModel({
    required this.userId,
    required this.totalChallenges,
    required this.completedCount,
    required this.totalPoints,
    required this.currentStreak,
    required this.longestStreak,
    required this.sevenDaysProgress,
    required this.numberOfBadges,
  });

  factory ChallengeStatsModel.fromJson(Map<String, dynamic> json) {
    return ChallengeStatsModel(
      userId: json['user_id'] ?? '',
      totalChallenges: json['total_challenges'] ?? 0,
      completedCount: json['completed_count'] ?? 0,
      totalPoints: json['total_points'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      sevenDaysProgress: json['sevendays_progress'] ?? 0,
      numberOfBadges: json['NoOfBadges'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_challenges': totalChallenges,
      'completed_count': completedCount,
      'total_points': totalPoints,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'sevendays_progress': sevenDaysProgress,
      'NoOfBadges': numberOfBadges,
    };
  }

  // Helper method to get progress percentage for the 7-day progress bar
  double get progressPercentage {
    if (sevenDaysProgress <= 0) return 0.0;
    if (sevenDaysProgress >= 7) return 1.0;
    return sevenDaysProgress / 7.0;
  }

  // Helper method to get progress percentage as a value between 0-100
  double get progressPercentageDisplay {
    return progressPercentage * 100;
  }

  ChallengeStatsModel copyWith({
    String? userId,
    int? totalChallenges,
    int? completedCount,
    int? totalPoints,
    int? currentStreak,
    int? longestStreak,
    int? sevenDaysProgress,
    int? numberOfBadges,
  }) {
    return ChallengeStatsModel(
      userId: userId ?? this.userId,
      totalChallenges: totalChallenges ?? this.totalChallenges,
      completedCount: completedCount ?? this.completedCount,
      totalPoints: totalPoints ?? this.totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      sevenDaysProgress: sevenDaysProgress ?? this.sevenDaysProgress,
      numberOfBadges: numberOfBadges ?? this.numberOfBadges,
    );
  }

  @override
  String toString() {
    return 'ChallengeStatsModel(userId: $userId, totalChallenges: $totalChallenges, completedCount: $completedCount, totalPoints: $totalPoints, currentStreak: $currentStreak, longestStreak: $longestStreak, sevenDaysProgress: $sevenDaysProgress, numberOfBadges: $numberOfBadges)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChallengeStatsModel &&
        other.userId == userId &&
        other.totalChallenges == totalChallenges &&
        other.completedCount == completedCount &&
        other.totalPoints == totalPoints &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        other.sevenDaysProgress == sevenDaysProgress &&
        other.numberOfBadges == numberOfBadges;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        totalChallenges.hashCode ^
        completedCount.hashCode ^
        totalPoints.hashCode ^
        currentStreak.hashCode ^
        longestStreak.hashCode ^
        sevenDaysProgress.hashCode ^
        numberOfBadges.hashCode;
  }
}
