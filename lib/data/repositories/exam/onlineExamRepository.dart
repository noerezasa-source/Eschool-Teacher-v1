import 'dart:convert';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:eschool_saas_staff/data/models/exam/questionOnlineExam.dart';
import 'package:eschool_saas_staff/data/models/exam/BankOnlineQuestion.dart'; // Update this importimport 'package:eschool_saas_staff/data/models/bankSoalQuestion.dart';import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class OnlineExamRepository {
  Future<Map<String, dynamic>> getOnlineExams(
      {String? search,
      int? subjectId,
      dynamic archive = false,
      int? classSectionId,
      int? sessionYearId,
      String? status,
      DateTime? startDate,
      DateTime? endDate,
      int offset = 0,
      int limit = 50,
      bool? modeAll = false}) async {
    try {
      final queryParameters = {
        'offset': offset.toString(),
        'limit': limit.toString(),
        'sort': 'id',
        'order': 'DESC',
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (search != null && search.isNotEmpty) 'search': search,
        if (subjectId != null) 'class_subject_id': subjectId.toString(),
        if (classSectionId != null)
          'class_section_id': classSectionId.toString(),
        if (sessionYearId != null) 'session_year_id': sessionYearId.toString(),
        'type': 'all',
        if (modeAll == true)
          'mode':
              'all', // Tambahkan parameter mode=all untuk menampilkan semua kelas
        if (archive == true || archive == 1 || archive == '1') 'archive': 1,
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final response = await Api.get(
        url: Api.getOnlineExamList,
        useAuthToken: true,
        queryParameters: queryParameters,
      );

      debugPrint('=== [DIAGNOSTIK RAW] START ===');
      debugPrint('RAW Response Type: ${response.runtimeType}');
      debugPrint('RAW Response Keys: ${response.keys.toList()}');
      if (response['data'] != null) {
        debugPrint('Data Type: ${response['data'].runtimeType}');
        if (response['data'] is Map) {
          debugPrint('Data Keys: ${response['data'].keys.toList()}');
        }
      }
      debugPrint('=== [DIAGNOSTIK RAW] END ===');

      // Ultra-robust data extraction
      List<dynamic> examsData = [];
      List<dynamic> subjectDetails = [];

      final dynamic rawData = response['data'];

      if (rawData is List) {
        examsData = rawData;
      } else if (rawData is Map) {
        // Check for 'rows' first (common in some modules)
        if (rawData.containsKey('rows') && rawData['rows'] is List) {
          examsData = rawData['rows'];
        }
        // Check for nested 'data' (common in Laravel pagination)
        else if (rawData.containsKey('data') && rawData['data'] is List) {
          examsData = rawData['data'];
        }

        // Extract subject details if present in the map
        subjectDetails = rawData['subjectDetails'] ?? [];
      }

      // If subjectDetails still empty, check at the root of response
      if (subjectDetails.isEmpty) {
        subjectDetails = response['subjectDetails'] ?? [];
      }

      debugPrint(
          'DEBUG: Extracted ${examsData.length} exams from API response');

      return {
        'exams': examsData,
        'subjectDetails': subjectDetails,
      };
    } catch (e) {
      debugPrint("Repository Error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOnlineExamResultAnswer({
    required int onlineExamId,
    required int questionId,
    String? search,
  }) async {
    try {
      // Convert null search to empty string to avoid 'null' in URL
      final searchQuery = search ?? '';

      final response = await Api.get(
        url: Api.getOnlineExamAnswerCorrection,
        useAuthToken: true,
        queryParameters: {
          'online_exam_id': onlineExamId,
          'question_id': questionId,
          'search': searchQuery,
        },
      );

      debugPrint("===");
      var encoder = const JsonEncoder.withIndent("  "); // Indentasi 2 spasi
      String prettyJson = encoder.convert(response);

      // Split per baris dan print satu per satu
      prettyJson.split('\n').forEach(debugPrint);

      // Check for error response
      if (response['error'] == true) {
        throw Exception(response['message'] ?? 'Unknown error occurred');
      }

      // Check for valid data structure
      if (response['error'] == false && response['data'] != null) {
        return {
          "marks": response['data']['marks'],
          "answers": response['data']['answers'] as List<dynamic>
        };
      }

      return {"marks": response['data']['marks'] ?? 0, "answers": []};
    } catch (e) {
      debugPrint('Error getting online exam result answer: $e');
      throw Exception(e.toString());
    }
  }

  Future<void> updateOnlineExamAnswerCorrection({
    required int onlineExamId,
    required List<Map<String, int>> data,
  }) async {
    try {
      final response = await Api.post(
        url: Api.updateOnlineExamAnswerCorrection,
        useAuthToken: true,
        body: {
          'online_exam_id': onlineExamId,
          'data': data,
        },
      );

      debugPrint("ERROR UPDATE ANSWER: $response");

      if (response['error'] == true) {
        throw ApiException(
            response['message'] ?? 'Failed to update online exam question');
      }
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> updateOnlineExam({
    required int id,
    required int classSectionId,
    required int classSubjectId,
    required String title,
    required String examKey,
    required int duration,
    required DateTime startDate,
  }) async {
    try {
      final response = await Api.post(
        url: '${Api.updateOnlineExam}/$id',
        useAuthToken: true, // Enable authentication
        body: {
          'class_section_id': classSectionId.toString(),
          'class_subject_id': classSubjectId.toString(),
          'title': title,
          'exam_key': examKey,
          'duration': duration.toString(),
          'start_date': DateFormat('yyyy-MM-dd HH:mm').format(startDate),
        },
      );

      debugPrint('Update Exam Response: $response');

      if (response.containsKey('status') && response['error'] == true) {
        throw ApiException(
            response['message'] ?? 'Failed to update online exam');
      }
    } catch (e) {
      debugPrint('Error updating online exam: $e');
      throw ApiException(e.toString());
    }
  }

  Future<void> deleteOnlineExam(int id, {String mode = 'archive'}) async {
    try {
      final response = await Api.delete(
        url: '${Api.deleteOnlineExam}/$id',
        useAuthToken: true,
        body: {
          'mode': mode,
        },
        queryParameters: {
          'mode': mode,
        },
      );

      if (response['error'] == true) {
        throw ApiException(response['message'] ?? 'Gagal menghapus ujian');
      }

      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Error deleting online exam: $e');
      if (e is DioException) {
        final response = e.response?.data;
        if (e.response?.statusCode == 404) {
          throw ApiException(
              'Ujian tidak ditemukan atau sudah dihapus sebelumnya');
        }
        throw ApiException(response?['message'] ?? 'Gagal menghapus ujian');
      }
      throw ApiException(e.toString());
    }
  }

  Future<void> restoreOnlineExam(int id) async {
    try {
      final response = await Api.delete(
        // Ubah dari post ke delete
        url: '${Api.deleteOnlineExam}/$id',
        useAuthToken: true,
        body: {
          'mode': 'restore',
        },
        queryParameters: {
          'mode': 'restore', // Tambahkan query parameter
        },
      );

      debugPrint('Restore Exam Response: $response');

      if (response['error'] == true) {
        throw ApiException(
            response['message'] ?? 'Failed to restore online exam');
      }

      // Tunggu sebentar sebelum melanjutkan
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Error restoring online exam: $e');
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> createOnlineExam({
    required int classSectionId,
    required int classSubjectId,
    required String title,
    required String examKey,
    required int duration,
    required DateTime startDate,
    int? sessionYearId,
  }) async {
    try {
      final response = await Api.post(
        url: Api.createOnlineExam,
        useAuthToken: true,
        body: {
          'class_section_id': classSectionId.toString(),
          'class_subject_id': classSubjectId.toString(),
          'title': title,
          'exam_key': examKey,
          'duration': duration.toString(),
          'start_date': DateFormat('yyyy-MM-dd HH:mm').format(startDate),
          if (sessionYearId != null)
            'session_year_id': sessionYearId.toString(),
        },
      );

      debugPrint('Create Exam Response: $response');

      if (response['success'] == true || response['error'] == false) {
        return response['data'] ?? {};
      } else {
        // Handle validation errors or other server-side failures
        String errorMessage =
            response['message'] ?? 'Failed to create online exam';
        if (response['errors'] != null && response['errors'] is Map) {
          final errors = response['errors'] as Map;
          if (errors.isNotEmpty) {
            errorMessage = errors.values.first.toString();
            // Clean up the error message if it's a list string [message]
            errorMessage = errorMessage.replaceAll('[', '').replaceAll(']', '');
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error creating exam: $e');
      // If it's already an exception with a specific message, just rethrow it
      if (e is Exception && !e.toString().contains('DioException')) {
        rethrow;
      }
      throw Exception(e.toString());
    }
  }

  Future<List<QuestionOnlineExam>> getOnlineExamQuestions(int examId,
      {int? bankId}) async {
    try {
      final response = await Api.get(
        url: "${Api.getOnlineExamQuestions}/$examId",
        useAuthToken: true,
        queryParameters: bankId != null ? {'bank_id': bankId} : null,
      );

      debugPrint('Questions Response: $response');

      // Debug di repository untuk melihat respons asli dari API
      debugPrint('Raw Response: $response');

      if (response['success'] == true || response['error'] == false) {
        final data = response['data'] as Map<String, dynamic>;
        final examQuestions = data['exam_questions'] as List;

        // Debug untuk melihat nilai versi pada data soal
        for (var q in examQuestions) {
          debugPrint(
              'Raw question data - ID: ${q['id']}, Version: ${q['version']}, Type: ${q['version'].runtimeType}');
        }

        return examQuestions.map((question) {
          // Parse options
          final options = (question['options'] as List?)?.first ?? {};

          debugPrint("OK BELUM ERROR");

          return QuestionOnlineExam(
            id: question['id'] ?? 0,
            questionId: question['question_id'] ?? 0,
            question: question['question_text'] ?? '',
            correctAnswer: options['is_answer'] == 1 ? 'A' : '',
            marks: question['marks'] ?? 0,
            options: question['options'],
            title: '', // Bisa diambil dari exam['title'] jika diperlukan
            version: question['version']?.toString() ??
                '1', // PERBAIKAN DISINI - ambil dari API
            type: question["type"] ?? "multiple_choice",
            onlineExamId: examId,
          );
        }).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch questions');
      }
    } catch (e) {
      debugPrint('Error fetching questionss: $e');
      throw Exception(e.toString());
    }
  }

  Future<List<QuestionOnlineExam>> getOnlineExamQuestionListCorrection(
      int examId, String? search) async {
    try {
      final response = await Api.get(
          url:
              "${Api.getOnlineExamQuestionListCorrection}?exam_id=${examId.toString()}&&search=$search",
          useAuthToken: true);

      debugPrint("AMAN SINI 1");

      if (response['error'] != true) {
        final data = response['data'] as Map<String, dynamic>;
        debugPrint("AMAN SINI 2");
        final examQuestions = data['exam_questions'] as List;

        debugPrint("AMAN SINI 3");

        return examQuestions.map((question) {
          final options = (question['options'] as List?)?.isNotEmpty == true
              ? question['options']!.first
              : {};

          return QuestionOnlineExam(
            id: question['id'] ?? 0,
            questionId: question['question_id'] ?? 0,
            question: question['question_text'] ?? '',
            correctAnswer: options['is_answer'] == 1
                ? 'A'
                : '', // Sesuaikan dengan response API
            marks: question['marks'] ?? 0,
            options: question['options'],
            title: '',
            version: '1.0', // Sesuaikan dengan kebutuhan
            type: question["question_type"] ?? "multiple_choice",
            onlineExamId: examId,
          );
        }).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch questions');
      }
    } catch (e) {
      debugPrint('Error fetching questions: $e');
      throw Exception(e.toString());
    }
  }

  Future<List<BankSoalQuestion>> getBankSoal(int examId) async {
    try {
      final response = await Api.get(
        url: "${Api.getOnlineExamQuestions}/$examId",
        useAuthToken: true,
      );

      debugPrint('Bank Soal Response: $response');

      if ((response['success'] == true || response['error'] == false) &&
          response['data'] != null) {
        // Extract exam data untuk mendapatkan class_section_id dan class_subject_id

        final examData = response['data']['exam'] as Map<String, dynamic>?;

        debugPrint("AMAN HERE");

        final classSectionId = examData?['class_section']?['id'] ?? 0;

        debugPrint("AMAN HERE LGI 1");

        final classSubjectId = examData?['subject']?['id'] ?? 0;
        debugPrint("AMAN HERE LGI 2");

        List bankList = response['data']['bank_soal'] ?? [];

        debugPrint("AMAN HERE LGI 3");

        debugPrint(bankList.toString());

        return bankList.map((bank) {
          final bankData = Map<String, dynamic>.from(bank);
          bankData['class_section_id'] = classSectionId;
          bankData['class_subject_id'] = classSubjectId;
          bankData['soal'] = List.from(Iterable.generate(
              bankData['total_questions'], (_) => {"options": ""}));

          return BankSoalQuestion.fromJson(bankData);
        }).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch bank soal');
      }
    } catch (e) {
      debugPrint('Error fetching bank soal: $e');
      throw Exception(e.toString());
    }
  }

  Future<void> storeOnlineExamQuestions({
    required int examId,
    required int classSectionId,
    required int classSubjectId,
    required Map<String, Map<String, dynamic>> assignQuestions,
  }) async {
    try {
      // Add additional validation
      if (examId <= 0 || classSectionId <= 0 || classSubjectId <= 0) {
        throw ApiException('Invalid input parameters');
      }

      // Debug: Log the data being sent
      debugPrint('=== DEBUGGING STORE QUESTIONS ===');
      debugPrint('assign_questions: $assignQuestions');
      debugPrint('Data types in assign_questions:');
      assignQuestions.forEach((key, value) {
        debugPrint('  $key: ${value.runtimeType}');
        value.forEach((k, v) {
          debugPrint('    $k: $v (${v.runtimeType})');
        });
      });
      debugPrint('merge_existing: true (Boolean)');
      debugPrint('===================================');

      final response = await Api.postJson(
        url: Api.storeOnlineExamQuestions,
        useAuthToken: true,
        body: {
          'exam_id': examId,
          'class_section_id': classSectionId,
          'class_subject_id': classSubjectId,
          'assign_questions': assignQuestions,
          'merge_existing': true, // Send as actual boolean
        },
      );

      debugPrint('Store questions response: $response');

      if (response['error'] == true) {
        throw ApiException(response['message'] ?? 'Failed to store questions');
      }
    } catch (e) {
      debugPrint('Error storing questions: $e');
      throw ApiException(e.toString());
    }
  }

  Future<void> deleteOnlineExamQuestions(
      int examId, List<int> questionIds) async {
    try {
      debugPrint('=== DELETE QUESTIONS REQUEST ===');
      debugPrint('URL: ${Api.deleteQuestionOnlineExam}');
      debugPrint('Exam ID: $examId');
      debugPrint('Question IDs: $questionIds');

      final response = await Api.delete(
        url: Api.deleteQuestionOnlineExam,
        useAuthToken: true,
        body: {
          'exam_id': examId,
          'question_id': questionIds,
        },
      );

      if (response['error'] == true) {
        throw ApiException(response['message'] ?? 'Failed to delete questions');
      }
    } catch (e) {
      debugPrint('=== DELETE QUESTIONS ERROR ===');
      debugPrint('Error Type: ${e.runtimeType}');
      debugPrint('Error Message: $e');
      throw ApiException(e.toString());
    }
  }
}
