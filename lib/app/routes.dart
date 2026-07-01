import 'dart:convert';

import 'package:eschool_saas_staff/ui/screens/system/AboutUsScreen.dart';
import 'package:eschool_saas_staff/ui/screens/system/PrivacyPolicyScreen.dart';
import 'package:eschool_saas_staff/ui/screens/system/TermsAndConditionScreen.dart';
import 'package:flutter/material.dart';
import 'package:eschool_saas_staff/ui/screens/system/addAnnouncementScreen.dart';
import 'package:eschool_saas_staff/ui/screens/addNotification/addNotificationScreen.dart';
import 'package:eschool_saas_staff/ui/screens/payroll/allowancesAndDeductionsScreen.dart';
import 'package:eschool_saas_staff/ui/screens/leave/applyLeaveScreen.dart';
import 'package:eschool_saas_staff/ui/screens/auth/changePasswordScreen.dart';
import 'package:eschool_saas_staff/ui/screens/academics/classTimeTableScreen.dart';
import 'package:eschool_saas_staff/ui/screens/academics/classesScreen.dart';
import 'package:eschool_saas_staff/ui/screens/system/contactUsScreen.dart';
import 'package:eschool_saas_staff/ui/screens/contact/contactListScreen.dart';
import 'package:eschool_saas_staff/ui/screens/contact/contactDetailScreen.dart';
import 'package:eschool_saas_staff/ui/screens/contact/submitContactScreen.dart';
import 'package:eschool_saas_staff/cubits/contact/contactListCubit.dart';
import 'package:eschool_saas_staff/cubits/contact/contactDetailCubit.dart';
import 'package:eschool_saas_staff/cubits/contact/submitContactCubit.dart';
import 'package:eschool_saas_staff/cubits/contact/contactStatsCubit.dart';
import 'package:eschool_saas_staff/data/repositories/chat/contactRepository.dart';
import 'package:eschool_saas_staff/ui/screens/system/editAnnouncementScreen.dart';
import 'package:eschool_saas_staff/ui/screens/auth/editProfileScreen.dart';
import 'package:eschool_saas_staff/ui/screens/exam/examsScreen.dart';
import 'package:eschool_saas_staff/ui/screens/system/generalLeavesScreen.dart';
import 'package:eschool_saas_staff/ui/screens/system/generalPermissionScreen.dart';
import 'package:eschool_saas_staff/ui/screens/system/holidaysScreen.dart';
import 'package:eschool_saas_staff/ui/screens/home/homeScreen.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/chatContainer/chatContainer.dart';
import 'package:eschool_saas_staff/ui/screens/leave/leaveRequestsScreen.dart';
import 'package:eschool_saas_staff/ui/screens/leaves/leavesScreen.dart';
import 'package:eschool_saas_staff/ui/screens/login/loginScreen.dart';
import 'package:eschool_saas_staff/ui/screens/onlineExam/archiveOnlineExam.dart';
import 'package:eschool_saas_staff/ui/screens/manageAnnouncement/manageAnnouncementScreen.dart';
import 'package:eschool_saas_staff/ui/screens/manageNotification/manageNotificationScreen.dart';
import 'package:eschool_saas_staff/ui/screens/managePayrolls/managePayrollsScreen.dart';
import 'package:eschool_saas_staff/ui/screens/payroll/myPayrollScreen.dart';
import 'package:eschool_saas_staff/ui/screens/system/notificationsScreen.dart';
import 'package:eschool_saas_staff/ui/screens/offlineResult/offlineResultScreen.dart';
import 'package:eschool_saas_staff/ui/screens/onlineExam/onlineExamResultQuestionsScreen.dart';
import 'package:eschool_saas_staff/ui/screens/onlineExam/onlineExamResultAnswerScreen.dart';
import 'package:eschool_saas_staff/ui/screens/onlineExam/onlineExamResult.dart';
import 'package:eschool_saas_staff/ui/screens/payroll/paidFeesScreen.dart';
import 'package:eschool_saas_staff/ui/screens/staff/searchTeachersScreen.dart';
import 'package:eschool_saas_staff/ui/screens/system/searchUsersScreen.dart';
import 'package:eschool_saas_staff/ui/screens/system/sessionYearsScreen.dart';
import 'package:eschool_saas_staff/ui/screens/system/splashScreen.dart';
import 'package:eschool_saas_staff/ui/screens/staff/staffDetailsScreen.dart';
import 'package:eschool_saas_staff/ui/screens/staff/staffsScreen.dart';
import 'package:eschool_saas_staff/ui/screens/student/studentProfileScreen.dart';
import 'package:eschool_saas_staff/ui/screens/student/studentsAttendanceScreen.dart';
import 'package:eschool_saas_staff/ui/screens/student/studentsScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/rankingAttendanceScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/recapAttendanceSubjectScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherAddAttendanceScreeen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherAddAttendanceSubjectScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherAddEditAnnouncementScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherAddEditAssignmentScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherAddEditLessonScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherAddEditTopicScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherClassSectionScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherEditAssignmentSubmission.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherExamResultScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherManageAnnouncementScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherManageAssignmentScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherManageAssignmentSubmissionScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherManageLessonScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherManageTopicScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherMyTimetableScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherViewAttendanceScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherViewAttendanceSubjectScreen.dart';
import 'package:eschool_saas_staff/ui/screens/staff/teacherProfileScreen.dart';
import 'package:eschool_saas_staff/ui/screens/academics/teacherTimeTableDetailsScreen.dart';
import 'package:eschool_saas_staff/ui/screens/staff/teachersScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/attendanceRecapScreen.dart';
import 'package:get/get.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/questionBankListScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/questionSubjectScreen.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/assignment/questionBankCubit.dart';
import 'package:eschool_saas_staff/data/repositories/exam/questionBankRepository.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/addQuestionScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/editQuestionScreen.dart';
import 'package:eschool_saas_staff/data/models/exam/subjectQuestion.dart';
import 'package:eschool_saas_staff/data/models/exam/questionBank.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/bankQuestionScreen.dart';
import 'package:eschool_saas_staff/ui/screens/onlineExam/onlineExamScreen.dart';
import 'package:eschool_saas_staff/ui/screens/onlineExam/createOnlineExam.dart';
import 'package:eschool_saas_staff/ui/screens/onlineExam/editOnlineExam.dart';
import 'package:flutter_bloc/flutter_bloc.dart' hide Transition;
import 'package:eschool_saas_staff/cubits/onlineExam/onlineExamCubit.dart';
import 'package:eschool_saas_staff/cubits/questionOnlineExam/questionOnlineExamCubit.dart';
import 'package:eschool_saas_staff/data/repositories/exam/onlineExamRepository.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/classSectionsAndSubjects.dart';
import 'package:eschool_saas_staff/ui/screens/onlineExam/questionOnlineExamScreen.dart';
import 'package:eschool_saas_staff/ui/screens/onlineExam/BankSoalSelectionScreen.dart';
import 'package:eschool_saas_staff/ui/screens/onlineExam/previewQuestionBankSoal.dart';
import 'package:eschool_saas_staff/data/models/exam/BankOnlineQuestion.dart';
import 'package:eschool_saas_staff/ui/screens/onlineExam/examStatuScreen.dart';
import 'package:eschool_saas_staff/cubits/examStatus/examStatusCubit.dart';
import 'package:eschool_saas_staff/cubits/academics/sessionYearsAndMediumsCubit.dart';
import 'package:eschool_saas_staff/data/repositories/exam/examStatusRepository.dart';
import 'package:eschool_saas_staff/ui/screens/assignmentMonitoring/assignmentMonitoringScreen.dart';
import 'package:eschool_saas_staff/ui/screens/assignmentMonitoring/assignmentDetailMonitoringScreen.dart';
import 'package:eschool_saas_staff/ui/screens/extracurricular/extracurricularScreen.dart';
import 'package:eschool_saas_staff/ui/screens/extracurricular/createExtracurricular.dart';
import 'package:eschool_saas_staff/ui/screens/extracurricular/editExtracurricular.dart';
import 'package:eschool_saas_staff/ui/screens/extracurricular/archiveExtracurricular.dart';
import 'package:eschool_saas_staff/ui/screens/extracurricular/extracurricularTimetableScreen.dart';
import 'package:eschool_saas_staff/ui/screens/extracurricular/createExtracurricularTimetableScreen.dart';
import 'package:eschool_saas_staff/ui/screens/extracurricular/extracurricularMemberScreen.dart';
import 'package:eschool_saas_staff/cubits/extracurricular/extracurricularCubit.dart';
import 'package:eschool_saas_staff/cubits/extracurricularTimetable/extracurricularTimetableCubit.dart';
import 'package:eschool_saas_staff/cubits/extracurricularMember/extracurricularMemberCubit.dart';
import 'package:eschool_saas_staff/data/repositories/extracurricular/extracurricularRepository.dart';
import 'package:eschool_saas_staff/data/repositories/extracurricular/extracurricularTimetableRepository.dart';
import 'package:eschool_saas_staff/data/repositories/extracurricular/extracurricularMemberRepository.dart';
import 'package:eschool_saas_staff/ui/screens/extracurricular/extracurricularAttendanceScreen.dart';

