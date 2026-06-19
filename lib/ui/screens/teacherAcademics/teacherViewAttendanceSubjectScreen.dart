import 'dart:async';
import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/cubits/student/studentsByClassSectionCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/attendence/attendanceSubjectCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/classSectionsAndSubjects.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/teacherMyTimetableCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/academic/timeTableSlot.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/attendanceStatCard.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/attendanceStatusFilterButton.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/holidayAttendanceContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/student/studentSubjectAttendanceContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:eschool_saas_staff/data/models/academic/studyMaterial.dart';
import 'package:url_launcher/url_launcher.dart';


class TeacherViewAttendanceSubjectScreen extends StatefulWidget {
  static Widget getRouteInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SubjectAttendanceCubit(),
        ),
        BlocProvider(create: (context) => StudentsByClassSectionCubit()),
        BlocProvider(
          create: (context) => ClassesCubit(),
        ),
        BlocProvider(create: (context) => TeacherMyTimetableCubit()),
        BlocProvider(
          create: (context) => ClassSectionsAndSubjectsCubit(),
        ),
      ],
      child: const TeacherViewAttendanceSubjectScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  const TeacherViewAttendanceSubjectScreen({
    super.key,
  });

  @override
  State<TeacherViewAttendanceSubjectScreen> createState() =>
      _TeacherViewAttendanceSubjectScreenState();
}

