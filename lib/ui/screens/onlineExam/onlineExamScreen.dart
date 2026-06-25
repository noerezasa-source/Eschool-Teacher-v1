import 'dart:async';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool_saas_staff/cubits/onlineExam/onlineExamCubit.dart';
import 'package:eschool_saas_staff/data/repositories/exam/onlineExamRepository.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/classSectionsAndSubjects.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/data/models/exam/onlineExam.dart' as exam;
import 'package:eschool_saas_staff/data/models/academic/subjectDetail.dart';
import '../../../app/routes.dart';
import 'package:eschool_saas_staff/cubits/academics/sessionYearsAndMediumsCubit.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';
import 'package:eschool_saas_staff/ui/widgets/system/no_search_results_widget.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';

class OnlineExamScreen extends StatefulWidget {
  const OnlineExamScreen({super.key});

  static Widget getRouteInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<OnlineExamCubit>(
          create: (context) => OnlineExamCubit(OnlineExamRepository()),
        ),
        BlocProvider<ClassSectionsAndSubjectsCubit>(
          create: (context) => ClassSectionsAndSubjectsCubit(),
        ),
        BlocProvider<SessionYearsAndMediumsCubit>(
          create: (context) => SessionYearsAndMediumsCubit(),
        ),
      ],
      child: const OnlineExamScreen(),
    );
  }

  static Map<String, dynamic> buildArguments() {
    return {};
  }

  @override
  State<OnlineExamScreen> createState() => _OnlineExamScreenState();
}

