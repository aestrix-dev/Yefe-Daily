import '../models/mood_analytics_model.dart';
import '../../core/utils/api_result.dart';
import 'base_api_service.dart';

class SleepApiService extends BaseApiService {
  // Get sleep graph data
  Future<ApiResult<SleepGraphResponse>> getSleepGraph() async {
    return safeApiCall(
      () => dioService.get('/v1/sleep/graph'),
      (json) => SleepGraphResponse.fromJson(json),
    );
  }

  // Record sleep entry (new API format)
  Future<ApiResult<SleepEntryResponse>> recordSleep({
    required String sleptDate,
    required String sleptTime,
    required String wokeUpDate,
    required String wokeUpTime,
  }) async {
    return safeApiCall(
      () => dioService.post('/v1/sleep', data: {
        'slept_date': sleptDate,
        'slept_time': sleptTime,
        'woke_up_date': wokeUpDate,
        'woke_up_time': wokeUpTime,
      }),
      (json) => SleepEntryResponse.fromJson(json),
    );
  }

  // Legacy add sleep entry (keeping for compatibility)
  Future<ApiResult<bool>> addSleepEntry({
    required DateTime date,
    required double duration,
  }) async {
    return safeApiCallBool(() => dioService.post(
      '/v1/sleep/entry',
      data: {
        'date': date.toIso8601String(),
        'duration': duration,
      },
    ));
  }

  // Update sleep entry
  Future<ApiResult<bool>> updateSleepEntry({
    required String entryId,
    required double duration,
  }) async {
    return safeApiCallBool(() => dioService.put(
      '/v1/sleep/entry/$entryId',
      data: {
        'duration': duration,
      },
    ));
  }

  // Delete sleep entry
  Future<ApiResult<bool>> deleteSleepEntry(String entryId) async {
    return safeApiCallBool(() => dioService.delete('/v1/sleep/entry/$entryId'));
  }
}