// Nama route
class Routes {
  static String splashScreen = "/splash";

  static String homeScreen = "/";
  static String loginScreen = "/login";
  static String teachersScreen = "/teachers";
  static String teacherProfileScreen = "/teacherProfile";
  static String staffsScreen = "/staffs";
  static String staffDetailsScreen = "/staffDetails";
  static String studentsScreen = "/students";
  static String studentProfileScreen = "/studentProfile";
  static String leaveRequestScreen = "/leaveRequest";
  static String teacherTimeTableDetailsScreen = "/teacherTimeTableDetails";
  static String generalLeavesScreen = "/generalLeaves";
  static String generalPermissionScreen = "/generalPermission";
  static String holidaysScreen = "/holidays";
  static String applyLeaveScreen = "/applyLeave";
  static String leavesScreen = "/leaves";
  static String studentsAttendanceScreen = "/studentsAttendance";
  static String offlineResultScreen = "/offlineResult";
  static String manageNotificationScreen = "/manageNotification";
  static String addNotificationScreen = "/addNotification";
  static String manageAnnouncementScreen = "/manageAnnouncement";
  static String addAnnouncementScreen = "/addAnnouncement";
  static String paidFeesScreen = "/paidFees";
  static String managePayrollScreen = "/managePayroll";
  static String myPayrollScreen = "/myPayroll";
  static String editProfileScreen = "/editProfile";
  static String changePasswordScreen = "/changePassword";
  static String searchTeachersScreen = "/searchTeachers";
  static String notificationsScreen = "/notifications";
  static String classesScreen = "/classes";
  static String classTimetableScreen = "/classTimetable";
  static String examsScreen = "/exams";
  static String editAnnouncementScreen = "/editAnnouncement";
  static String searchUsersScreen = "/searchUsers";
  static String aboutUsScreen = "/aboutUs";
  static String contactUsScreen = "/contactUS";
  static String privacyPolicyScreen = "/privacyPolicy";
  static String termsAndConditionScreen = "/termsAndCondition";
  static String assignmentMonitoringScreen = "/assignmentMonitoring";
  static String assignmentDetailMonitoringScreen =
      "/assignmentDetailMonitoring";

