import 'dart:math';
import 'package:eschool_saas_staff/cubits/settings/appThemeCubit.dart';
import 'package:eschool_saas_staff/ui/widgets/system/osStyleMenuWidgets.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class TeacherAcademicsContainer extends StatefulWidget {
  const TeacherAcademicsContainer({super.key});

  @override
  State<TeacherAcademicsContainer> createState() =>
      _TeacherAcademicsContainerState();
}

class _TeacherAcademicsContainerState extends State<TeacherAcademicsContainer>
    with TickerProviderStateMixin {
  late AnimationController _bgAnimController;
  late Animation<double> _bgAnimation;
  Offset? _tapPos;

  @override
  void initState() {
    super.initState();
    context.read<ClassesCubit>().getClasses();
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

        // Helper: generate icon color that harmonizes with current theme
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

            // Main content — listens to class state for walas check
            BlocBuilder<ClassesCubit, ClassesState>(
              builder: (context, classState) {
                final isWalas = classState is ClassesFetchSuccess &&
                    classState.primaryClasses.isNotEmpty;

                return AnimationLimiter(
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

                          // ─── JADWAL ─────────────────────────────────
                          OsStyleMenuSection(
                            title: "Jadwal",
                            primaryColor: primary,
                            menus: [
                              OsStyleMenuItem(
                                icon: Icons.calendar_today_outlined,
                                title: "Jadwal Saya",
                                iconBgColor:
                                    ic(OsMenuIconColors.hueSchedule),
                                primaryColor: primary,
                                isLast: !isWalas,
                                onTap: () => Get.toNamed(
                                    Routes.teacherMyTimetableScreen),
                              ),
                              if (isWalas)
                                OsStyleMenuItem(
                                  icon: Icons.class_outlined,
                                  title: "Kelas",
                                  iconBgColor:
                                      ic(OsMenuIconColors.hueClass),
                                  primaryColor: primary,
                                  isLast: true,
                                  onTap: () => Get.toNamed(
                                      Routes.teacherClassSectionScreen),
                                ),
                            ],
                          ),

                          // ─── KEHADIRAN (walas only) ──────────────────
                          if (isWalas)
                            OsStyleMenuSection(
                              title: "Kehadiran",
                              primaryColor: primary,
                              menus: [
                                OsStyleMenuItem(
                                  icon: Icons.add_circle_outline,
                                  title: "Kehadiran Kegiatan Khusus",
                                  iconBgColor:
                                      ic(OsMenuIconColors.hueAttendance),
                                  primaryColor: primary,
                                  onTap: () => Get.toNamed(
                                      Routes.teacherAddAttendanceScreen),
                                ),
                                OsStyleMenuItem(
                                  icon: Icons.visibility_outlined,
                                  title: "Laporan Kehadiran Kegiatan Khusus",
                                  iconBgColor:
                                      ic(OsMenuIconColors.hueAttendance + 15),
                                  primaryColor: primary,
                                  onTap: () => Get.toNamed(
                                      Routes.teacherViewAttendanceScreen),
                                ),
                                OsStyleMenuItem(
                                  icon: Icons.subject_outlined,
                                  title: "Laporan Kehadiran per Mata Pelajaran",
                                  iconBgColor:
                                      ic(OsMenuIconColors.hueAttendance + 30),
                                  primaryColor: primary,
                                  onTap: () => Get.toNamed(Routes
                                      .teacherViewAttendanceSubjectScreen),
                                ),
                                OsStyleMenuItem(
                                  icon: Icons.summarize_outlined,
                                  title: "Rekap Kehadiran",
                                  iconBgColor:
                                      ic(OsMenuIconColors.hueAttendance + 45),
                                  primaryColor: primary,
                                  onTap: () => Get.toNamed(
                                      Routes.recapAttendanceSubjectScreen),
                                ),
                                OsStyleMenuItem(
                                  icon: Icons.leaderboard_outlined,
                                  title: "Point Alpha Siswa Tertinggi",
                                  iconBgColor:
                                      ic(OsMenuIconColors.hueAttendance + 60),
                                  primaryColor: primary,
                                  isLast: true,
                                  onTap: () => Get.toNamed(
                                      Routes.attendanceRankingScreen),
                                ),
                              ],
                            ),

                          // ─── MATA PELAJARAN ──────────────────────────
                          OsStyleMenuSection(
                            title: "Mata Pelajaran",
                            primaryColor: primary,
                            menus: [
                              OsStyleMenuItem(
                                icon: Icons.edit_outlined,
                                title: "Kelola Pelajaran (Bab)",
                                iconBgColor:
                                    ic(OsMenuIconColors.hueSubject),
                                primaryColor: primary,
                                onTap: () => Get.toNamed(
                                    Routes.teacherManageLessonScreen),
                              ),
                              OsStyleMenuItem(
                                icon: Icons.topic_outlined,
                                title: "Kelola Topik (Sub Bab)",
                                iconBgColor:
                                    ic(OsMenuIconColors.hueSubject + 15),
                                primaryColor: primary,
                                isLast: true,
                                onTap: () => Get.toNamed(
                                    Routes.teacherManageTopicScreen),
                              ),
                            ],
                          ),

                          // ─── BANK SOAL ───────────────────────────────
                          OsStyleMenuSection(
                            title: "Bank Soal",
                            primaryColor: primary,
                            menus: [
                              OsStyleMenuItem(
                                icon: Icons.quiz_outlined,
                                title: "Bank Soal",
                                iconBgColor:
                                    ic(OsMenuIconColors.hueQuestion),
                                primaryColor: primary,
                                isLast: true,
                                onTap: () => Get.toNamed(
                                  Routes.questionSubjectScreen,
                                  arguments: {'isStaffView': false},
                                ),
                              ),
                            ],
                          ),

                          // ─── TUGAS SISWA ─────────────────────────────
                          OsStyleMenuSection(
                            title: "Tugas Siswa",
                            primaryColor: primary,
                            menus: [
                              OsStyleMenuItem(
                                icon: Icons.edit_note_outlined,
                                title: "Kelola Tugas",
                                iconBgColor:
                                    ic(OsMenuIconColors.hueAssignment),
                                primaryColor: primary,
                                isLast: true,
                                onTap: () => Get.toNamed(
                                    Routes.teacherManageAssignmentScreen),
                              ),
                            ],
                          ),

                          // ─── PENGUMUMAN ──────────────────────────────
                          OsStyleMenuSection(
                            title: "Pengumuman",
                            primaryColor: primary,
                            menus: [
                              OsStyleMenuItem(
                                icon: Icons.campaign_outlined,
                                title: "Kelola Pengumuman",
                                iconBgColor:
                                    ic(OsMenuIconColors.hueAnnouncement),
                                primaryColor: primary,
                                isLast: true,
                                onTap: () => Get.toNamed(
                                    Routes.teacherManageAnnouncementScreen),
                              ),
                            ],
                          ),

                          // ─── UJIAN OFFLINE ───────────────────────────
                          OsStyleMenuSection(
                            title: "Ujian Offline",
                            primaryColor: primary,
                            menus: [
                              OsStyleMenuItem(
                                icon: Icons.edit_document,
                                title: "Jadwal Ujian Offline",
                                iconBgColor:
                                    ic(OsMenuIconColors.hueExamOffline),
                                primaryColor: primary,
                                onTap: () =>
                                    Get.toNamed(Routes.examsScreen),
                              ),
                              OsStyleMenuItem(
                                icon: Icons.analytics_outlined,
                                title: "Hasil Ujian Offline",
                                iconBgColor:
                                    ic(OsMenuIconColors.hueExamOffline + 20),
                                primaryColor: primary,
                                isLast: true,
                                onTap: () => Get.toNamed(
                                    Routes.teacherExamResultScreen),
                              ),
                            ],
                          ),

                          // ─── UJIAN ONLINE ────────────────────────────
                          OsStyleMenuSection(
                            title: "Ujian Online",
                            primaryColor: primary,
                            menus: [
                              OsStyleMenuItem(
                                icon: Icons.laptop_chromebook_outlined,
                                title: "Ujian Online",
                                iconBgColor:
                                    ic(OsMenuIconColors.hueExamOnline),
                                primaryColor: primary,
                                onTap: () =>
                                    Get.toNamed(Routes.onlineExamScreen),
                              ),
                              OsStyleMenuItem(
                                icon: Icons.assessment_outlined,
                                title: "Hasil Ujian Online",
                                iconBgColor:
                                    ic(OsMenuIconColors.hueExamOnline + 20),
                                primaryColor: primary,
                                onTap: () => Get.toNamed(
                                    Routes.onlineExamResultScreen),
                              ),
                              OsStyleMenuItem(
                                icon: Icons.visibility_outlined,
                                title: "Status Siswa Ujian",
                                iconBgColor:
                                    ic(OsMenuIconColors.hueExamOnline - 20),
                                primaryColor: primary,
                                isLast: true,
                                onTap: () =>
                                    Get.toNamed(Routes.examStatusScreen),
                              ),
                            ],
                          ),

                          // ─── EKSTRAKURIKULER ─────────────────────────
                          OsStyleMenuSection(
                            title: "Ekstrakurikuler",
                            primaryColor: primary,
                            menus: [
                              OsStyleMenuItem(
                                icon: Icons.sports_soccer_outlined,
                                title: "Kelola Ekstrakurikuler",
                                iconBgColor: ic(OsMenuIconColors.hueExtra),
                                primaryColor: primary,
                                onTap: () => Get.toNamed(
                                    Routes.extracurricularScreen),
                              ),
                              OsStyleMenuItem(
                                icon: Icons.calendar_today_outlined,
                                title: "Jadwal Ekstrakurikuler",
                                iconBgColor:
                                    ic(OsMenuIconColors.hueExtra + 15),
                                primaryColor: primary,
                                onTap: () => Get.toNamed(
                                    Routes.extracurricularTimetable),
                              ),
                              OsStyleMenuItem(
                                icon: Icons.group_outlined,
                                title: "Daftar Anggota",
                                iconBgColor:
                                    ic(OsMenuIconColors.hueExtra + 30),
                                primaryColor: primary,
                                onTap: () => Get.toNamed(
                                    Routes.extracurricularMember),
                              ),
                              OsStyleMenuItem(
                                icon: Icons.edit_calendar_rounded,
                                title: "Absensi Ekstrakurikuler",
                                iconBgColor:
                                    ic(OsMenuIconColors.hueExtra - 20),
                                primaryColor: primary,
                                isLast: true,
                                onTap: () => Get.toNamed(
                                    Routes.extracurricularAttendance),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
}

// ── Background painter ──────────────────────────────────────────────────────
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

// Keep public alias for any external imports
typedef BackgroundPatternPainter = _BackgroundPainter;
