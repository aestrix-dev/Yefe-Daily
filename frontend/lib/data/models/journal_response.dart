import 'package:yefa/data/models/journal_model.dart';

class JournalResponse {
  final bool success;
  final String message;
  final JournalModel data;
  final DateTime timestamp;

  const JournalResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  factory JournalResponse.fromJson(Map<String, dynamic> json) {
    return JournalResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: JournalModel.fromJson(json['data'] ?? {}),
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class JournalListResponse {
  final bool success;
  final String message;
  final List<JournalModel> data;
  final DateTime timestamp;
  final int? total;
  final int? page;
  final int? limit;

  const JournalListResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.timestamp,
    this.total,
    this.page,
    this.limit,
  });

  factory JournalListResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List? ?? [];
    return JournalListResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: dataList.map((item) => JournalModel.fromJson(item)).toList(),
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      total: json['total'],
      page: json['page'],
      limit: json['limit'],
    );
  }
}
