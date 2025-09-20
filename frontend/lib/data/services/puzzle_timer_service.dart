import 'dart:async';
import '../services/storage_service.dart';
import '../services/cache/home_cache.dart';
import '../../app/app_setup.dart';

class PuzzleTimerService {
  static const String _lastSubmissionKey = 'puzzle_last_submission';
  static const String _currentPuzzleIdKey = 'puzzle_current_id';
  static const Duration _cooldownDuration = Duration(hours: 24);

  final StorageService _storageService = locator<StorageService>();

  Timer? _countdownTimer;
  DateTime? _lastSubmissionTime;
  String? _currentPuzzleId;

  // Callback for when timer expires and new puzzle should be fetched
  Function()? onTimerExpired;
  // Callback for countdown updates
  Function(Duration remaining)? onCountdownUpdate;

  PuzzleTimerService() {
    _loadStoredData();
  }

  // Load stored submission time and puzzle ID
  void _loadStoredData() {
    final lastSubmissionString = _storageService.getString(_lastSubmissionKey);
    final puzzleId = _storageService.getString(_currentPuzzleIdKey);

    if (lastSubmissionString != null) {
      try {
        _lastSubmissionTime = DateTime.parse(lastSubmissionString);

      } catch (e) {

        _clearStoredData();
      }
    }

    if (puzzleId != null) {
      _currentPuzzleId = puzzleId;

    }
  }

  // Save submission time and puzzle ID
  Future<void> _saveSubmissionData(String puzzleId) async {
    final now = DateTime.now();
    _lastSubmissionTime = now;
    _currentPuzzleId = puzzleId;

    await _storageService.setString(_lastSubmissionKey, now.toIso8601String());
    await _storageService.setString(_currentPuzzleIdKey, puzzleId);

  }

  // Clear stored data
  Future<void> _clearStoredData() async {
    _lastSubmissionTime = null;
    _currentPuzzleId = null;

    await _storageService.remove(_lastSubmissionKey);
    await _storageService.remove(_currentPuzzleIdKey);

  }

  // Check if user is on cooldown
  bool get isOnCooldown {
    if (_lastSubmissionTime == null) return false;

    final timeSinceSubmission = DateTime.now().difference(_lastSubmissionTime!);
    return timeSinceSubmission < _cooldownDuration;
  }

  // Get remaining cooldown time
  Duration? get remainingCooldown {
    if (!isOnCooldown) return null;

    final timeSinceSubmission = DateTime.now().difference(_lastSubmissionTime!);
    return _cooldownDuration - timeSinceSubmission;
  }

  // Check if this is a new puzzle (different from stored one)
  bool isNewPuzzle(String puzzleId) {
    return _currentPuzzleId != puzzleId;
  }

  // Record puzzle submission
  Future<void> recordSubmission(String puzzleId) async {
    await _saveSubmissionData(puzzleId);
    // Cache the submission status for challenge completion
    await _storageService.cachePuzzleSubmissionStatus(true, puzzleId);
    _startCountdown();
  }

  // Start countdown timer
  void _startCountdown() {
    _stopCountdown();

    if (!isOnCooldown) {

      onTimerExpired?.call();
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = remainingCooldown;

      if (remaining == null || remaining.isNegative) {

        _stopCountdown();
        _clearStoredData();
        onTimerExpired?.call();
      } else {
        onCountdownUpdate?.call(remaining);
      }
    });
  }

  // Stop countdown timer
  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  // Initialize timer service (call when app starts)
  void initialize() {
    if (isOnCooldown) {

      _startCountdown();
    } else {

    }
  }

  // Manual reset (for testing or admin purposes)
  Future<void> reset() async {
    _stopCountdown();
    await _clearStoredData();

  }

  // Check if user can attempt puzzle
  bool canAttemptPuzzle() {
    return !isOnCooldown;
  }

  // Get formatted time remaining
  String getFormattedTimeRemaining() {
    final remaining = remainingCooldown;
    if (remaining == null) return '';

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void dispose() {
    _stopCountdown();
  }
}
