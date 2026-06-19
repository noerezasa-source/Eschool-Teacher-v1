import 'package:eschool_saas_staff/data/models/exam/exam.dart';
import 'package:eschool_saas_staff/data/models/student/studentAttendance.dart';
import 'package:eschool_saas_staff/data/models/student/studentDetails.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/logger.dart';
import 'package:flutter/foundation.dart';

class StudentRepository {
  Future<List<StudentDetails>> getStudentsByClassSectionAndSubject({
    required int classSectionId,
    required int? classSubjectId,
    required int? examId,
    StudentListStatus? status,
    String? search,
  }) async {
    const scope = 'StudentRepository.getStudentsByClassSectionAndSubject';
    try {
      AppLogger.info(scope, 'Request start', data: {
        'classSectionId': classSectionId,
        'classSubjectId': classSubjectId,
        'examId': examId,
        'status': status?.toString(),
        'search': search,
      });

      ///[0 - view all, 1 - Active, 2 - Inactive]
      int studentViewStatus = 0;
      if (status != null) {
        if (status == StudentListStatus.active) {
          studentViewStatus = 1;
        } else if (status == StudentListStatus.inactive) {
          studentViewStatus = 2;
        }
      }
      final result = await Api.get(
        url: Api.getStudents,
        useAuthToken: true,
        queryParameters: {
          "paginate": 0,
          "status": studentViewStatus,
          "class_section_id": classSectionId,
          if (search != null) "search": search,
          if (classSubjectId != null) "class_subject_id": classSubjectId,
          if (examId != null) "exam_id": examId
        },
      );

      AppLogger.debug(scope, 'Raw API response', data: {
        'responseKeys': result.keys.toList(),
        'hasData': result.containsKey('data'),
        'dataType': result['data']?.runtimeType.toString(),
        'dataStructure': result['data'] is Map
            ? (result['data'] as Map).keys.toList()
            : 'not a map',
        'studentsExists': result['data'] is Map
            ? result['data'].containsKey('students')
            : false,
        'studentsType':
            result['data'] is Map && result['data']['students'] != null
                ? result['data']['students'].runtimeType.toString()
                : 'null',
        'studentsHasData':
            result['data'] is Map && result['data']['students'] is Map
                ? result['data']['students'].containsKey('data')
                : false,
      });

      // Handle different response structures
      List<dynamic> studentsData;
      if (result['data'] is Map && result['data'].containsKey('students')) {
        var students = result['data']['students'];
        AppLogger.debug(scope, 'Students object found', data: {
          'studentsType': students.runtimeType.toString(),
          'hasDataKey': students is Map ? students.containsKey('data') : false,
        });

        // Check if students is a paginated structure
        if (students is Map &&
            students.containsKey('data') &&
            students['data'] is List) {
          // Paginated response structure: data.students.data
          studentsData = students['data'] as List;
          AppLogger.debug(scope, 'Using paginated students response structure',
              data: {'count': studentsData.length});
        } else if (students is List) {
          // Non-paginated students structure: data.students
          studentsData = students;
          AppLogger.debug(
              scope, 'Using non-paginated students response structure',
              data: {'count': studentsData.length});
        } else {
          studentsData = [];
          AppLogger.warn(scope, 'Invalid students data structure', data: {
            'studentsType': students?.runtimeType.toString() ?? 'null',
            'studentsKeys':
                students is Map ? students.keys.toList() : 'not a map',
          });
        }
      } else if (result['data'] is Map && result['data'].containsKey('data')) {
        // Legacy paginated response structure: data.data
        studentsData = result['data']['data'] as List;
        AppLogger.debug(scope, 'Using legacy paginated response structure',
            data: {'count': studentsData.length});
      } else if (result['data'] is List) {
        // Direct list response structure: data
        studentsData = result['data'] as List;
        AppLogger.debug(scope, 'Using direct list response structure',
            data: {'count': studentsData.length});
      } else {
        studentsData = [];
        AppLogger.warn(
            scope, 'Empty or invalid data structure, using empty list',
            data: {
              'responseData':
                  result['data']?.toString().substring(0, 200) ?? 'null',
              'dataType': result['data']?.runtimeType.toString() ?? 'null',
              'dataKeys': result['data'] is Map
                  ? (result['data'] as Map).keys.toList()
                  : 'not a map',
            });
      }

      AppLogger.info(scope, 'Request success', data: {
        'studentsCount': studentsData.length,
        'sampleData': studentsData.isNotEmpty
            ? '${studentsData.first.toString().substring(0, 100)}...'
            : null,
      });

      return studentsData.map((e) {
        return StudentDetails.fromJson(Map.from(e ?? {}));
      }).toList();
    } on ApiException catch (e, stackTrace) {
      AppLogger.error(scope, 'API Exception occurred',
          error: e.errorMessage,
          stack: stackTrace,
          data: {
            'classSectionId': classSectionId,
            'classSubjectId': classSubjectId,
          });

      // Provide user-friendly error message for server errors
      if (e.errorMessage.contains('Undefined variable')) {
        throw ApiException(
            'Server error: Database query issue. Please contact administrator.');
      } else if (e.errorMessage.contains('Error Occurred')) {
        throw ApiException(
            'Server encountered an error. Please try again or contact administrator.');
      }

      rethrow;
    } on Exception catch (e, stackTrace) {
      AppLogger.error(scope, 'Exception occurred',
          error: e.toString(), stack: stackTrace);
      throw ApiException('Failed to get student list: ${e.toString()}');
    } catch (e, stackTrace) {
      AppLogger.error(scope, 'Unknown error occurred',
          error: e.toString(), stack: stackTrace);
      throw ApiException('Unexpected error occurred while fetching students');
    }
  }

