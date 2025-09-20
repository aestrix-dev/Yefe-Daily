import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:yefa/core/utils/api_result.dart';
import '../../../data/repositories/challenge_repository.dart';
import '../../../data/models/challenge_model.dart';
import '../../../data/models/challenge_stats_model.dart';
import '../../../data/models/puzzle_model.dart';
import '../../../data/services/puzzle_timer_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/cache/home_cache.dart';
import '../../shared/widgets/toast_overlay.dart';
import '../../../app/app_setup.dart';

class ChallengesViewModel extends BaseViewModel {
  final ChallengeRepository _challengeRepository =
      locator<ChallengeRepository>();
  final PuzzleTimerService _timerService = PuzzleTimerService();
  final StorageService _storageService = locator<StorageService>();

  // Existing properties
  int _selectedTabIndex = 0;
  List<ChallengeModel> _activeChallenges = [];
  List<ChallengeModel> _completedChallenges = [];
  bool _hasCachedSubmission = false;
  ChallengeStatsModel _progressStats = ChallengeStatsModel(
    userId: '',
    totalChallenges: 0,
    completedCount: 0,
    totalPoints: 0,
    currentStreak: 0,
    longestStreak: 0,
    sevenDaysProgress: 0,
    numberOfBadges: 0,
  );

  // New puzzle properties with timer
  PuzzleState _puzzleState = const PuzzleState();
  bool _isLoadingPuzzle = false;
  bool _isSubmittingAnswer = false;
  String? _errorMessage;

  // Store context for toast usage
  BuildContext? _context;

  bool contextAlreadySet = false;

  void setContext(BuildContext context) {
    if (contextAlreadySet) return;
    _context = context;
    contextAlreadySet = true;
  }

  // Existing getters
  int get selectedTabIndex => _selectedTabIndex;
  List<ChallengeModel> get activeChallenges => _activeChallenges;
  List<ChallengeModel> get completedChallenges => _completedChallenges;
  ChallengeStatsModel get progressStats => _progressStats;
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
  bool get isPuzzleCompleted =>
      _puzzleState.hasSubmitted || _hasCachedSubmission;

  // Check if puzzle has been completed today (including cached status)
  Future<bool> get isPuzzleCompletedToday async {
    return _puzzleState.hasSubmitted ||
        await _storageService.getPuzzleSubmissionStatus();
  }

  @override
  void dispose() {
    _timerService.dispose();
    super.dispose();
  }

  void onModelReady() {
    _setupTimerCallbacks();
    _timerService.initialize();
    initialize();
  }

  Future<void> initialize() async {
    setBusy(true);

    try {
      // Load cached data first for immediate display
      await _loadCachedData();
      notifyListeners();

      // Then try to load fresh data if online
      await _loadFreshDataIfOnline();
    } catch (e) {

    } finally {
      setBusy(false);
    }
  }

  Future<void> _loadCachedData() async {
    try {
      // Load cached challenge (same as home screen)
      final cachedChallenge = await _storageService.getCachedChallenge();
      if (cachedChallenge != null) {
        _activeChallenges = [cachedChallenge];
      }

      // Load cached completed challenges
      final cachedCompletedChallenges = await _storageService
          .getCachedCompletedChallengesList();
      if (cachedCompletedChallenges != null) {
        _completedChallenges = cachedCompletedChallenges;
      }

      // Check if there's a cached puzzle submission for today
      _hasCachedSubmission = await _storageService.getPuzzleSubmissionStatus();

      // Load cached puzzle
      final cachedPuzzle = await _storageService.getCachedPuzzle();
      if (cachedPuzzle != null) {
        // Load cached puzzle state
        final cachedStateData = await _storageService.getCachedPuzzleState();
        if (cachedStateData != null) {
          final submissionResult = cachedStateData['submissionResult'] != null
              ? PuzzleSubmissionData.fromJson(
                  cachedStateData['submissionResult'],
                )
              : null;

          final submissionTime = cachedStateData['submissionTime'] != null
              ? DateTime.parse(cachedStateData['submissionTime'])
              : null;

          _updatePuzzleState(
            PuzzleState(
              puzzle: cachedPuzzle,
              selectedAnswer: cachedStateData['selectedAnswer'],
              hasSubmitted: cachedStateData['hasSubmitted'] ?? false,
              submissionResult: submissionResult,
              submissionTime: submissionTime,
              isOnCooldown: cachedStateData['isOnCooldown'] ?? false,
              remainingCooldown: _timerService.remainingCooldown,
            ),
          );
        } else {
          // Just load the puzzle without state
          _updatePuzzleState(_puzzleState.copyWith(puzzle: cachedPuzzle));
        }
      }
    } catch (e) {

    }
  }

