import 'package:eschool_saas_staff/data/models/student/studentDetails.dart';
import 'package:eschool_saas_staff/data/repositories/student/studentRepository.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

abstract class StudentsByClassSectionState {}

class StudentsByClassSectionInitial extends StudentsByClassSectionState {}

class StudentsByClassSectionFetchInProgress
    extends StudentsByClassSectionState {}

enum StudentByClassSectionSearchStatus { initial, loading, success, failure }

class StudentsByClassSectionFetchSuccess extends StudentsByClassSectionState {
  final List<StudentDetails> studentDetailsList;
  final StudentByClassSectionSearchStatus searchStatus;
  final List<StudentDetails>? searchedStudentDetailsList;
  String? searchErrorMessage;

  StudentsByClassSectionFetchSuccess({
    required this.studentDetailsList,
    this.searchedStudentDetailsList,
    this.searchErrorMessage,
    this.searchStatus = StudentByClassSectionSearchStatus.initial,
  });

  StudentsByClassSectionFetchSuccess copyWith({
    List<StudentDetails>? studentDetailsList,
    List<StudentDetails>? searchedStudentDetailsList,
    StudentByClassSectionSearchStatus? searchStatus,
    String? searchErrorMessage,
  }) {
    return StudentsByClassSectionFetchSuccess(
      studentDetailsList: studentDetailsList ?? this.studentDetailsList,
      searchedStudentDetailsList:
          searchedStudentDetailsList ?? this.searchedStudentDetailsList,
      searchStatus: searchStatus ?? this.searchStatus,
      searchErrorMessage: searchErrorMessage ?? this.searchErrorMessage,
    );
  }
}

class StudentsByClassSectionFetchFailure extends StudentsByClassSectionState {
  final String errorMessage;

  StudentsByClassSectionFetchFailure(this.errorMessage);
}

class StudentsByClassSectionCubit extends Cubit<StudentsByClassSectionState> {
  final StudentRepository _studentRepository = StudentRepository();

  StudentsByClassSectionCubit() : super(StudentsByClassSectionInitial());

  void updateState(StudentsByClassSectionState updatedState) {
    emit(updatedState);
  }

  Future<void> fetchStudents({
    required int classSectionId,
    int? classSubjectId,
    int? examId,
    StudentListStatus? status,
  }) async {
    emit(StudentsByClassSectionFetchInProgress());
    try {
      final studentDetailsList =
          await _studentRepository.getStudentsByClassSectionAndSubject(
        classSectionId: classSectionId,
        status: status,
        classSubjectId: classSubjectId,
        examId: examId,
      );

      debugPrint(
          'Fetched Students: ${studentDetailsList.map((student) => student.toJson()).toList()}');
      if (isClosed) return;
      emit(
        StudentsByClassSectionFetchSuccess(
          studentDetailsList: studentDetailsList,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      emit(StudentsByClassSectionFetchFailure(userFriendlyMessage));
      debugPrint(
          'Technical error: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
    }
  }

  void searchStudents({
    required int classSectionId,
    int? classSubjectId,
    int? examId,
    StudentListStatus? status,
    required String search,
  }) {
    if (state is StudentsByClassSectionFetchSuccess) {
      emit(
        (state as StudentsByClassSectionFetchSuccess).copyWith(
          searchStatus: StudentByClassSectionSearchStatus.loading,
        ),
      );

      _studentRepository
          .getStudentsByClassSectionAndSubject(
        classSectionId: classSectionId,
        classSubjectId: classSubjectId,
        examId: examId,
        search: search,
      )
          .then(
        (list) {
          if (isClosed) return;
          emit(
            (state as StudentsByClassSectionFetchSuccess).copyWith(
              searchStatus: StudentByClassSectionSearchStatus.success,
              searchedStudentDetailsList: list,
            ),
          );
        },
      ).catchError(
        (e) {
          if (isClosed) return;
          final userFriendlyMessage =
              ErrorMessageUtils.getReadableErrorMessage(e);
          emit(
            (state as StudentsByClassSectionFetchSuccess).copyWith(
              searchStatus: StudentByClassSectionSearchStatus.failure,
              searchErrorMessage: userFriendlyMessage,
            ),
          );
          debugPrint(
              'Technical error: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
        },
      );
    }
  }

  void clearSearch() {
    if (state is StudentsByClassSectionFetchSuccess) {
      emit(
        (state as StudentsByClassSectionFetchSuccess).copyWith(
          searchStatus: StudentByClassSectionSearchStatus.initial,
          searchedStudentDetailsList: null,
        ),
      );
    }
  }

  List<StudentDetails> getStudents() {
    return (state is StudentsByClassSectionFetchSuccess)
        ? (state as StudentsByClassSectionFetchSuccess).studentDetailsList
        : [];
  }
}

