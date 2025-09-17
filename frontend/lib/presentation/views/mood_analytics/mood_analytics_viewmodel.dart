import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stacked/stacked.dart';
import '../../../data/models/mood_analytics_model.dart';
import '../../../data/repositories/sleep_repository.dart';
import '../../../app/app_setup.dart';
import '../../../core/utils/api_result.dart';
import 'package:logger/logger.dart';

class MoodAnalyticsViewModel extends BaseViewModel {
  BuildContext? _context;
  final SleepRepository _sleepRepository = locator<SleepRepository>();
  final Logger _logger = Logger();

  WeeklyMoodData? _weeklyMoodData;
  SleepGraphResponse? _sleepGraphResponse;
  SleepSummaryData? _sleepSummaryData;
  bool _isAnimated = false;
  String? _errorMessage;

  WeeklyMoodData? get weeklyMoodData => _weeklyMoodData;
  SleepGraphResponse? get sleepGraphResponse => _sleepGraphResponse;
  SleepSummaryData? get sleepSummaryData => _sleepSummaryData;
  bool get isAnimated => _isAnimated;
  String? get errorMessage => _errorMessage;

  // Sleep-specific getters (now using dynamic summary)
  double get averageSleepDuration => _sleepSummaryData?.averageSleepDuration ?? 0.0;
  int get totalSleepEntries => _sleepSummaryData?.totalNights ?? 0;
  bool get hasRealSleepData => _sleepGraphResponse != null && _sleepGraphResponse!.totalEntries > 0;

  void setContext(BuildContext context) {
    _context = context;
  }

  void onModelReady() {
    _loadMoodData();
    _startAnimation();
  }

