import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'storage_service.dart';
import '../../app/app_setup.dart';

class DioService {
  static const String baseUrl = 'https://yefe-backend.onrender.com/';

  late Dio _dio;
  final _storageService = locator<StorageService>();

  DioService() {
    _dio = Dio();
    _setupDio();
  }

  void _setupDio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Add interceptors
    _dio.interceptors.addAll([
      _AuthInterceptor(_storageService),
      _ErrorInterceptor(),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    ]);
  }

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  // PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Upload file
  Future<Response> uploadFile(
    String path,
    String filePath, {
    String? fileName,
    Map<String, dynamic>? data,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        if (data != null) ...data,
      });

      return await _dio.post(path, data: formData);
    } catch (e) {
      rethrow;
    }
  }
}

// Auth Interceptor - Adds token to requests
class _AuthInterceptor extends Interceptor {
  final StorageService _storageService;

  _AuthInterceptor(this._storageService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _storageService.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

// Error Interceptor - Handles API errors
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Log for debugging (only in debug mode)
    if (kDebugMode) {
      print('🔴 API Error: ${err.type} - ${err.response?.statusCode ?? 'No status'}');
    }

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw ApiException('Connection timeout');

      case DioExceptionType.badResponse:
        _handleStatusError(err);
        break;

      case DioExceptionType.cancel:
        throw ApiException('Request cancelled');

      case DioExceptionType.unknown:
        if (err.message?.contains('SocketException') == true ||
            err.message?.contains('Network is unreachable') == true ||
            err.message?.contains('Failed host lookup') == true) {
          throw ApiException('No internet connection');
        }
        throw ApiException('Network error');

      default:
        throw ApiException('Network error');
    }

    handler.next(err);
  }

  void _handleStatusError(DioException err) {
    // Try to get custom error message from server response
    String? serverMessage = _extractServerErrorMessage(err.response?.data);

    switch (err.response?.statusCode) {
      case 400:
        throw ApiException(serverMessage ?? 'Invalid request');
      case 401:
        throw ApiException('Please login again');
      case 403:
        throw ApiException('Access denied');
      case 404:
        throw ApiException('Not found');
      case 422:
        throw ApiException(serverMessage ?? 'Validation failed');
      case 429:
        throw ApiException('Too many requests');
      case 500:
        throw ApiException('Server error');
      case 502:
      case 503:
      case 504:
        throw ApiException('Service unavailable');
      default:
        if (err.response?.statusCode != null && err.response!.statusCode! >= 500) {
          throw ApiException('Server error');
        } else {
          throw ApiException(serverMessage ?? 'Request failed');
        }
    }
  }

  // Extract error message from server response if available
  String? _extractServerErrorMessage(dynamic responseData) {
    try {
      if (responseData is Map<String, dynamic>) {
        // Common error message fields
        return responseData['message'] ??
               responseData['error'] ??
               responseData['detail'] ??
               responseData['msg'];
      } else if (responseData is String) {
        return responseData.length > 100 ? null : responseData; // Avoid long strings
      }
    } catch (e) {
      // Ignore extraction errors
    }
    return null;
  }
}

// Custom API Exception
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}
