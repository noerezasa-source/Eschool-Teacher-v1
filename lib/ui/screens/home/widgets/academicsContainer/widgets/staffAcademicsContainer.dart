import 'dart:math';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:eschool_saas_staff/cubits/userDetails/staffAllowedPermissionsAndModulesCubit.dart';
import 'package:eschool_saas_staff/ui/screens/leaves/leavesScreen.dart';
import 'package:eschool_saas_staff/ui/screens/staff/staffsScreen.dart';
import 'package:eschool_saas_staff/ui/screens/staff/teachersScreen.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/systemModulesAndPermissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class StaffAcademicsContainer extends StatefulWidget {
  const StaffAcademicsContainer({super.key});

  @override
  State<StaffAcademicsContainer> createState() =>
      _StaffAcademicsContainerState();
}

class _StaffAcademicsContainerState extends State<StaffAcademicsContainer>
    with SingleTickerProviderStateMixin {
  int _hoveredMenuIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _animation =
        Tween<double>(begin: 0, end: 2 * pi).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StaffAllowedPermissionsAndModulesCubit
        staffAllowedPermissionsAndModulesCubit =
        context.read<StaffAllowedPermissionsAndModulesCubit>();

    return Stack(
      children: [
        // Animated Background Pattern
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CustomPaint(
              size: Size(MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.height),
              painter: BackgroundPatternPainter(
                animation: _animation,
                primaryColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.03),
                accentColor: AppColorPalette.secondaryMaroon.withValues(alpha: 0.02),
              ),
            );
          },
        ),

        // Main Content
        AnimationLimiter(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: 100,
            ),
            child: Column(
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 600),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 30.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  // Added an empty SizedBox to provide additional space from the appbar
                  const SizedBox(height: 50),
                  // Classes Section
                  staffAllowedPermissionsAndModulesCubit.isPermissionGiven(
                          permission: viewClassesPermissionKey)
                      ? _buildMenuSection(
                          context: context,
                          title: "Kelas",
                          icon: Icons.class_outlined,
                          iconColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.9),
                          index: 0,
                          menus: [
                            _buildMenuItem(
                              context: context,
                              icon: Icons.view_list,
                              title: "Lihat Kelas",
                              index: 0,
                              onTap: () => Get.toNamed(Routes.classesScreen),
                            ),
                          ],
                        )
                      : const SizedBox(),

                  // Session Year Section
                  staffAllowedPermissionsAndModulesCubit.isPermissionGiven(
                          permission: viewSessionYearsPermissionKey)
                      ? _buildMenuSection(
                          context: context,
                          title: "Tahun Ajaran",
                          icon: Icons.calendar_today,
                          iconColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.9),
                          index: 1,
                          menus: [
                            _buildMenuItem(
                              context: context,
                              icon: Icons.view_list,
                              title: "Lihat Tahun Ajaran",
                              index: 1,
                              onTap: () =>
                                  Get.toNamed(Routes.sessionYearsScreen),
                            ),
                          ],
                        )
                      : const SizedBox(),

                  // Leave Section
                  _buildMenuSection(
                    context: context,
                    title: "Cuti",
                    icon: Icons.work_off,
                    iconColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.9),
                    index: 2,
                    menus: [
                      _buildMenuItem(
                        context: context,
                        icon: Icons.add_circle_outline,
                        title: "Ajukan Cuti",
                        index: 2,
                        onTap: () => Get.toNamed(Routes.applyLeaveScreen),
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.list_alt,
                        title: "Cuti Saya",
                        index: 3,
                        onTap: () => Get.toNamed(Routes.leavesScreen,
                            arguments: LeavesScreen.buildArguments(
                                showMyLeaves: true)),
                      ),
                      (staffAllowedPermissionsAndModulesCubit.isModuleEnabled(
                                  moduleId: staffLeaveManagementModuleId
                                      .toString()) &&
                              staffAllowedPermissionsAndModulesCubit
                                  .isPermissionGiven(
                                      permission: approveLeavePermissionKey))
                          ? _buildMenuItem(
                              context: context,
                              icon: Icons.people,
                              title: "Cuti Staf",
                              index: 4,
                              onTap: () => Get.toNamed(Routes.staffsScreen,
                                  arguments: StaffsScreen.buildArguments(
                                      forStaffLeave: true)),
                            )
                          : const SizedBox(),
                      (staffAllowedPermissionsAndModulesCubit.isModuleEnabled(
                                  moduleId: staffLeaveManagementModuleId
                                      .toString()) &&
                              staffAllowedPermissionsAndModulesCubit
                                  .isPermissionGiven(
                                      permission: approveLeavePermissionKey))
                          ? _buildMenuItem(
                              context: context,
                              icon: Icons.school,
                              title: "Cuti Guru",
                              index: 5,
                              onTap: () => Get.toNamed(
                                Routes.teachersScreen,
                                arguments: TeachersScreen.buildArguments(
                                    teacherNavigationType:
                                        TeacherNavigationType.leave),
                              ),
                            )
                          : const SizedBox(),
                    ],
                  ),

                  // // Attendance Section
                  // (staffAllowedPermissionsAndModulesCubit.isModuleEnabled(
                  //             moduleId:
                  //                 attendanceManagementModuleId.toString()) &&
                  //         staffAllowedPermissionsAndModulesCubit
                  //             .isPermissionGiven(
                  //                 permission:
                  //                     viewStudentAttendancePermissionKey))
                  //     ? _buildMenuSection(
                  //         context: context,
                  //         title: "Kehadiran",
                  //         icon: Icons.people,
                  //         iconColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.9),
                  //         index: 3,
                  //         menus: [
                  //           _buildMenuItem(
                  //             context: context,
                  //             icon: Icons.assignment_turned_in,
                  //             title: "Kehadiran Siswa",
                  //             index: 6,
                  //             onTap: () =>
                  //                 Get.toNamed(Routes.studentsAttendanceScreen),
                  //           ),
                  //         ],
                  //       )
                  //     : const SizedBox(),

                  // Timetable Section
                  (staffAllowedPermissionsAndModulesCubit.isModuleEnabled(
                              moduleId:
                                  timetableManagementModuleId.toString()) &&
                          staffAllowedPermissionsAndModulesCubit
                              .isPermissionGiven(
                                  permission: viewTimetablePermissionKey))
                      ? _buildMenuSection(
                          context: context,
                          title: "Jadwal",
                          icon: Icons.schedule,
                          iconColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.9),
                          index: 4,
                          menus: [
                            _buildMenuItem(
                              context: context,
                              icon: Icons.view_timeline,
                              title: "Jadwal Kelas",
                              index: 7,
                              onTap: () =>
                                  Get.toNamed(Routes.classTimetableScreen),
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.person_search,
                              title: "Jadwal Guru",
                              index: 8,
                              onTap: () => Get.toNamed(
                                Routes.teachersScreen,
                                arguments: TeachersScreen.buildArguments(
                                    teacherNavigationType:
                                        TeacherNavigationType.timetable),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox(),

                  // Question Bank Section
                  _buildMenuSection(
                    context: context,
                    title: "Bank Soal",
                    icon: Icons.quiz,
                    iconColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.9),
                    index: 6,
                    menus: [
                      _buildMenuItem(
                        context: context,
                        icon: Icons.question_answer,
                        title: "Bank Soal",
                        index: 11,
                        onTap: () {
                          Get.toNamed(Routes.questionSubjectScreen, arguments: {'isStaffView': true});
                        },
                      ),
                    ],
                  ),

                  // Assignment Monitoring Section
                  staffAllowedPermissionsAndModulesCubit.isPermissionGiven(
                          permission: "assignment-monitoring")
                      ? _buildMenuSection(
                          context: context,
                          title: "Monitoring Tugas",
                          icon: Icons.assignment_outlined,
                          iconColor: AppColorPalette.primaryMaroon,
                          index: 6,
                          menus: [
                            _buildMenuItem(
                              context: context,
                              icon: Icons.assessment_outlined,
                              title: "Monitoring Tugas Guru",
                              index: 14,
                              onTap: () {
                                Get.toNamed(Routes.assignmentMonitoringScreen);
                              },
                            ),
                          ],
                        )
                      : const SizedBox(),

                  // Offline Exam Section
                  (staffAllowedPermissionsAndModulesCubit.isModuleEnabled(
                              moduleId: examManagementModuleId.toString())) &&
                          (staffAllowedPermissionsAndModulesCubit
                                  .isPermissionGiven(
                                      permission: viewExamsPermissionKey) ||
                              staffAllowedPermissionsAndModulesCubit
                                  .isPermissionGiven(
                                      permission: viewExamResultPermissionKey))
                      ? _buildMenuSection(
                          context: context,
                          title: "Ujian Offline",
                          icon: Icons.school,
                          iconColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.9),
                          index: 5,
                          menus: [
                            staffAllowedPermissionsAndModulesCubit
                                    .isPermissionGiven(
                                        permission: viewExamsPermissionKey)
                                ? _buildMenuItem(
                                    context: context,
                                    icon: Icons.edit_document,
                                    title: "Jadwal Ujian Offline",
                                    index: 9,
                                    onTap: () =>
                                        Get.toNamed(Routes.examsScreen),
                                  )
                                : const SizedBox(),
                            staffAllowedPermissionsAndModulesCubit
                                    .isPermissionGiven(
                                        permission: viewExamResultPermissionKey)
                                ? _buildMenuItem(
                                    context: context,
                                    icon: Icons.analytics,
                                    title: "Hasil Ujian Offline",
                                    index: 10,
                                    onTap: () =>
                                        Get.toNamed(Routes.offlineResultScreen),
                                  )
                                : const SizedBox(),
                          ],
                        )
                      : const SizedBox(),

                  // Online Exam Section
                  _buildMenuSection(
                    context: context,
                    title: "Ujian Online",
                    icon: Icons.computer,
                    iconColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.9),
                    index: 7,
                    menus: [
                      _buildMenuItem(
                        context: context,
                        icon: Icons.quiz,
                        title: "Ujian Online",
                        index: 12,
                        onTap: () => Get.toNamed(Routes.onlineExamScreen),
                      ),
                      if (staffAllowedPermissionsAndModulesCubit
                          .isModuleEnabled(
                              moduleId:
                                  assignmentManagementModuleId.toString()))
                        _buildMenuItem(
                          context: context,
                          icon: Icons.assessment,
                          title: "Hasil Ujian Online",
                          index: 13,
                          onTap: () =>
                              Get.toNamed(Routes.onlineExamResultScreen),
                        ),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.visibility,
                        title: "Status Siswa Ujian",
                        index: 16,
                        onTap: () => Get.toNamed(Routes.examStatusScreen),
                      ),
                    ],
                  ),

                  // Extracurricular Section
                  _buildMenuSection(
                    context: context,
                    title: "Ekstrakurikuler",
                    icon: Icons.sports_soccer,
                    iconColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.9),
                    index: 8,
                    menus: [
                      _buildMenuItem(
                        context: context,
                        icon: Icons.list,
                        title: "Kelola Ekstrakurikuler",
                        index: 17,
                        onTap: () => Get.toNamed(Routes.extracurricularScreen),
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.calendar_today,
                        title: "Jadwal Ekstrakurikuler",
                        index: 18,
                        onTap: () =>
                            Get.toNamed(Routes.extracurricularTimetable),
                      ),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.people,
                        title: "Daftar Anggota",
                        index: 19,
                        onTap: () => Get.toNamed(Routes.extracurricularMember),
                      ),
                      _buildMenuItem(
                        context: context,
                        title: 'Absensi Ekstrakurikuler',
                        icon: Icons.edit_calendar_rounded,
                        index: 20,
                        onTap: () =>
                            Get.toNamed(Routes.extracurricularAttendance),
                      ),
                    ],
                  ),

                  // Message Section
                  (staffAllowedPermissionsAndModulesCubit.isModuleEnabled(
                                  moduleId: announcementManagementModuleId
                                      .toString()) &&
                              staffAllowedPermissionsAndModulesCubit
                                  .isPermissionGiven(
                                      permission:
                                          viewNotificationPermissionKey)) ||
                          (staffAllowedPermissionsAndModulesCubit
                                  .isModuleEnabled(
                                      moduleId: announcementManagementModuleId
                                          .toString()) &&
                              staffAllowedPermissionsAndModulesCubit
                                  .isPermissionGiven(
                                      permission:
                                          viewAnnouncementPermissionKey))
                      ? _buildMenuSection(
                          context: context,
                          title: "Pengumuman",
                          icon: Icons.announcement,
                          iconColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.9),
                          index: 8,
                          menus: [
                            (staffAllowedPermissionsAndModulesCubit
                                        .isModuleEnabled(
                                            moduleId:
                                                announcementManagementModuleId
                                                    .toString()) &&
                                    staffAllowedPermissionsAndModulesCubit
                                        .isPermissionGiven(
                                            permission:
                                                viewNotificationPermissionKey))
                                ? _buildMenuItem(
                                    context: context,
                                    icon: Icons.notifications,
                                    title: "Kelola Notifikasi",
                                    index: 14,
                                    onTap: () => Get.toNamed(
                                        Routes.manageNotificationScreen),
                                  )
                                : const SizedBox(),
                            (staffAllowedPermissionsAndModulesCubit
                                        .isModuleEnabled(
                                            moduleId:
                                                announcementManagementModuleId
                                                    .toString()) &&
                                    staffAllowedPermissionsAndModulesCubit
                                        .isPermissionGiven(
                                            permission:
                                                viewAnnouncementPermissionKey))
                                ? _buildMenuItem(
                                    context: context,
                                    icon: Icons.campaign,
                                    title: "Kelola Pengumuman",
                                    index: 15,
                                    onTap: () => Get.toNamed(
                                        Routes.manageAnnouncementScreen),
                                  )
                                : const SizedBox(),
                          ],
                        )
                      : const SizedBox(),

                  // Payment Section
                  (staffAllowedPermissionsAndModulesCubit.isModuleEnabled(
                              moduleId: feesManagementModuleId.toString())) ||
                          (staffAllowedPermissionsAndModulesCubit
                              .isModuleEnabled(
                                  moduleId:
                                      expenseManagementModuleId.toString()))
                      ? _buildMenuSection(
                          context: context,
                          title: "Pembayaran",
                          icon: Icons.payments,
                          iconColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.9),
                          index: 9,
                          menus: [
                            (staffAllowedPermissionsAndModulesCubit
                                        .isModuleEnabled(
                                            moduleId: feesManagementModuleId
                                                .toString()) &&
                                    staffAllowedPermissionsAndModulesCubit
                                        .isPermissionGiven(
                                            permission:
                                                viewFeesPaidPermissionKey))
                                ? _buildMenuItem(
                                    context: context,
                                    icon: Icons.paid,
                                    title: "Biaya yang Dibayar",
                                    index: 16,
                                    onTap: () =>
                                        Get.toNamed(Routes.paidFeesScreen),
                                  )
                                : const SizedBox(),
                            (staffAllowedPermissionsAndModulesCubit
                                        .isModuleEnabled(
                                            moduleId: expenseManagementModuleId
                                                .toString()) &&
                                    staffAllowedPermissionsAndModulesCubit
                                        .isPermissionGiven(
                                            permission:
                                                viewPayrollListPermissionKey))
                                ? _buildMenuItem(
                                    context: context,
                                    icon: Icons.account_balance_wallet,
                                    title: "Kelola Gaji",
                                    index: 17,
                                    onTap: () =>
                                        Get.toNamed(Routes.managePayrollScreen),
                                  )
                                : const SizedBox(),
                            staffAllowedPermissionsAndModulesCubit
                                    .isModuleEnabled(
                                        moduleId: expenseManagementModuleId
                                            .toString())
                                ? context
                                        .read<AuthCubit>()
                                        .getUserDetails()
                                        .isSchoolAdmin()
                                    ? const SizedBox()
                                    : _buildMenuItem(
                                        context: context,
                                        icon: Icons.account_balance,
                                        title: myPayRollKey,
                                        index: 18,
                                        onTap: () =>
                                            Get.toNamed(Routes.myPayrollScreen),
                                      )
                                : const SizedBox(),
                            staffAllowedPermissionsAndModulesCubit
                                    .isModuleEnabled(
                                        moduleId: expenseManagementModuleId
                                            .toString())
                                ? _buildMenuItem(
                                    context: context,
                                    icon: Icons.money,
                                    title: "Tunjangan & Potongan",
                                    index: 19,
                                    onTap: () => Get.toNamed(
                                        Routes.allowancesAndDeductionsScreen),
                                  )
                                : const SizedBox(),
                          ],
                        )
                      : const SizedBox(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required int index,
    required List<Widget> menus,
  }) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 400),
      child: SlideAnimation(
        verticalOffset: 40,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.white.withValues(alpha: 0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: iconColor.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              iconColor.withValues(alpha: 0.2),
                              iconColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        iconColor.withValues(alpha: 0.05),
                        iconColor.withValues(alpha: 0.2),
                        iconColor.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
                ...menus,
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int index,
    required VoidCallback onTap,
  }) {
    final isHovered = _hoveredMenuIndex == index;

    return StatefulBuilder(builder: (context, setState) {
      return MouseRegion(
        onEnter: (_) => this.setState(() => _hoveredMenuIndex = index),
        onExit: (_) => this.setState(() => _hoveredMenuIndex = -1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: isHovered
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColorPalette.primaryMaroon.withValues(alpha: 0.05),
                      AppColorPalette.secondaryMaroon.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            border: isHovered
                ? Border.all(
                    color: AppColorPalette.primaryMaroon.withValues(alpha: 0.1),
                    width: 1,
                  )
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              splashColor: AppColorPalette.primaryMaroon.withValues(alpha: 0.1),
              highlightColor: Colors.transparent,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isHovered
                            ? AppColorPalette.primaryMaroon.withValues(alpha: 0.1)
                            : AppColorPalette.warmBeige.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        boxShadow: isHovered
                            ? [
                                BoxShadow(
                                  color: AppColorPalette.primaryMaroon
                                      .withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        icon,
                        color: isHovered
                            ? AppColorPalette.primaryMaroon
                            : AppColorPalette.secondaryMaroon,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight:
                              isHovered ? FontWeight.w600 : FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform: Matrix4.translationValues(
                          isHovered ? 8.0 : 0.0, 0.0, 0.0),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.black.withValues(alpha: 0.5),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class BackgroundPatternPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primaryColor;
  final Color accentColor;

  BackgroundPatternPainter({
    required this.animation,
    required this.primaryColor,
    required this.accentColor,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Optimized dots pattern
    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    for (var x = 0.0; x < width; x += 60.0) {
      for (var y = 0.0; y < height; y += 60.0) {
        final offset = sin(x * 0.02 + y * 0.02 + animation.value) * 2;
        canvas.drawCircle(
          Offset(x + offset, y + offset),
          1.2,
          dotPaint,
        );
      }
    }

    // Simplified wave
    final wavePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var startY = 100.0; startY < height; startY += 250) {
      final path = Path();
      path.moveTo(0, startY);

      for (var x = 0.0; x < width; x += 20.0) {
        final y = startY + sin(x * 0.01 + animation.value) * 15;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(BackgroundPatternPainter oldDelegate) => true;
}
