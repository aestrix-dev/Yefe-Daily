
class SleepGraphData {
  final DateTime date;
  final double duration;
  final String dayOfWeek;

  SleepGraphData({
    required this.date,
    required this.duration,
    required this.dayOfWeek,
  });

  factory SleepGraphData.fromJson(Map<String, dynamic> json) {
    return SleepGraphData(
      date: DateTime.parse(json['date']),
      duration: (json['duration'] as num).toDouble(),
      dayOfWeek: json['day_of_week'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'duration': duration,
      'day_of_week': dayOfWeek,
    };
  }
}

// Complete sleep graph response model
class SleepGraphResponse {
  final List<SleepGraphData> graphData;
  final double averageSleepDuration;
  final int totalEntries;

  SleepGraphResponse({
    required this.graphData,
    required this.averageSleepDuration,
    required this.totalEntries,
  });

  factory SleepGraphResponse.fromJson(Map<String, dynamic> json) {
    return SleepGraphResponse(
      graphData: (json['graph_data'] as List<dynamic>)
          .map((item) => SleepGraphData.fromJson(item))
          .toList(),
      averageSleepDuration: (json['average_sleep_duration'] as num).toDouble(),
      totalEntries: json['total_entries'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'graph_data': graphData.map((data) => data.toJson()).toList(),
      'average_sleep_duration': averageSleepDuration,
      'total_entries': totalEntries,
    };
  }
}

// Keep original model for mood data compatibility
class MoodAnalyticsModel {
  final DateTime date;
  final int moodValue;
  final String dayOfWeek;

  MoodAnalyticsModel({
    required this.date,
    required this.moodValue,
    required this.dayOfWeek,
  });

  factory MoodAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return MoodAnalyticsModel(
      date: DateTime.parse(json['date']),
      moodValue: json['moodValue'],
      dayOfWeek: json['dayOfWeek'],
    );
  }

  // Convert from sleep data to mood representation (for chart compatibility)
  factory MoodAnalyticsModel.fromSleepData(SleepGraphData sleepData) {
    // Convert sleep duration to a mood-like scale (1-20)  
    // Use the actual duration to determine mood value (13h should get highest score)
    int moodValue;
    if (sleepData.duration >= 9.0) {
      moodValue = 20; // Excellent sleep (9+ hours) - 13h gets this!
    } else if (sleepData.duration >= 8.0) {
      moodValue = 18; // Great sleep (8-9 hours)  
    } else if (sleepData.duration >= 7.0) {
      moodValue = 15; // Good sleep (7-8 hours)
    } else if (sleepData.duration >= 6.0) {
      moodValue = 12; // Okay sleep (6-7 hours)
    } else if (sleepData.duration >= 5.0) {
      moodValue = 8;  // Poor sleep (5-6 hours)
    } else {
      moodValue = 4;  // Very poor sleep (<5 hours)
    }

    return MoodAnalyticsModel(
      date: sleepData.date,
      moodValue: moodValue,
      dayOfWeek: _getDayAbbreviation(sleepData.dayOfWeek),
    );
  }

  static String _getDayAbbreviation(String fullDay) {
    final dayMap = {
      'Monday': 'Mon',
      'Tuesday': 'Tue',
      'Wednesday': 'Wed',
      'Thursday': 'Thu',
      'Friday': 'Fri',
      'Saturday': 'Sat',
      'Sunday': 'Sun',
    };
    return dayMap[fullDay] ?? fullDay.substring(0, 3);
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'moodValue': moodValue,
      'dayOfWeek': dayOfWeek,
    };
  }

  static List<MoodAnalyticsModel> generateSampleData() {
    final now = DateTime.now();
    final List<String> days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final dayIndex = date.weekday % 7;
      
      return MoodAnalyticsModel(
        date: date,
        moodValue: 3 + (index * 3) % 17 + 1,
        dayOfWeek: days[dayIndex],
      );
    });
  }
}

class WeeklyMoodData {
  final List<MoodAnalyticsModel> dailyMoods;
  final double averageMood;
  final int highestMood;
  final int lowestMood;

  WeeklyMoodData({
    required this.dailyMoods,
    required this.averageMood,
    required this.highestMood,
    required this.lowestMood,
  });

  factory WeeklyMoodData.fromMoodList(List<MoodAnalyticsModel> moods) {
    if (moods.isEmpty) {
      return WeeklyMoodData(
        dailyMoods: [],
        averageMood: 0.0,
        highestMood: 0,
        lowestMood: 0,
      );
    }

    final values = moods.map((m) => m.moodValue).toList();
    final average = values.reduce((a, b) => a + b) / values.length;
    final highest = values.reduce((a, b) => a > b ? a : b);
    final lowest = values.reduce((a, b) => a < b ? a : b);

    return WeeklyMoodData(
      dailyMoods: moods,
      averageMood: average,
      highestMood: highest,
      lowestMood: lowest,
    );
  }
}

