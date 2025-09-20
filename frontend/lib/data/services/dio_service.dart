import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'storage_service.dart';
import '../../app/app_setup.dart';

class DioService {
  static const String baseUrl = 'https://yefe-backend.onrender.com/';
  // static const String baseUrl = 'https://adapted-kindly-perch.ngrok-free.app/';

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
    final int? statusCode = err.response?.statusCode;
    String? serverMessage = _extractServerErrorMessage(err.response?.data);

    if (statusCode == null) {
      throw ApiException('Network error - no response');
    }

    // Handle 5xx Server Errors
    if (statusCode >= 500) {
      throw ApiException('Server error. Please try again later.');
    }

    // Handle 4xx Client Errors
    if (statusCode >= 400 && statusCode < 500) {
      switch (statusCode) {
        case 400:
          throw ApiException(serverMessage ?? 'Bad request. Please check your input.');
        case 401:
          throw ApiException('Authentication required. Please login again.');
        case 403:
          throw ApiException(serverMessage ?? 'Access denied. You don\'t have permission.');
        case 404:
          throw ApiException('Resource not found.');
        case 405:
          throw ApiException('Method not allowed.');
        case 408:
          throw ApiException('Request timeout. Please try again.');
        case 409:
          throw ApiException(serverMessage ?? 'Conflict. Resource already exists.');
        case 410:
          throw ApiException('Resource no longer available.');
        case 413:
          throw ApiException('Request too large. Please reduce file size.');
        case 422:
          throw ApiException(serverMessage ?? 'Validation failed. Please check your input.');
        case 429:
          throw ApiException('Too many requests. Please wait and try again.');
        case 431:
          throw ApiException('Request header fields too large.');
        case 451:
          throw ApiException('Unavailable for legal reasons.');
        default:
          throw ApiException(serverMessage ?? 'Client error ($statusCode). Please check your request.');
      }
    }

    // Handle 3xx Redirects (shouldn't normally reach here)
    if (statusCode >= 300 && statusCode < 400) {
      throw ApiException('Redirect error ($statusCode). Please contact support.');
    }

    // Handle 2xx Success (shouldn't reach here)
    if (statusCode >= 200 && statusCode < 300) {
      throw ApiException('Unexpected success status in error handler ($statusCode).');
    }

    // Handle any other status codes
    throw ApiException('HTTP error ($statusCode). Please try again.');
  }

  // Extract error message from server response if available
  String? _extractServerErrorMessage(dynamic responseData) {
    try {
      if (responseData is Map<String, dynamic>) {
        // Common error message fields - try multiple variations
        return responseData['message'] ??
               responseData['error'] ??
               responseData['detail'] ??
               responseData['msg'] ??
               responseData['errorMessage'] ??
               responseData['description'] ??
               responseData['reason'];
      } else if (responseData is String) {
        // Clean up the string - remove "Error: " prefix if present
        String cleanMessage = responseData.trim();
        if (cleanMessage.startsWith('Error: ')) {
          cleanMessage = cleanMessage.substring(7);
        }
        return cleanMessage.length > 100 ? null : cleanMessage;
      }
    } catch (e) {
      // Log the error for debugging
      if (kDebugMode) {

      }
    }
    return null;
  }
}

// Custom API Exception
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() {
    // Ensure we never expose technical details to users
    String cleanMessage = message;

    // Remove any DioException prefixes
    if (cleanMessage.contains('DioException')) {
      // Extract only the meaningful part after the last colon
      final parts = cleanMessage.split(':');
      if (parts.length > 1) {
        cleanMessage = parts.last.trim();
      }
    }

    // Remove "Error: " prefix if present
    if (cleanMessage.startsWith('Error: ')) {
      cleanMessage = cleanMessage.substring(7);
    }

    return cleanMessage;
  }
}
