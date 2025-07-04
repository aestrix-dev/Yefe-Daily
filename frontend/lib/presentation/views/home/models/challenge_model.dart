class ChallengeModel {
  final String title;
  final String description;
  final bool isCompleted;

  const ChallengeModel({
    required this.title,
    required this.description,
    this.isCompleted = false,
  });

  static ChallengeModel get todaysChallenge => const ChallengeModel(
    title: 'Manhood Challenge',
    description: 'Reach out to a brother friend and offer encouragement.',
    isCompleted: false,
  );
}
