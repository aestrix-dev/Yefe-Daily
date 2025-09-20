
import 'package:yefa/app/app_setup.dart';
import 'package:yefa/data/models/auth_model.dart';
import 'package:yefa/data/services/storage_service.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/api_result.dart';
import 'base_api_service.dart';

class AuthApiService extends BaseApiService {
  // Single register endpoint that handles both registration and login
  Future<ApiResult<RegisterResponse>> register(RegisterRequest request) async {
    if (kDebugMode) {

    }

    final result = await safeApiCall<RegisterResponse>(
      () => dioService.post('v1/auth/register', data: request.toJson()),
      (json) => RegisterResponse.fromJson(json),
    );

    // Save user data on successful registration
    if (result.isSuccess) {
      final user = result.data!.data.user;
      await locator<StorageService>().saveUser(user);
      if (kDebugMode) {

      }
    }

    return result;
  }

  // Accept notifications by sending FCM token to server
  Future<ApiResult<AcceptNotificationResponse>> acceptNotifications(AcceptNotificationRequest request) async {
    if (kDebugMode) {

    }

    return await safeApiCall<AcceptNotificationResponse>(
      () => dioService.post('v1/auth/accept', data: request.toJson()),
      (json) => AcceptNotificationResponse.fromJson(json),
    );
  }
}

