import 'dart:async';
import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/attendence/attendanceCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherViewAttendanceScreen extends StatefulWidget {
  static Widget getRouteInstance() {
    //final arguments = Get.arguments as Map<String,dynamic>;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AttendanceCubit(),
        ),
        BlocProvider(
          create: (context) => ClassesCubit(),
        ),
      ],
      child: const TeacherViewAttendanceScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  const TeacherViewAttendanceScreen({super.key});

  @override
  State<TeacherViewAttendanceScreen> createState() =>
      _TeacherViewAttendanceScreenState();
}

class _TeacherViewAttendanceScreenState
    extends State<TeacherViewAttendanceScreen> with TickerProviderStateMixin {
  bool? isPresentStatusOnly;
  DateTime _selectedDateTime = DateTime.now();
  ClassSection? _selectedClassSection;
  StudentAttendanceStatus? selectedStatus;

  // Color scheme for maroon theme
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  Color get _maroonLight => AppColorPalette.secondaryMaroon;

  // Animation controllers
  late AnimationController _fabAnimationController;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _classSub;

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
        // Get classes and automatically select the first class
        context.read<ClassesCubit>().getClasses();

        // Add a listener to react to state changes
        _classSub = context.read<ClassesCubit>().stream.listen((classState) {
          if (mounted &&
              classState is ClassesFetchSuccess &&
              classState.primaryClasses.isNotEmpty) {
            setState(() {
              _selectedClassSection = classState.primaryClasses.first;
            });
            // Load attendance data for the automatically selected class
            getAttendance();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _classSub?.cancel();
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

  void getAttendance({StudentAttendanceStatus? selectedStatus}) {
    debugPrint('Getting attendance with:');
    debugPrint('Date: $_selectedDateTime');
    debugPrint('ClassSectionId: ${_selectedClassSection?.id}');
    debugPrint('Selected Status: $selectedStatus');

    // Tentukan type berdasarkan status
    int? attendanceType;

    if (selectedStatus != null) {
      // Mapping sesuai dengan enum yang sudah ada
      switch (selectedStatus) {
        case StudentAttendanceStatus.absent:
          attendanceType = 0;
          break;
        case StudentAttendanceStatus.present:
          attendanceType = 1;
          break;
        case StudentAttendanceStatus.sick:
          attendanceType = 2;
          break;
        case StudentAttendanceStatus.permission:
          attendanceType = 3;
          break;
        case StudentAttendanceStatus.alpa:
          attendanceType = 4;
          break;
      }
      debugPrint('Mapped attendanceType: $attendanceType');
    } else if (isPresentStatusOnly != null) {
      // Jika menggunakan isPresentStatusOnly
      attendanceType = isPresentStatusOnly! ? 1 : 0;
    }

    if (_selectedClassSection?.id == null) {
      debugPrint('Error: ClassSectionId is null');
      return;
    }

    context.read<AttendanceCubit>().fetchAttendance(
          date: _selectedDateTime,
          classSectionId: _selectedClassSection?.id ?? 0,
          type: attendanceType,
        );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required int count,
    required int total,
    required Color color,
    bool small = false,
  }) {
    final percentage =
        total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: small ? 10 : 16,
        horizontal: small ? 8 : 16,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: small ? 14 : 18,
                ),
              ),
              Text(
                '$percentage%',
                style: GoogleFonts.poppins(
                  fontSize: small ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: small ? 6 : 10),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: small ? 11 : 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count/$total',
            style: GoogleFonts.poppins(
              fontSize: small ? 14 : 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
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
              final isWeekend = _selectedDateTime.weekday == DateTime.sunday;

              if (state.attendance.isEmpty) {
                // Jika hari Minggu, tampilkan pesan "Tidak ada Kehadiran hari ini"
                if (isWeekend) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.2,
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
                              'Ringkasan Kehadiran',
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
                              child: _buildStatCard(
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
                              child: _buildStatCard(
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
                              child: _buildStatCard(
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
                              child: _buildStatCard(
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
                              child: _buildStatCard(
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
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 300.ms)
                                  .slideX(begin: -0.2, end: 0),

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
                          child: StudentAttendanceContainer(
                            studentAttendances: state.attendance,
                            isForAddAttendance: false,
                            showSummary:
                                false, // Hide the summary in this screen
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

  Widget _buildAppbarAndFilters() {
    return CustomModernAppBar(
      title: 'Lihat Kehadiran',
      icon: Icons.people_outline_rounded,
      fabAnimationController: _fabAnimationController,
      primaryColor: _maroonPrimary,
      lightColor: _maroonLight,
      height: 210, // Increased height to accommodate filters
      onBackPressed: () => Navigator.of(context).pop(),
      onFilterPressed: () {
        // Show filter options
        _showStatusFilterDialog();
      },
      tabBuilder: (context) {
        return Column(
          children: [
            // First row: Class and Date filters
            SizedBox(
              height: 50,
              child: Row(
                children: [
                  // Class filter
                  Expanded(
                    child: BlocBuilder<ClassesCubit, ClassesState>(
                      builder: (context, state) {
                        if (state is ClassesFetchSuccess) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (state.primaryClasses.isNotEmpty) {
                                  Utils.showBottomSheet(
                                    child: FilterSelectionBottomsheet<
                                        ClassSection>(
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
                                          state.primaryClasses.first,
                                      titleKey: classKey,
                                      values: state.primaryClasses,
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
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 30)),
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

            // Second row: Status filters
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Semua filter
                  _buildCompactStatusFilterButton(
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

                  // Hadir filter
                  _buildCompactStatusFilterButton(
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

                  // Tidak Hadir filter
                  _buildCompactStatusFilterButton(
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

                  // Sakit filter
                  _buildCompactStatusFilterButton(
                    icon: Icons.healing_rounded,
                    label: "Sakit",
                    isSelected: selectedStatus == StudentAttendanceStatus.sick,
                    color: Colors.orange,
                    onTap: () {
                      setState(() {
                        selectedStatus = StudentAttendanceStatus.sick;
                        isPresentStatusOnly = null;
                      });
                      getAttendance(
                          selectedStatus: StudentAttendanceStatus.sick);
                    },
                  ),

                  // Izin filter
                  _buildCompactStatusFilterButton(
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

                  // Alpha filter
                  _buildCompactStatusFilterButton(
                    icon: Icons.not_interested_rounded,
                    label: "Alpa",
                    isSelected: selectedStatus == StudentAttendanceStatus.alpa,
                    color: Colors.deepPurple,
                    onTap: () {
                      setState(() {
                        selectedStatus = StudentAttendanceStatus.alpa;
                        isPresentStatusOnly = null;
                      });
                      getAttendance(
                          selectedStatus: StudentAttendanceStatus.alpa);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showStatusFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Status Kehadiran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.all_inclusive_rounded),
                title: const Text('Semua'),
                onTap: () {
                  setState(() {
                    isPresentStatusOnly = null;
                    selectedStatus = null;
                  });
                  getAttendance();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.check_circle_rounded, color: Colors.green),
                title: const Text('Hadir'),
                onTap: () {
                  setState(() {
                    isPresentStatusOnly = true;
                    selectedStatus = null;
                  });
                  getAttendance();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.remove_circle_rounded, color: Colors.red),
                title: const Text('Tidak Hadir'),
                onTap: () {
                  setState(() {
                    isPresentStatusOnly = false;
                    selectedStatus = null;
                  });
                  getAttendance();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactStatusFilterButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
              color: isSelected
                  ? color.withValues(alpha: 0.2)
                  : Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? color : Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? color : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(240),
        child: _buildAppbarAndFilters(),
      ),
      body: BlocBuilder<ClassesCubit, ClassesState>(
        builder: (context, state) {
          if (state is ClassesFetchSuccess) {
            return _buildStudentsContainer();
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
          return const Center(
              child: SkeletonSubjectAttendanceScreen(itemCount: 6));
        },
      ),
    );
  }
}
