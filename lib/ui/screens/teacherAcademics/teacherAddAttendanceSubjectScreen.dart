import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/cubits/student/studentsByClassSectionCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/attendence/attendanceSubjectCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/attendence/submitAttendanceSubjectCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/teacherMyTimetableCubit.dart';
import 'package:eschool_saas_staff/data/models/student/attendanceStudent.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/student/studentAttendance.dart';
import 'package:eschool_saas_staff/data/models/academic/timeTableSlot.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/holidayAttendanceContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/errorContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:eschool_saas_staff/ui/widgets/student/studentAttendanceContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:eschool_saas_staff/utils/system/optimized_file_compression_mixin.dart';
import 'package:eschool_saas_staff/utils/system/optimized_file_compression_utils.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eschool_saas_staff/utils/system/snackBarUtils.dart';

class TeacherAddAttendanceSubjectScreen extends StatefulWidget {
  static Widget getRouteInstance() {
    //final arguments = Get.arguments as Map<String,dynamic>;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SubmitAttendanceSubjectCubit(),
        ),
        BlocProvider(
          create: (context) => SubjectAttendanceCubit(),
        ),
        BlocProvider(create: (context) => StudentsByClassSectionCubit()),
        BlocProvider(
          create: (context) => ClassesCubit(),
        ),
        BlocProvider(create: (context) => TeacherMyTimetableCubit()),
      ],
      child: const TeacherAddAttendanceSubjectScreen(),
    );
  }

  static Map<String, dynamic> buildArguments({
    required ClassSection? classSection,
    required TimeTableSlot? timeTableSlot,
  }) {
    return {
      "classSection": classSection,
      "timeTableSlot": timeTableSlot,
    };
  }

  const TeacherAddAttendanceSubjectScreen({super.key});

  @override
  State<TeacherAddAttendanceSubjectScreen> createState() =>
      _TeacherAddAttendanceScreenSubjectState();
}