  static String sessionYearsScreen = "/sessionYears";
  static String allowancesAndDeductionsScreen = "/allowancesAndDeductions";

  // Extracurricular routes
  static String extracurricularScreen = "/extracurricular";
  static String createExtracurricular = "/createExtracurricular";
  static String editExtracurricular = "/editExtracurricular";
  static String archiveExtracurricular = "/archiveExtracurricular";
  static String extracurricularTimetable = "/extracurricularTimetable";
  static String createExtracurricularTimetable =
      "/createExtracurricularTimetable";
  static String extracurricularMember = "/extracurricularMember";
  static String extracurricularAttendance = "/extracurricularAttendance";

  //teacher academics routes
  static String teacherMyTimetableScreen = "/teacherMyTimetable";
  static String teacherClassSectionScreen = "/teacherClassSection";
  static String teacherAddAttendanceScreen = "/teacherAddAttendance";
  static String teacherAddAttendanceSubjectScreen =
      "/teacherAddAttendanceSubject";
  static String teacherViewAttendanceScreen = "/teacherViewAttendance";
  static String teacherViewAttendanceSubjectScreen =
      "/teacherViewAttendanceSubject";
  static String recapAttendanceSubjectScreen = "/recapAttendanceSubject";
  static String attendanceRecapScreen = "/attendanceRecap";
  static String attendanceRankingScreen = "/attendanceRanking";
  static String teacherManageLessonScreen = "/teacherManageLesson";
  static String teacherManageTopicScreen = "/teacherManageTopic";

  // Question Bank routes
  static String questionBankScreen = "/questionBank";
  static String questionSubjectScreen = "/questionSubject";
  static String addQuestionScreen = "/addQuestion";
  static String editQuestionScreen = "/editQuestion";
  static String bankQuestionScreen = "/bankQuestion";
  static const String addQuestionBank = '/addQuestionBank';
  static const String previewQuestionBank = '/preview-question-bank';

  static String teacherManageAssignmentScreen = "/teacherManageAssignment";
  static String teacherManageAssignmentSubmissionScreen =
      "/teacherManageAssignmentSubmissionScreen";
  static String teacherManageAnnouncementScreen = "/teacherManageAnnouncement";

  static String teacherExamResultScreen = "/teacherExamResult";
  static String teacherAddEditLessonScreen = "/teacherAddEditLessonScreen";
  static String teacherAddEditTopicScreen = "/teacherAddEditTopicScreen";
  static String teacherAddEditAnnouncementScreen =
      teacherAddEditAnnouncementScreen = "/teacherAddEditAnnouncementScreen";
  static String teacherAddEditAssignmentScreen =
      "/teacherAddEditAssignmentScreen";
  static String teacherEditAssignmentSubmissionScreen =
      "/teacherEditAssignmentSubmissionScreen";

