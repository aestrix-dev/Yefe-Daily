import '../models/journal_model.dart';
import '../../core/utils/api_result.dart';
import 'base_api_service.dart';

class JournalApiService extends BaseApiService {
  // Save journal entry
  Future<ApiResult<JournalModel>> saveJournalEntry(
    Map<String, dynamic> data,
  ) async {
    return safeApiCall(
      () => dioService.post('/journal/entries', data: data),
      (json) => JournalModel.fromJson(json),
    );
  }

  // Get journal entries
  Future<ApiResult<List<JournalModel>>> getJournalEntries({
    int page = 1,
    int limit = 20,
  }) async {
    return safeApiCallList(
      () => dioService.get(
        '/journal/entries',
        queryParameters: {'page': page, 'limit': limit},
      ),
      (json) => JournalModel.fromJson(json),
    );
  }


  // Delete journal entry
  Future<ApiResult<bool>> deleteJournalEntry(String entryId) async {
    return safeApiCallBool(
      () => dioService.delete('/journal/entries/$entryId'),
    );
  }
}
