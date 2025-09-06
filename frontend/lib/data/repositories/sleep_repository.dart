import '../models/mood_analytics_model.dart';
import '../services/sleep_api_service.dart';
import '../../core/utils/api_result.dart';
import '../../app/app_setup.dart';
import 'base_repository.dart';

class SleepRepository extends BaseRepository {
  final SleepApiService _sleepApiService = locator<SleepApiService>();

  Future<ApiResult<SleepGraphResponse>> getSleepGraph() async {
    return handleApiResult(_sleepApiService.getSleepGraph());
  }

  Future<ApiResult<SleepEntryResponse>> recordSleep({
    required String sleptDate,
    required String sleptTime,
    required String wokeUpDate,
    required String wokeUpTime,
  }) async {
    return handleApiResult(_sleepApiService.recordSleep(
      sleptDate: sleptDate,
      sleptTime: sleptTime,
      wokeUpDate: wokeUpDate,
      wokeUpTime: wokeUpTime,
    ));
  }

  Future<ApiResult<bool>> addSleepEntry({
    required DateTime date,
    required double duration,
  }) async {
    return handleApiResult(_sleepApiService.addSleepEntry(
      date: date,
      duration: duration,
    ));
  }

  Future<ApiResult<bool>> updateSleepEntry({
    required String entryId,
    required double duration,
  }) async {
    return handleApiResult(_sleepApiService.updateSleepEntry(
      entryId: entryId,
      duration: duration,
    ));
  }

  Future<ApiResult<bool>> deleteSleepEntry(String entryId) async {
    return handleApiResult(_sleepApiService.deleteSleepEntry(entryId));
  }
}