import 'package:yefa/data/models/puzzle_model.dart';

import '../services/challenge_api_service.dart';
import '../models/challenge_model.dart';
import '../../core/utils/api_result.dart';
import '../../app/app_setup.dart';
import 'base_repository.dart';

class ChallengeRepository extends BaseRepository {
  final ChallengeApiService _apiService = locator<ChallengeApiService>();

  Future<ApiResult<List<ChallengeModel>>> getActiveChallenges() async {
    return handleApiResult(_apiService.getActiveChallenges());
  }

  Future<ApiResult<List<ChallengeModel>>> getCompletedChallenges() async {
    return handleApiResult(_apiService.getCompletedChallenges());
  }

  Future<ApiResult<bool>> markChallengeComplete(String challengeId) async {
    return handleApiResult(_apiService.markChallengeComplete(challengeId));
  }

  Future<ApiResult<PuzzleModel>> getDailyPuzzle() async {
    return handleApiResult(_apiService.getDailyPuzzle());
  }

  Future<ApiResult<bool>> submitPuzzleAnswer(
    String puzzleId,
    String answer,
  ) async {
    return handleApiResult(_apiService.submitPuzzleAnswer(puzzleId, answer));
  }
}
