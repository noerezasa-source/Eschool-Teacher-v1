import 'dart:math';
import 'package:eschool_saas_staff/cubits/settings/appThemeCubit.dart';
import 'package:eschool_saas_staff/ui/widgets/system/osStyleMenuWidgets.dart';
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
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class StaffAcademicsContainer extends StatefulWidget {
  const StaffAcademicsContainer({super.key});

  @override
  State<StaffAcademicsContainer> createState() =>
      _StaffAcademicsContainerState();
}

class _StaffAcademicsContainerState extends State<StaffAcademicsContainer>
    with TickerProviderStateMixin {
  late AnimationController _bgAnimController;
  late Animation<double> _bgAnimation;
  Offset? _tapPos;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _bgAnimation =
        Tween<double>(begin: 0, end: 2 * pi).animate(_bgAnimController);
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppThemeCubit, AppThemeState>(
      builder: (context, themeState) {
        final currentTheme = themeState.themeMode;
        final primary = AppColorPalette.getPrimaryColor(currentTheme);
        final primaryLight = AppColorPalette.getSecondaryColor(currentTheme);

        final perms =
            context.read<StaffAllowedPermissionsAndModulesCubit>();

        // Pre-compute icon colors that adapt to the current primary theme
        Color ic(double hue) => OsMenuIconColors.fromHue(hue, primary, themeMode: currentTheme);

        return Listener(
          onPointerDown: (event) {
            setState(() {
              _tapPos = event.localPosition;
            });
          },
          onPointerMove: (event) {
            setState(() {
              _tapPos = event.localPosition;
            });
          },
          onPointerUp: (event) {
            setState(() {
              _tapPos = null;
            });
          },
          onPointerCancel: (event) {
            setState(() {
              _tapPos = null;
            });
          },
          child: Stack(
            children: [
              // Subtle animated background
              AnimatedBuilder(
                animation: _bgAnimController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(MediaQuery.of(context).size.width,
                        MediaQuery.of(context).size.height),
                    painter: _BackgroundPainter(
                      animation: _bgAnimation,
                      primaryColor: primary.withValues(alpha: 0.03),
                      accentColor: primaryLight.withValues(alpha: 0.02),
                      themeMode: currentTheme,
                      tapPosition: _tapPos,
                    ),
                  );
                },
              ),

            // Main scrollable content
            AnimationLimiter(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  top: 130,
                  left: 16,
                  right: 16,
                  bottom: 110,
                ),
                child: Column(
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 500),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 24.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      const SizedBox(height: 36),

                      // ─── KELAS ───────────────────────────────────────
                      if (perms.isPermissionGiven(
                          permission: viewClassesPermissionKey))
                        OsStyleMenuSection(
                          title: "Kelas",
                          primaryColor: primary,
                          menus: [
                            OsStyleMenuItem(
                              icon: Icons.class_outlined,
                              title: "Lihat Kelas",
                              iconBgColor: ic(OsMenuIconColors.hueClass),
                              primaryColor: primary,
                              isLast: true,
                              onTap: () => Get.toNamed(Routes.classesScreen),
                            ),
                          ],
                        ),

                      // ─── TAHUN AJARAN ─────────────────────────────────
                      if (perms.isPermissionGiven(
                          permission: viewSessionYearsPermissionKey))
                        OsStyleMenuSection(
                          title: "Tahun Ajaran",
                          primaryColor: primary,
                          menus: [
                            OsStyleMenuItem(
                              icon: Icons.calendar_month_outlined,
                              title: "Lihat Tahun Ajaran",
                              iconBgColor: ic(OsMenuIconColors.hueSchedule),
                              primaryColor: primary,
                              isLast: true,
                              onTap: () =>
                                  Get.toNamed(Routes.sessionYearsScreen),
                            ),
                          ],
                        ),

                      // ─── CUTI ─────────────────────────────────────────
                      OsStyleMenuSection(
                        title: "Cuti",
                        primaryColor: primary,
                        menus: _buildLeaveMenus(context, perms, primary, ic),
                      ),

                      // ─── JADWAL ───────────────────────────────────────
                      if (perms.isModuleEnabled(
                              moduleId: timetableManagementModuleId.toString()) &&
                          perms.isPermissionGiven(
                              permission: viewTimetablePermissionKey))
                        OsStyleMenuSection(
                          title: "Jadwal",
                          primaryColor: primary,
                          menus: [
                            OsStyleMenuItem(
                              icon: Icons.view_timeline_outlined,
                              title: "Jadwal Kelas",
                              iconBgColor: ic(OsMenuIconColors.hueSchedule),
                              primaryColor: primary,
                              onTap: () =>
                                  Get.toNamed(Routes.classTimetableScreen),
                            ),
                            OsStyleMenuItem(
                              icon: Icons.person_search_outlined,
                              title: "Jadwal Guru",
                              iconBgColor: ic(OsMenuIconColors.hueSchedule + 15),
                              primaryColor: primary,
                              isLast: true,
                              onTap: () => Get.toNamed(
                                Routes.teachersScreen,
                                arguments: TeachersScreen.buildArguments(
                                    teacherNavigationType:
                                        TeacherNavigationType.timetable),
                              ),
                            ),
                          ],
                        ),

                      // ─── BANK SOAL ────────────────────────────────────
                      OsStyleMenuSection(
                        title: "Bank Soal",
                        primaryColor: primary,
                        menus: [
                          OsStyleMenuItem(
                            icon: Icons.quiz_outlined,
                            title: "Bank Soal",
                            iconBgColor: ic(OsMenuIconColors.hueQuestion),
                            primaryColor: primary,
                            isLast: true,
                            onTap: () => Get.toNamed(
                              Routes.questionSubjectScreen,
                              arguments: {'isStaffView': true},
                            ),
                          ),
                        ],
                      ),

                      // ─── MONITORING TUGAS ─────────────────────────────
                      if (perms.isPermissionGiven(
                          permission: "assignment-monitoring"))
                        OsStyleMenuSection(
                          title: "Monitoring Tugas",
                          primaryColor: primary,
                          menus: [
                            OsStyleMenuItem(
                              icon: Icons.assessment_outlined,
                              title: "Monitoring Tugas Guru",
                              iconBgColor: ic(OsMenuIconColors.hueMonitor),
                              primaryColor: primary,
                              isLast: true,
                              onTap: () => Get.toNamed(
                                  Routes.assignmentMonitoringScreen),
                            ),
                          ],
                        ),

                      // ─── UJIAN OFFLINE ────────────────────────────────
                      if (perms.isModuleEnabled(
                              moduleId: examManagementModuleId.toString()) &&
                          (perms.isPermissionGiven(
                                  permission: viewExamsPermissionKey) ||
                              perms.isPermissionGiven(
                                  permission: viewExamResultPermissionKey)))
                        OsStyleMenuSection(
                          title: "Ujian Offline",
                          primaryColor: primary,
                          menus: _buildOfflineExamMenus(
                              context, perms, primary, ic),
                        ),

                      // ─── UJIAN ONLINE ─────────────────────────────────
                      OsStyleMenuSection(
                        title: "Ujian Online",
                        primaryColor: primary,
                        menus: _buildOnlineExamMenus(
                            context, perms, primary, ic),
                      ),

                      // ─── EKSTRAKURIKULER ──────────────────────────────
                      OsStyleMenuSection(
                        title: "Ekstrakurikuler",
                        primaryColor: primary,
                        menus: [
                          OsStyleMenuItem(
                            icon: Icons.sports_soccer_outlined,
                            title: "Kelola Ekstrakurikuler",
                            iconBgColor: ic(OsMenuIconColors.hueExtra),
                            primaryColor: primary,
                            onTap: () =>
                                Get.toNamed(Routes.extracurricularScreen),
                          ),
                          OsStyleMenuItem(
                            icon: Icons.calendar_today_outlined,
                            title: "Jadwal Ekstrakurikuler",
                            iconBgColor: ic(OsMenuIconColors.hueExtra + 15),
                            primaryColor: primary,
                            onTap: () =>
                                Get.toNamed(Routes.extracurricularTimetable),
                          ),
                          OsStyleMenuItem(
                            icon: Icons.group_outlined,
                            title: "Daftar Anggota",
                            iconBgColor: ic(OsMenuIconColors.hueExtra + 30),
                            primaryColor: primary,
                            onTap: () =>
                                Get.toNamed(Routes.extracurricularMember),
                          ),
                          OsStyleMenuItem(
                            icon: Icons.edit_calendar_rounded,
                            title: "Absensi Ekstrakurikuler",
                            iconBgColor: ic(OsMenuIconColors.hueExtra - 20),
                            primaryColor: primary,
                            isLast: true,
                            onTap: () =>
                                Get.toNamed(Routes.extracurricularAttendance),
                          ),
                        ],
                      ),

                      // ─── PENGUMUMAN ───────────────────────────────────
                      if (_showAnnouncementSection(perms))
                        OsStyleMenuSection(
                          title: "Pengumuman",
                          primaryColor: primary,
                          menus: _buildAnnouncementMenus(
                              context, perms, primary, ic),
                        ),

                      // ─── PEMBAYARAN ───────────────────────────────────
                      if (_showPaymentSection(perms))
                        OsStyleMenuSection(
                          title: "Pembayaran",
                          primaryColor: primary,
                          menus: _buildPaymentMenus(
                              context, perms, primary, ic),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  // ── Helper builders ────────────────────────────────────────────────────────

  bool _showAnnouncementSection(
      StaffAllowedPermissionsAndModulesCubit perms) {
    return (perms.isModuleEnabled(
                moduleId: announcementManagementModuleId.toString()) &&
            perms.isPermissionGiven(
                permission: viewNotificationPermissionKey)) ||
        (perms.isModuleEnabled(
                moduleId: announcementManagementModuleId.toString()) &&
            perms.isPermissionGiven(
                permission: viewAnnouncementPermissionKey));
  }

  bool _showPaymentSection(StaffAllowedPermissionsAndModulesCubit perms) {
    return perms.isModuleEnabled(
            moduleId: feesManagementModuleId.toString()) ||
        perms.isModuleEnabled(
            moduleId: expenseManagementModuleId.toString());
  }

  List<Widget> _buildLeaveMenus(
    BuildContext context,
    StaffAllowedPermissionsAndModulesCubit perms,
    Color primary,
    Color Function(double) ic,
  ) {
    final items = <OsStyleMenuItem>[];
    items.add(OsStyleMenuItem(
      icon: Icons.add_circle_outline,
      title: "Ajukan Cuti",
      iconBgColor: ic(OsMenuIconColors.hueLeave),
      primaryColor: primary,
      onTap: () => Get.toNamed(Routes.applyLeaveScreen),
    ));
    items.add(OsStyleMenuItem(
      icon: Icons.history,
      title: "Cuti Saya",
      iconBgColor: ic(OsMenuIconColors.hueLeave + 20),
      primaryColor: primary,
      onTap: () => Get.toNamed(Routes.leavesScreen,
          arguments: LeavesScreen.buildArguments(showMyLeaves: true)),
    ));
    if (perms.isModuleEnabled(
            moduleId: staffLeaveManagementModuleId.toString()) &&
        perms.isPermissionGiven(permission: approveLeavePermissionKey)) {
      items.add(OsStyleMenuItem(
        icon: Icons.people_outline,
        title: "Cuti Staf",
        iconBgColor: ic(OsMenuIconColors.hueLeave + 40),
        primaryColor: primary,
        onTap: () => Get.toNamed(Routes.staffsScreen,
            arguments: StaffsScreen.buildArguments(forStaffLeave: true)),
      ));
      items.add(OsStyleMenuItem(
        icon: Icons.school_outlined,
        title: "Cuti Guru",
        iconBgColor: ic(OsMenuIconColors.hueLeave + 60),
        primaryColor: primary,
        onTap: () => Get.toNamed(
          Routes.teachersScreen,
          arguments: TeachersScreen.buildArguments(
              teacherNavigationType: TeacherNavigationType.leave),
        ),
      ));
    }
    // mark last
    if (items.isNotEmpty) {
      final last = items.removeLast();
      items.add(OsStyleMenuItem(
        icon: last.icon,
        title: last.title,
        iconBgColor: last.iconBgColor,
        primaryColor: last.primaryColor,
        isLast: true,
        onTap: last.onTap,
      ));
    }
    return items;
  }

  List<Widget> _buildOfflineExamMenus(
    BuildContext context,
    StaffAllowedPermissionsAndModulesCubit perms,
    Color primary,
    Color Function(double) ic,
  ) {
    final items = <OsStyleMenuItem>[];
    if (perms.isPermissionGiven(permission: viewExamsPermissionKey)) {
      items.add(OsStyleMenuItem(
        icon: Icons.edit_document,
        title: "Jadwal Ujian Offline",
        iconBgColor: ic(OsMenuIconColors.hueExamOffline),
        primaryColor: primary,
        onTap: () => Get.toNamed(Routes.examsScreen),
      ));
    }
    if (perms.isPermissionGiven(permission: viewExamResultPermissionKey)) {
      items.add(OsStyleMenuItem(
        icon: Icons.analytics_outlined,
        title: "Hasil Ujian Offline",
        iconBgColor: ic(OsMenuIconColors.hueExamOffline + 20),
        primaryColor: primary,
        onTap: () => Get.toNamed(Routes.offlineResultScreen),
      ));
    }
    if (items.isNotEmpty) {
      final last = items.removeLast();
      items.add(OsStyleMenuItem(
        icon: last.icon,
        title: last.title,
        iconBgColor: last.iconBgColor,
        primaryColor: last.primaryColor,
        isLast: true,
        onTap: last.onTap,
      ));
    }
    return items;
  }

  List<Widget> _buildOnlineExamMenus(
    BuildContext context,
    StaffAllowedPermissionsAndModulesCubit perms,
    Color primary,
    Color Function(double) ic,
  ) {
    final items = <OsStyleMenuItem>[];
    items.add(OsStyleMenuItem(
      icon: Icons.laptop_chromebook_outlined,
      title: "Ujian Online",
      iconBgColor: ic(OsMenuIconColors.hueExamOnline),
      primaryColor: primary,
      onTap: () => Get.toNamed(Routes.onlineExamScreen),
    ));
    if (perms.isModuleEnabled(
        moduleId: assignmentManagementModuleId.toString())) {
      items.add(OsStyleMenuItem(
        icon: Icons.assessment_outlined,
        title: "Hasil Ujian Online",
        iconBgColor: ic(OsMenuIconColors.hueExamOnline + 20),
        primaryColor: primary,
        onTap: () => Get.toNamed(Routes.onlineExamResultScreen),
      ));
    }
    items.add(OsStyleMenuItem(
      icon: Icons.visibility_outlined,
      title: "Status Siswa Ujian",
      iconBgColor: ic(OsMenuIconColors.hueExamOnline - 20),
      primaryColor: primary,
      isLast: true,
      onTap: () => Get.toNamed(Routes.examStatusScreen),
    ));
    if (items.isNotEmpty) {
      final last = items.removeLast();
      items.add(OsStyleMenuItem(
        icon: last.icon,
        title: last.title,
        iconBgColor: last.iconBgColor,
        primaryColor: last.primaryColor,
        isLast: true,
        onTap: last.onTap,
      ));
    }
    return items;
  }

  List<Widget> _buildAnnouncementMenus(
    BuildContext context,
    StaffAllowedPermissionsAndModulesCubit perms,
    Color primary,
    Color Function(double) ic,
  ) {
    final items = <OsStyleMenuItem>[];
    if (perms.isModuleEnabled(
            moduleId: announcementManagementModuleId.toString()) &&
        perms.isPermissionGiven(permission: viewNotificationPermissionKey)) {
      items.add(OsStyleMenuItem(
        icon: Icons.notifications_outlined,
        title: "Kelola Notifikasi",
        iconBgColor: ic(OsMenuIconColors.hueAnnouncement),
        primaryColor: primary,
        onTap: () => Get.toNamed(Routes.manageNotificationScreen),
      ));
    }
    if (perms.isModuleEnabled(
            moduleId: announcementManagementModuleId.toString()) &&
        perms.isPermissionGiven(permission: viewAnnouncementPermissionKey)) {
      items.add(OsStyleMenuItem(
        icon: Icons.campaign_outlined,
        title: "Kelola Pengumuman",
        iconBgColor: ic(OsMenuIconColors.hueAnnouncement + 20),
        primaryColor: primary,
        onTap: () => Get.toNamed(Routes.manageAnnouncementScreen),
      ));
    }
    if (items.isNotEmpty) {
      final last = items.removeLast();
      items.add(OsStyleMenuItem(
        icon: last.icon,
        title: last.title,
        iconBgColor: last.iconBgColor,
        primaryColor: last.primaryColor,
        isLast: true,
        onTap: last.onTap,
      ));
    }
    return items;
  }

  List<Widget> _buildPaymentMenus(
    BuildContext context,
    StaffAllowedPermissionsAndModulesCubit perms,
    Color primary,
    Color Function(double) ic,
  ) {
    final items = <OsStyleMenuItem>[];
    if (perms.isModuleEnabled(moduleId: feesManagementModuleId.toString()) &&
        perms.isPermissionGiven(permission: viewFeesPaidPermissionKey)) {
      items.add(OsStyleMenuItem(
        icon: Icons.paid_outlined,
        title: "Biaya yang Dibayar",
        iconBgColor: ic(OsMenuIconColors.hueFinance),
        primaryColor: primary,
        onTap: () => Get.toNamed(Routes.paidFeesScreen),
      ));
    }
    if (perms.isModuleEnabled(
            moduleId: expenseManagementModuleId.toString()) &&
        perms.isPermissionGiven(permission: viewPayrollListPermissionKey)) {
      items.add(OsStyleMenuItem(
        icon: Icons.account_balance_wallet_outlined,
        title: "Kelola Gaji",
        iconBgColor: ic(OsMenuIconColors.hueFinance + 20),
        primaryColor: primary,
        onTap: () => Get.toNamed(Routes.managePayrollScreen),
      ));
    }
    if (perms.isModuleEnabled(
        moduleId: expenseManagementModuleId.toString())) {
      if (!context.read<AuthCubit>().getUserDetails().isSchoolAdmin()) {
        items.add(OsStyleMenuItem(
          icon: Icons.account_balance_outlined,
          title: myPayRollKey,
          iconBgColor: ic(OsMenuIconColors.hueFinance + 40),
          primaryColor: primary,
          onTap: () => Get.toNamed(Routes.myPayrollScreen),
        ));
      }
      items.add(OsStyleMenuItem(
        icon: Icons.money_outlined,
        title: "Tunjangan & Potongan",
        iconBgColor: ic(OsMenuIconColors.huePayroll),
        primaryColor: primary,
        onTap: () => Get.toNamed(Routes.allowancesAndDeductionsScreen),
      ));
    }
    if (items.isNotEmpty) {
      final last = items.removeLast();
      items.add(OsStyleMenuItem(
        icon: last.icon,
        title: last.title,
        iconBgColor: last.iconBgColor,
        primaryColor: last.primaryColor,
        isLast: true,
        onTap: last.onTap,
      ));
    }
    return items;
  }
}

// ── Background painter (unchanged) ─────────────────────────────────────────
class _BackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final Color primaryColor;
  final Color accentColor;
  final String themeMode;
  final Offset? tapPosition;

  _BackgroundPainter({
    required this.animation,
    required this.primaryColor,
    required this.accentColor,
    required this.themeMode,
    this.tapPosition,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    for (var x = 0.0; x < size.width; x += 60.0) {
      for (var y = 0.0; y < size.height; y += 60.0) {
        final offset = sin(x * 0.02 + y * 0.02 + animation.value) * 2;
        canvas.drawCircle(Offset(x + offset, y + offset), 1.2, dotPaint);
      }
    }
    final wavePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (var startY = 100.0; startY < size.height; startY += 250) {
      final path = Path()..moveTo(0, startY);
      for (var x = 0.0; x < size.width; x += 20.0) {
        path.lineTo(x, startY + sin(x * 0.01 + animation.value) * 15);
      }
      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => true;
}

// Keep BackgroundPatternPainter alias for any imports from other files
typedef BackgroundPatternPainter = _BackgroundPainter;
