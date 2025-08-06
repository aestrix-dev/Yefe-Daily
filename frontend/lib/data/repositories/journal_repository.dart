import '../services/journal_api_service.dart';
import '../models/journal_model.dart';
import '../models/journal_request.dart';
import '../../core/utils/api_result.dart';
import '../../app/app_setup.dart';
import 'base_repository.dart';

class JournalRepository extends BaseRepository {
  final JournalApiService _apiService = locator<JournalApiService>();

  // Create new journal entry
  Future<ApiResult<JournalModel>> createJournalEntry({
    required String content,
    required String type,
    required List<String> tags,
  }) async {
    final request = CreateJournalRequest(
      content: content,
      type: type,
      tags: tags,
    );

    final result = await _apiService.createJournalEntry(request);

    if (result.isSuccess) {
      return Success(result.data!.data);
    } else {
      return Failure(result.error!, statusCode: (result as Failure).statusCode);
    }
  }

  // Get all journal entries
  Future<ApiResult<List<JournalModel>>> getJournalEntries() async {
    return await _apiService.getJournalEntries();
  }

  // Delete journal entry
  Future<ApiResult<bool>> deleteJournalEntry(String entryId) async {
    return await _apiService.deleteJournalEntry(entryId);
  }
}
