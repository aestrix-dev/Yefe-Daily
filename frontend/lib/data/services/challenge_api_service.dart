
import 'package:yefa/data/models/puzzle_model.dart';

import '../models/challenge_model.dart';
import '../../core/utils/api_result.dart';
import 'base_api_service.dart';

class ChallengeApiService extends BaseApiService {
  // Get active challenges
  Future<ApiResult<List<ChallengeModel>>> getActiveChallenges() async {
    return safeApiCallList(
      () => dioService.get('/challenges/active'),
      (json) => ChallengeModel.fromJson(json),
    );
  }

  // Get completed challenges
  Future<ApiResult<List<ChallengeModel>>> getCompletedChallenges() async {
    return safeApiCallList(
      () => dioService.get('/challenges/completed'),
      (json) => ChallengeModel.fromJson(json),
    );
  }

  // Mark challenge as complete
  Future<ApiResult<bool>> markChallengeComplete(String challengeId) async {
    return safeApiCallBool(
      () => dioService.post('/challenges/$challengeId/complete'),
    );
  }

  // Get daily puzzle
  Future<ApiResult<PuzzleModel>> getDailyPuzzle() async {
    return safeApiCall(
      () => dioService.get('/challenges/daily-puzzle'),
      (json) => PuzzleModel.fromJson(json),
    );
  }

  // Submit puzzle answer
  Future<ApiResult<bool>> submitPuzzleAnswer(
    String puzzleId,
    String answer,
  ) async {
    return safeApiCallBool(
      () => dioService.post(
        '/challenges/puzzle/$puzzleId/answer',
        data: {'answer': answer},
      ),
    );
  }
}
