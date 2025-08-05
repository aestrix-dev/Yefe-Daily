import '../services/audio_api_service.dart';
import '../models/audio_model.dart';
import '../../core/utils/api_result.dart';
import '../../app/app_setup.dart';
import 'base_repository.dart';

class AudioRepository extends BaseRepository {
  final AudioApiService _apiService = locator<AudioApiService>();

  Future<ApiResult<List<AudioCategoryModel>>> getAudioCategories() async {
    return handleApiResult(_apiService.getAudioCategories());
  }

  Future<ApiResult<List<AudioModel>>> getAudioByCategory(
    String categoryId,
  ) async {
    return handleApiResult(_apiService.getAudioByCategory(categoryId));
  }

  Future<ApiResult<List<AudioModel>>> searchAudio(String query) async {
    return handleApiResult(_apiService.searchAudio(query));
  }
}
