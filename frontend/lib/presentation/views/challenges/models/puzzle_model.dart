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

  PuzzleModel copyWith({String? selectedAnswer, bool? isAnswered}) {
    return PuzzleModel(
      id: id,
      question: question,
      options: options,
      correctAnswerIndex: correctAnswerIndex,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      isAnswered: isAnswered ?? this.isAnswered,
    );
  }

  bool get isCorrect => selectedAnswer == options[correctAnswerIndex];
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
}
