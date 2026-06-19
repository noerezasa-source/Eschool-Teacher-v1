import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/data/models/extracurricular/extracurricular.dart';
import 'package:eschool_saas_staff/data/repositories/extracurricular/extracurricularRepository.dart';
import 'package:eschool_saas_staff/data/models/auth/user.dart';
import 'package:flutter/foundation.dart';

abstract class ExtracurricularState {}

class ExtracurricularInitial extends ExtracurricularState {}

class ExtracurricularLoading extends ExtracurricularState {}

class ExtracurricularSuccess extends ExtracurricularState {
  final List<Extracurricular> extracurriculars;
  final List<Extracurricular> archivedExtracurriculars;

  ExtracurricularSuccess({
    required this.extracurriculars,
    required this.archivedExtracurriculars,
  });
}

class TeachersStaffLoading extends ExtracurricularState {}

class TeachersStaffSuccess extends ExtracurricularState {
  final List<User> users;

  TeachersStaffSuccess(this.users);
}

class TeachersStaffFailure extends ExtracurricularState {
  final String errorMessage;

  TeachersStaffFailure(this.errorMessage);
}

class ExtracurricularFailure extends ExtracurricularState {
  final String errorMessage;

  ExtracurricularFailure(this.errorMessage);
}

class ExtracurricularCubit extends Cubit<ExtracurricularState> {
  final ExtracurricularRepository _extracurricularRepository;

  static final Set<int> _optimisticRestoredIds = {};
  static final Map<int, Extracurricular> _optimisticRestoredExtracurriculars = {};

  ExtracurricularCubit(this._extracurricularRepository)
      : super(ExtracurricularInitial());

  void addExtracurricular(Extracurricular extracurricular) {
    _optimisticRestoredIds.add(extracurricular.id);
    _optimisticRestoredExtracurriculars[extracurricular.id] = extracurricular;

    final currentState = state;
    if (currentState is ExtracurricularSuccess) {
      if (currentState.extracurriculars.any((e) => e.id == extracurricular.id)) {
        return;
      }
      final updatedExtracurriculars = List<Extracurricular>.from(currentState.extracurriculars);
      updatedExtracurriculars.insert(0, extracurricular);
      emit(ExtracurricularSuccess(
        extracurriculars: updatedExtracurriculars,
        archivedExtracurriculars: currentState.archivedExtracurriculars,
      ));
    }
  }

  // Get active extracurriculars
  Future<void> getExtracurriculars() async {
    debugPrint(' [EXTRACURRICULAR CUBIT] Fetching extracurriculars...');
    emit(ExtracurricularLoading());
    try {
      final extracurriculars =
          await _extracurricularRepository.getExtracurriculars();

      for (var ec in extracurriculars) {
        _optimisticRestoredIds.remove(ec.id);
        _optimisticRestoredExtracurriculars.remove(ec.id);
      }

      final List<Extracurricular> activeList = List<Extracurricular>.from(extracurriculars);
      for (var id in _optimisticRestoredIds) {
        if (_optimisticRestoredExtracurriculars.containsKey(id)) {
          final ec = _optimisticRestoredExtracurriculars[id]!;
          if (!activeList.any((e) => e.id == ec.id)) {
            activeList.insert(0, ec);
          }
        }
      }

      final currentState = state;
      final archivedExtracurriculars = currentState is ExtracurricularSuccess
          ? currentState.archivedExtracurriculars
          : <Extracurricular>[];

      debugPrint(
          '✅ [EXTRACURRICULAR CUBIT] Success: ${activeList.length} active extracurriculars');
      emit(ExtracurricularSuccess(
        extracurriculars: activeList,
        archivedExtracurriculars: archivedExtracurriculars,
      ));
    } catch (e) {
      debugPrint('❌ [EXTRACURRICULAR CUBIT] Error: $e');
      emit(ExtracurricularFailure(e.toString()));
    }
  }

  // Get archived extracurriculars
  Future<void> getArchivedExtracurriculars() async {
    debugPrint('🗂️ [EXTRACURRICULAR CUBIT] Fetching archived extracurriculars...');
    emit(ExtracurricularLoading());
    try {
      final archivedExtracurriculars =
          await _extracurricularRepository.getArchivedExtracurriculars();
      final currentState = state;
      final extracurriculars = currentState is ExtracurricularSuccess
          ? currentState.extracurriculars
          : <Extracurricular>[];

      debugPrint(
          '✅ [EXTRACURRICULAR CUBIT] Success: ${archivedExtracurriculars.length} archived extracurriculars');
      emit(ExtracurricularSuccess(
        extracurriculars: extracurriculars,
        archivedExtracurriculars: archivedExtracurriculars,
      ));
    } catch (e) {
      debugPrint('❌ [EXTRACURRICULAR CUBIT] Archived fetch failed: $e');
      emit(ExtracurricularFailure(e.toString()));
    }
  }

