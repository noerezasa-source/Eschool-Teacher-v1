import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/classSectionsAndSubjects.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/gradeLevelCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/lesson/deleteLessonCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/lesson/lessonsCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/academic/gradeLevel.dart';
import 'package:eschool_saas_staff/data/models/academic/lesson.dart';
import 'package:eschool_saas_staff/data/models/academic/teacherSubject.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherAddEditLessonScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherManageTopicScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/confirmDeleteDialog.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customFilterModernAppbar.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionBottomsheet.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

// Define our theme colors (kept local: teacherManageTopicScreen import re-exports same names)
const Color maroonPrimary = Color(0xFF8B1F41);
const Color maroonLight = Color(0xFFAC3B5C);
const Color maroonDark = Color(0xFF6A0F2A);
const Color accentColor = Color(0xFFF5EBE0);
const Color bgColor = Color(0xFFFAF6F2);
const Color cardColor = Colors.white;
const Color textDarkColor = Color(0xFF2D2D2D);
const Color textMediumColor = Color(0xFF717171);
const Color borderColor = Color(0xFFE8E8E8);

class TeacherManageLessonScreen extends StatefulWidget {
  static Widget getRouteInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => LessonsCubit()),
        BlocProvider(create: (context) => ClassSectionsAndSubjectsCubit()),
        BlocProvider(create: (context) => GradeLevelCubit()),
      ],
      child: const TeacherManageLessonScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  const TeacherManageLessonScreen({super.key});

  @override
  State<TeacherManageLessonScreen> createState() =>
      _TeacherManageLessonScreenState();
}