  Future<void> _loadMoodData() async {
    setBusy(true);
    _errorMessage = null;
    
    try {
      final result = await _sleepRepository.getSleepGraph();
      
      result.when(
        success: (sleepResponse) {
          _sleepGraphResponse = sleepResponse;
          
          // Calculate dynamic sleep summary from real data
          _sleepSummaryData = SleepSummaryData.fromSleepResponse(sleepResponse);
          
          // Convert sleep data to mood analytics format for chart compatibility
          final moodData = sleepResponse.graphData
              .map((sleepData) => MoodAnalyticsModel.fromSleepData(sleepData))
              .toList();
              
          // Handle duplicate days by keeping the highest duration for each day
          final deduplicatedMoodData = _deduplicateByDay(moodData);
          
          // Create a full week with all 7 days, filling missing days with empty data
          final fullWeekData = _createFullWeekData(deduplicatedMoodData);
          
          if (deduplicatedMoodData.isNotEmpty) {
            _weeklyMoodData = WeeklyMoodData.fromMoodList(fullWeekData);
            _logger.i('Using real sleep data for chart with ${deduplicatedMoodData.length} unique days, expanded to 7 days');
          } else {
            final sampleMoods = MoodAnalyticsModel.generateSampleData();
            _weeklyMoodData = WeeklyMoodData.fromMoodList(sampleMoods);
            _logger.i('No sleep data available, using sample data for chart');
          }
          
          notifyListeners();
        },
        failure: (error) {
          _logger.e('Error loading sleep data: $error');
          _errorMessage = error;
          
          // Fallback to sample data on API error
          final sampleMoods = MoodAnalyticsModel.generateSampleData();
          _weeklyMoodData = WeeklyMoodData.fromMoodList(sampleMoods);
          notifyListeners();
        },
      );
    } catch (e) {
      _logger.e('Unexpected error loading mood data: $e');
      _errorMessage = 'An unexpected error occurred';
      
      // Fallback to sample data on any error
      final sampleMoods = MoodAnalyticsModel.generateSampleData();
      _weeklyMoodData = WeeklyMoodData.fromMoodList(sampleMoods);
      notifyListeners();
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

  // Handle duplicate days by keeping the highest duration (highest mood value)
  List<MoodAnalyticsModel> _deduplicateByDay(List<MoodAnalyticsModel> moodData) {
    if (moodData.isEmpty) return moodData;
    
    // Group by day of week and keep the one with highest mood value (duration)
    final Map<String, MoodAnalyticsModel> dayMap = {};
    
    for (final mood in moodData) {
      final day = mood.dayOfWeek;
      if (!dayMap.containsKey(day) || mood.moodValue > dayMap[day]!.moodValue) {
        dayMap[day] = mood;
      }
    }
    
    // Sort by date to maintain chronological order
    final result = dayMap.values.toList();
    result.sort((a, b) => a.date.compareTo(b.date));
    
    _logger.i('Deduplicated ${moodData.length} entries to ${result.length} unique days');
    for (final mood in result) {
      _logger.i('Day: ${mood.dayOfWeek}, Duration equivalent: ${mood.moodValue}');
    }
    
    return result;
  }

  // Create a full week (7 days) with missing days filled with default values
  List<MoodAnalyticsModel> _createFullWeekData(List<MoodAnalyticsModel> realData) {
    final now = DateTime.now();
    final List<String> dayAbbreviations = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    // Create a map of existing data by day abbreviation for easy lookup
    final Map<String, MoodAnalyticsModel> dataByDay = {};
    for (final mood in realData) {
      dataByDay[mood.dayOfWeek] = mood;
    }
    
    // Create 7 entries for the full week
    final List<MoodAnalyticsModel> fullWeek = [];
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      final dayIndex = date.weekday % 7; // Convert to 0-6 where 0 is Sunday
      final dayAbbr = dayAbbreviations[dayIndex];
      
      if (dataByDay.containsKey(dayAbbr)) {
        // Use real data if available
        fullWeek.add(dataByDay[dayAbbr]!);
      } else {
        // Create placeholder entry for missing day
        fullWeek.add(MoodAnalyticsModel(
          date: date,
          moodValue: 0, // 0 indicates no data for this day
          dayOfWeek: dayAbbr,
        ));
      }
    }
    
    _logger.i('Created full week data: ${fullWeek.map((m) => '${m.dayOfWeek}:${m.moodValue}').join(', ')}');
    return fullWeek;
  }

  void navigateBack() {
    if (_context != null && _context!.canPop()) {
      _context!.pop();
    } else if (_context != null) {
      _context!.go('/sleep-journal');
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
    if (_sleepSummaryData != null) {
      // Check if we have actual sleep data
      if (_sleepSummaryData!.totalNights == 0) {
        return 'No sleep data yet - start tracking your sleep! 📊💤';
      }
      
      // Dynamic sleep insights based on calculated summary
      final avgSleep = _sleepSummaryData!.averageSleepDuration;
      final goodSleepPercent = _sleepSummaryData!.goodSleepPercentage;
      final trend = _sleepSummaryData!.sleepTrend;
      
      // Priority insights based on data
      if (trend == "declining") {
        return 'Sleep quality declining - focus on consistency! 📉⚠️';
      }
      if (trend == "improving") {
        return 'Great progress! Your sleep is improving! 📈✨';
      }
      if (goodSleepPercent >= 80) {
        return 'Excellent! ${goodSleepPercent.toStringAsFixed(0)}% of nights with good sleep! 🌟';
      }
      if (avgSleep >= 8.0) {
        return 'Well-rested! Average ${_sleepSummaryData!.averageSleepFormatted} per night! 😴✨';
      }
      if (avgSleep >= 7.0) {
        return 'Good sleep pattern! Consistency: ${_sleepSummaryData!.consistencyRating} 🌙';
      }
      if (avgSleep >= 6.0) {
        return 'Room for improvement - aim for 7+ hours nightly! ⏰';
      }
      return 'Poor sleep detected - ${_sleepSummaryData!.poorSleepNights} nights under 6hrs! 🚨';
    }
    
    // Fallback to mood-based insights if no sleep data
    if (_weeklyMoodData == null) return '';
    final avg = _weeklyMoodData!.averageMood;
    if (avg >= 16) return 'You\'ve had an amazing week! 🌟';
    if (avg >= 13) return 'Great week overall! Keep it up! 😊';
    if (avg >= 10) return 'A pretty good week! 👍';
    if (avg >= 7) return 'An okay week. Tomorrow is a new day! ☀️';
    return 'Hang in there, better days are coming! 💪';
  }

  // Add method to refresh data
  Future<void> refreshData() async {
    await _loadMoodData();
  }
  
  // Sleep duration formatter
  String formatSleepDuration(double duration) {
    final hours = duration.floor();
    final minutes = ((duration - hours) * 60).round();
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }
  
  // Dynamic summary getters for UI
  String get longestSleepFormatted => _sleepSummaryData?.longestSleepFormatted ?? '0h';
  String get shortestSleepFormatted => _sleepSummaryData?.shortestSleepFormatted ?? '0h';
  String get averageSleepFormatted => _sleepSummaryData?.averageSleepFormatted ?? '0h';
  double get goodSleepPercentage => _sleepSummaryData?.goodSleepPercentage ?? 0.0;
  String get consistencyRating => _sleepSummaryData?.consistencyRating ?? 'No Data';
  String get trendDescription => _sleepSummaryData?.trendDescription ?? 'No Data';
  
  // Additional calculated metrics
  int get goodSleepNights => _sleepSummaryData?.goodSleepNights ?? 0;
  int get poorSleepNights => _sleepSummaryData?.poorSleepNights ?? 0;
  
  // Sleep score calculation (0-100)
  int get sleepScore {
    if (_sleepSummaryData == null || _sleepSummaryData!.totalNights == 0) return 0;
    
    final avgScore = (_sleepSummaryData!.averageSleepDuration / 9.0 * 40).clamp(0.0, 40.0);
    final consistencyScore = ((_sleepSummaryData!.sleepConsistency < 1.0 ? 30 : 
                              _sleepSummaryData!.sleepConsistency < 2.0 ? 20 : 10)).toDouble();
    final goodNightsScore = (_sleepSummaryData!.goodSleepPercentage * 0.3);
    
    return (avgScore + consistencyScore + goodNightsScore).round().clamp(0, 100);
  }
}