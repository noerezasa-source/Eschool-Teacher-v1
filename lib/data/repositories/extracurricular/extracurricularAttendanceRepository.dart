import 'package:eschool_saas_staff/data/models/extracurricular/extracurricularAttendance.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:eschool_saas_staff/utils/system/dateFormatter.dart';
import 'package:eschool_saas_staff/utils/system/hiveBoxKeys.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

class ExtracurricularAttendanceRepository {
  // Get attendance data for extracurricular
  Future<ExtracurricularAttendanceResponse> getExtracurricularAttendance({
    required int attendanceId,
    int? extracurricularId,
    String? date,
  }) async {
    try {
      debugPrint('🔍 [ATTENDANCE REPO] Getting attendance for ID: $attendanceId');

      // Build query parameters
      Map<String, dynamic> queryParams = {};
      if (extracurricularId != null) {
        queryParams['ekstrakurikuler_id'] = extracurricularId.toString();
      }
      if (date != null) {
        queryParams['date'] = date;
      }

      debugPrint('🔍 [ATTENDANCE REPO] Query params: $queryParams');

      final response = await Api.get(
        url: Api.getExtracurricularAttendance
            .replaceAll('{id}', attendanceId.toString()),
        useAuthToken: true,
        queryParameters: queryParams,
      );

      debugPrint('🔍 [ATTENDANCE REPO] Response: $response');

      if (response['error'] == false || response['success'] == true) {
        debugPrint('🔍 [ATTENDANCE REPO] Parsing response with fromJson...');
        final attendanceResponse =
            ExtracurricularAttendanceResponse.fromJson(response);
        debugPrint(
            '✅ [ATTENDANCE REPO] Successfully parsed ${attendanceResponse.members.length} members');

        // Debug: Print first few members
        if (attendanceResponse.members.isNotEmpty) {
          debugPrint(
              '🔍 [ATTENDANCE REPO] First member: ${attendanceResponse.members.first.toString()}');
        }

        return attendanceResponse;
      } else {
        throw Exception(response['message'] ?? 'Failed to get attendance data');
      }
    } catch (e) {
      debugPrint('❌ [ATTENDANCE REPO] Error getting attendance: $e');
      throw Exception('Failed to get attendance data: $e');
    }
  }

