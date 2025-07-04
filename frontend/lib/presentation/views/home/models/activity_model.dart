class ActivityModel {
  final String title;
  final String subtitle;
  final String time;
  final String type;

  const ActivityModel({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
  });

  static List<ActivityModel> get sampleActivities => [
    const ActivityModel(
      title: 'Morning Reflection • Faith',
      subtitle:
          'Today I showed my spiritual faith with my family and focused on my...',
      time: 'Yesterday, 6:00 AM',
      type: 'reflection',
    ),
    const ActivityModel(
      title: 'Morning Reflection • Faith',
      subtitle: 'Grateful that challenges now me I should let become...',
      time: '2 days ago, 6:00 AM',
      type: 'reflection',
    ),
  ];
}
