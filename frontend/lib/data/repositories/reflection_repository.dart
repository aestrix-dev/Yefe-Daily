import 'package:yefa/core/utils/api_result.dart';
import 'package:yefa/data/models/reflection_model.dart';
import 'package:yefa/data/services/reflection_api_service.dart';
import 'package:yefa/data/services/storage_service.dart';
import 'package:yefa/data/services/cache/home_cache.dart';

class ReflectionRepository {
  final ReflectionApiService _apiService;
  final StorageService _storageService;

  ReflectionRepository(this._apiService, this._storageService);

  // Get daily reflection with caching
  Future<ApiResult<ReflectionModel>> getDailyReflection({
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedReflection = await _storageService.getCachedReflection();

        if (cachedReflection != null &&
            cachedReflection.isForToday &&
            cachedReflection.isFresh) {

          return Success(cachedReflection);
        }
      }

      // Fetch from API

      final result = await _apiService.getDailyReflection();

      if (result.isSuccess) {
        final reflection = result.data!;

        // Cache the new reflection
        await _storageService.cacheReflection(reflection);

        return Success(reflection);
      } else {
        // If API fails, try to return cached data as fallback
        final cachedReflection = await _storageService.getCachedReflection();

        if (cachedReflection != null) {

          return Success(cachedReflection);
        }

        return result;
      }
    } catch (e) {

      // Try to return cached data as fallback
      final cachedReflection = await _storageService.getCachedReflection();

      if (cachedReflection != null) {

        return Success(cachedReflection);
      }

      return Failure('Failed to get daily reflection: $e');
    }
  }

  // Clear cached reflection (useful for testing or manual refresh)
  Future<void> clearCache() async {
    await _storageService.clearReflectionCache();
  }
}
