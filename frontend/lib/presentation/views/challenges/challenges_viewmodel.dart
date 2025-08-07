
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:yefa/core/utils/api_result.dart';
import '../../../data/repositories/challenge_repository.dart';
import '../../../data/models/challenge_model.dart';
import '../../../data/models/puzzle_model.dart';
import '../../../data/services/puzzle_timer_service.dart';
import '../../shared/widgets/toast_overlay.dart';
import '../../../app/app_setup.dart';


class ChallengesViewModel extends BaseViewModel {
  final ChallengeRepository _challengeRepository =
      locator<ChallengeRepository>();
  final PuzzleTimerService _timerService = PuzzleTimerService();

  // Existing properties
  int _selectedTabIndex = 0;
  List<ChallengeModel> _activeChallenges = [];
  List<ChallengeModel> _completedChallenges = [];
  final ProgressStatsModel _progressStats = const ProgressStatsModel(
    currentStreak: 7,
    totalBadges: 5,
    totalChallenges: 12,
    topStreak: 15,
  );

  // New puzzle properties with timer
  PuzzleState _puzzleState = const PuzzleState();
  bool _isLoadingPuzzle = false;
  bool _isSubmittingAnswer = false;
  String? _errorMessage;

  // Store context for toast usage
  BuildContext? _context;

  BuildContext? get context => _context;


  // Existing getters
  int get selectedTabIndex => _selectedTabIndex;
  List<ChallengeModel> get activeChallenges => _activeChallenges;
  List<ChallengeModel> get completedChallenges => _completedChallenges;
  ProgressStatsModel get progressStats => _progressStats;
  bool get isActiveTab => _selectedTabIndex == 0;
  bool get isCompletedTab => _selectedTabIndex == 1;

  // New puzzle getters
  PuzzleState get puzzleState => _puzzleState;
  bool get isLoadingPuzzle => _isLoadingPuzzle;
  bool get isSubmittingAnswer => _isSubmittingAnswer;
  String? get errorMessage => _errorMessage;

  // Convenience getters for puzzle
  PuzzleModel? get dailyPuzzle => _puzzleState.puzzle;
  int? get selectedAnswer => _puzzleState.selectedAnswer;
  bool get hasSubmitted => _puzzleState.hasSubmitted;
  bool get isOnCooldown => _puzzleState.isOnCooldown;
  bool get canSubmit => _puzzleState.canSubmit && !_isSubmittingAnswer;
  bool get canSelectAnswer => _puzzleState.canSelectAnswer;
  String get timeUntilNextPuzzle => _puzzleState.timeUntilNextPuzzle;
  PuzzleSubmissionData? get submissionResult => _puzzleState.submissionResult;

  // Legacy compatibility for existing UI
  bool get isPuzzleCompleted => _puzzleState.hasSubmitted;

  @override
  void dispose() {
    _timerService.dispose();
    super.dispose();
  }

  // Set context when view is ready
  void setContext(BuildContext context) {
    _context = context;
  }

  void onModelReady() {
    _setupTimerCallbacks();
    _timerService.initialize();
    _loadData();

    // Load puzzle if not on cooldown
    if (_timerService.canAttemptPuzzle()) {
      getDailyPuzzle();
    } else {
      // Update state to show cooldown
      _updatePuzzleState(
        _puzzleState.copyWith(
          isOnCooldown: true,
          remainingCooldown: _timerService.remainingCooldown,
        ),
      );
    }
  }

  // Setup timer service callbacks
  void _setupTimerCallbacks() {
    _timerService.onTimerExpired = () {
      print('⏰ Timer expired, fetching new puzzle...');
      _updatePuzzleState(
        _puzzleState.copyWith(
          puzzle: null,
          selectedAnswer: null,
          hasSubmitted: false,
          submissionResult: null,
          submissionTime: null,
          isOnCooldown: false,
          remainingCooldown: null,
        ),
      );
      getDailyPuzzle();
    };

    _timerService.onCountdownUpdate = (remaining) {
      _updatePuzzleState(_puzzleState.copyWith(remainingCooldown: remaining));
    };
  }