class _TeacherManageLessonScreenState extends State<TeacherManageLessonScreen>
    with TickerProviderStateMixin {
  ClassSection? _selectedClassSection;
  TeacherSubject? _selectedSubject;
  GradeLevel? _selectedGradeLevel;

  // Animation controllers
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  // For header collapsing effect
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutQuint,
      ),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<GradeLevelCubit>().getGradeLevels();
        // Also fetch class sections initially without grade level filter
        context
            .read<ClassSectionsAndSubjectsCubit>()
            .getClassSectionsAndSubjects();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
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

      // Clear lessons since filters have changed
      context.read<LessonsCubit>().updateState(LessonsFetchSuccess([]));
    }
  }

  void changeSelectedClassSection(ClassSection? classSection,
      {bool fetchNewSubjects = true}) {
    if (_selectedClassSection != classSection) {
      _selectedClassSection = classSection;
      // Reset subject when changing class
      _selectedSubject = null;

      if (fetchNewSubjects && _selectedClassSection != null) {
        context
            .read<ClassSectionsAndSubjectsCubit>()
            .getNewSubjectsFromSelectedClassSectionIndex(
                newClassSectionId: classSection?.id ?? 0)
            .then((value) {
          if (mounted) {
            if (context.read<ClassSectionsAndSubjectsCubit>().state
                is ClassSectionsAndSubjectsFetchSuccess) {
              changeSelectedTeacherSubject((context
                      .read<ClassSectionsAndSubjectsCubit>()
                      .state as ClassSectionsAndSubjectsFetchSuccess)
                  .subjects
                  .firstOrNull);
            }
          }
        });
      }
      setState(() {});
    }
  }

  void changeSelectedTeacherSubject(TeacherSubject? teacherSubject) {
    if (_selectedSubject != teacherSubject) {
      _selectedSubject = teacherSubject;
      setState(() {});
      getLessons();
    }
  }

  void getLessons() {
    context.read<LessonsCubit>().fetchLessons(
        classSubjectId: _selectedSubject?.classSubjectId ?? 0,
        classSectionId: _selectedClassSection?.id ?? 0);
  }

  Widget _buildLessonItem({required Lesson lesson}) {
    return BlocProvider(
      create: (context) => DeleteLessonCubit(),
      child: Builder(builder: (context) {
        return BlocConsumer<DeleteLessonCubit, DeleteLessonState>(
          listener: (context, state) {
            if (state is DeleteLessonSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "${Utils.getTranslatedLabel(lessonDeletedSuccessfullyKey)} ${lesson.name}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  backgroundColor: Colors.green.shade600,
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                ),
              );
              context.read<LessonsCubit>().deleteLesson(lesson.id);
            } else if (state is DeleteLessonFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "${Utils.getTranslatedLabel(unableToDeleteLessonKey)} ${lesson.name}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  backgroundColor: maroonPrimary,
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                ),
              );
            }
          },
          builder: (context, state) {
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: maroonPrimary.withValues(alpha: 0.1),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Premium header with enhanced design
                      Stack(
                        children: [
                          // Sophisticated background with animated gradient
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 130,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFF9F0F5),
                                  Color(0xFFFDF7FA),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),

                          // Dynamic decorative elements
                          Positioned(
                            top: -30,
                            right: -30,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    maroonPrimary.withValues(alpha: 0.08),
                                    maroonPrimary.withValues(alpha: 0.03)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -25,
                            left: -15,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    maroonPrimary.withValues(alpha: 0.06),
                                    maroonPrimary.withValues(alpha: 0.02)
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),

                          // Elegant accent bar
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [maroonPrimary, maroonLight],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: maroonPrimary.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                    spreadRadius: -2,
                                  )
                                ],
                              ),
                            ),
                          ),

                          // Enhanced content layout
                          Padding(
                            padding: const EdgeInsets.fromLTRB(26, 24, 20, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Enhanced typography and layout for lesson title
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lesson.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: textDarkColor,
                                          letterSpacing: -0.3,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Elegant topic counter with improved styling
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: maroonPrimary.withValues(
                                              alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: maroonPrimary.withValues(
                                                alpha: 0.15),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "${lesson.topicsCount} topik",
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: maroonPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Refined action menu with visual feedback
                                Material(
                                  color: Colors.transparent,
                                  child: PopupMenuButton<String>(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 12,
                                    offset: const Offset(0, 50),
                                    color: Colors.white,
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        HapticFeedback.lightImpact();
                                        Get.toNamed(
                                                Routes
                                                    .teacherAddEditLessonScreen,
                                                arguments: TeacherAddEditLessonScreen
                                                    .buildArguments(
                                                        lesson: lesson,
                                                        selectedClassSection:
                                                            _selectedClassSection,
                                                        selectedSubject:
                                                            _selectedSubject))
                                            ?.then((value) {
                                          if (value != null &&
                                              value is bool &&
                                              value) {
                                            getLessons();
                                          }
                                        });
                                      } else if (value == 'delete') {
                                        if (state is DeleteLessonInProgress) {
                                          return;
                                        }
                                        HapticFeedback.mediumImpact();
                                        showDialog<bool>(
                                          context: context,
                                          builder: (_) =>
                                              const ConfirmDeleteDialog(),
                                        ).then((value) {
                                          if (value != null && value) {
                                            if (context.mounted) {
                                              context
                                                  .read<DeleteLessonCubit>()
                                                  .deleteLesson(lesson.id);
                                            }
                                          }
                                        });
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      // Enhanced Edit button
                                      PopupMenuItem<String>(
                                        value: 'edit',
                                        height: 64,
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween<double>(
                                              begin: 0.9, end: 1.0),
                                          duration:
                                              const Duration(milliseconds: 200),
                                          builder: (context, value, child) {
                                            return Transform.scale(
                                              scale: value,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                        horizontal: 8),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.blue.shade400,
                                                      Colors.blue.shade600
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors
                                                          .blue.shade500
                                                          .withValues(
                                                              alpha: 0.3),
                                                      blurRadius: 12,
                                                      offset:
                                                          const Offset(0, 4),
                                                      spreadRadius: -2,
                                                    )
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.25),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: const Icon(
                                                        Icons.edit_rounded,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        'Edit',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 15,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      // Enhanced Delete button
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        height: 64,
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween<double>(
                                              begin: 0.9, end: 1.0),
                                          duration:
                                              const Duration(milliseconds: 300),
                                          builder: (context, value, child) {
                                            return Transform.scale(
                                              scale: value,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                        horizontal: 8),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.red.shade400,
                                                      Colors.red.shade700
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.red.shade500
                                                          .withValues(
                                                              alpha: 0.3),
                                                      blurRadius: 12,
                                                      offset:
                                                          const Offset(0, 4),
                                                      spreadRadius: -2,
                                                    )
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.25),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: const Icon(
                                                        Icons
                                                            .delete_outline_rounded,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        'Delete',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 15,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                    child: TweenAnimationBuilder<double>(
                                      tween:
                                          Tween<double>(begin: 0.8, end: 1.0),
                                      duration:
                                          const Duration(milliseconds: 300),
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              gradient: state
                                                      is DeleteLessonInProgress
                                                  ? LinearGradient(
                                                      colors: [
                                                        Colors.grey.shade300,
                                                        Colors.grey.shade400
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    )
                                                  : LinearGradient(
                                                      colors: [
                                                        Colors.white,
                                                        Colors.grey.shade100
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: maroonPrimary
                                                      .withValues(alpha: 0.1),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                  spreadRadius: -2,
                                                ),
                                              ],
                                            ),
                                            child: state
                                                    is DeleteLessonInProgress
                                                ? const Center(
                                                    child: SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                        color: maroonPrimary,
                                                        strokeWidth: 2,
                                                      ),
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.more_vert_rounded,
                                                    color: maroonPrimary,
                                                    size: 22,
                                                  ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Enhanced description section with refined styling
                      Container(
                        padding: const EdgeInsets.fromLTRB(26, 22, 26, 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade100,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        maroonPrimary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.description_outlined,
                                    color: maroonPrimary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  Utils.getTranslatedLabel(descriptionKey),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textDarkColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Elegant description container with enhanced readability
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                lesson.description,
                                style: GoogleFonts.poppins(
                                  fontSize: 14.5,
                                  color: textMediumColor,
                                  height: 1.6,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Study materials section with enhanced styling
                      if (lesson.studyMaterials.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(26),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade100,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          maroonPrimary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.attach_file_rounded,
                                      color: maroonPrimary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Materi Pembelajaran",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: textDarkColor,
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Animated counter badge
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.8, end: 1.0),
                                    duration: const Duration(milliseconds: 300),
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: maroonPrimary.withValues(
                                                alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: maroonPrimary.withValues(
                                                  alpha: 0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            "${lesson.studyMaterials.length}",
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: maroonPrimary,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Enhanced file list container
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Column(
                                    children: lesson.studyMaterials
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final index = entry.key;
                                      final material = entry.value;

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          border: index > 0
                                              ? Border(
                                                  top: BorderSide(
                                                    color: Colors.grey.shade200,
                                                    width: 1,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        padding: const EdgeInsets.all(18),
                                        child: Row(
                                          children: [
                                            // Enhanced file icon
                                            Container(
                                              width: 48,
                                              height: 48,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                            alpha: 0.05),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                    spreadRadius: -2,
                                                  ),
                                                ],
                                                border: Border.all(
                                                  color: Colors.grey.shade100,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Icon(
                                                _getFileTypeIcon(
                                                    material.fileName),
                                                color: maroonPrimary,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 16),

                                            // Enhanced file info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    material.fileName,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: textDarkColor,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade200,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                    ),
                                                    child: Text(
                                                      _getFileType(
                                                          material.fileName),
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: textMediumColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Enhanced download button with animation
                                            Material(
                                              color: Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              child: InkWell(
                                                onTap: () {
                                                  HapticFeedback.lightImpact();
                                                  Utils.viewOrDownloadStudyMaterial(
                                                    context: context,
                                                    storeInExternalStorage: true,
                                                    studyMaterial: material,
                                                  );
                                                },

                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                child: Container(
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.blue.shade500,
                                                        Colors.blue.shade700
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            14),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors
                                                            .blue.shade700
                                                            .withValues(
                                                                alpha: 0.25),
                                                        blurRadius: 12,
                                                        offset:
                                                            const Offset(0, 4),
                                                        spreadRadius: -3,
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.download_rounded,
                                                    color: Colors.white,
                                                    size: 22,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Premium view topics button
                      Container(
                        padding: const EdgeInsets.all(26),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Get.toNamed(
                                Routes.teacherManageTopicScreen,
                                arguments:
                                    TeacherManageTopicScreen.buildArguments(
                                        selectedLesson: lesson,
                                        selectedClassSection:
                                            _selectedClassSection,
                                        selectedSubject: _selectedSubject),
                              )?.then((value) {
                                if (value != null && value is bool && value) {
                                  // Delay to let pop animation finish
                                  Future.delayed(
                                      const Duration(milliseconds: 300), () {
                                    if (mounted) {
                                      getLessons();
                                    }
                                  });
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [maroonPrimary, maroonDark],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: maroonPrimary.withValues(alpha: 0.3),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                    spreadRadius: -6,
                                  ),
                                ],
                              ),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(width: 14),
                                    Text(
                                      "${Utils.getTranslatedLabel(viewTopicsKey)}${lesson.topicsCount != 0 ? ' (${lesson.topicsCount})' : ''}",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
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
      }),
    );
  }

  IconData _getFileTypeIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image_outlined;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file_outlined;
      case 'mp3':
      case 'wav':
        return Icons.audio_file_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return 'PDF Document';
      case 'doc':
      case 'docx':
        return 'Word Document';
      case 'xls':
      case 'xlsx':
        return 'Excel Spreadsheet';
      case 'ppt':
      case 'pptx':
        return 'PowerPoint Presentation';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'Image File';
      case 'mp4':
      case 'avi':
      case 'mov':
        return 'Video File';
      case 'mp3':
      case 'wav':
        return 'Audio File';
      default:
        return '${extension.toUpperCase()} File';
    }
  }

  // Helper function to calculate dynamic app bar height based on filter count
  double _getDynamicAppBarHeight() {
    // For consistency, use the same logic as in _buildHeaderSection
    // When we have 3 filters, return 250, otherwise 200
    if (_selectedClassSection != null) {
      return 250.0; // 3 filters: grade level + class + subject
    }
    return 200.0; // 2 filters: grade level + class
  }

  Widget _buildLessonList() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.only(
            bottom: (_selectedClassSection != null && _selectedSubject != null)
                ? 70
                : 20,
            top: Utils.appContentTopScrollPadding(context: context) +
                _getDynamicAppBarHeight() -
                55), // Dynamic AppBar height with offset
        child: BlocBuilder<LessonsCubit, LessonsState>(
          builder: (context, state) {
            if (state is LessonsFetchSuccess) {
              if (state.lessons.isEmpty) {
                return Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 50),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.menu_book_outlined,
                            color: textMediumColor,
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            Utils.getTranslatedLabel(noLessonKey),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                              color: textMediumColor,
                            ),
                          ),
                          if (_selectedClassSection != null &&
                              _selectedSubject != null) ...[
                            //       if (value != null && value is bool && value) {
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SlideTransition(
                position: _slideAnimation,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: appContentHorizontalPadding),
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Add initial padding at the top of the list
                      const SizedBox(height: 20),

                      // Lessons
                      ...List.generate(
                          state.lessons.length,
                          (index) =>
                              _buildLessonItem(lesson: state.lessons[index])),
                    ],
                  ),
                ),
              );
            } else if (state is LessonsFetchFailure) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.only(
                      top: topPaddingOfErrorAndLoadingContainer),
                  child: CustomErrorWidget(
                    message: "Gagal mendapatkan bab pelajaran, mohon coba lagi",
                    onRetry: () {
                      getLessons();
                    },
                    primaryColor: maroonPrimary,
                  ),
                ),
              );
            } else {
              return Center(
                child: Padding(
                  padding: EdgeInsets.only(
                      top: topPaddingOfErrorAndLoadingContainer),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.menu_book_outlined,
                          size: 40,
                          color: maroonPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Pilih kelas dan mata pelajaran terlebih dahulu",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: textMediumColor,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
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
    final bool showButton =
        _selectedClassSection != null && _selectedSubject != null;

    if (!showButton) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: EdgeInsets.all(appContentHorizontalPadding),
            width: MediaQuery.of(context).size.width,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getDarkenedColor(maroonPrimary, 0.1),
                  maroonPrimary,
                  _getLightenedColor(maroonPrimary, 0.1),
                  maroonLight,
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: maroonPrimary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative elements like in the AppBar
                // Positioned.fill(
                //   child: CustomPaint(
                //     painter: AppBarDecorationPainter(
                //       color: Colors.white.withValues(alpha: 0.07),
                //     ),
                //   ),
                // ),
                // Animated glowing effect
                Positioned(
                  bottom: -80,
                  right: -40,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 2000),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.2 * value),
                              Colors.white.withValues(alpha: 0.1 * value),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Button content
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.95, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              Get.toNamed(Routes.teacherAddEditLessonScreen,
                                      arguments: TeacherAddEditLessonScreen
                                          .buildArguments(
                                              lesson: null,
                                              selectedClassSection:
                                                  _selectedClassSection,
                                              selectedSubject:
                                                  _selectedSubject))
                                  ?.then((value) {
                                if (value != null && value is bool && value) {
                                  getLessons();
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(15),
                            highlightColor: Colors.white.withValues(alpha: 0.1),
                            splashColor: Colors.white.withValues(alpha: 0.2),
                            child: Container(
                              height: 56,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Using the same style as in AppBar
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withValues(alpha: 0.9),
                                            Colors.white.withValues(alpha: 0.4),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        color: maroonPrimary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Title text with glowing effect - same as AppBar title
                                    ShaderMask(
                                      shaderCallback: (Rect bounds) {
                                        return LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.white,
                                            Colors.white.withValues(alpha: 0.9),
                                          ],
                                        ).createShader(bounds);
                                      },
                                      blendMode: BlendMode.srcIn,
                                      child: Text(
                                        Utils.getTranslatedLabel(
                                            createLessonKey),
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          shadows: [
                                            const Shadow(
                                              color: Colors.black26,
                                              offset: Offset(0, 1),
                                              blurRadius: 3,
                                            ),
                                          ],
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
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper functions borrowed from CustomFilterModernAppBar for consistency
  Color _getLightenedColor(Color baseColor, double factor) {
    HSLColor hsl = HSLColor.fromColor(baseColor);
    return hsl
        .withLightness((hsl.lightness + factor).clamp(0.0, 1.0))
        .toColor();
  }

  Color _getDarkenedColor(Color baseColor, double factor) {
    HSLColor hsl = HSLColor.fromColor(baseColor);
    return hsl
        .withLightness((hsl.lightness - factor).clamp(0.0, 1.0))
        .toColor();
  }

  Widget _buildHeaderSection() {
    return BlocBuilder<GradeLevelCubit, GradeLevelState>(
      builder: (context, gradeLevelState) {
        return BlocBuilder<ClassSectionsAndSubjectsCubit,
            ClassSectionsAndSubjectsState>(
          builder: (context, classSectionState) {
            // Create filter configs for the CustomFilterModernAppBar
            FilterItemConfig? gradeLevelFilter;
            FilterItemConfig? classSectionFilter;
            FilterItemConfig? subjectFilter;

            // Grade Level Filter - always available
            if (gradeLevelState is GradeLevelFetchSuccess) {
              gradeLevelFilter = FilterItemConfig(
                title: _selectedGradeLevel?.name ?? "Pilih Tingkatan",
                icon: Icons.school_rounded,
                onTap: () {
                  if (gradeLevelState.gradeLevels.isEmpty) {
                    _showSnackBar("Tidak ada tingkatan yang tersedia");
                    return;
                  }

                  HapticFeedback.lightImpact();
                  Utils.showBottomSheet(
                    child: FilterSelectionBottomsheet<GradeLevel>(
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
                  ).then((result) {
                    if (result == null && _selectedGradeLevel == null) {
                      // Dialog closed without selection, auto-select first grade level
                      changeSelectedGradeLevel(
                          gradeLevelState.gradeLevels.first);
                    }
                  });
                },
              );
            }

            // Class Section Filter - available when we have class sections
            if (classSectionState is ClassSectionsAndSubjectsFetchSuccess) {
              // Filter classes based on selected grade level if any
              List<ClassSection> availableClasses =
                  classSectionState.classSections;

              // If a grade level is selected, filter classes by grade level
              if (_selectedGradeLevel != null) {
                availableClasses = classSectionState.classSections
                    .where((classSection) =>
                        classSection.gradeLevelId == _selectedGradeLevel!.id)
                    .toList();
              }

              if (availableClasses.isNotEmpty) {
                classSectionFilter = FilterItemConfig(
                  title: _selectedClassSection?.name ?? "Pilih Kelas",
                  icon: Icons.class_rounded,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Utils.showBottomSheet(
                      child: FilterSelectionBottomsheet<ClassSection>(
                        onSelection: (value) {
                          if (value != null) {
                            changeSelectedClassSection(value);
                            Get.back();
                          }
                        },
                        selectedValue:
                            _selectedClassSection ?? availableClasses.first,
                        titleKey: classKey,
                        values: availableClasses, // Use filtered classes
                      ),
                      context: context,
                    ).then((result) {
                      if (result == null && _selectedClassSection == null) {
                        // Dialog closed without selection, auto-select first class section
                        changeSelectedClassSection(availableClasses.first);
                      }
                    });
                  },
                );
              }

              // Subject Filter - only available after class section selected
              if (_selectedClassSection != null) {
                subjectFilter = FilterItemConfig(
                  title: _selectedSubject?.subject.getSybjectNameWithType() ??
                      "Pilih Mapel",
                  icon: Icons.book_rounded,
                  onTap: () {
                    if (classSectionState.subjects.isEmpty) {
                      _showSnackBar("Tidak ada mata pelajaran yang tersedia");
                      return;
                    }

                    HapticFeedback.lightImpact();
                    Utils.showBottomSheet(
                      child: FilterSelectionBottomsheet<TeacherSubject>(
                        onSelection: (value) {
                          if (value != null) {
                            changeSelectedTeacherSubject(value);
                            Get.back();
                          }
                        },
                        selectedValue: _selectedSubject ??
                            classSectionState.subjects.first,
                        values: classSectionState.subjects,
                        titleKey: subjectKey,
                      ),
                      context: context,
                    ).then((result) {
                      if (result == null && _selectedSubject == null) {
                        // Dialog closed without selection, auto-select first subject
                        changeSelectedTeacherSubject(
                            classSectionState.subjects.first);
                      }
                    });
                  },
                );
              }
            }

            // Calculate height dynamically based on available filters
            double dynamicHeight = 200.0; // Base height
            if (gradeLevelFilter != null &&
                classSectionFilter != null &&
                subjectFilter != null) {
              dynamicHeight = 250.0; // 3 filters need more space
            } else if ((gradeLevelFilter != null &&
                    classSectionFilter != null) ||
                (gradeLevelFilter != null && subjectFilter != null) ||
                (classSectionFilter != null && subjectFilter != null)) {
              dynamicHeight = 200.0; // 2 filters work well with base height
            }

            // Return the new modern AppBar with filters
            return CustomFilterModernAppBar(
              title: Utils.getTranslatedLabel(manageLessonKey),
              titleIcon: Icons.menu_book_rounded,
              primaryColor: maroonPrimary,
              secondaryColor: maroonLight,
              onBackPressed: () => Navigator.pop(context),
              firstFilterItem: gradeLevelFilter,
              secondFilterItem: classSectionFilter,
              thirdFilterItem: subjectFilter,
              height: dynamicHeight,
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: maroonPrimary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = ThemeData(
      primaryColor: maroonPrimary,
      scaffoldBackgroundColor: bgColor,
      textTheme: GoogleFonts.poppinsTextTheme(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: maroonPrimary,
        primary: maroonPrimary,
        secondary: maroonLight,
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            BlocBuilder<GradeLevelCubit, GradeLevelState>(
              builder: (context, gradeLevelState) {
                if (gradeLevelState is GradeLevelFetchSuccess) {
                  return BlocBuilder<ClassSectionsAndSubjectsCubit,
                      ClassSectionsAndSubjectsState>(
                    builder: (context, classSectionState) {
                      if (classSectionState
                          is ClassSectionsAndSubjectsFetchSuccess) {
                        return Stack(
                          children: [
                            _buildLessonList(),
                            _buildHeaderSection(),
                            _buildSubmitButton(),
                          ],
                        );
                      }
                      if (classSectionState
                          is ClassSectionsAndSubjectsFetchFailure) {
                        return Center(
                          child: CustomErrorWidget(
                            message:
                                "Gagal mendapatkan data kelas dan mata pelajaran, mohon coba lagi",
                            onRetry: () {
                              context
                                  .read<ClassSectionsAndSubjectsCubit>()
                                  .getClassSectionsAndSubjects();
                            },
                            primaryColor: maroonPrimary,
                          ),
                        );
                      }
                      // Loading state for class sections - show simplified header with grade level only
                      return Column(
                        children: [
                          CustomFilterModernAppBar(
                            title: Utils.getTranslatedLabel(manageLessonKey),
                            titleIcon: Icons.menu_book_rounded,
                            primaryColor: maroonPrimary,
                            secondaryColor: maroonLight,
                            onBackPressed: () => Navigator.pop(context),
                            height:
                                200, // Height for loading with partial filters
                            // Only show grade level filter if available
                            firstFilterItem: FilterItemConfig(
                              title: _selectedGradeLevel?.name ??
                                  "Pilih Tingkatan",
                              icon: Icons.school_rounded,
                              onTap: () {
                                if (gradeLevelState.gradeLevels.isEmpty) {
                                  _showSnackBar(
                                      "Tidak ada tingkatan yang tersedia");
                                  return;
                                }

                                HapticFeedback.lightImpact();
                                Utils.showBottomSheet(
                                  child: FilterSelectionBottomsheet<GradeLevel>(
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
                              },
                            ),
                            // Show loading placeholders for other filters
                            secondFilterItem: FilterItemConfig(
                              title: "Memuat kelas...",
                              icon: Icons.class_rounded,
                              onTap: () {}, // Disabled during loading
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.only(
                                top: 20,
                                left: 16,
                                right: 16,
                                bottom: 20,
                              ),
                              itemCount: 5,
                              itemBuilder: (context, index) =>
                                  const SkeletonLessonCard(),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }

                if (gradeLevelState is GradeLevelFetchFailure) {
                  return Center(
                    child: CustomErrorWidget(
                      message:
                          "Gagal mendapatkan data tingkat, mohon coba lagi",
                      onRetry: () {
                        context.read<GradeLevelCubit>().getGradeLevels();
                      },
                      primaryColor: maroonPrimary,
                    ),
                  );
                }

                // Loading state for grade level - show simplified header
                return Column(
                  children: [
                    // Use a simplified header during initial loading state
                    CustomFilterModernAppBar(
                      title: Utils.getTranslatedLabel(manageLessonKey),
                      titleIcon: Icons.menu_book_rounded,
                      primaryColor: maroonPrimary,
                      secondaryColor: maroonLight,
                      onBackPressed: () => Navigator.pop(context),
                      height: 150, // Reduced height for loading state
                      // No filter items during loading to prevent glitch
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          top: 20,
                          left: 16,
                          right: 16,
                          bottom: 20,
                        ),
                        itemCount: 5,
                        itemBuilder: (context, index) =>
                            const SkeletonLessonCard(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

