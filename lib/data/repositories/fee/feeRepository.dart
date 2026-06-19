import 'dart:convert';
import 'package:eschool_saas_staff/data/models/fee/fee.dart';
import 'package:eschool_saas_staff/data/models/student/studentDetails.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:flutter/foundation.dart';

class FeeRepository {
  Future<List<Fee>> getFees() async {
    try {
      final result = await Api.get(url: Api.getFees);

      if (result.containsKey('data') && result['data'] is List) {
        return (result['data'] as List)
            .map((fee) => Fee.fromJson(Map<String, dynamic>.from(fee ?? {})))
            .toList();
      }

      // Return empty list if data is not in the expected format
      debugPrint("Unexpected API response format in getFees: ${result.keys}");
      return [];
    } catch (e) {
      debugPrint("Error in getFees: $e");
      throw ApiException(e.toString());
    }
  }

  Future<
          ({
            List<StudentDetails> students,
            int currentPage,
            int totalPage,
            double compolsoryFeeAmount,
            double optionalFeeAmount,
            // New fields for metadata
            String feesType,
            String className,
            double totalAmount,
            String dueDate,
            int totalStudents,
            int paidStudents,
            int unpaidStudents,
          })>
      getStudentsFeePaymentStatus(
          {required int sessionYearId,
          required int status,
          required int feeId,
          String? search,
          int? page}) async {
    try {
      final Map<String, dynamic> queryParams = {
        "page": page ?? 1,
        "fees_id": feeId,
        "status": status
      };

      // Add optional parameters if provided
      if (sessionYearId > 0) {
        queryParams["session_year_id"] = sessionYearId;
      }

      if (search != null && search.isNotEmpty) {
        queryParams["search"] = search;
      }

      final result = await Api.get(
          url: Api.getStudentsFeeStatus, queryParameters: queryParams);

      // Debug: Print the structure of the response
      debugPrint("API Response Structure: ${result.keys}");
      if (result.containsKey('data')) {
        debugPrint(
            "Data Structure: ${result['data'] is Map ? 'Map' : (result['data'] is List ? 'List' : 'Other')}");
        if (result['data'] is Map && result['data'].containsKey('data')) {
          debugPrint(
              "Data.data Structure: ${result['data']['data'] is Map ? 'Map' : (result['data']['data'] is List ? 'List' : 'Other')}");
          if (result['data']['data'] is Map) {
            debugPrint(
                "Data.data Keys: ${(result['data']['data'] as Map).keys.take(5).join(', ')}...");
          }
        }
      }

      // Parse meta information from the new API structure
      Map<String, dynamic> meta = {};
      Map<String, dynamic> statistics = {};

      try {
        if (result.containsKey('meta')) {
          if (result['meta'] is Map) {
            meta = Map<String, dynamic>.from(result['meta']);

            if (meta.containsKey('statistics') && meta['statistics'] is Map) {
              statistics = Map<String, dynamic>.from(meta['statistics']);
            }
          }
        }
      } catch (e) {
        debugPrint("Error parsing meta information: $e");
        // Continue with default values if meta parsing fails
      }

      // Safely extract student data
      List<StudentDetails> students = [];
      try {
        if (result.containsKey('data') &&
            result['data'] is Map &&
            result['data'].containsKey('data')) {
          final dataList = result['data']['data'];

          // Case 1: dataList is a List (original format)
          if (dataList is List) {
            debugPrint("API returned List for student data");
            students = dataList
                .map((studentDetails) {
                  try {
                    return StudentDetails.fromJson(
                        Map<String, dynamic>.from(studentDetails ?? {}));
                  } catch (e) {
                    debugPrint("Error parsing individual student: $e");
                    return null;
                  }
                })
                .where((student) => student != null)
                .cast<StudentDetails>()
                .toList();
          }
          // Case 2: dataList is a Map with numeric keys (new format from API)
          else if (dataList is Map) {
            debugPrint("API returned Map instead of List for student data");
            debugPrint("Map keys: ${dataList.keys.take(5).join(', ')}");

            // Convert Map values to a list
            final values = dataList.values.toList();
            if (values.isNotEmpty) {
              students = values
                  .map((studentDetails) {
                    try {
                      if (studentDetails is Map) {
                        return StudentDetails.fromJson(
                            Map<String, dynamic>.from(studentDetails));
                      } else {
                        debugPrint(
                            "Invalid student data type: ${studentDetails.runtimeType}");
                        return null;
                      }
                    } catch (e) {
                      debugPrint("Error parsing individual student: $e");
                      return null;
                    }
                  })
                  .where((student) => student != null)
                  .cast<StudentDetails>()
                  .toList();
            }
          } else {
            debugPrint("Unexpected data type for students: ${dataList.runtimeType}");
          }
        } else {
          debugPrint("Invalid API response structure: missing 'data.data'");
          if (result.containsKey('data')) {
            debugPrint("'data' is type: ${result['data'].runtimeType}");
          }
        }

        debugPrint("Successfully parsed ${students.length} students");
      } catch (e) {
        debugPrint("Error parsing student data: $e");
        // Continue with empty list if student data parsing fails
      }

      return (
        students: students, // Use the safely extracted students list
        currentPage: result['data']?['current_page'] is int
            ? result['data']['current_page'] as int
            : int.tryParse(result['data']?['current_page']?.toString() ?? '') ??
                1,
        totalPage: result['data']?['last_page'] is int
            ? result['data']['last_page'] as int
            : int.tryParse(result['data']?['last_page']?.toString() ?? '') ?? 1,

        // Old fields with fallback to existing ones for backward compatibility
        compolsoryFeeAmount: double.parse(
            (result['compolsory_fees'] ?? meta['total_amount'] ?? 0.0)
                .toString()),
        optionalFeeAmount:
            double.parse((result['optional_fees'] ?? 0.0).toString()),

        // New metadata fields
        feesType: meta['fees_type'] as String? ?? "",
        className: meta['class_name'] as String? ?? "",
        totalAmount: double.parse((meta['total_amount'] ?? 0.0).toString()),
        dueDate: meta['due_date'] as String? ?? "",
        totalStudents: statistics['total_students'] is int
            ? statistics['total_students'] as int
            : int.tryParse(statistics['total_students']?.toString() ?? '') ?? 0,
        paidStudents: statistics['paid_students'] is int
            ? statistics['paid_students'] as int
            : int.tryParse(statistics['paid_students']?.toString() ?? '') ?? 0,
        unpaidStudents: statistics['unpaid_students'] is int
            ? statistics['unpaid_students'] as int
            : int.tryParse(statistics['unpaid_students']?.toString() ?? '') ??
                0,
      );
    } catch (e) {
      debugPrint("Error in getStudentsFeePaymentStatus: $e");
      throw ApiException(e.toString());
    }
  }

  Future<String> downloadStudentFeeReceipt({
    required List<int> paymentHistoryIds,
  }) async {
    try {
      // Validate that at least one payment ID is provided
      if (paymentHistoryIds.isEmpty) {
        debugPrint("Error: No payment records selected");
        throw ApiException("No payment records selected");
      }

      debugPrint("===== DOWNLOADING FEE RECEIPT =====");
      debugPrint("Payment History IDs: $paymentHistoryIds");

      // Convert the list of IDs to the correct format for API
      // The API expects payment_history_id[0], payment_history_id[1], etc format
      final Map<String, dynamic> params = {};
      for (int i = 0; i < paymentHistoryIds.length; i++) {
        params['payment_history_id[$i]'] = paymentHistoryIds[i].toString();
      }

      debugPrint("Request Parameters: $params");

      // Make the API request with payment history IDs
      final result = await Api.get(
        url: Api.downloadStudentFeeReceipt,
        queryParameters: params,
      );

      // Use centralized helper for PDF (Support pdf_url)
      final bytes = await Api.fetchDocumentBytes(result);
      return base64Encode(bytes);
    } catch (e) {
      debugPrint("Error in downloadStudentFeeReceipt: $e");
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(e.toString());
    }
  }
}

