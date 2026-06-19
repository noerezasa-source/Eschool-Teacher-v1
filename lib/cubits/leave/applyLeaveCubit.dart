import 'package:eschool_saas_staff/data/repositories/leave/leaveRepository.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

abstract class ApplyLeaveState {}

class ApplyLeaveInitial extends ApplyLeaveState {}

class ApplyLeaveInProgress extends ApplyLeaveState {}

class ApplyLeaveSuccess extends ApplyLeaveState {}

class ApplyLeaveFailure extends ApplyLeaveState {
  final String errorMessage;

  ApplyLeaveFailure(this.errorMessage);
}

class ApplyLeaveCubit extends Cubit<ApplyLeaveState> {
  final LeaveRepository _leaveRepository = LeaveRepository();

  ApplyLeaveCubit() : super(ApplyLeaveInitial());

  void applyLeave(
      {required String reason,
      required Map<DateTime, String> leaveDays,
      List<String>? attachmentPaths}) async {
    try {
      List<Map<String, String>> leaveDetails = [];

      for (var leaveDay in leaveDays.keys) {
        // Ensure standard YYYY-MM-DD format with zero-padding for months and days
        final year = leaveDay.year;
        final month = leaveDay.month.toString().padLeft(2, '0');
        final day = leaveDay.day.toString().padLeft(2, '0');

        leaveDetails.add({
          "type": getLeaveTypeValueFromKey(leaveTypeKey: leaveDays[leaveDay]!),
          "date": "$year-$month-$day"
        });
      }
      emit(ApplyLeaveInProgress());
      await _leaveRepository.applyLeave(
        leaves: leaveDetails,
        reason: reason,
        attachmentPaths: attachmentPaths,
      );
      emit(ApplyLeaveSuccess());
    } catch (e) {
      // Gunakan ErrorMessageUtils untuk mengkonversi error teknis menjadi pesan yang ramah
      final userFriendlyMessage = ErrorMessageUtils.getReadableErrorMessage(e);
      emit(ApplyLeaveFailure(userFriendlyMessage));

      // Log technical error untuk debugging (hanya untuk development)
      debugPrint(
          'Technical error in applyLeave: ${ErrorMessageUtils.getTechnicalErrorMessage(e)}');
    }
  }
}
