import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:yefa/app/app_setup.dart';
import 'package:yefa/core/utils/api_result.dart';
import 'package:yefa/data/models/journal_model.dart';
import 'package:yefa/data/models/user_model.dart';
import 'package:yefa/data/models/challenge_model.dart';
import 'package:yefa/data/repositories/journal_repository.dart';
import 'package:yefa/data/services/cache/home_cache.dart';
import 'package:yefa/data/services/storage_service.dart';
import 'package:yefa/data/repositories/challenge_repository.dart';
import 'models/verse_model.dart';

class HomeViewModel extends BaseViewModel {
  final StorageService _storageService = locator<StorageService>();
  final ChallengeRepository _challengeRepository =
      locator<ChallengeRepository>();
  final JournalRepository _journalRepository = locator<JournalRepository>();

  List<JournalModel> _entries = [];
  String? _errorMessage;
  UserModel? _user;
  bool _isRefreshing = false;
  bool _hasInternetConnection = true;

  VerseModel _todaysVerse = VerseModel.todaysVerse;
  VerseModel get todaysVerse => _todaysVerse;

  ChallengeModel? _todaysChallenge;
  ChallengeModel? get todaysChallenge => _todaysChallenge;

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

  int get fireCount => _calculateStreakDays();

  Future<void> fetchJournalEntries() async {
    print('🔄 Fetching journal entries...');
    _errorMessage = null;

    final result = await _journalRepository.getJournalEntries();

    if (result.isSuccess) {
      _entries = result.data ?? [];

      // Cache the entries
      await _storageService.cacheJournalEntries(_entries);

      print(
        '🟢 API Call Success - ${_entries.length} entries loaded and cached',
      );
    } else {
      _errorMessage = result.error ?? 'Failed to fetch entries';
      print('❌ API Call Failed: $_errorMessage');
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
      print('Error initializing HomeViewModel: $e');
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

      final cachedVerse = await _storageService.getCachedVerse();
      if (cachedVerse != null) {
        _todaysVerse = cachedVerse;
      }

      final cachedEntries = await _storageService.getCachedJournalEntries();
      if (cachedEntries != null) {
        _entries = cachedEntries;
        print('✅ Loaded ${_entries.length} cached journal entries');
      }
    } catch (e) {
      print('Error loading cached data: $e');
    }
  }

  Future<void> _loadFreshDataIfOnline() async {
    try {
      _hasInternetConnection = await _checkInternetConnection();

      if (_hasInternetConnection) {
        await _loadTodaysChallenge(fromCache: false);
        await _loadTodaysVerse();
        await fetchJournalEntries();
      }
    } catch (e) {
      print('Error loading fresh data: $e');
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
      print('Error loading today\'s challenge: $e');
    }
  }

  Future<void> _loadTodaysVerse() async {
    try {
      await _storageService.cacheVerse(_todaysVerse);
    } catch (e) {
      print('Error loading today\'s verse: $e');
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

  int _calculateStreakDays() {
    if (_user?.createdAt == null) return 0;

    final start = DateTime(
      _user!.createdAt.year,
      _user!.createdAt.month,
      _user!.createdAt.day,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return today.difference(start).inDays + 1;
  }

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

  @override
  void dispose() {
    super.dispose();
  }
}
