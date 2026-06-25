import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/classSectionsAndSubjects.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/gradeLevelCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/lesson/lessonsCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/topic/deleteTopicCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/topic/topicsCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/academic/gradeLevel.dart';
import 'package:eschool_saas_staff/data/models/academic/lesson.dart';
import 'package:eschool_saas_staff/data/models/academic/teacherSubject.dart';
import 'package:eschool_saas_staff/data/models/academic/topic.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherAddEditTopicScreen.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/confirmDeleteDialog.dart';
import 'package:eschool_saas_staff/ui/widgets/system/errorContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Define our theme colors
Color get maroonPrimary => AppColorPalette.primaryMaroon;
Color get maroonLight => AppColorPalette.secondaryMaroon;
const Color maroonDark = Color(0xFF6A0F2A);
Color get accentColor => AppColorPalette.lightMaroon;
Color get bgColor => AppColorPalette.accentPink;
const Color cardColor = Colors.white;
const Color textDarkColor = Color(0xFF2D2D2D);
const Color textMediumColor = Color(0xFF717171);
const Color borderColor = Color(0xFFE8E8E8);

class TeacherManageTopicScreen extends StatefulWidget {
  final ClassSection? selectedClassSection;
  final TeacherSubject? selectedSubject;
  final Lesson? selectedLesson;

  static Widget getRouteInstance() {
    final arguments = Get.arguments as Map<String, dynamic>?;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => LessonsCubit()),
        BlocProvider(create: (context) => ClassSectionsAndSubjectsCubit()),
        BlocProvider(create: (context) => TopicsCubit()),
        BlocProvider(create: (context) => GradeLevelCubit()),
      ],
      child: TeacherManageTopicScreen(
        selectedClassSection: arguments?['selectedClassSection'],
        selectedSubject: arguments?['selectedSubject'],
        selectedLesson: arguments?['selectedLesson'],
      ),
    );
  }

  static Map<String, dynamic> buildArguments({
    required ClassSection? selectedClassSection,
    required TeacherSubject? selectedSubject,
    required Lesson? selectedLesson,
  }) {
    return {
      "selectedClassSection": selectedClassSection,
      "selectedSubject": selectedSubject,
      "selectedLesson": selectedLesson,
    };
  }

  const TeacherManageTopicScreen({
    super.key,
    this.selectedClassSection,
    this.selectedSubject,
    this.selectedLesson,
  });

  @override
  State<TeacherManageTopicScreen> createState() =>
      _TeacherManageTopicScreenState();
}

