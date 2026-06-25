import 'package:eschool_saas_staff/cubits/teacherAcademics/gradeLevelCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/gradeLevel.dart';
import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/student/studentsByClassSectionCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/exam/examCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/exam/submitExamMarksCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/exam/exam.dart';
import 'package:eschool_saas_staff/data/models/student/studentDetails.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:math' show sin, cos;

class TeacherExamResultScreen extends StatefulWidget {
  static Widget getRouteInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ClassesCubit(),
        ),
        BlocProvider(
          create: (context) => ExamsCubit(),
        ),
        BlocProvider(
          create: (context) => StudentsByClassSectionCubit(),
        ),
        BlocProvider(
          create: (context) => SubmitExamMarksCubit(),
        ),
        BlocProvider(
          create: (context) => GradeLevelCubit(),
        ),
      ],
      child: const TeacherExamResultScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  const TeacherExamResultScreen({super.key});

  @override
  State<TeacherExamResultScreen> createState() =>
      _TeacherExamResultScreenState();
}

class PatternPainter extends CustomPainter {
  final double amplitude;
  final Color color;

  PatternPainter({
    required this.amplitude,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();

    // Draw a wavy pattern
    final double width = size.width;
    final double height = size.height;

    path.moveTo(0, height / 2);

    for (double x = 0; x < width; x += 10) {
      final y = height / 2 + amplitude * sin(x * 0.1);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Draw a second wave offset slightly
    final path2 = Path();
    path2.moveTo(0, height / 2 + 10);

    for (double x = 0; x < width; x += 10) {
      final y = height / 2 + 10 + amplitude * cos(x * 0.1);
      path2.lineTo(x, y);
    }

    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(PatternPainter oldDelegate) {
    return oldDelegate.amplitude != amplitude || oldDelegate.color != color;
  }
}

class _TeacherExamResultScreenState extends State<TeacherExamResultScreen>
    with TickerProviderStateMixin {
  ClassSection? _selectedClassSection;
  ExamTimeTable? _selectedExamTimetableSubject;
  Exam? _selectedExam;
  GradeLevel? _selectedGradeLevel;

  List<TextEditingController> marksControllers = [];
  late TextEditingController bulkMarksController;
  late TextEditingController searchController;

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // App bar animation controller
  late AnimationController _appBarAnimationController;

  // Theme colors - Softer Maroon palette
  static Color get _primaryColor => AppColorPalette.primaryMaroon; // Softer deep maroon
  static Color get _accentColor => AppColorPalette.secondaryMaroon; // Softer medium maroon
  static Color get _energyColor => AppColorPalette.lightMaroon; // Softer light maroon
  static Color get _glowColor => AppColorPalette.secondaryMaroon; // Softer rich maroon
  @override
  void initState() {
    bulkMarksController = TextEditingController();
    searchController = TextEditingController();

    // Initialize animation controllers
    // Add pulse animation controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    // Initialize app bar animation controller
    _appBarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<ClassesCubit>().getClasses();
        context.read<GradeLevelCubit>().getGradeLevels();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    for (var element in marksControllers) {
      element.dispose();
    }
    bulkMarksController.dispose();
    searchController.dispose();
    _pulseController.dispose();
    _appBarAnimationController.dispose();
    super.dispose();
  }

  void changeSelectedClassSection(ClassSection? classSection,
      {bool fetchNewSubjects = true}) {
    if (_selectedClassSection != classSection) {
      _selectedClassSection = classSection;
      getExams();
      setState(() {});
    }
  }

  void changeSelectedGradeLevel(GradeLevel? gradeLevel) {
    if (_selectedGradeLevel != gradeLevel) {
      _selectedGradeLevel = gradeLevel;
      // Reset selections when grade level changes
      _selectedClassSection = null;
      _selectedExam = null;
      _selectedExamTimetableSubject = null;
      // Re-fetch classes - filter will be applied in UI
      context.read<ClassesCubit>().getClasses();
      setState(() {});
    }
  }

  void getExams() {
    context.read<ExamsCubit>().fetchExamsList(
          examStatus: 2, //exam should be finished
          publishStatus: 0, //exam should not be published
          classSectionId: _selectedClassSection?.id ?? 0,
        );
  }

  void getStudents() {
    if (_selectedExamTimetableSubject == null &&
        _selectedExam?.examTimetable?.isNotEmpty == true) {
      _selectedExamTimetableSubject = _selectedExam?.examTimetable?.firstOrNull;
    }

    if (_selectedExamTimetableSubject != null) {
      context.read<StudentsByClassSectionCubit>().fetchStudents(
          status: StudentListStatus.active,
          classSectionId: _selectedClassSection?.id ?? 0,
          examId: _selectedExam?.examID ?? 0,
          classSubjectId: _selectedExamTimetableSubject?.classSubjectId ?? 0);
    } else {
      context.read<StudentsByClassSectionCubit>().updateState(
          StudentsByClassSectionFetchFailure(
              "Tidak ada mata pelajaran dalam ujian ini. Silakan pilih ujian lain."));
    }
  }

  void setupMarksInitialValues(List<StudentDetails> students) {
    for (var element in marksControllers) {
      element.dispose();
    }
    marksControllers.clear();
    for (int i = 0; i < students.length; i++) {
      final existingMark = students[i].examMarks?.firstWhereOrNull((element) =>
          element.examTimetableId == _selectedExamTimetableSubject?.id);
      marksControllers.add(TextEditingController(
          text: existingMark != null ? existingMark.obtainedMarks.toString() : ""));
    }
  }

  void applyBulkMarksToAll() {
    if (bulkMarksController.text.isEmpty) {
      Utils.showSnackBar(
          message: "Silakan masukkan nilai terlebih dahulu", context: context);
      return;
    }

    int bulkMark = int.tryParse(bulkMarksController.text) ?? 0;
    int totalMarks = _selectedExamTimetableSubject?.totalMarks ?? 0;

    if (bulkMark > totalMarks) {
      Utils.showSnackBar(
          message: "Nilai tidak boleh melebihi nilai maksimum ($totalMarks)",
          context: context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi"),
        content:
            Text("Semua siswa akan mendapatkan nilai $bulkMark. Lanjutkan?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              for (var controller in marksControllers) {
                controller.text = bulkMark.toString();
              }
              Navigator.pop(context);
              // Show custom success toast
              OverlayEntry? overlayEntry;

              void showSuccessToast(String message) {
                // Remove existing overlay if any
                overlayEntry?.remove();
                overlayEntry = null;

                overlayEntry = OverlayEntry(
                  builder: (context) => Positioned(
                    bottom: 70,
                    left: 20,
                    right: 20,
                    child: SlideInUp(
                      duration: const Duration(milliseconds: 300),
                      child: Material(
                        elevation: 10,
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF43A047), // Green shade
                                Color(0xFF388E3C), // Slightly darker green
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF43A047)
                                    .withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  message,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    size: 18),
                                onPressed: () {
                                  overlayEntry?.remove();
                                  overlayEntry = null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );

                // Show the toast
                Overlay.of(context).insert(overlayEntry!);

                // Auto-dismiss after 3 seconds
                Future.delayed(const Duration(seconds: 3), () {
                  overlayEntry?.remove();
                  overlayEntry = null;
                });
              }

              // Call the custom toast function
              showSuccessToast("Nilai berhasil diterapkan ke semua siswa");
            },
            child: const Text("Ya"),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return SlideInUp(
      duration: const Duration(milliseconds: 800),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildFilterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Cari siswa...',
            prefixIcon: Icon(Icons.search, color: _primaryColor),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          onChanged: (value) {
            // Implement search functionality here
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return BlocBuilder<ClassesCubit, ClassesState>(
      builder: (context, state) {
        return FadeInDown(
          duration: const Duration(milliseconds: 700),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_alt_rounded, color: _primaryColor),
                        const SizedBox(width: 10),
                        Text(
                          'Filter Hasil Ujian',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedGradeLevel = null;
                          _selectedClassSection = null;
                          _selectedExam = null;
                          _selectedExamTimetableSubject = null;
                          // Re-fetch all data
                          context.read<ClassesCubit>().getClasses();
                        });
                      },
                      child: Text(
                        'Reset',
                        style: TextStyle(color: _primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Grade Level Dropdown
                BlocBuilder<GradeLevelCubit, GradeLevelState>(
                  builder: (context, gradeLevelState) {
                    if (gradeLevelState is GradeLevelFetchSuccess) {
                      return _buildDropdown(
                        value: _selectedGradeLevel,
                        items: gradeLevelState.gradeLevels
                            .map((gradeLevel) => DropdownMenuItem<GradeLevel>(
                                  value: gradeLevel,
                                  child: Text(gradeLevel.name ?? ""),
                                ))
                            .toList(),
                        onChanged: (value) {
                          changeSelectedGradeLevel(value);
                        },
                        icon: Icons.layers_rounded,
                        label: 'Pilih Tingkatan',
                      );
                    }
                    return Container();
                  },
                ),

                const SizedBox(height: 15),

                // Class Section Dropdown
                BlocBuilder<ClassesCubit, ClassesState>(
                  builder: (context, state) {
                    if (state is ClassesFetchSuccess) {
                      List<ClassSection> classes =
                          context.read<ClassesCubit>().getAllClasses();

                      // Filter classes based on selected grade level
                      if (_selectedGradeLevel != null) {
                        classes = classes
                            .where((classSection) =>
                                classSection.gradeLevelId ==
                                _selectedGradeLevel!.id)
                            .toList();
                      }

                      return _buildDropdown(
                        value: _selectedClassSection,
                        items: classes
                            .map((cls) => DropdownMenuItem<ClassSection>(
                                  value: cls,
                                  child: Text(Utils()
                                      .cleanClassName(cls.fullName ?? "")),
                                ))
                            .toList(),
                        onChanged: (value) {
                          changeSelectedClassSection(value);
                        },
                        icon: Icons.school_rounded,
                        label: 'Pilih Kelas',
                      );
                    }
                    return Container();
                  },
                ),

                const SizedBox(height: 15),

                // Exam Dropdown
                BlocBuilder<ExamsCubit, ExamsState>(
                  builder: (context, state) {
                    if (state is ExamsFetchSuccess) {
                      return _buildDropdown(
                        value: _selectedExam,
                        items: state.examList
                            .map((exam) => DropdownMenuItem<Exam>(
                                  value: exam,
                                  child: Text(exam.examName ?? ""),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedExam = value;
                            _selectedExamTimetableSubject =
                                _selectedExam?.examTimetable?.firstOrNull;
                            getStudents();
                          });
                        },
                        icon: Icons.assignment_outlined,
                        label: 'Pilih Ujian',
                      );
                    }
                    return Container();
                  },
                ),

                const SizedBox(height: 15),

                // Subject Dropdown
                BlocBuilder<ExamsCubit, ExamsState>(
                  builder: (context, examState) {
                    if (examState is ExamsFetchSuccess &&
                        _selectedExam != null) {
                      List<ExamTimeTable> subjects = _selectedExam
                              ?.examTimetable
                              ?.where((timetable) =>
                                  timetable.subjectName?.isNotEmpty ?? false)
                              .toList() ??
                          [];

                      return _buildDropdown(
                        value: _selectedExamTimetableSubject,
                        items: subjects
                            .map((subject) => DropdownMenuItem<ExamTimeTable>(
                                  value: subject,
                                  child: Text(subject.subjectName ?? ""),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedExamTimetableSubject = value;
                            getStudents();
                          });
                        },
                        icon: Icons.book_outlined,
                        label: 'Pilih Mata Pelajaran',
                      );
                    }
                    return Container();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required IconData icon,
    required String label,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _primaryColor),
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor),
        ),
      ),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      hint: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildBulkMarksAssignment() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.assignment_turned_in_rounded,
                    color: _primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Nilai Massal",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: bulkMarksController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: "Input Nilai",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: applyBulkMarksToAll,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryColor, _accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "Terapkan",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  "Tindakan ini akan mengubah nilai siswa",
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentContainer({
    required StudentDetails studentDetails,
    required TextEditingController controller,
    required int index,
  }) {
    // Calculate a unique hue for each student card based on their index
    final double hueValue = (index * 15) % 360;
    final Color accentColor =
        HSLColor.fromAHSL(0.2, hueValue, 0.6, 0.8).toColor();

    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 450),
      child: SlideAnimation(
        horizontalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: Colors.grey.shade100,
                width: 1.0,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                splashColor: _primaryColor.withValues(alpha: 0.05),
                highlightColor: Colors.transparent,
                onTap: () {
                  // Let the user tap the text field directly to edit
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Student avatar/number container with gradient
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _primaryColor.withValues(alpha: 0.8),
                              _accentColor,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            (index + 1).toString().padLeft(2, '0'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Student info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Student name with icon

                                Expanded(
                                  child: Text(
                                    studentDetails.fullName ?? "",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey[800],
                                      letterSpacing: 0.2,
                                    ),
                                    // Show full name with no ellipsis
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (studentDetails.rollNumber != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.badge_outlined,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "No. Absen: ${studentDetails.rollNumber}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),

                      // Score input with animated container
                      Container(
                        width: 76,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.grey[100]!,
                              Colors.grey[50]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background score indicator
                            if (controller.text.isNotEmpty)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: double.infinity,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(11),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      _primaryColor.withValues(alpha: 0.05),
                                      _accentColor.withValues(alpha: 0.08),
                                    ],
                                  ),
                                ),
                              ),

                            // Input field
                            TextField(
                              controller: controller,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _primaryColor,
                                letterSpacing: 0.5,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                hintText: "0",
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
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
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<StudentsByClassSectionCubit,
        StudentsByClassSectionState>(
      builder: (context, studentState) {
        if (studentState is StudentsByClassSectionFetchSuccess) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BlocConsumer<SubmitExamMarksCubit, SubmitExamMarksState>(
              listener: (submitListenerContext, state) {
                if (state is SubmitExamMarksSubmitSuccess) {
                  // Show custom success toast
                  OverlayEntry? overlayEntry;

                  overlayEntry = OverlayEntry(
                    builder: (overlayContext) => Positioned(
                      bottom: 70,
                      left: 20,
                      right: 20,
                      child: SlideInUp(
                        duration: const Duration(milliseconds: 300),
                        child: Material(
                          elevation: 10,
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color.fromARGB(
                                      255, 44, 187, 51), // Green shade
                                  Color.fromARGB(255, 46, 193,
                                      53), // Slightly darker green
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF43A047)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    Utils.getTranslatedLabel(
                                        resultAddedSuccessfullyKey),
                                    style: const TextStyle(
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
                  );

                  // Show the toast
                  Overlay.of(context).insert(overlayEntry);

                  // Auto-dismiss after 3 seconds
                  Future.delayed(const Duration(seconds: 3), () {
                    overlayEntry?.remove();
                    overlayEntry = null;
                  });
                } else if (state is SubmitExamMarksSubmitFailure) {
                  Utils.showSnackBar(
                      message: state.errorMessage,
                      context: context);
                }
              },
              builder: (submitBuilderContext, state) {
                return AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (animBuilderContext, child) {
                    return Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _primaryColor,
                            _accentColor,
                            const Color(0xFF8A2A2A),
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withValues(alpha: 0.3),
                            blurRadius: 12 + (8 * _pulseAnimation.value),
                            offset: const Offset(0, 4),
                            spreadRadius: -2 + (1 * _pulseAnimation.value),
                          ),
                          BoxShadow(
                            color: _glowColor.withValues(
                                alpha: 0.1 + (0.1 * _pulseAnimation.value)),
                            blurRadius: 20 + (10 * _pulseAnimation.value),
                            offset: const Offset(0, 2),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // Add haptic feedback for better user experience
                            HapticFeedback.mediumImpact();

                            if (state is SubmitExamMarksSubmitInProgress) {
                              return;
                            } else {
                              for (int i = 0;
                                  i < marksControllers.length;
                                  i++) {
                                if (marksControllers[i].text.trim().isEmpty) {
                                  Utils.showSnackBar(
                                      message: pleaseAddMarksToAllStudentsKey,
                                      context: context);
                                  return;
                                } else if ((int.tryParse(
                                            marksControllers[i].text) ??
                                        0) >
                                    (_selectedExamTimetableSubject
                                            ?.totalMarks ??
                                        0)) {
                                  Utils.showSnackBar(
                                      message: cannotAddMoreMarksThenTotalKey,
                                      context: context);
                                  return;
                                }
                              }

                              context
                                  .read<SubmitExamMarksCubit>()
                                  .submitOfflineExamMarks(
                                    examTimetableId:
                                        _selectedExamTimetableSubject?.id ?? 0,
                                    classSubjectId:
                                        _selectedExamTimetableSubject
                                                ?.classSubjectId ??
                                            0,
                                    classSectionId:
                                        _selectedClassSection?.id ?? 0,
                                    examId: _selectedExam?.examID ?? 0,
                                    marksDataValue: {
                                      "exam_id": _selectedExam?.examID ?? 0,
                                      "class_subject_id": _selectedExamTimetableSubject?.classSubjectId ?? 0,
                                      "class_section_id": _selectedClassSection?.id ?? 0,
                                      "exam_timetable_id": _selectedExamTimetableSubject?.id ?? 0,
                                      "marks_data": List.generate(
                                        marksControllers.length,
                                        (index) => {
                                          "student_id": studentState
                                              .studentDetailsList[index]
                                              .id ?? 0,
                                          "obtained_marks": int.tryParse(
                                                  marksControllers[index]
                                                      .text) ?? 0
                                        },
                                      ),
                                    },
                                  );
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          highlightColor: Colors.white.withValues(alpha: 0.1),
                          splashColor: Colors.white.withValues(alpha: 0.2),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Subtle animated pattern
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: ShaderMask(
                                    shaderCallback: (Rect bounds) {
                                      return LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white.withValues(alpha: 0.1),
                                          Colors.white.withValues(alpha: 0.05),
                                        ],
                                      ).createShader(bounds);
                                    },
                                    blendMode: BlendMode.srcIn,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withValues(alpha: 0.1),
                                            Colors.white
                                                .withValues(alpha: 0.05),
                                          ],
                                        ),
                                      ),
                                      child: CustomPaint(
                                        painter: PatternPainter(
                                          amplitude:
                                              4 + (2 * _pulseAnimation.value),
                                          color: Colors.white
                                              .withValues(alpha: 0.07),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Button content
                              Center(
                                child: state is SubmitExamMarksSubmitInProgress
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Animated icon
                                          AnimatedBuilder(
                                            animation: _pulseAnimation,
                                            builder: (context, child) {
                                              return Transform.scale(
                                                scale: 1.0 +
                                                    0.1 * _pulseAnimation.value,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white.withValues(
                                                        alpha: 0.15 +
                                                            0.05 *
                                                                _pulseAnimation
                                                                    .value),
                                                  ),
                                                  child: const Icon(
                                                    Icons.check_circle_outline,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 12),

                                          // Text with subtle animation
                                          Text(
                                            Utils.getTranslatedLabel(
                                                submitResultKey),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 17,
                                              letterSpacing: 0.5,
                                              shadows: [
                                                Shadow(
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

                              // Top highlight for 3D effect
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 1.5,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.1),
                                        Colors.white.withValues(alpha: 0.3),
                                        Colors.white.withValues(alpha: 0.1),
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildStudentsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: BlocConsumer<StudentsByClassSectionCubit,
          StudentsByClassSectionState>(
        listener: (context, state) {
          if (state is StudentsByClassSectionFetchSuccess) {
            setupMarksInitialValues(state.studentDetailsList);
          }
        },
        builder: (context, state) {
          // Show message prompt when no class or exam is selected yet
          if (_selectedClassSection == null || _selectedExam == null) {
            return Center(
              child: FadeIn(
                duration: const Duration(milliseconds: 800),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      Icons.assignment_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Pilih Kelas dan ujian untuk melihat hasil",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _accentColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Data siswa akan tampil setelah kelas & ujian dipilih",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is StudentsByClassSectionFetchSuccess) {
            if (state.studentDetailsList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Tidak ada hasil ujian",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            List<StudentDetails> filteredStudents = state.studentDetailsList;
            if (searchController.text.isNotEmpty) {
              filteredStudents = state.studentDetailsList
                  .where((student) => (student.fullName ?? "")
                      .toLowerCase()
                      .contains(searchController.text.toLowerCase()))
                  .toList();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exam Info Header
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _accentColor.withValues(alpha: 0.9),
                          _primaryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.assignment_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedExam?.examName ?? "",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedExamTimetableSubject
                                            ?.subjectName ??
                                        "",
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildExamInfoItem(
                              icon: Icons.class_outlined,
                              label: Utils().cleanClassName(
                                  _selectedClassSection?.fullName ?? ""),
                            ),
                            const SizedBox(width: 16),
                            _buildExamInfoItem(
                              icon: Icons.people_outline,
                              label: "${state.studentDetailsList.length} Siswa",
                            ),
                            const SizedBox(width: 16),
                            _buildExamInfoItem(
                              icon: Icons.grading_outlined,
                              label:
                                  "Nilai Max: ${_selectedExamTimetableSubject?.totalMarks ?? 0}",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bulk marks assignment
                _buildBulkMarksAssignment(),

                // Students list heading with animation
                FadeInLeft(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          _primaryColor.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _primaryColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.people_alt_outlined,
                            color: _primaryColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Daftar Siswa ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryColor,
                                ),
                              ),
                              TextSpan(
                                text: "(${filteredStudents.length})",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _primaryColor.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Students list
                ...List.generate(filteredStudents.length, (index) {
                  int originalIndex =
                      state.studentDetailsList.indexOf(filteredStudents[index]);
                  return _buildStudentContainer(
                    controller: marksControllers[originalIndex],
                    studentDetails: filteredStudents[index],
                    index: index,
                  );
                }),
                const SizedBox(height: 100), // Bottom padding for scroll
              ],
            );
          } else if (state is StudentsByClassSectionFetchFailure) {
            return Center(
              child: CustomErrorWidget(
                message: state.errorMessage,
                onRetry: () {
                  if (state.errorMessage.contains("Ujian belum selesai")) {
                    Utils.showSnackBar(
                        message:
                            "Silakan pilih ujian yang telah selesai untuk menginput nilai",
                        context: context);
                  } else {
                    getStudents();
                  }
                },
                primaryColor: _primaryColor,
              ),
            );
          } else {
            return Center(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 8,
                  itemBuilder: (_, __) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildExamInfoItem({required IconData icon, required String label}) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.grey[50],
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      appBar: CustomModernAppBar(
        title: "Hasil Ujian",
        icon: Icons.assignment_turned_in_rounded,
        fabAnimationController: _appBarAnimationController,
        primaryColor: _primaryColor,
        lightColor:
            _energyColor, // Using energyColor for better contrast and visual appeal
        onBackPressed: () => Navigator.pop(context),
        height: 85, // Slightly taller app bar for better presence
        showAddButton: false,
        showArchiveButton: false,
        showFilterButton: false,
        showHelperButton: false,
      ),
      body: Container(
        color: Colors.grey[50],
        child: SafeArea(
          top:
              false, // Set to false since the CustomModernAppBar handles the top safe area
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<ClassesCubit, ClassesState>(
                  builder: (context, state) {
                    if (state is ClassesFetchSuccess) {
                      return Stack(
                        children: [
                          // Main content with search, filter and student list
                          SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 70),
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                _buildSearchAndFilter(),
                                _buildStudentsList(),
                              ],
                            ),
                          ),

                          // Submit button at bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: _buildSubmitButton(),
                          ),
                        ],
                      );
                    }
                    if (state is ClassesFetchFailure) {
                      return Center(
                        child: CustomErrorWidget(
                          message: state.errorMessage,
                          onRetry: () {
                            context.read<ClassesCubit>().getClasses();
                          },
                          primaryColor: _primaryColor,
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 0, vertical: 20),
                      itemCount: 5,
                      itemBuilder: (context, index) => const SkeletonExamCard(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

