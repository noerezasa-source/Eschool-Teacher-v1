import 'dart:ui';
import 'package:eschool_saas_staff/data/models/exam/offlineExam.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/data/models/exam/offlineExamTimetableSlot.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';


class OfflineExamTimetableBottomsheet extends StatelessWidget {
  final List<OfflineExamTimeTableSlot>? timetableSlots;
  final Color primaryColor;
  final OfflineExam exam;
  final bool isLoading;

  const OfflineExamTimetableBottomsheet({
    super.key,
    required this.timetableSlots,
    this.primaryColor = const Color(0xFF8B2635),
    required this.exam,
    this.isLoading = false,
  });
  @override
  Widget build(BuildContext context) {
    // Check if timetableSlots is null or empty
    final bool hasTimetableData =
        timetableSlots != null && timetableSlots!.isNotEmpty;

    // Sort slots by date if they exist
    final sortedSlots = hasTimetableData
        ? (timetableSlots!.toList()
          ..sort((a, b) {
            try {
              final dateA = DateTime.parse(a.date!);
              final dateB = DateTime.parse(b.date!);
              return dateA.compareTo(dateB);
            } catch (e) {
              return 0;
            }
          }))
        : <OfflineExamTimeTableSlot>[];

    // Group slots by date if they exist
    Map<String, List<OfflineExamTimeTableSlot>> groupedByDate = {};
    if (hasTimetableData) {
      for (var slot in sortedSlots) {
        if (slot.date == null) continue;

        String formattedDate = '';
        try {
          final date = DateTime.parse(slot.date!);
          formattedDate = Utils.formatDate(date);
        } catch (e) {
          continue;
        }

        if (!groupedByDate.containsKey(formattedDate)) {
          groupedByDate[formattedDate] = [];
        }
        groupedByDate[formattedDate]!.add(slot);
      }
    }

    return CustomBottomsheet(
      titleLabelKey: "Jadwal Ujian",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Exam Header Card with glass effect
          _buildExamHeaderCard(context),
          const SizedBox(height: 20), // Timetable content
          Flexible(
            child: timetableSlots == null
                ? _buildLoadingState() // Tampilkan loading state jika timetableSlots == null
                : sortedSlots.isEmpty
                    ? _buildEmptyState()
                    : _buildTimetableContent(context, groupedByDate),
          ),
        ],
      ),
    );
  }

  Widget _buildExamHeaderCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Fancy gradient background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColorPalette.primaryMaroon,
                      primaryColor,
                      AppColorPalette.secondaryMaroon,
                      AppColorPalette.secondaryMaroon,
                    ],
                    stops: const [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Decorative pattern elements
            Positioned.fill(
              child: CustomPaint(
                painter: ModernPatternPainter(
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),

            // Glowing effect
            Positioned(
              top: -70,
              right: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Section with icon and title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon container
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.9),
                              Colors.white.withValues(alpha: 0.4),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: primaryColor,
                          size: 22,
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Title and class info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Exam name
                            ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white,
                                    Colors.white.withValues(alpha: 0.9),
                                  ],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.srcIn,
                              child: Text(
                                exam.name ?? "Jadwal Ujian",
                                style: GoogleFonts.poppins(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                  shadows: [
                                    const Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Class name
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                Utils().cleanClassName(exam.className ?? "-"),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Info Section with glass effect
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Dates Row
                            Row(
                              children: [
                                // Start date
                                _buildDateInfo(
                                  icon: Icons.calendar_today_rounded,
                                  title: "Tanggal Mulai",
                                  value: exam.examStartingDate != null &&
                                          exam.examStartingDate!.isNotEmpty
                                      ? Utils.formatDate(DateTime.parse(
                                          exam.examStartingDate!))
                                      : "-",
                                ),

                                const SizedBox(width: 16),

                                // End date
                                _buildDateInfo(
                                  icon: Icons.event_rounded,
                                  title: "Tanggal Selesai",
                                  value: exam.examEndingDate != null &&
                                          exam.examEndingDate!.isNotEmpty
                                      ? Utils.formatDate(
                                          DateTime.parse(exam.examEndingDate!))
                                      : "-",
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            Divider(
                                color: Colors.white.withValues(alpha: 0.2),
                                height: 1),
                            const SizedBox(height: 12),

                            // Stats Row
                            Row(
                              children: [
                                // Subject count
                                _buildStatInfo(
                                  icon: Icons.subject_rounded,
                                  value: "${timetableSlots?.length ?? "-"}",
                                  label: "Pelajaran",
                                ),

                                const SizedBox(width: 24),

                                // Duration
                                _buildStatInfo(
                                  icon: Icons.timer_outlined,
                                  value: _calculateTotalDuration(),
                                  label: "Total Durasi",
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.easeOutQuint,
        );
  }

  // Helper method for date information
  Widget _buildDateInfo({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for stat information
  Widget _buildStatInfo({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _calculateTotalDuration() {
    try {
      if (timetableSlots == null) {
        return "-";
      }

      int totalMinutes = 0;

      for (var slot in timetableSlots!) {
        if (slot.startTime != null && slot.endTime != null) {
          final startHour = Utils.getHourFromTimeDetails(time: slot.startTime!);
          final startMinute =
              Utils.getMinuteFromTimeDetails(time: slot.startTime!);
          final endHour = Utils.getHourFromTimeDetails(time: slot.endTime!);
          final endMinute = Utils.getMinuteFromTimeDetails(time: slot.endTime!);

          final startTotalMinutes = startHour * 60 + startMinute;
          final endTotalMinutes = endHour * 60 + endMinute;
          final duration = endTotalMinutes - startTotalMinutes;

          if (duration > 0) {
            totalMinutes += duration;
          }
        }
      }

      final hours = totalMinutes ~/ 60;
      return hours > 0 ? "$hours jam" : "${totalMinutes % 60} menit";
    } catch (e) {
      return "-";
    }
  }

  Widget _buildTimetableContent(BuildContext context,
      Map<String, List<OfflineExamTimeTableSlot>> groupedByDate) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: groupedByDate.length,
      itemBuilder: (context, dateIndex) {
        final date = groupedByDate.keys.elementAt(dateIndex);
        final slots = groupedByDate[date]!;
        final firstDateSlot = slots.first;

        // Parse the date to extract day number and day name
        DateTime? parsedDate;
        String dayName = "";
        String dayNumber = "";

        try {
          parsedDate = DateTime.parse(firstDateSlot.date!);
          dayName = _getDayName(parsedDate.weekday);
          dayNumber = parsedDate.day.toString();
        } catch (e) {
          // Use defaults
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern date header with day visualization
            Container(
              margin: const EdgeInsets.only(bottom: 18, top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Adding padding to shift the circular date to the right
                  const SizedBox(width: 15),
                  // Day number in circle
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, const Color(0xFF5A2223)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        dayNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Day name and date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dayName,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              parsedDate != null
                                  ? DateFormat('MMMM yyyy', 'id')
                                      .format(parsedDate)
                                  : "-",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Exam count chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(
                  duration: 400.ms,
                  delay: (100 * dateIndex).ms,
                )
                .slideX(
                  begin: -0.1,
                  end: 0,
                  duration: 500.ms,
                  delay: (100 * dateIndex).ms,
                  curve: Curves.easeOutQuint,
                ),

            // Subjects for this date in a timeline layout
            ...List.generate(
              slots.length,
              (index) => _buildSubjectTimelineCard(context, slots[index],
                  dateIndex * 100 + index, index == slots.length - 1),
            ),
          ],
        );
      },
    );
  }

  String _getDayName(int weekday) {
    const days = [
      '',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    return days[weekday];
  }

  Widget _buildSubjectTimelineCard(BuildContext context,
      OfflineExamTimeTableSlot slot, int animationIndex, bool isLast) {
    final subjectName = slot.subject?.getSybjectNameWithType() ?? "-";
    return Container(
      margin: EdgeInsets.only(left: 41, right: 26, bottom: isLast ? 0 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject header with time
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor,
                          const Color(0xFF5A2223), // Deeper complementary shade
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Decorative elegant circle patterns
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: CustomPaint(
                              painter: ElegantCirclesDecorationPainter(
                                  color: Colors.white),
                            ),
                          ),
                        ),

                        // Main content
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Subject icon
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.book,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Subject name with improved typography
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pelajaran',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    CustomTextContainer(
                                      textKey: subjectName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        height: 1.2,
                                        shadows: [
                                          const Shadow(
                                            color: Colors.black26,
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Elegant time display
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.95),
                                      Colors.white.withValues(alpha: 0.85),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 14,
                                      color: primaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      Utils.formatTime(
                                        timeOfDay: TimeOfDay(
                                          hour: Utils.getHourFromTimeDetails(
                                              time: slot.startTime!),
                                          minute:
                                              Utils.getMinuteFromTimeDetails(
                                                  time: slot.startTime!),
                                        ),
                                        context: context,
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Details section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Time and duration info
                        Row(
                          children: [
                            _buildInfoItem(
                              title: "Durasi",
                              value: _calculateDuration(
                                  slot.startTime!, slot.endTime!),
                              icon: Icons.timer_outlined,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoItem(
                              title: "Waktu Selesai",
                              value: Utils.formatTime(
                                timeOfDay: TimeOfDay(
                                  hour: Utils.getHourFromTimeDetails(
                                      time: slot.endTime!),
                                  minute: Utils.getMinuteFromTimeDetails(
                                      time: slot.endTime!),
                                ),
                                context: context,
                              ),
                              icon: Icons.access_time_filled_rounded,
                              color: const Color(0xFF5A6ACF),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Marks row
                        Row(
                          children: [
                            _buildInfoItem(
                              title: "Nilai Total",
                              value: "${slot.totalMarks ?? 0}",
                              icon: Icons.assignment_rounded,
                              color: const Color(0xFF43A047),
                            ),
                            const SizedBox(width: 8),
                            _buildInfoItem(
                              title: "Nilai Kelulusan",
                              value: "${slot.passingMarks ?? 0}",
                              icon: Icons.check_circle_rounded,
                              color: const Color(0xFFE57373),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: (80 * animationIndex).ms)
        .slideX(
            begin: 0.1,
            end: 0,
            curve: Curves.easeOutQuint,
            duration: 600.ms,
            delay: (80 * animationIndex).ms);
  }

  Widget _buildInfoItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy,
              size: 64,
              color: primaryColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Tidak ada jadwal tersedia",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Jadwal ujian akan ditampilkan di sini",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  String _calculateDuration(String startTime, String endTime) {
    try {
      final startHour = Utils.getHourFromTimeDetails(time: startTime);
      final startMinute = Utils.getMinuteFromTimeDetails(time: startTime);
      final endHour = Utils.getHourFromTimeDetails(time: endTime);
      final endMinute = Utils.getMinuteFromTimeDetails(time: endTime);

      final startMinutes = startHour * 60 + startMinute;
      final endMinutes = endHour * 60 + endMinute;
      final durationMinutes = endMinutes - startMinutes;

      if (durationMinutes <= 0) return "N/A";

      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;

      if (hours > 0) {
        return "$hours jam ${minutes > 0 ? "$minutes menit" : ""}";
      } else {
        return "$minutes menit";
      }
    } catch (e) {
      return "N/A";
    }
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
      itemCount: 6,
      itemBuilder: (context, index) => const SkeletonExamCard(),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class ExamCardBackgroundPainter extends CustomPainter {
  final Color color;
  final double angle;

  ExamCardBackgroundPainter({required this.color, required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw patterned background with rotated lines
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle * (3.14159 / 180));
    canvas.translate(-center.dx, -center.dy);

    const spacing = 12.0;
    for (double i = -size.width; i < size.width * 2; i += spacing) {
      canvas.drawLine(
        Offset(i, -size.height),
        Offset(i + size.height * 2, size.height * 2),
        paint..strokeWidth = 4,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CirclePatternPainter extends CustomPainter {
  final Color color;

  CirclePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw decorative circles
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.3),
      size.width * 0.4,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.7),
      size.width * 0.3,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CornerDecoratorPainter extends CustomPainter {
  final Color color;

  CornerDecoratorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(size.width * 0.3, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.7)
      ..close();

    canvas.drawPath(path, paint);

    // Draw a smaller accent path
    final path2 = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.5)
      ..close();

    canvas.drawPath(path2, paint..color = color.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ModernPatternPainter extends CustomPainter {
  final Color color;

  ModernPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw decorative patterns
    // Abstract circular patterns
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.3),
      size.width * 0.2,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.7),
      size.width * 0.15,
      paint,
    );

    // Draw diagonal lines
    for (int i = 0; i < 5; i++) {
      final offset = i * 20.0;
      canvas.drawLine(
        Offset(size.width - offset, 0),
        Offset(size.width, offset),
        paint,
      );
    }

    // Draw abstract decorations in the corner
    final path = Path()
      ..moveTo(size.width, size.height * 0.7)
      ..lineTo(size.width * 0.7, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ElegantCirclesDecorationPainter extends CustomPainter {
  final Color color;

  ElegantCirclesDecorationPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw multiple decorative circles with varying sizes and positions
    for (int i = 0; i < 5; i++) {
      double opacity = 0.1 - (i * 0.02);
      paint.color = color.withValues(alpha: opacity > 0 ? opacity : 0.01);

      // Large circle in the top right
      canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.3),
        size.width * (0.25 + i * 0.1),
        paint,
      );

      // Small circle in the bottom left
      canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.7),
        size.width * (0.15 + i * 0.05),
        paint,
      );
    }

    // Add a few accent dots
    paint.style = PaintingStyle.fill;
    paint.color = color.withValues(alpha: 0.2);

    canvas.drawCircle(
      Offset(size.width * 0.95, size.height * 0.15),
      3,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.05, size.height * 0.85),
      2,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.9),
      4,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
