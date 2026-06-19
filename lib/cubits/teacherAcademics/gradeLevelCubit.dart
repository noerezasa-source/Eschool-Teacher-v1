import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/data/models/academic/gradeLevel.dart';
import 'package:eschool_saas_staff/data/repositories/teacherRepository.dart';

abstract class GradeLevelState {}

class GradeLevelInitial extends GradeLevelState {}

class GradeLevelFetchInProgress extends GradeLevelState {}

class GradeLevelFetchSuccess extends GradeLevelState {
  final List<GradeLevel> gradeLevels;

  GradeLevelFetchSuccess({required this.gradeLevels});
}

class GradeLevelFetchFailure extends GradeLevelState {
  final String errorMessage;

  GradeLevelFetchFailure(this.errorMessage);
}

class GradeLevelCubit extends Cubit<GradeLevelState> {
  final TeacherRepository _teacherRepository = TeacherRepository();

  GradeLevelCubit() : super(GradeLevelInitial());

  void getGradeLevels() async {
    emit(GradeLevelFetchInProgress());
    try {
      final gradeLevelsResult = await _teacherRepository.getGradeLevels();
      if (isClosed) return;
      emit(GradeLevelFetchSuccess(gradeLevels: gradeLevelsResult));
    } catch (e) {
      if (isClosed) return;
      emit(GradeLevelFetchFailure(e.toString()));
    }
  }
}
