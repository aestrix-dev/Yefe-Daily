import 'package:dio/dio.dart';
import '../models/challenge_model.dart';
import '../models/challenge_stats_model.dart';
import '../models/puzzle_model.dart';
import '../../core/utils/api_result.dart';
import 'base_api_service.dart';

class ChallengeApiService extends BaseApiService {
  // Get active challenges
  Future<ApiResult<List<ChallengeModel>>> getActiveChallenges() async {
    return safeApiCallList(
      () => dioService.get('/v1/challenges/active'),
      (json) => ChallengeModel.fromJson(json),
    );
  }

  Future<ApiResult<List<ChallengeModel>>> getTodayChallenge() async {
    try {
      final response = await dioService.get('/v1/challenges/today');

      if (response.statusCode == 200) {
        final outer = response.data['challenge'];
        final inner = outer['challenge'];
        final challenge = ChallengeModel.fromJson(inner);
        return Success([challenge]);
      } else {
        return Failure('Failed to load today challenge');
      }
    } catch (e) {
      return Failure('Error fetching today challenge: $e');
    }
  }

  // Get completed challenges
  Future<ApiResult<List<ChallengeModel>>> getCompletedChallenges() async {
    try {

      final response = await dioService.get('/v1/challenges/history');

      if (response.statusCode == 200) {
        final challengesList =
            response.data['challenge'] as List<dynamic>? ?? [];

        final completedChallenges = challengesList.map((item) {
          // Extract the nested challenge data and add completion info
          final challengeData = item['challenge'] as Map<String, dynamic>;
          final status = item['status'] as String?;
          final completedAt = item['completed_at'] as String?;

          // Add completion status to the challenge data
          challengeData['is_completed'] = status == 'completed';
          challengeData['completed_date'] = completedAt;

          return ChallengeModel.fromJson(challengeData);
        }).toList();

        return Success(completedChallenges);
      } else {
        return Failure(
          'Failed to get completed challenges with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {

      String errorMessage = 'Failed to get completed challenges';
      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage =
              responseData['message'] ?? responseData['error'] ?? errorMessage;
        }
      }

      return Failure(errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {

      return Failure('An unexpected error occurred: $e');
    }
  }

  // Mark challenge as complete
  Future<ApiResult<bool>> markChallengeComplete(String challengeId) async {
    return safeApiCallBool(
      () => dioService.put('/v1/challenges/$challengeId/complete'),
    );
  }

  // Get challenge statistics
  Future<ApiResult<ChallengeStatsModel>> getChallengeStats() async {
    try {

      final response = await dioService.get('/v1/challenges/stats');

      if (response.statusCode == 200) {
        final stats = ChallengeStatsModel.fromJson(response.data);
        return Success(stats);
      } else {
        return Failure(
          'Failed to get challenge stats with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {

      String errorMessage = 'Failed to get challenge stats';
      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage =
              responseData['message'] ?? responseData['error'] ?? errorMessage;
        }
      }

      return Failure(errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {

      return Failure('An unexpected error occurred: $e');
    }
  }

  // Get daily puzzle
  Future<ApiResult<PuzzleResponse>> getDailyPuzzle() async {
    try {

      final response = await dioService.get('/v1/puzzle/daily');

      if (response.statusCode == 200) {
        final puzzleResponse = PuzzleResponse.fromJson(response.data);
        return Success(puzzleResponse);
      } else {
        return Failure(
          'Failed to get daily puzzle with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {

      String errorMessage = 'Failed to get daily puzzle';
      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage =
              responseData['message'] ?? responseData['error'] ?? errorMessage;
        }
      }

      return Failure(errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {

      return Failure('An unexpected error occurred: $e');
    }
  }

  // Submit puzzle answer
  Future<ApiResult<PuzzleSubmissionResponse>> submitPuzzleAnswer(
    SubmitPuzzleRequest request,
  ) async {
    try {


      final response = await dioService.put(
        '/v1/puzzle/submit',
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final fullJson = response.data as Map<String, dynamic>;

        final innerData = fullJson['data']?['data'];
        final submissionData = innerData != null
            ? PuzzleSubmissionData.fromJson(innerData)
            : null;

        final submissionResponse = PuzzleSubmissionResponse(
          success: fullJson['success'] ?? false,
          message: fullJson['message'] ?? '',
          timestamp: DateTime.parse(
            fullJson['timestamp'] ?? DateTime.now().toIso8601String(),
          ),
          data: submissionData,
        );

        return Success(submissionResponse);
      } else {
        return Failure(
          'Failed to submit puzzle answer with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {

      String errorMessage = 'Failed to submit puzzle answer';
      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage =
              responseData['message'] ?? responseData['error'] ?? errorMessage;
        }
      }

      return Failure(errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {

      return Failure('An unexpected error occurred: $e');
    }
  }
}
