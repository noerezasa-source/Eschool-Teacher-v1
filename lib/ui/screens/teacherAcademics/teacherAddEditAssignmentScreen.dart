import 'dart:async';
import 'package:eschool_saas_staff/cubits/teacherAcademics/assignment/createAssignmentCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/assignment/editAssignmentCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/classSectionsAndSubjects.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/gradeLevelCubit.dart';
import 'package:eschool_saas_staff/data/repositories/academics/assignmentRepository.dart';
import 'package:eschool_saas_staff/data/models/academic/assignment.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/academic/studyMaterial.dart';
import 'package:eschool_saas_staff/data/models/academic/teacherSubject.dart';
import 'package:eschool_saas_staff/data/models/academic/gradeLevel.dart';
import 'package:eschool_saas_staff/data/models/academic/AssignmentFiletype.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/customFileContainer.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/studyMaterialContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextFieldContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/errorContainer.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:eschool_saas_staff/utils/system/optimized_file_compression_mixin.dart';
import 'package:eschool_saas_staff/utils/system/optimized_file_compression_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TeacherAddEditAssignmentScreen extends StatefulWidget {
  final Assignment? assignment;
  final ClassSection? selectedClassSection;
  final TeacherSubject? selectedSubject;
  static Widget getRouteInstance() {
    final arguments = Get.arguments as Map<String, dynamic>?;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => CreateAssignmentCubit(),
        ),
        BlocProvider(
          create: (context) => EditAssignmentCubit(),
        ),
        BlocProvider(
          create: (context) => ClassSectionsAndSubjectsCubit(),
        ),
        BlocProvider(
          create: (context) => GradeLevelCubit(),
        ),
      ],
      child: TeacherAddEditAssignmentScreen(
        assignment: arguments?['assignment'],
        selectedClassSection: arguments?['selectedClassSection'],
        selectedSubject: arguments?['selectedSubject'],
      ),
    );
  }

  static Map<String, dynamic> buildArguments(
      {required Assignment? assignment,
      required ClassSection? selectedClassSection,
      required TeacherSubject? selectedSubject}) {
    return {
      "assignment": assignment,
      "selectedClassSection": selectedClassSection,
      "selectedSubject": selectedSubject
    };
  }

  const TeacherAddEditAssignmentScreen(
      {super.key,
      required this.assignment,
      this.selectedClassSection,
      this.selectedSubject});

  @override
  State<TeacherAddEditAssignmentScreen> createState() =>
      _TeacherAddEditAssignmentScreenState();
}

