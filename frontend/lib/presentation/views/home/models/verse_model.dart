class VerseModel {
  final String text;
  final String reference;
  final String date;
  final bool isBookmarked;

  const VerseModel({
    required this.text,
    required this.reference,
    required this.date,
    this.isBookmarked = false,
  });

  static VerseModel get todaysVerse => const VerseModel(
    text:
        '"For I know the plans I have for you," declares the LORD, "plans to prosper you and not to harm you, plans to give you hope and a future."',
    reference: 'Jeremiah 29:11',
    date: 'June 9 • Day 01 of your journey',
    isBookmarked: false,
  );

  VerseModel copyWith({bool? isBookmarked}) {
    return VerseModel(
      text: text,
      reference: reference,
      date: date,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  // JSON Serialization
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'reference': reference,
      'date': date,
      'isBookmarked': isBookmarked,
    };
  }

  // JSON Deserialization
  factory VerseModel.fromJson(Map<String, dynamic> json) {
    return VerseModel(
      text: json['text'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      date: json['date'] as String? ?? '',
      isBookmarked: json['isBookmarked'] as bool? ?? false,
    );
  }

  // For API responses - if your API returns different field names
  factory VerseModel.fromApiResponse(Map<String, dynamic> json) {
    return VerseModel(
      text: json['verse_text'] as String? ?? json['text'] as String? ?? '',
      reference:
          json['verse_reference'] as String? ??
          json['reference'] as String? ??
          '',
      date: json['verse_date'] as String? ?? json['date'] as String? ?? '',
      isBookmarked:
          json['is_bookmarked'] as bool? ??
          json['isBookmarked'] as bool? ??
          false,
    );
  }

  // Convert API response to standard format
  Map<String, dynamic> toApiJson() {
    return {
      'verse_text': text,
      'verse_reference': reference,
      'verse_date': date,
      'is_bookmarked': isBookmarked,
    };
  }

  // Helper method to get DateTime from date string (for caching logic)
  DateTime? get createdAt {
    try {
      // If your date format is different, adjust this parsing logic
      // For now, returning current date since your date field is a display string
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  // Helper method to check if verse is for today
  bool get isForToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final verseDate = createdAt;

    if (verseDate == null) return false;

    final verseDateOnly = DateTime(
      verseDate.year,
      verseDate.month,
      verseDate.day,
    );
    return today.isAtSameMomentAs(verseDateOnly);
  }

  @override
  String toString() {
    return 'VerseModel(text: $text, reference: $reference, date: $date, isBookmarked: $isBookmarked)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VerseModel &&
        other.text == text &&
        other.reference == reference &&
        other.date == date &&
        other.isBookmarked == isBookmarked;
  }

  @override
  int get hashCode {
    return text.hashCode ^
        reference.hashCode ^
        date.hashCode ^
        isBookmarked.hashCode;
  }
}
