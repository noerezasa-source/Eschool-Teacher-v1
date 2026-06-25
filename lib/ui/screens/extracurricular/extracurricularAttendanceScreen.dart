import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:eschool_saas_staff/cubits/extracurricularAttendance/extracurricularAttendanceCubit.dart';
import 'package:eschool_saas_staff/cubits/extracurricularAttendance/extracurricularAttendanceState.dart';
import 'package:eschool_saas_staff/data/repositories/extracurricular/extracurricularAttendanceRepository.dart';
import 'package:eschool_saas_staff/data/models/extracurricular/extracurricularAttendance.dart';
import 'package:eschool_saas_staff/data/models/student/studentAttendance.dart';
import 'package:eschool_saas_staff/data/models/student/studentDetails.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/errorContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/student/studentAttendanceContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:eschool_saas_staff/utils/system/dateFormatter.dart';

class ExtracurricularAttendanceScreen extends StatefulWidget {
  const ExtracurricularAttendanceScreen({super.key});

  static Widget getRouteInstance() {
    return BlocProvider(
      create: (context) => ExtracurricularAttendanceCubit(
        ExtracurricularAttendanceRepository(),
      ),
      child: const ExtracurricularAttendanceScreen(),
    );
  }

  @override
  State<ExtracurricularAttendanceScreen> createState() =>
      _ExtracurricularAttendanceScreenState();
}

