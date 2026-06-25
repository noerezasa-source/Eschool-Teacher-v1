import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/teacherMyTimetableCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/academics/timetableSlotContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherMyTimetableScreen extends StatefulWidget {
  static Widget getRouteInstance() {
    return const TeacherMyTimetableScreen();
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  const TeacherMyTimetableScreen({super.key});

  @override
  State<TeacherMyTimetableScreen> createState() =>
      _TeacherMyTimetableScreenState();
}

class _TeacherMyTimetableScreenState extends State<TeacherMyTimetableScreen>
    with TickerProviderStateMixin {
  late String _selectedDayKey = Utils.weekDays[DateTime.now().weekday - 1];

  // Animation controller for app bar effects
  late AnimationController _fabAnimationController;
  final ScrollController _scrollController = ScrollController();
  // Controller for horizontal day selector
  final ScrollController _dayScrollController = ScrollController();
  // Keys for each day pill to allow ensureVisible
  final List<GlobalKey> _dayKeys = List.generate(7, (_) => GlobalKey());

  // Theme colors
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  bool _focusedOnce = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scrollController.addListener(_scrollListener);
    debugPrint('TeacherMyTimetableScreen init - selected day: $_selectedDayKey');

    Future.delayed(Duration.zero, () {
      if (mounted) {
        // Initially fetch with the selected day key
        context.read<TeacherMyTimetableCubit>().getTeacherMyTimetable(
              dayKey: _selectedDayKey,
            );
        context.read<ClassesCubit>().getAllClasses();
      }
      // After first frame, ensure the selected day pill is visible and
      // trigger a rebuild so its selected styling/animation runs.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusSelectedDay();
      });
    });
  }

  void _scrollListener() {
    if (_scrollController.offset > 50) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _dayScrollController.dispose();
    _fabAnimationController.dispose();

    // Reset the timetable to show all days when leaving the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TeacherMyTimetableCubit>().getTeacherMyTimetable();
      }
    });

    super.dispose();
  }

  void _focusSelectedDay() {
    try {
      final int index = Utils.weekDays.indexOf(_selectedDayKey);
      if (index >= 0 && index < _dayKeys.length) {
        final ctx = _dayKeys[index].currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.5,
            duration: const Duration(milliseconds: 300),
          );
        }
      }
    } catch (e) {
      // ignore
    }
    // Force rebuild so animation/selection appears
    if (mounted) setState(() {});
  }

  Widget _buildDaySelector(BuildContext context) {
    // Use canonical weekday keys from Utils.weekDays (e.g. "mon","tue")
    // to ensure comparisons with _selectedDayKey succeed.
    final List<String> shortLabels = [
      'SEN',
      'SEL',
      'RAB',
      'KAM',
      'JUM',
      'SAB',
      'MIN'
    ];
    final List<String> longLabels = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];

    final List<Map<String, String>> weekDays = List.generate(7, (i) {
      final key = Utils.weekDays.length > i ? Utils.weekDays[i] : '';
      return {
        'key': key,
        'short': shortLabels[i],
        'long': longLabels[i],
      };
    });

    return SingleChildScrollView(
      controller: _dayScrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: weekDays.asMap().entries.map((entry) {
            final int idx = entry.key;
            final day = entry.value;
            bool isSelected = _selectedDayKey == day['key'];
            // Debug: show which day is being built and whether it's selected
            // ignore: avoid_print
            debugPrint(
                'Building day selector item: ${day['key']} index:$idx isSelected:$isSelected');
            return Padding(
              key: _dayKeys[idx],
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _selectedDayKey = day['key']!;
                    });
                    context
                        .read<TeacherMyTimetableCubit>()
                        .getTeacherMyTimetable(
                            isRefresh: true, dayKey: day['key']!);
                  },
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      // Selected pill appears white with maroon text for high contrast
                      color: isSelected ? Colors.white : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? _maroonPrimary.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.22),
                        width: isSelected ? 1 : 0.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _maroonPrimary.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      day['short']!,
                      style: GoogleFonts.poppins(
                        // Maroon text when selected, otherwise white
                        color: isSelected ? _maroonPrimary : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            )
                .animate(
                  autoPlay: true,
                  target: isSelected ? 1 : 0,
                )
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.05, 1.05),
                  curve: Curves.easeOutCubic,
                  duration: const Duration(milliseconds: 300),
                );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TeacherMyTimetableCubit>().state;
    debugPrint("Current state: $state");
    if (state is TeacherMyTimetableFetchSuccess) {
      debugPrint("Total slots in state: ${state.timeTableSlots.length}");
      debugPrint("Selected day: $_selectedDayKey");
      debugPrint("Days in data: ${state.timeTableSlots.map((s) => s.day).toSet()}");
      // Ensure we focus the selected day once after data has arrived
      if (!_focusedOnce) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusSelectedDay();
        });
        _focusedOnce = true;
      }
    }

    return Scaffold(
      appBar: CustomModernAppBar(
        title: Utils.getTranslatedLabel(myTimetableKey),
        icon: Icons.schedule_rounded,
        fabAnimationController: _fabAnimationController,
        primaryColor: _maroonPrimary,
        onBackPressed: () => Navigator.of(context).pop(),
        height: 140, // Increased height for tab content
        filterActive: true,
        tabBuilder: _buildDaySelector,
      ),
      body: BlocBuilder<TeacherMyTimetableCubit, TeacherMyTimetableState>(
        builder: (context, state) {
          if (state is TeacherMyTimetableFetchSuccess) {
            // Display all returned slots without filtering by day
            // Since the API already returns the correct slots for the selected day
            final slots = state.timeTableSlots;

            debugPrint("Total slots: ${slots.length}");
            for (var slot in slots) {
              debugPrint(
                  "Slot - Day: ${slot.day}, ID: ${slot.id}, ClassSectionId: ${slot.classSectionId}");
            }

            if (slots.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: CustomTextContainer(
                    textKey: Utils.getTranslatedLabel(noTimeTableKey),
                  ),
                ),
              );
            }

            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 25, top: 25),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.all(appContentHorizontalPadding),
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    children: slots
                        .map((timeTableSlot) => TimetableSlotContainer(
                              note: timeTableSlot.note ?? "",
                              endTime: timeTableSlot.endTime ?? "",
                              isForClass: false,
                              classSectionName: getClassSectionName(
                                  timeTableSlot.classSectionId),
                              startTime: timeTableSlot.startTime ?? "",
                              subjectName: timeTableSlot.subject
                                      ?.getSybjectNameWithType() ??
                                  "-",
                            ))
                        .toList(),
                  ),
                ),
              ),
            );
          }
          if (state is TeacherMyTimetableFetchFailure) {
            return Center(
              child: CustomErrorWidget(
                message: state.errorMessage,
                onRetry: () {
                  context
                      .read<TeacherMyTimetableCubit>()
                      .getTeacherMyTimetable();
                },
                primaryColor: _maroonPrimary,
              ),
            );
          }

          return Center(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 25, top: 25),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.all(appContentHorizontalPadding),
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    children:
                        List.generate(6, (index) => const SkeletonTimetableSlot()),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String getClassSectionName(int? classSectionId) {
    if (classSectionId == null) {
      debugPrint("ClassSectionId is null");
      return "-";
    }

    final classState = context.read<ClassesCubit>().state;
    debugPrint("ClassState: $classState");

    if (classState is ClassesFetchSuccess) {
      try {
        debugPrint("Checking class section ID: $classSectionId");
        debugPrint(
            "Primary classes: ${classState.primaryClasses.map((e) => '${e.name} (${e.id})')}");
        debugPrint(
            "Other classes: ${classState.classes.map((e) => '${e.name} (${e.id})')}");

        // Check in primary classes first
        final primaryClass = classState.primaryClasses.firstWhere(
          (element) => element.id == classSectionId,
          orElse: () => ClassSection(id: 0, name: "", classId: 0),
        );

        if (primaryClass.id != 0) {
          debugPrint("Found in primary classes: ${primaryClass.name}");
          return primaryClass.name ?? "";
        }

        // Then check in other classes
        final classSection = classState.classes.firstWhere(
          (element) => element.id == classSectionId,
          orElse: () => ClassSection(id: 0, name: "-", classId: 0),
        );

        debugPrint(
            "Found class section: ${classSection.name} for ID: $classSectionId");
        return classSection.name ?? "";
      } catch (e) {
        debugPrint("Error finding class section: $e");
        return "-";
      }
    }
    return "-";
  }
}
