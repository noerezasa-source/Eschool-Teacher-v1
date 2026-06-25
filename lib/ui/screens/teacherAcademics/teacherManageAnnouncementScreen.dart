import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/announcement/teacherAnnouncementsCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/announcement/teacherDeleteAnnouncementCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/classSectionsAndSubjects.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/gradeLevelCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/announcement/teacherAnnouncement.dart';
import 'package:eschool_saas_staff/data/models/academic/teacherSubject.dart';
import 'package:eschool_saas_staff/data/models/academic/gradeLevel.dart';
import 'package:eschool_saas_staff/data/models/academic/studyMaterial.dart';


import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherAddEditAnnouncementScreen.dart';
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

// Define missing key constants
const String noAnnouncementKey = 'noAnnouncement';
const String createAnnouncementKey = 'createAnnouncement';

class TeacherManageAnnouncementScreen extends StatefulWidget {
  static Widget getRouteInstance() {
    //final arguments = Get.arguments as Map<String,dynamic>;
    return MultiBlocProvider(providers: [
      BlocProvider(
        create: (context) => TeacherAnnouncementsCubit(),
      ),
      BlocProvider(
        create: (context) => ClassSectionsAndSubjectsCubit(),
      ),
      BlocProvider(
        create: (context) => GradeLevelCubit(),
      ),
    ], child: const TeacherManageAnnouncementScreen());
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  const TeacherManageAnnouncementScreen({super.key});

  @override
  State<TeacherManageAnnouncementScreen> createState() =>
      _TeacherManageAnnouncementScreenState();
}

class _TeacherManageAnnouncementScreenState
    extends State<TeacherManageAnnouncementScreen>
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
        context
            .read<ClassSectionsAndSubjectsCubit>()
            .getClassSectionsAndSubjects();
        context.read<GradeLevelCubit>().getGradeLevels();
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.maxScrollExtent ==
          _scrollController.offset) {
        if (context.read<TeacherAnnouncementsCubit>().hasMore()) {
          getMoreAnnouncements();
        }
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

  void scrollListener() {
    if (_scrollController.position.maxScrollExtent ==
        _scrollController.offset) {
      if (context.read<TeacherAnnouncementsCubit>().hasMore()) {
        getMoreAnnouncements();
      }
    }
  }

  // Helper method to check if description is long enough to truncate
  bool _isDescriptionLong(String description) {
    // Consider a description long if it's more than 150 characters
    // or has more than 3 newlines
    return description.length > 150 || '\n'.allMatches(description).length > 2;
  }

  // Show dialog with full description
  void _showFullDescriptionDialog(
      BuildContext context, TeacherAnnouncement announcement) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 16,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with title
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [maroonPrimary, maroonLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          Utils.getTranslatedLabel(descriptionKey),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable description content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement.title,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textDarkColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: maroonPrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: maroonPrimary.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: maroonPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                Utils.getFormattedDate(announcement.createdAt),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: maroonPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          announcement.description,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: textMediumColor,
                            height: 1.6,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom close button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Material(
                    borderRadius: BorderRadius.circular(16),
                    color: maroonPrimary,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: Text(
                          "Tutup",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
      ),
    );
  }

  void changeSelectedGradeLevel(GradeLevel? gradeLevel) {
    if (_selectedGradeLevel != gradeLevel) {
      _selectedGradeLevel = gradeLevel;

      // Reset class section and subject selection
      _selectedClassSection = null;
      _selectedSubject = null;

      setState(() {});

      // If grade level is selected, filter class sections automatically
      if (gradeLevel != null) {
        final state = context.read<ClassSectionsAndSubjectsCubit>().state;
        if (state is ClassSectionsAndSubjectsFetchSuccess) {
          final filteredClassSections = state.classSections
              .where(
                  (classSection) => classSection.gradeLevelId == gradeLevel.id)
              .toList();

          // If there are filtered class sections, auto-select the first one
          if (filteredClassSections.isNotEmpty) {
            changeSelectedClassSection(filteredClassSections.first);
          }
        }
      } else {
        // If no grade level selected, fetch all class sections
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
      debugPrint('Selected Class Section: ${classSection?.id}');
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
      getAnnouncements();
    }
  }

  void getAnnouncements() {
    context.read<TeacherAnnouncementsCubit>().fetchTeacherAnnouncements(
        classSubjectId: _selectedSubject?.classSubjectId ?? 0,
        classSectionId: _selectedClassSection?.id ?? 0);
  }

  void getMoreAnnouncements() {
    context.read<TeacherAnnouncementsCubit>().fetchMoreTeacherAnnouncements(
        classSubjectId: _selectedSubject?.classSubjectId ?? 0,
        classSectionId: _selectedClassSection?.id ?? 0);
  }

  Widget _buildAnnouncementItem({required TeacherAnnouncement announcement}) {
    return BlocProvider(
      create: (context) => TeacherDeleteAnnouncementCubit(),
      child: Builder(builder: (context) {
        return BlocConsumer<TeacherDeleteAnnouncementCubit,
            TeacherDeleteAnnouncementState>(
          listener: (context, state) {
            if (state is TeacherDeleteAnnouncementSuccess) {
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
                            "${Utils.getTranslatedLabel('announcementDeletedSuccessfully')} ${announcement.title}",
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
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                ),
              );
              context
                  .read<TeacherAnnouncementsCubit>()
                  .deleteTeacherAnnouncement(announcementId: announcement.id);
            } else if (state is TeacherDeleteAnnouncementFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "${Utils.getTranslatedLabel('unableToDeleteAnnouncement')} ${announcement.title}",
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
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                                // Enhanced typography and layout for announcement title
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        announcement.title,
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: textDarkColor,
                                          letterSpacing: -0.3,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Date display with improved styling
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color:
                                              maroonPrimary.withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color:
                                                maroonPrimary.withValues(alpha: 0.15),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 14,
                                              color: maroonPrimary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              Utils.getFormattedDate(
                                                  announcement.createdAt),
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
                                                    .teacherAddEditAnnouncementScreen,
                                                arguments: TeacherAddEditAnnouncementScreen
                                                    .buildArguments(
                                                        announcement:
                                                            announcement,
                                                        selectedClassSection:
                                                            _selectedClassSection,
                                                        selectedSubject:
                                                            _selectedSubject))
                                            ?.then((value) {
                                          if (value != null &&
                                              value is bool &&
                                              value) {
                                            getAnnouncements();
                                          }
                                        });
                                      } else if (value == 'delete') {
                                        if (state
                                            is TeacherDeleteAnnouncementInProgress) {
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
                                                  .read<
                                                      TeacherDeleteAnnouncementCubit>()
                                                  .deleteAnnouncement(
                                                    announcementId:
                                                        announcement.id,
                                                  );
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
                                          duration: const Duration(milliseconds: 200),
                                          builder: (context, value, child) {
                                            return Transform.scale(
                                              scale: value,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                    vertical: 8, horizontal: 8),
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
                                                          .withValues(alpha: 0.3),
                                                      blurRadius: 12,
                                                      offset: const Offset(0, 4),
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
                                                          const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withValues(alpha: 0.25),
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
                                                        Utils
                                                            .getTranslatedLabel(
                                                                'edit'),
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
                                          duration: const Duration(milliseconds: 300),
                                          builder: (context, value, child) {
                                            return Transform.scale(
                                              scale: value,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                    vertical: 8, horizontal: 8),
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
                                                          .withValues(alpha: 0.3),
                                                      blurRadius: 12,
                                                      offset: const Offset(0, 4),
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
                                                          const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withValues(alpha: 0.25),
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
                                                        Utils
                                                            .getTranslatedLabel(
                                                                'delete'),
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
                                      duration: const Duration(milliseconds: 300),
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              gradient: state
                                                      is TeacherDeleteAnnouncementInProgress
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
                                                    is TeacherDeleteAnnouncementInProgress
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
                                    color: maroonPrimary.withValues(alpha: 0.08),
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

                            // Elegant description container with enhanced readability and ellipsis support
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    announcement.description,
                                    maxLines: _isDescriptionLong(
                                            announcement.description)
                                        ? 3
                                        : null,
                                    overflow: _isDescriptionLong(
                                            announcement.description)
                                        ? TextOverflow.ellipsis
                                        : TextOverflow.visible,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.5,
                                      color: textMediumColor,
                                      height: 1.6,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                  if (_isDescriptionLong(
                                      announcement.description))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: InkWell(
                                        onTap: () {
                                          _showFullDescriptionDialog(
                                              context, announcement);
                                        },
                                        child: Text(
                                          "Lihat selengkapnya",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: maroonPrimary,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Attachments section with enhanced styling
                      if (announcement.files.isNotEmpty)
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
                                      color: maroonPrimary.withValues(alpha: 0.08),
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
                                    "Lampiran",
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
                                            color:
                                                maroonPrimary.withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: maroonPrimary
                                                  .withValues(alpha: 0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            "${announcement.files.length}",
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
                                    children: announcement.files
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final index = entry.key;
                                      final file = entry.value;

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
                                                color: maroonPrimary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                _getFileTypeIcon(file.fileName),
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
                                                    file.fileName,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: textDarkColor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _getFileType(file.fileName),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: textMediumColor,
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
                                                    studyMaterial: StudyMaterial.fromURL(file.fileUrl),
                                                  );
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: maroonPrimary
                                                        .withValues(
                                                            alpha: 0.07),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            14),
                                                  ),
                                                  child: Icon(
                                                    Icons.download_rounded,
                                                    color: maroonPrimary,
                                                    size: 20,
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

  Widget _buildAnnouncementList() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 70, top: 20),
        child:
            BlocBuilder<TeacherAnnouncementsCubit, TeacherAnnouncementsState>(
          builder: (context, state) {
            if (state is TeacherAnnouncementsFetchSuccess) {
              if (state.announcements.isEmpty) {
                return Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.campaign_outlined,
                            color: textMediumColor,
                            size: 80,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Tidak ada pengumuman yang tersedia",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                              color: textMediumColor,
                            ),
                          ),
                          SizedBox(height: 20),
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

                      // Announcements
                      ...List.generate(
                          state.announcements.length,
                          (index) => _buildAnnouncementItem(
                              announcement: state.announcements[index])),
                    ],
                  ),
                ),
              );
            } else if (state is TeacherAnnouncementsFetchFailure) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.only(
                      top: topPaddingOfErrorAndLoadingContainer),
                  child: CustomErrorWidget(
                    message: "Gagal mendapatkan pengumuman, mohon coba lagi",
                    onRetry: () {
                      getAnnouncements();
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
                        child: Icon(
                          Icons.campaign_outlined,
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
                Positioned.fill(
                  child: CustomPaint(
                    painter: AppBarDecorationPainter(
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),
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
                              Get.toNamed(
                                      Routes.teacherAddEditAnnouncementScreen,
                                      arguments:
                                          TeacherAddEditAnnouncementScreen
                                              .buildArguments(
                                                  announcement: null,
                                                  selectedClassSection:
                                                      _selectedClassSection,
                                                  selectedSubject:
                                                      _selectedSubject))
                                  ?.then((value) {
                                if (value != null && value is bool && value) {
                                  getAnnouncements();
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
                                            color:
                                                Colors.black.withValues(alpha: 0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
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
                                        "Buat Pengumuman",
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

  Widget _buildHeaderSection() {
    // Create filter configs for the CustomFilterModernAppBar
    FilterItemConfig? gradeLevelFilter;
    FilterItemConfig? classSectionFilter;
    FilterItemConfig? subjectFilter;

    // Grade Level Filter
    final gradeLevelState = context.read<GradeLevelCubit>().state;
    if (gradeLevelState is GradeLevelFetchSuccess) {
      gradeLevelFilter = FilterItemConfig(
        title: _selectedGradeLevel?.name ?? "Pilih Tingkatan",
        icon: Icons.school_rounded,
        onTap: () {
          if (gradeLevelState.gradeLevels.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Tidak ada tingkatan yang tersedia"),
                backgroundColor: maroonPrimary,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          HapticFeedback.lightImpact();
          Utils.showBottomSheet(
            child: FilterSelectionBottomsheet<GradeLevel>(
              titleKey: gradeLevelKey,
              values: gradeLevelState.gradeLevels,
              selectedValue:
                  _selectedGradeLevel ?? gradeLevelState.gradeLevels.first,
              onSelection: (value) {
                if (value != null) {
                  Navigator.pop(context);
                  changeSelectedGradeLevel(value);
                }
              },
            ),
            context: context,
          ).then((result) {
            if (result == null && _selectedGradeLevel == null) {
              // Dialog closed without selection, auto-select first grade level
              changeSelectedGradeLevel(gradeLevelState.gradeLevels.first);
            }
          });
        },
      );
    }

    // Create filters based on the current state
    final state = context.read<ClassSectionsAndSubjectsCubit>().state;
    if (state is ClassSectionsAndSubjectsFetchSuccess) {
      // Filter class sections based on selected grade level
      List<ClassSection> filteredClassSections = state.classSections;
      if (_selectedGradeLevel != null) {
        filteredClassSections = state.classSections
            .where((classSection) =>
                classSection.gradeLevelId == _selectedGradeLevel!.id)
            .toList();
      }

      // Class Section Filter
      classSectionFilter = FilterItemConfig(
        title: _selectedClassSection?.name ?? "Pilih Kelas",
        icon: Icons.class_rounded,
        onTap: () {
          if (filteredClassSections.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_selectedGradeLevel != null
                    ? "Tidak ada kelas yang tersedia untuk tingkatan ${_selectedGradeLevel!.name}"
                    : "Tidak ada kelas yang tersedia untuk guru ini"),
                backgroundColor: maroonPrimary,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          HapticFeedback.lightImpact();
          Utils.showBottomSheet(
                  child: FilterSelectionBottomsheet<ClassSection>(
                    titleKey: classKey,
                    values: filteredClassSections,
                    selectedValue:
                        _selectedClassSection ?? filteredClassSections.first,
                    onSelection: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        changeSelectedClassSection(value);
                      }
                    },
                  ),
                  context: context)
              .then((result) {
            if (result == null && _selectedClassSection == null) {
              // Dialog closed without selection, auto-select first class section
              changeSelectedClassSection(filteredClassSections.first);
            }
          });
        },
      );

      // Subject Filter
      subjectFilter = FilterItemConfig(
        title:
            _selectedSubject?.subject.getSybjectNameWithType() ?? "Pilih Mapel",
        icon: Icons.announcement_rounded,
        onTap: () {
          if (state.subjects.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    "Tidak ada mata pelajaran yang tersedia untuk guru ini"),
                backgroundColor: maroonPrimary,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          HapticFeedback.lightImpact();
          Utils.showBottomSheet(
                  child: FilterSelectionBottomsheet<TeacherSubject>(
                    titleKey: subjectKey,
                    selectedValue: _selectedSubject ?? state.subjects.first,
                    values: state.subjects,
                    onSelection: (value) {
                      if (value != null) {
                        Navigator.pop(context);
                        if (_selectedSubject != value) {
                          changeSelectedTeacherSubject(value);
                        }
                      }
                    },
                  ),
                  context: context)
              .then((result) {
            if (result == null && _selectedSubject == null) {
              // Dialog closed without selection, auto-select first subject
              changeSelectedTeacherSubject(state.subjects.first);
            }
          });
        },
      );
    }

    // Return the new modern AppBar with filters
    return CustomFilterModernAppBar(
      title: Utils.getTranslatedLabel(manageAnnouncementKey),
      titleIcon: Icons.campaign_rounded,
      primaryColor: maroonPrimary,
      secondaryColor: maroonLight,
      onBackPressed: () => Navigator.pop(context),
      firstFilterItem: gradeLevelFilter,
      secondFilterItem: classSectionFilter,
      thirdFilterItem: subjectFilter,
      height: 250.0, // Increased height for 3 filters
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
        body: BlocBuilder<ClassSectionsAndSubjectsCubit,
            ClassSectionsAndSubjectsState>(
          builder: (context, state) {
            return Column(
              children: [
                // Header section - now as a normal widget in Column
                _buildHeaderSection(),

                // Content area with different states
                Expanded(
                  child: Stack(
                    children: [
                      if (state is ClassSectionsAndSubjectsFetchSuccess) ...[
                        _buildAnnouncementList(),
                        _buildSubmitButton(),
                      ] else if (state is ClassSectionsAndSubjectsFetchFailure)
                        Container(
                          padding: const EdgeInsets.only(top: 20),
                          child: Center(
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
                          ),
                        )
                      else
                        // Loading state - show skeleton with proper padding
                        Container(
                          padding: EdgeInsets.fromLTRB(
                            appContentHorizontalPadding,
                            20,
                            appContentHorizontalPadding,
                            0,
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            itemCount: 4,
                            itemBuilder: (context, index) =>
                                const SkeletonAnnouncementCard(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