  // Save attendance data for extracurricular
  Future<ExtracurricularAttendanceSaveResponse> saveExtracurricularAttendance({
    required int sessionId,
    required ExtracurricularAttendanceRequest request,
  }) async {
    try {
      debugPrint('🔍 [ATTENDANCE REPO] Saving attendance for session: $sessionId');
      debugPrint('🔍 [ATTENDANCE REPO] Request body: ${request.toJson()}');

      // Log authentication info before making request
      final authBox = Hive.box(authBoxKey);
      final token = authBox.get(authTokenKey);
      final schoolCode = authBox.get('schoolCode'); // Match AuthRepository key
      debugPrint(
          '🔑 [ATTENDANCE REPO] Auth Token: ${token != null ? "Bearer $token" : "NO TOKEN"}');
      debugPrint(
          '🏫 [ATTENDANCE REPO] School Code: ${schoolCode ?? "NO SCHOOL CODE"}');

      // Validate request data
      if (request.attendanceData.isEmpty) {
        throw ArgumentError('Attendance data is empty');
      }

      // Validate date format
      if (!DateFormatter.isValidGetRequestDateFormat(request.date)) {
        throw ArgumentError(
            'Invalid date format: ${request.date}. Expected DD-MM-YYYY');
      }

      // Validate all attendance data
      for (final data in request.attendanceData) {
        if (!data.isValid()) {
          throw ArgumentError('Invalid attendance data: ${data.toString()}');
        }
      }

      final response = await Api.post(
        url: Api.saveExtracurricularAttendance
            .replaceAll('{id}', request.extracurricularId.toString()),
        body: request.toJson(),
        useAuthToken: true,
      );

      debugPrint('🔍 [ATTENDANCE REPO] Save response: $response');

      // Check if request was successful
      if (response['error'] == false) {
        // Create save response manually since API doesn't return savedCount
        final saveResponse = ExtracurricularAttendanceSaveResponse(
          success: true,
          message: response['message'] ?? 'Absensi berhasil disimpan',
          savedCount: request.attendanceData.length,
        );

        debugPrint(
            '✅ [ATTENDANCE REPO] Successfully saved ${request.attendanceData.length} attendance records');
        return saveResponse;
      } else {
        final errorMessage = response['message'] ?? 'Gagal menyimpan absensi';
        final errorCode = response['code'];

        // Handle specific error codes
        if (errorCode == 103) {
          throw Exception(
              'Format tanggal tidak valid. Pastikan menggunakan format YYYY-MM-DD');
        }

        debugPrint(
            '❌ [ATTENDANCE REPO] API returned error: $errorMessage (code: $errorCode)');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ [ATTENDANCE REPO] Error saving attendance: $e');

      // Provide user-friendly error messages
      if (e.toString().contains('Carbon')) {
        throw Exception('Format tanggal tidak valid. Silakan coba lagi.');
      }

      rethrow;
    }
  }

  // Get extracurricular list for dropdown/filter
  Future<List<Map<String, dynamic>>> getExtracurricularList() async {
    try {
      debugPrint('🔍 [ATTENDANCE REPO] Getting extracurricular list');

      final response = await Api.get(
        url: Api.getExtracurriculars,
        useAuthToken: true,
      );

      debugPrint('🔍 [ATTENDANCE REPO] Extracurricular list response: $response');

      // Handle different response structures
      List<dynamic> data = [];

      if (response['error'] == false || response['success'] == true) {
        // Try different possible data locations
        final rawData = response['data'] ?? response['rows'] ?? [];
        if (rawData is List) {
          data = rawData;
        } else {
          debugPrint(
              '⚠️ [ATTENDANCE REPO] Expected List but got: ${rawData.runtimeType}');
          data = [];
        }
      } else {
        throw Exception(
            response['message'] ?? 'Failed to get extracurricular list');
      }

      final List<Map<String, dynamic>> extracurriculars = data
          .map((item) => {
                'id': item['id'],
                'name':
                    item['name'] ?? item['title'] ?? item['nama'] ?? 'Unknown',
                'description': item['description'] ?? item['deskripsi'] ?? '',
              })
          .toList();

      debugPrint(
          '✅ [ATTENDANCE REPO] Successfully fetched ${extracurriculars.length} extracurriculars');
      debugPrint('✅ [ATTENDANCE REPO] Extracurriculars: $extracurriculars');
      return extracurriculars;
    } catch (e) {
      debugPrint('❌ [ATTENDANCE REPO] Error getting extracurricular list: $e');
      throw Exception('Failed to get extracurricular list: $e');
    }
  }

  // Get staff info for session ID (if needed)
  Future<Map<String, dynamic>> getStaffInfo() async {
    try {
      final authBox = Hive.box(authBoxKey);
      final staffData = authBox.get(userDetailsKey);

      if (staffData != null) {
        return {
          'id': staffData['id'],
          'name': staffData['full_name'] ?? staffData['name'],
          'email': staffData['email'],
        };
      } else {
        throw Exception('Staff data not found');
      }
    } catch (e) {
      debugPrint('❌ [ATTENDANCE REPO] Error getting staff info: $e');
      throw Exception('Failed to get staff info: $e');
    }
  }

  // Helper method to format date for API using DateFormatter (YYYY-MM-DD format for POST)
  String formatDateForApi(DateTime date) {
    return DateFormatter.toApiFormat(date);
  }

  // Helper method to format date for GET request (DD-MM-YYYY format)
  String formatDateForGetRequest(DateTime date) {
    return DateFormatter.toGetRequestFormat(date);
  }

  // Helper method to parse date from API using DateFormatter
  DateTime? parseDateFromApi(String? dateString) {
    return DateFormatter.fromApiFormat(dateString);
  }

  // Get attendance history for a specific extracurricular and date range
  Future<List<ExtracurricularAttendance>> getAttendanceHistory({
    required int extracurricularId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint(
          '🔍 [ATTENDANCE REPO] Getting attendance history for extracurricular: $extracurricularId');

      Map<String, dynamic> queryParams = {
        'ekstrakurikuler_id': extracurricularId.toString(),
      };

      if (startDate != null) {
        queryParams['start_date'] = formatDateForGetRequest(startDate);
      }
      if (endDate != null) {
        queryParams['end_date'] = formatDateForGetRequest(endDate);
      }

      // Note: This endpoint might need to be adjusted based on actual backend implementation
      final response = await Api.get(
        url: Api.getExtracurricularAttendanceHistory,
        useAuthToken: true,
        queryParameters: queryParams,
      );

      debugPrint('🔍 [ATTENDANCE REPO] History response: $response');

      if (response['error'] == false) {
        final List<dynamic> data = response['data'] ?? [];
        final List<ExtracurricularAttendance> attendanceList = data
            .map((item) => ExtracurricularAttendance.fromJson(item))
            .toList();

        debugPrint(
            '✅ [ATTENDANCE REPO] Successfully fetched ${attendanceList.length} attendance records');
        return attendanceList;
      } else {
        throw Exception(
            response['message'] ?? 'Failed to get attendance history');
      }
    } catch (e) {
      debugPrint('❌ [ATTENDANCE REPO] Error getting attendance history: $e');
      throw Exception('Failed to get attendance history: $e');
    }
  }
}
