import 'dart:async';
import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/student/studentsByClassSectionCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/attendence/attendanceCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/attendence/submitAttendanceCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/student/studentAttendance.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/holidayAttendanceContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/student/studentAttendanceContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherAddAttendanceScreen extends StatefulWidget {
  static Widget getRouteInstance() {
    //final arguments = Get.arguments as Map<String,dynamic>;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SubmitAttendanceCubit(),
        ),
        BlocProvider(
          create: (context) => AttendanceCubit(),
        ),
        BlocProvider(create: (context) => StudentsByClassSectionCubit()),
        BlocProvider(
          create: (context) => ClassesCubit(),
        ),
      ],
      child: const TeacherAddAttendanceScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  const TeacherAddAttendanceScreen({super.key});

  @override
  State<TeacherAddAttendanceScreen> createState() =>
      _TeacherAddAttendanceScreenState();
}

class _TeacherAddAttendanceScreenState extends State<TeacherAddAttendanceScreen>
    with TickerProviderStateMixin {
  List<({StudentAttendanceStatus status, int studentId})> attendanceReport = [];

  DateTime _selectedDateTime = DateTime.now();
  ClassSection? _selectedClassSection;

  final bool _isSendNotificationToGuardian = false;
  final bool _isHoliday = false;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchVisible = false;

  // Color scheme for maroon theme matching subject screen
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  Color get _maroonLight => AppColorPalette.secondaryMaroon;

  // Animation controllers
  late AnimationController _fabAnimationController;
  late final ScrollController _scrollController = ScrollController()
    ..addListener(scrollListener);
  StreamSubscription? _classSub;
  StreamSubscription? _studentsSub;

  @override
  void dispose() {
    _classSub?.cancel();
    _studentsSub?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(scrollListener);
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void scrollListener() {
    // Animate elements based on scroll
    if (_scrollController.offset > 50) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  @override
  void initState() {
    super.initState();

    debugPrint('timetable');
    // Initialize animation controllers
    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    Future.delayed(Duration.zero, () {
      if (mounted) {
        // Load classes first
        context.read<ClassesCubit>().getClasses();

        // Listen to ClassesCubit state changes to automatically select a class when loaded
        _classSub = context.read<ClassesCubit>().stream.listen((state) {
          if (state is ClassesFetchSuccess && _selectedClassSection == null) {
            if (state.primaryClasses.isNotEmpty) {
              debugPrint(
                  "Auto-selecting first class: ${state.primaryClasses.first.fullName}");
              changeClassSectionSelection(state.primaryClasses.first);
            } else if (state.primaryClasses.isNotEmpty) {
              debugPrint(
                  "Auto-selecting first available class: ${state.primaryClasses.first.fullName}");
              changeClassSectionSelection(state.primaryClasses.first);
            }
          }
        });

        // Listen to StudentsByClassSectionCubit state changes for debugging
        _studentsSub =
            context.read<StudentsByClassSectionCubit>().stream.listen((state) {
          if (state is StudentsByClassSectionFetchSuccess) {
            debugPrint(
                "✅ Students loaded successfully: ${state.studentDetailsList.length} students");
          } else if (state is StudentsByClassSectionFetchFailure) {
            debugPrint("❌ Failed to load students: ${state.errorMessage}");
          } else if (state is StudentsByClassSectionFetchInProgress) {
            debugPrint("⌛ Loading students...");
          }
        });
      }
    });
  }

  void getAttendance() {
    context
        .read<AttendanceCubit>()
        .fetchAttendance(
          date: _selectedDateTime,
          classSectionId: _selectedClassSection?.id ?? 0,
          type: null,
        )
        .catchError((error) {
      debugPrint('Error: $error');
    });
  }

  void getStudentList() {
    attendanceReport.clear();
    context.read<StudentsByClassSectionCubit>().fetchStudents(
          status:
              StudentListStatus.all, // Tampilkan semua siswa termasuk non-aktif
          classSectionId: _selectedClassSection?.id ?? 0,
        );
  }

  void changeClassSectionSelection(ClassSection? newSelectedClassSection) {
    _selectedClassSection = newSelectedClassSection;

    setState(() {});
    if (newSelectedClassSection != null) {
      getAttendance();
      getStudentList();
    }
  }

  Widget _buildStudents({required List<StudentAttendance> attendance}) {
    return BlocBuilder<StudentsByClassSectionCubit,
        StudentsByClassSectionState>(
      builder: (BuildContext context, StudentsByClassSectionState state) {
        if (state is StudentsByClassSectionFetchSuccess) {
          if (state.studentDetailsList.isEmpty) {
            return const SizedBox.shrink();
          }
          if (_isHoliday) {
            return const SizedBox.shrink();
          }
          final allStudents = state.studentDetailsList;

          // Filter students based on search query
          final filteredStudents = _searchQuery.isEmpty
              ? allStudents
              : allStudents.where((student) {
                  final fullName = (student.fullName ??
                          '${student.firstName ?? ''} ${student.lastName ?? ''}')
                      .trim()
                      .toLowerCase();
                  return fullName.contains(_searchQuery);
                }).toList();

          return StudentAttendanceContainer(
            studentAttendances: filteredStudents.map((e) {
              final matchedAttendance = attendance
                  .firstWhereOrNull((element) => element.studentId == e.id);

              debugPrint(matchedAttendance.toString());

              debugPrint('Found attendance record: ${matchedAttendance?.type}');

              return StudentAttendance.fromStudentDetails(
                  studentDetails: e, type: matchedAttendance?.type);
            }).toList(),
            allStudentAttendances: allStudents.map((e) {
              final matchedAttendance = attendance
                  .firstWhereOrNull((element) => element.studentId == e.id);

              return StudentAttendance.fromStudentDetails(
                  studentDetails: e, type: matchedAttendance?.type);
            }).toList(),
            onStatusChanged: (attendanceStatuses) {
              attendanceReport = attendanceStatuses;
            },
            isForAddAttendance: true,
          );
        } else if (state is StudentsByClassSectionFetchFailure) {
          return Center(
            child: Padding(
              padding:
                  EdgeInsets.only(top: topPaddingOfErrorAndLoadingContainer),
              child: CustomErrorWidget(
                message: state.errorMessage,
                onRetry: () {
                  getStudentList();
                },
                primaryColor: _maroonPrimary,
              ),
            ),
          );
        } else {
          // Return just the student list skeleton without extra padding
          return const SkeletonAttendanceList(itemCount: 8);
        }
      },
    );
  }

  Widget _buildStudentsContainer() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 20, bottom: 90),
        child: BlocBuilder<AttendanceCubit, AttendanceState>(
          builder: (context, state) {
            if (state is AttendanceFetchSuccess) {
              if (state.isHoliday) {
                return HolidayAttendanceContainer(
                  holiday: state.holidayDetails,
                );
              }

              // Title and subtitle section
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and subtitle section
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kehadiran Siswa',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _maroonPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.1, end: 0, curve: Curves.easeOutQuad),

                  // Students attendance list
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // List header with modern design
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _maroonPrimary.withValues(alpha: 0.9),
                                _maroonPrimary,
                                _maroonLight,
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            boxShadow: [
                              BoxShadow(
                                color: _maroonPrimary.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Animated icon
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.people_alt_rounded,
                                  color: Colors.white,
                                  size: 20,
                                )
                                    .animate()
                                    .fadeIn(duration: 300.ms)
                                    .slideX(begin: -0.2, end: 0),
                              ),

                              const SizedBox(width: 16),

                              // Title text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Daftar Kehadiran Siswa',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Student list
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: _buildStudents(attendance: state.attendance),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 200.ms)
                      .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad),
                ],
              );
            } else if (state is AttendanceFetchFailure) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * 0.2),
                  child: CustomErrorWidget(
                    message: state.errorMessage,
                    onRetry: () {
                      getAttendance();
                    },
                    primaryColor: _maroonPrimary,
                  ),
                ),
              );
            } else {
              // Return skeleton with same structure as the actual content
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and subtitle section skeleton
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 180,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // Students container skeleton with same structure
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header skeleton with same styling
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          child: Row(
                            children: [
                              // Icon skeleton
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Title skeleton
                              Container(
                                width: 160,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Student list skeleton
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: SkeletonAttendanceList(itemCount: 8),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (context, state) {
        if (state is AttendanceFetchSuccess) {
          if (state.isHoliday) {
            // Hide button completely
            return const SizedBox();
          }
          return BlocConsumer<SubmitAttendanceCubit, SubmitAttendanceState>(
              listener: (context, submitAttendanceState) {
            if (submitAttendanceState is SubmitAttendanceSuccess) {
              CustomSuccessMessage.show(
                context: context,
                message: "Berhasil menyimpan Kehadiran!",
                backgroundColor: Colors.green,
                textColor: Colors.white,
              );

              // Optional: Add haptic feedback
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
            } else if (submitAttendanceState is SubmitAttendanceFailure) {
              Utils.showSnackBar(
                context: context,
                message: submitAttendanceState.errorMessage,
              );
            }
          }, builder: (context, submitAttendanceState) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.8),
                      Colors.white,
                      Colors.white,
                    ],
                    stops: const [0.0, 0.2, 0.5, 1.0],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      // Always use the active button colors
                      colors: [
                        _maroonPrimary,
                        const Color(0xFF9A1E3C),
                        _maroonLight,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    // Always show the shadow
                    boxShadow: [
                      BoxShadow(
                        color: _maroonPrimary.withValues(alpha: 0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      highlightColor: Colors.white.withValues(alpha: 0.1),
                      splashColor: Colors.white.withValues(alpha: 0.2),
                      onTap: () {
                        // Log detailed submission data
                        debugPrint('=== ATTENDANCE SUBMISSION DATA ===');
                        debugPrint(
                            '📅 Date: ${Utils.formatDate(_selectedDateTime)}');
                        debugPrint(
                            '🏫 Class: ${_selectedClassSection?.fullName} (ID: ${_selectedClassSection?.id})');
                        debugPrint(
                            '🔔 Send Notification: $_isSendNotificationToGuardian');
                        debugPrint('📅 Is Holiday: $_isHoliday');
                        debugPrint('👥 Attendance Report:');

                        for (var attendance in attendanceReport) {
                          String status = '';
                          switch (attendance.status) {
                            case StudentAttendanceStatus.present:
                              status = '✅ Present';
                              break;
                            case StudentAttendanceStatus.absent:
                              status = '❌ Absent';
                              break;
                            default:
                              status = '❓ Unknown';
                          }
                          debugPrint(
                              '   Student ID: ${attendance.studentId} - Status: $status');
                        }
                        debugPrint('================================');

                        try {
                          context
                              .read<SubmitAttendanceCubit>()
                              .submitAttendance(
                                isHoliday: _isHoliday,
                                sendAbsentNotification:
                                    _isSendNotificationToGuardian,
                                dateTime: _selectedDateTime,
                                classSectionId: _selectedClassSection?.id ?? 0,
                                attendanceReport:
                                    _isHoliday ? [] : attendanceReport,
                              );
                        } catch (e) {
                          debugPrint('Error submitting attendance: $e');
                          debugPrint('Error details: ${e.toString()}');
                        }
                      },
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                            );
                          },
                          child: submitAttendanceState
                                  is SubmitAttendanceInProgress
                              ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  key: ValueKey<String>("loading"),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : Row(
                                  key: const ValueKey<String>("button"),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      Utils.getTranslatedLabel(submitKey),
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    if (attendanceReport.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(left: 12),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          "${attendanceReport.length}",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 500.ms);
          });
        }
        return const SizedBox();
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomModernAppBar(
      title: 'Kehadiran Siswa',
      icon: Icons.edit_calendar_rounded,
      fabAnimationController: _fabAnimationController,
      primaryColor: _maroonPrimary,
      lightColor: _maroonLight,
      height: 160, // Increased height to accommodate filters
      showSearchButton: true,
      onSearchPressed: () {
        setState(() {
          _isSearchVisible = !_isSearchVisible;
          if (!_isSearchVisible) {
            _searchQuery = '';
            _searchController.clear();
          }
        });
      },
      onBackPressed: () => Navigator.of(context).pop(),
      tabBuilder: (context) {
        // Show search input if search is active
        if (_isSearchVisible) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari nama siswa...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          );
        }

        // Default tab content for filters
        return Row(
          children: [
            // Date filter
            Expanded(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final selectedDate = await Utils.openDatePicker(
                      context: context,
                      inititalDate: _selectedDateTime,
                      lastDate: DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 30)),
                    );

                    if (selectedDate != null) {
                      _selectedDateTime = selectedDate;
                      setState(() {});
                      getAttendance();
                    }
                  },
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            Utils.formatDate(_selectedDateTime),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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

            // Class selection filter
            Expanded(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    final state = context.read<ClassesCubit>().state;
                    if (state is ClassesFetchSuccess) {
                      if (state.primaryClasses.isNotEmpty) {
                        Utils.showBottomSheet(
                          child: FilterSelectionBottomsheet<ClassSection>(
                            onSelection: (value) {
                              changeClassSectionSelection(value);
                              Get.back();
                            },
                            selectedValue: _selectedClassSection ??
                                state.primaryClasses.first,
                            titleKey: classKey,
                            values: state.primaryClasses,
                          ),
                          context: context,
                        );
                      }
                    }
                  },
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
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
                            _selectedClassSection?.fullName ?? 'Pilih Kelas',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: BlocBuilder<ClassesCubit, ClassesState>(
        builder: (context, state) {
          if (state is ClassesFetchSuccess) {
            if (state.primaryClasses.isEmpty) {
              return const SizedBox.shrink();
            }
            return Stack(children: [
              _buildStudentsContainer(),
              _buildSubmitButton(),
            ]);
          }
          if (state is ClassesFetchFailure) {
            return Center(
                child: CustomErrorWidget(
              message: state.errorMessage,
              onRetry: () {
                context.read<ClassesCubit>().getClasses();
              },
              primaryColor: _maroonPrimary,
            ));
          }
          return const Center(child: SkeletonAttendanceList(itemCount: 8));
        },
      ),
    );
  }
}

class SnackBarUtils {
  static void showSnackBar({
    required BuildContext context,
    required String message,
    Color backgroundColor = Colors.black87, // Default color
    Color textColor = Colors.white, // Default text color
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor),
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class CustomSuccessMessage {
  static void show({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    Color backgroundColor = Colors.green,
    Color textColor = Colors.white,
    VoidCallback? onDismiss,
  }) {
    // Add haptic feedback for better UX
    HapticFeedback.mediumImpact();

    // Create overlay entry
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 30,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: textColor, size: 24),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Add to overlay
    overlayState.insert(overlayEntry);

    // Remove after duration
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
        if (onDismiss != null) {
          onDismiss();
        }
      }
    });
  }
}

