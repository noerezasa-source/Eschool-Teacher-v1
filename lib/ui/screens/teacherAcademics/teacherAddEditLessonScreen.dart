import 'package:eschool_saas_staff/cubits/teacherAcademics/classSectionsAndSubjects.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/lesson/createLessonCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/lesson/editLessonCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/gradeLevelCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/academic/lesson.dart';
import 'package:eschool_saas_staff/data/models/academic/pickedStudyMaterial.dart';
import 'package:eschool_saas_staff/data/models/academic/studyMaterial.dart';
import 'package:eschool_saas_staff/data/models/academic/teacherSubject.dart';
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
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TeacherAddEditLessonScreen extends StatefulWidget {
  final Lesson? lesson;
  final ClassSection? selectedClassSection;
  final TeacherSubject? selectedSubject;
  static Widget getRouteInstance() {
    final arguments = Get.arguments as Map<String, dynamic>?;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => CreateLessonCubit(),
        ),
        BlocProvider(
          create: (context) => EditLessonCubit(),
        ),
        BlocProvider(
          create: (context) => ClassSectionsAndSubjectsCubit(),
        ),
        BlocProvider(
          create: (context) => GradeLevelCubit(),
        ),
      ],
      child: TeacherAddEditLessonScreen(
        lesson: arguments?['lesson'],
        selectedClassSection: arguments?['selectedClassSection'],
        selectedSubject: arguments?['selectedSubject'],
      ),
    );
  }

  static Map<String, dynamic> buildArguments(
      {required Lesson? lesson,
      required ClassSection? selectedClassSection,
      required TeacherSubject? selectedSubject}) {
    return {
      "lesson": lesson,
      "selectedClassSection": selectedClassSection,
      "selectedSubject": selectedSubject
    };
  }

  const TeacherAddEditLessonScreen(
      {super.key,
      required this.lesson,
      this.selectedClassSection,
      this.selectedSubject});

  @override
  State<TeacherAddEditLessonScreen> createState() =>
      _TeacherAddEditLessonScreenState();
}

