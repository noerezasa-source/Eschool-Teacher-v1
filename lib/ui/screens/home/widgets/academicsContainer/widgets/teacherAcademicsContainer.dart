import 'dart:math';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/utils/system/in_appbanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AppColorPalette {
  static const Color primaryMaroon = Color(0xFF8B1F41);
  static const Color secondaryMaroon = Color(0xFFA84B5C);
  static const Color lightMaroon = Color(0xFFE7C8CD);
  static const Color accentPink = Color(0xFFF4D0D9);
  static const Color warmBeige = Color(0xFFF5E6E8);
}

class TeacherAcademicsContainer extends StatefulWidget {
  const TeacherAcademicsContainer({super.key});

  @override
  State<TeacherAcademicsContainer> createState() =>
      _TeacherAcademicsContainerState();
}

class _TeacherAcademicsContainerState extends State<TeacherAcademicsContainer>
    with SingleTickerProviderStateMixin {
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
                primaryColor:
                    AppColorPalette.primaryMaroon.withValues(alpha: 0.03),
                accentColor:
                    AppColorPalette.secondaryMaroon.withValues(alpha: 0.02),
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
                      60, // Increased from 16 to 60 to create more space from the appbar
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
                      // Added an empty SizedBox to provide additional space from the appbar
                      const SizedBox(height: 30),

                      _buildMenuSection(
                        context: context,
                        title: "Jadwal",
                        icon: Icons.schedule,
                        iconColor:
                            const Color(0xFF8B0000).withValues(alpha: 0.9),
                        index: 0,
                        menus: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.calendar_today,
                            title: "Jadwal Saya", // Ganti dari myTimetableKey
                            index: 0,
                            onTap: () =>
                                Get.toNamed(Routes.teacherMyTimetableScreen),
                          ),
                          if (isWalas)
                            _buildMenuItem(
                              context: context,
                              icon: Icons.class_,
                              title: "Kelas", // Ganti dari classSectionKey
                              index: 1,
                              onTap: () =>
                                  Get.toNamed(Routes.teacherClassSectionScreen),
                            ),
                        ],
                      ),

                      // Attendance Section
                      if (isWalas) ...[
                        _buildMenuSection(
                          context: context,
                          title: "Kehadiran", // Ganti dari attendanceKey
                          icon: Icons.people,
                          iconColor:
                              const Color(0xFF8B0000).withValues(alpha: 0.9),
                          index: 1,
                          menus: [
                            _buildMenuItem(
                              context: context,
                              icon: Icons.add_circle_outline,
                              title:
                                  "Kehadiran Kegiatan Khusus", // Ganti dari addAttendanceKey
                              index: 2,
                              onTap: () => Get.toNamed(
                                  Routes.teacherAddAttendanceScreen),
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.visibility,
                              title:
                                  "Laporan Kehadiran Kegiatan Khusus", // Ganti dari viewAttendanceKey
                              index: 3,
                              onTap: () => Get.toNamed(
                                  Routes.teacherViewAttendanceScreen),
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.subject,
                              title:
                                  "Laporan Kehadiran per Mata Pelajaran", // Ganti dari viewAttendanceSubjectKey
                              index: 4,
                              onTap: () => Get.toNamed(
                                  Routes.teacherViewAttendanceSubjectScreen),
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.summarize,
                              title:
                                  "Rekap Kehadiran", // Ganti dari recapAttendanceSubjectKey
                              index: 5,
                              onTap: () => Get.toNamed(
                                  Routes.recapAttendanceSubjectScreen),
                            ),
                            _buildMenuItem(
                              context: context,
                              icon: Icons.leaderboard,
                              title:
                                  "Point Alpha Siswa Tertinggi", // Ganti dari rankingAbsentKey
                              index: 6,
                              onTap: () =>
                                  Get.toNamed(Routes.attendanceRankingScreen),
                            ),
                          ],
                        ),
                      ],

                      // Lesson Section
                      _buildMenuSection(
                        context: context,
                        title: "Mata Pelajaran", // Ganti dari subjectLessonKey
                        icon: Icons.book,
                        iconColor:
                            const Color(0xFF8B0000).withValues(alpha: 0.9),
                        index: 2,
                        menus: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.edit,
                            title:
                                "Kelola Pelajaran (Bab)", // Ganti dari manageLessonKey
                            index: 7,
                            onTap: () =>
                                Get.toNamed(Routes.teacherManageLessonScreen),
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.topic,
                            title:
                                "Kelola Topik (Sub Bab)", // Ganti dari manageTopicKey
                            index: 8,
                            onTap: () =>
                                Get.toNamed(Routes.teacherManageTopicScreen),
                          ),
                        ],
                      ),

                      // Question Bank Section
                      _buildMenuSection(
                        context: context,
                        title: "Bank Soal",
                        icon: Icons.library_books,
                        iconColor:
                            const Color(0xFF8B0000).withValues(alpha: 0.9),
                        index: 3,
                        menus: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.question_answer,
                            title: "Bank Soal",
                            index: 9,
                            onTap: () => Get.toNamed(
                                Routes.questionSubjectScreen,
                                arguments: {'isStaffView': false}),
                          ),
                        ],
                      ),

                      // Assignment Section
                      _buildMenuSection(
                        context: context,
                        title: "Tugas Siswa", // Ganti dari studentAssignmentKey
                        icon: Icons.assignment,
                        iconColor:
                            const Color(0xFF8B0000).withValues(alpha: 0.9),
                        index: 4,
                        menus: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.edit_note,
                            title:
                                "Kelola Tugas", // Ganti dari manageAssignmentKey
                            index: 10,
                            onTap: () => Get.toNamed(
                                Routes.teacherManageAssignmentScreen),
                          ),
                        ],
                      ),

                      // Announcement Section
                      _buildMenuSection(
                        context: context,
                        title: "Pengumuman", // Ganti dari messageKey
                        icon: Icons.announcement,
                        iconColor:
                            const Color(0xFF8B0000).withValues(alpha: 0.9),
                        index: 5,
                        menus: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.campaign,
                            title:
                                "Kelola Pengumuman", // Ganti dari manageAnnouncementKey
                            index: 11,
                            onTap: () => Get.toNamed(
                                Routes.teacherManageAnnouncementScreen),
                          ),
                        ],
                      ),

                      // Offline Exam Section
                      _buildMenuSection(
                        context: context,
                        title: "Ujian Offline", // Ganti dari offlineExamKey
                        icon: Icons.school,
                        iconColor:
                            const Color(0xFF8B0000).withValues(alpha: 0.9),
                        index: 6,
                        menus: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.edit_document,
                            title:
                                "Jadwal Ujian Offline", // Ganti dari examsKey
                            index: 12,
                            onTap: () => Get.toNamed(Routes.examsScreen),
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.analytics,
                            title:
                                "Hasil Ujian Offline", // Ganti dari examResultKey
                            index: 13,
                            onTap: () =>
                                Get.toNamed(Routes.teacherExamResultScreen),
                          ),
                        ],
                      ),

                      // Online Exam Section
                      _buildMenuSection(
                        context: context,
                        title: "Ujian Online",
                        icon: Icons.computer,
                        iconColor:
                            const Color(0xFF8B0000).withValues(alpha: 0.9),
                        index: 7,
                        menus: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.laptop_chromebook,
                            title: "Ujian Online",
                            index: 14,
                            onTap: () => Get.toNamed(Routes.onlineExamScreen),
                          ),
                          _buildMenuItem(
                            context: context,
                            icon: Icons.assessment,
                            title: "Hasil Ujian Online",
                            index: 15,
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
                        iconColor:
                            const Color(0xFF8B0000).withValues(alpha: 0.9),
                        index: 8,
                        menus: [
                          _buildMenuItem(
                            context: context,
                            icon: Icons.list,
                            title: "Kelola Ekstrakurikuler",
                            index: 17,
                            onTap: () =>
                                Get.toNamed(Routes.extracurricularScreen),
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
                            onTap: () =>
                                Get.toNamed(Routes.extracurricularMember),
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
                    ],
                  ),
                ),
              ),
            );
          },
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
                          color: Colors.black, // Changed to black
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
                            ? AppColorPalette.primaryMaroon
                                .withValues(alpha: 0.1)
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
                          color: Colors.black, // Changed to black
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform: Matrix4.translationValues(
                          isHovered ? 8.0 : 0.0, 0.0, 0.0),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.black.withValues(
                            alpha: 0.5), // Changed to black with opacity
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

    // Draw dots pattern
    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    for (var x = 0; x < width; x += 30) {
      for (var y = 0; y < height; y += 30) {
        final offset = sin(x * 0.05 + y * 0.05 + animation.value) * 3;
        final radius = 1 + sin(x * 0.04 + y * 0.04 + animation.value) * 0.5;
        canvas.drawCircle(
          Offset(x + offset, y + offset),
          radius,
          dotPaint,
        );
      }
    }

    // Draw animated wave
    final wavePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var startY = 0; startY < height; startY += 200) {
      final path = Path();
      var startX = 0.0;
      path.moveTo(startX, startY.toDouble());

      for (var x = 0; x < width; x += 10) {
        final y = startY + sin(x * 0.02 + animation.value) * 20;
        path.lineTo(x.toDouble(), y);
      }

      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(BackgroundPatternPainter oldDelegate) => true;
}
