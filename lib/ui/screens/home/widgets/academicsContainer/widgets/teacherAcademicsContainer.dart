

import 'dart:math';
import 'package:eschool_saas_staff/cubits/settings/appThemeCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class TeacherAcademicsContainer extends StatefulWidget {
  const TeacherAcademicsContainer({super.key});

  @override
  State<TeacherAcademicsContainer> createState() =>
      _TeacherAcademicsContainerState();
}

class _TeacherAcademicsContainerState extends State<TeacherAcademicsContainer>
    with TickerProviderStateMixin {
  int _hoveredMenuIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    context.read<ClassesCubit>().getClasses();
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
            BlocBuilder<ClassesCubit, ClassesState>(
              builder: (context, classState) {
                final isWalas = classState is ClassesFetchSuccess &&
                    classState.primaryClasses.isNotEmpty;

                return AnimationLimiter(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top:
                          120, // Increased to create more space from the appbar
                      left: 16,
                      right: 16,
                      bottom: 0,
                    ),
                    child: Column(
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 600),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 30.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          const SizedBox(height: 30),

                          _buildMenuSection(
                            context: context,
                            title: "Jadwal",
                            icon: Icons.schedule,
                            iconColor: maroonPrimary.withValues(alpha: 0.9),
                            index: 0,
                            maroonPrimary: maroonPrimary,
                            maroonLight: maroonLight,
                            menus: [
                              _buildMenuItem(
                                context: context,
                                icon: Icons.calendar_today,
                                title: "Jadwal Saya",
                                index: 0,
                                onTap: () => Get.toNamed(
                                    Routes.teacherMyTimetableScreen),
                                maroonPrimary: maroonPrimary,
                                maroonLight: maroonLight,
                              ),
                              if (isWalas)
                                _buildMenuItem(
                                  context: context,
                                  icon: Icons.class_,
                                  title: "Kelas",
                                  index: 1,
                                  onTap: () => Get.toNamed(
                                      Routes.teacherClassSectionScreen),
                                  maroonPrimary: maroonPrimary,
                                  maroonLight: maroonLight,
                                ),
                            ],
                          ),

                          // Attendance Section
                          if (isWalas) ...[
                            _buildMenuSection(
                              context: context,
                              title: "Kehadiran",
                              icon: Icons.people,
                              iconColor: maroonPrimary.withValues(alpha: 0.9),
                              index: 1,
                              maroonPrimary: maroonPrimary,
                              maroonLight: maroonLight,
                              menus: [
                                _buildMenuItem(
                                  context: context,
                                  icon: Icons.add_circle_outline,
                                  title: "Kehadiran Kegiatan Khusus",
                                  index: 2,
                                  onTap: () => Get.toNamed(
                                      Routes.teacherAddAttendanceScreen),
                                  maroonPrimary: maroonPrimary,
                                  maroonLight: maroonLight,
                                ),
                                _buildMenuItem(
                                  context: context,
                                  icon: Icons.visibility,
                                  title: "Laporan Kehadiran Kegiatan Khusus",
                                  index: 3,
                                  onTap: () => Get.toNamed(
                                      Routes.teacherViewAttendanceScreen),
                                  maroonPrimary: maroonPrimary,
                                  maroonLight: maroonLight,
                                ),
                                _buildMenuItem(
                                  context: context,
                                  icon: Icons.subject,
                                  title: "Laporan Kehadiran per Mata Pelajaran",
                                  index: 4,
                                  onTap: () => Get.toNamed(Routes
                                      .teacherViewAttendanceSubjectScreen),
                                  maroonPrimary: maroonPrimary,
                                  maroonLight: maroonLight,
                                ),
                                _buildMenuItem(
                                  context: context,
                                  icon: Icons.summarize,
                                  title: "Rekap Kehadiran",
                                  index: 5,
                                  onTap: () => Get.toNamed(
                                      Routes.recapAttendanceSubjectScreen),
                                  maroonPrimary: maroonPrimary,
                                  maroonLight: maroonLight,
                                ),
                                _buildMenuItem(
                                  context: context,
                                  icon: Icons.leaderboard,
                                  title: "Point Alpha Siswa Tertinggi",
                                  index: 6,
                                  onTap: () => Get.toNamed(
                                      Routes.attendanceRankingScreen),
                                  maroonPrimary: maroonPrimary,
                                  maroonLight: maroonLight,
                                ),
                              ],
                            ),
                          ],

                          // Lesson Section
                          _buildMenuSection(
                            context: context,
                            title: "Mata Pelajaran",
                            icon: Icons.book,
                            iconColor: maroonPrimary.withValues(alpha: 0.9),
                            index: 2,
                            maroonPrimary: maroonPrimary,
                            maroonLight: maroonLight,
                            menus: [
                              _buildMenuItem(
                                context: context,
                                icon: Icons.edit,
                                title: "Kelola Pelajaran (Bab)",
                                index: 7,
                                onTap: () => Get.toNamed(
                                    Routes.teacherManageLessonScreen),
                                maroonPrimary: maroonPrimary,
                                maroonLight: maroonLight,
                              ),
                              _buildMenuItem(
                                context: context,
                                icon: Icons.topic,
                                title: "Kelola Topik (Sub Bab)",
                                index: 8,
                                onTap: () => Get.toNamed(
                                    Routes.teacherManageTopicScreen),
                                maroonPrimary: maroonPrimary,
                                maroonLight: maroonLight,
                              ),
                            ],
                          ),

                          // Question Bank Section
                          _buildMenuSection(
                            context: context,
                            title: "Bank Soal",
                            icon: Icons.library_books,
                            iconColor: maroonPrimary.withValues(alpha: 0.9),
                            index: 3,
                            maroonPrimary: maroonPrimary,
                            maroonLight: maroonLight,
                            menus: [
                              _buildMenuItem(
                                context: context,
                                icon: Icons.question_answer,
                                title: "Bank Soal",
                                index: 9,
                                onTap: () => Get.toNamed(
                                    Routes.questionSubjectScreen,
                                    arguments: {'isStaffView': false}),
                                maroonPrimary: maroonPrimary,
                                maroonLight: maroonLight,
                              ),
                            ],
                          ),

                          // Assignment Section
                          _buildMenuSection(
                            context: context,
                            title: "Tugas Siswa",
                            icon: Icons.assignment,
                            iconColor: maroonPrimary.withValues(alpha: 0.9),
                            index: 4,
                            maroonPrimary: maroonPrimary,
                            maroonLight: maroonLight,
                            menus: [
                              _buildMenuItem(
                                context: context,
                                icon: Icons.edit_note,
                                title: "Kelola Tugas",
                                index: 10,
                                onTap: () => Get.toNamed(
                                    Routes.teacherManageAssignmentScreen),
                                maroonPrimary: maroonPrimary,
                                maroonLight: maroonLight,
                              ),
                            ],
                          ),

                          // Announcement Section
                          _buildMenuSection(
                            context: context,
                            title: "Pengumuman",
                            icon: Icons.announcement,
                            iconColor: maroonPrimary.withValues(alpha: 0.9),
                            index: 5,
                            maroonPrimary: maroonPrimary,
                            maroonLight: maroonLight,
                            menus: [
                              _buildMenuItem(
                                context: context,
                                icon: Icons.campaign,
                                title: "Kelola Pengumuman",
                                index: 11,
                                onTap: () => Get.toNamed(
                                    Routes.teacherManageAnnouncementScreen),
                                maroonPrimary: maroonPrimary,
                                maroonLight: maroonLight,
                              ),
                            ],
                          ),

                          // Offline Exam Section
                          _buildMenuSection(
                            context: context,
                            title: "Ujian Offline",
                            icon: Icons.school,
                            iconColor: maroonPrimary.withValues(alpha: 0.9),
                            index: 6,
                            maroonPrimary: maroonPrimary,
                            maroonLight: maroonLight,
                            menus: [
                              _buildMenuItem(
                                context: context,
                                icon: Icons.edit_document,
                                title: "Jadwal Ujian Offline",
                                index: 12,
                                onTap: () => Get.toNamed(Routes.examsScreen),
                                maroonPrimary: maroonPrimary,
                                maroonLight: maroonLight,
                              ),
                              _buildMenuItem(
                                context: context,
                                icon: Icons.analytics,
                                title: "Hasil Ujian Offline",
                                index: 13,
                                onTap: () => Get.toNamed(
                                    Routes.teacherExamResultScreen),
                                maroonPrimary: maroonPrimary,
                                maroonLight: maroonLight,
                              ),
                            ],
                          ),

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
                                icon: Icons.laptop_chromebook,
                                title: "Ujian Online",
                                index: 14,
                                onTap: () =>
                                    Get.toNamed(Routes.onlineExamScreen),
                                maroonPrimary: maroonPrimary,
                                maroonLight: maroonLight,
                              ),
                              _buildMenuItem(
                                context: context,
                                icon: Icons.assessment,
                                title: "Hasil Ujian Online",
                                index: 15,
                                onTap: () => Get.toNamed(
                                    Routes.onlineExamResultScreen),
                                maroonPrimary: maroonPrimary,
                                maroonLight: maroonLight,
                              ),
                              _buildMenuItem(
                                context: context,
                                icon: Icons.visibility,
                                title: "Status Siswa Ujian",
                                index: 16,
                                onTap: () =>
                                    Get.toNamed(Routes.examStatusScreen),
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
                                onTap: () => Get.toNamed(
                                    Routes.extracurricularTimetable),
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
                                onTap: () => Get.toNamed(
                                    Routes.extracurricularAttendance),
                                maroonPrimary: maroonPrimary,
                                maroonLight: maroonLight,
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

    // Optimized dots pattern - increased spacing
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

    // Draw animated wave simplified
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