  static String chatScreen = "/chat";
  static String chatContacts = "/chatContacts";
  static String newChatContactsScreen = "/newChatContactsScreen";

  static String onlineExamScreen = "/onlineExam";
  static String onlineExamResultScreen = "/onlineExamResult";
  static String onlineExamResultQuestionsScreen =
      "/OnlineExamResultQuestionsScreen/:id/:nama";
  static String onlineExamResultAnswerScreen =
      "/OnlineExamResultAnswerScreen/:examId/:questionId/:examName/:questionType";
  static String createOnlineExam = "/create-exam";

  // Tambahkan route baru
  static const String questionOnlineExam = '/exam-questions/:id';
  static const String editOnlineExam = '/edit-exam';
  static const String archiveOnlineExam = '/archive-online-exam';
  static const String bankSoalSelection = '/bank-soal-selection';
  static const String questionOnlineExamScreen = '/question-online-exam';
  static const String examStatusScreen = "/examStatus";

  // Contact routes
  static const String contactListScreen = "/contact-list";
  static const String contactDetailScreen = "/contact-detail";
  static const String submitContactScreen = "/submit-contact";

  // Nama page
  static final List<GetPage> getPages = [
    GetPage(name: splashScreen, page: () => SplashScreen.getRouteInstance()),
    GetPage(name: loginScreen, page: () => LoginScreen.getRouteInstance()),
    GetPage(name: homeScreen, page: () => HomeScreen.getRouteInstance()),
    GetPage(
        name: teachersScreen, page: () => TeachersScreen.getRouteInstance()),
    GetPage(
        name: teacherProfileScreen,
        page: () => TeacherProfileScreen.getRouteInstance()),
    GetPage(name: staffsScreen, page: () => StaffsScreen.getRouteInstance()),
    GetPage(
        name: staffDetailsScreen,
        page: () => StaffDetailsScreen.getRouteInstance()),
    GetPage(
        name: studentsScreen, page: () => StudentsScreen.getRouteInstance()),
    GetPage(
        name: studentProfileScreen,
        page: () => StudentProfileScreen.getRouteInstance()),
    GetPage(
        name: leaveRequestScreen,
        page: () => LeaveRequestsScreen.getRouteInstance()),
    GetPage(
        name: teacherTimeTableDetailsScreen,
        page: () => TeacherTimeTableDetailsScreen.getRouteInstance()),
    GetPage(
        name: generalLeavesScreen,
        page: () => GeneralLeavesScreen.getRouteInstance()),
    GetPage(
        name: generalPermissionScreen,
        page: () => GeneralPermissionScreen.getRouteInstance()),
    GetPage(
        name: holidaysScreen, page: () => HolidaysScreen.getRouteInstance()),
    GetPage(
        name: applyLeaveScreen,
        page: () => ApplyLeaveScreen.getRouteInstance()),
    GetPage(name: leavesScreen, page: () => LeavesScreen.getRouteInstance()),
    GetPage(
        name: studentsAttendanceScreen,
        page: () => StudentsAttendanceScreen.getRouteInstance()),
    GetPage(
        name: offlineResultScreen,
        page: () => OfflineResultScreen.getRouteInstance()),
    GetPage(
        name: manageNotificationScreen,
        page: () => ManageNotificationScreen.getRouteInstance()),
    GetPage(
        name: addNotificationScreen,
        page: () => AddNotificationScreen.getRouteInstance()),
    GetPage(
        name: manageAnnouncementScreen,
        page: () => ManageAnnouncementScreen.getRouteInstance()),
    GetPage(
        name: addAnnouncementScreen,
        page: () => AddAnnouncementScreen.getRouteInstance()),
    GetPage(
        name: editAnnouncementScreen,
        page: () => EditAnnouncementScreen.getRouteInstance()),
    GetPage(
        name: paidFeesScreen, page: () => PaidFeesScreen.getRouteInstance()),
    GetPage(
        name: managePayrollScreen,
        page: () => ManagePayrollsScreen.getRouteInstance()),
    GetPage(
        name: myPayrollScreen, page: () => MyPayrollScreen.getRouteInstance()),
    GetPage(
        name: editProfileScreen,
        page: () => EditProfileScreen.getRouteInstance()),
    GetPage(
        name: changePasswordScreen,
        page: () => ChangePasswordScreen.getRouteInstance()),
    GetPage(
      name: questionSubjectScreen,
      page: () {
        // Safe check for arguments
        final args = Get.arguments;
        final bool isStaffView = (args != null && args is Map && args['isStaffView'] == true);
        
        return BlocProvider(
          create: (context) => QuestionBankCubit(
            repository: QuestionBankRepository(),
          )..fetchTeacherSubjects(isStaffView: isStaffView),
          child: QuestionSubjectScreen(isStaffView: isStaffView),
        );
      },
    ),
    GetPage(name: aboutUsScreen, page: () => AboutUsScreen.getRouteInstance()),
    GetPage(
        name: contactUsScreen, page: () => ContactUsScreen.getRouteInstance()),
    GetPage(
        name: privacyPolicyScreen,
        page: () => PrivacyPolicyScreen.getRouteInstance()),
    GetPage(
        name: termsAndConditionScreen,
        page: () => TermsAndConditionScreen.getRouteInstance()),
    GetPage(
        name: searchTeachersScreen,
        page: () => SearchTeachersScreen.getRouteInstance()),
    GetPage(
        name: notificationsScreen,
        page: () => NotificationsScreen.getRouteInstance()),
    GetPage(
      name: classesScreen,
      page: () => ClassesScreen.getRouteInstance(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: const Duration(milliseconds: 380),
    ),
    GetPage(
      name: teacherMyTimetableScreen,
      page: () => TeacherMyTimetableScreen.getRouteInstance(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: const Duration(milliseconds: 380),
    ),
    GetPage(
      name: classTimetableScreen,
      page: () => ClassTimeTableScreen.getRouteInstance(),
      transition: Transition.rightToLeftWithFade,
      transitionDuration: const Duration(milliseconds: 380),
    ),
    GetPage(
      name: sessionYearsScreen,
      page: () => SessionYearsScreen.getRouteInstance(),
    ),
    GetPage(
      name: teacherClassSectionScreen,
      page: () => TeacherClassSectionScreen.getRouteInstance(),
    ),
    GetPage(
      name: teacherAddAttendanceScreen,
      page: () => TeacherAddAttendanceScreen.getRouteInstance(),
    ),
    GetPage(
      name: teacherViewAttendanceScreen,
      page: () => TeacherViewAttendanceScreen.getRouteInstance(),
    ),
    GetPage(
      name: teacherAddAttendanceSubjectScreen,
      page: () => TeacherAddAttendanceSubjectScreen.getRouteInstance(),
    ),
    GetPage(
      name: teacherViewAttendanceSubjectScreen,
      page: () => TeacherViewAttendanceSubjectScreen.getRouteInstance(),
    ),
    GetPage(
      name: recapAttendanceSubjectScreen,
      page: () => RecapAttendanceSubjectScreen.getRouteInstance(),
    ),
    GetPage(
      name: attendanceRecapScreen,
      page: () => AttendanceRecapScreen.getRouteInstance(),
    ),
    GetPage(
      name: attendanceRankingScreen,
      page: () => RankingAttendanceScreen.getRouteInstance(),
    ),
    GetPage(
      name: teacherManageLessonScreen,
      page: () => TeacherManageLessonScreen.getRouteInstance(),
    ),
    GetPage(
      name: teacherManageTopicScreen,
      page: () => TeacherManageTopicScreen.getRouteInstance(),
      popGesture: false,
    ),
    GetPage(
      name: teacherManageAssignmentScreen,
      page: () => TeacherManageAssignmentScreen.getRouteInstance(),
    ),
    GetPage(
      name: teacherManageAssignmentSubmissionScreen,
      page: () => TeacherManageAssignmentSubmissionScreen.getRouteInstance(),
    ),
    GetPage(
      name: teacherManageAnnouncementScreen,
      page: () => TeacherManageAnnouncementScreen.getRouteInstance(),
    ),
    GetPage(
      name: examsScreen,
      page: () => ExamsScreen.getRouteInstance(),
    ),
    GetPage(
      name: searchUsersScreen,
      popGesture: false,
      page: () => SearchUsersScreen.getRouteInstance(),
    ),
    GetPage(
      name: teacherExamResultScreen,
      page: () => TeacherExamResultScreen.getRouteInstance(),
    ),
    GetPage(
      name: teacherAddEditLessonScreen,
      page: () => TeacherAddEditLessonScreen.getRouteInstance(),
      popGesture: false,
    ),
    GetPage(
      name: teacherAddEditTopicScreen,
      page: () => TeacherAddEditTopicScreen.getRouteInstance(),
      popGesture: false,
    ),
    GetPage(
      name: teacherAddEditAnnouncementScreen,
      page: () => TeacherAddEditAnnouncementScreen.getRouteInstance(),
      popGesture: false,
    ),
    GetPage(
      name: teacherAddEditAssignmentScreen,
      page: () => TeacherAddEditAssignmentScreen.getRouteInstance(),
      popGesture: false,
    ),
    GetPage(
      name: teacherEditAssignmentSubmissionScreen,
      page: () => TeacherEditAssignmentSubmissionScreen.getRouteInstance(),
    ),
    GetPage(
      name: allowancesAndDeductionsScreen,
      page: () => AllowancesAndDeductionsScreen.getRouteInstance(),
    ),
    GetPage(
      name: chatContacts,
      page: () => ChatContainer.getRouteInstance(),
    ),

    GetPage(
      name: questionBankScreen,
      page: () => BlocProvider(
        create: (context) => QuestionBankCubit(
          repository: QuestionBankRepository(),
        ),
        child: QuestionBankListScreen(
          subject: Get.arguments as SubjectQuestion,
        ),
      ),
    ),
    //   GetPage(
    //     name: questionBankScreen,
    //     page: () => BlocProvider(
    //       create: (context) => QuestionBankCubit(QuestionBankRepository()),
    //       child: QuestionBankListScreen(),
    //     ),
    //   ),
    //   GetPage(name: chatScreen, page: () => ChatScreen.getRouteInstance()),
    //   GetPage(
    //       name: newChatContactsScreen,
    //       page: () => NewChatContactsScreen.getRouteInstance()),
    //   GetPage(
    //     name: addQuestionScreen,
    //     page: () => BlocProvider(
    //       create: (context) => QuestionBankCubit(QuestionBankRepository()),
    //       child: AddQuestionScreen(),
    //     ),
    //   ),
    //  GetPage(
    //   name: editQuestionScreen, // Route yang sudah didefinisikan
    //   page: () => BlocProvider(
    //     create: (context) => QuestionBankCubit(QuestionBankRepository()),
    //     child: EditQuestionScreen(
    //       question: Get.arguments as Question,
    //     ),
    //   ),
    // ),
    // GetPage(
    //   name: editQuestionScreen,
    //   page: () => BlocProvider(
    //     create: (context) => QuestionBankCubit(QuestionBankRepository()),
    //     child: EditQuestionScreen(
    //       question: Get.arguments as Question,
    //     ),
    //   ),
    // ),

    GetPage(
      name: onlineExamResultScreen,
      page: () => MultiBlocProvider(
        providers: [
          BlocProvider<OnlineExamCubit>(
            create: (context) => OnlineExamCubit(OnlineExamRepository()),
          ),
          BlocProvider<ClassSectionsAndSubjectsCubit>(
            create: (context) => ClassSectionsAndSubjectsCubit(),
          ),
        ],
        child: const OnlineExamResultScreen(),
      ),
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: onlineExamResultQuestionsScreen,
      page: () => MultiBlocProvider(
        providers: [
          BlocProvider<OnlineExamCubit>(
            create: (context) => OnlineExamCubit(OnlineExamRepository()),
          ),
          BlocProvider<ClassSectionsAndSubjectsCubit>(
            create: (context) => ClassSectionsAndSubjectsCubit(),
          ),
        ],
        child: OnlineExamResultQuestionsScreen(
            examId: int.parse(Get.parameters['id'] ?? '0'),
            examName: utf8.decode(base64.decode(Get.parameters['nama'] ?? ''))),
      ),
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: onlineExamResultAnswerScreen,
      page: () => MultiBlocProvider(
        providers: [
          BlocProvider<OnlineExamCubit>(
            create: (context) => OnlineExamCubit(OnlineExamRepository()),
          ),
          BlocProvider<ClassSectionsAndSubjectsCubit>(
            create: (context) => ClassSectionsAndSubjectsCubit(),
          ),
        ],
        child: OnlineExamResultAnswerScreen(
            examId: int.parse(Get.parameters['examId'] ?? '0'),
            questionId: int.parse(Get.parameters['questionId'] ?? '0'),
            examName:
                utf8.decode(base64.decode(Get.parameters['examName'] ?? '')),
            questionType: Get.parameters['questionType'] ?? ''),
      ),
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: bankQuestionScreen,
      page: () => BlocProvider(
        create: (context) =>
            QuestionBankCubit(repository: QuestionBankRepository()),
        child: BankQuestionScreen(
          bankSoal: Get.arguments['bankSoal'] as BankSoal,
          subjectId: Get.arguments['subjectId'] as int,
          subject: Get.arguments['subject'] as SubjectQuestion,
        ),
      ),
    ),
    // GetPage(
    //   name: addQuestionBank,
    //   page: () => BlocProvider(
    //     create: (context) => QuestionBankCubit(repository: QuestionBankRepository()),
    //     child: AddQuestionBank(subject: Get.arguments as SubjectQuestion),
    //   ),
    // ),


    GetPage(
      name: addQuestionScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return BlocProvider(
          create: (context) => QuestionBankCubit(
            repository: QuestionBankRepository(),
          ),
          child: AddQuestionScreen(
            bankSoalId: args['bankSoalId'] as int,
            subjectId: args['subjectId'] as int,
          ),
        );
      },
    ),
    GetPage(
      name: editQuestionScreen,
      page: () => BlocProvider(
        create: (context) =>
            QuestionBankCubit(repository: QuestionBankRepository()),
        child: EditQuestionScreen(
          idList: Get.arguments['idList'],
          questionData:
              Get.arguments['questionData'], // This expects 'questionData'
        ),
      ),
    ),
    GetPage(
      name: onlineExamScreen,
      page: () => OnlineExamScreen.getRouteInstance(),
    ),

    GetPage(
      name: createOnlineExam,
      page: () => MultiBlocProvider(
        providers: [
          BlocProvider<OnlineExamCubit>(
            create: (context) => OnlineExamCubit(OnlineExamRepository()),
          ),
          BlocProvider<ClassSectionsAndSubjectsCubit>(
            create: (context) => ClassSectionsAndSubjectsCubit(),
          ),
          BlocProvider<SessionYearsAndMediumsCubit>(
            create: (context) => SessionYearsAndMediumsCubit(),
          ),
        ],
        child: const CreateOnlineExam(),
      ),
    ),
    GetPage(
      name: Routes.questionOnlineExam,
      page: () => MultiBlocProvider(
        providers: [
          BlocProvider<QuestionOnlineExamCubit>(
            create: (context) =>
                QuestionOnlineExamCubit(OnlineExamRepository()),
          ),
        ],
        child: QuestionOnlineExamScreen(
          examId: int.parse(Get.parameters['id'] ?? '0'),
        ),
      ),
    ),
    GetPage(
      name: bankSoalSelection,
      page: () => BlocProvider(
        create: (context) => QuestionOnlineExamCubit(
          OnlineExamRepository(),
        ),
        child: BankSoalSelectionScreen(
          examId: int.parse(Get.parameters['examId'] ?? '0'),
        ),
      ),
    ),

    // GetPage(
    //   name: bankSoalSelection,

    GetPage(
      name: editOnlineExam,
      page: () => MultiBlocProvider(
        providers: [
          BlocProvider<OnlineExamCubit>(
            create: (context) => OnlineExamCubit(OnlineExamRepository()),
          ),
          BlocProvider<ClassSectionsAndSubjectsCubit>(
            create: (context) => ClassSectionsAndSubjectsCubit(),
          ),
          BlocProvider<SessionYearsAndMediumsCubit>(
            create: (context) => SessionYearsAndMediumsCubit(),
          ),
        ],
        child: EditOnlineExam(
          exam: Get.arguments,
        ),
      ),
    ),

    GetPage(
      name: archiveOnlineExam,
      page: () => MultiBlocProvider(
        providers: [
          BlocProvider<OnlineExamCubit>(
            create: (context) => OnlineExamCubit(OnlineExamRepository()),
          ),
          BlocProvider<ClassSectionsAndSubjectsCubit>(
            create: (context) => ClassSectionsAndSubjectsCubit(),
          ),
          BlocProvider<SessionYearsAndMediumsCubit>(
            create: (context) => SessionYearsAndMediumsCubit(),
          ),
        ],
        child:
            const ArchiveOnlineExam(), // Replace Container() with ArchiveOnlineExam()
      ),
    ),

    // Extracurricular routes
    GetPage(
      name: extracurricularScreen,
      page: () => ExtracurricularScreen.getRouteInstance(),
    ),
    GetPage(
      name: createExtracurricular,
      page: () => BlocProvider<ExtracurricularCubit>(
        create: (context) => ExtracurricularCubit(ExtracurricularRepository()),
        child: const CreateExtracurricular(),
      ),
    ),
    GetPage(
      name: editExtracurricular,
      page: () => BlocProvider<ExtracurricularCubit>(
        create: (context) => ExtracurricularCubit(ExtracurricularRepository()),
        child: EditExtracurricular(
          extracurricular: Get.arguments,
        ),
      ),
    ),
    GetPage(
      name: archiveExtracurricular,
      page: () => BlocProvider<ExtracurricularCubit>(
        create: (context) => ExtracurricularCubit(ExtracurricularRepository()),
        child: const ArchiveExtracurricular(),
      ),
    ),
    GetPage(
      name: extracurricularTimetable,
      page: () => ExtracurricularTimetableScreen.getRouteInstance(),
    ),
    GetPage(
      name: createExtracurricularTimetable,
      page: () => BlocProvider<ExtracurricularTimetableCubit>(
        create: (context) => ExtracurricularTimetableCubit(
          ExtracurricularTimetableRepository(),
        ),
        child: CreateExtracurricularTimetableScreen(
          existingEntry: Get.arguments?['existingEntry'],
          extracurriculars: Get.arguments?['extracurriculars'],
          selectedExtracurricularId:
              Get.arguments?['selectedExtracurricularId'],
        ),
      ),
    ),
    GetPage(
      name: extracurricularMember,
      page: () => BlocProvider<ExtracurricularMemberCubit>(
        create: (context) => ExtracurricularMemberCubit(
          ExtracurricularMemberRepository(),
        ),
        child: const ExtracurricularMemberScreen(),
      ),
    ),
    GetPage(
      name: extracurricularAttendance,
      page: () => ExtracurricularAttendanceScreen.getRouteInstance(),
    ),

    GetPage(
      name: Routes
          .previewQuestionBank, // Pastikan 'previewQuestionBank' didefinisikan di Routes
      page: () => MultiBlocProvider(
        providers: [
          BlocProvider<OnlineExamCubit>(
            create: (context) => OnlineExamCubit(OnlineExamRepository()),
          ),
          BlocProvider<ClassSectionsAndSubjectsCubit>(
            create: (context) => ClassSectionsAndSubjectsCubit(),
          ),
          BlocProvider<QuestionBankCubit>(
            // Tambahkan QuestionBankCubit
            create: (context) => QuestionBankCubit(
              repository: QuestionBankRepository(),
            )..fetchTeacherSubjects(
                isStaffView: true), // Set isStaffView to true for staff
            child: const QuestionSubjectScreen(isStaffView: true),
          ),
        ],
        child: Builder(
          builder: (context) {
            final args = Get.arguments as Map<String, dynamic>;
            return PreviewQuestionBankSoal(
              bank: args['bank'] as BankSoalQuestion,
              examId: args['examId'] as int,
              classSectionId: args['classSectionId'] as int,
              classSubjectId: args['classSubjectId'] as int,
            );
          },
        ),
      ),
    ),
    GetPage(
      name: questionOnlineExamScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return QuestionOnlineExamScreen(
          examId: args['examId'] as int,
        );
      },
    ),
    GetPage(
      name: examStatusScreen,
      page: () => MultiBlocProvider(
        providers: [
          BlocProvider<OnlineExamCubit>(
            create: (context) => OnlineExamCubit(OnlineExamRepository()),
          ),
          BlocProvider<ExamStatusCubit>(
            create: (context) => ExamStatusCubit(
              examStatusRepository: ExamStatusRepository(),
            ),
          ),
        ],
        child: const ExamStatusScreen(),
      ),
    ),
    // Add AssignmentMonitoringScreen route
    GetPage(
      name: assignmentMonitoringScreen,
      page: () => AssignmentMonitoringScreen.getRouteInstance(),
    ),

    // Add AssignmentDetailMonitoringScreen route
    GetPage(
      name: assignmentDetailMonitoringScreen,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return AssignmentDetailMonitoringScreen.getRouteInstance(
          teacherId: args['teacherId'] as int,
          teacherName: args['teacherName'] as String,
        );
      },
    ),

