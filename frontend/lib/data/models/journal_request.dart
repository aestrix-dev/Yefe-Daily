class CreateJournalRequest {
  final String content;
  final String type;
  final List<String> tags;

  const CreateJournalRequest({
    required this.content,
    required this.type,
    required this.tags,
  });

  Map<String, dynamic> toJson() {
    return {'content': content, 'type': type, 'tags': tags};
  }
}

class UpdateJournalRequest {
  final String content;
  final String type;
  final List<String> tags;

  const UpdateJournalRequest({
    required this.content,
    required this.type,
    required this.tags,
  });

  Map<String, dynamic> toJson() {
    return {'content': content, 'type': type, 'tags': tags};
  }
}
