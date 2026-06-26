

import 'dart:math';
import 'package:eschool_saas_staff/cubits/settings/appThemeCubit.dart';
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
    with TickerProviderStateMixin {
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
    return BlocBuilder<AppThemeCubit, AppThemeState>(
      builder: (context, themeState) {
        final currentTheme = themeState.themeMode;
        final maroonPrimary = AppColorPalette.getPrimaryColor(currentTheme);
        final maroonLight = AppColorPalette.getSecondaryColor(currentTheme);

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
                    primaryColor: maroonPrimary.withValues(alpha: 0.03),
                    accentColor: maroonLight.withValues(alpha: 0.02),
                  ),
                );
              },
            ),

            // Main Content
            AnimationLimiter(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: 120, // Increased to match AppBar height
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
                      const SizedBox(height: 50),
                      // Classes Section
                      staffAllowedPermissionsAndModulesCubit.isPermissionGiven(
                              permission: viewClassesPermissionKey)
                          ? _buildMenuSection(
                              context: context,
                              title: "Kelas",
                              icon: Icons.class_outlined,
                              iconColor: maroonPrimary.withValues(alpha: 0.9),
                              index: 0,
                              maroonPrimary: maroonPrimary,
                              maroonLight: maroonLight,
                              menus: [
                                _buildMenuItem(
                                  context: context,
                                  icon: Icons.view_list,
                                  title: "Lihat Kelas",
                                  index: 0,
                                  onTap: () =>
                                      Get.toNamed(Routes.classesScreen),
                                  maroonPrimary: maroonPrimary,
                                  maroonLight: maroonLight,
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
                              iconColor: maroonPrimary.withValues(alpha: 0.9),
                              index: 1,
                              maroonPrimary: maroonPrimary,
                              maroonLight: maroonLight,
                              menus: [
                                _buildMenuItem(
                                  context: context,
                                  icon: Icons.view_list,
                                  title: "Lihat Tahun Ajaran",
                                  index: 1,
                                  onTap: () =>
                                      Get.toNamed(Routes.sessionYearsScreen),
                                  maroonPrimary: maroonPrimary,
                                  maroonLight: maroonLight,
                                ),
                              ],
                            )
                          : const SizedBox(),

                      // Leave Section
                      _buildMenuSection(
                        context: context,
                        title: "Cuti",
                        icon: Icons.work_off,
                        iconColor: maroonPrimary.withValues(alpha: 0.9),
                        index: 2,
                        maroonPrimary: maroonPrimary,
                        maroonLight: maroonLight,
                        menus: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.add_circle_outline,
                            title: "Ajukan Cuti",
                            index: 2,
                            onTap: () => Get.toNamed(Routes.applyLeaveScreen),
                            maroonPrimary: maroonPrimary,
                            maroonLight: maroonLight,
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.list_alt,
                            title: "Cuti Saya",
                            index: 3,
                            onTap: () => Get.toNamed(Routes.leavesScreen,
                                arguments: LeavesScreen.buildArguments(
                                    showMyLeaves: true)),
                            maroonPrimary: maroonPrimary,
                            maroonLight: maroonLight,
                          ),
                          (staffAllowedPermissionsAndModulesCubit
                                      .isModuleEnabled(
                                          moduleId: staffLeaveManagementModuleId
                                              .toString()) &&
                                  staffAllowedPermissionsAndModulesCubit
                                      .isPermissionGiven(
                                          permission:
                                              approveLeavePermissionKey))
                              ? _buildMenuItem(
                                  context: context,
                                  icon: Icons.people,
                                  title: "Cuti Staf",
                                  index: 4,
                                  onTap: () => Get.toNamed(Routes.staffsScreen,
                                      arguments: StaffsScreen.buildArguments(
                                          forStaffLeave: true)),
                                  maroonPrimary: maroonPrimary,
                                  maroonLight: maroonLight,
                                )
                              : const SizedBox(),
                          (staffAllowedPermissionsAndModulesCubit
                                      .isModuleEnabled(
                                          moduleId: staffLeaveManagementModuleId
                                              .toString()) &&
                                  staffAllowedPermissionsAndModulesCubit
                                      .isPermissionGiven(
                                          permission:
                                              approveLeavePermissionKey))
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
                                  maroonPrimary: maroonPrimary,
                                  maroonLight: maroonLight,
                                )
                              : const SizedBox(),
                        ],
                      ),

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
                              iconColor: maroonPrimary.withValues(alpha: 0.9),
                              index: 4,
                              maroonPrimary: maroonPrimary,
                              maroonLight: maroonLight,
                              menus: [
                                _buildMenuItem(
                                  context: context,
                                  icon: Icons.view_timeline,
                                  title: "Jadwal Kelas",
                                  index: 7,
                                  onTap: () =>
                                      Get.toNamed(Routes.classTimetableScreen),
                                  maroonPrimary: maroonPrimary,
                                  maroonLight: maroonLight,
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
                                  maroonPrimary: maroonPrimary,
                                  maroonLight: maroonLight,
                                ),
                              ],
                            )
                          : const SizedBox(),

                      // Question Bank Section
                      _buildMenuSection(
                        context: context,
                        title: "Bank Soal",
                        icon: Icons.quiz,
                        iconColor: maroonPrimary.withValues(alpha: 0.9),
                        index: 6,
                        maroonPrimary: maroonPrimary,
                        maroonLight: maroonLight,
                        menus: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.question_answer,
                            title: "Bank Soal",
                            index: 11,
                            onTap: () {
                              Get.toNamed(Routes.questionSubjectScreen,
                                  arguments: {'isStaffView': true});
                            },
                            maroonPrimary: maroonPrimary,
                            maroonLight: maroonLight,
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
                              iconColor: maroonPrimary,
                              index: 6,
                              maroonPrimary: maroonPrimary,
                              maroonLight: maroonLight,
                              menus: [
                                _buildMenuItem(
                                  context: context,
                                  icon: Icons.assessment_outlined,
                                  title: "Monitoring Tugas Guru",
                                  index: 14,
                                  onTap: () {
                                    Get.toNamed(
                                        Routes.assignmentMonitoringScreen);
                                  },
                                  maroonPrimary: maroonPrimary,
                                  maroonLight: maroonLight,
                                ),
                              ],
                            )
                          : const SizedBox(),

                      // Offline Exam Section
                      (staffAllowedPermissionsAndModulesCubit.isModuleEnabled(
                                  moduleId:
                                      examManagementModuleId.toString())) &&
                              (staffAllowedPermissionsAndModulesCubit
                                      .isPermissionGiven(
                                          permission:
                                              viewExamsPermissionKey) ||
                                  staffAllowedPermissionsAndModulesCubit
                                      .isPermissionGiven(
                                          permission:
                                              viewExamResultPermissionKey))
                          ? _buildMenuSection(
                              context: context,
                              title: "Ujian Offline",
                              icon: Icons.school,
                              iconColor: maroonPrimary.withValues(alpha: 0.9),
                              index: 5,
                              maroonPrimary: maroonPrimary,
                              maroonLight: maroonLight,
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
                                        maroonPrimary: maroonPrimary,
                                        maroonLight: maroonLight,
                                      )
                                    : const SizedBox(),
                                staffAllowedPermissionsAndModulesCubit
                                        .isPermissionGiven(
                                            permission:
                                                viewExamResultPermissionKey)
                                    ? _buildMenuItem(
                                        context: context,
                                        icon: Icons.analytics,
                                        title: "Hasil Ujian Offline",
                                        index: 10,
                                        onTap: () => Get.toNamed(
                                            Routes.offlineResultScreen),
                                        maroonPrimary: maroonPrimary,
                                        maroonLight: maroonLight,
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
                        iconColor: maroonPrimary.withValues(alpha: 0.9),
                        index: 7,
                        maroonPrimary: maroonPrimary,
                        maroonLight: maroonLight,
                        menus: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.quiz,
                            title: "Ujian Online",
                            index: 12,
                            onTap: () => Get.toNamed(Routes.onlineExamScreen),
                            maroonPrimary: maroonPrimary,
                            maroonLight: maroonLight,
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
                              maroonPrimary: maroonPrimary,
                              maroonLight: maroonLight,
                            ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.visibility,
                            title: "Status Siswa Ujian",
                            index: 16,
                            onTap: () => Get.toNamed(Routes.examStatusScreen),
                            maroonPrimary: maroonPrimary,
                            maroonLight: maroonLight,
                          ),
                        ],
                      ),

                      // Extracurricular Section
                      _buildMenuSection(
                        context: context,
                        title: "Ekstrakurikuler",
                        icon: Icons.sports_soccer,
                        iconColor: maroonPrimary.withValues(alpha: 0.9),
                        index: 8,
                        maroonPrimary: maroonPrimary,
                        maroonLight: maroonLight,
                        menus: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.list,
                            title: "Kelola Ekstrakurikuler",
                            index: 17,
                            onTap: () =>
                                Get.toNamed(Routes.extracurricularScreen),
                            maroonPrimary: maroonPrimary,
                            maroonLight: maroonLight,
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.calendar_today,
                            title: "Jadwal Ekstrakurikuler",
                            index: 18,
                            onTap: () =>
                                Get.toNamed(Routes.extracurricularTimetable),
                            maroonPrimary: maroonPrimary,
                            maroonLight: maroonLight,
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.people,
                            title: "Daftar Anggota",
                            index: 19,
                            onTap: () =>
                                Get.toNamed(Routes.extracurricularMember),
                            maroonPrimary: maroonPrimary,
                            maroonLight: maroonLight,
                          ),
                          _buildMenuItem(
                            context: context,
                            title: 'Absensi Ekstrakurikuler',
                            icon: Icons.edit_calendar_rounded,
                            index: 20,
                            onTap: () =>
                                Get.toNamed(Routes.extracurricularAttendance),
                            maroonPrimary: maroonPrimary,
                            maroonLight: maroonLight,
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
                              title: "Pengumumkan",
                              icon: Icons.announcement,
                              iconColor: maroonPrimary.withValues(alpha: 0.9),
                              index: 8,
                              maroonPrimary: maroonPrimary,
                              maroonLight: maroonLight,
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
                                        onTap: () => Get.toNamed(Routes
                                            .manageNotificationScreen),
                                        maroonPrimary: maroonPrimary,
                                        maroonLight: maroonLight,
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
                                        onTap: () => Get.toNamed(Routes
                                            .manageAnnouncementScreen),
                                        maroonPrimary: maroonPrimary,
                                        maroonLight: maroonLight,
                                      )
                                    : const SizedBox(),
                              ],
                            )
                          : const SizedBox(),

                      // Payment Section
                      (staffAllowedPermissionsAndModulesCubit.isModuleEnabled(
                                  moduleId:
                                      feesManagementModuleId.toString())) ||
                              (staffAllowedPermissionsAndModulesCubit
                                  .isModuleEnabled(
                                      moduleId:
                                          expenseManagementModuleId.toString()))
                          ? _buildMenuSection(
                              context: context,
                              title: "Pembayaran",
                              icon: Icons.payments,
                              iconColor: maroonPrimary.withValues(alpha: 0.9),
                              index: 9,
                              maroonPrimary: maroonPrimary,
                              maroonLight: maroonLight,
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
                                        maroonPrimary: maroonPrimary,
                                        maroonLight: maroonLight,
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
                                        onTap: () => Get.toNamed(
                                            Routes.managePayrollScreen),
                                        maroonPrimary: maroonPrimary,
                                        maroonLight: maroonLight,
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
                                            onTap: () => Get.toNamed(
                                                Routes.myPayrollScreen),
                                            maroonPrimary: maroonPrimary,
                                            maroonLight: maroonLight,
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
                                        onTap: () => Get.toNamed(Routes
                                            .allowancesAndDeductionsScreen),
                                        maroonPrimary: maroonPrimary,
                                        maroonLight: maroonLight,
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
      },
    );
  }

  Widget _buildMenuSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required int index,
    required List<Widget> menus,
    required Color maroonPrimary,
    required Color maroonLight,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = context.read<AppThemeCubit>().state.themeMode;
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
                colors: isDark
                    ? [
                        AppColorPalette.getLightColor(themeMode),
                        AppColorPalette.getLightColor(themeMode)
                            .withValues(alpha: 0.95),
                      ]
                    : [
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
                color: iconColor.withValues(alpha: isDark ? 0.2 : 0.05),
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
                          color: isDark ? Colors.white : Colors.black,
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
    required Color maroonPrimary,
    required Color maroonLight,
  }) {
    final isHovered = _hoveredMenuIndex == index;

    return StatefulBuilder(builder: (context, setState) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final themeMode = context.read<AppThemeCubit>().state.themeMode;
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
                      maroonPrimary.withValues(alpha: 0.05),
                      maroonLight.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            border: isHovered
                ? Border.all(
                    color: maroonPrimary.withValues(alpha: 0.1),
                    width: 1,
                  )
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              splashColor: maroonPrimary.withValues(alpha: 0.1),
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
                            ? maroonPrimary.withValues(alpha: 0.1)
                            : (isDark
                                ? AppColorPalette.getLightColor(themeMode)
                                : AppColorPalette.getWarmBeigeColor(themeMode)
                                    .withValues(alpha: 0.5)),
                        shape: BoxShape.circle,
                        boxShadow: isHovered
                            ? [
                                BoxShadow(
                                  color: maroonPrimary.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        icon,
                        color: isHovered
                            ? maroonPrimary
                            : (isDark ? Colors.white70 : maroonLight),
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
                          color: isDark
                              ? (isHovered
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.8))
                              : (isHovered
                                  ? Colors.black
                                  : Colors.black.withValues(alpha: 0.8)),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform: Matrix4.translationValues(
                          isHovered ? 8.0 : 0.0, 0.0, 0.0),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: isHovered
                            ? maroonPrimary
                            : (isDark
                                ? Colors.white30
                                : maroonLight.withValues(alpha: 0.5)),
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
