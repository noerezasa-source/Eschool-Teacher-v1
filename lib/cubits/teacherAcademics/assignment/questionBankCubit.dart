
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/data/models/exam/question.dart';
import 'package:eschool_saas_staff/data/models/exam/questionBank.dart';
import 'package:eschool_saas_staff/data/models/exam/subjectQuestion.dart';
import 'package:eschool_saas_staff/data/repositories/exam/questionBankRepository.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
// Tambahkan import File
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

abstract class QuestionBankState {}

class QuestionBankInitial extends QuestionBankState {}

class QuestionBankLoading extends QuestionBankState {}

class QuestionBankError extends QuestionBankState {
  final String message;
  QuestionBankError(this.message);
}

class SubjectsFetchSuccess extends QuestionBankState {
  final List<SubjectQuestion> subjects;
  SubjectsFetchSuccess(this.subjects);
}

class BankQuestionsFetchSuccess extends QuestionBankState {
  final List<Question> questions;
  BankQuestionsFetchSuccess(this.questions);
}

// Add new state
class BankSoalFetchSuccess extends QuestionBankState {
  final List<BankSoal> bankSoal;
  BankSoalFetchSuccess(this.bankSoal);
}

class QuestionBankCubit extends Cubit<QuestionBankState> {
  final QuestionBankRepository _repository;

  // Static cache to persist question counts across screens and cubit instances
  static final Map<int, int> _bankQuestionCountsCache = {};

  QuestionBankCubit({required QuestionBankRepository repository})
      : _repository = repository,
        super(QuestionBankInitial());

