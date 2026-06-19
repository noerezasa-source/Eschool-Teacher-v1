import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/data/repositories/exam/onlineExamRepository.dart';
import 'package:eschool_saas_staff/data/models/exam/onlineExam.dart';
import 'package:eschool_saas_staff/utils/system/api.dart';
// Add this import
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';

import 'package:eschool_saas_staff/data/models/academic/subjectDetail.dart';

abstract class OnlineExamState {}

class OnlineExamInitial extends OnlineExamState {}

class OnlineExamLoading extends OnlineExamState {}

class OnlineExamAnswer extends OnlineExamState {
  final int id;
  final String studentName;
  final int studentId;
  final String answer;
  final int marks;
  final int totalMarks;
  late bool isCorrect;

  OnlineExamAnswer({
    required this.id,
    required this.studentName,
    required this.studentId,
    required this.isCorrect,
    required this.totalMarks,
    required this.marks,
    required this.answer,
  });
}

class OnlineExamAnswersSuccess extends OnlineExamState {
  final List<OnlineExamAnswer> answers;

  OnlineExamAnswersSuccess({
    required this.answers,
  });
}

class OnlineExamSuccess extends OnlineExamState {
  final List<OnlineExam> exams;
  final List<OnlineExam> archivedExams;
  final List<dynamic> subjectDetails;

  OnlineExamSuccess({
    required this.exams,
    this.archivedExams = const [],
    required this.subjectDetails,
  });
}

// Add this new state
class OnlineExamLoaded extends OnlineExamState {
  final OnlineExam exam;
  final List<SubjectDetail> subjects;

  OnlineExamLoaded({
    required this.exam,
    required this.subjects,
  });
}

class OnlineExamFailure extends OnlineExamState {
  final String message;

  OnlineExamFailure(this.message);
}

// Add these states
class CreateOnlineExamLoading extends OnlineExamState {}

// Add new state
class CreateOnlineExamSuccess extends OnlineExamState {
  final OnlineExam exam;
  CreateOnlineExamSuccess(this.exam);
}

class CreateOnlineExamFailure extends OnlineExamState {
  final String message;
  CreateOnlineExamFailure(this.message);
}

// Tambahkan state baru
class SubjectsLoading extends OnlineExamState {}

class SubjectsLoaded extends OnlineExamState {
  final List<dynamic> subjects;
  SubjectsLoaded(this.subjects);
}

class SubjectsError extends OnlineExamState {
  final String message;
  SubjectsError(this.message);
}

// Add new states
class StoringQuestions extends OnlineExamState {}

class QuestionsStored extends OnlineExamState {}

class OnlineExamCubit extends Cubit<OnlineExamState> {
  final OnlineExamRepository _repository;

  // Static tracking for optimistic updates - shared across all cubit instances
  // because OnlineExamScreen and ArchiveOnlineExam create separate cubit instances
  static final Set<int> _optimisticArchivedIds = {};
  static final Map<int, OnlineExam> _optimisticArchivedExams = {};
  static final Set<int> _optimisticRestoredIds = {};
  static final Map<int, OnlineExam> _optimisticRestoredExams = {};

  OnlineExamCubit(this._repository) : super(OnlineExamInitial());

  void addExam(OnlineExam exam) {
    _optimisticRestoredIds.add(exam.id);
    _optimisticRestoredExams[exam.id] = exam;
    if (state is OnlineExamSuccess) {
      final currentState = state as OnlineExamSuccess;
      if (currentState.exams.any((e) => e.id == exam.id)) {
        return;
      }
      final updatedExams = List<OnlineExam>.from(currentState.exams);
      updatedExams.insert(0, exam);
      emit(OnlineExamSuccess(
        exams: updatedExams,
        archivedExams: currentState.archivedExams,
        subjectDetails: currentState.subjectDetails,
      ));
    }
  }

