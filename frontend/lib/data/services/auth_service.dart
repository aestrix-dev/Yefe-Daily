
import 'package:dio/dio.dart';
import 'package:yefa/data/models/auth_model.dart';

import '../../core/utils/api_result.dart';
import 'base_api_service.dart';

class AuthApiService extends BaseApiService {
  // Single register endpoint that handles both registration and login
  Future<ApiResult<RegisterResponse>> register(RegisterRequest request) async {
    try {
      print('🔍 AuthApiService: Starting registration request');
      print('📤 Request Data: ${request.toJson()}');

      // Make the API call with detailed logging
      final response = await dioService.post(
        'v1/auth/register',
        data: request.toJson(),
      );

      print('✅ Response Status: ${response.statusCode}');
      print('📥 Response Data: ${response.data}');

      // Parse the response
      final registerResponse = RegisterResponse.fromJson(response.data);
      return Success(registerResponse);
    } catch (e) {
      print('❌ AuthApiService Error: $e');
      if (e is DioException) {
        print('🔍 DioException Details:');
        print('   - Type: ${e.type}');
        print('   - Message: ${e.message}');
        print('   - Response Status: ${e.response?.statusCode}');
        print('   - Response Data: ${e.response?.data}');
        print('   - Request Path: ${e.requestOptions.path}');
        print('   - Request Data: ${e.requestOptions.data}');
        print('   - Request Headers: ${e.requestOptions.headers}');
      }
      return Failure('Registration failed: $e');
    }
  }
}