class _TeacherAddAttendanceScreenSubjectState
    extends State<TeacherAddAttendanceSubjectScreen>
    with TickerProviderStateMixin, OptimizedFileCompressionMixin {
  List<({StudentAttendanceStatus status, int studentId})> attendanceReport = [];

  final TextEditingController _materiController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  int? _selectedGradeLevelId;
  ClassSection? _selectedClassSection;
  int _selectedTimeTableId = 0;
  int _selectedJumlahJp = 0;
  String _selectedMateri = '';
  String? _selectedLampiran;

  TimeTableSlot? _selectedTimeTableSlot;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchVisible = false;

  // Color scheme for maroon theme
  final Color _maroonPrimary = const Color(0xFF800020);
  final Color _maroonLight = const Color(0xFFAA6976);

  // Animation controllers
  late AnimationController _fabAnimationController;
  late final ScrollController _scrollController = ScrollController()
    ..addListener(scrollListener);

  @override
  void dispose() {
    _materiController.dispose();
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

  // Helper method to check if all required data is valid for fetching attendance
  bool _isDataValidForFetch() {
    return _selectedClassSection != null && _selectedClassSection!.id != null;
  }

  // Helper method to get validation message for missing data
  String _getValidationMessage() {
    if (_selectedClassSection == null || _selectedClassSection!.id == null) {
      return "Pilih kelas terlebih dahulu";
    }
    return "";
  }

  @override
  void initState() {
    super.initState();
    _selectedDateTime = DateTime.now();
    _selectedClassSection = null; // Reset selected class section
    _selectedTimeTableId = 0; // Reset selected timetable ID
    _selectedJumlahJp = 0; // Reset jumlah JP
    _selectedMateri = ''; // Reset materi
    _selectedLampiran = null; // Reset lampiran

    // Initialize animation controllers
    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    Future.delayed(Duration.zero, () {
      final arguments = Get.arguments as Map<String, dynamic>?;
      if (arguments != null) {
        _selectedClassSection = arguments['classSection'] as ClassSection?;
        final timeTableSlot = arguments['timeTableSlot'] as TimeTableSlot?;
        if (timeTableSlot != null) {
          _selectedTimeTableId = timeTableSlot.id!;
        }
        _selectedTimeTableSlot = timeTableSlot;
        // Extract grade level from class section if available
        if (_selectedClassSection != null) {
          _selectedGradeLevelId = _selectedClassSection!.gradeLevelId;
        }
      }

      if (!mounted) return;
      context.read<ClassesCubit>().getClasses();
      context.read<TeacherMyTimetableCubit>().getTeacherMyTimetable();

      // Only fetch attendance if we have class section selected
      if (_selectedClassSection != null && _selectedClassSection!.id != null) {
        getAttendance();
        getStudentList();
      }
    }); // Listen to attendance cubit state changes
    context.read<SubjectAttendanceCubit>().stream.listen((state) {
      if (state is SubjectAttendanceFetchSuccess) {
        setState(() {
          _materiController.text = state.materi ?? ''; // Set saved materi
          _selectedMateri = state.materi ?? '';

          // Display previously uploaded lampiran if available
          if (state.lampiran != null && state.lampiran!.isNotEmpty) {
            debugPrint(
                "Loading previously uploaded attachment: ${state.lampiran}");
            _selectedLampiran = state.lampiran;
          }
        });
      }
    });
  }

  void getAttendance() {
    debugPrint("Fetching attendance data for:");
    debugPrint("- Date: $_selectedDateTime");
    debugPrint("- Grade Level ID: $_selectedGradeLevelId");
    debugPrint("- Class Section ID: ${_selectedClassSection?.id}");
    debugPrint("- Timetable ID: $_selectedTimeTableId");

    // Use helper method for validation
    if (!_isDataValidForFetch()) {
      String message = _getValidationMessage();
      if (message.isNotEmpty) {
        Utils.showSnackBar(message: message, context: context);
      }
      return;
    }

    // Set default timetable ID if not set
    int timetableIdToUse = _selectedTimeTableId > 0 ? _selectedTimeTableId : 1;
    int gradeLevelIdToUse =
        _selectedGradeLevelId ?? _selectedClassSection!.gradeLevelId ?? 1;

    context.read<SubjectAttendanceCubit>().fetchSubjectAttendance(
          date: _selectedDateTime,
          gradeLevelId: gradeLevelIdToUse,
          classSectionId: _selectedClassSection!.id!,
          timetableId: timetableIdToUse,
        );
  }

  void getStudentList() {
    attendanceReport.clear();
    debugPrint(
        "Fetching students for class section ID: ${_selectedClassSection?.id}");
    debugPrint("Getting student list");
    debugPrint("Selected class section: ${_selectedClassSection?.id}");
    debugPrint("Selected timetable: $_selectedTimeTableId");

    if (_selectedClassSection == null || _selectedClassSection!.id == null) {
      Utils.showSnackBar(
          message: "Pilih kelas terlebih dahulu", context: context);
      return;
    }

    context.read<StudentsByClassSectionCubit>().fetchStudents(
      status: StudentListStatus.all,
      classSectionId: _selectedClassSection!.id!,
      classSubjectId: _selectedTimeTableSlot?.subjectTeacherId,
    );
  }

  void changeClassSectionSelection(ClassSection? newSelectedClassSection) {
    _selectedClassSection = newSelectedClassSection;
    _selectedTimeTableId = 0; // Reset jadwal pelajaran ketika kelas berubah

    // Extract grade level from class section if available
    if (newSelectedClassSection != null) {
      _selectedGradeLevelId = newSelectedClassSection.gradeLevelId;
    }

    setState(() {});
    if (newSelectedClassSection != null && newSelectedClassSection.id != null) {
      getStudentList();
      getAttendance(); // Directly call getAttendance since we have class selection
      context.read<TeacherMyTimetableCubit>().getTeacherMyTimetable();
    }

    // Clear previous attendance data when class changes
    attendanceReport.clear();
  }

  void changeGradeLevelSelection(int? newGradeLevelId) {
    // Method kept for compatibility but simplified
    setState(() {
      _selectedGradeLevelId = newGradeLevelId;
    });
  }

  void resetForm() {
    setState(() {
      _selectedMateri = '';

      // Only clear lampiran if it's a local file, not a server URL
      if (_selectedLampiran != null && !_selectedLampiran!.startsWith('http')) {
        _selectedLampiran = null;
        uploadedFiles.clear();
      }

      attendanceReport.clear();
    });
  }

  void changeTimetableSlotSelection(int? newSelectedTimetableId) {
    _selectedTimeTableId = newSelectedTimetableId ?? 0;

    // Set default jumlah JP ketika jadwal dipilih
    if (newSelectedTimetableId != null && newSelectedTimetableId > 0) {
      _selectedJumlahJp = 1; // Default 1 JP per jadwal
    } else {
      _selectedJumlahJp = 1; // Default to 1 JP even without specific timetable
    }

    setState(() {});

    // Refresh attendance data if we have class section
    if (_selectedClassSection != null && _selectedClassSection!.id != null) {
      getAttendance();
    }
  }

  String formatTime(String time) {
    return time.substring(0, 5).replaceAll(':', '.');
  }

  Future<void> pickFile() async {
    debugPrint(
        '🎯 [ATTENDANCE SCREEN] Memulai upload lampiran dengan kompresi otomatis');

    // Gunakan mixin untuk pick dan kompres otomatis dengan loading dialog
    final compressedFiles = await pickAndCompressFiles(
      allowMultiple: false,
      maxSizeInMB: 0.5, // Target 500KB
      forceCompress: true,
      context: context,
    );

    if (compressedFiles != null && compressedFiles.isNotEmpty) {
      final file = compressedFiles.first;
      final fileSize = await file.length();
      final fileName = file.path.split('/').last;

      debugPrint(
          '✅ [ATTENDANCE SCREEN] File lampiran berhasil diproses: $fileName');
      debugPrint(
          '   📊 Ukuran final: ${OptimizedFileCompressionUtils.formatFileSize(fileSize)} (${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB)');

      // Show compression result to user
      // Note: We'll add original size tracking later for better feedback

      // Convert File to PlatformFile for compatibility
      final platformFile = PlatformFile(
        name: fileName,
        size: fileSize,
        path: file.path,
      );

      setState(() {
        _selectedLampiran = file.path;
        uploadedFiles.clear();
        uploadedFiles.add(platformFile);
      });
    } else {
      debugPrint(
          '❌ [ATTENDANCE SCREEN] Tidak ada file yang dipilih atau diproses');
    }
  }

  List<PlatformFile> uploadedFiles = [];

  Widget _buildStudents({required List<AttendanceStudent> attendance}) {
    return BlocBuilder<StudentsByClassSectionCubit,
        StudentsByClassSectionState>(
      builder: (BuildContext context, StudentsByClassSectionState state) {
        if (state is StudentsByClassSectionFetchSuccess) {
          if (state.studentDetailsList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Tidak ada siswa ditemukan di kelas ini",
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
            );
          }

          final allStudents = state.studentDetailsList;

          // Filter students based on search query
          final filteredStudents = _searchQuery.isEmpty
              ? allStudents
              : allStudents.where((student) {
                  final fullName = (student.fullName ??
                          '${student.firstName ?? ''} ${student.lastName ?? ''}')
                      .toLowerCase();
                  return fullName.contains(_searchQuery);
                }).toList();

          return StudentAttendanceContainer(
            studentAttendances: filteredStudents.map((e) {
              // Find matching attendance from previous submission
              final matchedAttendance = attendance
                  .firstWhereOrNull((element) => element.studentId == e.id);

              return StudentAttendance.fromStudentDetails(
                studentDetails: e,
                type: matchedAttendance?.type ??
                    1, // Use stored type or default to present (1)
              );
            }).toList(),
            allStudentAttendances: allStudents.map((e) {
              // Find matching attendance from previous submission for all students
              final matchedAttendance = attendance
                  .firstWhereOrNull((element) => element.studentId == e.id);

              return StudentAttendance.fromStudentDetails(
                studentDetails: e,
                type: matchedAttendance?.type ??
                    1, // Use stored type or default to present (1)
              );
            }).toList(),
            isForAddAttendance: true,
            isReadOnly: false, // Always allow editing
            onStatusChanged:
                (List<({StudentAttendanceStatus status, int studentId})>
                    attendanceStatuses) {
              attendanceReport = attendanceStatuses;
              setState(() {});
            },
          );
        } else if (state is StudentsByClassSectionFetchFailure) {
          return Center(
            child: Padding(
              padding:
                  EdgeInsets.only(top: topPaddingOfErrorAndLoadingContainer),
              child: ErrorContainer(
                errorMessage: state.errorMessage,
                onTapRetry: () {
                  getStudentList();
                },
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
        padding: const EdgeInsets.only(
            bottom: 100), // Add bottom padding to prevent overlap
        child: BlocBuilder<SubjectAttendanceCubit, SubjectAttendanceState>(
          builder: (context, state) {
            if (state is SubjectAttendanceFetchInProgress) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title section skeleton
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    width: double.infinity,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        height: 24,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  // Learning details section skeleton
                  const SkeletonLearningDetails(),

                  // Students attendance list skeleton
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
                        // List header skeleton
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  height: 16,
                                  width: 180,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Student list skeleton
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            children: List.generate(8, (index) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.grey.withValues(alpha: 0.05),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 13),
                                    child: Row(
                                      children: [
                                        // Number
                                        SizedBox(
                                          width: 32,
                                          child: Container(
                                            height: 14,
                                            width: 20,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Student avatar
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Student info
                                        Expanded(
                                          flex: 6,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                height: 16,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                height: 12,
                                                width: 80,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Attendance buttons
                                        SizedBox(
                                          width: 72,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
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
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else if (state is SubjectAttendanceFetchSuccess) {
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
                  ).animate().fadeIn(duration: 400.ms).slideY(
                      begin: -0.1,
                      end: 0,
                      curve: Curves
                          .easeOutQuad), // Form area with material input - Always show the form
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                        // Form header
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
                              // Icon
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_note_rounded,
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
                                child: Text(
                                  'Detail Pembelajaran',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Materi input field
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Label for Materi field with icon
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          _maroonPrimary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.menu_book_rounded,
                                      size: 18,
                                      color: _maroonPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Materi Pembelajaran (Opsional)',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Modern text field with shadow
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _materiController,
                                  minLines: 3,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Tuliskan materi pembelajaran di sini (opsional)...',
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: _maroonPrimary,
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedMateri = value;
                                    });
                                  },
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ), // File upload section
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          _maroonPrimary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.attachment_rounded,
                                      size: 18,
                                      color: _maroonPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Lampiran (Opsional)',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // File format description
                              Text(
                                'Format yang didukung: JPEG, PNG, JPG, GIF, SVG, DOC, DOCX, PDF',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Upload button
                              InkWell(
                                onTap: () => pickFile(),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          _maroonLight.withValues(alpha: 0.3),
                                      width: 1,
                                      style: BorderStyle.solid,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: _selectedLampiran != null
                                        ? _maroonPrimary.withValues(alpha: 0.03)
                                        : Colors.white,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_selectedLampiran == null) ...[
                                        Icon(
                                          Icons.upload_file_rounded,
                                          size: 32,
                                          color: _maroonLight,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Klik untuk mengunggah lampiran',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: _maroonLight,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ] else ...[
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: _maroonPrimary
                                                    .withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                _selectedLampiran!
                                                        .startsWith('http')
                                                    ? Icons.cloud_done_rounded
                                                    : Icons.check_rounded,
                                                color: _maroonPrimary,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _selectedLampiran!
                                                            .startsWith('http')
                                                        ? 'Lampiran'
                                                        : 'File berhasil diunggah',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: _maroonPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _selectedLampiran!
                                                            .startsWith('http')
                                                        ? _selectedLampiran!
                                                            .split('/')
                                                            .last
                                                        : _selectedLampiran!
                                                            .split('/')
                                                            .last,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                _selectedLampiran!
                                                        .startsWith('http')
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                        .delete_outline_rounded,
                                                color: _selectedLampiran!
                                                        .startsWith('http')
                                                    ? _maroonPrimary
                                                    : Colors.redAccent,
                                              ),
                                              onPressed: () async {
                                                if (_selectedLampiran!
                                                    .startsWith('http')) {
                                                  // Try to launch URL using Uri.parse
                                                  try {
                                                    final Uri url = Uri.parse(
                                                        _selectedLampiran!);
                                                    if (!await launchUrl(url)) {
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                      Utils.showSnackBar(
                                                          message:
                                                              "Tidak dapat membuka URL: $_selectedLampiran",
                                                          context: context);
                                                    }
                                                  } catch (e) {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    Utils.showSnackBar(
                                                        message:
                                                            "Tidak dapat membuka URL: $_selectedLampiran",
                                                        context: context);
                                                  }
                                                } else {
                                                  // Delete local file
                                                  setState(() {
                                                    _selectedLampiran = null;
                                                    uploadedFiles.clear();
                                                  });
                                                }
                                              },
                                            ),
                                          ],
                                        )
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 100.ms)
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
                              ), // Status badge - Always show as active
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
            } else if (state is SubjectAttendanceFetchFailure) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * 0.2),
                  child: ErrorContainer(
                    errorMessage: state.errorMessage,
                    onTapRetry: () {
                      getAttendance();
                    },
                  ),
                ),
              );
            } else {
              // For initial state or other states, show instructions with class selector
              return Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.1),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _maroonPrimary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.assignment_turned_in_rounded,
                          size: 48,
                          color: _maroonPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Siap untuk mengambil absensi?',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _maroonPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Pilih kelas untuk memulai',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Class selection dropdown
                      const SizedBox(height: 32),
                      BlocBuilder<ClassesCubit, ClassesState>(
                        builder: (context, state) {
                          if (state is ClassesFetchSuccess) {
                            return Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: DropdownButtonFormField<ClassSection>(
                                initialValue: _selectedClassSection,
                                items: state.classes
                                    .map((classSection) =>
                                        DropdownMenuItem<ClassSection>(
                                          value: classSection,
                                          child: Text(classSection.fullName ??
                                              'Unknown Class'),
                                        ))
                                    .toList(),
                                onChanged: (val) =>
                                    changeClassSectionSelection(val),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color:
                                          _maroonPrimary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color:
                                          _maroonPrimary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _maroonPrimary,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  prefixIcon: Icon(
                                    Icons.class_rounded,
                                    color: _maroonPrimary,
                                  ),
                                ),
                                hint: Text(
                                  'Pilih Kelas',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[500],
                                  ),
                                ),
                                style: GoogleFonts.poppins(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: _maroonPrimary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Memuat kelas...',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<SubjectAttendanceCubit, SubjectAttendanceState>(
      builder: (context, state) {
        if (state is SubjectAttendanceFetchSuccess) {
          if (state.isHoliday) {
            // Hide button only for holidays, not for teaching hours
            return const SizedBox();
          }
          return BlocConsumer<SubmitAttendanceSubjectCubit,
                  SubmitAttendanceSubjectState>(
              listener: (context, submitAttendanceSubjectState) {
            if (submitAttendanceSubjectState
                is SubmitAttendanceSubjectSuccess) {
              CustomSuccessMessage.show(
                context: context,
                message: "Berhasil menyimpan Kehadiran!",
                backgroundColor: Colors.green,
                textColor: Colors.white,
              );

              // Optional: Add haptic feedback
              HapticFeedback.mediumImpact();
              resetForm();
              Navigator.pop(context);
            } else if (submitAttendanceSubjectState
                is SubmitAttendanceSubjectFailure) {
              Utils.showSnackBar(
                context: context,
                message: submitAttendanceSubjectState.errorMessage,
              );
            }
          }, builder: (context, submitAttendanceSubjectState) {
            // Always active unless submission is in progress
            final bool isSubmitActive = submitAttendanceSubjectState
                is! SubmitAttendanceSubjectInProgress;

            return Positioned(
              bottom: 0,
              left: 0,
              right: 0,
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
                      colors: [
                        _maroonPrimary,
                        const Color(0xFF9A1E3C),
                        _maroonLight,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
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
                        if (!isSubmitActive) {
                          return; // Only check if submission is in progress
                        }

                        // Validasi data sebelum submit
                        // Validasi waktu pelajaran
                        if (_selectedTimeTableSlot != null &&
                            _selectedTimeTableSlot!.startTime != null) {
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final selectedDate = DateTime(_selectedDateTime.year,
                              _selectedDateTime.month, _selectedDateTime.day);

                          if (selectedDate.isAtSameMomentAs(today)) {
                            final startTimeParts =
                                _selectedTimeTableSlot!.startTime!.split(':');
                            final startHour = int.parse(startTimeParts[0]);
                            final startMinute = int.parse(startTimeParts[1]);
                            final lessonStartTime = DateTime(now.year,
                                now.month, now.day, startHour, startMinute);

                            if (now.isBefore(lessonStartTime)) {
                              Utils.showSnackBar(
                                message: "Belum memasuki jam pelajaran.",
                                context: context,
                              );
                              return;
                            }
                          }
                        }

                        if (_selectedClassSection == null ||
                            _selectedClassSection!.id == null) {
                          Utils.showSnackBar(
                              message: "Pilih kelas terlebih dahulu",
                              context: context);
                          return;
                        }

                        // Set defaults for required fields
                        int gradeLevelIdToSubmit = _selectedGradeLevelId ??
                            _selectedClassSection!.gradeLevelId ??
                            1;
                        int timetableIdToSubmit =
                            _selectedTimeTableId > 0 ? _selectedTimeTableId : 1;
                        int jumlahJpToSubmit =
                            _selectedJumlahJp > 0 ? _selectedJumlahJp : 1;

                        if (attendanceReport.isEmpty) {
                          Utils.showSnackBar(
                              message: "Data kehadiran siswa belum diisi",
                              context: context);
                          return;
                        }

                        // Log detailed submission data
                        debugPrint('=== ATTENDANCE SUBMISSION DATA ===');
                        debugPrint(
                            '📅 Date: ${Utils.formatDate(_selectedDateTime)}');
                        debugPrint(
                            '🏫 Class: ${_selectedClassSection?.fullName} (ID: ${_selectedClassSection?.id})');
                        debugPrint('📚 Timetable ID: $timetableIdToSubmit');
                        debugPrint('⏱️ JP Count: $jumlahJpToSubmit');
                        debugPrint(
                            '📝 Materi: ${_selectedMateri.isEmpty ? "(empty)" : _selectedMateri}');
                        debugPrint(
                            '📎 Lampiran: ${_selectedLampiran ?? "(none)"}');
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
                        debugPrint(
                            '================================'); // Only send lampiran if it's a local file path, not a URL
                        final String lampiranToSend =
                            (_selectedLampiran != null &&
                                    !_selectedLampiran!.startsWith('http'))
                                ? _selectedLampiran!
                                : '';

                        context
                            .read<SubmitAttendanceSubjectCubit>()
                            .submitSubjectAttendance(
                              date: _selectedDateTime,
                              classSectionId: _selectedClassSection!.id!,
                              attendanceReport: attendanceReport,
                              timetableId: timetableIdToSubmit,
                              jumlahJp: jumlahJpToSubmit,
                              materi: _selectedMateri,
                              lampiran: lampiranToSend,
                              gradeLevelId: gradeLevelIdToSubmit,
                            );
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
                          child: submitAttendanceSubjectState
                                  is SubmitAttendanceSubjectInProgress
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
      title: 'Kehadiran Pelajaran',
      icon: Icons.edit_calendar_rounded,
      fabAnimationController: _fabAnimationController,
      primaryColor: _maroonPrimary,
      lightColor: _maroonLight,
      height: 160, // Decreased height to match TeacherAddAttendanceScreen
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
                      if (_selectedClassSection != null) {
                        getAttendance();
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

            // Class selection filter (display only)
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          BlocBuilder<ClassesCubit, ClassesState>(
            builder: (context, state) {
              debugPrint("EMITT");
              debugPrint(state.toString());
              if (state is ClassesFetchSuccess) {
                return Stack(children: [
                  _buildStudentsContainer(),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildSubmitButton(),
                  ),
                ]);
              }
              if (state is ClassesFetchFailure) {
                return Center(
                    child: ErrorContainer(
                  errorMessage: state.errorMessage,
                  onTapRetry: () {
                    context.read<ClassesCubit>().getClasses();
                  },
                ));
              }
              debugPrint("LOADING");
              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title section skeleton
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      width: double.infinity,
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          height: 24,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    // Learning details section skeleton
                    const SkeletonLearningDetails(),

                    // Students attendance list skeleton
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
                          // List header skeleton
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            child: Shimmer.fromColors(
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100,
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    height: 16,
                                    width: 180,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Student list skeleton items
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              children: List.generate(6, (index) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.grey.withValues(alpha: 0.05),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 13),
                                      child: Row(
                                        children: [
                                          // Number
                                          SizedBox(
                                            width: 32,
                                            child: Container(
                                              height: 14,
                                              width: 20,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Student avatar
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Student info
                                          Expanded(
                                            flex: 6,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  height: 16,
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  height: 12,
                                                  width: 80,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Attendance buttons
                                          SizedBox(
                                            width: 72,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
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
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

