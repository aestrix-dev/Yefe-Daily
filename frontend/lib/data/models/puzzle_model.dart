class PuzzleModel {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? selectedAnswer;
  final bool isAnswered;

  const PuzzleModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.selectedAnswer,
    this.isAnswered = false,
  });

  // JSON serialization - Convert from API JSON to Dart object
  factory PuzzleModel.fromJson(Map<String, dynamic> json) {
    return PuzzleModel(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswerIndex:
          json['correct_answer_index'] ??
          json['correctAnswerIndex'] ??
          json['correct_answer'] ??
          0,
      selectedAnswer: json['selected_answer'] ?? json['selectedAnswer'],
      isAnswered: json['is_answered'] ?? json['isAnswered'] ?? false,
    );
  }

  // Convert Dart object to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correct_answer_index': correctAnswerIndex,
      'selected_answer': selectedAnswer,
      'is_answered': isAnswered,
    };
  }

  PuzzleModel copyWith({
    String? id,
    String? question,
    List<String>? options,
    int? correctAnswerIndex,
    String? selectedAnswer,
    bool? isAnswered,
  }) {
    return PuzzleModel(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      isAnswered: isAnswered ?? this.isAnswered,
    );
  }

  bool get isCorrect => selectedAnswer == options[correctAnswerIndex];

  // Helper getter to get correct answer text
  String get correctAnswer => options[correctAnswerIndex];

  // Helper method to check if a specific option is correct
  bool isOptionCorrect(String option) => option == correctAnswer;

  @override
  String toString() {
    return 'PuzzleModel(id: $id, question: $question, isAnswered: $isAnswered, isCorrect: $isCorrect)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PuzzleModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class ProgressStatsModel {
  final int currentStreak;
  final int totalBadges;
  final int totalChallenges;
  final int topStreak;

  const ProgressStatsModel({
    required this.currentStreak,
    required this.totalBadges,
    required this.totalChallenges,
    required this.topStreak,
  });

  // JSON serialization - Convert from API JSON to Dart object
  factory ProgressStatsModel.fromJson(Map<String, dynamic> json) {
    return ProgressStatsModel(
      currentStreak: json['current_streak'] ?? json['currentStreak'] ?? 0,
      totalBadges: json['total_badges'] ?? json['totalBadges'] ?? 0,
      totalChallenges: json['total_challenges'] ?? json['totalChallenges'] ?? 0,
      topStreak:
          json['top_streak'] ?? json['topStreak'] ?? json['best_streak'] ?? 0,
    );
  }

  // Convert Dart object to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'current_streak': currentStreak,
      'total_badges': totalBadges,
      'total_challenges': totalChallenges,
      'top_streak': topStreak,
    };
  }

  // Copy with method for updates
  ProgressStatsModel copyWith({
    int? currentStreak,
    int? totalBadges,
    int? totalChallenges,
    int? topStreak,
  }) {
    return ProgressStatsModel(
      currentStreak: currentStreak ?? this.currentStreak,
      totalBadges: totalBadges ?? this.totalBadges,
      totalChallenges: totalChallenges ?? this.totalChallenges,
      topStreak: topStreak ?? this.topStreak,
    );
  }

  // Helper methods for display
  String get streakText =>
      currentStreak == 1 ? '$currentStreak day' : '$currentStreak days';
  String get badgesText =>
      totalBadges == 1 ? '$totalBadges badge' : '$totalBadges badges';
  String get challengesText => totalChallenges == 1
      ? '$totalChallenges challenge'
      : '$totalChallenges challenges';

  // Calculate progress percentage (assuming a target)
  double getStreakProgress({int target = 30}) {
    return (currentStreak / target).clamp(0.0, 1.0);
  }

  // Check if current streak is a personal best
  bool get isPersonalBest => currentStreak >= topStreak;

  @override
  String toString() {
    return 'ProgressStatsModel(currentStreak: $currentStreak, totalBadges: $totalBadges, totalChallenges: $totalChallenges, topStreak: $topStreak)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgressStatsModel &&
        other.currentStreak == currentStreak &&
        other.totalBadges == totalBadges &&
        other.totalChallenges == totalChallenges &&
        other.topStreak == topStreak;
  }

  @override
  int get hashCode =>
      Object.hash(currentStreak, totalBadges, totalChallenges, topStreak);
}
