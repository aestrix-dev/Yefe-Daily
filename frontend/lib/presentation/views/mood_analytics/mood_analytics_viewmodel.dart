import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stacked/stacked.dart';
import '../../../data/models/mood_analytics_model.dart';

class MoodAnalyticsViewModel extends BaseViewModel {
  BuildContext? _context;

  WeeklyMoodData? _weeklyMoodData;
  bool _isAnimated = false;

  WeeklyMoodData? get weeklyMoodData => _weeklyMoodData;
  bool get isAnimated => _isAnimated;

  void setContext(BuildContext context) {
    _context = context;
  }

  void onModelReady() {
    _loadMoodData();
    _startAnimation();
  }

  Future<void> _loadMoodData() async {
    setBusy(true);
    
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // For now, we'll use sample data
      // In a real app, this would fetch from an API
      final sampleMoods = MoodAnalyticsModel.generateSampleData();
      _weeklyMoodData = WeeklyMoodData.fromMoodList(sampleMoods);
      
      notifyListeners();
    } catch (e) {
      print('Error loading mood data: $e');
    } finally {
      setBusy(false);
    }
  }

  void _startAnimation() {
    Future.delayed(const Duration(milliseconds: 800), () {
      _isAnimated = true;
      notifyListeners();
    });
  }

  void navigateBack() {
    if (_context != null && _context!.canPop()) {
      _context!.pop();
    } else if (_context != null) {
      _context!.go('/profile');
    }
  }

  String getMoodDescription(int moodValue) {
    if (moodValue >= 18) return 'Excellent';
    if (moodValue >= 15) return 'Great';
    if (moodValue >= 12) return 'Good';
    if (moodValue >= 9) return 'Okay';
    if (moodValue >= 6) return 'Fair';
    if (moodValue >= 3) return 'Low';
    return 'Very Low';
  }

  String getWeeklyInsight() {
    if (_weeklyMoodData == null) return '';
    
    final avg = _weeklyMoodData!.averageMood;
    if (avg >= 16) return 'You\'ve had an amazing week! 🌟';
    if (avg >= 13) return 'Great week overall! Keep it up! 😊';
    if (avg >= 10) return 'A pretty good week! 👍';
    if (avg >= 7) return 'An okay week. Tomorrow is a new day! ☀️';
    return 'Hang in there, better days are coming! 💪';
  }
}