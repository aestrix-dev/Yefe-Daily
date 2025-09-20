import 'dart:convert';
import 'package:yefa/data/models/challenge_model.dart';
import 'package:yefa/data/models/challenge_stats_model.dart';
import 'package:yefa/data/models/journal_model.dart';
import 'package:yefa/data/models/puzzle_model.dart';
import 'package:yefa/data/models/reflection_model.dart';
import 'package:yefa/data/services/storage_service.dart';
import 'package:yefa/presentation/views/home/models/verse_model.dart';

// Extension for Challenge caching
extension ChallengeStorage on StorageService {
  static const String _challengeKey = 'cached_challenge';
  static const String _challengeDateKey = 'challenge_cache_date';

  Future<void> cacheChallenge(ChallengeModel challenge) async {
    final challengeJson = json.encode(challenge.toJson());
    await setString(_challengeKey, challengeJson);

    // Store the date when this challenge was cached
    final today = DateTime.now().toIso8601String();
    await setString(_challengeDateKey, today);
  }

  Future<ChallengeModel?> getCachedChallenge() async {
    final challengeJson = getString(_challengeKey);
    final cacheDateString = getString(_challengeDateKey);

    if (challengeJson != null && cacheDateString != null) {
      try {
        final cacheDate = DateTime.parse(cacheDateString);
        final today = DateTime.now();

        // Check if the cached challenge is from today
        if (_isSameDay(cacheDate, today)) {
          return ChallengeModel.fromJson(json.decode(challengeJson));
        } else {
          // Clear old cache
          await _clearChallengeCache();
        }
      } catch (e) {

        await _clearChallengeCache();
      }
    }
    return null;
  }