  // Create extracurricular
  Future<void> createExtracurricular({
    required String name,
    required String description,
    required int coachId,
  }) async {
    debugPrint('➕ [EXTRACURRICULAR CUBIT] Creating: $name');
    try {
      await _extracurricularRepository.createExtracurricular(
        name: name,
        description: description,
        coachId: coachId,
      );
      debugPrint('✅ [EXTRACURRICULAR CUBIT] Created successfully');
      await getExtracurriculars();
    } catch (e) {
      debugPrint('❌ [EXTRACURRICULAR CUBIT] Create failed: $e');
      emit(ExtracurricularFailure(e.toString()));
      rethrow;
    }
  }

  // Update extracurricular
  Future<void> updateExtracurricular({
    required int id,
    required String name,
    required String description,
    required int coachId,
  }) async {
    debugPrint('✏️ [EXTRACURRICULAR CUBIT] Updating ID $id: $name');
    try {
      await _extracurricularRepository.updateExtracurricular(
        id: id,
        name: name,
        description: description,
        coachId: coachId,
      );
      debugPrint('✅ [EXTRACURRICULAR CUBIT] Updated successfully');
      await getExtracurriculars();
    } catch (e) {
      debugPrint('❌ [EXTRACURRICULAR CUBIT] Update failed: $e');
      emit(ExtracurricularFailure(e.toString()));
      rethrow;
    }
  }

  // Delete (Archive) extracurricular
  Future<void> deleteExtracurricular(int id) async {
    debugPrint('🗂️ [EXTRACURRICULAR CUBIT] Archiving ID: $id');

    // Optimistic update: immediately remove from UI
    final currentState = state;
    if (currentState is ExtracurricularSuccess) {
      final updatedExtracurriculars =
          currentState.extracurriculars.where((e) => e.id != id).toList();

      emit(ExtracurricularSuccess(
        extracurriculars: updatedExtracurriculars,
        archivedExtracurriculars: currentState.archivedExtracurriculars,
      ));
    }

    try {
      await _extracurricularRepository.deleteExtracurricular(id);
      debugPrint('✅ [EXTRACURRICULAR CUBIT] Archived successfully');
      // Refresh data silently without loading state
      await _refreshDataSilently();
    } catch (e) {
      debugPrint('❌ [EXTRACURRICULAR CUBIT] Archive failed: $e');
      // Revert optimistic update on error
      await _refreshDataSilently();
      emit(ExtracurricularFailure(e.toString()));
      rethrow;
    }
  }

  // Restore extracurricular
  Future<void> restoreExtracurricular(int id) async {
    debugPrint('🔄 [EXTRACURRICULAR CUBIT] Restoring ID: $id');
    try {
      await _extracurricularRepository.restoreExtracurricular(id);
      debugPrint(
          '✅ [EXTRACURRICULAR CUBIT] Restored successfully, refreshing data...');

      // Refresh both archived and active data for immediate UI update
      await getArchivedExtracurriculars();
      await getExtracurriculars();

      debugPrint('🔄 [EXTRACURRICULAR CUBIT] Data refreshed after restore');
    } catch (e) {
      debugPrint('❌ [EXTRACURRICULAR CUBIT] Restore failed: $e');
      emit(ExtracurricularFailure(e.toString()));
      rethrow;
    }
  }

  // Force delete extracurricular
  Future<void> forceDeleteExtracurricular(int id) async {
    try {
      await _extracurricularRepository.forceDeleteExtracurricular(id);
      await getArchivedExtracurriculars();
    } catch (e) {
      emit(ExtracurricularFailure(e.toString()));
      rethrow;
    }
  }

  // Get teachers and staff list
  Future<void> getTeachersStaffList() async {
    debugPrint('🔍 [EXTRACURRICULAR CUBIT] Fetching teachers/staff list...');
    emit(TeachersStaffLoading());
    try {
      final users = await _extracurricularRepository.getTeachersStaffList();
      debugPrint('✅ [EXTRACURRICULAR CUBIT] Success: ${users.length} users');
      emit(TeachersStaffSuccess(users));
    } catch (e) {
      debugPrint('❌ [EXTRACURRICULAR CUBIT] Error: $e');
      emit(TeachersStaffFailure(e.toString()));
    }
  }

  // Private method to refresh data without emitting loading states
  Future<void> _refreshDataSilently() async {
    try {
      final extracurriculars =
          await _extracurricularRepository.getExtracurriculars();

      for (var ec in extracurriculars) {
        _optimisticRestoredIds.remove(ec.id);
        _optimisticRestoredExtracurriculars.remove(ec.id);
      }

      final List<Extracurricular> activeList = List<Extracurricular>.from(extracurriculars);
      for (var id in _optimisticRestoredIds) {
        if (_optimisticRestoredExtracurriculars.containsKey(id)) {
          final ec = _optimisticRestoredExtracurriculars[id]!;
          if (!activeList.any((e) => e.id == ec.id)) {
            activeList.insert(0, ec);
          }
        }
      }

      final archivedExtracurriculars =
          await _extracurricularRepository.getArchivedExtracurriculars();

      emit(ExtracurricularSuccess(
        extracurriculars: activeList,
        archivedExtracurriculars: archivedExtracurriculars,
      ));
    } catch (e) {
      debugPrint('❌ [EXTRACURRICULAR CUBIT] Silent refresh failed: $e');
      // Don't emit failure state during silent refresh to avoid UI disruption
    }
  }
}
