import 'dart:convert';
import 'package:yefa/data/models/challenge_model.dart';
import 'package:yefa/data/models/journal_model.dart';
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
        print('❌ Error parsing cached challenge: $e');
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
        print('❌ Error parsing cached verse: $e');
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
        print('❌ Error parsing cached journal entries: $e');
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

// Extension for general cache management
extension CacheManagement on StorageService {
  // Clear all cached data
  Future<void> clearAllCache() async {
    // Clear challenge cache
    await remove(ChallengeStorage._challengeKey);
    await remove(ChallengeStorage._challengeDateKey);

    // Clear verse cache
    await remove(VerseStorage._verseKey);
    await remove(VerseStorage._verseDateKey);

    // Clear journal cache
    await remove(JournalStorage._journalEntriesKey);
    await remove(JournalStorage._journalCacheDateKey);
  }

  // Check if we have cached data for today
  Future<bool> hasTodaysCachedData() async {
    final challenge = await getCachedChallenge();
    final verse = await getCachedVerse();
    final journal = await getCachedJournalEntries();
    return challenge != null || verse != null || journal != null;
  }

  // Get cache status
  Future<Map<String, bool>> getCacheStatus() async {
    return {
      'hasChallenge': await getCachedChallenge() != null,
      'hasVerse': await getCachedVerse() != null,
      'hasJournal': await getCachedJournalEntries() != null,
    };
  }
}
