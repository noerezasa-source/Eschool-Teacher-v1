import 'package:eschool_saas_staff/cubits/teacherAcademics/classSectionsAndSubjects.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/lesson/lessonsCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/topic/createTopicCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/topic/editTopicCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/gradeLevelCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/academic/lesson.dart';
import 'package:eschool_saas_staff/data/models/academic/pickedStudyMaterial.dart';
import 'package:eschool_saas_staff/data/models/academic/studyMaterial.dart';
import 'package:eschool_saas_staff/data/models/academic/teacherSubject.dart';
import 'package:eschool_saas_staff/data/models/academic/topic.dart';
import 'package:eschool_saas_staff/data/models/academic/gradeLevel.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/addStudyMaterialBottomsheet.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/addedStudyMaterialFileContainer.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/studyMaterialContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/errorContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionBottomsheet.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:eschool_saas_staff/utils/system/optimized_file_compression_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

class TeacherAddEditTopicScreen extends StatefulWidget {
  final Topic? topic;
  final ClassSection? selectedClassSection;
  final TeacherSubject? selectedSubject;
  final Lesson? selectedLesson;
  static Widget getRouteInstance() {
    final arguments = Get.arguments as Map<String, dynamic>?;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => EditTopicCubit(),
        ),
        BlocProvider(
          create: (context) => CreateTopicCubit(),
        ),
        BlocProvider(
          create: (context) => LessonsCubit(),
        ),
        BlocProvider(
          create: (context) => ClassSectionsAndSubjectsCubit(),
        ),
        BlocProvider(
          create: (context) => GradeLevelCubit(),
        ),
      ],
      child: TeacherAddEditTopicScreen(
        topic: arguments?['topic'],
        selectedClassSection: arguments?['selectedClassSection'],
        selectedSubject: arguments?['selectedSubject'],
        selectedLesson: arguments?['selectedLesson'],
      ),
    );
  }

  static Map<String, dynamic> buildArguments(
      {required Topic? topic,
      required ClassSection? selectedClassSection,
      required TeacherSubject? selectedSubject,
      required Lesson? selectedLesson}) {
    return {
      "topic": topic,
      "selectedClassSection": selectedClassSection,
      "selectedSubject": selectedSubject,
      "selectedLesson": selectedLesson,
    };
  }

  const TeacherAddEditTopicScreen(
      {super.key,
      required this.topic,
      this.selectedClassSection,
      this.selectedSubject,
      this.selectedLesson});

  @override
  State<TeacherAddEditTopicScreen> createState() =>
      _TeacherAddEditTopicScreenState();
}

