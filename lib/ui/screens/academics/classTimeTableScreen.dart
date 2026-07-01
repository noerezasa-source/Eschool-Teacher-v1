import 'package:eschool_saas_staff/cubits/academics/classTimetableCubit.dart';
import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/cubits/settings/appThemeCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/academics/timetableSlotContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart' as constants;
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class ClassTimeTableScreen extends StatefulWidget {
  const ClassTimeTableScreen({super.key});

  static Widget getRouteInstance() {
    //final arguments = Get.arguments as Map<String, dynamic>;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ClassesCubit(),
        ),
        BlocProvider(
          create: (context) => ClassTimetableCubit(),
        ),
      ],
      child: const ClassTimeTableScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<ClassTimeTableScreen> createState() => _ClassTimeTableScreenState();
}

class _ClassTimeTableScreenState extends State<ClassTimeTableScreen>
    with TickerProviderStateMixin {
  ClassSection? _selectedClassSection;
  late String _selectedDayKey = Utils.weekDays.first;

  // Animation controller for app bar effects
  late AnimationController _fabAnimationController;
  final ScrollController _scrollController = ScrollController();

  // Theme colors
  String get _themeMode => context.watch<AppThemeCubit>().state.themeMode;
  Color get _maroonPrimary => AppColorPalette.getPrimaryColor(_themeMode);
  Color get _maroonLight => AppColorPalette.getSecondaryColor(_themeMode);
  bool get _isDark => _themeMode == 'dark';
  Color get _scaffoldBg => _isDark ? const Color(0xFF121212) : Colors.white;
  Color get _cardBg => _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scrollController.addListener(_scrollListener);

    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<ClassesCubit>().getClasses();
      }
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
    _fabAnimationController.dispose();
    super.dispose();
  }

  void changeSelectedClassSection(ClassSection classSection) {
    _selectedClassSection = classSection;
    setState(() {});
    getClassTimetable();
  }

  void getClassTimetable() {
    context
        .read<ClassTimetableCubit>()
        .getClassTimetable(classSectionId: _selectedClassSection?.id ?? 0);
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomModernAppBar(
      title: Utils.getTranslatedLabel(classTimetableKey),
      icon: Icons.schedule_outlined,
      fabAnimationController: _fabAnimationController,
      primaryColor: _maroonPrimary,
      lightColor: _maroonLight,
      onBackPressed: () => Navigator.of(context).pop(),
      height: 200,
      tabBuilder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Class filter with elegant design
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                splashColor: Colors.white.withValues(alpha: 0.1),
                highlightColor: Colors.white.withValues(alpha: 0.05),
                onTap: () {
                  final state = context.read<ClassesCubit>().state;
                  if (state is ClassesFetchSuccess &&
                      context.read<ClassesCubit>().getAllClasses().isNotEmpty) {
                    Utils.showBottomSheet(
                      child: FilterSelectionBottomsheet<ClassSection>(
                        onSelection: (value) {
                          changeSelectedClassSection(value!);
                          Get.back();
                        },
                        selectedValue: _selectedClassSection!,
                        titleKey: classKey,
                        values: context.read<ClassesCubit>().getAllClasses(),
                      ),
                      context: context,
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.class_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedClassSection == null
                              ? Utils.getTranslatedLabel(classKey)
                              : (_selectedClassSection?.fullName ?? ""),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Horizontal day selector
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: _buildHorizontalDaySelector(),
          ),
        ],
      ),
    );
  }

  // New horizontal day selector
  Widget _buildHorizontalDaySelector() {
    List<Map<String, String>> weekDays = [
      {'key': 'monday', 'short': 'SEN', 'long': 'Senin'},
      {'key': 'tuesday', 'short': 'SEL', 'long': 'Selasa'},
      {'key': 'wednesday', 'short': 'RAB', 'long': 'Rabu'},
      {'key': 'thursday', 'short': 'KAM', 'long': 'Kamis'},
      {'key': 'friday', 'short': 'JUM', 'long': 'Jumat'},
      {'key': 'saturday', 'short': 'SAB', 'long': 'Sabtu'},
      {'key': 'sunday', 'short': 'MIN', 'long': 'Minggu'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: weekDays.map((day) {
            bool isSelected = _selectedDayKey == day['key'];
            return Padding(
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
                  },
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected ? Colors.white : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.3),
                        width: isSelected ? 1 : 0.5,
                      ),
                    ),
                    child: Text(
                      day['short']!,
                      style: GoogleFonts.poppins(
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
                  autoPlay: false,
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

  Widget _buildClassTimetable() {
    return BlocBuilder<ClassTimetableCubit, ClassTimetableState>(
      builder: (context, state) {
        if (state is ClassTimetableFetchSuccess) {
          // Convert full day names to abbreviated keys for mapping
          Map<String, String> dayKeyMapping = {
            'monday': 'mon',
            'tuesday': 'tue',
            'wednesday': 'wed',
            'thursday': 'thu',
            'friday': 'fri',
            'saturday': 'sat',
            'sunday': 'sun',
          };

          // Get the abbreviated key for the selected day
          String abbrevKey = dayKeyMapping[_selectedDayKey] ?? _selectedDayKey;

          // Find the index of the abbreviated key in Utils.weekDays
          int dayIndex = Utils.weekDays.indexOf(abbrevKey);

          // Only filter by day if we found a valid index
          final slots = dayIndex >= 0
              ? state.classTimetableSlots
                  .where(
                      (element) => element.day == constants.weekDays[dayIndex])
                  .toList()
              : state.classTimetableSlots;

          if (slots.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Text(
                  'Tidak ada jadwal untuk hari ini',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          }
          final bool isToday = dayIndex == (DateTime.now().weekday - 1);

          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: _maroonPrimary,
                    secondary: _maroonLight,
                    surface: _cardBg,
                  ),
            ),
            child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(
                      top: 20), // Reduced padding since AppBar is now separate
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    padding:
                        EdgeInsets.all(constants.appContentHorizontalPadding),
                    color: _scaffoldBg,
                    child: Column(
                      children: slots
                          .map((timeTableSlot) => TimetableSlotContainer(
                                note: timeTableSlot.note ?? "",
                                endTime: timeTableSlot.endTime ?? "",
                                isForClass: true,
                                teacherName: timeTableSlot
                                        .subjectTeacher?.teacher?.fullName ??
                                    "-",
                                startTime: timeTableSlot.startTime ?? "",
                                subjectName: timeTableSlot.subject
                                        ?.getSybjectNameWithType() ??
                                    "-",
                                isActive: isToday &&
                                    Utils.isCurrentTimeWithinSlot(
                                        timeTableSlot.startTime ?? "",
                                        timeTableSlot.endTime ?? ""),
                              ))
                          .toList(),
                    ),
                  ),
                )),
          );
        }
        if (state is ClassTimetableFetchFailure) {
          return Center(
            child: CustomErrorWidget(
              message: state.errorMessage,
              onRetry: () {
                getClassTimetable();
              },
              primaryColor: _maroonPrimary,
            ),
          );
        }
        return _buildTimetableSkeleton();
      },
    );
  }

  Widget _buildTimetableSkeleton() {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _maroonPrimary,
              secondary: _maroonLight,
              surface: _cardBg,
            ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.only(top: 20),
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.all(constants.appContentHorizontalPadding),
            color: _scaffoldBg,
            child: Shimmer.fromColors(
              baseColor: _isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              highlightColor: _isDark ? Colors.grey.shade700 : Colors.grey.shade100,
              child: Column(
              children: List.generate(6, (index) {
                return Container(
                  margin: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                  height: Utils().getResponsiveHeight(context, 150),
                  child: LayoutBuilder(builder: (context, boxConstraints) {
                    return Row(
                      children: [
                        // Time column skeleton
                        SizedBox(
                          width: boxConstraints.maxWidth * (0.2),
                          child: Column(
                            children: [
                              // Start time
                              Container(
                                height: 18,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Timezone label
                              Container(
                                height: 12,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const Spacer(),
                              // Timeline
                              Container(
                                height:
                                    Utils().getResponsiveHeight(context, 65),
                                width: 2,
                                color: Colors.white,
                              ),
                              const Spacer(),
                              // End time
                              Container(
                                height: 18,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              // Timezone label
                              Container(
                                height: 12,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: boxConstraints.maxWidth * (0.05)),
                        // Content column skeleton
                        SizedBox(
                          width: boxConstraints.maxWidth * (0.7),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: constants.appContentHorizontalPadding,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Subject label
                                Container(
                                  height: 12,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Subject name
                                Container(
                                  height: 16,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const Spacer(),
                                // Teacher label
                                Container(
                                  height: 12,
                                  width: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Teacher name
                                Container(
                                  height: 16,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                );
              }),
            ),
          ),
        ),
      ),
    )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: _buildAppBar(),
      body: BlocConsumer<ClassesCubit, ClassesState>(
        listener: (context, state) {
          if (state is ClassesFetchSuccess &&
              context.read<ClassesCubit>().getAllClasses().isNotEmpty) {
            changeSelectedClassSection(
                context.read<ClassesCubit>().getAllClasses().first);
          }
        },
        builder: (context, state) {
          if (state is ClassesFetchSuccess) {
            if (context.read<ClassesCubit>().getAllClasses().isEmpty) {
              return const SizedBox();
            }
            return _buildClassTimetable();
          }
          if (state is ClassesFetchFailure) {
            return Center(
              child: CustomErrorWidget(
                message: state.errorMessage,
                onRetry: () {
                  context.read<ClassesCubit>().getClasses();
                },
                primaryColor: _maroonPrimary,
              ),
            );
          }

            return _buildTimetableSkeleton();
        },
      ),
    );
  }
}
