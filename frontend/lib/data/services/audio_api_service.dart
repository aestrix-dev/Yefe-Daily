import 'package:dio/dio.dart';
import '../models/audio_model.dart';
import '../../core/utils/api_result.dart';
import 'base_api_service.dart';

class AudioApiService extends BaseApiService {
  /// Fetch all audios
  Future<ApiResult<List<AudioModel>>> getAudios() async {
    try {
      final Response res = await dioService.get('v1/songs');

      // Extract the list safely from nested JSON
      final List<dynamic> rawList = res.data['data']?['data'] ?? [];

      // Map to AudioModel list
      final List<AudioModel> audios = rawList
          .map((json) => AudioModel.fromJson(json))
          .toList();

      return Success(audios, message: res.data['message'] ?? 'Fetched audios');
    } catch (e) {
      return Failure(
        e.toString(),
        statusCode: e is DioException ? e.response?.statusCode : null,
      );
    }
  }

  /// Search audios
  Future<ApiResult<List<AudioModel>>> searchAudio(String query) async {
    try {
      final Response res = await dioService.get(
        '/audio/search',
        queryParameters: {'q': query},
      );

      final List<dynamic> rawList = res.data['data']?['data'] ?? [];

      final List<AudioModel> audios = rawList
          .map((json) => AudioModel.fromJson(json))
          .toList();

      return Success(audios, message: res.data['message'] ?? 'Search results');
    } catch (e) {
      return Failure(
        e.toString(),
        statusCode: e is DioException ? e.response?.statusCode : null,
      );
    }
  }
}