  Future<void> _loadFreshDataIfOnline() async {
    try {
      // Load completed challenges first to check if today's challenge is already done
      await _loadCompletedChallenges();

      // Load challenge statistics
      await _loadChallengeStats();

      // Check if we should load a new challenge
      final shouldLoadNewChallenge = _shouldLoadNewChallenge();

      if (shouldLoadNewChallenge) {
        // Only load today's challenge if conditions are met
        await _loadTodaysChallenge();
      } else {

      }

      // Load puzzle if not on cooldown
      if (_timerService.canAttemptPuzzle()) {
        await getDailyPuzzle();
      } else {
        // Update state to show cooldown
        _updatePuzzleState(
          _puzzleState.copyWith(
            isOnCooldown: true,
            remainingCooldown: _timerService.remainingCooldown,
          ),
        );
      }
    } catch (e) {

    }
  }

  Future<void> _loadTodaysChallenge() async {
    try {
      final result = await _challengeRepository.getTodayChallenge();

      if (result.isSuccess && result.data!.isNotEmpty) {
        final challenge = result.data!.first;
        _activeChallenges = [challenge];
        await _storageService.cacheChallenge(challenge);
        notifyListeners();
      }
    } catch (e) {

    }
  }

  Future<void> _loadCompletedChallenges() async {
    try {
      final result = await _challengeRepository.getCompletedChallenges();

      if (result.isSuccess) {
        _completedChallenges = result.data ?? [];
        // Cache completed challenges for offline use
        await _storageService.cacheCompletedChallengesList(
          _completedChallenges,
        );
        notifyListeners();
      }
    } catch (e) {

    }
  }

  Future<void> _loadChallengeStats() async {
    try {
      final result = await _challengeRepository.getChallengeStats();

      if (result.isSuccess) {
        _progressStats = result.data!;
        notifyListeners();
      }
    } catch (e) {

    }
  }

  /// Determines if we should load a new challenge based on:
  /// 1. No challenge completed today
  /// 2. 24-hour puzzle countdown has expired (can attempt new puzzle)
  /// 3. If challenge completed today but puzzle countdown expired, show cached challenge
  bool _shouldLoadNewChallenge() {
    // Check if there's a challenge completed today
    final today = DateTime.now();
    final hasCompletedToday = _completedChallenges.any((challenge) {
      if (challenge.completedDate == null) return false;
      final completedDate = challenge.completedDate!;
      return completedDate.year == today.year &&
          completedDate.month == today.month &&
          completedDate.day == today.day;
    });

    // Check if 24-hour countdown has expired (can attempt new puzzle)
    final canAttemptPuzzle = _timerService.canAttemptPuzzle();

    // If challenge completed today AND puzzle countdown is still active, use cached challenge
    if (hasCompletedToday && !canAttemptPuzzle) {

      return false;
    }
    
    // If challenge completed today but countdown expired, can load new challenge
    if (hasCompletedToday && canAttemptPuzzle) {

      return true;
    }

    // If no challenge completed today but countdown active, use cached challenge
    if (!hasCompletedToday && !canAttemptPuzzle) {

      return false;
    }

    // No challenge completed today and countdown expired - load new challenge

    return true;
  }

  // Setup timer service callbacks
  void _setupTimerCallbacks() {
    _timerService.onTimerExpired = () {

      // Clear puzzle state for new puzzle
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

      // Clear cached submission status since new day started
      _hasCachedSubmission = false;
      
      // Clear any challenges being marked to reset UI state
      _markingAsComplete.clear();

      // Fetch new puzzle and challenge when countdown expires
      _refreshAfterCountdownExpired();
    };

    _timerService.onCountdownUpdate = (remaining) {
      _updatePuzzleState(_puzzleState.copyWith(remainingCooldown: remaining));
    };
  }

  // Handle refresh after countdown expires - this allows new challenges even if previous day was completed
  Future<void> _refreshAfterCountdownExpired() async {
    try {

      // Get new puzzle
      await getDailyPuzzle();
      
      // Re-evaluate completed challenges to check for today
      await _loadCompletedChallenges();
      
      // Now load today's challenge (should be available since countdown expired)
      await _loadTodaysChallenge();

    } catch (e) {

    }
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

      return;
    }

    _setLoadingPuzzle(true);
    _clearError();