// Sleep-specific summary data calculated from actual sleep entries
class SleepSummaryData {
  final double averageSleepDuration;
  final double longestSleep;
  final double shortestSleep;
  final int totalNights;
  final int goodSleepNights; // 7+ hours
  final int poorSleepNights; // <6 hours
  final double sleepConsistency; // Standard deviation
  final String sleepTrend; // "improving", "declining", "stable"

  SleepSummaryData({
    required this.averageSleepDuration,
    required this.longestSleep,
    required this.shortestSleep,
    required this.totalNights,
    required this.goodSleepNights,
    required this.poorSleepNights,
    required this.sleepConsistency,
    required this.sleepTrend,
  });

  factory SleepSummaryData.fromSleepResponse(SleepGraphResponse response) {
    if (response.graphData.isEmpty) {
      return SleepSummaryData(
        averageSleepDuration: 0.0,
        longestSleep: 0.0,
        shortestSleep: 0.0,
        totalNights: 0,
        goodSleepNights: 0,
        poorSleepNights: 0,
        sleepConsistency: 0.0,
        sleepTrend: "no_data",
      );
    }

    final durations = response.graphData.map((data) => data.duration).toList();
    final average = durations.reduce((a, b) => a + b) / durations.length;
    final longest = durations.reduce((a, b) => a > b ? a : b);
    final shortest = durations.reduce((a, b) => a < b ? a : b);
    final goodNights = durations.where((d) => d >= 7.0).length;
    final poorNights = durations.where((d) => d < 6.0).length;
    
    // Calculate sleep consistency (lower standard deviation = more consistent)
    final variance = durations.map((d) => (d - average) * (d - average)).reduce((a, b) => a + b) / durations.length;
    final consistency = variance; // We'll use variance as consistency metric
    
    // Calculate trend (compare first half vs second half)
    String trend = "stable";
    if (durations.length >= 4) {
      final midPoint = durations.length ~/ 2;
      final firstHalf = durations.sublist(0, midPoint);
      final secondHalf = durations.sublist(midPoint);
      
      final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
      
      final difference = secondAvg - firstAvg;
      if (difference > 0.3) {
        trend = "improving";
      } else if (difference < -0.3) {
        trend = "declining";
      }
    }

    return SleepSummaryData(
      averageSleepDuration: average,
      longestSleep: longest,
      shortestSleep: shortest,
      totalNights: durations.length,
      goodSleepNights: goodNights,
      poorSleepNights: poorNights,
      sleepConsistency: consistency,
      sleepTrend: trend,
    );
  }

  // Helper methods for UI display
  String get averageSleepFormatted {
    final hours = averageSleepDuration.floor();
    final minutes = ((averageSleepDuration - hours) * 60).round();
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }

  String get longestSleepFormatted {
    final hours = longestSleep.floor();
    final minutes = ((longestSleep - hours) * 60).round();
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }

  String get shortestSleepFormatted {
    final hours = shortestSleep.floor();
    final minutes = ((shortestSleep - hours) * 60).round();
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }

  double get goodSleepPercentage {
    return totalNights > 0 ? (goodSleepNights / totalNights) * 100 : 0.0;
  }

  String get consistencyRating {
    if (sleepConsistency < 0.5) return "Very Consistent";
    if (sleepConsistency < 1.0) return "Consistent";
    if (sleepConsistency < 2.0) return "Moderate";
    if (sleepConsistency < 3.0) return "Inconsistent";
    return "Very Inconsistent";
  }

  String get trendDescription {
    switch (sleepTrend) {
      case "improving":
        return "Your sleep is improving! 📈";
      case "declining":
        return "Sleep trend declining 📉";
      case "stable":
        return "Sleep pattern stable 📊";
      default:
        return "Not enough data for trends";
    }
  }
}

// Sleep entry response model to match API response
class SleepEntryResponse {
  final String id;
  final String userId;
  final DateTime sleptAt;
  final DateTime wokeUpAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  SleepEntryResponse({
    required this.id,
    required this.userId,
    required this.sleptAt,
    required this.wokeUpAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SleepEntryResponse.fromJson(Map<String, dynamic> json) {
    return SleepEntryResponse(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sleptAt: DateTime.parse(json['slept_at']),
      wokeUpAt: DateTime.parse(json['woke_up_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'slept_at': sleptAt.toIso8601String(),
      'woke_up_at': wokeUpAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Calculate sleep duration in hours
  double get duration {
    final difference = wokeUpAt.difference(sleptAt);
    return difference.inMinutes / 60.0;
  }
}