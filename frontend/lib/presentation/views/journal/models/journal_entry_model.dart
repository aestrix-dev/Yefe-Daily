class JournalEntryModel {
  final String id;
  final String content;
  final List<String> tags;
  final JournalType type;
  final DateTime createdAt;

  const JournalEntryModel({
    required this.id,
    required this.content,
    required this.tags,
    required this.type,
    required this.createdAt,
  });

  @override
  String toString() {
    return 'JournalEntry{id: $id, type: $type, content: $content, tags: $tags, createdAt: $createdAt}';
  }
}

enum JournalType { morning, evening, wisdomNote }
