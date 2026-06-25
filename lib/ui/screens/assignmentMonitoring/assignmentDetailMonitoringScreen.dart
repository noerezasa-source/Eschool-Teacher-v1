import 'package:eschool_saas_staff/cubits/assignment/teacherAssignmentDetailCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/teacherAssignmentDetail.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/data/repositories/academics/assignmentMonitoringRepository.dart';
import 'package:eschool_saas_staff/ui/screens/assignmentMonitoring/simpleAssignmentCard.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:ui';
import 'package:shimmer/shimmer.dart';

// Custom painter for decorative elements in the app bar
class AppBarDecorationPainter extends CustomPainter {
  final Color color;

  AppBarDecorationPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw decorative circles
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.2), 30, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 20, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.15), 15, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.7), 10, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.4), 8, paint);

    // Draw arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final arcRect = Rect.fromLTRB(size.width * 0.1, size.height * 0.2,
        size.width * 0.6, size.height * 0.6);
    canvas.drawArc(arcRect, 0.2, 1.5, false, arcPaint);

    // Draw another arc
    final arcRect2 = Rect.fromLTRB(size.width * 0.5, size.height * 0.4,
        size.width * 0.9, size.height * 0.8);
    canvas.drawArc(arcRect2, 3, 1.5, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class AssignmentDetailMonitoringScreen extends StatefulWidget {
  final int teacherId;
  final String teacherName;

  const AssignmentDetailMonitoringScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  static Widget getRouteInstance(
      {required int teacherId, required String teacherName}) {
    return BlocProvider(
      create: (context) => TeacherAssignmentDetailCubit(
        AssignmentMonitoringRepository(),
      ),
      child: AssignmentDetailMonitoringScreen(
        teacherId: teacherId,
        teacherName: teacherName,
      ),
    );
  }

  @override
  State<AssignmentDetailMonitoringScreen> createState() =>
      _AssignmentDetailMonitoringScreenState();
}

class _AssignmentDetailMonitoringScreenState
    extends State<AssignmentDetailMonitoringScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Define colors
  Color get maroonPrimary => AppColorPalette.primaryMaroon;
  Color get maroonLight => AppColorPalette.secondaryMaroon;
  final Color maroonDark = const Color(0xFF6A0F2A);
  Color get accentColor => AppColorPalette.lightMaroon;
  Color get bgColor => AppColorPalette.accentPink;
  final Color cardColor = Colors.white;
  final Color textDarkColor = const Color(0xFF2D2D2D);
  final Color textMediumColor = const Color(0xFF717171);
  final Color borderColor = const Color(0xFFE8E8E8); // Filter variables
  String _selectedClass = '';
  String _selectedSubject = '';
  DateTime? _startDate;
  DateTime? _endDate;
  @override
  void initState() {
    super.initState();

    // Initialize localization for Indonesian dates
    initializeDateFormatting('id_ID', null);

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Start animations
    _animationController
        .forward(); // Set current date range to the last 30 days by default
    _endDate = DateTime.now();
    _startDate = _endDate?.subtract(const Duration(days: 30));

    // Load initial data
    _fetchTeacherAssignmentDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Fetches assignment details based on current filters
  void _fetchTeacherAssignmentDetails() {
    final String? formattedStartDate = _startDate != null
        ? DateFormat('yyyy-MM-dd').format(_startDate!)
        : null;

    final String? formattedEndDate =
        _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

    context.read<TeacherAssignmentDetailCubit>().getTeacherAssignmentDetails(
          teacherId: widget.teacherId,
          submissionStatus: '', // Status filter removed as requested
          startDate: formattedStartDate,
          endDate: formattedEndDate,
        );
  }

  void _changeClass(String className) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedClass = className;
    });
    // Here you would filter assignments based on the selected class
    // We'll implement the visual filtering in the UI layer since we don't have API endpoint for that
  }

  void _changeSubject(String subject) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedSubject = subject;
    });
    // Here you would filter assignments based on the selected subject
    // We'll implement the visual filtering in the UI layer since we don't have API endpoint for that
  }

  void _changeDateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      HapticFeedback.lightImpact();
      setState(() {
        _startDate = start;
        _endDate = end;
      });
      _fetchTeacherAssignmentDetails();
    }
  }

  void _showClassFilter(BuildContext context) {
    // Get unique classes from the assignments
    final assignments = (context.read<TeacherAssignmentDetailCubit>().state
                as TeacherAssignmentDetailSuccess?)
            ?.assignments ??
        [];

    final Set<String> uniqueClasses =
        assignments.map((assignment) => assignment.classSection).toSet();

    final List<String> options = ['Semua Kelas', ...uniqueClasses];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Kelas',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: maroonDark,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RadioGroup<String>(
                  groupValue:
                      _selectedClass == '' ? 'Semua Kelas' : _selectedClass,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _changeClass(value == 'Semua Kelas' ? '' : value ?? '');
                  },
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(options[index]),
                        leading: Radio<String>(
                          value: options[index],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSubjectFilter(BuildContext context) {
    // Get unique subjects from the assignments
    final assignments = (context.read<TeacherAssignmentDetailCubit>().state
                as TeacherAssignmentDetailSuccess?)
            ?.assignments ??
        [];

    final Set<String> uniqueSubjects =
        assignments.map((assignment) => assignment.subject).toSet();

    final List<String> options = ['Semua Mata Pelajaran', ...uniqueSubjects];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Mata Pelajaran',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: maroonDark,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RadioGroup<String>(
                  groupValue: _selectedSubject == ''
                      ? 'Semua Mata Pelajaran'
                      : _selectedSubject,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _changeSubject(
                        value == 'Semua Mata Pelajaran' ? '' : value ?? '');
                  },
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(options[index]),
                        leading: Radio<String>(
                          value: options[index],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDateRangePicker(BuildContext context) {
    showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: maroonPrimary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    ).then((dateRange) {
      if (dateRange != null) {
        _changeDateRange(dateRange.start, dateRange.end);
      }
    });
  }
  // Submission status filter has been removed as requested

  // Build the app bar with stacked filter rows
  Widget _buildAppbarAndFilters() {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height:
            MediaQuery.of(context).padding.top + 210, // Height to fit 3 rows
        child: Stack(
          children: [
            // Fancy gradient background with animated particles
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, _) {
                  return ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColorPalette.primaryMaroon,
                          maroonPrimary,
                          AppColorPalette.secondaryMaroon,
                          maroonLight,
                        ],
                        stops: const [0.0, 0.3, 0.6, 1.0],
                        transform:
                            GradientRotation(_animationController.value * 0.02),
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcATop,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            maroonDark,
                            maroonPrimary,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Decorative design elements
            Positioned.fill(
              child: CustomPaint(
                painter: AppBarDecorationPainter(
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),

            // Animated glowing effect
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, _) {
                return Positioned(
                  top: -100 + (_animationController.value * 20),
                  right: -60 + (_animationController.value * 10),
                  child: Container(
                    width: 200,
                    height: 200,
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
                );
              },
            ),

            // Main app bar content with frosted glass effect - TOP ROW
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Back button with ripple effect
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              highlightColor:
                                  Colors.white.withValues(alpha: 0.1),
                              splashColor: Colors.white.withValues(alpha: 0.2),
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Animated divider
                        Container(
                          height: 24,
                          width: 1.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.4),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),

                        // Title with animated badge
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Main title
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Animated icon
                                    AnimatedBuilder(
                                      animation: _animationController,
                                      builder: (context, child) {
                                        return Transform.rotate(
                                          angle:
                                              _animationController.value * 0.05,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.white
                                                      .withValues(alpha: 0.9),
                                                  Colors.white
                                                      .withValues(alpha: 0.4),
                                                ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.assignment_outlined,
                                              color: maroonPrimary,
                                              size: 20,
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    const SizedBox(width: 12),

                                    // Title text with glowing effect
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
                                        "Pengumpulan Tugas",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
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
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // MIDDLE ROW - Class and Subject Filters with frosted glass effect
            Positioned(
              top: MediaQuery.of(context).padding.top + 75,
              left: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Class filter
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showClassFilter(context),
                              highlightColor:
                                  Colors.white.withValues(alpha: 0.1),
                              splashColor: Colors.white.withValues(alpha: 0.2),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.class_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _selectedClass.isEmpty
                                            ? 'Semua Kelas'
                                            : _selectedClass,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Vertical divider
                        Container(
                          height: 24,
                          width: 1.5,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.4),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),

                        // Subject filter
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showSubjectFilter(context),
                              highlightColor:
                                  Colors.white.withValues(alpha: 0.1),
                              splashColor: Colors.white.withValues(alpha: 0.2),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.book_outlined,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _selectedSubject.isEmpty
                                            ? 'Semua Pelajaran'
                                            : _selectedSubject,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 150.ms)
                  .slideY(begin: -0.2, end: 0, curve: Curves.easeOutQuad),
            ), // BOTTOM ROW - Date Filter with frosted glass effect (status filter removed)
            Positioned(
              bottom: 10,
              left: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          spreadRadius: 0,
                        )
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showDateRangePicker(context),
                        highlightColor: Colors.white.withValues(alpha: 0.1),
                        splashColor: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(15),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Enhanced calendar icon
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.2),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.calendar_today_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rentang Tanggal',
                                    style: GoogleFonts.poppins(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _startDate != null && _endDate != null
                                        ? '${DateFormat('dd MMM yyyy', 'id_ID').format(_startDate!)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(_endDate!)}'
                                        : 'Pilih Rentang Tanggal',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 200.ms)
                  .slideY(begin: -0.2, end: 0, curve: Curves.easeOutQuad),
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
          // Animated container for icon
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: maroonPrimary.withValues(alpha: 0.05),
              boxShadow: [
                BoxShadow(
                  color: maroonPrimary.withValues(alpha: 0.05),
                  blurRadius: 20,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 80,
              color: maroonLight.withValues(alpha: 0.7),
            ),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // Empty state title
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: [
                  maroonDark,
                  maroonPrimary,
                  maroonLight,
                ],
                stops: const [0.0, 0.5, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcIn,
            child: Text(
              'Tidak ada tugas ditemukan',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms),

          const SizedBox(height: 12),

          // Empty state subtitle with decorative container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.grey.shade100,
              ),
            ),
            child: Text(
              'Coba ubah filter atau cek di lain waktu',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textMediumColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 400.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildAssignmentItem(TeacherAssignmentDetail assignment) {
    // Skip filtering if no filter is selected
    if (_selectedClass.isNotEmpty &&
        !assignment.classSection.contains(_selectedClass)) {
      return const SizedBox.shrink();
    }

    if (_selectedSubject.isNotEmpty &&
        !assignment.subject.contains(_selectedSubject)) {
      return const SizedBox.shrink();
    }

    // Use the SimpleAssignmentCard component for a cleaner and more elegant design
    return SimpleAssignmentCard(
      assignment: assignment,
      maroonPrimary: maroonPrimary,
      maroonDark: maroonDark,
      maroonLight: maroonLight,
      textDarkColor: textDarkColor,
      textMediumColor: textMediumColor,
    );
  }

  Widget _buildAssignmentCardSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: maroonPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: maroonLight.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Assignment details section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Assignment name placeholder
                        Container(
                          height: 16,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Subject placeholder
                        Container(
                          height: 13,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Class badge placeholder
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 0),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      height: 13,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),

              // Divider placeholder
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 1,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),

              // Due date section placeholder
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Calendar icon placeholder
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Date info placeholder
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 13,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: 15,
                            width: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(3),
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
      ),
    );
  }

  Widget _buildAssignmentDetailMonitoringSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: maroonPrimary.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Row(
                children: [
                  // Icon placeholder
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text placeholders
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 18,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 14,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Count badge placeholder
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Assignment cards skeleton
          ...List.generate(6, (index) {
            return _buildAssignmentCardSkeleton();
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Main list content
          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 230, bottom: 20),
              child: BlocBuilder<TeacherAssignmentDetailCubit,
                  TeacherAssignmentDetailState>(
                builder: (context, state) {
                  if (state is TeacherAssignmentDetailLoading) {
                    return _buildAssignmentDetailMonitoringSkeleton();
                  } else if (state is TeacherAssignmentDetailFailure) {
                    return CustomErrorWidget(
                      message: state.errorMessage,
                      onRetry: () => _fetchTeacherAssignmentDetails(),
                      primaryColor: maroonPrimary,
                    );
                  } else if (state is TeacherAssignmentDetailSuccess) {
                    // Filter assignments based on selected class and subject (if API doesn't support)
                    final assignments = state.assignments;

                    if (assignments.isEmpty) {
                      return _buildEmptyState();
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced header for assignment count with gradient
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  maroonPrimary.withValues(alpha: 0.9),
                                  maroonLight.withValues(alpha: 0.9),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: maroonPrimary.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Decorative icon with background
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.15),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.assignment_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Assignment count and information
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Daftar Tugas',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${assignments.length} tugas ditemukan',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Animated count badge
                                AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                            spreadRadius: -2 +
                                                _animationController.value * 2,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${assignments.length}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: maroonPrimary,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                              .slideY(begin: -0.1, end: 0),

                          // Assignment list with filtered view and staggered animation
                          ...assignments.asMap().entries.map((entry) {
                            final index = entry.key;
                            final assignment = entry.value;
                            // Create staggered effect by delaying each item
                            return _buildAssignmentItem(assignment)
                                .animate()
                                .fadeIn(
                                    delay: Duration(milliseconds: 100 * index))
                                .moveY(
                                    begin: 10,
                                    end: 0,
                                    delay: Duration(milliseconds: 100 * index));
                          }),
                        ],
                      ),
                    );
                  }

                  return SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: maroonLight.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Pilih filter untuk melihat tugas',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: textMediumColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // App bar and filters
          _buildAppbarAndFilters(),
        ],
      ),
    );
  }
}

