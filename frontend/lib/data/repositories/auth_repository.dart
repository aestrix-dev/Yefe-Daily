// File: data/repositories/auth_repository.dart
import 'dart:convert';
import 'package:yefa/data/models/auth_model.dart';
import 'package:yefa/data/services/auth_service.dart';

import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../../core/utils/api_result.dart';
import '../../app/app_setup.dart';
import 'base_repository.dart';

class AuthRepository extends BaseRepository {
  final AuthApiService _apiService = locator<AuthApiService>();
  final StorageService _storageService = locator<StorageService>();

  // Storage keys 
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'current_user';
  static const String _tokenExpiryKey = 'token_expiry';

  // Register user 
  Future<ApiResult<RegisterResponse>> register(RegisterRequest request) async {
    final result = await handleApiResult(_apiService.register(request));

    if (result.isSuccess) {
      // Store all auth data
      await _storeAuthData(
        token: result.data!.data.token,
        user: result.data!.data.user,
      );
    }

    return result;
  }

  // Get current user from storage
  Future<UserModel?> getCurrentUser() async {
    final userJson = await _storageService.getString(_userKey);
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(userMap);
      } catch (e) {
        print('Error parsing stored user: $e');
        return null;
      }
    }
    return null;
  }

  // Get current token (for debugging or manual use)
  Future<String?> getCurrentToken() async {
    return await _storageService.getString(_tokenKey);
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storageService.getString(_refreshTokenKey);
  }

  // Check if token is expired (optional - for future use)
  Future<bool> isTokenExpired() async {
    final expiryString = await _storageService.getString(_tokenExpiryKey);
    if (expiryString != null) {
      final expiry = DateTime.parse(expiryString);
      return DateTime.now().isAfter(expiry);
    }
    return true; // Assume expired if no expiry date
  }

  // Check if user has valid auth data stored
  Future<bool> hasAuthData() async {
    final token = await getCurrentToken();
    final user = await getCurrentUser();
    return token != null && user != null;
  }

  // Private helper method to store all auth data
  Future<void> _storeAuthData({
    required TokenData token,
    required UserModel user,
  }) async {
    // Calculate token expiry time
    final expiryTime = DateTime.now().add(Duration(seconds: token.expiresIn));

    await Future.wait([
      // Store the access token (this is what your interceptor reads)
      _storageService.setString(_tokenKey, token.accessToken),
      // Store refresh token for future use
      _storageService.setString(_refreshTokenKey, token.refreshToken),
      // Store user data as JSON string
      _storageService.setString(_userKey, jsonEncode(user.toJson())),
      // Store token expiry time
      _storageService.setString(_tokenExpiryKey, expiryTime.toIso8601String()),
    ]);

    print('✅ Auth data stored successfully');
    print('🔑 Token: ${token.accessToken.substring(0, 20)}...');
    print('👤 User: ${user.name} (${user.email})');
  }
}