    try {

      final result = await _challengeRepository.getDailyPuzzle();

      if (result.isSuccess) {
        final puzzle = result.data!;

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

      } else {

        _setError(result.error ?? 'Failed to load daily puzzle');

        if (_context != null) {
          ToastOverlay.showError(
            context: _context!,
            message: result.error ?? 'Failed to load daily puzzle',
          );
        }
      }
    } catch (e) {

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

      // Backend expects 1-based answer numbers (1, 2, 3) directly

      final result = await _challengeRepository.submitPuzzleAnswer(
        puzzleId: _puzzleState.puzzle!.id,
        selectedAnswer: _puzzleState.selectedAnswer!,
      );

      if (result.isSuccess) {
        final submissionData = result.data!.data!;
        final submissionTime = DateTime.now();

        // Backend returns 1-based answer numbers directly, no conversion needed

        // Update puzzle state with submission result
        _updatePuzzleState(
          _puzzleState.copyWith(
            hasSubmitted: true,
            submissionResult: submissionData, // Use data directly
            submissionTime: submissionTime,
            isOnCooldown: true,
          ),
        );

        // Cache the updated puzzle state
        await _storageService.cachePuzzleState(_puzzleState);

        // Update the cached submission flag
        _hasCachedSubmission = true;

        // Record submission in timer service (starts 24hr countdown)
        await _timerService.recordSubmission(_puzzleState.puzzle!.id);

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

        _setError(result.error ?? 'Failed to submit puzzle answer');

        if (_context != null) {
          ToastOverlay.showError(
            context: _context!,
            message: result.error ?? 'Failed to submit puzzle answer',
          );
        }
      }
    } catch (e) {

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

  // Track which challenges are currently being marked as complete to prevent double-clicks
  final Set<String> _markingAsComplete = {};
  
  Future<void> markChallengeAsComplete(String challengeId) async {
    // Prevent multiple clicks - check if already processing this challenge
    if (_markingAsComplete.contains(challengeId)) {

      return;
    }

    // Check if puzzle has been submitted (either in current session or cached)
    final hasSubmittedToday =
        isPuzzleCompleted || await _storageService.getPuzzleSubmissionStatus();

    if (!hasSubmittedToday) {
      if (_context != null) {
        ToastOverlay.showWarning(
          context: _context!,
          message: 'Complete the daily puzzle first!',
        );
      }

      return;
    }

    final challengeIndex = _activeChallenges.indexWhere(
      (c) => c.id == challengeId,
    );

    if (challengeIndex != -1) {
      final challenge = _activeChallenges[challengeIndex];

      // Check if already completed
      if (challenge.isCompleted) {
        if (_context != null) {
          ToastOverlay.showInfo(
            context: _context!,
            message: 'Challenge already completed!',
          );
        }
        return;
      }

      // Add to processing set to prevent multiple clicks
      _markingAsComplete.add(challengeId);
      notifyListeners(); // Update UI to disable button

      try {
        // Call API to mark challenge as complete
        final result = await _challengeRepository.markChallengeComplete(
          challengeId,
        );

        if (result.isSuccess) {
          // Update the challenge to completed state
          final completedChallenge = challenge.copyWith(
            isCompleted: true,
            completedDate: DateTime.now(),
          );

          // Replace the challenge in the active list with completed version
          _activeChallenges[challengeIndex] = completedChallenge;

          // Cache the updated challenge
          await _storageService.cacheChallenge(completedChallenge);
          
          // Move to completed challenges list
          _completedChallenges.insert(0, completedChallenge);
          await _storageService.cacheCompletedChallengesList(_completedChallenges);


          // Show success toast
          if (_context != null) {
            ToastOverlay.showSuccess(
              context: _context!,
              message: '🎉 Challenge completed! +${challenge.points} points!',
            );
          }

          notifyListeners();
        } else {
          // Show error toast
          if (_context != null) {
            ToastOverlay.showError(
              context: _context!,
              message: result.error ?? 'Failed to complete challenge',
            );
          }
        }
      } catch (e) {

        if (_context != null) {
          ToastOverlay.showError(
            context: _context!,
            message: 'An error occurred while completing the challenge',
          );
        }
      } finally {
        // Always remove from processing set when done
        _markingAsComplete.remove(challengeId);
        notifyListeners();
      }
    }
  }

  // Check if a challenge is currently being marked as complete
  bool isChallengeBeingMarked(String challengeId) {
    return _markingAsComplete.contains(challengeId);
  }

  // Check if mark as done button should be enabled for a challenge
  bool shouldEnableMarkAsDone(ChallengeModel challenge) {
    // If challenge is already completed, disable
    if (challenge.isCompleted) {
      return false;
    }
    
    // If currently being marked as complete, disable to prevent multiple clicks
    if (_markingAsComplete.contains(challenge.id)) {
      return false;
    }
    
    // If puzzle is not completed, disable
    if (!isPuzzleCompleted) {
      return false;
    }
    
    // All conditions met, enable the button
    return true;
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