    // Contact routes
    GetPage(
      name: contactListScreen,
      page: () => MultiBlocProvider(
        providers: [
          BlocProvider<ContactListCubit>(
            create: (context) => ContactListCubit(ContactRepository()),
          ),
          BlocProvider<ContactStatsCubit>(
            create: (context) => ContactStatsCubit(ContactRepository()),
          ),
        ],
        child: const ContactListScreen(),
      ),
    ),
    GetPage(
      name: contactDetailScreen,
      page: () {
        final contactId = Get.arguments as int;
        return BlocProvider<ContactDetailCubit>(
          create: (context) => ContactDetailCubit(ContactRepository()),
          child: ContactDetailScreen(contactId: contactId),
        );
      },
    ),
    GetPage(
      name: submitContactScreen,
      page: () => BlocProvider<SubmitContactCubit>(
        create: (context) => SubmitContactCubit(ContactRepository()),
        child: const SubmitContactScreen(),
      ),
    ),
  ]; // Add semicolon here

  // /[This will check if user is login or not. If user is login then navigate to target screen]
  // /[If user is not login then it will redirect user to login screen]
  // static Widget _checkAuthenticity({required Widget to}) {
  //   if (Utils.isUserLoggedIn()) {
  //     return to;
  //   }
  //   return AuthenticationScreen.getRouteInstance(showSkipButton: false);
  // }
}
