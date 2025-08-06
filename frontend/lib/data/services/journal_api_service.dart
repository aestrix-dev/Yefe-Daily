import 'package:dio/dio.dart';
import '../models/journal_model.dart';
import '../models/journal_request.dart';
import '../models/journal_response.dart';
import '../../core/utils/api_result.dart';
import 'base_api_service.dart';

class JournalApiService extends BaseApiService {
  // Create new journal entry
  Future<ApiResult<JournalResponse>> createJournalEntry(
    CreateJournalRequest request,
  ) async {
    try {
      print('📝 Creating journal entry...');
      print('📤 Request: ${request.toJson()}');

      final response = await dioService.post(
        '/v1/journal/entries',
        data: request.toJson(),
      );

      print('✅ Create Response: ${response.statusCode}');
      print('📥 Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final journalResponse = JournalResponse.fromJson(response.data);
        return Success(journalResponse);
      } else {
        return Failure(
          'Failed to create journal entry with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('❌ Create Journal Error: ${e.message}');
      print('📍 Status: ${e.response?.statusCode}');
      print('📦 Response: ${e.response?.data}');

      String errorMessage = 'Failed to create journal entry';
      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage =
              responseData['message'] ?? responseData['error'] ?? errorMessage;
        }
      }

      return Failure(errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {
      print('❌ General Error in createJournalEntry: $e');
      return Failure('An unexpected error occurred: $e');
    }
  }

  // Get all journal entries (simple)
  Future<ApiResult<List<JournalModel>>> getJournalEntries() async {
    try {
      print('📖 Getting all journal entries...');

      final response = await dioService.get('/v1/journal/entries');

      print('✅ Get Entries Response: ${response.statusCode}');
      print('📥 Response Data: ${response.data}');

      if (response.statusCode == 200) {
        // Handle different response structures
        List<dynamic> entriesData;

        if (response.data is Map<String, dynamic>) {
          // If response has structure like {data: [...], success: true}
          final responseMap = response.data as Map<String, dynamic>;
          entriesData = responseMap['entries'] as List<dynamic>? ?? [];
        } else if (response.data is List) {
          // If response is directly an array
          entriesData = response.data as List<dynamic>;
        } else {
          return Failure('Invalid response format');
        }

        final journalEntries = entriesData
            .map((item) => JournalModel.fromJson(item as Map<String, dynamic>))
            .toList();

        return Success(journalEntries);
      } else {
        return Failure(
          'Failed to get journal entries with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('❌ Get Entries Error: ${e.message}');

      String errorMessage = 'Failed to get journal entries';
      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage =
              responseData['message'] ?? responseData['error'] ?? errorMessage;
        }
      }

      return Failure(errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {
      print('❌ General Error in getJournalEntries: $e');
      return Failure('An unexpected error occurred: $e');
    }
  }

  // Delete journal entry
  Future<ApiResult<bool>> deleteJournalEntry(String entryId) async {
    try {
      print('🗑️ Deleting journal entry: $entryId');

      final response = await dioService.delete('/v1/journal/entries/$entryId');

      print('✅ Delete Response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return Success(true);
      } else {
        return Failure(
          'Failed to delete journal entry with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('❌ Delete Entry Error: ${e.message}');

      String errorMessage = 'Failed to delete journal entry';
      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage =
              responseData['message'] ?? responseData['error'] ?? errorMessage;
        }
      }

      return Failure(errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }
}
