import 'package:eschool_saas_staff/data/models/academic/assignmentSubmission.dart';
import 'package:eschool_saas_staff/data/models/academic/studyMaterial.dart';
import 'package:eschool_saas_staff/utils/system/app_config.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:flutter/material.dart';

//[URL dikelola oleh AppConfig — pilih via env switcher di runtime]
// static const tersedia di AppConfig.devUrl / prodUrl / testingUrl
String get baseUrl => AppConfig.baseUrl;
String get databaseUrl => AppConfig.databaseUrl;
String get storageUrl => "${AppConfig.baseUrl}/storage/";

// Socket url
const socketUrl = "ws://193.203.162.252:8090";

// FCM Topics
const String staffNotificationsTopic = 'staff_notifications';
const String allNotificationsTopic = 'all_notifications';

// Web socket ping interval
const socketPingInterval = Duration(seconds: 275);

///[Socket events]
enum SocketEvent { register, message }

double appContentHorizontalPadding = 15.0;
double horizontalCompetitionListHeight = 70.0;
double bottomsheetBorderRadius = 15.0;
Duration snackBarDuration = const Duration(milliseconds: 1000);
Duration tabDuration = const Duration(milliseconds: 500);
Duration tileCollapsedDuration = const Duration(milliseconds: 500);
int nextSearchRequestQueryTimeInMilliSeconds = 700;
int searchRequestPerodicMilliSeconds = 100;
double topPaddingOfErrorAndLoadingContainer = 150;

// String defaultSchoolCode = "";
// String defaultEmail = "agungcahyono533@gmail.com";
// String defaultPassword = "081230093978";

String defaultSchoolCode = "";
String defaultEmail = "agungcahyono533@gmail.com";
String defaultPassword = "smkn8*()";

// String defaultSchoolCode = "";
// String defaultEmail = "adminsmk8malang@gmail.com";
// String defaultPassword = "smkn8*()";

// String defaultSchoolCode = "";
// String defaultEmail = "adminblimbingsdn100@sekolahku.id";
// String defaultPassword = "087890123456";

// Default credentials are now handled by Remember Me functionality
// Use the checkbox in login form to save credentials safely
// String defaultSchoolCode = "";
// String defaultEmail = "";
// String defaultPassword = "";

List<String> months = [
  januaryKey,
  februaryKey,
  marchKey,
  aprilKey,
  mayKey,
  juneKey,
  julyKey,
  augustKey,
  septemberKey,
  octoberKey,
  novemberKey,
  decemberKey
];

enum LeaveDayType { today, tomorrow, upcoming }

int getLeaveDayTypeStatus({required LeaveDayType leaveDayType}) {
  if (leaveDayType == LeaveDayType.tomorrow) {
    return 1;
  }

  if (leaveDayType == LeaveDayType.upcoming) {
    return 2;
  }

  return 0;
}

int getSatusValueFromKey({required String value}) {
  if (value == activeKey) {
    return 1;
  }
  if (value == inactiveKey) {
    return 2;
  }

  return 0;
}

const List<String> weekDays = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday"
];

String getLeaveTypeValueFromKey({required String leaveTypeKey}) {
  if (leaveTypeKey == firstHalfKey) {
    return "First Half";
  }
  if (leaveTypeKey == secondHalfKey) {
    return "Second Half";
  }
  return "Full";
}

///[ 0 -> Pending, 1 -> Approved, 2 -> Rejected ]
enum LeaveRequestStatus { pending, approved, rejected }

LeaveRequestStatus getLeaveRequestStatusEnumFromValue(int status) {
  if (status == 1) {
    return LeaveRequestStatus.approved;
  }

  if (status == 2) {
    return LeaveRequestStatus.rejected;
  }

  return LeaveRequestStatus.pending;
}

String getLeaveRequestStatusKey(LeaveRequestStatus leaveRequestStatus) {
  if (leaveRequestStatus == LeaveRequestStatus.approved) {
    return approvedKey;
  }

  if (leaveRequestStatus == LeaveRequestStatus.rejected) {
    return rejectedKey;
  }

  return pendingKey;
}

enum StudentListStatus { all, active, inactive }

// 0 => Absent, 1 => Present
enum StudentAttendanceStatus { absent, present, sick, permission, alpa }

StudentAttendanceStatus getStudentAttendanceStatusFromValue(int status) {
  debugPrint('Getting attendance status for value: $status');

  StudentAttendanceStatus result;
  if (status == 0) {
    result = StudentAttendanceStatus.absent;
  } else if (status == 1) {
    result = StudentAttendanceStatus.present;
  } else if (status == 2) {
    result = StudentAttendanceStatus.sick;
  } else if (status == 3) {
    result = StudentAttendanceStatus.permission;
  } else if (status == 4) {
    result = StudentAttendanceStatus.alpa;
  } else {
    result = StudentAttendanceStatus.absent;
  }

  debugPrint(
      'Attendance status resolved to: ${result.toString().split('.').last}');
  return result;
}

String getStudentAttendanceStatusKey(
    StudentAttendanceStatus studentAttendanceStatus) {
  if (studentAttendanceStatus == StudentAttendanceStatus.absent) {
    return absentKey;
  } else if (studentAttendanceStatus == StudentAttendanceStatus.present) {
    return presentKey;
  } else if (studentAttendanceStatus == StudentAttendanceStatus.sick) {
    return sickKey;
  } else if (studentAttendanceStatus == StudentAttendanceStatus.permission) {
    return permissionKey;
  } else if (studentAttendanceStatus == StudentAttendanceStatus.alpa) {
    return alpaKey;
  }
  return presentKey;
}

//assignment submission statuses
final List<AssignmentSubmissionStatus> allAssignmentSubmissionStatus = [
  AssignmentSubmissionStatus(
    typeStatusId: -1,
    titleKey: allKey,
    filter: AssignmentSubmissionFilters.all,
    color: Colors.black,
  ),
  AssignmentSubmissionStatus(
    typeStatusId: 0,
    titleKey: pendingKey,
    filter: AssignmentSubmissionFilters.submitted,
    color: Colors.orange,
  ),
  AssignmentSubmissionStatus(
    typeStatusId: 1,
    titleKey: acceptedKey,
    filter: AssignmentSubmissionFilters.accepted,
    color: Colors.green,
  ),
  AssignmentSubmissionStatus(
    typeStatusId: 2,
    titleKey: rejectedKey,
    filter: AssignmentSubmissionFilters.rejected,
    color: Colors.red,
  ),
  AssignmentSubmissionStatus(
    typeStatusId: 3,
    titleKey: resubmittedKey,
    filter: AssignmentSubmissionFilters.resubmitted,
    color: Colors.orange,
  ),
];

//For Study Material type dropdown items
List<StudyMaterialTypeItem> allStudyMaterialTypeItems = [
  StudyMaterialTypeItem(
    type: 1,
    title: fileUploadKey,
  ),
  StudyMaterialTypeItem(
    type: 2,
    title: youtubeLinkKey,
  ),
  StudyMaterialTypeItem(
    type: 3,
    title: videoUploadKey,
  ),
];

const String teacherRoleKey = "Teacher";
const String studentRoleKey = "Student";
const String guardianRoleKey = "Guardian";

const String allUserSendNotificationTypeKey = "All users";
const String specificUserSendNotificationTypeKey = "Specific users";
const String overDueFeesNotificationTypeKey = "Over Due Fees";
const String specificRolesSendNotificationTypeKey = "Roles";

const String schoolAdminRoleKey = "School Admin";