  void _loadData() {
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

  // Updated puzzle methods with API integration
  void selectPuzzleAnswer(int answerIndex) {
    if (!canSelectAnswer) return;

    _updatePuzzleState(_puzzleState.copyWith(selectedAnswer: answerIndex));
    _clearError();
  }

  // Get daily puzzle from API
  Future<void> getDailyPuzzle() async {
    if (!_timerService.canAttemptPuzzle()) {
      print('🚫 Cannot attempt puzzle - on cooldown');
      return;
    }

    _setLoadingPuzzle(true);
    _clearError();

    try {
      print('🧩 Loading daily puzzle...');

      final result = await _challengeRepository.getDailyPuzzle();

      if (result.isSuccess) {
        final puzzle = result.data!;

        // Check if this is a new puzzle
        final isNewPuzzle = _timerService.isNewPuzzle(puzzle.id);

        _updatePuzzleState(
          _puzzleState.copyWith(
            puzzle: puzzle,
            selectedAnswer: null,
            hasSubmitted: false,
            submissionResult: null,
            isOnCooldown: false,
            remainingCooldown: null,
          ),
        );

        print('✅ Daily puzzle loaded successfully!');
        print(
          '🧩 Puzzle: ${puzzle.title} ${isNewPuzzle ? "(NEW)" : "(EXISTING)"}',
        );
      } else {
        print('❌ Failed to load puzzle: ${result.error}');
        _setError(result.error ?? 'Failed to load daily puzzle');

        if (_context != null) {
          ToastOverlay.showError(
            context: _context!,
            message: result.error ?? 'Failed to load daily puzzle',
          );
        }
      }
    } catch (e) {
      print('❌ Error loading puzzle: $e');
      _setError('An unexpected error occurred while loading puzzle');

      if (_context != null) {
        ToastOverlay.showError(
          context: _context!,
          message: 'An unexpected error occurred while loading puzzle',
        );
      }
    } finally {
      _setLoadingPuzzle(false);
    }
  }

  // Submit puzzle answer to API
  Future<void> submitPuzzleAnswer() async {
    if (!canSubmit || _puzzleState.puzzle == null) {
      return;
    }

    _setSubmittingAnswer(true);
    _clearError();

    try {
      print('📝 Submitting puzzle answer...');
      print('🧩 Puzzle ID: ${_puzzleState.puzzle!.id}');
      print('✅ Selected Answer: ${_puzzleState.selectedAnswer}');

      final result = await _challengeRepository.submitPuzzleAnswer(
        puzzleId: _puzzleState.puzzle!.id,
        selectedAnswer: _puzzleState.selectedAnswer!,
      );

      if (result.isSuccess) {
        final submissionData = result.data!.data!;
        final submissionTime = DateTime.now();

        // Update puzzle state with submission result
        _updatePuzzleState(
          _puzzleState.copyWith(
            hasSubmitted: true,
            submissionResult: submissionData,
            submissionTime: submissionTime,
            isOnCooldown: true,
          ),
        );

        // Record submission in timer service (starts 24hr countdown)
        await _timerService.recordSubmission(_puzzleState.puzzle!.id);

        print('✅ Puzzle answer submitted successfully!');
        print('🎯 Correct: ${submissionData.isCorrect}');
        print('🏆 Points Earned: ${submissionData.pointsEarned}');

        // Show success/failure toast based on correctness
        if (_context != null) {
          if (submissionData.isCorrect) {
            ToastOverlay.showSuccess(
              context: _context!,
              message:
                  '🎉 Correct! You earned ${submissionData.pointsEarned} points!',
            );
          } else {
            ToastOverlay.showError(
              context: _context!,
              message: '❌ Incorrect answer. Check the explanation below!',
            );
          }
        }
      } else {
        print('❌ Failed to submit answer: ${result.error}');
        _setError(result.error ?? 'Failed to submit puzzle answer');

        if (_context != null) {
          ToastOverlay.showError(
            context: _context!,
            message: result.error ?? 'Failed to submit puzzle answer',
          );
        }
      }
    } catch (e) {
      print('❌ Error submitting answer: $e');
      _setError('An unexpected error occurred while submitting answer');

      if (_context != null) {
        ToastOverlay.showError(
          context: _context!,
          message: 'An unexpected error occurred while submitting answer',
        );
      }
    } finally {
      _setSubmittingAnswer(false);
    }
  }

  void markChallengeAsComplete(String challengeId) {
    // Only allow marking as complete if puzzle is completed
    if (!isPuzzleCompleted) {
      if (_context != null) {
        ToastOverlay.showWarning(
          context: _context!,
          message: 'Complete the daily puzzle first!',
        );
      }
      print('Complete the daily puzzle first!');
      return;
    }

    final challengeIndex = _activeChallenges.indexWhere(
      (c) => c.id == challengeId,
    );
    if (challengeIndex != -1) {
      // Update the challenge to completed state but keep it in active list
      final challenge = _activeChallenges[challengeIndex];
      final completedChallenge = challenge.copyWith(
        isCompleted: true,
        completedDate: DateTime.now(),
      );

      // Replace the challenge in the active list with completed version
      _activeChallenges[challengeIndex] = completedChallenge;

      print('=== CHALLENGE COMPLETED ===');
      print('Challenge: ${challenge.title}');
      print('Points Earned: ${challenge.points}');
      print('Completed Date: ${DateTime.now()}');
      print('==========================');

      // Show success toast
      if (_context != null) {
        ToastOverlay.showSuccess(
          context: _context!,
          message: '🎉 Challenge completed! +${challenge.points} points!',
        );
      }

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

  // Helper method to update puzzle state
  void _updatePuzzleState(PuzzleState newState) {
    _puzzleState = newState;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Reset puzzle (for testing purposes)
  Future<void> resetPuzzle() async {
    await _timerService.reset();
    _updatePuzzleState(const PuzzleState());
    _clearError();
    getDailyPuzzle();
  }

  // Helper methods
  void _setLoadingPuzzle(bool value) {
    _isLoadingPuzzle = value;
    notifyListeners();
  }

  void _setSubmittingAnswer(bool value) {
    _isSubmittingAnswer = value;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
