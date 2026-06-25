import 'package:eschool_saas_staff/cubits/extracurricular/extracurricularTimetableCubit.dart';
import 'package:eschool_saas_staff/data/repositories/extracurricular/extracurricularTimetableRepository.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/data/models/extracurricular/extracurricular.dart';
import 'package:eschool_saas_staff/data/repositories/extracurricular/extracurricularRepository.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/errorContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart' as constants;
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get/get.dart';
import 'package:eschool_saas_staff/ui/screens/extracurricular/createExtracurricularTimetableScreen.dart';
import 'package:eschool_saas_staff/cubits/extracurricularTimetable/extracurricularTimetableCubit.dart'
    as timetable_cubit;
import 'package:eschool_saas_staff/ui/widgets/extracurricular/extracurricularTimetableItem.dart';

class ExtracurricularTimetableScreen extends StatefulWidget {
  const ExtracurricularTimetableScreen({super.key});

  static Widget getRouteInstance() {
    return BlocProvider(
      create: (context) => ExtracurricularTimetableCubit(
        ExtracurricularTimetableRepository(),
      ),
      child: const ExtracurricularTimetableScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<ExtracurricularTimetableScreen> createState() =>
      _ExtracurricularTimetableScreenState();
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

class _ExtracurricularTimetableScreenState
    extends State<ExtracurricularTimetableScreen>
    with TickerProviderStateMixin {
  late String _selectedDayKey = Utils.weekDays[DateTime.now().weekday - 1];

  // Animation controller for app bar effects
  late AnimationController _fabAnimationController;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _dayScrollController = ScrollController();
  final List<GlobalKey> _dayKeys = List.generate(7, (_) => GlobalKey());

  // Theme colors
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  Color get _maroonLight => AppColorPalette.secondaryMaroon;

  // Day mapping for the UI and backend
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
        context
            .read<ExtracurricularTimetableCubit>()
            .getExtracurricularTimetable();
      }

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

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _focusSelectedDay();
                      });
                    },
                    highlightColor: Colors.white.withValues(alpha: 0.1),
                    splashColor: Colors.white.withValues(alpha: 0.2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 14),
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

  Widget _buildTimetableSkeleton() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.only(
            bottom: 25,
            top: Utils.appContentTopScrollPadding(context: context) + 100),
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

  // Function to handle add button press
  Future<void> _handleAddPressed() async {
    // Fetch fresh extracurricular data
    List<Extracurricular>? extracurriculars;

    try {
      final extracurricularRepo = ExtracurricularRepository();
      extracurriculars = await extracurricularRepo.getExtracurriculars();
    } catch (e) {
      debugPrint('Error fetching extracurriculars: $e');
      if (!mounted) return;
      // Fallback: try to get from current timetable state
      final currentState = context.read<ExtracurricularTimetableCubit>().state;
      if (currentState is ExtracurricularTimetableSuccess) {
        extracurriculars = currentState.timetables.map((timetable) {
          return Extracurricular(
            id: timetable.id ?? 0,
            name: timetable.extracurricularName ?? 'Unnamed',
            description: '',
            coachId: 0,
            coachName: '',
            createdAt: '',
            updatedAt: '',
          );
        }).toList();
      }
    }

    final result = await Get.to(() => BlocProvider(
          create: (context) => timetable_cubit.ExtracurricularTimetableCubit(
            ExtracurricularTimetableRepository(),
          ),
          child: CreateExtracurricularTimetableScreen(
            extracurriculars: extracurriculars,
          ),
        ));

    if (result == true) {
      if (!mounted) return;
      // Refresh timetable data
      context
          .read<ExtracurricularTimetableCubit>()
          .getExtracurricularTimetable();
    }
  }

  Widget _buildAppBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: MediaQuery.of(context).padding.top + 170,
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

            // App bar with blur effect - Title and Add Button
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
                              highlightColor:
                                  Colors.white.withValues(alpha: 0.1),
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
                              'Jadwal Kurikuler',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        // Add button - sama seperti di CustomModernAppBar
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: AnimatedBuilder(
                            animation: _fabAnimationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 +
                                    (_fabAnimationController.value * 0.02),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(50),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(50),
                                    highlightColor:
                                        Colors.white.withValues(alpha: 0.15),
                                    splashColor:
                                        Colors.white.withValues(alpha: 0.25),
                                    onTap: _handleAddPressed,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.12),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                            spreadRadius: 0.3,
                                          ),
                                          // Subtle glow shadow
                                          BoxShadow(
                                            color: _maroonPrimary.withValues(
                                                alpha: 0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 0),
                                            spreadRadius: 1,
                                          ),
                                        ],
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.4),
                                          width: 1.5,
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            _maroonLight.withValues(
                                                alpha: 0.75),
                                            _maroonPrimary.withValues(
                                                alpha: 0.75),
                                          ],
                                        ),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Glow effect
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: RadialGradient(
                                                colors: [
                                                  Colors.white
                                                      .withValues(alpha: 0.25),
                                                  Colors.white
                                                      .withValues(alpha: 0.0),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Icon
                                          const Icon(
                                            Icons.add_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Horizontal day selector
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
          BlocBuilder<ExtracurricularTimetableCubit,
              ExtracurricularTimetableState>(
            builder: (context, state) {
              if (state is ExtracurricularTimetableSuccess) {
                // Map the UI day key to backend day name
                String selectedDay;
                final int dayIndex = Utils.weekDays.indexOf(_selectedDayKey);
                if (dayIndex >= 0 && dayIndex < constants.weekDays.length) {
                  selectedDay = constants.weekDays[dayIndex];
                } else {
                  selectedDay = _selectedDayKey.substring(0, 1).toUpperCase() +
                      _selectedDayKey.substring(1);
                }

                // Filter items that have schedule for selected day
                final filteredItems = state.timetables.where((item) {
                  final schedule = item.getScheduleForDay(selectedDay);
                  return schedule != null &&
                      schedule != '-' &&
                      schedule.isNotEmpty;
                }).toList();

                if (filteredItems.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: CustomTextContainer(
                        textKey: 'Tidak ada jadwal ekstrakurikuler',
                      ),
                    ),
                  );
                }

                return Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                        bottom: 25,
                        top:
                            Utils.appContentTopScrollPadding(context: context) +
                                100),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding:
                          EdgeInsets.all(constants.appContentHorizontalPadding),
                      color: Theme.of(context).colorScheme.surface,
                      child: Column(
                        children: filteredItems.map((item) {
                          return ExtracurricularTimetableItem(
                            item: item,
                            selectedDay: selectedDay,
                            onRefresh: () {
                              context
                                  .read<ExtracurricularTimetableCubit>()
                                  .getExtracurricularTimetable();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              }

              if (state is ExtracurricularTimetableFailure) {
                return ErrorContainer(
                  errorMessage: state.errorMessage,
                  onTapRetry: () {
                    context
                        .read<ExtracurricularTimetableCubit>()
                        .getExtracurricularTimetable();
                  },
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