  Future<({List<StudentDetails> students, int currentPage, int totalPage})>
      getStudents(
          {required int classSectionId,
          int? page,
          int? sessionYearId,
          String? search,
          String? status,
          bool getAllData = false}) async {
    const scope = 'StudentRepository.getStudents';
    try {
      AppLogger.info(scope, 'Request start', data: {
        'classSectionId': classSectionId,
        'page': page,
        'sessionYearId': sessionYearId,
        'search': search,
        'status': status,
        'getAllData': getAllData,
      });

      ///[0 - view all, 1 - Active, 2 - Inactive]
      int? studentViewStatus;
      if (status != null) {
        if (status == '1') {
          studentViewStatus = 1; // Active
        } else if (status == '0') {
          studentViewStatus = 0; // Inactive
        }
      }
      final Map<String, dynamic> queryParameters = {
        "class_section_id": classSectionId,
        "session_year_id": sessionYearId,
        "search": search,
      };

      // Add pagination parameters only if not getting all data
      if (!getAllData) {
        queryParameters["page"] = page ?? 1;
      } else {
        queryParameters["paginate"] = 0; // Get all data without pagination
      }

      if (studentViewStatus != null) {
        queryParameters["status"] = studentViewStatus;
      }
      final result =
          await Api.get(url: Api.getStudents, queryParameters: queryParameters);

      AppLogger.debug(scope, 'Raw API response', data: {
        'responseKeys': result.keys.toList(),
        'hasData': result.containsKey('data'),
        'dataType': result['data']?.runtimeType.toString(),
        'getAllData': getAllData,
        'dataKeys': result['data'] is Map
            ? (result['data'] as Map).keys.toList()
            : 'not a map',
        'hasStudentsKey':
            result['data'] is Map && result['data'].containsKey('students'),
        'studentsType':
            result['data'] is Map && result['data']['students'] != null
                ? result['data']['students'].runtimeType.toString()
                : 'null',
      });

      // Handle different response structures based on pagination
      List<dynamic> studentsData;
      int currentPage = 1;
      int totalPage = 1;

      if (getAllData) {
        // When paginate=0, response structure is different
        final studentsResponse = result['data']['students'] ?? result['data'];
        if (studentsResponse is List) {
          studentsData = studentsResponse;
          AppLogger.debug(scope, 'Using direct list structure for getAllData');
        } else if (studentsResponse is Map &&
            studentsResponse['data'] != null) {
          studentsData = studentsResponse['data'] as List;
          AppLogger.debug(scope, 'Using nested data structure for getAllData');
        } else {
          studentsData = [];
          AppLogger.warn(scope, 'No valid data found for getAllData', data: {
            'dataType': studentsResponse?.runtimeType.toString(),
            'data': studentsResponse?.toString(),
            'hasStudentsWrapper': result['data']['students'] != null,
          });
        }
        // For non-paginated data, set page info
        currentPage = 1;
        totalPage = 1;
      } else {
        // Normal paginated response - handle nested students structure
        final studentsResponse = result['data']['students'] ?? result['data'];
        studentsData = (studentsResponse['data'] ?? []) as List;
        currentPage = (studentsResponse['current_page'] ?? 1) as int;
        totalPage = (studentsResponse['last_page'] ?? 1) as int;

        AppLogger.debug(scope, 'Using paginated response', data: {
          'studentsCount': studentsData.length,
          'currentPage': currentPage,
          'totalPage': totalPage,
          'hasStudentsWrapper': result['data']['students'] != null,
        });
      }

      AppLogger.info(scope, 'Request success', data: {
        'studentsCount': studentsData.length,
        'currentPage': currentPage,
        'totalPage': totalPage,
      });

      return (
        students: studentsData
            .map((studentDetails) =>
                StudentDetails.fromJson(Map.from(studentDetails ?? {})))
            .toList(),
        currentPage: currentPage,
        totalPage: totalPage,
      );
    } catch (e, stk) {
      AppLogger.error(scope, 'Error occurred', error: e.toString(), stack: stk);
      if (kDebugMode) {
        debugPrint(stk.toString());
      }
      throw ApiException(e.toString());
    }
  }