  // Method untuk mendapatkan ujian aktif
  Future<void> getOnlineExams(
      {String? search,
      dynamic getFull,
      int? subjectId,
      int? classSectionId,
      int? sessionYearId,
      DateTime? startDate,
      DateTime? endDate}) async {
    try {
      if (isClosed) return;
      emit(OnlineExamLoading());

      final result = await _repository.getOnlineExams(
          search: search,
          subjectId: subjectId,
          classSectionId: classSectionId,
          sessionYearId: sessionYearId,
          startDate: startDate,
          endDate: endDate,
          // status: 'active', // Dikomentari agar mengambil semua status lalu difilter di cubit
          archive: getFull ?? false,
          modeAll: true);

      final List<OnlineExam> activeExams = [];
      final List<OnlineExam> archivedExams = [];

      if (result['exams'] is List) {
        for (var examData in result['exams']) {
          try {
            final exam = OnlineExam.fromJson(examData);
            // In this specific system, it seems status 2 is widely used for exams.
            // We will show both status 1 and 2 in the active list if status 2 is not meant to be hidden.
            // If the user wants to see them, they must be in activeExams.
            activeExams.add(exam);
            _optimisticRestoredIds.remove(exam.id);
            _optimisticRestoredExams.remove(exam.id);

            // If we still want to track archived for the archive button, 
            // we'd need to know which status TRULY means archived (e.g. status 3 or 0)
            if (exam.status == 2) {
              archivedExams.add(exam);
            }
          } catch (e) {
            debugPrint('Error parsing exam (ID: ${examData['id']}): $e');
          }
        }
      }

      // Inject any remaining optimistic restored ones
      for (var id in _optimisticRestoredIds) {
        if (_optimisticRestoredExams.containsKey(id)) {
          final exam = _optimisticRestoredExams[id]!;
          if (!activeExams.any((e) => e.id == exam.id)) {
            activeExams.insert(0, exam);
          }
        }
      }

      if (isClosed) return;
      debugPrint('Cubit SUCCESS: Total Active Exams: ${activeExams.length}');
      emit(OnlineExamSuccess(
        exams: activeExams,
        archivedExams: archivedExams,
        subjectDetails: result['subjectDetails'] ?? [],
      ));
    } catch (e) {
      debugPrint("Cubit Error: $e");
      
      if (isClosed) return;
      // Gunakan ErrorMessageUtils untuk mengkonversi error teknis menjadi pesan yang ramah
      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      emit(OnlineExamFailure(userFriendlyMessage));

      // Log technical error untuk debugging (hanya untuk development)
      debugPrint(
          'Technical error in getOnlineExams: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
    }
  }

  Future<void> getOnlineExamResultAnswer({
    required int examId,
    required int questionId,
    String? search,
  }) async {
    try {
      if (isClosed) return;
      emit(OnlineExamLoading());

      final result = await _repository.getOnlineExamResultAnswer(
        onlineExamId: examId,
        questionId: questionId,
        search: search,
      );

      if (isClosed) return;
      emit(OnlineExamAnswersSuccess(
        answers: (result['answers'] as List<dynamic>)
            .map((answer) => OnlineExamAnswer(
                  id: answer['answer_id'] ?? 0,
                  marks: answer['marks'] ?? 0,
                  totalMarks: result['marks'] ?? 0,
                  studentId: answer['student_id'] ?? 0,
                  studentName: answer['student_name'] ?? '',
                  answer: answer['answer'] ?? '',
                  isCorrect: answer['is_answer'] ?? false,
                ))
            .toList(),
      ));
    } catch (e) {
      if (isClosed) return;
      // Gunakan ErrorMessageUtils untuk mengkonversi error teknis menjadi pesan yang ramah
      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      emit(OnlineExamFailure(userFriendlyMessage));

      // Log technical error untuk debugging (hanya untuk development)
      debugPrint(
          'Technical error in getOnlineExamResultAnswer: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
    }
  }

  // Update the createOnlineExam method in OnlineExamCubit
  Future<void> createOnlineExam({
    required int classSectionId,
    required int classSubjectId,
    required String title,
    required String examKey,
    required int duration,
    required DateTime startDate,
    int? sessionYearId,
  }) async {
    try {
      if (isClosed) return;
      emit(CreateOnlineExamLoading());

      final response = await _repository.createOnlineExam(
        classSectionId: classSectionId,
        classSubjectId: classSubjectId,
        title: title,
        examKey: examKey,
        duration: duration,
        startDate: startDate,
        sessionYearId: sessionYearId,
      );

      if (isClosed) return;
      // Emit success state with the created exam data
      emit(CreateOnlineExamSuccess(OnlineExam.fromJson(response)));
    } catch (e) {
      if (isClosed) return;
      
      String message = e.toString();
      // Remove "Exception: " prefix if present
      if (message.startsWith('Exception: ')) {
        message = message.replaceFirst('Exception: ', '');
      }
      
      // If it's a technical Dio error, use ErrorMessageUtils for a user-friendly translation
      if (message.contains('DioException') || message.contains('SocketException')) {
        message = ErrorMessageUtils.getReadableErrorMessage(e);
      }
      
      emit(CreateOnlineExamFailure(message));

      // Log technical error for debugging
      debugPrint('Technical error in createOnlineExam: $e');
    }
  }

  Future<bool> updateOnlineExamAnswerCorrection({
    required int examId,
    required List<Map<String, int>> data,
  }) async {
    debugPrint(data.toString());
    String formattedJson = const JsonEncoder.withIndent("  ").convert(data);

    // Cetak per baris
    for (var line in formattedJson.split("\n")) {
      debugPrint(line.toString());
    }
    debugPrint("OK DARI SISNI");
    try {
      await _repository.updateOnlineExamAnswerCorrection(
        onlineExamId: examId,
        data: data,
      );
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  // Add this method to the OnlineExamCubit class
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
      emit(OnlineExamLoading());

      await _repository.updateOnlineExam(
        id: id,
        classSectionId: classSectionId,
        classSubjectId: classSubjectId,
        title: title,
        examKey: examKey,
        duration: duration,
        startDate: startDate,
      );

      // Fetch updated exam list immediately

      final result = await _repository.getOnlineExams(status: 'active', modeAll: true);

      final List<OnlineExam> exams = [];
      if (result['exams'] is List) {
        for (var examData in result['exams']) {
          try {
            final exam = OnlineExam.fromJson(examData);
            exams.add(exam);
          } catch (e) {
            debugPrint('Error parsing exam: $e');
          }
        }
      }

      // Emit success state with updated exam list
      emit(OnlineExamSuccess(
        exams: exams,
        subjectDetails: result['subjectDetails'] ?? [],
      ));
    } catch (e) {
      // Gunakan ErrorMessageUtils untuk mengkonversi error teknis menjadi pesan yang ramah
      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      emit(OnlineExamFailure(userFriendlyMessage));

      // Log technical error untuk debugging (hanya untuk development)
      debugPrint(
          'Technical error in updateOnlineExam: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
      rethrow;
    }
  }

  Future<void> deleteOnlineExam({
    required int examId,
    required String mode,
  }) async {
    try {
      // Optimistic update
      if (state is OnlineExamSuccess) {
        final currentState = state as OnlineExamSuccess;
        if (mode == 'archive') {
          final updatedActive = currentState.exams.where((e) => e.id != examId).toList();
          
          OnlineExam? examToArchive;
          try {
            examToArchive = currentState.exams.firstWhere((e) => e.id == examId);
            _optimisticArchivedIds.add(examId);
            _optimisticArchivedExams[examId] = examToArchive;
          } catch (_) {}

          final updatedArchived = List<OnlineExam>.from(currentState.archivedExams);
          if (examToArchive != null) {
            updatedArchived.insert(0, examToArchive);
          }

          emit(OnlineExamSuccess(
            exams: updatedActive,
            archivedExams: updatedArchived,
            subjectDetails: currentState.subjectDetails,
          ));
        } else if (mode == 'permanent') {
          final updatedArchived = currentState.archivedExams.where((e) => e.id != examId).toList();
          emit(OnlineExamSuccess(
            exams: currentState.exams,
            archivedExams: updatedArchived,
            subjectDetails: currentState.subjectDetails,
          ));
        }
      } else {
        emit(OnlineExamLoading());
      }

      await _repository.deleteOnlineExam(examId, mode: mode);
    } catch (e) {
      debugPrint('Delete Error in Cubit: $e');
      String errorMessage = 'Gagal menghapus ujian';

      if (e is ApiException) {
        errorMessage = e.errorMessage;
      }

      // Rollback optimistic update by refreshing from backend
      if (mode == 'permanent') {
        await getArchivedExams();
      } else {
        await getOnlineExams();
      }

      emit(OnlineExamFailure(errorMessage));
      rethrow;
    }
  }

  // Perbaikan pada metode getArchivedExams()

  Future<void> getArchivedExams() async {
    try {
      emit(OnlineExamLoading());

      final result = await _repository.getOnlineExams(
        archive: true,
      );

      final List<OnlineExam> archivedExams = [];
      if (result['exams'] is List) {
        for (var examData in result['exams']) {
          try {
            final exam = OnlineExam.fromJson(examData);
            // Jangan filter berdasarkan status, tambahkan semua hasil dari parameter archive:true
            archivedExams.add(exam);
            _optimisticArchivedIds.remove(exam.id); // Remove from optimistic if backend returns it
            _optimisticArchivedExams.remove(exam.id);
          } catch (e) {
            debugPrint('Error parsing archived exam: $e');
          }
        }
      }

      // Inject any remaining optimistic ones
      for (var id in _optimisticArchivedIds) {
        if (_optimisticArchivedExams.containsKey(id)) {
          // Insert at the beginning so it shows at the top
          archivedExams.insert(0, _optimisticArchivedExams[id]!);
        }
      }
      
      // Remove any that were optimistically restored
      archivedExams.removeWhere((e) => _optimisticRestoredIds.contains(e.id));

      List<OnlineExam> currentActive = [];
      if (state is OnlineExamSuccess) {
        currentActive = (state as OnlineExamSuccess).exams;
      }

      emit(OnlineExamSuccess(
        exams: currentActive, // Keep existing active exams instead of clearing them
        archivedExams: archivedExams,
        subjectDetails: result['subjectDetails'] ?? [],
      ));
    } catch (e) {
      debugPrint("Archive Error: $e");
      // Gunakan ErrorMessageUtils untuk mengkonversi error teknis menjadi pesan yang ramah
      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      emit(OnlineExamFailure(userFriendlyMessage));

      // Log technical error untuk debugging (hanya untuk development)
      debugPrint(
          'Technical error in getArchivedExams: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
    }
  }

  Future<void> restoreOnlineExam(int examId) async {
    try {
      // Optimistic update
      if (state is OnlineExamSuccess) {
        final currentState = state as OnlineExamSuccess;
        final updatedArchived = currentState.archivedExams.where((e) => e.id != examId).toList();
        
        // We can't perfectly optimistically add to active exams because we don't have the full exam object 
        // to move, unless we find it in archivedExams.
        OnlineExam? examToRestore;
        try {
          examToRestore = currentState.archivedExams.firstWhere((e) => e.id == examId);
          _optimisticRestoredIds.add(examId);
          _optimisticArchivedIds.remove(examId);
          _optimisticArchivedExams.remove(examId);
        } catch (_) {}

        final updatedActive = List<OnlineExam>.from(currentState.exams);
        if (examToRestore != null) {
          updatedActive.insert(0, examToRestore);
        }

        emit(OnlineExamSuccess(
          exams: updatedActive,
          archivedExams: updatedArchived,
          subjectDetails: currentState.subjectDetails,
        ));
      } else {
        emit(OnlineExamLoading());
      }

      await _repository.restoreOnlineExam(examId);

    } catch (e) {
      debugPrint('Restore Error: $e');
      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      
      // Rollback optimistic update
      await getArchivedExams();
      
      emit(OnlineExamFailure(userFriendlyMessage));
      debugPrint(
          'Technical error in restoreOnlineExam: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
      rethrow;
    }
  }
}
