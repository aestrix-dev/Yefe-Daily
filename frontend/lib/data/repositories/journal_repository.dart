import '../services/journal_api_service.dart';
import '../models/journal_model.dart';
import '../../core/utils/api_result.dart';
import '../../app/app_setup.dart';
import 'base_repository.dart';

class JournalRepository extends BaseRepository {
  final JournalApiService _apiService = locator<JournalApiService>();

  Future<ApiResult<JournalModel>> saveJournalEntry(
    Map<String, dynamic> data,
  ) async {
    return handleApiResult(_apiService.saveJournalEntry(data));
  }

  Future<ApiResult<List<JournalModel>>> getJournalEntries({
    int page = 1,
    int limit = 20,
  }) async {
    return handleApiResult(
      _apiService.getJournalEntries(page: page, limit: limit),
    );
  }

  Future<ApiResult<bool>> deleteJournalEntry(String entryId) async {
    return handleApiResult(_apiService.deleteJournalEntry(entryId));
  }
}
