import 'package:stacked/stacked.dart';
import 'models/challenge_model.dart';
import 'models/puzzle_model.dart';

class ChallengesViewModel extends BaseViewModel {
  int _selectedTabIndex = 0;
  PuzzleModel? _dailyPuzzle;
  List<ChallengeModel> _activeChallenges = [];
  List<ChallengeModel> _completedChallenges = [];
  final ProgressStatsModel _progressStats = const ProgressStatsModel(
    currentStreak: 7,
    totalBadges: 5,
    totalChallenges: 12,
    topStreak: 15,
  );

  // Getters
  int get selectedTabIndex => _selectedTabIndex;
  PuzzleModel? get dailyPuzzle => _dailyPuzzle;
  List<ChallengeModel> get activeChallenges => _activeChallenges;
  List<ChallengeModel> get completedChallenges => _completedChallenges;
  ProgressStatsModel get progressStats => _progressStats;
  bool get isActiveTab => _selectedTabIndex == 0;
  bool get isCompletedTab => _selectedTabIndex == 1;

  void onModelReady() {
    _loadData();
  }

  void _loadData() {
    // Load daily puzzle
    _dailyPuzzle = PuzzleModel(
      id: 'daily_1',
      question:
          'Which parable is this: "A man sold all he had to buy one pearl"?',
      options: ['The Talent', 'The pearl of great prize', 'The lost coin'],
      correctAnswerIndex: 1,
    );

    // Load active challenges
    _activeChallenges = [
      ChallengeModel(
        id: 'manhood_1',
        title: "Today's Manhood Challenge",
        description:
            'Call or message a male family member you haven\'t spoken to in a while. Ask how they\'re doing and offer encouragement.',
        type: ChallengeType.manhood,
        points: 5,
        createdDate: DateTime.now(),
      ),
    ];

    // Load completed challenges
    _completedChallenges = [
      ChallengeModel(
        id: 'prayer_1',
        title: 'Morning Prayer',
        description: 'Start your day with 10 minutes of prayer',
        type: ChallengeType.spiritual,
        points: 3,
        isCompleted: true,
        completedDate: DateTime.now().subtract(const Duration(days: 1)),
        createdDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ChallengeModel(
        id: 'scripture_1',
        title: 'Scripture Memorization',
        description: 'Memorize one verse from the Bible',
        type: ChallengeType.spiritual,
        points: 4,
        isCompleted: true,
        completedDate: DateTime.now().subtract(const Duration(days: 2)),
        createdDate: DateTime.now().subtract(const Duration(days: 3)),
      ),
      ChallengeModel(
        id: 'service_1',
        title: 'Acts of Service',
        description: 'Perform a random act of kindness',
        type: ChallengeType.daily,
        points: 3,
        isCompleted: true,
        completedDate: DateTime.now().subtract(const Duration(days: 2)),
        createdDate: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ];

    notifyListeners();
  }

  void selectTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void selectPuzzleAnswer(String answer) {
    if (_dailyPuzzle != null && !_dailyPuzzle!.isAnswered) {
      _dailyPuzzle = _dailyPuzzle!.copyWith(selectedAnswer: answer);
      notifyListeners();
    }
  }

  void submitPuzzleAnswer() {
    if (_dailyPuzzle != null && _dailyPuzzle!.selectedAnswer != null) {
      _dailyPuzzle = _dailyPuzzle!.copyWith(isAnswered: true);

      print('=== PUZZLE SUBMISSION ===');
      print('Question: ${_dailyPuzzle!.question}');
      print('Selected Answer: ${_dailyPuzzle!.selectedAnswer}');
      print(
        'Correct Answer: ${_dailyPuzzle!.options[_dailyPuzzle!.correctAnswerIndex]}',
      );
      print('Is Correct: ${_dailyPuzzle!.isCorrect}');
      print('========================');

      notifyListeners();
    }
  }

  void markChallengeAsComplete(String challengeId) {
    final challengeIndex = _activeChallenges.indexWhere(
      (c) => c.id == challengeId,
    );
    if (challengeIndex != -1) {
      final challenge = _activeChallenges[challengeIndex];
      final completedChallenge = challenge.copyWith(
        isCompleted: true,
        completedDate: DateTime.now(),
      );

      _activeChallenges.removeAt(challengeIndex);
      _completedChallenges.insert(0, completedChallenge);

      print('=== CHALLENGE COMPLETED ===');
      print('Challenge: ${challenge.title}');
      print('Points Earned: ${challenge.points}');
      print('Completed Date: ${DateTime.now()}');
      print('==========================');

      notifyListeners();
    }
  }

  String formatCompletedDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Completed today';
    } else if (difference.inDays == 1) {
      return 'Completed yesterday';
    } else {
      return 'Completed ${date.day}/${date.month}';
    }
  }
}
