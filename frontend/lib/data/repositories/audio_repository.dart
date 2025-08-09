import '../services/audio_api_service.dart';
import '../models/audio_model.dart';
import '../../core/utils/api_result.dart';
import '../../app/app_setup.dart';
import 'base_repository.dart';

class AudioRepository extends BaseRepository {
  final AudioApiService _apiService = locator<AudioApiService>();

  // Get all audios
  Future<ApiResult<List<AudioModel>>> getAudios() async {
    return handleApiResult(_apiService.getAudios());
  }

  // Search
  Future<ApiResult<List<AudioModel>>> searchAudio(String query) async {
    return handleApiResult(_apiService.searchAudio(query));
  }
}