class _TeacherAddEditLessonScreenState extends State<TeacherAddEditLessonScreen>
    with TickerProviderStateMixin, OptimizedFileCompressionMixin {
  late ClassSection? _selectedClassSection = widget.selectedClassSection;
  late TeacherSubject? _selectedSubject = widget.selectedSubject;
  GradeLevel? _selectedGradeLevel;

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
        BlocListener<ClassSectionsAndSubjectsCubit,
            ClassSectionsAndSubjectsState>(
          listener: (context, state) {
            if (state is ClassSectionsAndSubjectsFetchSuccess &&
                widget.lesson != null &&
                _selectedClassSection == null) {
              // For edit mode, find the class section that matches the lesson's classSectionId
              ClassSection? classSection;
              for (var cs in state.classSections) {
                if (cs.id == widget.lesson!.classSectionId) {
                  classSection = cs;
                  break;
                }
              }
              if (classSection != null) {
                _selectedClassSection = classSection;
                setState(() {});
              }
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: CustomModernAppBar(
          title: widget.lesson != null ? 'Edit Pelajaran' : 'Tambah Pelajaran',
          icon: Icons.book_rounded,
          primaryColor: AppColorPalette.primaryMaroon,
          lightColor: AppColorPalette.secondaryMaroon,
          fabAnimationController: _fabAnimationController,
          onBackPressed: () => Navigator.of(context).pop(),
          showAddButton: false,
          showArchiveButton: false,
          showFilterButton: false,
          showHelperButton: false,
        ),
        body: _buildAddEditLessonForm(),
      ),
    );
  }

  //This will determine if need to refresh the previous page
  //lesson data. If teacher remove the the any study material
  //so we need to fetch the list again
  late bool refreshLessonsInPreviousPage = false;

  late final TextEditingController _lessonNameTextEditingController =
      TextEditingController(
    text: widget.lesson?.name,
  );
  late final TextEditingController _lessonDescriptionTextEditingController =
      TextEditingController(
    text: widget.lesson?.description,
  );

  List<PickedStudyMaterial> _addedStudyMaterials = [];

  late List<StudyMaterial> studyMaterials = widget.lesson?.studyMaterials ?? [];

  // Animation controllers for the glowing effects
  late AnimationController _pulseController;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    // For edit mode, we need to set the selected class section initially
    // The BlocListener will then automatically find and set the grade level
    if (widget.lesson != null && _selectedClassSection == null) {
      // We'll set _selectedClassSection after data loads in BlocListener
      // For now, just mark that we need to find it
    }

    Future.delayed(Duration.zero, () async {
      if (mounted) {
        // Start fetching data
        context.read<GradeLevelCubit>().getGradeLevels();
        context
            .read<ClassSectionsAndSubjectsCubit>()
            .getClassSectionsAndSubjects(
                classSectionId: _selectedClassSection?.id);
      }
    });

    // Add this with your other controller initialization
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    super.initState();
  }

  @override
  void dispose() {
    _lessonNameTextEditingController.dispose();
    _lessonDescriptionTextEditingController.dispose();
    _pulseController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void deleteStudyMaterial(int studyMaterialId) {
    studyMaterials.removeWhere((element) => element.id == studyMaterialId);
    refreshLessonsInPreviousPage = true;
    setState(() {});
  }

  void updateStudyMaterials(StudyMaterial studyMaterial) {
    final studyMaterialIndex =
        studyMaterials.indexWhere((element) => element.id == studyMaterial.id);
    studyMaterials[studyMaterialIndex] = studyMaterial;
    refreshLessonsInPreviousPage = true;
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

  void changeSelectedGradeLevel(GradeLevel? gradeLevel) {
    if (_selectedGradeLevel != gradeLevel) {
      _selectedGradeLevel = gradeLevel;

      // Reset selected class and subject when grade level changes
      _selectedClassSection = null;
      _selectedSubject = null;

      setState(() {});

      // Re-fetch classes for the selected grade level to filter them
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
      // Reset subject when changing class
      _selectedSubject = null;

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
              changeSelectedTeacherSubject(successState.subjects.firstOrNull);
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

  void editLesson() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_selectedGradeLevel == null) {
      showErrorMessage("Silakan pilih tingkatan terlebih dahulu");
      return;
    }

    if (_selectedSubject == null) {
      showErrorMessage(noSubjectSelectedKey);
      return;
    }

    if (_selectedClassSection == null) {
      showErrorMessage(noClassSectionSelectedKey);
      return;
    }

    if (_lessonNameTextEditingController.text.trim().isEmpty) {
      showErrorMessage(pleaseEnterLessonNameKey);
      return;
    }

    if (_lessonDescriptionTextEditingController.text.trim().isEmpty) {
      showErrorMessage(pleaseEnterLessonDescriptionKey);
      return;
    }

    context.read<EditLessonCubit>().editLesson(
          lessonDescription:
              _lessonDescriptionTextEditingController.text.trim(),
          lessonName: _lessonNameTextEditingController.text.trim(),
          lessonId: widget.lesson!.id,
          classSectionId: widget.lesson!.classSectionId,
          classSubjectId: _selectedSubject?.classSubjectId ?? 0,
          files: _addedStudyMaterials,
        );
  }

  void createLesson() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_selectedGradeLevel == null) {
      showErrorMessage("Silakan pilih tingkatan terlebih dahulu");
      return;
    }

    if (_selectedSubject == null) {
      showErrorMessage(noSubjectSelectedKey);
      return;
    }

    if (_selectedClassSection == null) {
      showErrorMessage(noClassSectionSelectedKey);
      return;
    }

    if (_lessonNameTextEditingController.text.trim().isEmpty) {
      showErrorMessage(pleaseEnterLessonNameKey);
      return;
    }

    if (_lessonDescriptionTextEditingController.text.trim().isEmpty) {
      showErrorMessage(pleaseEnterLessonDescriptionKey);
      return;
    }

    context.read<CreateLessonCubit>().createLesson(
          classSectionId: _selectedClassSection?.id ?? 0,
          files: _addedStudyMaterials,
          classSubjectId: _selectedSubject?.classSubjectId ?? 0,
          lessonDescription:
              _lessonDescriptionTextEditingController.text.trim(),
          lessonName: _lessonNameTextEditingController.text.trim(),
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
          child: widget.lesson != null
              ? BlocConsumer<EditLessonCubit, EditLessonState>(
                  listener: (context, state) {
                    if (state is EditLessonSuccess) {
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
                                  'Pelajaran diperbarui!',
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
                    } else if (state is EditLessonFailure) {
                      Utils.showSnackBar(
                          context: context, message: state.errorMessage);
                    }
                  },
                  builder: (context, state) {
                    return _buildButtonContent(
                      onTap: () {
                        if (state is EditLessonInProgress) return;
                        editLesson();
                      },
                      isLoading: state is EditLessonInProgress,
                      title: 'Perbarui Pelajaran',
                    );
                  },
                )
              : BlocConsumer<CreateLessonCubit, CreateLessonState>(
                  listener: (context, state) {
                    if (state is CreateLessonSuccess) {
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
                                  'Pelajaran ditambahkan!',
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
                      _lessonDescriptionTextEditingController.text = "";
                      _lessonNameTextEditingController.text = "";
                      _addedStudyMaterials = [];
                      refreshLessonsInPreviousPage = true;
                      setState(() {});
                      Navigator.pop(context, true);
                    } else if (state is CreateLessonFailure) {
                      Utils.showSnackBar(
                          context: context, message: state.errorMessage);
                    }
                  },
                  builder: (context, state) {
                    return _buildButtonContent(
                      onTap: () {
                        if (state is CreateLessonInProgress) return;
                        createLesson();
                      },
                      isLoading: state is CreateLessonInProgress,
                      title: 'Buat Pelajaran',
                    );
                  },
                ),
        ),
      ),
    );
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

  Widget _buildAddEditLessonForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Form Content
          BlocConsumer<ClassSectionsAndSubjectsCubit,
              ClassSectionsAndSubjectsState>(
            listener: (context, state) {
              // Add listener implementation if needed
            },
            builder: (context, state) {
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
                  : _buildFormContent(state);
            },
          ),

          const SizedBox(height: 30),

          // Submit Button
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildFormContent(ClassSectionsAndSubjectsState state) {
    return BlocBuilder<GradeLevelCubit, GradeLevelState>(
      builder: (context, gradeLevelState) {
        if (gradeLevelState is GradeLevelFetchFailure) {
          return Center(
            child: ErrorContainer(
              errorMessage: gradeLevelState.errorMessage,
              onTapRetry: () {
                context.read<GradeLevelCubit>().getGradeLevels();
              },
            ),
          );
        }

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
                  // Basic Info Section with Grade Level
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
                        if (gradeLevelState is GradeLevelFetchSuccess)
                          _buildAnimatedTextField(
                            controller: TextEditingController(
                                text: _selectedGradeLevel?.name ??
                                    'Pilih Tingkatan'),
                            label: 'Tingkatan',
                            icon: Icons.school_rounded,
                            readOnly: true,
                            onTap: () {
                              if (gradeLevelState.gradeLevels.isNotEmpty) {
                                Utils.showBottomSheet(
                                    child:
                                        FilterSelectionBottomsheet<GradeLevel>(
                                      showFilterByLabel: false,
                                      onSelection: (value) {
                                        changeSelectedGradeLevel(value);
                                        Get.back();
                                      },
                                      selectedValue: _selectedGradeLevel ??
                                          gradeLevelState.gradeLevels.first,
                                      titleKey: "Pilih Tingkatan",
                                      values: gradeLevelState.gradeLevels,
                                    ),
                                    context: context);
                              }
                            },
                          ),
                        if (gradeLevelState is GradeLevelFetchSuccess)
                          const SizedBox(height: 15),

                        // Class Selection - Filter based on grade level
                        _buildAnimatedTextField(
                          controller: TextEditingController(
                              text: _selectedClassSection?.fullName ??
                                  'Pilih Kelas'),
                          label: 'Bagian Kelas',
                          icon: Icons.class_,
                          readOnly: true,
                          onTap: () {
                            if (state is ClassSectionsAndSubjectsFetchSuccess) {
                              // Filter classes based on selected grade level
                              List<ClassSection> availableClasses =
                                  state.classSections;
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
                                      selectedValue: _selectedClassSection ??
                                          availableClasses.first,
                                      titleKey: classKey,
                                      values: availableClasses,
                                    ),
                                    context: context);
                              } else {
                                Utils.showSnackBar(
                                  context: context,
                                  message:
                                      "Tidak ada kelas untuk tingkatan yang dipilih",
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 15),

                        // Subject Selection
                        _buildAnimatedTextField(
                          controller: TextEditingController(
                              text: _selectedSubject?.subject
                                      .getSybjectNameWithType() ??
                                  'Pilih Mata Pelajaran'),
                          label: 'Mata Pelajaran',
                          icon: Icons.subject,
                          readOnly: true,
                          onTap: () {
                            if (state is ClassSectionsAndSubjectsFetchSuccess &&
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
                                      changeSelectedTeacherSubject(value!);
                                      Get.back();
                                    },
                                  ),
                                  context: context);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Lesson Details Section
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
                          'Detail Pelajaran',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildAnimatedTextField(
                          controller: _lessonNameTextEditingController,
                          label: 'Nama Pelajaran',
                          icon: Icons.book,
                        ),
                        const SizedBox(height: 15),
                        _buildAnimatedTextField(
                          controller: _lessonDescriptionTextEditingController,
                          label: 'Deskripsi',
                          icon: Icons.description,
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
                              // Existing study materials
                              if (widget.lesson != null &&
                                  studyMaterials.isNotEmpty) ...[
                                Text(
                                  'Materi Saat Ini',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...studyMaterials.map(
                                  (studyMaterial) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: StudyMaterialContainer(
                                      onDeleteStudyMaterial:
                                          deleteStudyMaterial,
                                      onEditStudyMaterial: updateStudyMaterials,
                                      showEditAndDeleteButton: true,
                                      studyMaterial: studyMaterial,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Added study materials
                              if (_addedStudyMaterials.isNotEmpty) ...[
                                Text(
                                  'Materi Baru',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._addedStudyMaterials.asMap().entries.map(
                                      (entry) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: AddedStudyMaterialContainer(
                                          backgroundColor: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                          onDelete: (index) {
                                            _addedStudyMaterials
                                                .removeAt(index);
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Tambah Materi',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
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
                  )
                ],
              );
      },
    );
  }

  // Add this helper method for consistent text field styling
  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    // For description and lesson name fields, we'll position the icon next to the label and allow multiline
    if (label == 'Deskripsi' || label == 'Nama Pelajaran') {
      return TextFormField(
        controller: controller,
        maxLines: null, // null allows unlimited lines for description
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          // Custom label with icon
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          alignLabelWithHint: true,
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        ),
        validator: (v) => v!.isEmpty ? 'Required' : null,
        minLines: label == 'Nama Pelajaran' ? 2 : 3,
      );
    }

    // For other fields, use the original implementation
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
      minLines: 1,
    );
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
}

