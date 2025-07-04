import 'package:stacked/stacked.dart';
import 'models/verse_model.dart';
import 'models/challenge_model.dart';
import 'models/activity_model.dart';

class HomeViewModel extends BaseViewModel {
  String get userName => 'John';
  String get todaySubtitle => 'June 9 • Day 01 of your journey';
  int get fireCount => 1; // Add this line

  VerseModel _todaysVerse = VerseModel.todaysVerse;
  VerseModel get todaysVerse => _todaysVerse;

  ChallengeModel get todaysChallenge => ChallengeModel.todaysChallenge;
  List<ActivityModel> get recentActivities => ActivityModel.recentActivities;

  void toggleBookmark() {
    _todaysVerse = _todaysVerse.copyWith(
      isBookmarked: !_todaysVerse.isBookmarked,
    );
    notifyListeners();
  }
}
