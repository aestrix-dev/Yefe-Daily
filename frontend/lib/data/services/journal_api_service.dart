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


      final response = await dioService.post(
        '/v1/journal/entries',
        data: request.toJson(),
      );

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

      return Failure('An unexpected error occurred: $e');
    }
  }

  // Get all journal entries (simple)
  Future<ApiResult<List<JournalModel>>> getJournalEntries() async {
    try {

      final response = await dioService.get('/v1/journal/entries');

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

      return Failure('An unexpected error occurred: $e');
    }
  }

  // Delete journal entry
  Future<ApiResult<bool>> deleteJournalEntry(String entryId) async {
    try {

      final response = await dioService.delete('/v1/journal/entries/$entryId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return Success(true);
      } else {
        return Failure(
          'Failed to delete journal entry with status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {

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
