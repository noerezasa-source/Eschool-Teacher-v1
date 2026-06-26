import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool_saas_staff/cubits/teacher/timeTableOfTeacherCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/data/models/auth/userDetails.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/errorContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/academics/timetableSlotContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart' as constants;
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class TeacherTimeTableDetailsScreen extends StatefulWidget {
  final UserDetails teacherDetails;
  const TeacherTimeTableDetailsScreen(
      {super.key, required this.teacherDetails});

  static Widget getRouteInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return BlocProvider(
      create: (context) => TimeTableOfTeacherCubit(),
      child: TeacherTimeTableDetailsScreen(
        teacherDetails: arguments['teacherDetails'],
      ),
    );
  }

  static Map<String, dynamic> buildArguments(
      {required UserDetails teacherDetails}) {
    return {
      "teacherDetails": teacherDetails,
    };
  }

  @override
  State<TeacherTimeTableDetailsScreen> createState() =>
      _TeacherTimeTableDetailsScreenState();
}

// Custom painter for decorative elements
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

// Skeleton widget for timetable slots
class _TimetableSlotSkeleton extends StatelessWidget {
  const _TimetableSlotSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10.0, bottom: 10.0),
      height: Utils().getResponsiveHeight(context, 150),
      child: LayoutBuilder(builder: (context, boxConstraints) {
        return Row(
          children: [
            // Time column skeleton (20% width)
            SizedBox(
              width: boxConstraints.maxWidth * (0.2),
              child: Column(
                children: [
                  // Start time skeleton
                  Container(
                    height: 20,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 12,
                    width: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  // Vertical line skeleton
                  Container(
                    height: Utils().getResponsiveHeight(context, 65),
                    width: Utils.getScaledValue(context, 1.5),
                    color: Colors.white,
                  ),
                  const Spacer(),
                  // End time skeleton
                  Container(
                    height: 20,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 12,
                    width: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // Spacing (5% width)
            SizedBox(width: boxConstraints.maxWidth * (0.05)),
            // Main content skeleton (70% width)
            SizedBox(
              width: boxConstraints.maxWidth * (0.7),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: constants.appContentHorizontalPadding,
                    vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject label skeleton
                    Container(
                      height: 12,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Subject name skeleton
                    Container(
                      height: 18,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    // Class/Teacher label skeleton
                    Container(
                      height: 12,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Class/Teacher name skeleton
                    Container(
                      height: 18,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _TeacherTimeTableDetailsScreenState
    extends State<TeacherTimeTableDetailsScreen> with TickerProviderStateMixin {
  late String _selectedDayKey = Utils.weekDays[DateTime.now().weekday - 1];

  // Animation controller for app bar effects
  late AnimationController _fabAnimationController;
  final ScrollController _scrollController = ScrollController();
  // Controller for horizontal day selector so we can ensure selected is visible
  final ScrollController _dayScrollController = ScrollController();
  // Keys for each day pill to allow ensureVisible
  final List<GlobalKey> _dayKeys = List.generate(7, (_) => GlobalKey());

  // Theme colors
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  Color get _maroonLight => AppColorPalette.secondaryMaroon;

  // Day mapping for the UI and backend (keys taken from Utils.weekDays for consistency)
  List<Map<String, String>> get _weekDays {
    final List<String> shortLabels = [
      'SEN',
      'SEL',
      'RAB',
      'KAM',
      'JUM',
      'SAB',
      'MIN'
    ];
    final List<String> longLabels = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];

    return List.generate(7, (i) {
      final key = Utils.weekDays.length > i ? Utils.weekDays[i] : '';
      return {
        'key': key,
        'short': shortLabels[i],
        'long': longLabels[i],
      };
    });
  }

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scrollController.addListener(_scrollListener);

    Future.delayed(Duration.zero, () {
      if (mounted) {
        // Fetch timetable for teacher for the current day by default
        context
            .read<TimeTableOfTeacherCubit>()
            .getTimeTableOfTeacher(teacherId: widget.teacherDetails.id ?? 0);
      }

      // After first frame, ensure the selected day pill is visible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusSelectedDay();
      });
    });
  }

  void _scrollListener() {
    if (_scrollController.offset > 50) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _dayScrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _focusSelectedDay() {
    try {
      final int index = Utils.weekDays.indexOf(_selectedDayKey);
      if (index >= 0 && index < _dayKeys.length) {
        final ctx = _dayKeys[index].currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.5,
            duration: const Duration(milliseconds: 300),
          );
        }
      }
    } catch (e) {
      // ignore
    }
    if (mounted) setState(() {});
  }

  // New horizontal day selector
  Widget _buildHorizontalDaySelector() {
    return SingleChildScrollView(
      controller: _dayScrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _weekDays.asMap().entries.map((entry) {
            final idx = entry.key;
            final day = entry.value;
            bool isSelected = _selectedDayKey == day['key'];
            return Padding(
                key: _dayKeys[idx],
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _selectedDayKey = day['key']!;
                      });

                      // Trigger a refresh/fetch if needed - keep consistency with teacherMyTimetableScreen
                      context
                          .read<TimeTableOfTeacherCubit>()
                          .getTimeTableOfTeacher(
                              teacherId: widget.teacherDetails.id ?? 0);
                      // Ensure the tapped pill becomes visible
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _focusSelectedDay();
                      });
                    },
                    highlightColor: Colors.white.withValues(alpha: 0.1),
                    splashColor: Colors.white.withValues(alpha: 0.2),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected ? Colors.white : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.3),
                          width: isSelected ? 1 : 0.5,
                        ),
                      ),
                      child: Text(
                        day['short']!,
                        style: GoogleFonts.poppins(
                          color: isSelected ? _maroonPrimary : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                )
                    .animate(
                      autoPlay: false,
                      target: isSelected ? 1 : 0,
                    )
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.05, 1.05),
                      curve: Curves.easeOutCubic,
                      duration: const Duration(milliseconds: 300),
                    ));
          }).toList(),
        ),
      ),
    );
  }

  // Build timetable skeleton for loading state
  Widget _buildTimetableSkeleton() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.only(
            bottom: 25,
            top: Utils.appContentTopScrollPadding(context: context) + 150),
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(constants.appContentHorizontalPadding),
          color: Theme.of(context).colorScheme.surface,
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Column(
              children:
                  List.generate(5, (index) => const _TimetableSlotSkeleton()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: MediaQuery.of(context).padding.top +
            220, // Increased height for better spacing between elements
        child: Stack(
          children: [
            // Gradient background with animated shader
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _fabAnimationController,
                builder: (context, _) {
                  return ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColorPalette.primaryMaroon,
                          _maroonPrimary,
                          AppColorPalette.secondaryMaroon,
                          _maroonLight,
                        ],
                        stops: const [0.0, 0.3, 0.6, 1.0],
                        transform: GradientRotation(
                            _fabAnimationController.value * 0.02),
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcATop,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColorPalette.primaryMaroon,
                            const Color(0xFF9A1E3C),
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

            // Decorative elements
            Positioned.fill(
              child: CustomPaint(
                painter: AppBarDecorationPainter(
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),

            // Animated decorative circle
            AnimatedBuilder(
              animation: _fabAnimationController,
              builder: (context, _) {
                return Positioned(
                  top: -100 + (_fabAnimationController.value * 20),
                  right: -60 + (_fabAnimationController.value * 10),
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

            // App bar with blur effect - Title
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
                        // Back button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              highlightColor: Colors.white.withValues(alpha: 0.1),
                              splashColor: Colors.white.withValues(alpha: 0.2),
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Separator
                        Container(
                          height: 24,
                          width: 1.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.5),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),

                        // Title
                        Expanded(
                          child: Center(
                            child: Text(
                              Utils.getTranslatedLabel(timetableKey),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Teacher Profile Container with blur effect
            Positioned(
              top: MediaQuery.of(context).padding.top + 76,
              left: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 75,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          offset: const Offset(0, 10),
                          blurRadius: 20,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        // Upgraded profile image with tap to zoom
                        GestureDetector(
                          onTap: () {
                            final profileImage =
                                widget.teacherDetails.image ?? "";
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.9,
                                    height: MediaQuery.of(context).size.height *
                                        0.7,
                                    child: Stack(
                                      children: [
                                        InteractiveViewer(
                                          minScale: 0.5,
                                          maxScale: 4.0,
                                          child: profileImage.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: profileImage,
                                                  fit: BoxFit.contain,
                                                  placeholder: (context, url) =>
                                                      Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                                  Color>(
                                                              _maroonPrimary),
                                                    ),
                                                  ),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          Center(
                                                    child: Icon(
                                                      Icons.error,
                                                      color: _maroonPrimary,
                                                      size: 50,
                                                    ),
                                                  ),
                                                )
                                              : Center(
                                                  child: Icon(
                                                    Icons.person,
                                                    color: _maroonPrimary,
                                                    size: 100,
                                                  ),
                                                ),
                                        ),
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: Material(
                                            color:
                                                Colors.black.withValues(alpha: 0.5),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              onTap: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.9),
                                  Colors.white.withValues(alpha: 0.5)
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _maroonPrimary.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(2.5),
                            child: Hero(
                              tag:
                                  "teacherProfileImage_${widget.teacherDetails.id}",
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _maroonPrimary.withValues(alpha: 0.2),
                                  ),
                                  child: (widget.teacherDetails.image ?? "")
                                          .isNotEmpty
                                      ? Image.network(
                                          widget.teacherDetails.image ?? "",
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(Icons.person,
                                                      color: _maroonPrimary,
                                                      size: 30),
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        (loadingProgress
                                                                .expectedTotalBytes ??
                                                            1)
                                                    : null,
                                              ),
                                            );
                                          },
                                        )
                                      : const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Teacher information with enhanced styling
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.teacherDetails.firstName ?? "-",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Guru",
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 100.ms)
                .slideY(begin: -0.2, end: 0, curve: Curves.easeOutQuad),

            // Horizontal day selector with elegant design
            Positioned(
              bottom: 10,
              left: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildHorizontalDaySelector(),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .slideY(begin: -0.2, end: 0, curve: Curves.easeOutQuad),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BlocBuilder<TimeTableOfTeacherCubit, TimeTableOfTeacherState>(
            builder: (context, state) {
              if (state is TimeTableOfTeacherFetchSuccess) {
                // Map the UI day key (e.g. 'mon') to the backend/full name
                // (e.g. 'Monday') using constants.weekDays for consistency.
                String selectedDay;
                final int dayIndex = Utils.weekDays.indexOf(_selectedDayKey);
                if (dayIndex >= 0 && dayIndex < constants.weekDays.length) {
                  selectedDay = constants.weekDays[dayIndex];
                } else {
                  // Fallback: capitalize first letter (for older keys like 'monday')
                  selectedDay = _selectedDayKey.substring(0, 1).toUpperCase() +
                      _selectedDayKey.substring(1);
                }

                // Filter slots directly with the properly formatted day
                final slots = state.timeTableSlots
                    .where((element) => element.day == selectedDay)
                    .toList();

                if (slots.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: CustomTextContainer(
                        textKey: Utils.getTranslatedLabel(noTimeTableKey),
                      ),
                    ),
                  );
                }

                 final bool isToday = Utils.weekDays.indexOf(_selectedDayKey) == (DateTime.now().weekday - 1);

                 return Align(
                   alignment: Alignment.topCenter,
                   child: SingleChildScrollView(
                     controller: _scrollController,
                     padding: EdgeInsets.only(
                         bottom: 25,
                         top:
                             Utils.appContentTopScrollPadding(context: context) +
                                 150),
                     child: Container(
                       width: MediaQuery.of(context).size.width,
                       padding:
                           EdgeInsets.all(constants.appContentHorizontalPadding),
                       color: Theme.of(context).colorScheme.surface,
                       child: Column(
                         children: slots
                             .map((timeTableSlot) => TimetableSlotContainer(
                                   note: timeTableSlot.note ?? "",
                                   endTime: timeTableSlot.endTime ?? "",
                                   isForClass: false,
                                   classSectionName:
                                       timeTableSlot.classSection?.fullName ??
                                           "-",
                                   startTime: timeTableSlot.startTime ?? "",
                                   subjectName: timeTableSlot.subject
                                           ?.getSybjectNameWithType() ??
                                       "-",
                                   isActive: isToday &&
                                       Utils.isCurrentTimeWithinSlot(
                                           timeTableSlot.startTime ?? "",
                                           timeTableSlot.endTime ?? ""),
                                 ))
                             .toList(),
                       ),
                     ),
                   ),
                 );
              }

              if (state is TimeTableOfTeacherFetchFailure) {
                return Center(
                  child: ErrorContainer(
                    errorMessage: state.errorMessage,
                    onTapRetry: () {
                      context
                          .read<TimeTableOfTeacherCubit>()
                          .getTimeTableOfTeacher(
                              teacherId: widget.teacherDetails.id ?? 0);
                    },
                  ),
                );
              }

              return _buildTimetableSkeleton();
            },
          ),
          _buildAppBar(),
        ],
      ),
    );
  }
}