  Future<void> fetchTeacherSubjects({bool isStaffView = false}) async {
    try {
      emit(QuestionBankLoading());
      debugPrint("Fetching subjects for ${isStaffView ? 'staff' : 'teacher'}...");

      final subjects =
          await _repository.getTeacherSubjects(isStaffView: isStaffView);

      if (subjects.isEmpty) {
        emit(QuestionBankError("Tidak ada mata pelajaran yang tersedia"));
        return;
      }

      debugPrint("Successfully fetched ${subjects.length} subjects");
      emit(SubjectsFetchSuccess(subjects));
    } catch (e) {
      debugPrint("Error in QuestionBankCubit: $e");
      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      emit(QuestionBankError(userFriendlyMessage));
      debugPrint(
          'Technical error: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
    }
  }

  Future<void> fetchBankQuestions({
    required int subjectId,
    required int bankId,
    int? examId,
  }) async {
    try {
      emit(QuestionBankLoading());

      final questions = await _repository.getBankQuestions(
        subjectId: subjectId,
        bankId: bankId,
        onlineExamId: examId,
      );

      // Update the local cache with the actual count of fetched questions
      _bankQuestionCountsCache[bankId] = questions.length;

      emit(BankQuestionsFetchSuccess(questions));
    } catch (e) {
      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      emit(QuestionBankError(userFriendlyMessage));
      debugPrint(
          'Technical error: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
    }
  }

  Future<void> fetchBankSoal(int subjectId) async {
    try {
      emit(QuestionBankLoading());
      final bankSoal = await _repository.getBankSoal(subjectId);

      // Verify and update soalCount from local cache if we have a more recent/accurate count
      final updatedBankSoal = bankSoal.map((bank) {
        if (_bankQuestionCountsCache.containsKey(bank.id)) {
          final cachedCount = _bankQuestionCountsCache[bank.id]!;
          // Use the cached count if the API returns 0 or if we have a more recent count
          if (bank.soalCount != cachedCount) {
            debugPrint(
                '[QUESTION BANK CUBIT] Syncing count for bank ${bank.id} (${bank.name}): API=${bank.soalCount}, Cache=$cachedCount');
            return bank.copyWith(soalCount: cachedCount);
          }
        }
        return bank;
      }).toList();

      emit(BankSoalFetchSuccess(updatedBankSoal));
    } catch (e) {
      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      emit(QuestionBankError(userFriendlyMessage));
      debugPrint(
          'Technical error: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
    }
  }

  // Add createQuestionBank method
  Future<void> createQuestionBank({
    required int subjectId,
    required String name,
  }) async {
    try {
      emit(QuestionBankLoading());

      await _repository.createQuestionBank(
        subjectId: subjectId,
        name: name,
      );
      // Fetch updated bank soal list after creation
      final bankSoal = await _repository.getBankSoal(subjectId);
      emit(BankSoalFetchSuccess(bankSoal));
    } catch (e) {
      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      emit(QuestionBankError(userFriendlyMessage));
      rethrow; // Re-throw to handle in UI
    }
  }

  // Add updateQuestionBank method
  Future<void> updateQuestionBank({
    required int subjectId,
    required int banksoalId,
    required String name,
  }) async {
    try {
      emit(QuestionBankLoading());
      await _repository.updateQuestionBank(
        subjectId: subjectId,
        banksoalId: banksoalId,
        name: name,
      );
      // Fetch updated bank soal list after update
      final bankSoal = await _repository.getBankSoal(subjectId);
      emit(BankSoalFetchSuccess(bankSoal));
    } catch (e) {
      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      emit(QuestionBankError(userFriendlyMessage));
      rethrow;
    }
  }

  // Add createQuestion method
  Future<void> createQuestion({
    required int banksoalId,
    required int subjectId,
    required String name,
    required String type,
    required String orderType,
    required int defaultPoint,
    required String question,
    required String note,
    required List<QuestionOption> options,
    File? image,
  }) async {
    try {
      emit(QuestionBankLoading());

      debugPrint('\n=== QUESTION BANK CUBIT: CREATE QUESTION ===');
      debugPrint('Starting question creation in cubit...');

      // Validate image if exists
      if (image != null) {
        debugPrint('\n=== IMAGE VALIDATION ===');
        final imageSize = await image.length();
        final imageSizeInMB = imageSize / (1024 * 1024);
        debugPrint('Image Size: ${imageSizeInMB.toStringAsFixed(2)} MB');

        if (imageSizeInMB > 2) {
          throw ApiException('Ukuran gambar harus kurang dari 2MB');
        }

        final extension = image.path.split('.').last.toLowerCase();
        debugPrint('Image Extension: $extension');

        if (!['jpg', 'jpeg', 'png'].contains(extension)) {
          throw ApiException(
              'Hanya file JPG, JPEG, dan PNG yang diperbolehkan');
        }
      }

      await _repository.createQuestion(
        banksoalId: banksoalId,
        subjectId: subjectId,
        name: name,
        type: type,
        orderType: orderType,
        defaultPoint: defaultPoint,
        question: question,
        note: note,
        options: options,
        image: image,
      );

      final questions = await _repository.getBankQuestions(
          subjectId: subjectId, bankId: banksoalId);

      // Update cache after adding a new question
      _bankQuestionCountsCache[banksoalId] = questions.length;

      emit(BankQuestionsFetchSuccess(questions));
    } catch (e) {
      debugPrint('\n=== ERROR IN CUBIT ===');
      debugPrint('Error Type: ${e.runtimeType}');
      debugPrint('Error Message: $e');
      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      emit(QuestionBankError(userFriendlyMessage));
      debugPrint(
          'Technical error: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
      rethrow;
    }
  }

  // Add updateQuestion method
  Future<void> updateQuestion({
    required int banksoalSoalId,
    required int subjectId,
    required int bankSoalId,
    required String name,
    required String type,
    required int defaultPoint,
    required String question,
    required String note,
    required List<QuestionOption> options,
    dynamic image, // Tambahkan parameter image
    String? orderType,
  }) async {
    debugPrint("OKKK 10");
    try {
      emit(QuestionBankLoading());

      debugPrint("OK 11");

      debugPrint(banksoalSoalId.toString());
      debugPrint(subjectId.toString());

      await _repository.updateQuestion(
        banksoalSoalId: banksoalSoalId,
        subjectId: subjectId,
        name: name,
        type: type,
        defaultPoint: defaultPoint,
        question: question,
        bankSoalId: bankSoalId,
        note: note,
        options: options,
        image: image,
        orderType: type == "multiple_choice" ? orderType : null,
      );

      debugPrint("OK 12");

      // Fetch updated questions after successful update
      final questions = await _repository.getBankQuestions(
          subjectId: subjectId, bankId: bankSoalId);
      debugPrint("OK 13");
      emit(BankQuestionsFetchSuccess(questions));
      debugPrint("OK 14");
    } catch (e) {
      // Check if error message indicates success
      if (e.toString().contains('Soal Updated Successfully')) {
        // Fetch updated questions even though we got an error
        final questions = await _repository.getBankQuestions(
            subjectId: subjectId, bankId: banksoalSoalId);
        emit(BankQuestionsFetchSuccess(questions));
        return;
      }

      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      emit(QuestionBankError(userFriendlyMessage));
      debugPrint(
          'Technical error: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
      rethrow;
    }
  }

  Future<void> deleteBankSoal({
    required int subjectId,
    required int banksoalId,
  }) async {
    try {
      debugPrint('📝 QuestionBankCubit: Starting delete process');
      emit(QuestionBankLoading());

      debugPrint('📊 Delete Parameters:');
      debugPrint('Subject ID: $subjectId');
      debugPrint('Bank Soal ID: $banksoalId');

      await _repository.deleteBankSoal(
        subjectId: subjectId,
        banksoalId: banksoalId,
      );

      debugPrint('🔄 Refreshing bank soal list');
      final bankSoal = await _repository.getBankSoal(subjectId);
      emit(BankSoalFetchSuccess(bankSoal));
      debugPrint('✅ Delete process completed successfully');
    } catch (e) {
      debugPrint('❌ Delete Error in Cubit: $e');
      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      emit(QuestionBankError(userFriendlyMessage));
      debugPrint(
          'Technical error: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
      rethrow;
    }
  }

  // Add this method to QuestionBankCubit class
  Future<void> deleteQuestion({
    required int subjectId,
    required int banksoalId,
    required int banksoalSoalId,
  }) async {
    try {
      debugPrint('📝 QuestionBankCubit: Starting delete question process');
      emit(QuestionBankLoading());

      await _repository.deleteQuestion(
        subjectId: subjectId,
        banksoalId: banksoalId,
        banksoalSoalId: banksoalSoalId,
      );

      // Get updated questions list
      final updatedQuestions = await _repository.getBankQuestions(
        subjectId: subjectId,
        bankId: banksoalId,
      );

      // Update cache after deleting a question
      _bankQuestionCountsCache[banksoalId] = updatedQuestions.length;

      emit(BankQuestionsFetchSuccess(updatedQuestions));
      debugPrint('✅ Delete question process completed successfully');
    } catch (e) {
      debugPrint('❌ Delete Error in Cubit: $e');
      if (e.toString().contains('validation.exists')) {
        emit(QuestionBankError('Soal tidak ditemukan atau sudah dihapus'));
      } else {
        final userFriendlyMessage =
            ErrorMessageUtils.getReadableErrorMessage(e);
        emit(QuestionBankError(userFriendlyMessage));
        debugPrint(
            'Technical error: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
      }
      rethrow;
    }
  }
}
