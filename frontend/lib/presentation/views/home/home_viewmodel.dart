import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:yefa/app/app_setup.dart';
import 'package:yefa/core/utils/api_result.dart';
import 'package:yefa/data/models/user_model.dart';
import 'package:yefa/data/models/challenge_model.dart';
import 'package:yefa/data/services/storage_service.dart';
import 'package:yefa/data/repositories/challenge_repository.dart';
import 'models/verse_model.dart';
import 'models/activity_model.dart';

class HomeViewModel extends BaseViewModel {
  final StorageService _storageService = locator<StorageService>();
  final ChallengeRepository _challengeRepository =
      locator<ChallengeRepository>();

  UserModel? _user;

  VerseModel _todaysVerse = VerseModel.todaysVerse;
  VerseModel get todaysVerse => _todaysVerse;

  ChallengeModel? _todaysChallenge;
  ChallengeModel? get todaysChallenge => _todaysChallenge;

  List<ActivityModel> get recentActivities => ActivityModel.recentActivities;

  String get userName => _user?.name ?? 'Guest';

  String get todaySubtitle {
    if (_user?.createdAt != null) {
      final start = _user!.createdAt;
      final now = DateTime.now();
      final dayNumber = now.difference(start).inDays + 1;
      final formattedDate = DateFormat('MMMM d').format(now);
      return '$formattedDate • Day $dayNumber of your journey';
    }
    return 'Welcome to your journey';
  }

  int get fireCount => 1;

  Future<void> initialize() async {
    _user = await _storageService.getUser();
    await _loadTodaysChallenge();
    notifyListeners();
  }

  Future<void> _loadTodaysChallenge() async {
    final result = await _challengeRepository.getTodayChallenge();

    if (result.isSuccess && result.data!.isNotEmpty) {
      _todaysChallenge = result.data!.first;
    } else {
      _todaysChallenge = null;
    }
  }

  void toggleBookmark() {
    _todaysVerse = _todaysVerse.copyWith(
      isBookmarked: !_todaysVerse.isBookmarked,
    );
    notifyListeners();
  }
}