class _TeacherAddEditTopicScreenState extends State<TeacherAddEditTopicScreen>
    with TickerProviderStateMixin, OptimizedFileCompressionMixin {
  late ClassSection? _selectedClassSection = widget.selectedClassSection;
  late TeacherSubject? _selectedSubject = widget.selectedSubject;
  late Lesson? _selectedLesson = widget.selectedLesson;
  GradeLevel? _selectedGradeLevel;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController
      _fabAnimationController; // Added for CustomModernAppBar

  // Theme colors - Softer Maroon palette
  static const Color _primaryColor = Color(0xFF7A1E23); // Softer deep maroon
  static const Color _accentColor = Color(0xFF9D3C3C); // Softer medium maroon

  //This will determine if need to refresh the previous page
  //topics data. If teacher remove the the any study material
  //so we need to fetch the list again
  late bool refreshTopicsInPreviousPage = false;

  late final TextEditingController _topicNameTextEditingController =
      TextEditingController(
    text: widget.topic?.name,
  );
  late final TextEditingController _topicDescriptionTextEditingController =
      TextEditingController(
    text: widget.topic?.description,
  );

  List<PickedStudyMaterial> _addedStudyMaterials = [];

  late List<StudyMaterial> studyMaterials = widget.topic?.studyMaterials ?? [];
  @override
  void initState() {
    super.initState();
    // Debug: Check study materials
    debugPrint("=== Topic Study Materials Debug ===");
    debugPrint("Topic is null: ${widget.topic == null}");
    debugPrint("Study materials count: ${studyMaterials.length}");
    if (widget.topic != null) {
      debugPrint("Topic name: ${widget.topic!.name}");
      debugPrint(
          "Topic studyMaterials count: ${widget.topic!.studyMaterials.length}");
      for (var material in widget.topic!.studyMaterials) {
        debugPrint(
            "Study Material: ${material.fileName} - Type: ${material.studyMaterialType}");
      }
    }
    debugPrint("================================");

    Future.delayed(Duration.zero, () {
      if (mounted) {
        debugPrint("=== Init Fetch Debug ===");
        debugPrint(
            "Selected class section: ${_selectedClassSection?.fullName}");
        debugPrint("Selected class section ID: ${_selectedClassSection?.id}");
        debugPrint(
            "Selected subject: ${_selectedSubject?.subject.getSybjectNameWithType()}");
        debugPrint("Selected lesson: ${_selectedLesson?.name}");
        debugPrint("========================");
        context.read<GradeLevelCubit>().getGradeLevels();
        context
            .read<ClassSectionsAndSubjectsCubit>()
            .getClassSectionsAndSubjects(
                classSectionId: _selectedClassSection?.id);
        // Fetch lessons if subject is already selected
        if (_selectedSubject != null && _selectedClassSection != null) {
          getLessons();
        }
      }
    }); // Add animation controllers initialization
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();

    // Initialize _pulseController
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseController.repeat(reverse: true);
  
    // Initialize fabAnimationController for CustomModernAppBar
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fabAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _topicNameTextEditingController.dispose();
    _topicDescriptionTextEditingController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _fabAnimationController.dispose(); // Added to dispose the controller
    super.dispose();
  }

  void deleteStudyMaterial(int studyMaterialId) {
    studyMaterials.removeWhere((element) => element.id == studyMaterialId);
    refreshTopicsInPreviousPage = true;
    setState(() {});
  }

  void updateStudyMaterials(StudyMaterial studyMaterial) {
    final studyMaterialIndex =
        studyMaterials.indexWhere((element) => element.id == studyMaterial.id);
    studyMaterials[studyMaterialIndex] = studyMaterial;
    refreshTopicsInPreviousPage = true;
    setState(() {});
  }

  void _addStudyMaterial(PickedStudyMaterial pickedStudyMaterial) {
    setState(() {
      _addedStudyMaterials.add(pickedStudyMaterial);
    });
  }

  void showErrorMessage(String errorMessageKey) {
    Utils.showSnackBar(
      context: context,
      message: errorMessageKey,
    );
  }

  void editTopic() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_topicNameTextEditingController.text.trim().isEmpty) {
      showErrorMessage(pleaseEnterTopicNameKey);
      return;
    }

    if (_topicDescriptionTextEditingController.text.trim().isEmpty) {
      showErrorMessage(pleaseEnterTopicDescriptionKey);
      return;
    }

    context.read<EditTopicCubit>().editTopic(
          topicDescription: _topicDescriptionTextEditingController.text.trim(),
          topicName: _topicNameTextEditingController.text.trim(),
          lessonId: _selectedLesson?.id ?? 0,
          classSectionId: _selectedClassSection?.id ?? 0,
          subjectId: _selectedSubject?.id ?? 0,
          topicId: widget.topic?.id ?? 0,
          files: _addedStudyMaterials,
        );
  }

  void createTopic() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_selectedSubject == null) {
      showErrorMessage(noSubjectSelectedKey);
      return;
    }
    if (_selectedLesson == null) {
      showErrorMessage(noLessonSelectedKey);
      return;
    }
    if (_selectedClassSection == null) {
      showErrorMessage(noClassSectionSelectedKey);
      return;
    }
    if (_topicNameTextEditingController.text.trim().isEmpty) {
      showErrorMessage(pleaseEnterTopicNameKey);
      return;
    }

    if (_topicDescriptionTextEditingController.text.trim().isEmpty) {
      showErrorMessage(pleaseEnterTopicDescriptionKey);
      return;
    }

    context.read<CreateTopicCubit>().createTopic(
          topicName: _topicNameTextEditingController.text.trim(),
          lessonId: _selectedLesson?.id ?? 0,
          classSectionId: _selectedClassSection?.id ?? 0,
          subjectId: _selectedSubject?.id ?? 0,
          topicDescription: _topicDescriptionTextEditingController.text.trim(),
          files: _addedStudyMaterials,
        );
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
            // Remove auto-selection for subjects, let user choose manually
            // Only auto-select if we're editing an existing topic
            if (context.read<ClassSectionsAndSubjectsCubit>().state
                    is ClassSectionsAndSubjectsFetchSuccess &&
                widget.topic != null) {
              final successState = (context
                  .read<ClassSectionsAndSubjectsCubit>()
                  .state as ClassSectionsAndSubjectsFetchSuccess);
              // Only auto-select if we don't have a subject selected yet and we're editing
              if (_selectedSubject == null &&
                  successState.subjects.isNotEmpty) {
                changeSelectedTeacherSubject(successState.subjects.firstOrNull);
              }
            }
          }
        });
      }
      setState(() {});
    }
  }

  void changeSelectedGradeLevel(GradeLevel? gradeLevel) {
    if (_selectedGradeLevel != gradeLevel) {
      _selectedGradeLevel = gradeLevel;

      // Reset selected class, subject, and lesson when grade level changes
      _selectedClassSection = null;
      _selectedSubject = null;
      _selectedLesson = null;

      setState(() {});

      // Re-fetch classes for the selected grade level to filter them
      if (_selectedGradeLevel != null) {
        // Add delay to prevent lag
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            context
                .read<ClassSectionsAndSubjectsCubit>()
                .getClassSectionsAndSubjects(
                    gradeLevelId: _selectedGradeLevel!.id);
          }
        });
      } else {
        // If no grade level selected, show all classes
        context
            .read<ClassSectionsAndSubjectsCubit>()
            .getClassSectionsAndSubjects();
      }
    }
  }

  void changeSelectedTeacherSubject(TeacherSubject? teacherSubject) {
    if (_selectedSubject != teacherSubject) {
      _selectedSubject = teacherSubject;
      // Reset lesson when changing subject
      _selectedLesson = null;
      setState(() {});

      // Add debug log
      debugPrint("=== Subject Changed Debug ===");
      debugPrint(
          "New subject: ${_selectedSubject?.subject.getSybjectNameWithType()}");
      debugPrint("Class subject ID: ${_selectedSubject?.classSubjectId}");
      debugPrint("Class section ID: ${_selectedClassSection?.id}");

      if (_selectedSubject != null && _selectedClassSection != null) {
        getLessons();
      }
    }
  }

  void getLessons() {
    debugPrint("=== Getting Lessons Debug ===");
    debugPrint("Class subject ID: ${_selectedSubject?.classSubjectId}");
    debugPrint("Class section ID: ${_selectedClassSection?.id}");

    if (_selectedSubject?.classSubjectId != null &&
        _selectedClassSection?.id != null) {
      context.read<LessonsCubit>().fetchLessons(
          classSubjectId: _selectedSubject!.classSubjectId,
          classSectionId: _selectedClassSection!.id ?? 0);
    } else {
      debugPrint("ERROR: Missing required IDs for fetching lessons");
    }
  }

  Widget _buildFormatChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  // Helper methods for attachment type styling
  Color _getAttachmentTypeColor(StudyMaterialType type) {
    switch (type) {
      case StudyMaterialType.youtubeVideo:
        return Colors.red.shade600;
      case StudyMaterialType.uploadedVideoUrl:
        return Colors.purple.shade600;
      case StudyMaterialType.file:
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getAttachmentIcon(StudyMaterialType type) {
    switch (type) {
      case StudyMaterialType.youtubeVideo:
        return Icons.play_circle_fill;
      case StudyMaterialType.uploadedVideoUrl:
        return Icons.video_file;
      case StudyMaterialType.file:
        return Icons.attach_file;
      default:
        return Icons.attachment;
    }
  }

  String _getAttachmentTypeLabel(StudyMaterialType type) {
    switch (type) {
      case StudyMaterialType.youtubeVideo:
        return 'Video YouTube';
      case StudyMaterialType.uploadedVideoUrl:
        return 'Video Upload';
      case StudyMaterialType.file:
        return 'File/Dokumen';
      default:
        return 'Lampiran';
    }
  }

  Widget _buildButtonContent({
    required VoidCallback onTap,
    required bool isLoading,
    required String title,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      splashColor: Colors.white.withValues(alpha: 0.2),
      highlightColor: Colors.white.withValues(alpha: 0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              isLoading ? 'Memproses...' : title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            if (!isLoading) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 22,
              ).animate(onPlay: (controller) {
                controller.repeat(reverse: true);
              }).slideX(
                begin: 0,
                end: 0.3,
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: widget.topic != null
              ? BlocConsumer<EditTopicCubit, EditTopicState>(
                  listener: (context, state) {
                    if (state is EditTopicSuccess) {
                      Get.back(result: true);
                      // Show auto-dismissing success banner
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  'Topik berhasil diperbarui!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          backgroundColor: Colors.green.shade400,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                      );

                      // Add slight delay before popping
                      Future.delayed(const Duration(milliseconds: 2200), () {
                        if (context.mounted) {
                          Navigator.pop(context, true);
                        }
                      });
                    } else if (state is EditTopicFailure) {
                      Utils.showSnackBar(
                          context: context, message: state.errorMessage);
                    }
                  },
                  builder: (context, state) {
                    return _buildButtonContent(
                      onTap: () {
                        if (state is EditTopicInProgress) return;
                        editTopic();
                      },
                      isLoading: state is EditTopicInProgress,
                      title: 'Perbarui Topik',
                    );
                  },
                )
              : BlocConsumer<CreateTopicCubit, CreateTopicState>(
                  listener: (context, state) {
                    if (state is CreateTopicSuccess) {
                      // Show auto-dismissing success banner
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  'Topik berhasil ditambahkan!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          backgroundColor: Colors.green.shade400,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                      );

                      // Clear form and pop with slight delay
                      Future.delayed(const Duration(milliseconds: 2200), () {
                        if (context.mounted) {
                          Navigator.pop(context, true);
                        }
                      });
                      _topicNameTextEditingController.text = "";
                      _topicDescriptionTextEditingController.text = "";
                      _addedStudyMaterials = [];
                      refreshTopicsInPreviousPage = true;
                      setState(() {});
                      Navigator.pop(context, true);
                    } else if (state is CreateTopicFailure) {
                      Utils.showSnackBar(
                          context: context, message: state.errorMessage);
                    }
                  },
                  builder: (context, state) {
                    return _buildButtonContent(
                      onTap: () {
                        if (state is CreateTopicInProgress) return;
                        createTopic();
                      },
                      isLoading: state is CreateTopicInProgress,
                      title: 'Buat Topik',
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    bool expandable =
        false, // Tambahkan parameter untuk input yang dapat mengembang
  }) {
    return TextFormField(
      controller: controller,
      maxLines:
          expandable ? null : maxLines, // Set null agar bisa ekspansi otomatis
      minLines: expandable
          ? 3
          : maxLines, // Set minimal line untuk input yang expandable
      maxLength: maxLength,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType ??
          (expandable ? TextInputType.multiline : TextInputType.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
        ),
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.secondary),
        ),
        counterText: "", // Menyembunyikan indikator jumlah karakter
        alignLabelWithHint:
            expandable, // Agar label selaras dengan baris pertama pada input multiline
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
      textAlignVertical:
          expandable ? TextAlignVertical.top : TextAlignVertical.center,
    );
  }

  Widget _buildFormContent(ClassSectionsAndSubjectsState state) {
    return state is ClassSectionsAndSubjectsFetchFailure
        ? Center(
            child: ErrorContainer(
            errorMessage: state.errorMessage,
            onTapRetry: () {
              context
                  .read<ClassSectionsAndSubjectsCubit>()
                  .getClassSectionsAndSubjects();
            },
          ))
        : Column(
            children: [
              // Basic Info Section
              Container(
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
                    Text(
                      'Informasi Dasar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Grade Level Selection
                    BlocBuilder<GradeLevelCubit, GradeLevelState>(
                      builder: (context, gradeLevelState) {
                        String displayText = 'Pilih Tingkatan';
                        bool isEnabled = false;

                        if (gradeLevelState is GradeLevelFetchInProgress) {
                          displayText = 'Memuat tingkatan...';
                        } else if (gradeLevelState is GradeLevelFetchSuccess) {
                          if (gradeLevelState.gradeLevels.isNotEmpty) {
                            displayText =
                                _selectedGradeLevel?.name ?? 'Pilih Tingkatan';
                            isEnabled = true;
                          } else {
                            displayText = 'Tidak ada tingkatan tersedia';
                          }
                        } else if (gradeLevelState is GradeLevelFetchFailure) {
                          displayText = 'Error memuat tingkatan';
                        }

                        return _buildAnimatedTextField(
                          controller: TextEditingController(text: displayText),
                          label: 'Tingkatan',
                          icon: Icons.school_rounded,
                          readOnly: true,
                          onTap: isEnabled
                              ? () {
                                  if (gradeLevelState
                                          is GradeLevelFetchSuccess &&
                                      gradeLevelState.gradeLevels.isNotEmpty) {
                                    Utils.showBottomSheet(
                                      child: FilterSelectionBottomsheet<
                                          GradeLevel>(
                                        showFilterByLabel: false,
                                        onSelection: (value) {
                                          if (value != null) {
                                            changeSelectedGradeLevel(value);
                                            Get.back();
                                          }
                                        },
                                        selectedValue: _selectedGradeLevel ??
                                            gradeLevelState.gradeLevels.first,
                                        titleKey: gradeLevelKey,
                                        values: gradeLevelState.gradeLevels,
                                      ),
                                      context: context,
                                    );
                                  }
                                }
                              : null,
                        );
                      },
                    ),
                    const SizedBox(height: 15),

                    // Class Selection
                    BlocBuilder<ClassSectionsAndSubjectsCubit,
                        ClassSectionsAndSubjectsState>(
                      builder: (context, state) {
                        String displayText = 'Pilih Kelas';
                        bool isEnabled = false;

                        if (state is ClassSectionsAndSubjectsFetchInProgress) {
                          displayText = 'Memuat kelas...';
                        } else if (state
                            is ClassSectionsAndSubjectsFetchSuccess) {
                          // Filter classes based on selected grade level if any
                          List<ClassSection> availableClasses =
                              state.classSections;

                          // If a grade level is selected, filter classes by grade level
                          if (_selectedGradeLevel != null) {
                            availableClasses = state.classSections
                                .where((classSection) =>
                                    classSection.gradeLevelId ==
                                    _selectedGradeLevel!.id)
                                .toList();
                          }

                          if (availableClasses.isNotEmpty) {
                            displayText = _selectedClassSection?.fullName ??
                                'Pilih Kelas';
                            isEnabled = true;
                          } else {
                            displayText = _selectedGradeLevel != null
                                ? 'Tidak ada kelas untuk tingkatan ini'
                                : 'Tidak ada kelas tersedia';
                          }
                        } else if (state
                            is ClassSectionsAndSubjectsFetchFailure) {
                          displayText = 'Error memuat kelas';
                        }

                        return _buildAnimatedTextField(
                          controller: TextEditingController(text: displayText),
                          label: 'Bagian Kelas',
                          icon: Icons.class_,
                          readOnly: true,
                          onTap: isEnabled
                              ? () {
                                  if (state
                                      is ClassSectionsAndSubjectsFetchSuccess) {
                                    // Filter classes based on selected grade level if any
                                    List<ClassSection> availableClasses =
                                        state.classSections;

                                    // If a grade level is selected, filter classes by grade level
                                    if (_selectedGradeLevel != null) {
                                      availableClasses = state.classSections
                                          .where((classSection) =>
                                              classSection.gradeLevelId ==
                                              _selectedGradeLevel!.id)
                                          .toList();
                                    }

                                    if (availableClasses.isNotEmpty) {
                                      Utils.showBottomSheet(
                                          child: FilterSelectionBottomsheet<
                                              ClassSection>(
                                            showFilterByLabel: false,
                                            onSelection: (value) {
                                              changeSelectedClassSection(value);
                                              Get.back();
                                            },
                                            selectedValue:
                                                _selectedClassSection ??
                                                    availableClasses.first,
                                            titleKey: classKey,
                                            values: availableClasses,
                                          ),
                                          context: context);
                                    }
                                  }
                                }
                              : null,
                        );
                      },
                    ),
                    const SizedBox(height: 15),

                    // Subject Selection
                    BlocBuilder<ClassSectionsAndSubjectsCubit,
                        ClassSectionsAndSubjectsState>(
                      builder: (context, state) {
                        String displayText = 'Pilih Mata Pelajaran';
                        bool isEnabled = false;

                        if (state is ClassSectionsAndSubjectsFetchInProgress) {
                          displayText = 'Memuat mata pelajaran...';
                        } else if (state
                            is ClassSectionsAndSubjectsFetchSuccess) {
                          if (state.subjects.isNotEmpty) {
                            displayText = _selectedSubject?.subject
                                    .getSybjectNameWithType() ??
                                'Pilih Mata Pelajaran';
                            isEnabled = true;
                          } else {
                            displayText = 'Tidak ada mata pelajaran tersedia';
                          }
                        } else if (state
                            is ClassSectionsAndSubjectsFetchFailure) {
                          displayText = 'Error memuat mata pelajaran';
                        } else {
                          displayText = 'Pilih kelas terlebih dahulu';
                        }

                        return _buildAnimatedTextField(
                          controller: TextEditingController(text: displayText),
                          label: 'Mata Pelajaran',
                          icon: Icons.subject,
                          readOnly: true,
                          onTap: isEnabled
                              ? () {
                                  if (state
                                          is ClassSectionsAndSubjectsFetchSuccess &&
                                      state.subjects.isNotEmpty) {
                                    Utils.showBottomSheet(
                                        child: FilterSelectionBottomsheet<
                                            TeacherSubject>(
                                          showFilterByLabel: false,
                                          selectedValue: _selectedSubject ??
                                              state.subjects.first,
                                          titleKey: subjectKey,
                                          values: state.subjects,
                                          onSelection: (value) {
                                            changeSelectedTeacherSubject(
                                                value!);
                                            Get.back();
                                          },
                                        ),
                                        context: context);
                                  }
                                }
                              : null,
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    // Lesson Selection
                    BlocConsumer<LessonsCubit, LessonsState>(
                      listener: (context, lessonState) {
                        debugPrint("=== Lesson State Changed ===");
                        debugPrint("State: ${lessonState.runtimeType}");
                        if (lessonState is LessonsFetchSuccess) {
                          debugPrint(
                              "Lessons fetched: ${lessonState.lessons.length}");
                          for (var lesson in lessonState.lessons) {
                            debugPrint(
                                "Lesson: ${lesson.name} (ID: ${lesson.id})");
                          }
                          // Remove auto-selection to let user choose manually
                          // Only auto-select if we're editing an existing topic with a predefined lesson
                        } else if (lessonState is LessonsFetchFailure) {
                          debugPrint(
                              "ERROR fetching lessons: ${lessonState.errorMessage}");
                        }
                      },
                      builder: (context, lessonState) {
                        String displayText = 'Pilih Bab';
                        bool isEnabled = false;

                        if (lessonState is LessonsFetchInProgress) {
                          displayText = 'Memuat bab...';
                        } else if (lessonState is LessonsFetchSuccess) {
                          if (lessonState.lessons.isNotEmpty) {
                            displayText = _selectedLesson?.name ?? 'Pilih Bab';
                            isEnabled = true;
                          } else {
                            displayText = 'Tidak ada bab tersedia';
                          }
                        } else if (lessonState is LessonsFetchFailure) {
                          displayText = 'Error memuat bab';
                        } else {
                          displayText = 'Pilih mata pelajaran terlebih dahulu';
                        }

                        return _buildAnimatedTextField(
                          controller: TextEditingController(text: displayText),
                          label: 'Bab',
                          icon: Icons.book_outlined,
                          readOnly: true,
                          onTap: isEnabled
                              ? () {
                                  if (lessonState is LessonsFetchSuccess &&
                                      lessonState.lessons.isNotEmpty) {
                                    Utils.showBottomSheet(
                                        child:
                                            FilterSelectionBottomsheet<Lesson>(
                                          showFilterByLabel: false,
                                          selectedValue: _selectedLesson ??
                                              lessonState.lessons.first,
                                          titleKey: lessonKey,
                                          values: lessonState.lessons,
                                          onSelection: (value) {
                                            if (_selectedLesson != value) {
                                              _selectedLesson = value;
                                              debugPrint(
                                                  "Selected lesson: ${value?.name} (ID: ${value?.id})");
                                              setState(() {});
                                            }
                                            Get.back();
                                          },
                                        ),
                                        context: context);
                                  }
                                }
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Topic Details Section
              Container(
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
                    Text(
                      'Detail Topik',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildAnimatedTextField(
                        controller: _topicNameTextEditingController,
                        label: 'Nama Topik',
                        icon: Icons.topic,
                        maxLength: 128,
                        expandable: true),
                    const SizedBox(height: 15),
                    _buildAnimatedTextField(
                      controller: _topicDescriptionTextEditingController,
                      label: 'Deskripsi',
                      icon: Icons.description,
                      maxLength: 1024,
                      expandable: true, // Aktifkan fitur ekspansi otomatis
                      keyboardType: TextInputType.multiline,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                  height:
                      20), // Study Materials Section - Clean & Minimalist Design
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clean Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.folder_copy_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Materi Pembelajaran',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Minimalist Info Card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Format yang didukung',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildFormatChip('PDF'),
                              _buildFormatChip('JPEG'),
                              _buildFormatChip('PNG'),
                              _buildFormatChip('CSV'),
                              _buildFormatChip('MS Word'),
                              _buildFormatChip('MP4'),
                              _buildFormatChip('AVI'),
                              _buildFormatChip('YouTube'),
                            ],
                          ),
                          // SizedBox(height: 8),
                          // Text(
                          //   'Batasan ukuran file adalah 2 MB',
                          //   style: TextStyle(
                          //     fontSize: 12,
                          //     color: Colors.grey.shade600,
                          //     fontStyle: FontStyle.italic,
                          //   ),
                          // ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Content Area
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Existing study materials/attachments - Show when editing topic
                          if (studyMaterials.isNotEmpty) ...[
                            Text(
                              'Materi Saat Ini (${studyMaterials.length})',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Display existing attachments in clean format
                            ...studyMaterials.map(
                              (studyMaterial) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getAttachmentTypeColor(
                                            studyMaterial.studyMaterialType)
                                        .withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Clean attachment type indicator
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getAttachmentTypeColor(
                                                studyMaterial.studyMaterialType)
                                            .withValues(alpha: 0.08),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          topRight: Radius.circular(8),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _getAttachmentIcon(studyMaterial
                                                .studyMaterialType),
                                            color: _getAttachmentTypeColor(
                                                studyMaterial
                                                    .studyMaterialType),
                                            size: 14,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _getAttachmentTypeLabel(
                                                studyMaterial
                                                    .studyMaterialType),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: _getAttachmentTypeColor(
                                                  studyMaterial
                                                      .studyMaterialType),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Study material content
                                    StudyMaterialContainer(
                                      onDeleteStudyMaterial:
                                          deleteStudyMaterial,
                                      onEditStudyMaterial: updateStudyMaterials,
                                      showEditAndDeleteButton: true,
                                      studyMaterial: studyMaterial,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],

                          // Added study materials (new ones being added)
                          if (_addedStudyMaterials.isNotEmpty) ...[
                            Text(
                              'Materi Baru (${_addedStudyMaterials.length})',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._addedStudyMaterials.asMap().entries.map(
                                  (entry) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            Colors.blue.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: AddedStudyMaterialContainer(
                                      backgroundColor: Colors.blue.shade50,
                                      onDelete: (index) {
                                        _addedStudyMaterials.removeAt(index);
                                        setState(() {});
                                      },
                                      onEdit: (index, file) {
                                        _addedStudyMaterials[index] = file;
                                        setState(() {});
                                      },
                                      file: entry.value,
                                      fileIndex: entry.key,
                                    ),
                                  ),
                                ),
                            const SizedBox(height: 16),
                          ],

                          // Clean Add Button
                          InkWell(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              Utils.showBottomSheet(
                                child: AddStudyMaterialBottomsheet(
                                  editFileDetails: false,
                                  onTapSubmit: _addStudyMaterial,
                                ),
                                context: context,
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tambah Materi',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GradeLevelCubit, GradeLevelState>(
          listener: (context, state) {
            if (state is GradeLevelFetchSuccess &&
                _selectedClassSection != null &&
                _selectedGradeLevel == null) {
              GradeLevel? gradeLevel;
              for (var g in state.gradeLevels) {
                if (g.id == _selectedClassSection!.gradeLevelId) {
                  gradeLevel = g;
                  break;
                }
              }
              if (gradeLevel != null) {
                _selectedGradeLevel = gradeLevel;
                setState(() {});
                // Fetch classes filtered by grade level, but keep subjects for selected class section
                context
                    .read<ClassSectionsAndSubjectsCubit>()
                    .getClassSectionsAndSubjects(
                        gradeLevelId: gradeLevel.id,
                        classSectionId: _selectedClassSection?.id);
              }
            }
          },
        ),
        BlocListener<LessonsCubit, LessonsState>(
          listener: (context, lessonState) {
            if (lessonState is LessonsFetchSuccess &&
                widget.topic != null &&
                _selectedLesson == null) {
              Lesson? lesson;
              for (var l in lessonState.lessons) {
                if (l.id == widget.topic!.lessonId) {
                  lesson = l;
                  break;
                }
              }
              if (lesson != null) {
                _selectedLesson = lesson;
                setState(() {});
              }
            }
          },
        ),
      ],
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            return;
          }
          Get.back(result: refreshTopicsInPreviousPage);
        },
        child: Scaffold(
          extendBodyBehindAppBar: true, // Allow content behind status bar
          appBar: CustomModernAppBar(
            title: widget.topic != null ? "Edit Topik" : "Tambah Topik",
            icon: Icons.topic_rounded,
            fabAnimationController: _fabAnimationController,
            onBackPressed: () {
              Get.back(result: refreshTopicsInPreviousPage);
            },
            primaryColor: _primaryColor,
            lightColor: _accentColor,
            height: 80,
          ),
          body: Container(
            color: Colors.grey[50], // White background for the entire screen
            child: Column(
              children: [
                SizedBox(
                    height: 80 +
                        MediaQuery.of(context)
                            .padding
                            .top), // Space for app bar

                // Main content section
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Form Content
                        BlocConsumer<ClassSectionsAndSubjectsCubit,
                            ClassSectionsAndSubjectsState>(
                          listener: (context, state) {
                            // Remove auto-selection to let user choose manually
                            // Only auto-select if we're editing an existing topic and have predefined selections
                            if (state is ClassSectionsAndSubjectsFetchSuccess) {
                              debugPrint(
                                  "=== ClassSectionsAndSubjectsFetchSuccess ===");
                              debugPrint(
                                  "Class sections count: ${state.classSections.length}");
                              debugPrint(
                                  "Subjects count: ${state.subjects.length}");
                              for (var subject in state.subjects) {
                                debugPrint(
                                    "Subject: ${subject.subject.getSybjectNameWithType()}");
                              }
                              debugPrint(
                                  "=====================================");
                              // Only auto-select subjects if we already have a selected class section
                              // and we're editing an existing topic (not creating new)
                              if (_selectedClassSection != null &&
                                  _selectedSubject == null &&
                                  widget.topic != null) {
                                changeSelectedTeacherSubject(
                                    state.subjects.firstOrNull);
                              }
                            }
                          },
                          builder: (context, state) {
                            return _buildFormContent(state);
                          },
                        ),

                        const SizedBox(height: 30),

                        // Submit Button
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
