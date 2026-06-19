// ignore: depend_on_referenced_packages
import 'package:bloc/bloc.dart';
import 'package:eschool_saas_staff/data/repositories/student/studentRepository.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';

abstract class SubmitExamMarksState {}

class SubmitExamMarksInitial extends SubmitExamMarksState {}

class SubmitExamMarksSubmitInProgress extends SubmitExamMarksState {}

class SubmitExamMarksSubmitSuccess extends SubmitExamMarksState {}

class SubmitExamMarksSubmitFailure extends SubmitExamMarksState {
  final String errorMessage;

  SubmitExamMarksSubmitFailure({required this.errorMessage});
}

class SubmitExamMarksCubit extends Cubit<SubmitExamMarksState> {
  final StudentRepository studentRepository = StudentRepository();

  SubmitExamMarksCubit() : super(SubmitExamMarksInitial());

  Future<void> submitOfflineExamMarks({
    required int classSubjectId,
    required int classSectionId,
    required int examId,
    required int examTimetableId,
    required Map<String, dynamic> marksDataValue,
  }) async {
    emit(SubmitExamMarksSubmitInProgress());
    try {
      await studentRepository.addOfflineExamMarks(
        examId: examId,
        marksDataValue: marksDataValue,
        classSubjectId: classSubjectId,
        classSectionId: classSectionId,
        examTimetableId: examTimetableId,
      );
      if (isClosed) return;
      emit(SubmitExamMarksSubmitSuccess());
    } catch (e) {
      if (isClosed) return;
      // Gunakan ErrorMessageUtils untuk mengkonversi error teknis menjadi pesan yang ramah
      // Check if error is numeric (integer or string number)
      final errorString = e.toString();
      final isNumericError = int.tryParse(errorString) != null;

      if (isNumericError) {
        final userFriendlyMessage =
            ErrorMessageUtils.getReadableErrorMessage(e);
        emit(SubmitExamMarksSubmitFailure(errorMessage: userFriendlyMessage));
      } else {
        emit(SubmitExamMarksSubmitFailure(errorMessage: errorString));
      }
    }
  }
}