class _TeacherViewAttendanceSubjectScreenState
    extends State<TeacherViewAttendanceSubjectScreen>
    with TickerProviderStateMixin {
  bool? isPresentStatusOnly;
  DateTime _selectedDateTime = DateTime.now();
  ClassSection? _selectedClassSection;
  StudentAttendanceStatus? selectedStatus;
  int _selectedTimetableId = 0;

  final TextEditingController _materiController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Color scheme for maroon theme
  final Color _maroonPrimary = const Color(0xFF800020);
  final Color _maroonLight = const Color(0xFFAA6976);

  // Animation controllers
  late AnimationController _fabAnimationController;

  List<ClassSection> allClasses = [];
  StreamSubscription? _classSub;

  @override
  void dispose() {
    _classSub?.cancel();
    _scrollController.removeListener(scrollListener);
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _materiController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedDateTime = DateTime.now();

    // Initialize animation controllers
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Add scroll listener
    _scrollController.addListener(scrollListener);

    Future.delayed(Duration.zero, () {
      if (mounted) {
        // Load timetable
        context.read<TeacherMyTimetableCubit>().getTeacherMyTimetable();
        context
            .read<ClassSectionsAndSubjectsCubit>()
            .getClassSectionsAndSubjects();

        // Get classes and automatically select the first class
        context.read<ClassesCubit>().getClasses();

        // Add a listener to react to state changes
        _classSub = context.read<ClassesCubit>().stream.listen((classState) {
          if (mounted && classState is ClassesFetchSuccess) {
            // Get all available classes
            final allAvailableClasses =
                context.read<ClassesCubit>().getAllClasses();

            if (allAvailableClasses.isNotEmpty) {
              setState(() {
                // Use the first class from all available classes
                _selectedClassSection = allAvailableClasses.first;
              });
              // Load attendance data for the automatically selected class
              getAttendance();
            }
          }
        });
      }
    });

    // Fetch initial data
    getClasses();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<ClassesCubit>().getClasses();
    context.read<TeacherMyTimetableCubit>().getTeacherMyTimetable();
  }

  void scrollListener() {
    // Animate elements based on scroll
    if (_scrollController.offset > 50) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  void changeTimetableSlotSelection(int? newSelectedTimetableId) {
    debugPrint('Changing timetable selection to ID: $newSelectedTimetableId');

    setState(() {
      _selectedTimetableId = newSelectedTimetableId ?? 0;
    });

    // Add delay to ensure state is updated
    Future.microtask(() {
      if (_selectedTimetableId != 0) {
        debugPrint(
            'Fetching attendance for timetable ID: $_selectedTimetableId');
        getAttendance();
      }
    });
  }

  String formatTime(String time) {
    // if (time == null) return '';
    return time.substring(0, 5).replaceAll(':', '.');
  }

  String? _getDayInIndonesian(String? day) {
    if (day == null) return null;

    // Map of English day names to Indonesian day names
    final Map<String, String> dayMapping = {
      'Monday': 'Senin',
      'Tuesday': 'Selasa',
      'Wednesday': 'Rabu',
      'Thursday': 'Kamis',
      'Friday': 'Jumat',
      'Saturday': 'Sabtu',
      'Sunday': 'Minggu',
    };

    return dayMapping[day] ??
        day; // Return the Indonesian name or the original if not found
  }

  void getAttendance({StudentAttendanceStatus? selectedStatus}) {
    debugPrint("Getting attendance for:");
    debugPrint("Date: $_selectedDateTime");
    debugPrint(
        "Class: ${_selectedClassSection?.name} (${_selectedClassSection?.id})");
    debugPrint("Timetable ID: $_selectedTimetableId");

    if (_selectedClassSection == null) {
      final classState = context.read<ClassesCubit>().state;
      if (classState is ClassesFetchSuccess &&
          classState.primaryClasses.isNotEmpty) {
        _selectedClassSection = classState.primaryClasses.first;
        debugPrint("Using primary class: ${_selectedClassSection?.name}");
      } else {
        debugPrint("No class section selected!");
        return;
      }
    }

    // Get available slots for selected class and date
    final timetableState = context.read<TeacherMyTimetableCubit>().state;
    if (timetableState is TeacherMyTimetableFetchSuccess) {
      final slots = timetableState.timeTableSlots
          .where((slot) =>
              slot.day == weekDays[_selectedDateTime.weekday - 1] &&
              slot.classSectionId == _selectedClassSection?.id)
          .toList();

      debugPrint(
          "Available slots for selected class and date: ${slots.length}");
      for (var slot in slots) {
        debugPrint(
            "Slot: ${slot.id} - ${slot.subject?.name} - ${slot.startTime}-${slot.endTime}");
      }

      // Update selected timetable id if needed
      if (_selectedTimetableId == 0 && slots.isNotEmpty) {
        _selectedTimetableId = slots.first.id!;
        debugPrint("Updated timetable ID to: $_selectedTimetableId");
      }
    }

    if (_selectedClassSection != null) {
      debugPrint("Fetching attendance with params:");
      debugPrint(
          "- Date: ${DateFormat('yyyy-MM-dd').format(_selectedDateTime)}");
      debugPrint("- Class Section ID: ${_selectedClassSection!.id}");
      debugPrint("- Timetable ID: $_selectedTimetableId");

      context.read<SubjectAttendanceCubit>().fetchSubjectAttendance(
            date: _selectedDateTime,
            classSectionId: _selectedClassSection!.id!,
            timetableId:
                _selectedTimetableId == 0 ? null : _selectedTimetableId,
            gradeLevelId: _selectedClassSection!.classId!,
          );
    }
  }

  int getStudentAttendanceStatusValue(StudentAttendanceStatus status) {
    switch (status) {
      case StudentAttendanceStatus.absent:
        return 0;
      case StudentAttendanceStatus.present:
        return 1;
      case StudentAttendanceStatus.sick:
        return 2;
      case StudentAttendanceStatus.permission:
        return 3;
      case StudentAttendanceStatus.alpa:
        return 4;
    }
  }

  Widget _buildStudentsContainer() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 20, bottom: 90),
        child: BlocBuilder<SubjectAttendanceCubit, SubjectAttendanceState>(
          builder: (context, state) {
            if (state is SubjectAttendanceFetchSuccess) {
              if (state.isHoliday) {
                return HolidayAttendanceContainer(
                  holiday: state.holidayDetails,
                );
              }
              final isWeekend = _selectedDateTime.weekday == DateTime.sunday;

              if (state.attendance.isEmpty) {
                // Jika hari Minggu, tampilkan pesan "Tidak ada Kehadiran hari ini"
                if (isWeekend) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.1,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak Ada Kehadiran Hari Ini',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Jika hari biasa, tampilkan pesan "Belum ada Kehadiran"
                return Center(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * 0.2,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.pending_actions_rounded,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum Ada Data Kehadiran',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Apply the status filter to the attendance data
              var filteredAttendance = state.attendance;

              if (selectedStatus != null) {
                // Filter by specific status (sick, permission, alpha)
                filteredAttendance = filteredAttendance.where((student) {
                  switch (selectedStatus) {
                    case StudentAttendanceStatus.sick:
                      return student.isSick();
                    case StudentAttendanceStatus.permission:
                      return student.isPermission();
                    case StudentAttendanceStatus.alpa:
                      return student.isAlpa();
                    default:
                      return true;
                  }
                }).toList();
              } else if (isPresentStatusOnly == false) {
                // For "Tidak Hadir" (absent) filter
                filteredAttendance = filteredAttendance
                    .where((student) => !student.isPresent())
                    .toList();
              } else if (isPresentStatusOnly == true) {
                // For "Hadir" (present) filter
                filteredAttendance = filteredAttendance
                    .where((student) => student.isPresent())
                    .toList();
              }

              if (filteredAttendance.isEmpty) {
                if (selectedStatus == StudentAttendanceStatus.sick) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.2,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.healing_rounded,
                            size: 48,
                            color: Colors.orange[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada siswa yang sakit',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (selectedStatus ==
                    StudentAttendanceStatus.permission) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.2,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.sticky_note_2_rounded,
                            size: 48,
                            color: Colors.blue[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada siswa yang izin',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (selectedStatus == StudentAttendanceStatus.alpa) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.2,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.not_interested_rounded,
                            size: 48,
                            color: Colors.deepPurple[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada siswa yang alpa',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (isPresentStatusOnly == false) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.2,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cancel_rounded,
                            size: 48,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada siswa yang tidak hadir',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.2,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: Colors.green[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            Utils.getTranslatedLabel(noAttendanceYetKey),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
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
                          'Kehadiran Mapel Siswa',
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

                  // Statistics cards
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
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
                        // Summary header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _maroonPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.pie_chart_rounded,
                                size: 18,
                                color: _maroonPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Ringkasan Kehadiran Mapel',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _maroonPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Present and Absent stats
                        Row(
                          children: [
                            Expanded(
                              child: AttendanceStatCard(
                                icon: Icons.check_circle_rounded,
                                title: 'Hadir',
                                count: state.attendance
                                    .where((element) => element.isPresent())
                                    .length,
                                total: state.attendance.length,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AttendanceStatCard(
                                icon: Icons.cancel_rounded,
                                title: 'Tidak Hadir',
                                count: state.attendance
                                    .where((element) => !element.isPresent())
                                    .length,
                                total: state.attendance.length,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Sick, Permission, and Alpa stats
                        Row(
                          children: [
                            Expanded(
                              child: AttendanceStatCard(
                                icon: Icons.healing_rounded,
                                title: 'Sakit',
                                count: state.attendance
                                    .where((element) => element.isSick())
                                    .length,
                                total: state.attendance.length,
                                color: Colors.orange,
                                small: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AttendanceStatCard(
                                icon: Icons.sticky_note_2_rounded,
                                title: 'Izin',
                                count: state.attendance
                                    .where((element) => element.isPermission())
                                    .length,
                                total: state.attendance.length,
                                color: Colors.blue,
                                small: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AttendanceStatCard(
                                icon: Icons.not_interested_rounded,
                                title: 'Alpa',
                                count: state.attendance
                                    .where((element) => element.isAlpa())
                                    .length,
                                total: state.attendance.length,
                                color: Colors.deepPurple,
                                small: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 200.ms)
                      .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad),

                  // Display subject information
                  BlocBuilder<TeacherMyTimetableCubit, TeacherMyTimetableState>(
                    builder: (context, timetableState) {
                      if (timetableState is TeacherMyTimetableFetchSuccess) {
                        final selectedSlot = timetableState.timeTableSlots
                            .firstWhere(
                                (slot) => slot.id == _selectedTimetableId,
                                orElse: () => TimeTableSlot());

                        if (selectedSlot.subject != null) {
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Subject header with fancy gradient
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
                                        color: _maroonPrimary.withValues(
                                            alpha: 0.3),
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
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.menu_book_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      )
                                          .animate()
                                          .fadeIn(duration: 300.ms)
                                          .scale(
                                              begin: const Offset(0.8, 0.8),
                                              end: const Offset(1.0, 1.0)),

                                      const SizedBox(width: 16),

                                      // Title text
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Informasi Mata Pelajaran',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            Text(
                                              selectedSlot.subject?.name ?? '-',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.white
                                                    .withValues(alpha: 0.9),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Content area
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Card for time and day
                                      Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                // Time icon with container
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: _maroonPrimary
                                                        .withValues(alpha: 0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.access_time_rounded,
                                                    color: _maroonPrimary,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),

                                                // Time and day details
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Jadwal Pelajaran',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Colors.grey[800],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            _getDayInIndonesian(
                                                                    selectedSlot
                                                                        .day) ??
                                                                '-',
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  _maroonPrimary,
                                                            ),
                                                          ),
                                                          Text(
                                                            ', ',
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontSize: 16,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                          ),
                                                          Text(
                                                            "${formatTime(selectedSlot.startTime ?? '00:00')} - ${formatTime(selectedSlot.endTime ?? '00:00')}",
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: Colors
                                                                  .grey[700],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                          .animate()
                                          .fadeIn(
                                              duration: 600.ms, delay: 100.ms)
                                          .slideY(begin: 0.1, end: 0),

                                      // Materi section with modern design
                                      BlocBuilder<SubjectAttendanceCubit,
                                          SubjectAttendanceState>(
                                        builder: (context, state) {
                                          if (state
                                              is SubjectAttendanceFetchSuccess) {
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 16),
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.grey.shade200,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: _maroonLight
                                                              .withValues(
                                                                  alpha: 0.15),
                                                          shape:
                                                              BoxShape.circle,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: _maroonPrimary
                                                                  .withValues(
                                                                      alpha:
                                                                          0.1),
                                                              blurRadius: 4,
                                                              offset:
                                                                  const Offset(
                                                                      0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Icon(
                                                          Icons
                                                              .auto_stories_rounded,
                                                          color: _maroonPrimary,
                                                          size: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          'Materi Pelajaran',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Colors
                                                                .grey[800],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      border: Border.all(
                                                        color: Colors
                                                            .grey.shade100,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withValues(
                                                                  alpha: 0.02),
                                                          blurRadius: 5,
                                                          offset: const Offset(
                                                              0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      state.materi ?? '-',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 15,
                                                        height: 1.5,
                                                        color: Colors.grey[800],
                                                      ),
                                                    ),
                                                  ),

                                                  // Lampiran section with better visual presentation
                                                  if (state.lampiran != null &&
                                                      state
                                                          .lampiran!.isNotEmpty)
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const SizedBox(
                                                            height: 16),
                                                        Row(
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .amber
                                                                    .withValues(
                                                                        alpha:
                                                                            0.1),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              child: Icon(
                                                                Icons
                                                                    .attachment_rounded,
                                                                color: Colors
                                                                    .amber[700],
                                                                size: 18,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 8),
                                                            Text(
                                                              'Lampiran',
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .grey[800],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 12),
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            border: Border.all(
                                                              color: Colors.grey
                                                                  .shade200,
                                                            ),
                                                          ),
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            child: Material(
                                                              color: Colors
                                                                  .transparent,
                                                              child: InkWell(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                onTap: () =>
                                                                    _showAttachmentDialog(
                                                                        context,
                                                                        state
                                                                            .lampiran!),
                                                                child: Row(
                                                                  children: [
                                                                    // Thumbnail preview

                                                                    // File information
                                                                    Expanded(
                                                                      child:
                                                                          Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            12.0),
                                                                        child:
                                                                            Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Text(
                                                                              'Lampiran Materi',
                                                                              style: GoogleFonts.poppins(
                                                                                fontSize: 14,
                                                                                fontWeight: FontWeight.w600,
                                                                                color: Colors.grey[800],
                                                                              ),
                                                                            ),
                                                                            const SizedBox(height: 4),
                                                                            Text(
                                                                              'Klik untuk melihat lampiran',
                                                                              style: GoogleFonts.poppins(
                                                                                fontSize: 12,
                                                                                color: Colors.grey[600],
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),

                                                                    // View button
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                          .all(
                                                                          8.0),
                                                                      child:
                                                                          Container(
                                                                        padding: const EdgeInsets
                                                                            .symmetric(
                                                                            horizontal:
                                                                                12,
                                                                            vertical:
                                                                                8),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color:
                                                                              _maroonPrimary,
                                                                          borderRadius:
                                                                              BorderRadius.circular(8),
                                                                        ),
                                                                        child:
                                                                            Text(
                                                                          'Lihat',
                                                                          style:
                                                                              GoogleFonts.poppins(
                                                                            fontSize:
                                                                                12,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                            color:
                                                                                Colors.white,
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
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            )
                                                .animate()
                                                .fadeIn(
                                                    duration: 700.ms,
                                                    delay: 200.ms)
                                                .slideY(begin: 0.1, end: 0);
                                          }
                                          return const SizedBox();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 500.ms, delay: 300.ms);
                        }
                      }

                      return const SizedBox();
                    },
                  ),

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

                              // Filter badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.filter_list_rounded,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      selectedStatus == null
                                          ? isPresentStatusOnly == false
                                              ? 'Tidak Hadir'
                                              : isPresentStatusOnly == true
                                                  ? 'Hadir'
                                                  : 'Semua'
                                          : selectedStatus ==
                                                  StudentAttendanceStatus.sick
                                              ? 'Sakit'
                                              : selectedStatus ==
                                                      StudentAttendanceStatus
                                                          .permission
                                                  ? 'Izin'
                                                  : 'Alpa',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
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
                              horizontal: 8, vertical: 8),
                          child: StudentSubjectAttendanceContainer(
                            studentAttendances: filteredAttendance,
                            isForAddAttendance: false,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 300.ms)
                      .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad),
                ],
              );
            } else if (state is SubjectAttendanceFetchFailure) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * 0.2),
                  child: CustomErrorWidget(
                    message: ErrorMessageUtils.getReadableErrorMessage(
                        state.errorMessage),
                    onRetry: () {
                      getAttendance();
                    },
                    primaryColor: _maroonPrimary,
                  ),
                ),
              );
            } else {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: SkeletonSubjectAttendanceScreen(itemCount: 4),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppbarAndFilters() {
    return CustomModernAppBar(
      title: 'Lihat Kehadiran Mapel',
      icon: Icons.menu_book_rounded,
      fabAnimationController: _fabAnimationController,
      primaryColor: _maroonPrimary,
      lightColor: _maroonLight,
      height: 200, // Increased height to accommodate filter tabs
      tabBuilder: (context) => _buildFilterTabs(),
      onBackPressed: () => Navigator.of(context).pop(),
    );
  }

  Widget _buildFilterTabs() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Filters Row (Class and Date)
        SizedBox(
          height: 50,
          child: Row(
            children: [
              // Class filter
              Expanded(
                child: BlocBuilder<ClassesCubit, ClassesState>(
                  builder: (context, state) {
                    if (state is ClassesFetchSuccess) {
                      final allAvailableClasses =
                          context.read<ClassesCubit>().getAllClasses();

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (allAvailableClasses.isNotEmpty) {
                              Utils.showBottomSheet(
                                child: FilterSelectionBottomsheet<ClassSection>(
                                  onSelection: (value) {
                                    Get.back();
                                    if (_selectedClassSection != value) {
                                      setState(() {
                                        _selectedClassSection = value;
                                      });
                                      getAttendance();
                                    }
                                  },
                                  selectedValue: _selectedClassSection ??
                                      allAvailableClasses.first,
                                  titleKey: classKey,
                                  values: allAvailableClasses,
                                ),
                                context: context,
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
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
                                    _selectedClassSection?.fullName ??
                                        'Pilih Kelas',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return Center(
                      child: Text(
                        'Loading...',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 8),

              // Date filter
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final selectedDate = await Utils.openDatePicker(
                        context: context,
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
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
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
                                fontSize: 12,
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
          ),
        ),

        const SizedBox(height: 8),

        // Status Filters Row
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              AttendanceStatusFilterButton(
                icon: Icons.all_inclusive_rounded,
                label: "Semua",
                isSelected:
                    isPresentStatusOnly == null && selectedStatus == null,
                onTap: () {
                  setState(() {
                    isPresentStatusOnly = null;
                    selectedStatus = null;
                  });
                  getAttendance();
                },
              ),
              AttendanceStatusFilterButton(
                icon: Icons.check_circle_rounded,
                label: "Hadir",
                isSelected: isPresentStatusOnly == true,
                color: Colors.green,
                onTap: () {
                  setState(() {
                    isPresentStatusOnly = true;
                    selectedStatus = null;
                  });
                  getAttendance();
                },
              ),
              AttendanceStatusFilterButton(
                icon: Icons.remove_circle_rounded,
                label: "Tidak Hadir",
                isSelected: isPresentStatusOnly == false,
                color: Colors.red,
                onTap: () {
                  setState(() {
                    isPresentStatusOnly = false;
                    selectedStatus = null;
                  });
                  getAttendance();
                },
              ),
              AttendanceStatusFilterButton(
                icon: Icons.healing_rounded,
                label: "Sakit",
                isSelected: selectedStatus == StudentAttendanceStatus.sick,
                color: Colors.orange,
                onTap: () {
                  setState(() {
                    selectedStatus = StudentAttendanceStatus.sick;
                    isPresentStatusOnly = null;
                  });
                  getAttendance(selectedStatus: StudentAttendanceStatus.sick);
                },
              ),
              AttendanceStatusFilterButton(
                icon: Icons.sticky_note_2_rounded,
                label: "Izin",
                isSelected:
                    selectedStatus == StudentAttendanceStatus.permission,
                color: Colors.blue,
                onTap: () {
                  setState(() {
                    selectedStatus = StudentAttendanceStatus.permission;
                    isPresentStatusOnly = null;
                  });
                  getAttendance(
                      selectedStatus: StudentAttendanceStatus.permission);
                },
              ),
              AttendanceStatusFilterButton(
                icon: Icons.not_interested_rounded,
                label: "Alpa",
                isSelected: selectedStatus == StudentAttendanceStatus.alpa,
                color: Colors.deepPurple,
                onTap: () {
                  setState(() {
                    selectedStatus = StudentAttendanceStatus.alpa;
                    isPresentStatusOnly = null;
                  });
                  getAttendance(selectedStatus: StudentAttendanceStatus.alpa);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbarAndFilters(),
      body: BlocBuilder<ClassesCubit, ClassesState>(
        builder: (context, state) {
          if (state is ClassesFetchSuccess) {
            debugPrint("ClassesFetchSuccess: ${state.primaryClasses}");
            return _buildStudentsContainer();
          }
          if (state is ClassesFetchFailure) {
            debugPrint("ClassesFetchFailure: ${state.errorMessage}");
            // return Center(
            //     child: ErrorContainer(
            //   errorMessage: state.errorMessage,
            //   onTapRetry: () {
            //     context.read<ClassesCubit>().getClasses();
            //   },
            // ));
          }
          return const Center(
              child: SkeletonSubjectAttendanceScreen(itemCount: 6));
        },
      ),
    );
  }

  String? getClassSectionName(int? classSectionId) {
    if (classSectionId == null) return null;

    return allClasses
        .firstWhere((element) => element.id == classSectionId,
            orElse: () => ClassSection())
        .fullName;
  }

  void getClasses() async {
    try {
      final classState = context.read<ClassesCubit>().state;

      if (classState is ClassesFetchSuccess) {
        // Get all available classes from the system
        final allAvailableClasses =
            context.read<ClassesCubit>().getAllClasses();

        debugPrint(
            "All available classes: ${allAvailableClasses.length} classes");

        setState(() {
          // Use all available classes from ClassesCubit instead of just timetable slots
          allClasses = allAvailableClasses;
        });
      }
    } catch (e) {
      debugPrint("Error fetching classes: $e");
    }
  }

  void changeSelectedClassSection(ClassSection? classSection) {
    if (_selectedClassSection != classSection) {
      setState(() {
        _selectedClassSection = classSection;
        _selectedTimetableId = 0;
      });
      getAttendance();
    }
  }

  // Helper method to check if file is an image
  bool _isImageFile(String url) {
    final String extension = url.split('.').last.toLowerCase();
    final List<String> imageExtensions = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp'
    ];
    return imageExtensions.contains(extension);
  }

  void _showAttachmentDialog(BuildContext context, String imageUrl) {
    // Build full URL if it's a relative path
    String fullUrl =
        imageUrl.startsWith('http') ? imageUrl : '$storageUrl$imageUrl';

    // Check if file is an image based on extension
    bool isImage = _isImageFile(fullUrl);

    if (!isImage) {
      // For non-image files (like PDF), open directly in WebView
      _openImageExternally(imageUrl);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.black87,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lampiran',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          // Download button (if needed)
                          IconButton(
                            icon: const Icon(Icons.download_rounded,
                                color: Colors.white),
                            onPressed: () {
                              Utils.viewOrDownloadStudyMaterial(
                                context: context,
                                storeInExternalStorage: true,
                                studyMaterial: StudyMaterial.fromURL(imageUrl),
                              );
                            },

                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Image container with error handling
                Flexible(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      child: InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl: fullUrl,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            filterQuality: FilterQuality.high,
                            fadeInDuration: const Duration(milliseconds: 300),
                            fadeOutDuration: const Duration(milliseconds: 100),
                            placeholder: (context, url) => SizedBox(
                              height: 300,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _maroonPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Memuat gambar...',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              debugPrint('Error loading full image: $error');
                              // Automatically try to open in external app without showing error dialog
                              Future.microtask(() {
                                if (!dialogContext.mounted) return;
                                Navigator.of(dialogContext).pop();
                                _openImageExternally(fullUrl);
                              });

                              // Show a brief loading message while redirecting
                              return SizedBox(
                                height: 300,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          _maroonPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Membuka lampiran di aplikasi...',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            httpHeaders: const {
                              'User-Agent':
                                  'Mozilla/5.0 (compatible; eSchool App)',
                              'Accept':
                                  'image/webp,image/apng,image/*,*/*;q=0.8',
                              'Cache-Control': 'no-cache',
                            },
                          ),
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
  }

  // Helper method to open image in external app
  void _openImageExternally(String imageUrl) async {
    // Build full URL if it's a relative path
    String fullUrl =
        imageUrl.startsWith('http') ? imageUrl : '$storageUrl$imageUrl';

    // For PDF files, use Google Docs viewer to display in WebView
    if (fullUrl.toLowerCase().endsWith('.pdf')) {
      final googleDocsUrl =
          'https://docs.google.com/viewer?url=${Uri.encodeComponent(fullUrl)}&embedded=true';

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return Dialog(
            backgroundColor: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_maroonPrimary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat PDF...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mohon tunggu sebentar',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      try {
        final Uri url = Uri.parse(googleDocsUrl);
        if (await canLaunchUrl(url)) {
          // Close loading dialog and launch URL
          // Close loading dialog and launch URL
          if (mounted) {
            Navigator.of(context).pop();
            await launchUrl(url, mode: LaunchMode.inAppWebView);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('PDF berhasil dibuka'),
                  backgroundColor: _maroonPrimary,
                ),
              );
            }
          }
          return;
        }
      } catch (e) {
        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }
        debugPrint('Error opening PDF with Google Docs: $e');
      }
    }

    try {
      // Try to launch URL directly
      final Uri url = Uri.parse(fullUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.inAppWebView);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Lampiran berhasil dibuka'),
              backgroundColor: _maroonPrimary,
            ),
          );
        }
      } else {
        // Fallback: copy URL to clipboard
        await Clipboard.setData(ClipboardData(text: fullUrl));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('URL lampiran disalin ke clipboard'),
              backgroundColor: _maroonPrimary,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening image externally: $e');
      // Fallback: copy URL to clipboard
      try {
        await Clipboard.setData(ClipboardData(text: fullUrl));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('URL lampiran disalin ke clipboard'),
              backgroundColor: _maroonPrimary,
            ),
          );
        }
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka lampiran'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
