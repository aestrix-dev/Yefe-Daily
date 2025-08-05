import '../services/user_api_service.dart';
import '../models/user_model.dart';
import '../../core/utils/api_result.dart';
import '../../app/app_setup.dart';
import 'base_repository.dart';

class UserRepository extends BaseRepository {
  final UserApiService _apiService = locator<UserApiService>();

  Future<ApiResult<UserModel>> getUserProfile() async {
    return handleApiResult(_apiService.getUserProfile());
  }

  Future<ApiResult<UserModel>> updateUserProfile(
    Map<String, dynamic> data,
  ) async {
    return handleApiResult(_apiService.updateUserProfile(data));
  }

  Future<ApiResult<bool>> upgradeToPremium() async {
    return handleApiResult(_apiService.upgradeToPremium());
  }

}