class _ExtracurricularAttendanceScreenState
    extends State<ExtracurricularAttendanceScreen>
    with TickerProviderStateMixin {
  // Controllers and variables
  DateTime _selectedDate = DateTime.now();
  int? _selectedExtracurricularId;
  String? _selectedExtracurricularName;
  List<Map<String, dynamic>> _extracurricularList = [];
  List<ExtracurricularAttendance> _attendanceList = [];
  List<({StudentAttendanceStatus status, int studentId})> attendanceReport = [];

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchVisible = false;

  // Animation controllers
  late AnimationController _fabAnimationController;
  late final ScrollController _scrollController = ScrollController();

  // Theme colors
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  Color get _maroonLight => AppColorPalette.secondaryMaroon;

  @override
  void initState() {
    super.initState();

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fabAnimationController.forward();

    // Load extracurricular list
    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<ExtracurricularAttendanceCubit>().getExtracurricularList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  // Format date for API using DateFormatter (DD-MM-YYYY format for all requests)
  String _formatDateForApi(DateTime date) {
    return DateFormatter.toApiFormat(date);
  }

  // Load attendance data
  void _loadAttendanceData() {
    if (_selectedExtracurricularId != null) {
      // Use extracurricular ID as attendance ID for now
      // This might need adjustment based on actual backend implementation
      context.read<ExtracurricularAttendanceCubit>().getAttendanceData(
            attendanceId: _selectedExtracurricularId!,
            extracurricularId: _selectedExtracurricularId,
            date: _formatDateForApi(_selectedDate), // Use DD-MM-YYYY format
          );
    }
  }

  // Save attendance data with validation
  void _saveAttendance() {
    if (_selectedExtracurricularId == null) {
      debugPrint('❌ [ATTENDANCE SCREEN] Cannot save: No extracurricular selected');
      _showErrorSnackbar('Pilih ekstrakurikuler terlebih dahulu');
      return;
    }

    if (attendanceReport.isEmpty) {
      debugPrint('❌ [ATTENDANCE SCREEN] Cannot save: No attendance data');
      _showErrorSnackbar('Tidak ada data absensi untuk disimpan');
      return;
    }

    debugPrint('🔍 [ATTENDANCE SCREEN] Preparing to save attendance...');
    debugPrint(
        '🔍 [ATTENDANCE SCREEN] Attendance report count: ${attendanceReport.length}');
    debugPrint(
        '🔍 [ATTENDANCE SCREEN] Selected date: ${_formatDateForApi(_selectedDate)}');

    // Validate date format
    final dateString = _formatDateForApi(_selectedDate);
    if (!DateFormatter.isValidGetRequestDateFormat(dateString)) {
      debugPrint('❌ [ATTENDANCE SCREEN] Invalid date format: $dateString');
      _showErrorSnackbar('Format tanggal tidak valid');
      return;
    }

    // Convert attendance report to API format with validation
    final List<AttendanceData> attendanceData = [];
    bool hasInvalidData = false;

    for (final report in attendanceReport) {
      debugPrint(
          '🔍 [ATTENDANCE SCREEN] Processing report: StudentID=${report.studentId}, Status=${report.status}');

      // Validate student ID
      if (report.studentId <= 0) {
        debugPrint('❌ [ATTENDANCE SCREEN] Invalid student ID: ${report.studentId}');
        hasInvalidData = true;
        continue;
      }

      try {
        final data = AttendanceData.create(
          studentId: report.studentId,
          type: _convertStatusToInt(report.status),
        );

        if (data.isValid()) {
          attendanceData.add(data);
          debugPrint(
              '✅ [ATTENDANCE SCREEN] Added valid attendance data: ${data.toString()}');
        } else {
          debugPrint(
              '❌ [ATTENDANCE SCREEN] Invalid attendance data: ${data.toString()}');
          hasInvalidData = true;
        }
      } catch (e) {
        debugPrint('❌ [ATTENDANCE SCREEN] Error creating attendance data: $e');
        hasInvalidData = true;
      }
    }

    if (hasInvalidData) {
      _showErrorSnackbar(
          'Beberapa data absensi tidak valid. Periksa data siswa.');
      return;
    }

    if (attendanceData.isEmpty) {
      debugPrint('❌ [ATTENDANCE SCREEN] No valid attendance data to save');
      _showErrorSnackbar('Tidak ada data absensi yang valid untuk disimpan');
      return;
    }

    debugPrint(
        '🔍 [ATTENDANCE SCREEN] Final attendance data (${attendanceData.length} items):');
    for (final data in attendanceData) {
      debugPrint('  - ${data.toString()}');
    }

    // Send to API
    context.read<ExtracurricularAttendanceCubit>().saveAttendance(
          sessionId: 1, // This should be actual session/staff ID
          extracurricularId: _selectedExtracurricularId!,
          date: dateString,
          attendanceData: attendanceData,
        );
  }

  // Show error snackbar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Convert StudentAttendanceStatus to int
  int _convertStatusToInt(StudentAttendanceStatus status) {
    switch (status) {
      case StudentAttendanceStatus.present:
        return 1;
      case StudentAttendanceStatus.absent:
        return 0;
      case StudentAttendanceStatus.sick:
        return 2;
      case StudentAttendanceStatus.permission:
        return 3;
      case StudentAttendanceStatus.alpa:
        return 0; // Alpa sama dengan absent
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: CustomModernAppBar(
        title: 'Absensi Kurikuler',
        icon: Icons.edit_calendar_rounded,
        fabAnimationController: _fabAnimationController,
        primaryColor: _maroonPrimary,
        lightColor: _maroonLight,
        onBackPressed: () {
          _fabAnimationController.stop();
          Get.back();
        },
        height: 160,
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
                    hintText: 'Cari nama anggota...',
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
                        inititalDate: _selectedDate,
                        lastDate: DateTime.now(),
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 30)),
                      );

                      if (selectedDate != null) {
                        setState(() {
                          _selectedDate = selectedDate;
                        });
                        _loadAttendanceData();
                      }
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              Utils.formatDate(_selectedDate),
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

              // Divider
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

              // Extracurricular selection
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showExtracurricularPicker(),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.sports_soccer,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _selectedExtracurricularName ??
                                  'Pilih Ekstrakurikuler',
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
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ExtracurricularAttendanceCubit,
                ExtracurricularAttendanceState>(
              listener: (context, state) {
                debugPrint(
                    '🔍 [ATTENDANCE SCREEN] State changed: ${state.runtimeType}');

                if (state is ExtracurricularAttendanceSuccess) {
                  debugPrint('🔍 [ATTENDANCE SCREEN] Success state received');

                  if (state.extracurricularList != null) {
                    debugPrint(
                        '🔍 [ATTENDANCE SCREEN] Extracurricular list received: ${state.extracurricularList!.length} items');
                    debugPrint(
                        '🔍 [ATTENDANCE SCREEN] List content: ${state.extracurricularList}');
                    setState(() {
                      _extracurricularList = state.extracurricularList!;
                    });
                  }
                  if (state.attendanceData != null) {
                    debugPrint(
                        '🔍 [ATTENDANCE SCREEN] Attendance data received: ${state.attendanceData!.members.length} members');

                    // Debug: Print first few members to see their structure
                    for (int i = 0;
                        i < state.attendanceData!.members.length && i < 3;
                        i++) {
                      final member = state.attendanceData!.members[i];
                      debugPrint(
                          '🔍 [ATTENDANCE SCREEN] Member $i: AttendanceID=${member.attendanceId}, StudentID=${member.studentId}, Name=${member.studentName}');
                    }

                    setState(() {
                      _attendanceList = state.attendanceData!.members;
                      _initializeAttendanceReport();
                    });
                  }
                }

                if (state is ExtracurricularAttendanceSaveSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        state.message,
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  // Reload data after save with delay to ensure backend has processed
                  debugPrint(
                      '✅ [ATTENDANCE SCREEN] Save successful, reloading data...');
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _loadAttendanceData();
                  });
                }

                if (state is ExtracurricularAttendanceFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        state.errorMessage,
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ExtracurricularAttendanceLoading) {
                  return _buildLoadingSkeleton();
                }

                if (state is ExtracurricularAttendanceFailure) {
                  return ErrorContainer(
                    errorMessage: state.errorMessage,
                    onTapRetry: () {
                      if (_selectedExtracurricularId != null) {
                        _loadAttendanceData();
                      } else {
                        context
                            .read<ExtracurricularAttendanceCubit>()
                            .getExtracurricularList();
                      }
                    },
                  );
                }

                return _buildAttendanceContent();
              },
            ),
          ),

          // Submit button
          if (_selectedExtracurricularId != null && _attendanceList.isNotEmpty)
            _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildAttendanceContent() {
    if (_selectedExtracurricularId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_soccer,
              size: 80,
              color: _maroonPrimary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              'Pilih Ekstrakurikuler',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Silakan pilih ekstrakurikuler terlebih dahulu',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return _buildStudentsContainer();
  }

  Widget _buildStudentsContainer() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 20, bottom: 90),
        child: Column(
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
                    'Kehadiran Anggota Ekstrakurikuler',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _maroonPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Students attendance container
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
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
                        ),

                        const SizedBox(width: 16),

                        // Title text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daftar Kehadiran Anggota',
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

                  // Student attendance list
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildStudents(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudents() {
    if (_attendanceList.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.people_alt_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada anggota untuk ditampilkan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan pilih ekstrakurikuler dan tanggal',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Convert ExtracurricularAttendance to StudentAttendance format
    final studentAttendances = _attendanceList.map((member) {
      debugPrint(
          '🔍 [ATTENDANCE SCREEN] Converting member: AttendanceID=${member.attendanceId}, StudentID=${member.studentId}, Name=${member.studentName}, Status=${member.status.label}');

      // Create StudentDetails from ExtracurricularAttendance
      final studentDetails = StudentDetails.fromJson({
        'id': member.studentId,
        'full_name': member.studentName,
        'first_name': member.studentName.split(' ').first,
        'last_name': member.studentName.split(' ').skip(1).join(' '),
        'gr_number': member.studentNisn,
        'class_section': {
          'full_name': member.className,
        },
        'student': {
          'user_id': member.studentId, // Ensure this matches studentId
          'id': member.studentId, // Also set id field
          'class_section_id': 1,
          'session_year_id': 1,
        },
      });

      debugPrint(
          '🔍 [ATTENDANCE SCREEN] Created StudentDetails: ID=${studentDetails.id}, UserID=${studentDetails.student?.userId}');

      // Convert backend status to StudentAttendance type
      int studentAttendanceType;
      switch (member.status) {
        case AttendanceStatus.absent:
          studentAttendanceType = 4; // Alpa in StudentAttendance
          break;
        case AttendanceStatus.present:
          studentAttendanceType = 1; // Present
          break;
        case AttendanceStatus.sick:
          studentAttendanceType = 2; // Sick
          break;
        case AttendanceStatus.permission:
          studentAttendanceType = 3; // Permission
          break;
      }

      final studentAttendance = StudentAttendance.fromStudentDetails(
        studentDetails: studentDetails,
        type:
            studentAttendanceType, // Use converted type for proper status detection
      );

      debugPrint(
          '🔍 [ATTENDANCE SCREEN] Created StudentAttendance: ID=${studentAttendance.studentDetails?.id}, Type=${studentAttendance.type}, Status=${member.status.label}');
      debugPrint(
          '🔍 [ATTENDANCE SCREEN] Status check - isPresent: ${studentAttendance.isPresent()}, isAbsent: ${studentAttendance.isAbsent()}, isSick: ${studentAttendance.isSick()}, isPermission: ${studentAttendance.isPermission()}, isAlpa: ${studentAttendance.isAlpa()}');

      return studentAttendance;
    }).toList();

    // Filter students based on search query
    final filteredStudents = _searchQuery.isEmpty
        ? studentAttendances
        : studentAttendances.where((attendance) {
            final fullName =
                (attendance.studentDetails?.fullName ?? '').toLowerCase();
            return fullName.contains(_searchQuery.toLowerCase());
          }).toList();

    return StudentAttendanceContainer(
      studentAttendances: filteredStudents,
      allStudentAttendances: studentAttendances,
      onStatusChanged: (attendanceStatuses) {
        debugPrint(
            '🔍 [ATTENDANCE SCREEN] Status changed callback received ${attendanceStatuses.length} items:');
        for (int i = 0; i < attendanceStatuses.length; i++) {
          final item = attendanceStatuses[i];
          debugPrint(
              '  - Index $i: StudentID=${item.studentId}, Status=${item.status}');
        }
        attendanceReport = attendanceStatuses;
      },
      isForAddAttendance: true,
      showSummary: true,
    );
  }

  void _initializeAttendanceReport() {
    // Initialize attendance report with current data
    attendanceReport = _attendanceList.map((member) {
      final convertedStatus =
          _convertAttendanceStatusToStudentStatus(member.status);
      debugPrint(
          '🔍 [ATTENDANCE SCREEN] Initializing report for student ID: ${member.studentId}, Original Status: ${member.status.label} (${member.status.value}), Converted: $convertedStatus');

      return (
        status: convertedStatus,
        studentId: member.studentId,
      );
    }).toList();

    debugPrint(
        '🔍 [ATTENDANCE SCREEN] Initialized ${attendanceReport.length} attendance reports');

    // Debug: Print all attendance reports
    for (int i = 0; i < attendanceReport.length; i++) {
      final report = attendanceReport[i];
      debugPrint(
          '🔍 [ATTENDANCE SCREEN] Report $i: StudentID=${report.studentId}, Status=${report.status}');
    }
  }

  // Convert AttendanceStatus to StudentAttendanceStatus
  StudentAttendanceStatus _convertAttendanceStatusToStudentStatus(
      AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.absent:
        return StudentAttendanceStatus.alpa; // Fix: absent should map to alpa
      case AttendanceStatus.present:
        return StudentAttendanceStatus.present;
      case AttendanceStatus.sick:
        return StudentAttendanceStatus.sick;
      case AttendanceStatus.permission:
        return StudentAttendanceStatus.permission;
    }
  }

  void _showExtracurricularPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Pilih Ekstrakurikuler',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _maroonPrimary,
                ),
              ),
            ),
            Expanded(
              child: _extracurricularList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada ekstrakurikuler',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Belum ada data ekstrakurikuler yang tersedia',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Retry loading
                              context
                                  .read<ExtracurricularAttendanceCubit>()
                                  .getExtracurricularList();
                            },
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _extracurricularList.length,
                      itemBuilder: (context, index) {
                        final extracurricular = _extracurricularList[index];
                        return ListTile(
                          leading:
                              Icon(Icons.sports_soccer, color: _maroonPrimary),
                          title: Text(
                            extracurricular['name'],
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            extracurricular['description'] ?? '',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedExtracurricularId =
                                  extracurricular['id'];
                              _selectedExtracurricularName =
                                  extracurricular['name'];
                            });
                            Navigator.pop(context);
                            _loadAttendanceData();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BlocBuilder<ExtracurricularAttendanceCubit,
          ExtracurricularAttendanceState>(
        builder: (context, state) {
          final isLoading = state is ExtracurricularAttendanceSaveLoading;

          return ElevatedButton(
            onPressed: isLoading ? null : _saveAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: _maroonPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Simpan Absensi',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Center(
      child: CircularProgressIndicator(
        color: _maroonPrimary,
      ),
    );
  }
}

