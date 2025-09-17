import 'package:yefa/core/utils/api_result.dart';
import 'package:yefa/data/models/reflection_model.dart';
import 'package:yefa/data/services/base_api_service.dart';

class ReflectionApiService extends BaseApiService {
  // Get daily reflection
  Future<ApiResult<ReflectionModel>> getDailyReflection() async {
    try {
      print('📖 Getting daily reflection...');

      final response = await dioService.get('/v1/reflection');

      print('✅ Reflection Response: ${response.statusCode}');
      print('📥 Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final reflectionData = ReflectionModel.fromApiResponse(response.data);
        
        print('✅ Parsed reflection: ${reflectionData.reference}');
        return Success(reflectionData);
      } else {
        return Failure(
          'Failed to get daily reflection with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('❌ Reflection Error: $e');
      
      String errorMessage = 'Failed to get daily reflection';
      if (e.toString().contains('DioException')) {
        errorMessage = 'Network error occurred while fetching reflection';
      }

      return Failure(errorMessage);
    }
  }
}
