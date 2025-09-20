import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:yefa/app/app_setup.dart';
import 'package:yefa/core/utils/api_result.dart';
import 'package:yefa/data/models/journal_model.dart';
import 'package:yefa/data/models/user_model.dart';
import 'package:yefa/data/models/challenge_model.dart';
import 'package:yefa/data/models/challenge_stats_model.dart';
import 'package:yefa/data/repositories/journal_repository.dart';
import 'package:yefa/data/repositories/reflection_repository.dart';
import 'package:yefa/data/services/cache/home_cache.dart';
import 'package:yefa/data/services/storage_service.dart';
import 'package:yefa/data/repositories/challenge_repository.dart';
import 'models/verse_model.dart';

class HomeViewModel extends BaseViewModel {
  final StorageService _storageService = locator<StorageService>();
  final ChallengeRepository _challengeRepository =
      locator<ChallengeRepository>();
  final JournalRepository _journalRepository = locator<JournalRepository>();
  final ReflectionRepository _reflectionRepository =
      locator<ReflectionRepository>();

  List<JournalModel> _entries = [];
  UserModel? _user;
  bool _isRefreshing = false;
  bool _hasInternetConnection = true;

  VerseModel _todaysVerse = VerseModel.todaysVerse;
  VerseModel get todaysVerse => _todaysVerse;

  ChallengeModel? _todaysChallenge;
  ChallengeModel? get todaysChallenge => _todaysChallenge;

  // Challenge stats for streak (from API)
  ChallengeStatsModel? _challengeStats;
  ChallengeStatsModel? get challengeStats => _challengeStats;

  // Use journal entries as recent activities
  List<JournalModel> get recentActivities => _entries;

  String get userName => _user?.name ?? 'Guest';
  bool get isRefreshing => _isRefreshing;
  bool get hasInternetConnection => _hasInternetConnection;

  String get todaySubtitle {
    if (_user?.createdAt != null) {
      final start = DateTime(
        _user!.createdAt.year,
        _user!.createdAt.month,
        _user!.createdAt.day,
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final dayNumber = today.difference(start).inDays + 1;
      final formattedDate = DateFormat('MMMM d').format(now);
      return '$formattedDate • Day $dayNumber of your journey';
    }
    return 'Welcome to your journey';
  }

  // Use API streak value instead of calculated one
  int get fireCount => _challengeStats?.currentStreak ?? 0;

  Future<void> fetchJournalEntries() async {

    final result = await _journalRepository.getJournalEntries();

    if (result.isSuccess) {
      _entries = result.data ?? [];

      // Cache the entries
      await _storageService.cacheJournalEntries(_entries);

    } else {
      // Error occurred but not displayed to user
    }

    notifyListeners();
  }

  Future<void> initialize() async {
    setBusy(true);

    try {
      _user = await _storageService.getUser();
      await _loadCachedData();
      notifyListeners();
      fetchJournalEntries();
      await _loadFreshDataIfOnline();
    } catch (e) {

    } finally {
      setBusy(false);
    }
  }

  Future<void> _loadCachedData() async {
    try {
      final cachedChallenge = await _storageService.getCachedChallenge();
      if (cachedChallenge != null) {
        _todaysChallenge = cachedChallenge;
      }

      // Load cached challenge stats (including streak)
      final cachedStats = await _storageService.getCachedChallengeStats();
      if (cachedStats != null) {
        _challengeStats = cachedStats;

      }

      // Try to load reflection first, fallback to cached verse
      final cachedReflection = await _storageService.getCachedReflection();
      if (cachedReflection != null) {
        _todaysVerse = cachedReflection.toVerseModel();

      } else {
        final cachedVerse = await _storageService.getCachedVerse();
        if (cachedVerse != null) {
          _todaysVerse = cachedVerse;

        }
      }

      final cachedEntries = await _storageService.getCachedJournalEntries();
      if (cachedEntries != null) {
        _entries = cachedEntries;

      }
    } catch (e) {

    }
  }

  Future<void> _loadFreshDataIfOnline() async {
    try {
      _hasInternetConnection = await _checkInternetConnection();

      if (_hasInternetConnection) {
        await _loadTodaysChallenge(fromCache: false);
        await _loadTodaysReflection();
        await _loadChallengeStats();
        await fetchJournalEntries();
      }
    } catch (e) {

      _hasInternetConnection = false;
    }
  }

  Future<void> _loadTodaysChallenge({bool fromCache = true}) async {
    try {
      final result = await _challengeRepository.getTodayChallenge();

      if (result.isSuccess && result.data!.isNotEmpty) {
        _todaysChallenge = result.data!.first;
        await _storageService.cacheChallenge(_todaysChallenge!);
      } else {
        if (!fromCache) {
          _todaysChallenge = null;
        }
      }
    } catch (e) {

    }
  }

  Future<void> _loadTodaysReflection() async {
    try {

      final result = await _reflectionRepository.getDailyReflection();

      if (result.isSuccess) {
        final reflection = result.data!;
        _todaysVerse = reflection.toVerseModel();

      } else {

        // Keep the default verse if reflection fails
      }

      notifyListeners();
    } catch (e) {

      // Keep the default verse if reflection fails
    }
  }

  Future<void> _loadChallengeStats() async {
    try {

      final result = await _challengeRepository.getChallengeStats();

      if (result.isSuccess) {
        _challengeStats = result.data!;
        
        // Cache the stats
        await _storageService.cacheChallengeStats(_challengeStats!);

      } else {

        // Keep cached stats if API fails
      }

      notifyListeners();
    } catch (e) {

      // Keep cached stats if error occurs
    }
  }

  Future<void> refreshData() async {
    _isRefreshing = true;
    notifyListeners();

    try {
      await _loadFreshDataIfOnline();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // Removed _calculateStreakDays() - now using API streak value

  Future<bool> _checkInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  void toggleBookmark() {
    _todaysVerse = _todaysVerse.copyWith(
      isBookmarked: !_todaysVerse.isBookmarked,
    );
    _storageService.cacheVerse(_todaysVerse);
    notifyListeners();
  }

}