class _OnlineExamScreenState extends State<OnlineExamScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? selectedSubject;
  int? selectedSessionYearId;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  String searchQuery = ""; // Tambahkan ini
  String? _restoredExamId; // ID ujian yang baru dipulihkan untuk highlight

  // Animation controller for CustomModernAppBar
  late AnimationController _appBarAnimationController;

  SubjectDetail? selectedSubjectDetail;
  List<SubjectDetail> subjectDetails = [];
  String? selectedTingkatan;
  String? selectedKelas;
  String? selectedMapel;
  List<String> tingkatanList = [];
  List<String> kelasList = [];
  List<String> mapelList = [];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _examSub;

  // Theme colors - Softer Maroon palette
  static Color get _primaryColor => AppColorPalette.primaryMaroon; // Softer deep maroon
  static Color get _highlightColor =>
      AppColorPalette.secondaryMaroon; // Softer bright maroon
  @override
  void initState() {
    super.initState();
    // Initialize date formatting for Indonesian locale
    initializeDateFormatting('id_ID', null);
    _refreshExams();

    // Initialize class sections and session years
    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<ClassSectionsAndSubjectsCubit>().getClassSectionsAndSubjects();
        context.read<SessionYearsAndMediumsCubit>().getSessionYearsAndMediums();
      }
    });

    // Add listener for state changes
    _examSub = context.read<OnlineExamCubit>().stream.listen((state) {
      if (state is OnlineExamSuccess) {
        setState(() {
          // Update UI when new data arrives
        });
      }
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();

    // Add this new controller for pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Initialize the app bar animation controller
    _appBarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    // Make sure to stop animations before disposing
    _examSub?.cancel();
    _animationController.stop();
    _pulseController.stop();
    _appBarAnimationController.stop();

    // Dispose all controllers
    _animationController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    _appBarAnimationController.dispose();

    super.dispose();
  }

  void _refreshExams({bool resetFilters = false}) {
    debugPrint('=== OnlineExamScreen: Triggering Refresh (ResetFilters: $resetFilters) ===');
    
    if (resetFilters) {
      setState(() {
        selectedMapel = null;
        selectedKelas = null;
        selectedTingkatan = null;
        searchQuery = "";
      });
    }

    // Cancel any existing subscriptions
    if (mounted) {
      int? sessionYearId;
      final sessionState = context.read<SessionYearsAndMediumsCubit>().state;
      if (sessionState is SessionYearsAndMediumsFetchSuccess) {
        sessionYearId = sessionState.sessionYears
            .firstWhereOrNull((s) => s.defaultYear == 1)
            ?.id;
      }

      context.read<OnlineExamCubit>().getOnlineExams(
            sessionYearId: sessionYearId,
          );
    }
  }



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh exams when returning to this screen
    _refreshExams();
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar to transparent with light icons for better visibility on dark app bar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Make sure to stop animations before popping
        _animationController.stop();
        _pulseController.stop();
        _appBarAnimationController.stop();
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        extendBodyBehindAppBar: true,
        appBar: CustomModernAppBar(
          title: 'Ujian Online',
          icon: Icons.assignment_outlined,
          fabAnimationController: _appBarAnimationController,
          primaryColor: _primaryColor,
          lightColor: _highlightColor,
          showAddButton: true,
          onAddPressed: () async {
            // Navigate ke create exam screen dan tunggu hasil
            final result = await Get.toNamed(Routes.createOnlineExam);
            // Jika kembali dengan result true, refresh data dan reset filter agar ujian baru kelihatan
            if (result == true) {
              // Berikan jeda sangat singkat untuk sinkronisasi server
              await Future.delayed(const Duration(milliseconds: 500));
              _refreshExams(resetFilters: true);
            }
          },
          showArchiveButton: true,
          onArchivePressed: () async {
            // Navigate to archived exams page and wait for result
            final result = await Get.toNamed(Routes.archiveOnlineExam);
            if (!context.mounted) return;
            // If an exam was restored, refresh data and show the restored exam
            if (result != null && result is Map<String, dynamic>) {
              if (result['action'] == 'restored') {
                // Store the restored exam ID for highlighting
                _restoredExamId = result['examId'].toString();

                // Immediately inject restored exam into active list
                if (result['exam'] != null && result['exam'] is exam.OnlineExam) {
                  final restoredExam = (result['exam'] as exam.OnlineExam).copyWith(status: 1);
                  context.read<OnlineExamCubit>().addExam(restoredExam);
                }

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
                            'Ujian berhasil dipulihkan!',
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

                // Background sync: refresh from backend to ensure consistency
                Future.delayed(const Duration(milliseconds: 1200), () {
                  if (mounted) {
                    _refreshExams();
                  }
                });

                // Remove highlight after 8 seconds
                Future.delayed(const Duration(seconds: 8), () {
                  if (mounted) {
                    setState(() {
                      _restoredExamId = null;
                    });
                  }
                });
              }
            }
          },
          onBackPressed: () {
            // Make sure to stop animations before popping
            _animationController.stop();
            _pulseController.stop();
            _appBarAnimationController.stop();
            Get.back();
          },
        ),
        body: _buildAnimatedBody(),
      ),
    );
  }

  // _buildCreateExamButton method removed as we're using the CustomModernAppBar add button
  Widget _buildAnimatedBody() {
    return AnimationLimiter(
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Add padding for the app bar
          const SliverPadding(
            padding: EdgeInsets.only(
                top:
                    120), // Increased padding to create more space between appbar and search
            sliver: SliverToBoxAdapter(child: SizedBox()),
          ),
          _buildSearchAndFilter(),
          BlocBuilder<OnlineExamCubit, OnlineExamState>(
            builder: (context, state) {
              if (state is OnlineExamLoading) {
                return SliverFillRemaining(
                  child: _buildShimmerLoading(),
                );
              }
              if (state is OnlineExamSuccess) {
                return state.exams.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyState())
                    : _buildExamGrid(state);
              }
              if (state is OnlineExamFailure) {
                return SliverFillRemaining(
                  child: CustomErrorWidget(
                    message: ErrorMessageUtils.getReadableErrorMessage(
                        state.message),
                    onRetry: _refreshExams,
                    primaryColor: _primaryColor,
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 20),
            _buildFilterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Cari ujian...',
            prefixIcon:
                Icon(Icons.search, color: Theme.of(context).primaryColor),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear,
                        color: Theme.of(context).primaryColor),
                    onPressed: () {
                      setState(() {
                        searchQuery = "";
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return BlocBuilder<OnlineExamCubit, OnlineExamState>(
      builder: (context, state) {
        List<SubjectDetail> subjects = [];
        if (state is OnlineExamSuccess) {
          subjects = state.subjectDetails
              .where((e) => e != null)
              .map((e) {
                try {
                  return SubjectDetail.fromJson(e);
                } catch (error) {
                  return null;
                }
              })
              .whereType<SubjectDetail>()
              .toList();
        }

        // Build Tingkatan list (X, XI, XII) from subjectDetails
        tingkatanList = subjects
            .map((e) => e.classSection.name.split(RegExp(r"\s+")).first.trim())
            .where((t) => t.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        // Build Kelas list based on selectedTingkatan
        // Use exact match on the first token (tingkatan) to avoid 'X' matching 'XI'/'XII'
        kelasList = selectedTingkatan == null
            ? []
            : subjects
                .where((e) =>
                    e.classSection.name.split(RegExp(r"\s+")).first.trim() ==
                    selectedTingkatan)
                .map((e) => e.classSection.name)
                .toSet()
                .toList()
          ..sort();

        // Build Mapel list based on selectedKelas
        mapelList = selectedKelas == null
            ? []
            : subjects
                .where((e) => e.classSection.name == selectedKelas)
                .map((e) => e.subject.name)
                .toSet()
                .toList()
          ..sort();

        return FadeInDown(
          duration: const Duration(milliseconds: 700),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppColorPalette.primaryMaroon.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_alt_rounded,
                            color: AppColorPalette.primaryMaroon),
                        const SizedBox(width: 10),
                        Text(
                          'Filter Ujian',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColorPalette.primaryMaroon,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedTingkatan = null;
                          selectedKelas = null;
                          selectedMapel = null;
                        });
                        context.read<OnlineExamCubit>().getOnlineExams();
                      },
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          color: AppColorPalette.primaryMaroon,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Tingkatan Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedTingkatan,
                  decoration: InputDecoration(
                    prefixIcon:
                        Icon(Icons.layers, color: AppColorPalette.primaryMaroon),
                    labelText: 'Pilih Tingkatan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColorPalette.primaryMaroon),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColorPalette.primaryMaroon),
                    ),
                  ),
                  items: tingkatanList
                      .map((tingkatan) => DropdownMenuItem<String>(
                            value: tingkatan,
                            child: Text(tingkatan),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedTingkatan = value;
                      selectedKelas = null;
                      selectedMapel = null;
                    });
                  },
                  isExpanded: true,
                  hint: Text('Pilih Tingkatan',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ),
                if (selectedTingkatan != null) ...[
                  const SizedBox(height: 15),
                  // Kelas Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedKelas,
                    decoration: InputDecoration(
                      prefixIcon:
                          Icon(Icons.class_, color: AppColorPalette.primaryMaroon),
                      labelText: 'Pilih Kelas',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColorPalette.primaryMaroon),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColorPalette.primaryMaroon),
                      ),
                    ),
                    items: kelasList
                        .map((kelas) => DropdownMenuItem<String>(
                              value: kelas,
                              child: Text(kelas),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedKelas = value;
                        selectedMapel = null;
                      });
                    },
                    isExpanded: true,
                    hint: Text('Pilih Kelas',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ),
                ],
                if (selectedKelas != null) ...[
                  const SizedBox(height: 15),
                  // Mata Pelajaran Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedMapel,
                    decoration: InputDecoration(
                      prefixIcon:
                          Icon(Icons.menu_book, color: AppColorPalette.primaryMaroon),
                      labelText: 'Pilih Mata Pelajaran',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColorPalette.primaryMaroon),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColorPalette.primaryMaroon),
                      ),
                    ),
                    items: mapelList
                        .map((mapel) => DropdownMenuItem<String>(
                              value: mapel,
                              child: Text(mapel),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMapel = value;
                      });
                      // Find the SubjectDetail for this selection
                      final matches = subjects
                          .where((e) =>
                              e.classSection.name == selectedKelas &&
                              e.subject.name == value)
                          .toList();
                      if (matches.isNotEmpty) {
                        final selectedDetail = matches.first;
                        context.read<OnlineExamCubit>().getOnlineExams(
                              subjectId: selectedDetail.classSubjectId,
                              classSectionId: selectedDetail.classSection.id,
                            );
                      }
                    },
                    isExpanded: true,
                    hint: Text('Pilih Mata Pelajaran',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExamGrid(OnlineExamSuccess state) {
    // 1. Filter berdasarkan kata kunci pencarian
    var filteredExams = state.exams.where((exam) {
      final matchesSearch = searchQuery.isEmpty || 
          exam.title.toLowerCase().contains(searchQuery.toLowerCase());
      
      // 2. Filter berdasarkan Tingkatan (diambil dari token pertama nama kelas, misal "X" dari "X IPA 1")
      bool matchesTingkatan = true;
      if (selectedTingkatan != null) {
        final examTingkatan = exam.classSectionName.split(RegExp(r"\s+")).first.trim();
        matchesTingkatan = examTingkatan == selectedTingkatan;
      }

      // CATATAN: Filter Kelas dan Mapel tidak perlu dicek lagi di sini karena sudah 
      // dilakukan oleh server (filtering by ID) saat pemilihan di dropdown.
      
      return matchesSearch && matchesTingkatan;
    }).toList();

    // Sort to prioritize restored exam if exists
    if (_restoredExamId != null) {
      // Debug: check if restored exam exists in the list
      final restoredExamExists =
          filteredExams.any((exam) => exam.id.toString() == _restoredExamId);
      debugPrint('DEBUG: Looking for restored exam ID: $_restoredExamId');
      debugPrint('DEBUG: Restored exam exists in list: $restoredExamExists');
      debugPrint(
          'DEBUG: Total exams in filtered list: ${filteredExams.length}');

      filteredExams.sort((a, b) {
        final aIsRestored = a.id.toString() == _restoredExamId;
        final bIsRestored = b.id.toString() == _restoredExamId;

        // Prioritize restored exam at the top
        if (aIsRestored && !bIsRestored) return -1;
        if (!aIsRestored && bIsRestored) return 1;

        // For non-restored exams, sort by ID (newer ID = newer exam)
        if (!aIsRestored && !bIsRestored) {
          return b.id.compareTo(a.id);
        }

        return 0;
      });

      // Debug: check position after sorting
      if (restoredExamExists && filteredExams.isNotEmpty) {
        final restoredExamIndex = filteredExams
            .indexWhere((exam) => exam.id.toString() == _restoredExamId);
        debugPrint(
            'DEBUG: Restored exam position after sorting: $restoredExamIndex');
      }
    } else {
      // Default sorting by ID (newest first) when no restored exam
      filteredExams.sort((a, b) => b.id.compareTo(a.id));
    } // Jika tidak ada ujian yang sesuai dengan pencarian, tampilkan NoSearchResultsWidget
    // 5. Handle empty state after filtering
    final bool hasActiveFilters = searchQuery.isNotEmpty || 
                                 selectedTingkatan != null || 
                                 selectedKelas != null || 
                                 selectedMapel != null;

    if (filteredExams.isEmpty && hasActiveFilters) {
      return SliverFillRemaining(
        child: NoSearchResultsWidget(
          searchQuery: searchQuery,
          onClearSearch: () {
            setState(() {
              searchQuery = "";
              selectedTingkatan = null;
              selectedKelas = null;
              selectedMapel = null;
            });
            _refreshExams();
          },
          primaryColor: _primaryColor,
          accentColor: _highlightColor,
          title: 'Ujian Tidak Ditemukan',
          description: 'Tidak ada ujian yang sesuai dengan kriteria filter atau pencarian Anda.',
          clearButtonText: 'Reset Semua Filter',
          icon: Icons.filter_list_off,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 500),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildExamCard(context, filteredExams[index]),
                ),
              ),
            );
          },
          childCount: filteredExams.length,
        ),
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, exam.OnlineExam exam) {
    // Check if this is the restored exam for highlighting
    final bool isRecentlyRestored = _restoredExamId == exam.id.toString();

    // Define modern color scheme with soft maroon colors
    final colorScheme = {
      'primary': const Color.fromARGB(255, 172, 33, 33),
      'gradient1': const Color(0xFF7D1F1F), // Lighter maroon
      'gradient2': const Color(0xFF9B2F2F), // Medium maroon
      'gradient3': const Color(0xFFBF4040), // Soft bright maroon
      'neutral1': const Color(0xFF333333), // Dark gray for primary text
      'neutral2': const Color(0xFF666666), // Medium gray for secondary text
      'accent': const Color(0xFF8B4513), // Brown accent color
    }; // Calculate the positioning for perfect centering

    // Improved calculation for text wrapping
    final double screenWidth = MediaQuery.of(context).size.width;
    final double availableWidth = screenWidth - 48; // 24px padding on each side
    const double titleFontSize = 24.0;
    const double lineHeight = 1.4;

    // Calculate estimated number of lines based on character count and available width
    final int estimatedCharactersPerLine =
        (availableWidth / (titleFontSize * 0.6)).floor();
    final int estimatedLines =
        math.max(1, (exam.title.length / estimatedCharactersPerLine).ceil());
    final double estimatedTextHeight =
        estimatedLines * (titleFontSize * lineHeight);

    const double minHeight = 260.0; // Increased minimum height untuk header
    const double maxHeight = 450.0; // Increased maximum height untuk header

    // Sesuaikan headerHeight dengan batasan min dan max, plus extra space untuk wrapping
    final double headerHeight = math.min(
      maxHeight,
      math.max(minHeight,
          estimatedTextHeight + 200.0), // Increased padding for better spacing
    );

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: isRecentlyRestored
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.1),
                    blurRadius: 40,
                    spreadRadius: 5,
                    offset: const Offset(0, 0),
                  ),
                ],
              )
            : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Get.toNamed('/exam-questions/${exam.id}'),
            borderRadius: BorderRadius.circular(32),
            highlightColor: Colors.transparent,
            splashColor: colorScheme['primary']!.withValues(alpha: 0.05),
            child: Ink(
              decoration: BoxDecoration(
                color: isRecentlyRestored
                    ? const Color.fromARGB(255, 240, 253,
                        244) // Light green tint for restored exam
                    : const Color.fromARGB(
                        255, 237, 237, 237), // Very slightly off-white
                borderRadius: BorderRadius.circular(32),
                border: isRecentlyRestored
                    ? Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                        width: 2,
                      )
                    : null,
                // Keep your existing shadows if desired
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Exam Title
                      Container(
                        height: headerHeight, // Increased height
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme['gradient1']!,
                              colorScheme['gradient2']!,
                              colorScheme['gradient3']!,
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Decorative Pattern Overlay
                            Opacity(
                              opacity: 0.07,
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: Modern2025PatternPainter(
                                  primaryColor: Colors.white,
                                  secondaryColor:
                                      Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ),

                            // Glow Effect Corner
                            Positioned(
                              top: -30,
                              right: -30,
                              child: Container(
                                height: 150,
                                width: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.2),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Duration Badge
                            Positioned(
                              top: 20,
                              right: 24,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      spreadRadius: -5,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timer_outlined,
                                        size: 16,
                                        color: colorScheme['primary']),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${exam.duration} min',
                                      style: TextStyle(
                                        color: colorScheme['primary'],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Exam Title - Updated position and styling with better wrapping
                            Positioned(
                              top: 80, // Move title more to top
                              left: 24,
                              right: 24,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Remove Container constraint and let text wrap naturally
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Text(
                                        exam.title,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize:
                                              24, // Keep consistent font size
                                          fontWeight: FontWeight.w800,
                                          height:
                                              1.4, // Good line height for readability
                                          letterSpacing: 0.3,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.5),
                                              offset: const Offset(0, 2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                        textAlign: TextAlign.left,
                                        maxLines: null, // Allow unlimited lines
                                      );
                                    },
                                  ),
                                  // Add restored badge if applicable

                                  Container(
                                    width: 60,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(1.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content Section - Dynamic padding based on header height
                      Container(
                        padding: EdgeInsets.fromLTRB(
                            24,
                            math.max(
                                120,
                                (headerHeight * 0.35)
                                    .round()
                                    .toDouble()), // Dynamic top padding based on header height
                            24,
                            24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Actions Row - Modern Button Design
                            Row(
                              children: [
                                // Edit Button - Modern Design
                                Expanded(
                                  child: _buildModernActionButton(
                                    onTap: () async {
                                      // Navigate ke edit exam screen dan tunggu hasil
                                      final result = await Get.toNamed(
                                        Routes.editOnlineExam,
                                        arguments: exam,
                                      );
                                      // Jika kembali dengan result true, refresh data
                                      if (result == true) {
                                        _refreshExams();
                                      }
                                    },
                                    icon: Icons.edit_outlined,
                                    label: 'Edit',
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF26A69A),
                                        Color(0xFF00897B),
                                        Color(0xFF00796B),
                                      ],
                                    ),
                                    shadowColor: const Color(0xFF26A69A)
                                        .withValues(alpha: 0.4),
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Archive Button - Modern Design
                                Expanded(
                                  child: _buildModernActionButton(
                                    onTap: () => _showDeleteConfirmation(exam),
                                    icon: Icons.archive_outlined,
                                    label: 'Arsip',
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF9C4146), // Softer maroon
                                        Color(0xFF812A33), // Medium maroon
                                        Color(0xFF6A1B24), // Deep maroon
                                      ],
                                    ),
                                    shadowColor: const Color(0xFF812A33)
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Overlapping Card - Dynamic position based on header height
                  Positioned(
                    top: headerHeight -
                        85, // Dynamic positioning based on header height
                    left: 20,
                    right: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                            spreadRadius: -5,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 5,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () =>
                              Get.toNamed('/exam-questions/${exam.id}'),
                          splashColor:
                              colorScheme['primary']!.withValues(alpha: 0.05),
                          highlightColor: Colors.transparent,
                          child: Column(
                            children: [
                              // Top section: Manage Questions
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    // Icon Container - reduced padding
                                    Container(
                                      padding: const EdgeInsets.all(
                                          10), // Reduced from 12
                                      decoration: BoxDecoration(
                                        color: colorScheme['primary']!
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.question_answer_rounded,
                                        color: colorScheme['primary'],
                                        size: 20, // Reduced from 22
                                      ),
                                    ),
                                    const SizedBox(
                                        width: 12), // Reduced from 16

                                    // Text Content - with overflow handling
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Kelola Soal Ujian',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: colorScheme['neutral1'],
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Lihat dan atur soal pada ujian ini',
                                            style: TextStyle(
                                              color: colorScheme['neutral2'],
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Arrow Icon - reduced padding
                                    Container(
                                      padding: const EdgeInsets.all(
                                          8), // Reduced from 10
                                      decoration: BoxDecoration(
                                        color: colorScheme['primary']!
                                            .withValues(alpha: 0.07),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        color: colorScheme['primary'],
                                        size: 16, // Reduced from 18
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Divider
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: colorScheme['primary']!
                                    .withValues(alpha: 0.08),
                                indent: 20,
                                endIndent: 20,
                              ),

                              // Bottom section: Dates display
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    // Start Date
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              size: 16,
                                              color: colorScheme['primary'],
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Mulai',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colorScheme['neutral2'],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('dd MMM yyyy', 'id_ID')
                                              .format(exam.startDate),
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: colorScheme['neutral1'],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Divider
                                    Container(
                                      height: 35,
                                      width: 1,
                                      color: Colors.grey.shade200,
                                    ),

                                    // End Date
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.calendar_month_rounded,
                                              size: 16,
                                              color: colorScheme['accent'],
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Selesai',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colorScheme['neutral2'],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('dd MMM yyyy', 'id_ID')
                                              .format(exam.endDate),
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: colorScheme['neutral1'],
                                            fontWeight: FontWeight.w600,
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
  }

  Widget _buildModernActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required Color shadowColor,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.3),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.transparent,
          child: Stack(
            children: [
              // Subtle pattern overlay
              Opacity(
                opacity: 0.05,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: NetworkImage(
                          'https://www.transparenttextures.com/patterns/cubes.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // Button content
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Top highlight for 3D effect
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (_, index) {
        return const SkeletonOnlineExamCard();
      },
    );
  }

  Widget _buildEmptyState() {
    return FadeIn(
      duration: const Duration(milliseconds: 800),
      child: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                Icon(
                  Icons.assignment_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 20),
                Text(
                  'Belum ada ujian',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Tambahkan ujian baru dengan menekan tombol +',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(exam.OnlineExam exam) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF812A33).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.archive_rounded,
                  color: Color(0xFF812A33),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Arsipkan Ujian',
                  style: TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda yakin ingin mengarsipkan ujian "${exam.title}"?',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ujian yang diarsipkan dapat dilihat kembali di menu Arsip.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF9C4146), // Softer maroon
                            Color(0xFF812A33), // Medium maroon
                            Color(0xFF6A1B24), // Deep maroon
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF812A33).withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(dialogContext);
                            try {
                              await context
                                  .read<OnlineExamCubit>()
                                  .deleteOnlineExam(
                                    examId: exam.id,
                                    mode: 'archive',
                                  );

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: Colors.white),
                                        SizedBox(width: 12),
                                        Text(
                                          'Ujian berhasil diarsipkan!',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  backgroundColor: const Color(0xFF2E7D32),
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

                              Future.delayed(const Duration(milliseconds: 800),
                                  () {
                                if (mounted) {
                                  _refreshExams();
                                }
                              });
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Gagal mengarsipkan ujian'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          splashColor: Colors.white.withValues(alpha: 0.2),
                          highlightColor: Colors.transparent,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.archive_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Arsipkan Sekarang',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    letterSpacing: 0.3,
                                  ),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class Modern2025PatternPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  Modern2025PatternPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create a sophisticated pattern with curved lines and dots
    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    const double spacing = 40;

    // Draw curved lines
    for (double i = -size.width / 2; i < size.width * 1.5; i += spacing) {
      final path = Path();
      path.moveTo(i, 0);

      // Create a gentle curve
      path.quadraticBezierTo(
          i + size.width / 3, size.height / 2, i + size.width / 4, size.height);

      canvas.drawPath(path, paint);
    }

    // Add decorative dots
    for (int i = 0; i < 12; i++) {
      double x = (size.width / 12) * i + (i % 2 == 0 ? 10 : -10);
      double y = (i % 3 == 0)
          ? size.height * 0.2
          : (i % 3 == 1)
              ? size.height * 0.5
              : size.height * 0.8;

      // Vary dot sizes
      double radius = (i % 4 == 0)
          ? 3.0
          : (i % 4 == 1)
              ? 1.5
              : (i % 4 == 2)
                  ? 2.0
                  : 1.0;

      canvas.drawCircle(Offset(x, y), radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
