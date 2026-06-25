import 'dart:async';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/academics/classesAndSessionYearsCubit.dart';
import 'package:eschool_saas_staff/cubits/student/studentsCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/academic/sessionYear.dart';
import 'package:eschool_saas_staff/ui/screens/student/studentProfileScreen.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextButton.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customFilterModernAppbar.dart';
import 'package:eschool_saas_staff/ui/widgets/student/studentListCard.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  static Widget getRouteInstance() => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ClassesAndSessionYearsCubit(),
          ),
          BlocProvider(
            create: (context) => StudentsCubit(),
          ),
        ],
        child: const StudentsScreen(),
      );

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

// State implementation for StudentsScreen
class _StudentsScreenState extends State<StudentsScreen>
    with TickerProviderStateMixin {
  ClassSection? _selectedClassSection;
  SessionYear? _selectedSessionYear;
  String? _selectedStatus; // null = semua, '1' = aktif, '0' = non-aktif

  late final ScrollController _scrollController = ScrollController();

  late final TextEditingController _textEditingController =
      TextEditingController()..addListener(searchQueryTextControllerListener);

  late int waitForNextRequestSearchQueryTimeInMilliSeconds =
      nextSearchRequestQueryTimeInMilliSeconds;

  Timer? waitForNextSearchRequestTimer;

  // Animation controllers
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  // Define theme colors
  static Color get maroonPrimary => AppColorPalette.primaryMaroon;
  static Color get maroonLight => AppColorPalette.secondaryMaroon;
  static Color get bgColor => AppColorPalette.accentPink;
  final Color cardColor = Colors.white;
  static const Color textDarkColor = Color(0xFF2D2D2D);
  static const Color textMediumColor = Color(0xFF717171);
  static const Color borderColor = Color(0xFFE8E8E8);

  @override
  void initState() {
    super.initState();

    // Update header height to accommodate filters better
    // _headerHeight = 240.0; // Increased from 200 to 240

    // Primary animation controller for fade effects
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    // Start animations
    _animationController.forward();

    // Add scroll listener for pagination only
    _scrollController.addListener(scrollListener);

    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<ClassesAndSessionYearsCubit>().getClassesAndSessionYears();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textEditingController.dispose();
    _animationController.dispose();
    waitForNextSearchRequestTimer?.cancel();
    super.dispose();
  }

  void searchQueryTextControllerListener() {
    if (_textEditingController.text.trim().isEmpty) {
      return;
    }
    waitForNextSearchRequestTimer?.cancel();
    setWaitForNextSearchRequestTimer();
  }

  void setWaitForNextSearchRequestTimer() {
    if (waitForNextRequestSearchQueryTimeInMilliSeconds !=
        (waitForNextRequestSearchQueryTimeInMilliSeconds -
            searchRequestPerodicMilliSeconds)) {
      //
      waitForNextRequestSearchQueryTimeInMilliSeconds =
          (nextSearchRequestQueryTimeInMilliSeconds -
              searchRequestPerodicMilliSeconds);
    }
    //
    waitForNextSearchRequestTimer = Timer.periodic(
        Duration(milliseconds: searchRequestPerodicMilliSeconds), (timer) {
      if (waitForNextRequestSearchQueryTimeInMilliSeconds == 0) {
        timer.cancel();
        getStudents();
      } else {
        waitForNextRequestSearchQueryTimeInMilliSeconds =
            waitForNextRequestSearchQueryTimeInMilliSeconds -
                searchRequestPerodicMilliSeconds;
      }
    });
  }

  void scrollListener() {
    // Only check for pagination, no header height changes
    if (_scrollController.position.maxScrollExtent ==
        _scrollController.offset) {
      if (context.read<StudentsCubit>().hasMore()) {
        getMoreStudents();
      }
    }
  }

  void changeSelectedClassSection(ClassSection classSection) {
    _selectedClassSection = classSection;
    setState(() {});
  }

  void changeSelectedSessionYear(SessionYear sessionYear) {
    _selectedSessionYear = sessionYear;
    setState(() {});
  }

  void changeSelectedStatus(String? status) {
    _selectedStatus = status;
    setState(() {});
    getStudents();
  }

  void getStudents() {
    if (_selectedClassSection == null || _selectedSessionYear == null) return;
    if (_selectedClassSection!.id == null || _selectedSessionYear!.id == null) {
      return;
    }

    debugPrint('Fetching students with status: ${_selectedStatus ?? "all"}');
    context.read<StudentsCubit>().getStudents(
        search: _textEditingController.text.trim().isEmpty
            ? null
            : _textEditingController.text.trim(),
        classSectionId: _selectedClassSection!.id!,
        sessionYearId: _selectedSessionYear!.id!,
        status: _selectedStatus);
  }

  void getMoreStudents() {
    if (_selectedClassSection == null || _selectedSessionYear == null) return;
    if (_selectedClassSection!.id == null || _selectedSessionYear!.id == null) {
      return;
    }

    context.read<StudentsCubit>().fetchMore(
        search: _textEditingController.text.trim().isEmpty
            ? null
            : _textEditingController.text.trim(),
        classSectionId: _selectedClassSection!.id!,
        sessionYearId: _selectedSessionYear!.id!,
        status: _selectedStatus);
  }

  PreferredSizeWidget _buildHeaderSection() {
    return CustomFilterModernAppBar(
      title: studentsKey.tr,
      titleIcon: Icons.school_rounded,
      primaryColor: maroonPrimary,
      secondaryColor: maroonLight,
      onBackPressed: () {
        Navigator.pop(context);
      },
      animationController: _animationController,
      enableAnimations: true,
      height: 250.0, // Further increased height for more breathing room
      // contentPadding:
      //     EdgeInsets.fromLTRB(24, 20, 24, 24), // Increased outer padding
      firstFilterItem: FilterItemConfig(
        title: _selectedClassSection?.name ?? classKey.tr,
        icon: Icons.class_rounded,
        onTap: () {
          if (context.read<ClassesAndSessionYearsCubit>().state
              is ClassesAndSessionYearsFetchSuccess) {
            final classes =
                context.read<ClassesAndSessionYearsCubit>().getClasses();
            if (classes.isNotEmpty) {
              _showClassSectionFilter(context, classes);
            }
          }
        },
      ),
      secondFilterItem: FilterItemConfig(
        title: _selectedSessionYear?.name ?? sessionYearKey.tr,
        icon: Icons.calendar_today_rounded,
        onTap: () {
          if (context.read<ClassesAndSessionYearsCubit>().state
              is ClassesAndSessionYearsFetchSuccess) {
            final state = context.read<ClassesAndSessionYearsCubit>().state
                as ClassesAndSessionYearsFetchSuccess;
            if (state.sessionYears.isNotEmpty) {
              _showSessionYearFilter(context, state.sessionYears);
            }
          }
        },
      ),
      thirdFilterItem: FilterItemConfig(
        title: _selectedStatus == '0'
            ? "Siswa Aktif"
            : _selectedStatus == '1'
                ? "Siswa Non-Aktif"
                : "Semua Status",
        icon: Icons.filter_list_rounded,
        onTap: () {
          _showStatusFilter(context);
        },
      ),
    );
  }

  void _showClassSectionFilter(
      BuildContext context, List<ClassSection> classSections) {
    // Prevent overflow errors with proper sheet sizing
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6, // Start at 60% of screen height
        minChildSize: 0.3, // Can be dragged to minimum 30%
        maxChildSize: 0.9, // Maximum 90% of screen height
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  "Pilih Kelas",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textDarkColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: classSections.length,
                  itemBuilder: (context, index) {
                    final classSection = classSections[index];
                    final isSelected =
                        _selectedClassSection?.id == classSection.id;

                    return InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        changeSelectedClassSection(classSection);
                        getStudents();
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? maroonPrimary.withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? maroonPrimary : borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.class_rounded,
                              color:
                                  isSelected ? maroonPrimary : textMediumColor,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                classSection.name ?? "",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? maroonPrimary
                                      : textDarkColor,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: maroonPrimary,
                                size: 24,
                              ),
                          ],
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
    );
  }

  void _showSessionYearFilter(
      BuildContext context, List<SessionYear> sessionYears) {
    // Prevent overflow errors with proper sheet sizing
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6, // Start at 60% of screen height
        minChildSize: 0.3, // Can be dragged to minimum 30%
        maxChildSize: 0.9, // Maximum 90% of screen height
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  "Pilih Tahun Ajaran",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textDarkColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: sessionYears.length,
                  itemBuilder: (context, index) {
                    final sessionYear = sessionYears[index];
                    final isSelected =
                        _selectedSessionYear?.id == sessionYear.id;
                    final isDefault = sessionYear.isThisDefault();

                    return InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        changeSelectedSessionYear(sessionYear);
                        getStudents();
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? maroonPrimary.withValues(alpha: 0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? maroonPrimary : borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color:
                                  isSelected ? maroonPrimary : textMediumColor,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sessionYear.name ?? "",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? maroonPrimary
                                          : textDarkColor,
                                    ),
                                  ),
                                  if (isDefault)
                                    Text(
                                      "Tahun Ajaran Saat Ini",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: maroonLight,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                color: maroonPrimary,
                                size: 24,
                              ),
                          ],
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
    );
  }

  void _showStatusFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                "Filter Status Siswa",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textDarkColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusFilterOption(
              context: context,
              title: "Semua Siswa",
              subtitle: "Tampilkan semua status siswa",
              icon: Icons.people_alt_rounded,
              isSelected: _selectedStatus == null,
              onTap: () {
                HapticFeedback.lightImpact();
                changeSelectedStatus(null);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            _buildStatusFilterOption(
              context: context,
              title: "Siswa Aktif",
              subtitle: "Hanya tampilkan siswa dengan status aktif",
              icon: Icons.check_circle_outline_rounded,
              isSelected: _selectedStatus == '0',
              onTap: () {
                HapticFeedback.lightImpact();
                changeSelectedStatus('0');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            _buildStatusFilterOption(
              context: context,
              title: "Siswa Non-Aktif",
              subtitle: "Hanya tampilkan siswa dengan status non-aktif",
              icon: Icons.cancel_outlined,
              isSelected: _selectedStatus == '1',
              onTap: () {
                HapticFeedback.lightImpact();
                changeSelectedStatus('1');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color:
              isSelected ? maroonPrimary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? maroonPrimary : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? maroonPrimary : textMediumColor,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? maroonPrimary : textDarkColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: textMediumColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: maroonPrimary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudents() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 10), // Fixed top padding
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Only show search container when both filters are selected
          if (_selectedClassSection != null && _selectedSessionYear != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: TextField(
                          controller: _textEditingController,
                          decoration: InputDecoration(
                            hintText: "Cari siswa...",
                            hintStyle: const TextStyle(
                              color: textMediumColor,
                              fontFamily: 'Poppins',
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: maroonPrimary,
                            ),
                            suffixIcon: _textEditingController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: textMediumColor,
                                    ),
                                    onPressed: () {
                                      _textEditingController.clear();
                                      getStudents();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: textDarkColor,
                          ),
                          onChanged: (value) {
                            // Debounced search will be handled by the listener
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          // Only add space if search is shown
          if (_selectedClassSection != null && _selectedSessionYear != null)
            const SizedBox(height: 15),
          BlocConsumer<ClassesAndSessionYearsCubit,
              ClassesAndSessionYearsState>(
            listener: (context, state) {
              if (state is ClassesAndSessionYearsFetchSuccess) {
                if (context
                        .read<ClassesAndSessionYearsCubit>()
                        .getClasses()
                        .isNotEmpty &&
                    state.sessionYears.isNotEmpty) {
                  // Only set initial values if not already set
                  if (_selectedClassSection == null) {
                    changeSelectedClassSection(context
                        .read<ClassesAndSessionYearsCubit>()
                        .getClasses()
                        .first);
                  }
                  if (_selectedSessionYear == null) {
                    changeSelectedSessionYear(state.sessionYears
                        .where((element) => element.isThisDefault())
                        .first);
                  }
                  if (context.read<StudentsCubit>().state is StudentsInitial) {
                    getStudents();
                  }
                }
              }
            },
            builder: (context, state) {
              return BlocBuilder<StudentsCubit, StudentsState>(
                  builder: (context, state) {
                if (state is StudentsFetchInProgress) {
                  return _buildStudentsSkeleton();
                }
                if (state is StudentsFetchSuccess) {
                  return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          if (state.students.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 100),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.school_outlined,
                                      size: 80,
                                      color:
                                          maroonPrimary.withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      "Tidak ada data siswa",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: textMediumColor,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      "Silakan pilih kelas dan tahun ajaran lain",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: textMediumColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (state.students.isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.people_alt_rounded,
                                    color: maroonPrimary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Daftar Siswa",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: textDarkColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          maroonPrimary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: maroonPrimary.withValues(
                                            alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      "${state.students.length} Siswa",
                                      style: TextStyle(
                                        color: maroonPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: state.students.length +
                                  (context.read<StudentsCubit>().hasMore()
                                      ? 1
                                      : 0),
                              itemBuilder: (context, index) {
                                if (index == state.students.length) {
                                  // This is the loading more indicator
                                  if (state.fetchMoreError) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 20),
                                        child: CustomTextButton(
                                          buttonTextKey: retryKey,
                                          onTapButton: () {
                                            getMoreStudents();
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                  return Center(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 20),
                                      child: CustomCircularProgressIndicator(
                                        indicatorColor: maroonPrimary,
                                      ),
                                    ),
                                  );
                                }

                                final studentDetails = state.students[index];
                                return AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    // Stagger the animations
                                    final delay = (index * 0.1).clamp(0.0, 1.0);
                                    final delayedAnimation =
                                        Tween<double>(begin: 0.0, end: 1.0)
                                            .animate(
                                      CurvedAnimation(
                                        parent: _animationController,
                                        curve: Interval(delay, 1.0,
                                            curve: Curves.easeOut),
                                      ),
                                    );

                                    return Transform.translate(
                                      offset: Offset(0,
                                          20 * (1.0 - delayedAnimation.value)),
                                      child: Opacity(
                                        opacity: delayedAnimation.value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: StudentListCard(
                                      studentDetails: studentDetails,
                                      classSection: _selectedClassSection,
                                      sessionYear: _selectedSessionYear,
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        Get.toNamed(
                                          Routes.studentProfileScreen,
                                          arguments: StudentProfileScreen
                                              .buildArguments(
                                            classSection:
                                                _selectedClassSection ??
                                                    ClassSection.fromJson({}),
                                            sessionYear: _selectedSessionYear ??
                                                SessionYear.fromJson({}),
                                            studentDetails: studentDetails,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            )
                          ],
                        ],
                      ));
                }
                if (state is StudentsFetchFailure) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: topPaddingOfErrorAndLoadingContainer),
                      child: CustomErrorWidget(
                        message: state.errorMessage,
                        onRetry: () {
                          getStudents();
                        },
                        primaryColor: AppColorPalette.primaryMaroon,
                      ),
                    ),
                  );
                }

                // Condition when one of the filters is selected but not both
                if (_selectedClassSection != null &&
                    _selectedSessionYear == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 60,
                          color: maroonPrimary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Kelas telah dipilih",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: textMediumColor,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Silakan pilih tahun ajaran untuk melanjutkan",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: textMediumColor.withValues(alpha: 0.8),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (_selectedClassSection == null &&
                    _selectedSessionYear != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.class_rounded,
                          size: 60,
                          color: maroonPrimary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Tahun ajaran telah dipilih",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: textMediumColor,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Silakan pilih kelas untuk melanjutkan",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: textMediumColor.withValues(alpha: 0.8),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Default state when no filters are selected yet
                if (_selectedClassSection == null &&
                    _selectedSessionYear == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          size: 60,
                          color: maroonPrimary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Pilih Filter Terlebih Dahulu",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: textDarkColor,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Silakan pilih kelas dan tahun ajaran\ndari menu filter di atas untuk melihat data siswa",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: textMediumColor,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Default loading state when waiting for initial data or during fetch
                return _buildStudentsSkeleton();
              });
            },
          ),
          // Add some bottom padding
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStudentsSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(6, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Stack(
                children: [
                  // Status indicator strip skeleton
                  Positioned(
                    top: 0,
                    left: 0,
                    bottom: 0,
                    child: Container(
                      width: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  // Main content
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      children: [
                        // Header section with profile image and name
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: borderColor,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Profile image skeleton
                              Container(
                                width: 65,
                                height: 65,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Status and gender badges row
                                    Row(
                                      children: [
                                        // Status badge skeleton
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Container(
                                            width: 50,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Gender badge skeleton
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Container(
                                            width: 35,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // Student name skeleton
                                    Container(
                                      height: 17,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    // GR Number row skeleton
                                    Row(
                                      children: [
                                        Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          height: 13,
                                          width: 100,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Information section skeleton
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Roll number column skeleton
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: 32,
                                      width: 32,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 14,
                                      width: 30,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      height: 11,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.white,
                              ),
                              // Class column skeleton
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: 32,
                                      width: 32,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 14,
                                      width: 25,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      height: 11,
                                      width: 35,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.white,
                              ),
                              // Session year column skeleton
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: 32,
                                      width: 32,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 14,
                                      width: 35,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      height: 11,
                                      width: 30,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action row skeleton
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                height: 12,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
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
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          // Ensure status bar has correct styling with fixed AppBar
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: bgColor,
        // Set extendBodyBehindAppBar to false to ensure AppBar stays fixed
        extendBodyBehindAppBar: false,
        appBar: _buildHeaderSection(),
        body: BlocBuilder<ClassesAndSessionYearsCubit,
            ClassesAndSessionYearsState>(
          builder: (context, state) {
            if (state is ClassesAndSessionYearsFetchSuccess) {
              return _buildStudents();
            }

            if (state is ClassesAndSessionYearsFetchFailure) {
              return Center(
                  child: CustomErrorWidget(
                message: state.errorMessage,
                onRetry: () {
                  context
                      .read<ClassesAndSessionYearsCubit>()
                      .getClassesAndSessionYears();
                },
                primaryColor: AppColorPalette.primaryMaroon,
              ));
            }

            return _buildStudentsSkeleton();
          },
        ),
      ),
    );
  }
}
