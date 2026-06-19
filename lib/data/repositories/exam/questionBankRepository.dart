import 'dart:io';
import 'package:eschool_saas_staff/data/models/exam/question.dart';
import 'package:eschool_saas_staff/data/models/exam/questionBank.dart';
import 'package:eschool_saas_staff/data/models/exam/subjectQuestion.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class QuestionBankRepository {
  Future<List<SubjectQuestion>> getTeacherSubjects(
      {bool isStaffView = false}) async {
    try {
      final response = await Api.get(
        url: Api.getTeacherSubject,
        queryParameters:
            isStaffView ? {'view_type': 'staff', 'all': true} : null,
      );

      debugPrint(
          "Raw API Response for ${isStaffView ? 'Staff' : 'Teacher'}: $response");

      if (response['data'] == null) {
        throw ApiException("Data is null");
      }

      // Handle the response structure
      List<Map<String, dynamic>> subjectsData = [];

      if (response['data'] is List) {
        // If data is already a list, use it directly
        subjectsData = (response['data'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      } else if (response['data'] is Map) {
        // If data is a map, convert its values to a list
        subjectsData = (response['data'] as Map)
            .values
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }

      debugPrint("Processed subjects data: $subjectsData");

      final subjects = subjectsData.map((json) {
        try {
          return SubjectQuestion.fromJson(json);
        } catch (e) {
          debugPrint("Error parsing subject: $e");
          debugPrint("Subject JSON: $json");
          rethrow;
        }
      }).toList();

      debugPrint("Successfully parsed ${subjects.length} subjects");
      return subjects;
    } catch (e) {
      debugPrint("Error fetching subjects: $e");
      throw ApiException(e.toString());
    }
  }

  Future<List<Question>> getBankQuestions(
      {required int subjectId, required int bankId, int? onlineExamId}) async {
    try {
      debugPrint({
        'subject_id': subjectId,
        'banksoal_id': bankId,
        if (onlineExamId != null) 'online_exam_id': onlineExamId
      }.toString());
      final response = await Api.get(
        url: Api.getBankQuestions,
        queryParameters: {
          'subject_id': subjectId,
          'banksoal_id': bankId,
          if (onlineExamId != null) 'online_exam_id': onlineExamId
        },
      );

      if (response['data'] == null) {
        throw ApiException("Data is null");
      }

      final questions = (response['data'] as List)
          .map((json) => Question.fromJson(json))
          .toList();

      return questions;
    } catch (e) {
      debugPrint("Error fetching questions: $e");
      throw ApiException(e.toString());
    }
  }

  Future<List<BankSoal>> getBankSoal(int subjectId) async {
    try {
      debugPrint("=== FETCH BANK SOAL ===");
      debugPrint("Subject ID: $subjectId");
      debugPrint("URL: ${Api.getBankSoal}?subject_id=$subjectId");

      final response = await Api.get(
        url: Api.getBankSoal,
        queryParameters: {'subject_id': subjectId},
      );

      debugPrint("Response: $response");

      if (response['data'] == null) {
        throw ApiException("Data is null");
      }

      final bankSoal = (response['data'] as List)
          .map((json) => BankSoal.fromJson(json))
          .toList();

      debugPrint("Parsed ${bankSoal.length} bank soal");
      return bankSoal;
    } catch (e) {
      debugPrint("=== BANK SOAL ERROR ===");
      debugPrint("Subject ID: $subjectId");
      debugPrint("Error: $e");
      debugPrint("Error type: ${e.runtimeType}");
      throw ApiException(e.toString());
    }
  }

  Future<void> createQuestionBank({
    required int subjectId,
    required String name,
  }) async {
    try {
      debugPrint(
          "Creating bank soal with: subject_id=$subjectId, name=$name"); // Debug log

      final response = await Api.post(
        url: Api.createQuestionBank,
        body: {
          'subject_id': subjectId.toString(), // Convert to string
          'name': name,
        },
      );

      debugPrint("Create bank soal response: $response"); // Debug log

      if (response['error'] == true) {
        throw ApiException(response['message']);
      }
    } catch (e) {
      debugPrint("Error creating bank soal: $e"); // Debug log
      throw ApiException(e.toString());
    }
  }

  Future<void> createQuestion({
    required int banksoalId,
    required int subjectId,
    required String name,
    required String type,
    required String orderType,
    required int defaultPoint,
    required String question,
    String note = '',
    required List<QuestionOption> options,
    File? image,
  }) async {
    try {
      debugPrint('\n=== CREATE QUESTION WITH IMAGE ===');
      debugPrint('Starting question creation process...');

      // Create FormData manually to ensure correct format
      final formData = FormData.fromMap({
        'banksoal_id': banksoalId.toString(),
        'subject_id': subjectId.toString(),
        'name': name,
        'type': type,
        'default_point': defaultPoint.toString(),
        'question': question,
        'note': note,
        if (type == 'multiple_choice') 'choice_style': orderType,
      });

      // Add options as individual form fields
      for (var i = 0; i < options.length; i++) {
        formData.fields.addAll([
          MapEntry('options[$i][text]', options[i].text),
          MapEntry('options[$i][percentage]', options[i].percentage.toString()),
          MapEntry('options[$i][feedback]', options[i].feedback),
        ]);
      }

      // Add image if exists
      if (image != null) {
        debugPrint('\n=== IMAGE DETAILS ===');
        debugPrint('Image Path: ${image.path}');
        debugPrint(
            'Image Size: ${(image.lengthSync() / 1024).toStringAsFixed(2)} KB');
        debugPrint('Image Name: ${image.path.split('/').last}');

        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(
              image.path,
              filename: image.path.split('/').last,
              contentType: MediaType('image', 'jpeg'),
            ),
          ),
        );
        debugPrint('Image successfully added to form data');
      }

      debugPrint('\n=== SENDING REQUEST ===');
      debugPrint('Request URL: ${Api.createQuestion}');
      debugPrint('Form Data Fields: ${formData.fields}');

      // Use Dio with custom headers
      final dio = Dio();
      dio.options.headers = {
        ...Api.headers(),
        'Content-Type': 'multipart/form-data',
      };

      final response = await dio.post(
        Api.createQuestion,
        data: formData,
        options: Options(
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('\n=== RESPONSE DETAILS ===');
      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');

      if (response.data['error'] == true) {
        throw ApiException(
            response.data['message'] ?? 'Failed to create question');
      }

      debugPrint('\n=== QUESTION CREATED SUCCESSFULLY ===');
    } catch (e) {
      debugPrint('\n=== ERROR CREATING QUESTION ===');
      debugPrint('Error Type: ${e.runtimeType}');
      debugPrint('Error Message: $e');
      throw ApiException('Failed to create question: ${e.toString()}');
    }
  }

  Future<void> updateQuestionBank({
    required int subjectId,
    required int banksoalId,
    required String name,
  }) async {
    try {
      final response = await Api.post(
        url: Api.updateQuestionBank,
        body: {
          'subject_id': subjectId,
          'banksoal_id': banksoalId,
          'name': name,
        },
      );

      if (response['error'] == true) {
        throw ApiException(response['message']);
      }
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> updateQuestion({
    required int banksoalSoalId,
    required int subjectId,
    required int bankSoalId,
    required String name,
    required String type,
    required int defaultPoint,
    required String question,
    String? orderType,
    String note = '',
    required List<QuestionOption> options,
    dynamic image, // Tambahkan parameter image
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'banksoal_soal_id': banksoalSoalId.toString(),
        'banksoal_id': bankSoalId.toString(),
        'subject_id': subjectId.toString(),
        'name': name,
        'type': type,
        'default_point': defaultPoint.toString(),
        'question': question,
        'note': note,
        if (orderType != null) 'choice_style': orderType,
        'options': options
            .map((opt) => {
                  'text': opt.text,
                  'percentage': opt.percentage.toString(),
                  'feedback': opt.feedback,
                })
            .toList(),
      };

      // Add image if provided
      if (image != null) {
        if (image is XFile) {
          requestBody['image'] = MultipartFile.fromBytes(
            await (image).readAsBytes(),
            filename: image.name.isNotEmpty ? image.name : 'default_image.jpg',
          );
        } else {
          requestBody['image'] = await MultipartFile.fromFile(
            (image as File).path,
          );
        }
      } else {
        requestBody['image'] = null;
      }

      final response =
          await Api.post(url: Api.updateQuestion, body: requestBody);

      if (response['code'] == 200 && response['error'] == false) {
        debugPrint("Question updated successfully");
        return;
      }

      throw ApiException(response['message'] ?? 'Failed to update question');
    } catch (e) {
      debugPrint("Error updating question: $e");

      if (e.toString().contains('Soal Updated Successfully')) {
        debugPrint("Update successful despite error");
        return;
      }

      throw ApiException(e.toString());
    }
  }

  Future<void> deleteBankSoal({
    required int subjectId,
    required int banksoalId,
  }) async {
    try {
      debugPrint('🗑️ Attempting to delete bank soal:');
      debugPrint('Subject ID: $subjectId');
      debugPrint('Bank Soal ID: $banksoalId');

      final response = await Api.delete(
        url: Api.deleteQuestionBank,
        body: {
          'subject_id': subjectId.toString(),
          'banksoal_id': banksoalId.toString(),
        },
      );

      debugPrint('Delete Response: $response');

      if (response['error'] == true) {
        debugPrint('❌ Delete Error: ${response['message']}');
        throw ApiException(response['message']);
      }

      debugPrint('✅ Bank soal deleted successfully');
    } catch (e) {
      debugPrint('❌ Delete Exception: $e');
      throw ApiException(e.toString());
    }
  }

  Future<void> deleteQuestion({
    required int subjectId,
    required int banksoalId,
    required int banksoalSoalId,
  }) async {
    try {
      debugPrint('🗑️ Attempting to delete question:');
      debugPrint('Subject ID: $subjectId');
      debugPrint('Bank Soal ID: $banksoalId');
      debugPrint('Question ID: $banksoalSoalId');

      // Verify question exists first
      final questions =
          await getBankQuestions(subjectId: subjectId, bankId: banksoalId);
      final questionExists = questions.any((q) => q.id == banksoalSoalId);

      if (!questionExists) {
        throw ApiException('Soal tidak ditemukan atau sudah dihapus');
      }

      final response = await Api.delete(
        url: Api.deleteQuestion,
        body: {
          'subject_id': subjectId.toString(),
          'banksoal_id': banksoalId.toString(),
          'banksoal_soal_id': banksoalSoalId.toString(),
        },
      );

      debugPrint('Delete Response: $response');

      // Handle specific validation error
      if (response['error'] == true) {
        if (response['message'] is Map &&
            response['message']['banksoal_soal_id']
                    ?.contains('validation.exists') ==
                true) {
          throw ApiException('Soal tidak ditemukan atau sudah dihapus');
        }
        throw ApiException(response['message'].toString());
      }

      debugPrint('✅ Question deleted successfully');
    } catch (e) {
      debugPrint('❌ Delete Exception: $e');
    }
  }
}
