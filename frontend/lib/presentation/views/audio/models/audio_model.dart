class AudioModel {
  final String id;
  final String title;
  final String duration;
  final String audioUrl;
  final String categoryId;
  final bool isPremium;
  final String? subtitle;

  const AudioModel({
    required this.id,
    required this.title,
    required this.duration,
    required this.audioUrl,
    required this.categoryId,
    required this.isPremium,
    this.subtitle,
  });

  AudioModel copyWith({
    String? id,
    String? title,
    String? duration,
    String? audioUrl,
    String? categoryId,
    bool? isPremium,
    String? subtitle,
  }) {
    return AudioModel(
      id: id ?? this.id,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      audioUrl: audioUrl ?? this.audioUrl,
      categoryId: categoryId ?? this.categoryId,
      isPremium: isPremium ?? this.isPremium,
      subtitle: subtitle ?? this.subtitle,
    );
  }
}

class AudioCategoryModel {
  final String id;
  final String title;
  final List<AudioModel> audios;

  const AudioCategoryModel({
    required this.id,
    required this.title,
    required this.audios,
  });

  AudioCategoryModel copyWith({
    String? id,
    String? title,
    List<AudioModel>? audios,
  }) {
    return AudioCategoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      audios: audios ?? this.audios,
    );
  }
}
