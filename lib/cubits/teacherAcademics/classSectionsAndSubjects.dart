
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/academic/teacherSubject.dart';
import 'package:eschool_saas_staff/data/repositories/academics/academicRepository.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

abstract class ClassSectionsAndSubjectsState {}

class ClassSectionsAndSubjectsInitial extends ClassSectionsAndSubjectsState {}

class ClassSectionsAndSubjectsFetchInProgress
    extends ClassSectionsAndSubjectsState {}

class ClassSectionsAndSubjectsFetchSuccess
    extends ClassSectionsAndSubjectsState {
  final List<ClassSection> classSections;
  final List<TeacherSubject> subjects;

  ClassSectionsAndSubjectsFetchSuccess(
      {required this.classSections, required this.subjects});
}

class ClassSectionsAndSubjectsFetchFailure
    extends ClassSectionsAndSubjectsState {
  final String errorMessage;

  ClassSectionsAndSubjectsFetchFailure(this.errorMessage);
}

class ClassSectionsAndSubjectsCubit
    extends Cubit<ClassSectionsAndSubjectsState> {
  final AcademicRepository _academicRepository = AcademicRepository();

  ClassSectionsAndSubjectsCubit() : super(ClassSectionsAndSubjectsInitial());

  void getClassSectionsAndSubjects(
      {int? classSectionId, int? gradeLevelId}) async {
    try {
      debugPrint(
          "ClassSectionsAndSubjectsCubit: Starting to fetch class sections and subjects");
      emit(ClassSectionsAndSubjectsFetchInProgress());

      final classesResult = await _academicRepository.getClasses(
        modeAll: true,
        gradeLevelId: gradeLevelId,
      );

      debugPrint(
          "ClassSectionsAndSubjectsCubit: Received classes - Primary: ${classesResult.primaryClasses.length}, Other: ${classesResult.classes.length}");

      //
      List<ClassSection> classSections =
          List<ClassSection>.from(classesResult.classes);
      classSections
          .addAll(List<ClassSection>.from(classesResult.primaryClasses));

      debugPrint(
          "ClassSectionsAndSubjectsCubit: Combined total classes: ${classSections.length}");

      final subjects = await _academicRepository.getClassSectionSubjects(
          classSectionId: classSectionId ?? classSections.first.id ?? 0);
      if (isClosed) return;
      emit(ClassSectionsAndSubjectsFetchSuccess(
          classSections: classSections,
          subjects: subjects));
    } catch (e) {
      debugPrint("ClassSectionsAndSubjectsCubit: Error occurred - $e");
      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      if (isClosed) return;
      emit(ClassSectionsAndSubjectsFetchFailure(userFriendlyMessage));
      debugPrint(
          'Technical error: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
    }
  }

  Future<void> getNewSubjectsFromSelectedClassSectionIndex(
      {required int newClassSectionId}) async {
    if (state is ClassSectionsAndSubjectsFetchSuccess) {
      final successState = (state as ClassSectionsAndSubjectsFetchSuccess);
      final subjects = await _academicRepository.getClassSectionSubjects(
          classSectionId: newClassSectionId);
      if (isClosed) return;
      emit(ClassSectionsAndSubjectsFetchSuccess(
          classSections: successState.classSections,
          subjects: subjects));
    }
  }
}

