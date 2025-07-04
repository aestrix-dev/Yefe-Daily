class ChallengeModel {
  final String title;
  final String description;
  final bool isCompleted;

  const ChallengeModel({
    required this.title,
    required this.description,
    required this.isCompleted,
  });

  static ChallengeModel get sample => const ChallengeModel(
    title: 'Manhood Challenge',
    description: 'Reach out to a brother friend and offer encouragement.',
    isCompleted: false,
  );
}