class _TeacherAddEditAssignmentScreenState
    extends State<TeacherAddEditAssignmentScreen>
    with TickerProviderStateMixin, OptimizedFileCompressionMixin {
  late ClassSection? _selectedClassSection = widget.selectedClassSection;
  late TeacherSubject? _selectedSubject = widget.selectedSubject;
  GradeLevel? _selectedGradeLevel;

  // Dropdown selection states for tiered selection
  String? selectedTingkatan;
  String? selectedKelas;
  String? selectedMapel;
  List<String> tingkatanList = [];
  List<String> kelasList = [];
  List<String> mapelList = [];

  // Animation controllers
  late AnimationController _fabAnimationController;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  StreamSubscription? _editAssignmentSub;
  StreamSubscription? _gradeLevelSub;

  // Elegant Maroon Design System
  static const Color _deepMaroon = Color(0xFF7B2D3A); // Rich deep maroon
  static const Color _softMaroon = Color(0xFF9B4C5C); // Primary maroon
  static const Color _dustyRose = Color(0xFFB8707C); // Light dusty rose
  static const Color _blushPink = Color(0xFFD4A5A5); // Soft blush
  static const Color _pearl =
      Color(0xFFFFFFFF); // Pure white for better contrast
  static const Color _roseMist = Color(0xFFFAF8F8); // Rose mist
  static const Color _burgundy = Color(0xFF5D2329); // Dark burgundy
  static const Color _champagne =
      Color(0xFFF5F0ED); // Lighter champagne for better contrast

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _roseMist,
      appBar: CustomModernAppBar(
        title: widget.assignment != null ? "Edit Tugas" : "Buat Tugas Baru",
        icon: Icons.assignment_rounded,
        fabAnimationController: _fabAnimationController,
        primaryColor: _deepMaroon,
        lightColor: _softMaroon,
        onBackPressed: () => Get.back(result: refreshAssignmentsInPreviousPage),
        showAddButton: false,
        showArchiveButton: false,
        showFilterButton: false,
        showHelperButton: false,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: _buildAddEditAssignmentForm(),
            ),
            // Add some bottom padding for better scrolling on devices with notches
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  //This will determine if need to refresh the previous page
  //assignments data. If teacher remove the the any file
  //so we need to fetch the list again
  late bool refreshAssignmentsInPreviousPage = false;

  late final TextEditingController _assignmentNameTextEditingController =
      TextEditingController(
    text: widget.assignment?.name,
  );
  late final TextEditingController _assignmentDescriptionTextEditingController =
      TextEditingController(
    text: widget.assignment?.description ?? '', // Add null safety
  );

  late final List<StudyMaterial> _assignmentUploadedFilesEditingController =
      List.from(widget.assignment?.studyMaterial ?? []);

  late final TextEditingController _assignmentPointsTextEditingController =
      TextEditingController(
    text: widget.assignment?.points.toString(),
  );

  late final TextEditingController _extraResubmissionDaysTextEditingController =
      TextEditingController(
          text: widget.assignment?.extraDaysForResubmission.toString() ?? "0");
  // Remove unused resubmission status method
  // Using resubmission information from assignment directly in the code

  late DateTime? dueDate =
      DateTime.tryParse(widget.assignment?.dueDate.toString() ?? "");

  late TimeOfDay? dueTime = widget.assignment != null
      ? TimeOfDay.fromDateTime(widget.assignment!.dueDate)
      : null;

  List<PlatformFile> uploadedFiles = [];

  late List<StudyMaterial> assignmentAttachments =
      widget.assignment?.studyMaterial ?? [];

  List<AssignmentFileType> fileTypes = [];

  late final TextEditingController _minPointsTextEditingController =
      TextEditingController(
    text: widget.assignment?.minPoints != null &&
            widget.assignment!.minPoints != 0
        ? widget.assignment!.minPoints.toString()
        : '',
  );
  final TextEditingController _startDateTextEditingController =
      TextEditingController(); // Add this line
  final TextEditingController _endDateTextEditingController =
      TextEditingController(); // Add this line
  late final TextEditingController _maxFileSizeTextEditingController =
      TextEditingController(
          text: widget.assignment?.maxFile != null &&
                  widget.assignment!.maxFile != 0
              ? widget.assignment!.maxFile.toString()
              : '');
  late final TextEditingController _maxFileTextEditingController =
      TextEditingController(
    text: widget.assignment?.maxFile != null && widget.assignment!.maxFile != 0
        ? widget.assignment!.maxFile.toString()
        : '',
  );

  late DateTime? startDate = widget.assignment?.startDate;

  late DateTime? endDate = widget.assignment?.endDate;

  String? selectedAnswerType = "dokumen"; // Default to dokumen

  late bool _isTextAnswerAllowed;
  late bool _isFileAnswerAllowed;
  // These variables are already declared above, no need to redeclare
  // Just using the existing animation controllers

  // Color getters for elegant maroon design system
  Color get deepMaroonUI => _deepMaroon;
  Color get softMaroonUI => _softMaroon;
  Color get dustyRoseUI => _dustyRose;
  Color get blushPinkUI => _blushPink;
  Color get pearlUI => _pearl;
  Color get roseMistUI => _roseMist;
  Color get burgundyUI => _burgundy;
  Color get champagneUI => _champagne;

  // Main form builder method
  Widget _buildAddEditAssignmentForm() {
    return BlocBuilder<ClassSectionsAndSubjectsCubit,
        ClassSectionsAndSubjectsState>(
      builder: (context, state) {
        if (state is ClassSectionsAndSubjectsFetchInProgress) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_deepMaroon),
            ),
          );
        }

        if (state is ClassSectionsAndSubjectsFetchFailure) {
          return ErrorContainer(
            errorMessage: state.errorMessage,
            onTapRetry: () {
              context
                  .read<ClassSectionsAndSubjectsCubit>()
                  .getClassSectionsAndSubjects(
                    classSectionId: _selectedClassSection?.id,
                  );
            },
          );
        }

        if (state is ClassSectionsAndSubjectsFetchSuccess) {
          // Auto-fill class and subject selections if they were passed from previous screen
          if (widget.selectedClassSection != null && selectedKelas == null) {
            selectedKelas = widget.selectedClassSection!.fullName;
            _selectedClassSection = widget.selectedClassSection;
            // Fetch subjects for the selected class section
            changeSelectedClassSection(_selectedClassSection,
                fetchNewSubjects: true);
          }
          if (widget.selectedSubject != null && selectedMapel == null) {
            selectedMapel =
                widget.selectedSubject!.subject.getSybjectNameWithType();
            _selectedSubject = widget.selectedSubject;
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Basic Information Section
                _buildLuxurySection(
                  title: "Informasi Dasar",
                  subtitle: "Detail dan informasi utama tugas",
                  icon: Icons.info_rounded,
                  gradient: [_burgundy, _deepMaroon],
                  children: [
                    // Subject selection
                    _buildSubjectSelection(),
                    const SizedBox(height: 15),
                    // Assignment Name
                    _buildAnimatedTextField(
                      controller: _assignmentNameTextEditingController,
                      label: 'Nama Tugas',
                      icon: Icons.assignment_rounded,
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                    const SizedBox(height: 15),
                    // Description
                    _buildAnimatedTextField(
                      controller: _assignmentDescriptionTextEditingController,
                      label: 'Deskripsi Tugas',
                      icon: Icons.description_rounded,
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Date & Time Section
                _buildLuxurySection(
                  title: "Jadwal Tugas",
                  subtitle:
                      "Tentukan waktu mulai, berakhir, dan deadline pengumpulan",
                  icon: Icons.schedule_rounded,
                  gradient: [_burgundy, _deepMaroon],
                  children: [
                    _buildDateTimeSection(),
                  ],
                ),

                const SizedBox(height: 20),

                // Scoring Section
                _buildLuxurySection(
                  title: "Penilaian",
                  subtitle: "Sistem poin dan aturan pengumpulan ulang",
                  icon: Icons.grade_rounded,
                  gradient: [_burgundy, _deepMaroon],
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnimatedTextField(
                            controller: _assignmentPointsTextEditingController,
                            label: 'Poin Max',
                            icon: Icons.star_rounded,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAnimatedTextField(
                            controller: _minPointsTextEditingController,
                            label: 'Poin Minim',
                            icon: Icons.star_border_rounded,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildAnimatedTextField(
                      controller: _extraResubmissionDaysTextEditingController,
                      label: 'Pengumpulan Ulang',
                      icon: Icons.refresh_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Answer Type Section
                _buildAnswerTypeSection(),

                const SizedBox(height: 24),

                // Attachment Section
                _buildAttachmentSection(),

                const SizedBox(height: 24),

                // Submit Button
                _buildSubmitButton(),

                const SizedBox(height: 100), // Bottom spacing
              ],
            ),
          );
        }

        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_deepMaroon),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super
        .initState(); // Initialize the animation controller for the modern app bar
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _fabAnimationController.repeat();

    // Add EditAssignment state listener
    _editAssignmentSub =
        context.read<EditAssignmentCubit>().stream.listen((state) {
      if (state is EditAssignmentSuccess) {
        setState(() {
          _assignmentNameTextEditingController.text =
              widget.assignment?.name ?? '';
        });
      }
    });

    // Initialize dates from existing assignment if editing
    if (widget.assignment != null) {
      startDate = widget.assignment!.startDate;
      endDate = widget.assignment!.endDate;

      // Update the text controllers with formatted dates
      _startDateTextEditingController.text =
          DateFormat('dd-MM-yyyy').format(widget.assignment!.startDate);
      _endDateTextEditingController.text =
          DateFormat('dd-MM-yyyy').format(widget.assignment!.endDate);

      // Set description from existing assignment
      _assignmentDescriptionTextEditingController.text =
          widget.assignment!.description;

      // Set grade level from selected class section
      if (widget.selectedClassSection != null) {
        // We'll set the grade level after we fetch the grade levels
        // This will be handled in the Future.delayed section
      }
    }

    _isTextAnswerAllowed = widget.assignment?.text == "1";
    _isFileAnswerAllowed = widget.assignment?.acceptedFile.isNotEmpty ?? false;

    if (_isFileAnswerAllowed && widget.assignment != null) {
      for (var fileType in fileTypes) {
        fileType.isSelected = widget.assignment!.acceptedFile
            .contains(fileType.name.toLowerCase());
      }
    }

    _loadFileTypes().then((_) {
      if (widget.assignment != null) {
        setState(() {
          for (var type in fileTypes) {
            type.isSelected = widget.assignment!.acceptedFile
                .map((e) => e.toLowerCase())
                .contains(type.name.toLowerCase());
          }
        });
      }
    });
    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<GradeLevelCubit>().getGradeLevels();

        // Set grade level after data is loaded
        if (widget.selectedClassSection != null) {
          // Listen to grade level changes to set initial value
          _gradeLevelSub =
              context.read<GradeLevelCubit>().stream.listen((gradeLevelState) {
            if (gradeLevelState is GradeLevelFetchSuccess &&
                _selectedGradeLevel == null) {
              final matchingGradeLevel = gradeLevelState.gradeLevels
                  .where((gradeLevel) =>
                      gradeLevel.id ==
                      widget.selectedClassSection!.gradeLevelId)
                  .firstOrNull;
              if (matchingGradeLevel != null && mounted) {
                setState(() {
                  _selectedGradeLevel = matchingGradeLevel;
                  // Initialize tiered dropdown selections based on selected class section
                  selectedTingkatan = matchingGradeLevel.name;
                });
              }
            }
          });
        }

        context
            .read<ClassSectionsAndSubjectsCubit>()
            .getClassSectionsAndSubjects();

        // Initialize class section and subject selections if provided
        if (widget.selectedClassSection != null) {
          selectedKelas = widget.selectedClassSection!.fullName;
          _selectedClassSection = widget.selectedClassSection;
          // Fetch subjects for the selected class section
          changeSelectedClassSection(_selectedClassSection,
              fetchNewSubjects: true);
        }
        if (widget.selectedSubject != null) {
          selectedMapel =
              widget.selectedSubject!.subject.getSybjectNameWithType();
        }
      }
    });

    // Initialize file types from saved assignment
    if (widget.assignment != null) {
      final savedTypes = widget.assignment!.acceptedFile;
      for (var type in fileTypes) {
        type.isSelected = savedTypes.contains(type.name.toLowerCase());
      }
    }

    // Initialize animation controllers
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();

    // Add pulse animation controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _editAssignmentSub?.cancel();
    _gradeLevelSub?.cancel();
    _fabAnimationController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _assignmentNameTextEditingController.dispose();
    _assignmentDescriptionTextEditingController.dispose();
    _assignmentPointsTextEditingController.dispose();
    _extraResubmissionDaysTextEditingController.dispose();
    _minPointsTextEditingController.dispose();
    _startDateTextEditingController.dispose();
    _endDateTextEditingController.dispose();
    _maxFileSizeTextEditingController.dispose();
    _maxFileTextEditingController.dispose();
    super.dispose();
  }

  Future<void> _loadFileTypes() async {
    try {
      final types = await AssignmentRepository().fetchAssignmentFileTypes();
      setState(() {
        fileTypes = types;
      });
    } catch (e) {
      if (!mounted) return;
      Utils.showSnackBar(
        context: context,
        message: e.toString(),
      );
    }
  }

  Future<void> _addFiles() async {
    debugPrint(
        '?? [ASSIGNMENT SCREEN] Memulai upload file dengan kompresi otomatis');

    // Gunakan mixin untuk pick dan kompres otomatis dengan loading dialog
    final compressedFiles = await pickAndCompressFiles(
      allowMultiple: true,
      maxSizeInMB: 0.5, // Target 500KB
      forceCompress: true,
      context: context,
    );

    if (compressedFiles != null && compressedFiles.isNotEmpty) {
      // Convert File to PlatformFile for compatibility
      for (final file in compressedFiles) {
        final fileSize = await file.length();
        final fileName = file.path.split('/').last;

        debugPrint('? [ASSIGNMENT SCREEN] File berhasil diproses: $fileName');
        debugPrint(
            '   ?? Ukuran final: ${OptimizedFileCompressionUtils.formatFileSize(fileSize)}');

        final platformFile = PlatformFile(
          name: fileName,
          size: fileSize,
          path: file.path,
        );

        uploadedFiles.add(platformFile);
      }
      setState(() {});
    } else {
      debugPrint(
          '? [ASSIGNMENT SCREEN] Tidak ada file yang dipilih atau diproses');
    }
  }

  Future<void> openDatePicker() async {
    final temp = await Utils.openDatePicker(context: context);
    if (temp != null) {
      dueDate = temp;
      setState(() {});
    }
  }

  Future<void> openTimePicker() async {
    final temp = await Utils.openTimePicker(context: context);
    if (temp != null) {
      dueTime = temp;
      setState(() {});
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    startDate = (startDate ?? DateTime.now()).isBefore(DateTime.now())
        ? DateTime.now()
        : startDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
        _startDateTextEditingController.text =
            DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != endDate) {
      setState(() {
        endDate = picked;
        _endDateTextEditingController.text =
            DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  void showErrorMessage(String errorMessageKey) {
    Utils.showSnackBar(
      context: context,
      message: errorMessageKey,
    );
  }

  void changeSelectedGradeLevel(GradeLevel? gradeLevel) {
    if (_selectedGradeLevel != gradeLevel) {
      _selectedGradeLevel = gradeLevel;
      // Reset class section and subject when grade level changes
      _selectedClassSection = null;
      _selectedSubject = null;

      setState(() {});

      // Re-fetch classes for the selected grade level
      if (_selectedGradeLevel != null) {
        context
            .read<ClassSectionsAndSubjectsCubit>()
            .getClassSectionsAndSubjects(gradeLevelId: _selectedGradeLevel!.id);
      } else {
        // If no grade level selected, show all classes
        context
            .read<ClassSectionsAndSubjectsCubit>()
            .getClassSectionsAndSubjects();
      }
    }
  }

  void changeSelectedClassSection(ClassSection? classSection,
      {bool fetchNewSubjects = true}) {
    if (_selectedClassSection != classSection) {
      _selectedClassSection = classSection;
      //fetching new subjects after user changes the selected class
      if (fetchNewSubjects && _selectedClassSection != null) {
        context
            .read<ClassSectionsAndSubjectsCubit>()
            .getNewSubjectsFromSelectedClassSectionIndex(
                newClassSectionId: classSection?.id ?? 0)
            .then((value) {
          if (mounted) {
            if (context.read<ClassSectionsAndSubjectsCubit>().state
                is ClassSectionsAndSubjectsFetchSuccess) {
              final successState = (context
                  .read<ClassSectionsAndSubjectsCubit>()
                  .state as ClassSectionsAndSubjectsFetchSuccess);
              // Only auto-select subject if none was passed from previous screen
              if (widget.selectedSubject == null) {
                changeSelectedTeacherSubject(successState.subjects.firstOrNull);
              }
            }
          }
        });
      }
      setState(() {});
    }
  }

  void changeSelectedTeacherSubject(TeacherSubject? teacherSubject,
      {bool fetchNewLessons = true}) {
    if (_selectedSubject != teacherSubject) {
      _selectedSubject = teacherSubject;
      setState(() {});
    }
  }

  void _showOverlayMessage(
      {required BuildContext context, required String message}) {
    OverlayEntry overlayEntry;

    // Determine the message text based on the message key
    String displayMessage;
    if (message == assignmentEditedSuccessfullyKey) {
      displayMessage = "Tugas diperbarui";
    } else {
      displayMessage = "Tugas Ditambahkan";
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).size.height * 0.1,
        width: MediaQuery.of(context).size.width,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                            spreadRadius: -2,
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 24),
                          const SizedBox(width: 16),
                          Text(
                            displayMessage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  void createAssignment() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_selectedGradeLevel == null) {
      showErrorMessage("Silakan pilih tingkatan terlebih dahulu");
      return;
    }

    if (_selectedClassSection == null) {
      showErrorMessage(noClassSectionSelectedKey);
      return;
    }

    if (_selectedSubject == null) {
      showErrorMessage(noSubjectSelectedKey);
      return;
    }

    if (_assignmentNameTextEditingController.text.trim().isEmpty) {
      showErrorMessage("Kolom Nama Tugas wajib diisi.");
      return;
    }

    if (_assignmentDescriptionTextEditingController.text.trim().isEmpty) {
      showErrorMessage("Kolom Deskripsi Tugas wajib diisi.");
      return;
    }

    if (_assignmentPointsTextEditingController.text.trim().isEmpty) {
      showErrorMessage("Kolom Poin Tugas wajib diisi.");
      return;
    }

    if (_assignmentPointsTextEditingController.text.length >= 10) {
      showErrorMessage(invalidPointsLengthKey);
      return;
    }

    // Validasi poin minim tidak boleh lebih tinggi dari poin maksimal
    final maxPoints =
        int.tryParse(_assignmentPointsTextEditingController.text.trim()) ?? 0;
    final minPoints =
        int.tryParse(_minPointsTextEditingController.text.trim()) ?? 0;
    if (minPoints > maxPoints) {
      showErrorMessage(
          "Poin minimal tidak boleh lebih tinggi dari poin maksimal.");
      return;
    }

    if (dueDate == null) {
      showErrorMessage("Kolom Tanggal Tenggat wajib diisi.");
      return;
    }
    if (dueTime == null) {
      showErrorMessage("Kolom Waktu Tenggat wajib diisi.");
      return;
    }
    if (startDate == null) {
      // Add this line
      showErrorMessage("Kolom Tanggal Mulai Penugasan wajib diisi.");
      return;
    }

    if (endDate == null) {
      // Add this line
      showErrorMessage("Kolom Tanggal Akhir Penugasan wajib diisi.");
      return;
    }

    // Add this validation instead if needed
    if (_extraResubmissionDaysTextEditingController.text.trim().isNotEmpty) {
      final resubmissionCount = int.tryParse(
              _extraResubmissionDaysTextEditingController.text.trim()) ??
          0;
      if (resubmissionCount < 0) {
        showErrorMessage("Jumlah pengumpulan ulang tidak boleh negatif");
        return;
      }
    }

    // Ensure at least one answer type is selected (text or file) - REQUIRED
    if (!_isTextAnswerAllowed && !_isFileAnswerAllowed) {
      showErrorMessage(
          "Jenis jawaban wajib dipilih. Pilih minimal satu antara Teks atau File.");
      return;
    }

    // Get selected file types
    final selectedFileTypes = _isFileAnswerAllowed
        ? fileTypes
            .where((type) => type.isSelected)
            .map((type) => type.name)
            .toList()
        : [];

    // Prepare text value
    final textValue = _isTextAnswerAllowed ? "1" : "0";

    if (_isFileAnswerAllowed && selectedFileTypes.isEmpty) {
      showErrorMessage("Pilih minimal satu jenis file yang diizinkan");
      return;
    }

    context.read<CreateAssignmentCubit>().createAssignment(
          classSectionId: _selectedClassSection?.id ?? 0,
          classSubjectId: _selectedSubject?.classSubjectId ?? 0,
          name: _assignmentNameTextEditingController.text.trim(),
          dateTime:
              "${DateFormat('dd-MM-yyyy').format(dueDate!).toString()} ${dueTime!.hour}:${dueTime!.minute}",
          startDate: DateFormat('dd-MM-yyyy')
              .format(startDate!)
              .toString(), // Add this line
          endDate: DateFormat('dd-MM-yyyy')
              .format(endDate!)
              .toString(), // Add this line
          extraDayForResubmission:
              _extraResubmissionDaysTextEditingController.text.trim(),
          description: _assignmentDescriptionTextEditingController.text.trim(),
          points: _assignmentPointsTextEditingController.text.trim(),
          minPoints:
              _minPointsTextEditingController.text.trim(), // Add this line
          maxFile:
              _maxFileSizeTextEditingController.text.trim(), // Add this line
          resubmission: (int.tryParse(
                      _extraResubmissionDaysTextEditingController.text
                          .trim()) ??
                  0) >
              0,
          file: uploadedFiles,
          acceptedFile: selectedFileTypes.cast<String>(),
          text: textValue,
        );
  }

  void editAssignment() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_selectedGradeLevel == null) {
      showErrorMessage("Silakan pilih tingkatan terlebih dahulu");
      return;
    }

    if (_assignmentNameTextEditingController.text.trim().isEmpty) {
      showErrorMessage("Kolom Nama Tugas wajib diisi.");
      return;
    }

    if (_assignmentDescriptionTextEditingController.text.trim().isEmpty) {
      showErrorMessage("Kolom Deskripsi Tugas wajib diisi.");
      return;
    }

    if (_assignmentPointsTextEditingController.text.trim().isEmpty) {
      showErrorMessage("Kolom Poin Tugas wajib diisi.");
      return;
    }

    if (dueDate == null) {
      showErrorMessage("Kolom Tanggal Tenggat wajib diisi.");
      return;
    }
    if (_assignmentPointsTextEditingController.text.length >= 10) {
      return;
    }

    // Validasi poin minim tidak boleh lebih tinggi dari poin maksimal
    final maxPoints =
        int.tryParse(_assignmentPointsTextEditingController.text.trim()) ?? 0;
    final minPoints =
        int.tryParse(_minPointsTextEditingController.text.trim()) ?? 0;
    if (minPoints > maxPoints) {
      showErrorMessage(
          "Poin minimal tidak boleh lebih tinggi dari poin maksimal.");
      return;
    }

    if (dueTime == null) {
      showErrorMessage("Kolom Waktu Tenggat wajib diisi.");
      return;
    }
    if (startDate == null) {
      showErrorMessage("Kolom Tanggal Mulai Penugasan wajib diisi.");
      return;
    }
    if (endDate == null) {
      showErrorMessage("Kolom Tanggal Akhir Penugasan wajib diisi.");
      return;
    }

    // Add this validation instead if needed
    if (_extraResubmissionDaysTextEditingController.text.trim().isNotEmpty) {
      final resubmissionCount = int.tryParse(
              _extraResubmissionDaysTextEditingController.text.trim()) ??
          0;
      if (resubmissionCount < 0) {
        showErrorMessage("Jumlah pengumpulan ulang tidak boleh negatif");
        return;
      }
    }

    // Validasi required: minimal satu jenis jawaban harus dipilih
    if (!_isTextAnswerAllowed && !_isFileAnswerAllowed) {
      showErrorMessage(
          "Jenis jawaban wajib dipilih. Pilih minimal satu antara Teks atau File.");
      return;
    }

    debugPrint("File allowed?");
    debugPrint(_isFileAnswerAllowed.toString());

    final selectedFileTypes = _isFileAnswerAllowed
        ? fileTypes
            .where((type) => type.isSelected)
            .map((type) => type.name)
            .toList()
        : [];

    if (_isFileAnswerAllowed && selectedFileTypes.isEmpty) {
      showErrorMessage("Pilih minimal satu jenis file yang diizinkan");
      return;
    }

    // Format dates properly for API
    final formattedStartDate = DateFormat('dd-MM-yyyy').format(startDate!);
    final formattedEndDate = DateFormat('dd-MM-yyyy').format(endDate!);
    final textValue = _isTextAnswerAllowed ? "1" : "0";

    debugPrint("Must Upload");
    debugPrint(uploadedFiles.toString());
    debugPrint("====");
    debugPrint(_assignmentUploadedFilesEditingController.toString());

    context.read<EditAssignmentCubit>().editAssignment(
          classSelectionId: _selectedClassSection?.id ?? 0,
          classSubjectId: _selectedSubject?.classSubjectId ?? 0,
          name: _assignmentNameTextEditingController.text.trim(),
          dateTime:
              "${DateFormat('dd-MM-yyyy').format(dueDate!).toString()} ${dueTime!.hour}:${dueTime!.minute}",
          extraDayForResubmission:
              _extraResubmissionDaysTextEditingController.text.trim(),
          description: _assignmentDescriptionTextEditingController.text.trim(),
          points: _assignmentPointsTextEditingController.text.trim(),
          minPoints: _minPointsTextEditingController.text.trim(),
          resubmission:
              (_extraResubmissionDaysTextEditingController.text.trim() != '' &&
                      _extraResubmissionDaysTextEditingController.text.trim() !=
                          '0' &&
                      int.tryParse(_extraResubmissionDaysTextEditingController
                              .text
                              .trim()) !=
                          0)
                  ? 1
                  : 0,
          filePaths: uploadedFiles,
          studyMaterials: _assignmentUploadedFilesEditingController,
          assignmentId: widget.assignment!.id,
          // Update these lines to use the actual DateTime objects
          startDate: formattedStartDate,
          endDate: formattedEndDate,
          acceptedFile: selectedFileTypes.cast<String>(),
          text: textValue,
          maxFile:
              int.tryParse(_maxFileSizeTextEditingController.text.trim()) ?? 0,
        );
  }

  // ?? PREMIUM SUBMIT BUTTON - Luxury design for action button
  Widget _buildSubmitButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: widget.assignment != null
          ? BlocConsumer<EditAssignmentCubit, EditAssignmentState>(
              listener: (context, state) {
                if (state is EditAssignmentSuccess) {
                  Get.back(result: true);
                  _showOverlayMessage(
                    context: context,
                    message: assignmentEditedSuccessfullyKey,
                  );
                } else if (state is EditAssignmentFailure) {
                  Utils.showSnackBar(
                    context: context,
                    message: state.errorMessage,
                  );
                }
              },
              builder: (context, state) {
                return _buildLuxuryButton(
                  onTap: () {
                    if (state is EditAssignmentInProgress) return;
                    editAssignment();
                  },
                  isLoading: state is EditAssignmentInProgress,
                  title: 'Perbarui Tugas',
                  subtitle: 'Simpan perubahan tugas',
                  icon: Icons.update_rounded,
                );
              },
            )
          : BlocConsumer<CreateAssignmentCubit, CreateAssignmentState>(
              listener: (context, state) {
                if (state is CreateAssignmentSuccess) {
                  _showOverlayMessage(
                    context: context,
                    message: assignmentAddedSuccessfullyKey,
                  );
                  // Reset form fields
                  _assignmentNameTextEditingController.text = "";
                  _assignmentDescriptionTextEditingController.text = "";
                  _assignmentPointsTextEditingController.text = "";
                  _extraResubmissionDaysTextEditingController.text = "";
                  _minPointsTextEditingController.text = "";
                  _maxFileSizeTextEditingController.text = "";
                  // Reset dates and time
                  dueDate = null;
                  dueTime = null;
                  startDate = null;
                  endDate = null;
                  // Reset answer types
                  _isTextAnswerAllowed = false;
                  _isFileAnswerAllowed = false;
                  // Reset file selections
                  for (var type in fileTypes) {
                    type.isSelected = false;
                  }
                  // Reset uploaded files
                  uploadedFiles = [];
                  assignmentAttachments = [];
                  refreshAssignmentsInPreviousPage = true;
                  setState(() {});
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  });
                } else if (state is CreateAssignmentFailure) {
                  Utils.showSnackBar(
                    context: context,
                    message: state.errorMessage,
                  );
                }
              },
              builder: (context, state) {
                return _buildLuxuryButton(
                  onTap: () {
                    if (state is CreateAssignmentInProcess) return;
                    createAssignment();
                  },
                  isLoading: state is CreateAssignmentInProcess,
                  title: 'Buat Tugas',
                  subtitle: 'Publikasikan tugas baru',
                  icon: Icons.add_task_rounded,
                );
              },
            ),
    );
  }

  // LUXURY BUTTON - Ultra premium button design
  Widget _buildLuxuryButton({
    required VoidCallback onTap,
    required bool isLoading,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_deepMaroon, _softMaroon],
            stops: [0.0, 1.0],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _deepMaroon.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading) ...[
                    // Loading State
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Memproses...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mohon tunggu sebentar',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Normal State
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Animated Text Field - Similar to createOnlineExam.dart
  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLines = 1,
    int? minLines,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    Color? iconColor,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextAlignVertical? textAlignVertical,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator ?? (v) => v!.isEmpty ? 'Required' : null,
      onChanged: onChanged,
      textAlignVertical: textAlignVertical,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade500,
        ),
        prefixIcon: Icon(
          icon,
          color: iconColor ?? _deepMaroon,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _deepMaroon),
        ),
      ),
    );
  }

  // Subject Selection Widget - Similar to createOnlineExam.dart
  Widget _buildSubjectSelection() {
    return BlocBuilder<ClassSectionsAndSubjectsCubit,
        ClassSectionsAndSubjectsState>(
      builder: (context, state) {
        if (state is ClassSectionsAndSubjectsFetchSuccess) {
          // Get grade levels from GradeLevelCubit
          final gradeLevelState = context.watch<GradeLevelCubit>().state;

          if (gradeLevelState is GradeLevelFetchSuccess) {
            // Build lists for dropdowns
            tingkatanList = gradeLevelState.gradeLevels
                .map((e) => e.name ?? "")
                .where((t) => t.isNotEmpty)
                .toSet()
                .toList()
              ..sort();

            kelasList = selectedTingkatan == null
                ? []
                : state.classSections
                    .where((e) {
                      final gradeLevelMatches = gradeLevelState.gradeLevels
                          .where((gl) => gl.id == e.gradeLevelId);
                      if (gradeLevelMatches.isEmpty) {
                        debugPrint(
                            '[ASSIGNMENT SCREEN] Warning: Grade level not found for classSection ${e.fullName} (id: ${e.id}, gradeLevelId: ${e.gradeLevelId})');
                        return false;
                      }
                      return gradeLevelMatches.first.name == selectedTingkatan;
                    })
                    .map((e) => e.fullName ?? "")
                    .toSet()
                    .toList()
              ..sort();

            // Build mapelList (subjects). If the cubit hasn't loaded
            // subjects yet (state.subjects is empty) but the screen was
            // opened with a `selectedSubject` passed in from previous
            // screen, use that as a fallback so the currently-selected
            // subject still appears in the dropdown options.
            if (selectedKelas == null) {
              mapelList = [];
            } else if (state.subjects.isEmpty) {
              // Fallback: use incoming selectedSubject if it belongs to
              // the selected classSection so users still see the value.
              if (_selectedSubject != null &&
                  _selectedClassSection != null &&
                  _selectedSubject!.classSection.id ==
                      _selectedClassSection!.id) {
                mapelList = [
                  _selectedSubject!.subject.getSybjectNameWithType()
                ];
                debugPrint(
                    '[ASSIGNMENT SCREEN] subjects list empty in state; using fallback selectedSubject (${mapelList.first}) for dropdown');
              } else {
                mapelList = [];
              }
            } else {
              mapelList = state.subjects
                  .where((e) => e.classSection.id == _selectedClassSection?.id)
                  .map((e) => e.subject.getSybjectNameWithType())
                  .toSet()
                  .toList()
                ..sort();
            }

            return Column(
              children: [
                // Tingkatan Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedTingkatan,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.layers, color: _deepMaroon),
                    labelText: 'Pilih Tingkatan',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: tingkatanList
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedTingkatan = v;
                      selectedKelas = null;
                      selectedMapel = null;
                      _selectedSubject = null;
                      _selectedClassSection = null;
                    });
                  },
                  isExpanded: true,
                  hint: const Text('Pilih Tingkatan'),
                ),
                if (selectedTingkatan != null) ...[
                  const SizedBox(height: 12),
                  // Kelas Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedKelas,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.class_, color: _deepMaroon),
                      labelText: 'Pilih Kelas',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: kelasList
                        .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedKelas = v;
                        selectedMapel = null;
                        _selectedSubject = null;
                        _selectedClassSection = null;
                      });

                      // Set selected class section
                      final classMatches = state.classSections
                          .where((e) => e.fullName == v)
                          .toList();
                      if (classMatches.isNotEmpty) {
                        _selectedClassSection = classMatches.first;
                        changeSelectedClassSection(_selectedClassSection,
                            fetchNewSubjects: true);
                      }
                    },
                    isExpanded: true,
                    hint: const Text('Pilih Kelas'),
                  ),
                ],
                if (selectedKelas != null) ...[
                  const SizedBox(height: 12),
                  // Mata Pelajaran Dropdown - Show loading if subjects are being fetched
                  if (context.watch<ClassSectionsAndSubjectsCubit>().state
                      is ClassSectionsAndSubjectsFetchInProgress)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(_deepMaroon),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Memuat mata pelajaran...',
                            style: TextStyle(
                              color: _dustyRose,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (mapelList.isEmpty)
                    // Show message when there are no subjects available for the
                    // selected class and also log diagnostic information so
                    // developers can debug why subjects are missing.
                    Builder(builder: (ctx) {
                      // Schedule logs after this frame to avoid side-effects
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        try {
                          // Collect diagnostic details
                          final gradeSelected = selectedTingkatan ?? '<none>';
                          final kelasSelected = selectedKelas ?? '<none>';
                          final mapelSelected = selectedMapel ?? '<none>';
                          final classSectionId =
                              _selectedClassSection?.id?.toString() ?? '<none>';

                          final totalClassSections = state.classSections.length;
                          final totalSubjects = state.subjects.length;

                          // Subjects that belong to the selected classSection
                          final filteredSubjects = state.subjects
                              .where((e) =>
                                  e.classSection.id ==
                                  _selectedClassSection?.id)
                              .map((e) => e.subject.getSybjectNameWithType())
                              .toList();

                          debugPrint('--- [ASSIGNMENT SCREEN DIAGNOSTICS] ---');
                          debugPrint(
                              'Selected Tingkatan: $gradeSelected, Selected Kelas: $kelasSelected');
                          debugPrint(
                              'Selected ClassSection id: $classSectionId');
                          debugPrint('Selected Mapel (name): $mapelSelected');
                          debugPrint(
                              'Total classSections in state: $totalClassSections');
                          debugPrint('Total subjects in state: $totalSubjects');
                          debugPrint(
                              'Filtered subjects for selected classSection (count: ${filteredSubjects.length}):');
                          for (var s in filteredSubjects) {
                            debugPrint(' - $s');
                          }
                          if (filteredSubjects.isEmpty) {
                            debugPrint(
                                'NOTE: filter produced no results. Possible causes: selected classSection is null, classSection IDs do not match between classSections and subjects, or grade level/tingkatan mismatch.');
                          }
                          debugPrint('--- [END DIAGNOSTICS] ---');
                        } catch (e, st) {
                          debugPrint(
                              'Error while logging diagnostics in teacherAddEditAssignmentScreen: $e\n$st');
                        }
                      });

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.grey.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tidak ada mata pelajaran tersedia untuk kelas ini',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                  else
                    DropdownButtonFormField<String>(
                      initialValue: selectedMapel,
                      decoration: InputDecoration(
                        prefixIcon:
                            const Icon(Icons.menu_book, color: _deepMaroon),
                        labelText: 'Pilih Mata Pelajaran',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: mapelList
                          .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedMapel = v;
                        });

                        // Set selected subject
                        final subjectMatches = state.subjects
                            .where((e) =>
                                e.classSection.id ==
                                    _selectedClassSection?.id &&
                                e.subject.getSybjectNameWithType() == v)
                            .toList();
                        if (subjectMatches.isNotEmpty) {
                          _selectedSubject = subjectMatches.first;
                          changeSelectedTeacherSubject(_selectedSubject);
                        }
                      },
                      isExpanded: true,
                      hint: const Text('Pilih Mata Pelajaran'),
                    ),
                ],
              ],
            );
          }
        }
        return const SizedBox(
          height: 50,
          child: Center(
            child: CircularProgressIndicator(
              color: _deepMaroon,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }

  // LUXURY SECTION BUILDER - Creates stunning sectioned cards (Updated to match createOnlineExam style)
  Widget _buildLuxurySection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 5,
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  color: _deepMaroon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: _deepMaroon,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _deepMaroon,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  // ELEGANT FIELD BUILDER - Creates beautiful input fields
  Widget _buildElegantField(
      String label, String description, IconData icon, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: _deepMaroon.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border:
                  const Border(left: BorderSide(color: _deepMaroon, width: 3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: _deepMaroon, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _deepMaroon,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: _dustyRose,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _blushPink.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  // DATE TIME SECTION - Beautiful date and time pickers
  Widget _buildDateTimeSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAnimatedTextField(
                controller: TextEditingController(
                  text: startDate != null
                      ? DateFormat('dd-MM-yyyy').format(startDate!)
                      : '',
                ),
                label: 'Tgl Mulai',
                icon: Icons.calendar_today,
                onTap: () => _selectStartDate(context),
                readOnly: true,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildAnimatedTextField(
                controller: TextEditingController(
                  text: endDate != null
                      ? DateFormat('dd-MM-yyyy').format(endDate!)
                      : '',
                ),
                label: 'Tgl Akhir',
                icon: Icons.calendar_today,
                onTap: () => _selectEndDate(context),
                readOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildAnimatedTextField(
                controller: TextEditingController(
                  text: dueDate != null
                      ? DateFormat('dd-MM-yyyy').format(dueDate!)
                      : '',
                ),
                label: 'Tenggat',
                icon: Icons.calendar_today,
                onTap: openDatePicker,
                readOnly: true,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildAnimatedTextField(
                controller: TextEditingController(
                  text: dueTime != null
                      ? '${dueTime!.hour.toString().padLeft(2, '0')}:${dueTime!.minute.toString().padLeft(2, '0')}'
                      : '',
                ),
                label: 'Jam Deadline',
                icon: Icons.access_time,
                onTap: openTimePicker,
                readOnly: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ANSWER TYPE SECTION - Interactive answer type selection
  Widget _buildAnswerTypeSection() {
    return _buildLuxurySection(
      title: "Jenis Jawaban *",
      subtitle: "Cara Siswa Menjawab (Wajib pilih minimal satu)",
      icon: Icons.quiz_rounded,
      gradient: [_burgundy, _deepMaroon],
      children: [
        // Answer Type Cards with Required Indicator
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_champagne.withValues(alpha: 0.6), _pearl],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _blushPink.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Wajib pilih minimal satu jenis jawaban",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                  child: _buildAnswerTypeCard(
                "Teks *",
                "Jawaban berupa teks",
                Icons.text_fields_rounded,
                _isTextAnswerAllowed,
                () => setState(
                    () => _isTextAnswerAllowed = !_isTextAnswerAllowed),
              )),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildAnswerTypeCard(
                "File *",
                "Upload dokumen",
                Icons.upload_file_rounded,
                _isFileAnswerAllowed,
                () => setState(
                    () => _isFileAnswerAllowed = !_isFileAnswerAllowed),
              )),
            ],
          ),
        ),

        // File Type Selection
        if (_isFileAnswerAllowed) ...[
          const SizedBox(height: 28),
          _buildFileTypeSelection(),
          const SizedBox(height: 24),
          _buildElegantField(
            "Ukuran Maksimal File",
            "Batas ukuran file dalam MB",
            Icons.storage_rounded,
            CustomTextFieldContainer(
              keyboardType: TextInputType.number,
              textEditingController: _maxFileSizeTextEditingController,
              hintTextKey: 'Contoh: 10 MB',
              backgroundColor: _pearl,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
        ],
      ],
    );
  }

  // ANSWER TYPE CARD - Beautiful interactive cards
  Widget _buildAnswerTypeCard(String title, String description, IconData icon,
      bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_deepMaroon, _softMaroon],
                )
              : const LinearGradient(
                  colors: [Colors.white, _pearl],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _deepMaroon : _blushPink.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _deepMaroon.withValues(alpha: 0.25)
                  : _blushPink.withValues(alpha: 0.1),
              blurRadius: isSelected ? 15 : 8,
              offset: Offset(0, isSelected ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : _dustyRose.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : _deepMaroon,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : _deepMaroon,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.8)
                    : _dustyRose,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FILE TYPE SELECTION - Elegant file type chips
  Widget _buildFileTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  _dustyRose.withValues(alpha: 0.15),
                  _blushPink.withValues(alpha: 0.1)
                ]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.folder_rounded,
                  size: 18, color: _deepMaroon),
            ),
            const SizedBox(width: 12),
            const Text(
              "Format File yang Diizinkan",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _deepMaroon,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_pearl, _champagne.withValues(alpha: 0.5)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _blushPink.withValues(alpha: 0.3)),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                fileTypes.map((type) => _buildFileTypeChip(type)).toList(),
          ),
        ),
      ],
    );
  }

  // FILE TYPE CHIP - Beautiful file type selectors
  Widget _buildFileTypeChip(AssignmentFileType type) {
    return GestureDetector(
      onTap: () => setState(() => type.isSelected = !type.isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: type.isSelected
              ? const LinearGradient(colors: [_deepMaroon, _softMaroon])
              : const LinearGradient(colors: [Colors.white, _roseMist]),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: type.isSelected
                ? _deepMaroon
                : _dustyRose.withValues(alpha: 0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: type.isSelected
                  ? _deepMaroon.withValues(alpha: 0.3)
                  : _dustyRose.withValues(alpha: 0.1),
              blurRadius: type.isSelected ? 8 : 4,
              offset: Offset(0, type.isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Text(
          type.name.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: type.isSelected ? Colors.white : _deepMaroon,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ATTACHMENT SECTION - Modern file attachment UI
  Widget _buildAttachmentSection() {
    return _buildLuxurySection(
      title: "Lampiran Tugas",
      subtitle: "File Pendukung",
      icon: Icons.attach_file_rounded,
      gradient: [_burgundy, _deepMaroon],
      children: [
        // Info Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_champagne.withValues(alpha: 0.6), _pearl],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _blushPink.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: [_dustyRose, _blushPink]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Format: PDF, JPEG, PNG, DOCX, MP4",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _deepMaroon,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Current Attachments
        if (widget.assignment != null && assignmentAttachments.isNotEmpty) ...[
          _buildAttachmentList(
              "Lampiran Saat Ini",
              assignmentAttachments
                  .map(
                    (attachment) => StudyMaterialContainer(
                      onDeleteStudyMaterial: (fileId) {
                        assignmentAttachments
                            .removeWhere((element) => element.id == fileId);
                        refreshAssignmentsInPreviousPage = true;
                        setState(() {});
                      },
                      showOnlyStudyMaterialTitles: true,
                      showEditAndDeleteButton: true,
                      studyMaterial: attachment,
                    ),
                  )
                  .toList()),
          const SizedBox(height: 20),
        ],

        // New Attachments
        if (uploadedFiles.isNotEmpty) ...[
          _buildAttachmentList(
              "Lampiran Baru",
              uploadedFiles
                  .asMap()
                  .entries
                  .map(
                    (entry) => CustomFileContainer(
                      backgroundColor: _pearl,
                      onDelete: () {
                        uploadedFiles.removeAt(entry.key);
                        setState(() {});
                      },
                      title: entry.value.name,
                    ),
                  )
                  .toList()),
          const SizedBox(height: 20),
        ],

        // Add Files Button
        GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            _addFiles();
          },
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _deepMaroon.withValues(alpha: 0.1),
                  _dustyRose.withValues(alpha: 0.05)
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: _deepMaroon.withValues(alpha: 0.3), width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_deepMaroon, _softMaroon]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Tambah Lampiran",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _deepMaroon,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ?? ATTACHMENT LIST - Organized file lists
  Widget _buildAttachmentList(String title, List<Widget> attachments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  _dustyRose.withValues(alpha: 0.15),
                  _blushPink.withValues(alpha: 0.1)
                ]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.folder_outlined,
                  size: 16, color: _deepMaroon),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _deepMaroon,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...attachments.map((attachment) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: attachment,
            )),
      ],
    );
  }
}

