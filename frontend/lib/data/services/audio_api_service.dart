import '../models/audio_model.dart';
import '../../core/utils/api_result.dart';
import 'base_api_service.dart';

class AudioApiService extends BaseApiService {
  // Get all audio categories
  Future<ApiResult<List<AudioCategoryModel>>> getAudioCategories() async {
    return safeApiCallList(
      () => dioService.get('/audio/categories'),
      (json) => AudioCategoryModel.fromJson(json),
    );
  }

  // Get audio by category
  Future<ApiResult<List<AudioModel>>> getAudioByCategory(
    String categoryId,
  ) async {
    return safeApiCallList(
      () => dioService.get('/audio/category/$categoryId'),
      (json) => AudioModel.fromJson(json),
    );
  }

  // Search audio
  Future<ApiResult<List<AudioModel>>> searchAudio(String query) async {
    return safeApiCallList(
      () => dioService.get('/audio/search', queryParameters: {'q': query}),
      (json) => AudioModel.fromJson(json),
    );
  }
}
