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

  // JSON serialization
  factory AudioModel.fromJson(Map<String, dynamic> json) {
    return AudioModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      duration: json['duration'] ?? '',
      audioUrl: json['audio_url'] ?? json['audioUrl'] ?? '',
      categoryId: json['category_id'] ?? json['categoryId'] ?? '',
      isPremium: json['is_premium'] ?? json['isPremium'] ?? false,
      subtitle: json['subtitle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'duration': duration,
      'audio_url': audioUrl,
      'category_id': categoryId,
      'is_premium': isPremium,
      'subtitle': subtitle,
    };
  }

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

  factory AudioCategoryModel.fromJson(Map<String, dynamic> json) {
    return AudioCategoryModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      audios:
          (json['audios'] as List<dynamic>?)
              ?.map((audio) => AudioModel.fromJson(audio))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'audios': audios.map((audio) => audio.toJson()).toList(),
    };
  }
}
