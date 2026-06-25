import 'dart:async';
import 'dart:math' as math;
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';

import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/teacher/teachersCubit.dart';
import 'package:eschool_saas_staff/ui/screens/leaves/leavesScreen.dart';
import 'package:eschool_saas_staff/ui/screens/staff/teacherProfileScreen.dart';
import 'package:eschool_saas_staff/ui/screens/academics/teacherTimeTableDetailsScreen.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/profileImageContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/no_search_results_widget.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/route_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

enum TeacherNavigationType { leave, profile, timetable }

// Menambahkan enum untuk filter status guru
enum TeacherStatusFilter { all, active, inactive }

class TeachersScreen extends StatefulWidget {
  final TeacherNavigationType teacherNavigationType;
  const TeachersScreen({super.key, required this.teacherNavigationType});

  static Widget getRouteInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return BlocProvider(
      create: (context) => TeachersCubit(),
      child: TeachersScreen(
        teacherNavigationType: arguments['teacherNavigationType'],
      ),
    );
  }

  static Map<String, dynamic> buildArguments(
      {required TeacherNavigationType teacherNavigationType}) {
    return {"teacherNavigationType": teacherNavigationType};
  }

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen>
    with TickerProviderStateMixin {
  late final TextEditingController _textEditingController =
      TextEditingController()..addListener(searchQueryTextControllerListener);

  // Variable untuk status filter guru
  TeacherStatusFilter _currentStatusFilter = TeacherStatusFilter.all;

  late int waitForNextRequestSearchQueryTimeInMilliSeconds =
      nextSearchRequestQueryTimeInMilliSeconds;

  Timer? waitForNextSearchRequestTimer;

  // Warna tema maroon yang digunakan dalam aplikasi
  Color get maroonPrimary => AppColorPalette.primaryMaroon;
  final Color maroonSecondary = const Color(0xFFA84B5C);
  final Color maroonLight = const Color(0xFFE7C8CD);
  final Color accentPink = const Color(0xFFF4D0D9);
  final Color warmBeige = const Color(0xFFF5E6E8);

  // Map untuk terjemahan role ke bahasa Indonesia
  final Map<String, String> _roleTranslations = {
    'Teacher': 'Guru',
    'Staff': 'Staf',
    'School Admin': 'Admin Sekolah',
    'Super Admin': 'Super Admin',
    'Principal': 'Kepala Sekolah',
    'Vice Principal': 'Wakil Kepala Sekolah',
    'Academic Coordinator': 'Koordinator Akademik',
    'Student Affairs': 'Bagian Kesiswaan',
    'Librarian': 'Pustakawan',
    'Counselor': 'Konselor',
    'IT Support': 'Dukungan IT',
    'Finance': 'Keuangan',
    'HR': 'SDM',
    'Class Teacher': 'Wali Kelas',
    'Subject Teacher': 'Guru Mata Pelajaran',
    'Homeroom Teacher': 'Guru Wali Kelas',
  };

  // Controllers untuk animasi
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController
      _fabAnimationController; // Added for CustomModernAppBar

  // Untuk efek hover pada item staff
  int _hoveredTeacherIndex = -1;

  // Untuk efek scroll header
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();

    // Inisialisasi animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Pulse animation untuk efek interaktif
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Rotation animation untuk elemen dekoratif
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    )..repeat();

    // Initialize fabAnimationController for CustomModernAppBar
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    // Listener untuk efek scroll header
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled) {
        setState(() {
          _isScrolled = true;
        });
      } else if (_scrollController.offset <= 50 && _isScrolled) {
        setState(() {
          _isScrolled = false;
        });
      }
    });

    Future.delayed(Duration.zero, () {
      getTeachers();
    });
  }

  @override
  void dispose() {
    waitForNextSearchRequestTimer?.cancel();
    _textEditingController.removeListener(searchQueryTextControllerListener);
    _textEditingController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _fabAnimationController
        .dispose(); // Add this line to dispose the new controller
    _scrollController.dispose();
    super.dispose();
  }

  void getTeachers() {
    context.read<TeachersCubit>().getTeachers(
        search: _textEditingController.text.trim().isEmpty
            ? null
            : _textEditingController.text.trim());
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
        getTeachers();
      } else {
        waitForNextRequestSearchQueryTimeInMilliSeconds =
            waitForNextRequestSearchQueryTimeInMilliSeconds -
                searchRequestPerodicMilliSeconds;
      }
    });
  }

  void changeTab(String value) {
    // Tab functionality removed - keeping for future use if needed
    getTeachers();
  }

  String getNavigationTitleKey() {
    if (widget.teacherNavigationType == TeacherNavigationType.leave) {
      return viewLeavesKey;
    }
    if (widget.teacherNavigationType == TeacherNavigationType.timetable) {
      return timetableKey;
    }
    return viewProfileKey;
  }

  // Fungsi untuk menerjemahkan role ke bahasa Indonesia
  String _translateRole(String role) {
    return _roleTranslations[role] ?? role;
  }

  Widget _buildTeacherList(TeachersFetchSuccess state, BuildContext context) {
    // Menerapkan filter berdasarkan status guru
    var filteredTeachers = state.teachers;

    if (_currentStatusFilter == TeacherStatusFilter.active) {
      filteredTeachers =
          state.teachers.where((teacher) => teacher.isActive()).toList();
    } else if (_currentStatusFilter == TeacherStatusFilter.inactive) {
      filteredTeachers =
          state.teachers.where((teacher) => !teacher.isActive()).toList();
    }

    if (filteredTeachers.isEmpty) {
      // Check if this is due to search or no data at all
      if (_textEditingController.text.trim().isNotEmpty) {
        return NoSearchResultsWidget(
          searchQuery: _textEditingController.text.trim(),
          onClearSearch: () {
            _textEditingController.clear();
            getTeachers();
          },
          primaryColor: maroonPrimary,
          accentColor: maroonSecondary,
          title: 'Guru Tidak Ditemukan',
          description:
              'Tidak ditemukan guru yang sesuai dengan pencarian Anda. Coba gunakan kata kunci yang berbeda.',
          icon: Icons.person_outline,
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ikon statis
              Icon(
                Icons.people_outline,
                size: 80,
                color: maroonPrimary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                "Tidak ada data guru ditemukan",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        );
      }
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        itemCount: filteredTeachers.length,
        itemBuilder: (context, index) {
          final teacherDetails = filteredTeachers[index];
          final bool isHovered = _hoveredTeacherIndex == index;

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 450),
            child: SlideAnimation(
              horizontalOffset: 40,
              child: FadeInAnimation(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (widget.teacherNavigationType ==
                        TeacherNavigationType.leave) {
                      Get.toNamed(Routes.leavesScreen,
                          arguments: LeavesScreen.buildArguments(
                              showMyLeaves: false,
                              userDetails: teacherDetails));
                    } else if (widget.teacherNavigationType ==
                        TeacherNavigationType.timetable) {
                      Get.toNamed(Routes.teacherTimeTableDetailsScreen,
                          arguments:
                              TeacherTimeTableDetailsScreen.buildArguments(
                                  teacherDetails: teacherDetails));
                    } else {
                      Get.toNamed(Routes.teacherProfileScreen,
                          arguments: TeacherProfileScreen.buildArguments(
                              userDetails: teacherDetails));
                    }
                  },
                  onTapDown: (_) {
                    setState(() {
                      _hoveredTeacherIndex = index;
                    });
                  },
                  onTapCancel: () {
                    setState(() {
                      _hoveredTeacherIndex = -1;
                    });
                  },
                  onTapUp: (_) {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        setState(() {
                          _hoveredTeacherIndex = -1;
                        });
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isHovered
                            ? [
                                maroonPrimary.withValues(alpha: 0.02),
                                maroonSecondary.withValues(alpha: 0.05),
                              ]
                            : [Colors.white, Colors.white],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isHovered
                            ? maroonPrimary.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isHovered
                              ? maroonPrimary.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.03),
                          blurRadius: isHovered ? 12 : 6,
                          offset: const Offset(0, 4),
                          spreadRadius: isHovered ? 1 : 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar dengan efek hover
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isHovered
                                  ? maroonPrimary.withValues(alpha: 0.4)
                                  : Colors.grey.shade200,
                              width: 2,
                            ),
                            boxShadow: isHovered
                                ? [
                                    BoxShadow(
                                      color: maroonPrimary.withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : [],
                          ),
                          child: ProfileImageContainer(
                            imageUrl: teacherDetails.image ?? "",
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Teacher info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      teacherDetails.firstName ?? "-",
                                      style: GoogleFonts.poppins(
                                        fontWeight: isHovered
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        fontSize: 16,
                                        color: isHovered
                                            ? maroonPrimary
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),

                                  // Status indicator
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: teacherDetails.isActive()
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      teacherDetails.isActive()
                                          ? "Aktif"
                                          : "Non-aktif",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: teacherDetails.isActive()
                                            ? Colors.green
                                            : Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4),

                              // Role tags
                              if (teacherDetails.getRoles().isNotEmpty) ...[
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: teacherDetails
                                      .getRoles()
                                      .split(',')
                                      .map((role) => role.trim())
                                      .where((role) => role.isNotEmpty)
                                      .map((role) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: maroonPrimary
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _translateRole(role),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: maroonPrimary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Icon animasi
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          transform: Matrix4.translationValues(
                              isHovered ? 8.0 : 0.0, 0.0, 0.0),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: isHovered
                                ? maroonPrimary
                                : maroonPrimary.withValues(alpha: 0.5),
                            size: 16,
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
    );
  }

  Widget _buildTeacherSkeletonList() {
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
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with teacher info and status
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 16,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 14,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Role tags section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Role tags
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Container(
                                width: 90,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              Container(
                                width: 65,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              if (index % 3 == 0)
                                Container(
                                  width: 75,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              if (index % 4 == 0)
                                Container(
                                  width: 25,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Arrow icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Need to add a fabAnimationController for the CustomModernAppBar
    late final AnimationController fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    String titleKey = "Daftar Guru";
    if (widget.teacherNavigationType == TeacherNavigationType.leave) {
      titleKey = "Guru - Cuti";
    } else if (widget.teacherNavigationType ==
        TeacherNavigationType.timetable) {
      titleKey = "Guru - Jadwal";
    } else {
      titleKey = "Daftar Guru";
    }

    return Scaffold(
      appBar: CustomModernAppBar(
        title: titleKey,
        icon: Icons.people_alt_rounded,
        fabAnimationController: fabAnimationController,
        primaryColor: maroonPrimary,
        lightColor: maroonSecondary,
        onBackPressed: () => Navigator.of(context).pop(),
        showFilterButton: true,
        onFilterPressed: () {
          // Optional: Implement filter functionality here
          HapticFeedback.lightImpact();
          // Show filter options
          showFilterOptions();
        },
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _textEditingController,
                decoration: InputDecoration(
                  hintText: "Cari guru...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: maroonPrimary),
                  suffixIcon: _textEditingController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _textEditingController.clear();
                            getTeachers();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Filter Indicator
          if (_currentStatusFilter != TeacherStatusFilter.all)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  Icon(
                    _currentStatusFilter == TeacherStatusFilter.active
                        ? Icons.check_circle_outline
                        : Icons.remove_circle_outline,
                    color: maroonPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentStatusFilter == TeacherStatusFilter.active
                        ? "Menampilkan Guru Aktif"
                        : "Menampilkan Guru Non-Aktif",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _currentStatusFilter = TeacherStatusFilter.all;
                      });
                    },
                    child: Text(
                      "Reset",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: maroonPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Filter Status Indicator
          if (_currentStatusFilter != TeacherStatusFilter.all)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: maroonPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: maroonPrimary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentStatusFilter == TeacherStatusFilter.active
                          ? Icons.check_circle_outline
                          : Icons.remove_circle_outline,
                      color: maroonPrimary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentStatusFilter == TeacherStatusFilter.active
                          ? "Filter: Guru Aktif"
                          : "Filter: Guru Non-Aktif",
                      style: GoogleFonts.poppins(
                        color: maroonPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _currentStatusFilter = TeacherStatusFilter.all;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          color: maroonPrimary,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Teacher List
          Expanded(
            child: BlocBuilder<TeachersCubit, TeachersState>(
              builder: (context, state) {
                if (state is TeachersFetchSuccess) {
                  return _buildTeacherList(state, context);
                }

                if (state is TeachersFetchFailure) {
                  return Center(
                    child: CustomErrorWidget(
                      message: state.errorMessage,
                      onRetry: () {
                        getTeachers();
                      },
                      primaryColor: maroonPrimary,
                    ),
                  );
                }

                return _buildTeacherSkeletonList();
              },
            ),
          ),
        ],
      ),
    );
  }

  void showFilterOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Filter Status Guru",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      onTap: () {
                        setState(() {
                          _currentStatusFilter = TeacherStatusFilter.all;
                        });
                        Navigator.pop(context);
                      },
                      title: Text(
                        "Semua Guru",
                        style: GoogleFonts.poppins(
                          fontWeight:
                              _currentStatusFilter == TeacherStatusFilter.all
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                          color: _currentStatusFilter == TeacherStatusFilter.all
                              ? maroonPrimary
                              : Colors.black87,
                        ),
                      ),
                      leading: Icon(
                        Icons.people_alt_rounded,
                        color: _currentStatusFilter == TeacherStatusFilter.all
                            ? maroonPrimary
                            : Colors.grey.shade600,
                      ),
                      trailing: _currentStatusFilter == TeacherStatusFilter.all
                          ? Icon(Icons.check_circle, color: maroonPrimary)
                          : null,
                      tileColor: _currentStatusFilter == TeacherStatusFilter.all
                          ? maroonPrimary.withValues(alpha: 0.05)
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      onTap: () {
                        setState(() {
                          _currentStatusFilter = TeacherStatusFilter.active;
                        });
                        Navigator.pop(context);
                      },
                      title: Text(
                        "Guru Aktif",
                        style: GoogleFonts.poppins(
                          fontWeight:
                              _currentStatusFilter == TeacherStatusFilter.active
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                          color:
                              _currentStatusFilter == TeacherStatusFilter.active
                                  ? maroonPrimary
                                  : Colors.black87,
                        ),
                      ),
                      leading: Icon(
                        Icons.check_circle_outline,
                        color:
                            _currentStatusFilter == TeacherStatusFilter.active
                                ? maroonPrimary
                                : Colors.grey.shade600,
                      ),
                      trailing:
                          _currentStatusFilter == TeacherStatusFilter.active
                              ? Icon(Icons.check_circle, color: maroonPrimary)
                              : null,
                      tileColor:
                          _currentStatusFilter == TeacherStatusFilter.active
                              ? maroonPrimary.withValues(alpha: 0.05)
                              : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      onTap: () {
                        setState(() {
                          _currentStatusFilter = TeacherStatusFilter.inactive;
                        });
                        Navigator.pop(context);
                      },
                      title: Text(
                        "Guru Non-Aktif",
                        style: GoogleFonts.poppins(
                          fontWeight: _currentStatusFilter ==
                                  TeacherStatusFilter.inactive
                              ? FontWeight.w500
                              : FontWeight.normal,
                          color: _currentStatusFilter ==
                                  TeacherStatusFilter.inactive
                              ? maroonPrimary
                              : Colors.black87,
                        ),
                      ),
                      leading: Icon(
                        Icons.remove_circle_outline,
                        color:
                            _currentStatusFilter == TeacherStatusFilter.inactive
                                ? maroonPrimary
                                : Colors.grey.shade600,
                      ),
                      trailing:
                          _currentStatusFilter == TeacherStatusFilter.inactive
                              ? Icon(Icons.check_circle, color: maroonPrimary)
                              : null,
                      tileColor:
                          _currentStatusFilter == TeacherStatusFilter.inactive
                              ? maroonPrimary.withValues(alpha: 0.05)
                              : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      // Refresh list after filter is selected
      setState(() {});
    });
  }
}

class BackgroundPatternPainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color accentColor;

  BackgroundPatternPainter({
    required this.animation,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Pola titik-titik
    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    for (var x = 0; x < width; x += 30) {
      for (var y = 0; y < height; y += 30) {
        final offset = math.sin(x * 0.05 + y * 0.05 + animation) * 3;
        final radius = 1 + math.sin(x * 0.04 + y * 0.04 + animation) * 0.5;
        canvas.drawCircle(
          Offset(x + offset, y + offset),
          radius,
          dotPaint,
        );
      }
    }

    // Gelombang animasi
    final wavePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var startY = 0; startY < height; startY += 200) {
      final path = Path();
      var startX = 0.0;
      path.moveTo(startX, startY.toDouble());

      for (var x = 0; x < width; x += 10) {
        final y = startY + math.sin(x * 0.02 + animation) * 20;
        path.lineTo(x.toDouble(), y);
      }

      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(BackgroundPatternPainter oldDelegate) => true;
}
