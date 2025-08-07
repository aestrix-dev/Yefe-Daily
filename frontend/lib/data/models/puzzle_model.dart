class PuzzleModel {
  final String id;
  final String title;
  final String question;
  final Map<String, String> options;
  final int? correctAnswer;
  final String? difficulty;
  final String? category;
  final int? points;
  final String? explanation;

  const PuzzleModel({
    required this.id,
    required this.title,
    required this.question,
    required this.options,
    this.correctAnswer,
    this.difficulty,
    this.category,
    this.points,
    this.explanation,
  });

  factory PuzzleModel.fromJson(Map<String, dynamic> json) {
    return PuzzleModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      question: json['question'] ?? '',
      options: Map<String, String>.from(json['options'] ?? {}),
      correctAnswer: json['correctAnswer'],
      difficulty: json['difficulty'],
      category: json['category'],
      points: json['points'],
      explanation: json['explanation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'difficulty': difficulty,
      'category': category,
      'points': points,
      'explanation': explanation,
    };
  }

  @override
  String toString() {
    return 'PuzzleModel(id: $id, title: $title, question: $question, difficulty: $difficulty, points: $points)';
  }
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
class PuzzleResponse {
  final bool success;
  final String message;
  final PuzzleData data;
  final DateTime timestamp;

  const PuzzleResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  factory PuzzleResponse.fromJson(Map<String, dynamic> json) {
    return PuzzleResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: PuzzleData.fromJson(json['data'] ?? {}),
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class PuzzleData {
  final PuzzleModel data;

  const PuzzleData({required this.data});

  factory PuzzleData.fromJson(Map<String, dynamic> json) {
    return PuzzleData(data: PuzzleModel.fromJson(json['data'] ?? {}));
  }
}

class SubmitPuzzleRequest {
  final String puzzleId;
  final int selectedAnswer;

  const SubmitPuzzleRequest({
    required this.puzzleId,
    required this.selectedAnswer,
  });

  Map<String, dynamic> toJson() {
    return {'puzzle_id': puzzleId, 'selectedAnswer': selectedAnswer};
  }
}

class PuzzleSubmissionResponse {
  final bool success;
  final String message;
  final PuzzleSubmissionData? data;
  final DateTime timestamp;

  const PuzzleSubmissionResponse({
    required this.success,
    required this.message,
    this.data,
    required this.timestamp,
  });

  factory PuzzleSubmissionResponse.fromJson(Map<String, dynamic> json) {
    return PuzzleSubmissionResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? PuzzleSubmissionData.fromJson(json['data'])
          : null,
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class PuzzleSubmissionData {
  final bool isCorrect;
  final int correctAnswer;
  final String explanation;
  final int? pointsEarned;
  final bool? isFirstAttempt;

  const PuzzleSubmissionData({
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
    this.pointsEarned,
    this.isFirstAttempt,
  });

  factory PuzzleSubmissionData.fromJson(Map<String, dynamic> json) {
    return PuzzleSubmissionData(
      isCorrect: json['isCorrect'] ?? false,
      correctAnswer: json['correctAnswer'] ?? 0,
      explanation: json['explanation'] ?? '',
      pointsEarned: json['pointsEarned'] ?? json['points_earned'] ?? 0,
      isFirstAttempt:
          json['isFirstAttempt'] ?? json['is_first_attempt'] ?? true,
    );
  }
}

class PuzzleState {
  final PuzzleModel? puzzle;
  final int? selectedAnswer;
  final bool hasSubmitted;
  final PuzzleSubmissionData? submissionResult;
  final DateTime? submissionTime;
  final bool isOnCooldown;
  final Duration? remainingCooldown;

  const PuzzleState({
    this.puzzle,
    this.selectedAnswer,
    this.hasSubmitted = false,
    this.submissionResult,
    this.submissionTime,
    this.isOnCooldown = false,
    this.remainingCooldown,
  });

  PuzzleState copyWith({
    PuzzleModel? puzzle,
    int? selectedAnswer,
    bool? hasSubmitted,
    PuzzleSubmissionData? submissionResult,
    DateTime? submissionTime,
    bool? isOnCooldown,
    Duration? remainingCooldown,
  }) {
    return PuzzleState(
      puzzle: puzzle ?? this.puzzle,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      hasSubmitted: hasSubmitted ?? this.hasSubmitted,
      submissionResult: submissionResult ?? this.submissionResult,
      submissionTime: submissionTime ?? this.submissionTime,
      isOnCooldown: isOnCooldown ?? this.isOnCooldown,
      remainingCooldown: remainingCooldown ?? this.remainingCooldown,
    );
  }

  bool get canSubmit =>
      selectedAnswer != null && !hasSubmitted && !isOnCooldown;
  bool get canSelectAnswer => !hasSubmitted && !isOnCooldown;

  String get timeUntilNextPuzzle {
    if (remainingCooldown == null) return '';

    final hours = remainingCooldown!.inHours;
    final minutes = remainingCooldown!.inMinutes % 60;
    final seconds = remainingCooldown!.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