  Future<void> _clearChallengeCache() async {
    await remove(_challengeKey);
    await remove(_challengeDateKey);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

// Extension for Verse caching
extension VerseStorage on StorageService {
  static const String _verseKey = 'cached_verse';
  static const String _verseDateKey = 'verse_cache_date';

  Future<void> cacheVerse(VerseModel verse) async {
    final verseJson = json.encode(verse.toJson());
    await setString(_verseKey, verseJson);

    // Store the date when this verse was cached (not verse date)
    final today = DateTime.now().toIso8601String();
    await setString(_verseDateKey, today);
  }

  Future<VerseModel?> getCachedVerse() async {
    final verseJson = getString(_verseKey);
    final cacheDateString = getString(_verseDateKey);

    if (verseJson != null && cacheDateString != null) {
      try {
        final cacheDate = DateTime.parse(cacheDateString);
        final today = DateTime.now();

        // Check if the cached verse is from today (based on when it was cached)
        if (_isSameDay(cacheDate, today)) {
          return VerseModel.fromJson(json.decode(verseJson));
        } else {
          // Clear old cache
          await _clearVerseCache();
        }
      } catch (e) {

        await _clearVerseCache();
      }
    }
    return null;
  }

  Future<void> _clearVerseCache() async {
    await remove(_verseKey);
    await remove(_verseDateKey);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

// Extension for Reflection caching
extension ReflectionStorage on StorageService {
  static const String _reflectionKey = 'cached_reflection';
  static const String _reflectionDateKey = 'reflection_cache_date';

  Future<void> cacheReflection(ReflectionModel reflection) async {
    final reflectionJson = json.encode(reflection.toJson());
    await setString(_reflectionKey, reflectionJson);

    // Store the date when this reflection was cached
    final today = DateTime.now().toIso8601String();
    await setString(_reflectionDateKey, today);

  }

  Future<ReflectionModel?> getCachedReflection() async {
    final reflectionJson = getString(_reflectionKey);
    final cacheDateString = getString(_reflectionDateKey);

    if (reflectionJson == null || cacheDateString == null) {

      return null;
    }

    try {
      final cacheDate = DateTime.parse(cacheDateString);
      final today = DateTime.now();

      // Check if cached reflection is from today
      if (_isSameDay(cacheDate, today)) {
        final reflectionMap = json.decode(reflectionJson);
        final reflection = ReflectionModel.fromJson(reflectionMap);

        return reflection;
      } else {

        await clearReflectionCache();
        return null;
      }
    } catch (e) {

      await clearReflectionCache();
      return null;
    }
  }

  Future<void> clearReflectionCache() async {
    await remove(_reflectionKey);
    await remove(_reflectionDateKey);

  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

// Extension for Journal entries caching
extension JournalStorage on StorageService {
  static const String _journalEntriesKey = 'cached_journal_entries';
  static const String _journalCacheDateKey = 'journal_cache_date';

  Future<void> cacheJournalEntries(List<JournalModel> entries) async {
    final entriesJson = json.encode(entries.map((e) => e.toJson()).toList());
    await setString(_journalEntriesKey, entriesJson);

    // Store the date when entries were cached
    final now = DateTime.now().toIso8601String();
    await setString(_journalCacheDateKey, now);
  }

  Future<List<JournalModel>?> getCachedJournalEntries() async {
    final entriesJson = getString(_journalEntriesKey);
    final cacheDateString = getString(_journalCacheDateKey);

    if (entriesJson != null && cacheDateString != null) {
      try {
        final cacheDate = DateTime.parse(cacheDateString);
        final now = DateTime.now();

        // Check if cache is less than 1 hour old (adjust as needed)
        final difference = now.difference(cacheDate);
        if (difference.inHours < 1) {
          final List<dynamic> entriesListJson = json.decode(entriesJson);
          return entriesListJson.map((e) => JournalModel.fromJson(e)).toList();
        } else {
          // Clear old cache
          await _clearJournalCache();
        }
      } catch (e) {

        await _clearJournalCache();
      }
    }
    return null;
  }

  Future<void> _clearJournalCache() async {
    await remove(_journalEntriesKey);
    await remove(_journalCacheDateKey);
  }

  Future<void> addJournalEntryToCache(JournalModel entry) async {
    final cachedEntries = await getCachedJournalEntries() ?? [];
    cachedEntries.insert(0, entry); // Add to beginning for most recent first
    await cacheJournalEntries(cachedEntries);
  }

  Future<void> removeJournalEntryFromCache(String entryId) async {
    final cachedEntries = await getCachedJournalEntries() ?? [];
    cachedEntries.removeWhere((entry) => entry.id == entryId);
    await cacheJournalEntries(cachedEntries);
  }
}

// Extension for Puzzle caching
extension PuzzleStorage on StorageService {
  static const String _puzzleKey = 'cached_puzzle';
  static const String _puzzleDateKey = 'puzzle_cache_date';
  static const String _puzzleStateKey = 'puzzle_state';
  static const String _puzzleSubmissionKey = 'puzzle_submission_state';

  Future<void> cachePuzzle(PuzzleModel puzzle) async {
    final puzzleJson = json.encode(puzzle.toJson());
    await setString(_puzzleKey, puzzleJson);

    // Store the date when this puzzle was cached
    final today = DateTime.now().toIso8601String();
    await setString(_puzzleDateKey, today);

  }

  Future<PuzzleModel?> getCachedPuzzle() async {
    final puzzleJson = getString(_puzzleKey);
    final cacheDateString = getString(_puzzleDateKey);

    if (puzzleJson == null || cacheDateString == null) {

      return null;
    }

    try {
      final cacheDate = DateTime.parse(cacheDateString);
      final today = DateTime.now();

      // Check if cached puzzle is from today
      if (_isSameDay(cacheDate, today)) {
        final puzzleMap = json.decode(puzzleJson);
        final puzzle = PuzzleModel.fromJson(puzzleMap);

        return puzzle;
      } else {

        await clearPuzzleCache();
        return null;
      }
    } catch (e) {

      await clearPuzzleCache();
      return null;
    }
  }

  Future<void> clearPuzzleCache() async {
    await remove(_puzzleKey);
    await remove(_puzzleDateKey);

  }

  // Cache puzzle state (submission status, selected answer, etc.)
  Future<void> cachePuzzleState(PuzzleState state) async {
    final stateJson = json.encode({
      'hasSubmitted': state.hasSubmitted,
      'selectedAnswer': state.selectedAnswer,
      'submissionTime': state.submissionTime?.toIso8601String(),
      'isOnCooldown': state.isOnCooldown,
      'submissionResult': state.submissionResult?.toJson(),
    });
    await setString(_puzzleStateKey, stateJson);

  }

  Future<Map<String, dynamic>?> getCachedPuzzleState() async {
    final stateJson = getString(_puzzleStateKey);
    if (stateJson == null) return null;

    try {
      return json.decode(stateJson);
    } catch (e) {

      await remove(_puzzleStateKey);
      return null;
    }
  }

  Future<void> clearPuzzleState() async {
    await remove(_puzzleStateKey);

  }

  // Cache puzzle submission status for challenge completion
  Future<void> cachePuzzleSubmissionStatus(
    bool hasSubmitted,
    String puzzleId,
  ) async {
    final submissionData = json.encode({
      'hasSubmitted': hasSubmitted,
      'puzzleId': puzzleId,
      'submissionDate': DateTime.now().toIso8601String(),
    });
    await setString(_puzzleSubmissionKey, submissionData);

  }

  Future<bool> getPuzzleSubmissionStatus() async {
    final submissionJson = getString(_puzzleSubmissionKey);
    if (submissionJson == null) return false;

    try {
      final submissionData = json.decode(submissionJson);
      final submissionDate = DateTime.parse(submissionData['submissionDate']);
      final today = DateTime.now();

      // Check if submission is from today
      if (_isSameDay(submissionDate, today)) {
        return submissionData['hasSubmitted'] ?? false;
      } else {
        // Clear outdated submission status
        await remove(_puzzleSubmissionKey);
        return false;
      }
    } catch (e) {

      await remove(_puzzleSubmissionKey);
      return false;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

// Extension for Completed Challenges caching
extension CompletedChallengesStorage on StorageService {
  static const String _completedChallengesKey =
      'cached_completed_challenges_list';
  static const String _completedChallengesDateKey =
      'completed_challenges_cache_date';

  Future<void> cacheCompletedChallengesList(
    List<ChallengeModel> challenges,
  ) async {
    final challengesJson = json.encode(
      challenges.map((e) => e.toJson()).toList(),
    );
    await setString(_completedChallengesKey, challengesJson);

    final today = DateTime.now().toIso8601String();
    await setString(_completedChallengesDateKey, today);

  }

  Future<List<ChallengeModel>?> getCachedCompletedChallengesList() async {
    final challengesJson = getString(_completedChallengesKey);
    final cacheDateString = getString(_completedChallengesDateKey);

    if (challengesJson == null || cacheDateString == null) {

      return null;
    }

    try {
      final cacheDate = DateTime.parse(cacheDateString);
      final today = DateTime.now();

      // Check if cached challenges are from today
      if (_isSameDay(cacheDate, today)) {
        final challengesList = json.decode(challengesJson) as List;
        final challenges = challengesList
            .map((e) => ChallengeModel.fromJson(e))
            .toList();

        return challenges;
      } else {

        await clearCompletedChallengesCache();
        return null;
      }
    } catch (e) {

      await clearCompletedChallengesCache();
      return null;
    }
  }

  Future<void> clearCompletedChallengesCache() async {
    await remove(_completedChallengesKey);
    await remove(_completedChallengesDateKey);

  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

// Extension for Challenge Stats caching (including streak)
extension ChallengeStatsStorage on StorageService {
  static const String _challengeStatsKey = 'cached_challenge_stats';
  static const String _challengeStatsDateKey = 'challenge_stats_cache_date';

  Future<void> cacheChallengeStats(ChallengeStatsModel stats) async {
    final statsJson = json.encode(stats.toJson());
    await setString(_challengeStatsKey, statsJson);

    // Store the date when stats were cached
    final now = DateTime.now().toIso8601String();
    await setString(_challengeStatsDateKey, now);

  }

  Future<ChallengeStatsModel?> getCachedChallengeStats() async {
    final statsJson = getString(_challengeStatsKey);
    final cacheDateString = getString(_challengeStatsDateKey);

    if (statsJson == null || cacheDateString == null) {

      return null;
    }

    try {
      final cacheDate = DateTime.parse(cacheDateString);
      final now = DateTime.now();

      // Check if cache is less than 1 hour old (stats don't change frequently)
      final difference = now.difference(cacheDate);
      if (difference.inHours < 1) {
        final statsMap = json.decode(statsJson);
        final stats = ChallengeStatsModel.fromJson(statsMap);

        return stats;
      } else {

        await clearChallengeStatsCache();
        return null;
      }
    } catch (e) {

      await clearChallengeStatsCache();
      return null;
    }
  }

  Future<void> clearChallengeStatsCache() async {
    await remove(_challengeStatsKey);
    await remove(_challengeStatsDateKey);

  }
}

// Extension for general cache management
extension CacheManagement on StorageService {
  // Clear all cached data
  Future<void> clearAllCache() async {
    // Clear challenge cache
    await remove(ChallengeStorage._challengeKey);
    await remove(ChallengeStorage._challengeDateKey);

    // Clear challenge stats cache
    await remove(ChallengeStatsStorage._challengeStatsKey);
    await remove(ChallengeStatsStorage._challengeStatsDateKey);

    // Clear verse cache
    await remove(VerseStorage._verseKey);
    await remove(VerseStorage._verseDateKey);

    // Clear reflection cache
    await remove(ReflectionStorage._reflectionKey);
    await remove(ReflectionStorage._reflectionDateKey);

    // Clear journal cache
    await remove(JournalStorage._journalEntriesKey);
    await remove(JournalStorage._journalCacheDateKey);

    // Clear puzzle cache
    await remove(PuzzleStorage._puzzleKey);
    await remove(PuzzleStorage._puzzleDateKey);
    await remove(PuzzleStorage._puzzleStateKey);
    await remove(PuzzleStorage._puzzleSubmissionKey);

    // Clear completed challenges cache
    await remove(CompletedChallengesStorage._completedChallengesKey);
    await remove(CompletedChallengesStorage._completedChallengesDateKey);
  }

  // Check if we have cached data for today
  Future<bool> hasTodaysCachedData() async {
    final challenge = await getCachedChallenge();
    final verse = await getCachedVerse();
    final reflection = await getCachedReflection();
    final journal = await getCachedJournalEntries();
    return challenge != null ||
        verse != null ||
        reflection != null ||
        journal != null;
  }

  // Get cache status
  Future<Map<String, bool>> getCacheStatus() async {
    return {
      'hasChallenge': await getCachedChallenge() != null,
      'hasVerse': await getCachedVerse() != null,
      'hasReflection': await getCachedReflection() != null,
      'hasJournal': await getCachedJournalEntries() != null,
    };
  }
}
