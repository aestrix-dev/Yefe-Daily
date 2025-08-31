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
          print('📖 Using cached reflection: ${cachedReflection.reference}');
          return Success(cachedReflection);
        }
      }

      // Fetch from API
      print('🌐 Fetching fresh reflection from API...');
      final result = await _apiService.getDailyReflection();

      if (result.isSuccess) {
        final reflection = result.data!;

        // Cache the new reflection
        await _storageService.cacheReflection(reflection);
        print('💾 Cached new reflection: ${reflection.reference}');

        return Success(reflection);
      } else {
        // If API fails, try to return cached data as fallback
        final cachedReflection = await _storageService.getCachedReflection();

        if (cachedReflection != null) {
          print('📖 API failed, using cached reflection as fallback');
          return Success(cachedReflection);
        }

        return result;
      }
    } catch (e) {
      print('❌ Error in reflection repository: $e');

      // Try to return cached data as fallback
      final cachedReflection = await _storageService.getCachedReflection();

      if (cachedReflection != null) {
        print('📖 Error occurred, using cached reflection as fallback');
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
