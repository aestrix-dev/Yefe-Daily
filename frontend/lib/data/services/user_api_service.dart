import '../models/user_model.dart';
import '../../core/utils/api_result.dart';
import 'base_api_service.dart';

class UserApiService extends BaseApiService {
  // Get user profile
  Future<ApiResult<UserModel>> getUserProfile() async {
    return safeApiCall(
      () => dioService.get('/user/profile'),
      (json) => UserModel.fromJson(json),
    );
  }

  // Update user profile
  Future<ApiResult<UserModel>> updateUserProfile(
    Map<String, dynamic> data,
  ) async {
    return safeApiCall(
      () => dioService.put('/user/profile', data: data),
      (json) => UserModel.fromJson(json),
    );
  }

  // Upgrade to premium
  Future<ApiResult<bool>> upgradeToPremium() async {
    return safeApiCallBool(() => dioService.post('/user/upgrade-premium'));
  }
}
