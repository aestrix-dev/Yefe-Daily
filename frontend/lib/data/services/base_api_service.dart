// ignore_for_file: unused_field

import 'package:dio/dio.dart';
import 'package:yefa/data/services/dio_service.dart';
import '../../core/utils/api_result.dart';
import '../../app/app_setup.dart';

abstract class BaseApiService {
  final DioService dioService = locator<DioService>();

  // Protected method for safe API calls
  Future<ApiResult<T>> safeApiCall<T>(
    Future<Response> Function() apiCall,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await apiCall();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = fromJson(response.data);
        return Success(data);
      } else {
        return Failure('Request failed with status: ${response.statusCode}');
      }
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Unexpected error occurred: ${e.toString()}');
    }
  }

  // For API calls that return a list
  Future<ApiResult<List<T>>> safeApiCallList<T>(
    Future<Response> Function() apiCall,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await apiCall();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> jsonList = response.data['data'] ?? response.data;
        final List<T> dataList = jsonList
            .map((json) => fromJson(json as Map<String, dynamic>))
            .toList();
        return Success(dataList);
      } else {
        return Failure('Request failed with status: ${response.statusCode}');
      }
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Unexpected error occurred: ${e.toString()}');
    }
  }

  // For simple API calls without data transformation
  Future<ApiResult<Map<String, dynamic>>> safeApiCallRaw(
    Future<Response> Function() apiCall,
  ) async {
    try {
      final response = await apiCall();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(response.data);
      } else {
        return Failure('Request failed with status: ${response.statusCode}');
      }
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Unexpected error occurred: ${e.toString()}');
    }
  }

  // For API calls that don't return data (like delete operations)
  Future<ApiResult<bool>> safeApiCallBool(
    Future<Response> Function() apiCall,
  ) async {
    try {
      final response = await apiCall();

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        return const Success(true);
      } else {
        return Failure('Request failed with status: ${response.statusCode}');
      }
    } on ApiException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('Unexpected error occurred: ${e.toString()}');
    }
  }
}
