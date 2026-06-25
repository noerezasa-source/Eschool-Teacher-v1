import 'dart:convert';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'dart:math' as math;
import 'package:eschool_saas_staff/cubits/onlineExam/onlineExamCubit.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:eschool_saas_staff/ui/widgets/system/no_search_results_widget.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';

class OnlineExamResultScreen extends StatefulWidget {
  const OnlineExamResultScreen({super.key});

  @override
  State<OnlineExamResultScreen> createState() => _OnlineExamResultScreenState();
}

class _OnlineExamResultScreenState extends State<OnlineExamResultScreen>
    with TickerProviderStateMixin {
  late final _searchController = TextEditingController();
  bool _showSearchBar = false;
  bool _isSearching = false;
  String _selectedFilter = "Semua";
  DateTime? _startDate;
  DateTime? _endDate;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomModernAppBar(
        title: 'Hasil Ujian Online',
        icon: Icons.assignment_outlined,
        fabAnimationController: _animationController,
        primaryColor: _primaryColor,
        lightColor: _accentColor,
        onBackPressed: () => Navigator.of(context).pop(),
        showFilterButton: true,
        onFilterPressed: () => _showFilterBottomSheet(context),
        // Keep add, archive, and helper buttons disabled as requested
        showAddButton: false,
        showArchiveButton: false,
        showHelperButton: false,
      ),
      body: _buildBody(),
    );
  }

  // Animation controller for the app bar
  late AnimationController _animationController;

  // Theme colors for the app bar
  static Color get _primaryColor => AppColorPalette.primaryMaroon; // Deep maroon
  static Color get _accentColor => AppColorPalette.secondaryMaroon; // Medium maroon
  @override
  void initState() {
    super.initState();
    context.read<OnlineExamCubit>().getOnlineExams();

    // Initialize animation controller for the app bar
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Start the animation
    _animationController.forward();

    // Setup continuous animation for dynamic effects
    _animationController.repeat(reverse: true, min: 0.9, max: 1.0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Judul
                  Text(
                    'Filter Status Ujian',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColorPalette.primaryMaroon,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Input Tanggal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: modalContext,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setModalState(() {
                                _startDate = picked;
                                parentContext
                                    .read<OnlineExamCubit>()
                                    .getOnlineExams(
                                      search: _searchController.text,
                                      startDate: _startDate,
                                      endDate: _endDate,
                                    );
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _startDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_startDate!)
                                  : 'Dari',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[800]),
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '-',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: modalContext,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setModalState(() {
                                _endDate = picked;
                                parentContext
                                    .read<OnlineExamCubit>()
                                    .getOnlineExams(
                                      search: _searchController.text,
                                      startDate: _startDate,
                                      endDate: _endDate,
                                    );
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _endDate != null
                                  ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                  : 'Sampai',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[800]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Filter Status
                  RadioGroup<String>(
                    groupValue: _selectedFilter,
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value ?? 'Semua';
                        parentContext.read<OnlineExamCubit>().getOnlineExams(
                              search: _searchController.text,
                              startDate: _startDate,
                              endDate: _endDate,
                            );
                      });
                      setModalState(() {});
                      Navigator.pop(context);
                    },
                    child: Column(
                      children: [
                        _buildFilterOption(
                            'Semua', setModalState, parentContext),
                        _buildFilterOption(
                            'Selesai', setModalState, parentContext),
                        _buildFilterOption(
                            'Belum Dimulai', setModalState, parentContext),
                        _buildFilterOption(
                            'Sedang Berlangsung', setModalState, parentContext),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption(
      String label, StateSetter setModalState, BuildContext parentContext) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _selectedFilter = label;
              parentContext.read<OnlineExamCubit>().getOnlineExams(
                    search: _searchController.text,
                    startDate: _startDate,
                    endDate: _endDate,
                  );
            });
            setModalState(() {});
            Navigator.pop(context);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
                Radio<String>(
                  value: label,
                  activeColor: AppColorPalette.primaryMaroon,
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: Colors.grey[300]),
      ],
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _isSearching = _searchController.text.isNotEmpty;
        });
        await context.read<OnlineExamCubit>().getOnlineExams(
              search: _searchController.text,
              startDate: _startDate,
              endDate: _endDate,
            );
      },
      child: Column(
        children: [
          if (_showSearchBar) _buildSearchBar(),
          if (!_showSearchBar) const SizedBox(height: 20),
          Expanded(
            child: _buildExamCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController, // Gunakan controller
            onChanged: (value) {
              setState(() {
                _isSearching = value.isNotEmpty;
              });
              context.read<OnlineExamCubit>().getOnlineExams(
                    search: value,
                    startDate: _startDate,
                    endDate: _endDate,
                  );
            },
            decoration: InputDecoration(
              hintText: 'Cari hasil ujian...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamCard() {
    return BlocBuilder<OnlineExamCubit, OnlineExamState>(
      builder: (context, state) {
        if (state is OnlineExamLoading) {
          return _buildSkeletonLoading();
        }
        if (state is OnlineExamFailure) {
          return Center(
            child: CustomErrorWidget(
              message:
                  "Tidak dapat terhubung ke server, mohon periksa koneksi internet anda dan coba lagi",
              onRetry: () {
                context.read<OnlineExamCubit>().getOnlineExams();
              },
              primaryColor: AppColorPalette.primaryMaroon,
            ),
          );
        }
        if (state is OnlineExamSuccess) {
          if (state.exams.length > 5 && !_showSearchBar) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _showSearchBar = true;
              });
            });
          }

          final now = DateTime.now();
          final filteredExams = state.exams.where((exam) {
            if (_selectedFilter == "Semua") return true;

            int effectiveStatus = exam.status;
            if (exam.status == 0 &&
                now.isAfter(exam.startDate) &&
                now.isBefore(exam.endDate)) {
              effectiveStatus = 1;
            }

            if (_selectedFilter == "Belum Dimulai") return effectiveStatus == 0;
            if (_selectedFilter == "Sedang Berlangsung") {
              return effectiveStatus == 1;
            }
            if (_selectedFilter == "Selesai") return effectiveStatus == 2;
            return false;
          }).toList()
            ..sort((a, b) => b.startDate.compareTo(a.startDate));
          if (filteredExams.isEmpty) {
            // Jika sedang searching, gunakan NoSearchResultsWidget
            if (_isSearching) {
              return NoSearchResultsWidget(
                searchQuery: _searchController.text,
                onClearSearch: () {
                  setState(() {
                    _searchController.clear();
                    _isSearching = false;
                  });
                  context.read<OnlineExamCubit>().getOnlineExams(
                        startDate: _startDate,
                        endDate: _endDate,
                      );
                },
                primaryColor: _primaryColor,
                accentColor: _accentColor,
                title: 'Tidak Ada Hasil Ujian',
                description:
                    'Tidak ditemukan hasil ujian yang sesuai dengan pencarian Anda. Coba gunakan kata kunci yang berbeda.',
                clearButtonText: 'Hapus Pencarian',
                icon: Icons.assignment_outlined,
              );
            }
            // Jika tidak sedang searching, tampilkan pesan filter
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_list_off,
                        size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada ujian tersedia untuk filter ini',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredExams.length,
              itemBuilder: (context, index) {
                final exam = filteredExams[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 500),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildModernExamCard(context, exam),
                    ),
                  ),
                );
              },
            ),
          );
        }
        return const Center(child: Text('No data available'));
      },
    );
  }

  Widget _buildModernExamCard(BuildContext context, dynamic exam) {
    // Define modern color scheme with soft maroon colors - consistent with onlineExamScreen
    final colorScheme = {
      'primary': const Color.fromARGB(255, 172, 33, 33),
      'gradient1': const Color(0xFF7D1F1F), // Lighter maroon
      'gradient2': const Color(0xFF9B2F2F), // Medium maroon
      'gradient3': const Color(0xFFBF4040), // Soft bright maroon
      'neutral1': const Color(0xFF2D3748), // Dark text
      'neutral2': const Color(0xFF718096), // Secondary text
      'accent': const Color(0xFFE53E3E), // Accent color
    };

    // Improved calculation for text wrapping - same as onlineExamScreen.dart
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (exam.status == 2) {
                Get.toNamed(
                    "/OnlineExamResultQuestionsScreen/${exam.id}/${base64.encode(utf8.encode(exam.title))}");
              }
            },
            borderRadius: BorderRadius.circular(32),
            highlightColor: Colors.transparent,
            splashColor: colorScheme['primary']!.withValues(alpha: 0.05),
            child: Ink(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 237, 237, 237),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Exam Title and Status
                      Container(
                        height: headerHeight,
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

                            // Status Badge
                            Positioned(
                              top: 20,
                              right: 24,
                              child: Builder(builder: (context) {
                                final now = DateTime.now();
                                int effectiveStatus = exam.status;

                                // Logika Status Dinamis:
                                // Jika status di DB masih 0 (Belum Dimulai) tapi waktu sekarang sudah masuk jadwal,
                                // maka tampilkan sebagai Berlangsung (1).
                                if (exam.status == 0 &&
                                    now.isAfter(exam.startDate) &&
                                    now.isBefore(exam.endDate)) {
                                  effectiveStatus = 1;
                                }

                                return Container(
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
                                      Icon(
                                        effectiveStatus == 0
                                            ? Icons.schedule_outlined
                                            : effectiveStatus == 1
                                                ? Icons.play_circle_outline
                                                : Icons.check_circle_outline,
                                        size: 16,
                                        color: effectiveStatus == 0
                                            ? Colors.orange
                                            : effectiveStatus == 1
                                                ? Colors.blue
                                                : Colors.green,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        effectiveStatus == 0
                                            ? 'Belum Dimulai'
                                            : effectiveStatus == 1
                                                ? 'Berlangsung'
                                                : 'Selesai',
                                        style: TextStyle(
                                          color: effectiveStatus == 0
                                              ? Colors.orange
                                              : effectiveStatus == 1
                                                  ? Colors.blue
                                                  : Colors.green,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),

                            // Exam Title
                            Positioned(
                              top: 80,
                              left: 24,
                              right: 24,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width -
                                              64,
                                    ),
                                    child: Text(
                                      exam.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        height: 1.4,
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
                                    ),
                                  ),
                                  const SizedBox(height: 16),
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

                      // Content Section - bottom padding for overlapping card
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
                        child: const SizedBox(),
                      ),
                    ],
                  ),

                  // Overlapping Card with exam details
                  Positioned(
                    top: headerHeight - 85,
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
                          onTap: () {
                            if (exam.status == 2) {
                              Get.toNamed(
                                  "/OnlineExamResultQuestionsScreen/${exam.id}/${base64.encode(utf8.encode(exam.title))}");
                            }
                          },
                          splashColor:
                              colorScheme['primary']!.withValues(alpha: 0.05),
                          highlightColor: Colors.transparent,
                          child: Column(
                            children: [
                              // Subject and View Results Section
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: colorScheme['primary']!
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.assignment_outlined,
                                        color: colorScheme['primary'],
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            exam.status == 2
                                                ? 'Lihat Hasil Ujian'
                                                : 'Hasil Ujian',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: colorScheme['neutral1'],
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            exam.subjectName,
                                            style: TextStyle(
                                              color: colorScheme['neutral2'],
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (exam.status == 2)
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: colorScheme['primary']!
                                              .withValues(alpha: 0.07),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_rounded,
                                          color: colorScheme['primary'],
                                          size: 16,
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

                              // Exam Details Section
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
                                              'Tanggal',
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

                                    // Duration
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.timer_outlined,
                                              size: 16,
                                              color: colorScheme['accent'],
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Durasi',
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
                                          '${exam.duration} menit',
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

  Widget _buildSkeletonLoading() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: const SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: SkeletonOnlineExamCard(),
              ),
            ),
          );
        },
      ),
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