  Future<
          ({
            List<StudentAttendance> studentAttendances,
            int currentPage,
            int totalPage
          })>
      getStudentAttendance(
          {required int classSectionId,
          required String date,
          int? status,
          int? page}) async {
    const scope = 'StudentRepository.getStudentAttendance';
    try {
      AppLogger.info(scope, 'Request start', data: {
        'classSectionId': classSectionId,
        'date': date,
        'status': status,
        'page': page,
      });

      final result = await Api.get(
          url: Api.getStudentAttendanceForStaff,
          queryParameters: {
            "class_section_id": classSectionId,
            "page": page ?? 1,
            "date": date,
            "status": status
          });

      AppLogger.info(scope, 'Request success', data: {
        'attendanceCount': (result['data']['data'] as List?)?.length ?? 0,
        'currentPage': result['data']['current_page'],
        'totalPage': result['data']['last_page'],
      });

      return (
        studentAttendances: ((result['data']['data'] ?? []) as List)
            .map((studentAttendance) =>
                StudentAttendance.fromJson(Map.from(studentAttendance ?? {})))
            .toList(),
        currentPage: (result['data']['current_page'] ?? 1) as int,
        totalPage: (result['data']['last_page'] ?? 1) as int,
      );
    } catch (e, stk) {
      AppLogger.error(scope, 'Error occurred', error: e.toString(), stack: stk);
      throw ApiException(e.toString());
    }
  }

  Future<List<Exam>> fetchExamsList(
      {required int examStatus,
      int? studentID,
      int? publishStatus,
      int? classSectionId}) async {
    const scope = 'StudentRepository.fetchExamsList';
    try {
      var queryParameter = {
        'status': examStatus,
        if (studentID != null) 'student_id': studentID,
      };

      AppLogger.info(scope, 'Request start', data: {
        'examStatus': examStatus,
        'studentID': studentID,
        'publishStatus': publishStatus,
        'classSectionId': classSectionId,
      });

      if (classSectionId != null) {
        queryParameter["class_section_id"] = classSectionId;
      }
      if (publishStatus != null) queryParameter['publish'] = publishStatus;

      final result = await Api.get(
        url: Api.examList,
        useAuthToken: true,
        queryParameters: queryParameter,
      );

      AppLogger.debug(scope, 'API call details', data: {
        'url': Api.examList,
        'queryParameters': queryParameter,
      });

      final examsList = (result['data'] as List)
          .map((e) => Exam.fromExamJson(Map.from(e)))
          .toList();

      AppLogger.info(scope, 'Request success', data: {
        'examsCount': examsList.length,
      });

      return examsList;
    } catch (e, stk) {
      AppLogger.error(scope, 'Error occurred', error: e.toString(), stack: stk);
      throw ApiException(e.toString());
    }
  }

  Future<void> addOfflineExamMarks({
  required int examId,
  required int classSubjectId,
  required int classSectionId,
  required int examTimetableId,
  required Map<String, dynamic> marksDataValue,
}) async {
  try {
    // Gabungkan marks_data dengan ID agar dikirim bersamaan dalam satu JSON body
    final Map<String, dynamic> body = {
      ...marksDataValue, // Menyalin array "marks_data" dari Cubit
      "exam_id": examId,
      "class_subject_id": classSubjectId,
      "class_section_id": classSectionId,
      "exam_timetable_id": examTimetableId,
    };

    // Kirim data ke API menggunakan postJson
    await Api.postJson(
      body: body,
      url: Api.submitExamMarks,
      useAuthToken: true,
    );
  } catch (e) {
    // Memastikan error dilempar dengan benar ke Cubit
    throw ApiException(e.toString());
  }
}

  Future<List<StudentDetails>> getAllStudents({
    required int classSectionId,
    int? sessionYearId,
    String? search,
    String? status,
  }) async {
    try {
      ///[0 - view all, 1 - Active, 2 - Inactive]
      int? studentViewStatus;
      if (status != null) {
        if (status == '1') {
          studentViewStatus = 1; // Active
        } else if (status == '0') {
          studentViewStatus = 0; // Inactive
        }
      }

      final Map<String, dynamic> queryParameters = {
        "class_section_id": classSectionId,
        "paginate": 0, // This will return all data without pagination
        "session_year_id": sessionYearId,
        "search": search,
      };

      if (studentViewStatus != null) {
        queryParameters["status"] = studentViewStatus;
      }

      final result = await Api.get(
          url: Api.getStudents,
          useAuthToken: true,
          queryParameters: queryParameters);

      // Handle both paginated and non-paginated response structure
      List<dynamic> studentsData;
      final studentsResponse = result['data']['students'] ?? result['data'];
      if (studentsResponse is Map && studentsResponse['data'] != null) {
        studentsData = studentsResponse['data'] as List;
      } else if (studentsResponse is List) {
        studentsData = studentsResponse;
      } else {
        studentsData = [];
      }

      return studentsData
          .map((studentDetails) =>
              StudentDetails.fromJson(Map.from(studentDetails ?? {})))
          .toList();
    } catch (e, stk) {
      if (kDebugMode) {
        debugPrint(stk.toString());
      }
      throw ApiException(e.toString());
    }
  }
}

