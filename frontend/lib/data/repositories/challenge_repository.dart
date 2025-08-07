import '../services/challenge_api_service.dart';
import '../models/challenge_model.dart';
import '../models/puzzle_model.dart';
import '../../core/utils/api_result.dart';
import '../../app/app_setup.dart';
import 'base_repository.dart';

class ChallengeRepository extends BaseRepository {
  final ChallengeApiService _apiService = locator<ChallengeApiService>();

  // Get active challenges
  Future<ApiResult<List<ChallengeModel>>> getActiveChallenges() async {
    return await _apiService.getActiveChallenges();
  }
  // Get today challenges
  Future<ApiResult<List<ChallengeModel>>> getTodayChallenge() async {
    return await _apiService.getTodayChallenge();
  }

  // Get completed challenges
  Future<ApiResult<List<ChallengeModel>>> getCompletedChallenges() async {
    return await _apiService.getCompletedChallenges();
  }

  // Mark challenge as complete
  Future<ApiResult<bool>> markChallengeComplete(String challengeId) async {
    return await _apiService.markChallengeComplete(challengeId);
  }

  // Get daily puzzle
  Future<ApiResult<PuzzleModel>> getDailyPuzzle() async {
    final result = await _apiService.getDailyPuzzle();

    if (result.isSuccess) {
      return Success(result.data!.data.data);
    } else {
      return Failure(result.error!, statusCode: (result as Failure).statusCode);
    }
  }

  // Submit puzzle answer
  Future<ApiResult<PuzzleSubmissionResponse>> submitPuzzleAnswer({
    required String puzzleId,
    required int selectedAnswer,
  }) async {
    final request = SubmitPuzzleRequest(
      puzzleId: puzzleId,
      selectedAnswer: selectedAnswer,
    );

    return await _apiService.submitPuzzleAnswer(request);
  }
}
