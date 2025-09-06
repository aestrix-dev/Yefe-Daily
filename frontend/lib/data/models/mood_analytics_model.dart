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
        moodValue: 3 + (index * 3) % 17 + 1, // Sample values between 1-20
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