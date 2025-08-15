class AudioModel {
  final String uuid;
  final String title;
  final String feel;
  final String description;
  final String genre;
  final String length;
  final String access;
  final String downloadUrl;

  AudioModel({
    required this.uuid,
    required this.title,
    required this.feel,
    required this.description,
    required this.genre,
    required this.length,
    required this.access,
    required this.downloadUrl,
  });

  factory AudioModel.fromJson(Map<String, dynamic> json) {
    return AudioModel(
      uuid: json['uuid'] ?? '',
      title: json['title'] ?? '',
      feel: json['feel'] ?? '',
      description: json['description'] ?? '',
      genre: json['genre'] ?? '',
      length: json['length'] ?? '',
      access: json['access'] ?? '',
      downloadUrl: json['download_url'] ?? '',
    );
  }

  // Add toJson method for caching
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'title': title,
      'feel': feel,
      'description': description,
      'genre': genre,
      'length': length,
      'access': access,
      'download_url': downloadUrl,
    };
  }

  // Helper getters for UI compatibility
  String get id => uuid;
  String get duration => length;
  String get audioUrl => downloadUrl;
  bool get isPremium => access != 'free';
  String? get subtitle => feel.isNotEmpty ? feel : null;
}

class AudioCategoryModel {
  final String id;
  final String title;
  final List<AudioModel> audios;

  AudioCategoryModel({
    required this.id,
    required this.title,
    required this.audios,
  });
}