class _TeacherManageTopicScreenState extends State<TeacherManageTopicScreen>
    with TickerProviderStateMixin {
  ClassSection? _selectedClassSection;
  TeacherSubject? _selectedSubject;
  Lesson? _selectedLesson;
  GradeLevel? _selectedGradeLevel;
  bool didCreateNewTopic = false; // For tracking new topic creation
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _fabAnimationController;

  // For header collapsing effect
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState(); // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Initialize app bar animation controller
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _fabAnimationController.forward();

    if (widget.selectedLesson == null) {
      Future.delayed(Duration.zero, () {
        if (mounted) {
          context.read<GradeLevelCubit>().getGradeLevels();
          context
              .read<ClassSectionsAndSubjectsCubit>()
              .getClassSectionsAndSubjects();
        }
      });
    } else {
      _selectedLesson = widget.selectedLesson;
      _selectedSubject = widget.selectedSubject;
      _selectedClassSection = widget.selectedClassSection;
      getTopics();
      // Initialize grade level cubit even when we have selected lesson
      Future.delayed(Duration.zero, () {
        if (mounted) {
          context.read<GradeLevelCubit>().getGradeLevels();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void changeSelectedClassSection(ClassSection? classSection,
      {bool fetchNewSubjects = true}) {
    if (_selectedClassSection != classSection) {
      _selectedClassSection = classSection;
      // Reset subject and lesson when changing class
      _selectedSubject = null;
      _selectedLesson = null;

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
        context
            .read<ClassSectionsAndSubjectsCubit>()
            .getClassSectionsAndSubjects(gradeLevelId: _selectedGradeLevel!.id);
      } else {
        // If no grade level selected, show all classes
        context
            .read<ClassSectionsAndSubjectsCubit>()
            .getClassSectionsAndSubjects();
      }

      // Clear topics since filters have changed
      context.read<TopicsCubit>().updateState(TopicsFetchSuccess([]));
    }
  }

  void changeSelectedTeacherSubject(TeacherSubject? teacherSubject) {
    if (_selectedSubject != teacherSubject) {
      _selectedSubject = teacherSubject;
      // Reset lesson when changing subject
      _selectedLesson = null;
      setState(() {});
      getLessons();
    }
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

  void getLessons() {
    context.read<LessonsCubit>().fetchLessons(
        classSubjectId: _selectedSubject?.classSubjectId ?? 0,
        classSectionId: _selectedClassSection?.id ?? 0);
  }

  void getTopics() {
    if (_selectedLesson != null) {
      context.read<TopicsCubit>().fetchTopics(lessonId: _selectedLesson!.id);
    }
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

  Widget _buildTopicItem({required Topic topic}) {
    return BlocProvider(
      create: (context) => DeleteTopicCubit(),
      child: Builder(builder: (context) {
        return BlocConsumer<DeleteTopicCubit, DeleteTopicState>(
          listener: (context, state) {
            if (state is DeleteTopicSuccess) {
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
                            "${Utils.getTranslatedLabel(topicDeletedSuccessfullyKey)} ${topic.name}",
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
              context.read<TopicsCubit>().deleteTopic(topic.id);
            } else if (state is DeleteTopicFailure) {
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
                            "${Utils.getTranslatedLabel(unableToDeleteTopicKey)} ${topic.name}",
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
                margin: const EdgeInsets.only(
                  bottom: 30,
                  left: 16,
                  right: 16,
                ),
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
                                gradient: LinearGradient(
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
                                // Enhanced typography and layout for topic title
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        topic.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: textDarkColor,
                                          letterSpacing: -0.3,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
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
                                          Routes.teacherAddEditTopicScreen,
                                          arguments: TeacherAddEditTopicScreen
                                              .buildArguments(
                                            topic: topic,
                                            selectedClassSection:
                                                _selectedClassSection,
                                            selectedLesson: _selectedLesson,
                                            selectedSubject: _selectedSubject,
                                          ),
                                        )?.then((value) {
                                          if (value != null &&
                                              value is bool &&
                                              value) {
                                            // Delay to let pop animation finish
                                            Future.delayed(
                                                const Duration(
                                                    milliseconds: 300), () {
                                              if (mounted) {
                                                getTopics();
                                              }
                                            });
                                          }
                                        });
                                      } else if (value == 'delete') {
                                        if (state is DeleteTopicInProgress) {
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
                                                  .read<DeleteTopicCubit>()
                                                  .deleteTopic(
                                                      topicId: topic.id);
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
                                                        'Hapus',
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
                                                      is DeleteTopicInProgress
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
                                                    is DeleteTopicInProgress
                                                ? Center(
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
                                                : Icon(
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
                                  child: Icon(
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
                                topic.description,
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

                      // Study materials section with enhanced styling - similar to lesson screen
                      if (topic.studyMaterials.isNotEmpty)
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
                                    child: Icon(
                                      Icons.attach_file_rounded,
                                      color: maroonPrimary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Materi Topik",
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
                                            "${topic.studyMaterials.length}",
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
                                    children: topic.studyMaterials
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
                                                  Utils
                                                      .viewOrDownloadStudyMaterial(
                                                    context: context,
                                                    storeInExternalStorage:
                                                        true,
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

  Widget _buildTopicList() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(
          bottom: 80,
          left: 8,
          right: 8,
          // Adjusted top padding to work with CustomModernAppBar
          top: 20, // CustomModernAppBar height (180) + additional space (80)
        ),
        child: BlocBuilder<TopicsCubit, TopicsState>(
          builder: (context, state) {
            if (state is TopicsFetchSuccess) {
              if (state.topics.isEmpty) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.topic_outlined,
                          color: maroonPrimary,
                          size: 56,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          Utils.getTranslatedLabel(noTopicKey),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Silahkan tambahkan topik baru",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: List.generate(
                  state.topics.length,
                  (index) => _buildTopicItem(topic: state.topics[index]),
                ),
              );
            } else if (state is TopicsFetchFailure) {
              return Center(
                child: ErrorContainer(
                  errorMessage:
                      Utils.getTranslatedLabel(defaultErrorMessageKey),
                  onTapRetry: () {
                    getTopics();
                  },
                ),
              );
            } else {
              // Instead of showing loading indicator, show message to select class, subject and chapter
              if (_selectedClassSection == null ||
                  _selectedSubject == null ||
                  _selectedLesson == null) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: maroonPrimary,
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Silahkan pilih kelas, mata pelajaran, dan bab terlebih dahulu",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Gunakan filter di atas untuk memilih",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              // Show skeleton loading when all selections are made
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  children: List.generate(
                    5,
                    (index) => const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 5),
                      child: SkeletonAssignmentCard(),
                    ),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              Get.toNamed(
                Routes.teacherAddEditTopicScreen,
                arguments: TeacherAddEditTopicScreen.buildArguments(
                  topic: null,
                  selectedClassSection: _selectedClassSection,
                  selectedLesson: _selectedLesson,
                  selectedSubject: _selectedSubject,
                ),
              )?.then((value) {
                if (value != null && value is bool && value) {
                  // Delay to let pop animation finish
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      getTopics();
                      didCreateNewTopic = true;
                    }
                  });
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    maroonPrimary,
                    const Color(0xFF9A1E3C),
                    maroonLight,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: maroonPrimary.withValues(alpha: 0.3),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      Utils.getTranslatedLabel(createTopicKey),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 500.ms),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  CustomModernAppBar _buildAppBar() {
    return CustomModernAppBar(
      title: Utils.getTranslatedLabel(manageTopicKey),
      icon: Icons.topic_rounded,
      fabAnimationController: _fabAnimationController,
      primaryColor: maroonPrimary,
      lightColor: maroonLight,
      height: 260, // Adjusted height for new layout
      onBackPressed: () {
        Get.back(result: didCreateNewTopic);
      },
      tabBuilder: (context) => _buildFilterTabs(),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 140, // Slightly increased height for better spacing
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Top row with Grade Level and Class Section filters
          Row(
            children: [
              // Grade Level filter
              Expanded(
                child: BlocBuilder<GradeLevelCubit, GradeLevelState>(
                  builder: (context, gradeLevelState) {
                    return _buildFilterButton(
                      icon: Icons.school_rounded,
                      text: _selectedGradeLevel?.name ?? "Pilih Tingkatan",
                      onTap: () {
                        if (gradeLevelState is GradeLevelFetchSuccess) {
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
                        }
                      },
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Class Section filter
              Expanded(
                child: BlocBuilder<ClassSectionsAndSubjectsCubit,
                    ClassSectionsAndSubjectsState>(
                  builder: (context, state) {
                    return _buildFilterButton(
                      icon: Icons.class_rounded,
                      text: _selectedClassSection?.name ?? "Pilih Kelas",
                      onTap: () {
                        if (state is ClassSectionsAndSubjectsFetchSuccess) {
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

                          if (availableClasses.isEmpty) {
                            _showSnackBar("Tidak ada kelas yang tersedia");
                            return;
                          }

                          HapticFeedback.lightImpact();
                          Utils.showBottomSheet(
                            child: FilterSelectionBottomsheet<ClassSection>(
                              onSelection: (value) {
                                if (value != null) {
                                  changeSelectedClassSection(value);
                                  Get.back();
                                }
                              },
                              selectedValue: _selectedClassSection ??
                                  availableClasses.first,
                              values: availableClasses,
                              titleKey: classKey,
                            ),
                            context: context,
                          ).then((result) {
                            if (result == null &&
                                _selectedClassSection == null) {
                              // Dialog closed without selection, auto-select first class section
                              changeSelectedClassSection(
                                  availableClasses.first);
                            }
                          });
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bottom row with Subject and Lesson filters
          Row(
            children: [
              // Subject filter
              Expanded(
                child: BlocBuilder<ClassSectionsAndSubjectsCubit,
                    ClassSectionsAndSubjectsState>(
                  builder: (context, state) {
                    return _buildFilterButton(
                      icon: Icons.book_rounded,
                      text:
                          _selectedSubject?.subject.getSybjectNameWithType() ??
                              "Pilih Mapel",
                      onTap: () {
                        if (state is ClassSectionsAndSubjectsFetchSuccess) {
                          if (state.subjects.isEmpty) {
                            _showSnackBar(
                                "Tidak ada mata pelajaran yang tersedia");
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
                              selectedValue:
                                  _selectedSubject ?? state.subjects.first,
                              values: state.subjects,
                              titleKey: subjectKey,
                            ),
                            context: context,
                          ).then((result) {
                            if (result == null && _selectedSubject == null) {
                              // Dialog closed without selection, auto-select first subject
                              changeSelectedTeacherSubject(
                                  state.subjects.first);
                            }
                          });
                        }
                      },
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Lesson filter
              Expanded(
                child: BlocConsumer<LessonsCubit, LessonsState>(
                  listener: (context, state) {
                    if (state is LessonsFetchSuccess) {
                      if (state.lessons.isNotEmpty && _selectedLesson == null) {
                        _selectedLesson = state.lessons.first;
                        getTopics();
                        setState(() {});
                      }
                    }
                  },
                  builder: (context, state) {
                    return _buildFilterButton(
                      icon: Icons.menu_book_rounded,
                      text: _selectedLesson?.name ?? "Pilih Bab",
                      onTap: () {
                        if (state is LessonsFetchSuccess) {
                          if (state.lessons.isEmpty) {
                            _showSnackBar(
                                "Tidak ada bab pelajaran yang tersedia");
                            return;
                          }

                          HapticFeedback.lightImpact();
                          Utils.showBottomSheet(
                            child: FilterSelectionBottomsheet<Lesson>(
                              onSelection: (value) {
                                if (value != _selectedLesson) {
                                  _selectedLesson = value;
                                  getTopics();
                                  setState(() {});
                                }
                                Get.back();
                              },
                              selectedValue:
                                  _selectedLesson ?? state.lessons.first,
                              values: state.lessons,
                              titleKey: "Bab",
                            ),
                            context: context,
                          ).then((result) {
                            if (result == null && _selectedLesson == null) {
                              // Dialog closed without selection, auto-select first lesson
                              _selectedLesson = state.lessons.first;
                              getTopics();
                              setState(() {});
                            }
                          });
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        splashColor: Colors.white.withValues(alpha: 0.2),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GradeLevelCubit, GradeLevelState>(
      builder: (context, gradeLevelState) {
        if (gradeLevelState is GradeLevelFetchSuccess) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: Stack(
              children: [
                _buildTopicList(),
                _buildSubmitButton(),
              ],
            ),
          );
        }

        if (gradeLevelState is GradeLevelFetchFailure) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: maroonPrimary,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Gagal mendapatkan data tingkat, mohon coba lagi",
                    style: TextStyle(
                      fontSize: 16,
                      color: textMediumColor,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<GradeLevelCubit>().getGradeLevels();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: maroonPrimary,
                    ),
                    child: const Text(
                      "Coba Lagi",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemBuilder: (context, index) =>
                      const SkeletonAssignmentCard(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
