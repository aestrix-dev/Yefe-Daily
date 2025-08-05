import '../../core/utils/api_result.dart';

abstract class BaseRepository {

  Future<ApiResult<T>> handleApiResult<T>(Future<ApiResult<T>> apiCall) async {
    try {
      return await apiCall;
    } catch (e) {
      return Failure('Repository error: ${e.toString()}');
    }
  }
}
