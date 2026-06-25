import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/academics/sessionYearsCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/assignment/assignmentMonitoringCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/sessionYear.dart';
import 'package:eschool_saas_staff/data/repositories/academics/assignmentMonitoringRepository.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customFilterModernAppbar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class AssignmentMonitoringScreen extends StatefulWidget {
  const AssignmentMonitoringScreen({super.key});

  static Widget getRouteInstance() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionYearsCubit>(
          create: (context) => SessionYearsCubit(),
        ),
        BlocProvider<AssignmentMonitoringCubit>(
          create: (context) => AssignmentMonitoringCubit(
            assignmentMonitoringRepository: AssignmentMonitoringRepository(),
          ),
        ),
      ],
      child: const AssignmentMonitoringScreen(),
    );
  }

  @override
  State<AssignmentMonitoringScreen> createState() =>
      _AssignmentMonitoringScreenState();
}

class _AssignmentMonitoringScreenState extends State<AssignmentMonitoringScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  // Define colors
  Color get maroonPrimary => AppColorPalette.primaryMaroon;
  Color get maroonLight => AppColorPalette.secondaryMaroon;
  final Color maroonDark = const Color(0xFF6A0F2A);
  Color get accentColor => AppColorPalette.lightMaroon;
  Color get bgColor => AppColorPalette.accentPink;
  final Color cardColor = Colors.white;
  final Color textDarkColor = const Color(0xFF2D2D2D);
  final Color textMediumColor = const Color(0xFF717171);
  final Color borderColor = const Color(0xFFE8E8E8);

  // Gradient colors for modern design
  final List<Color> gradientColors = [
    AppColorPalette.primaryMaroon,
    AppColorPalette.secondaryMaroon,
  ];
  // Filter variables
  SessionYear? _selectedSessionYear;
  String _submissionStatus = '';
  DateTime? _startDate;
  DateTime? _endDate;
  double _headerHeight =
      240.0; // Increased initial height with expanded filters
  final ScrollController _scrollController = ScrollController();

  // Pagination variables
  int _currentPage = 1;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Start animations
    _animationController
        .forward(); // Set current date range to the last 30 days by default    _endDate = DateTime.now();
    _startDate = _endDate?.subtract(const Duration(days: 30));

    // Set default submission status to not_submitted
    _submissionStatus =
        'not_submitted'; // Scroll listener for collapsing header effect
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && _headerHeight == 240.0) {
        setState(() {
          _headerHeight =
              160.0; // Increased collapsed height for header (still has room for 3 filters)
        });
      } else if (_scrollController.offset <= 50 && _headerHeight == 160.0) {
        setState(() {
          _headerHeight = 240.0; // Increased expanded height for header
        });
      }
    });

    // Initialize data loading pipeline
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SessionYearsCubit>().getSessionYears();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchAssignmentMonitoring() {
    if (_selectedSessionYear == null) return;

    final String? formattedStartDate = _startDate != null
        ? DateFormat('yyyy-MM-dd').format(_startDate!)
        : null;

    final String? formattedEndDate =
        _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

    // Debugging info untuk filter yang digunakan
    debugPrint('Fetching assignment monitoring with filters:');
    debugPrint(
        '- Submission Status: ${_submissionStatus.isEmpty ? "all" : _submissionStatus}');
    debugPrint('- Start Date: $formattedStartDate');
    debugPrint('- End Date: $formattedEndDate');
    debugPrint('- Page: $_currentPage, Limit: $_limit');

    context.read<AssignmentMonitoringCubit>().getAssignmentMonitoring(
          submissionStatus:
              _submissionStatus.isEmpty ? null : _submissionStatus,
          startDate: formattedStartDate,
          endDate: formattedEndDate,
          page: _currentPage,
          limit: _limit,
        );
  }

  void _changeSelectedSessionYear(SessionYear sessionYear) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedSessionYear = sessionYear;
      _currentPage = 1; // Reset pagination when changing filters
    });
    _fetchAssignmentMonitoring();
  }

  void _changeSubmissionStatus(String status) {
    HapticFeedback.lightImpact();
    setState(() {
      _submissionStatus = status;
      _currentPage = 1; // Reset pagination when changing filters
    });

    // Print status yang dipilih untuk debugging
    debugPrint('Selected submission status: $_submissionStatus');

    _fetchAssignmentMonitoring();
  }

  void _changeDateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      HapticFeedback.lightImpact();
      setState(() {
        _startDate = start;
        _endDate = end;
        _currentPage = 1; // Reset pagination when changing filters
      });
      _fetchAssignmentMonitoring();
    }
  }

  void _showSessionYearFilter(
      BuildContext context, List<SessionYear> sessionYears) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Pilih Tahun Ajaran',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textDarkColor,
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: sessionYears.length,
                  itemBuilder: (context, index) {
                    final SessionYear sessionYear = sessionYears[index];
                    final bool isSelected =
                        _selectedSessionYear?.id == sessionYear.id;

                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _changeSelectedSessionYear(sessionYear);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 16.0,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? maroonPrimary.withValues(alpha: 0.1)
                              : null,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                sessionYear.name ?? 'Unnamed',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? maroonPrimary
                                      : textDarkColor,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: maroonPrimary,
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

  void _showSubmissionStatusFilter(BuildContext context) {
    final List<Map<String, String>> statusOptions = [
      {'value': 'submitted', 'label': 'Sudah Mengumpulkan'},
      {'value': 'not_submitted', 'label': 'Belum Mengumpulkan'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Filter Status Pengumpulan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textDarkColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Pilih status untuk menampilkan guru berdasarkan status pengumpulan tugas',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: textMediumColor,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: statusOptions.length,
                  itemBuilder: (context, index) {
                    final option = statusOptions[index];
                    final bool isSelected =
                        _submissionStatus == option['value'];

                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _changeSubmissionStatus(option['value']!);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 16.0,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? maroonPrimary.withValues(alpha: 0.1)
                              : null,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option['label']!,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? maroonPrimary
                                      : textDarkColor,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: maroonPrimary,
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

  void _showDateRangePicker(BuildContext context) {
    showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: maroonPrimary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: maroonPrimary,
              ),
            ),
          ),
          child: child!,
        );
      },
    ).then((dateRange) {
      if (dateRange != null) {
        _changeDateRange(dateRange.start, dateRange.end);
      }
    });
  }

  PreferredSizeWidget _buildHeaderSection() {
    final String dateRangeText = _startDate != null && _endDate != null
        ? '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM').format(_endDate!)}'
        : 'Pilih Tanggal';
    final String statusText = _submissionStatus == 'submitted'
        ? 'Sudah Mengumpulkan'
        : 'Belum Mengumpulkan';

    return CustomFilterModernAppBar(
      title: 'Monitoring Tugas Guru',
      titleIcon: Icons.assignment_outlined,
      primaryColor: maroonPrimary,
      secondaryColor: maroonLight,
      onBackPressed: () {
        Navigator.pop(context);
      },
      animationController: _animationController,
      enableAnimations: true,
      height: _headerHeight + 20, // Increase height to add more spacing
      firstFilterItem: FilterItemConfig(
        title: dateRangeText,
        icon: Icons.date_range_rounded,
        onTap: () {
          _showDateRangePicker(context);
        },
      ),
      secondFilterItem: FilterItemConfig(
        title: _selectedSessionYear?.name ?? "Tahun Ajaran",
        icon: Icons.calendar_today_rounded,
        onTap: () {
          final state = context.read<SessionYearsCubit>().state;
          if (state is SessionYearsFetchSuccess) {
            _showSessionYearFilter(context, state.sessionYears);
          }
        },
      ),
      thirdFilterItem: FilterItemConfig(
        title: statusText,
        icon: Icons.assignment_turned_in_rounded,
        onTap: () {
          _showSubmissionStatusFilter(context);
        },
      ),
    );
  }

  Widget _buildStatisticsCard(int total) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: maroonPrimary.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with icon
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.insert_chart_rounded,
                  color: maroonPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ringkasan Monitoring',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: maroonPrimary,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(
              begin: -0.1, end: 0, duration: 500.ms, curve: Curves.easeOutQuad),

          const SizedBox(height: 4),

          // Summary content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Progress bar section
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Jumlah Guru',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: textMediumColor,
                            ),
                          ),
                          Text(
                            '$total Guru',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: total > 50
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms).slideX(
                          begin: -0.1,
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.easeOutQuad),

                      const SizedBox(height: 8),

                      // Progress bar with animation
                      Stack(
                        children: [
                          // Background
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          // Fill
                          Container(
                            height: 8,
                            width: MediaQuery.of(context).size.width *
                                0.6 *
                                (total > 100 ? 0.9 : total / 100),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: total > 50
                                    ? [
                                        Colors.green.shade400,
                                        Colors.green.shade700
                                      ]
                                    : [
                                        Colors.orange.shade400,
                                        Colors.orange.shade700
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms).slideX(
                          begin: -0.2,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOutQuad),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Additional info section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: textMediumColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data monitoring tugas dari semua guru berdasarkan filter',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: textMediumColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(
        begin: const Offset(0.95, 0.95),
        end: const Offset(1.0, 1.0),
        duration: 500.ms);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_outlined,
                color: maroonPrimary.withValues(alpha: 0.7),
                size: 80,
              ),
            ).animate().scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 500.ms),
            const SizedBox(height: 24),
            Text(
              'Tidak ada data tugas',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: maroonPrimary,
                letterSpacing: 0.5,
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            Text(
              _submissionStatus == 'not_submitted'
                  ? 'Tidak ada guru yang belum mengumpulkan tugas'
                  : _submissionStatus == 'submitted'
                      ? 'Tidak ada guru yang sudah mengumpulkan tugas'
                      : 'Coba ubah filter untuk melihat data lainnya',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textMediumColor,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms)
                .slideY(begin: 0.3, end: 0),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _showDateRangePicker(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: maroonPrimary,
                foregroundColor: Colors.white,
                elevation: 2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_alt_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Ubah Filter Tanggal',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms).scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                duration: 300.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    return BlocConsumer<AssignmentMonitoringCubit, AssignmentMonitoringState>(
      listener: (context, state) {
        if (state is AssignmentMonitoringInitial &&
            _selectedSessionYear != null) {
          _fetchAssignmentMonitoring();
        }
      },
      builder: (context, state) {
        if (state is AssignmentMonitoringLoading) {
          return _buildAssignmentMonitoringSkeleton();
        } else if (state is AssignmentMonitoringFailure) {
          return CustomErrorWidget(
            message: state.errorMessage,
            onRetry: () {
              _fetchAssignmentMonitoring();
            },
            primaryColor: maroonPrimary,
          );
        } else if (state is AssignmentMonitoringSuccess) {
          final data = state.monitoringData;

          if (data.rows.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // Show statistics
              _buildStatisticsCard(data.total),

              // Data table
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            maroonPrimary.withValues(alpha: 0.95),
                            maroonLight.withValues(alpha: 0.95),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: maroonPrimary.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              'No',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Nama Guru',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Total Tugas',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.1, end: 0),

                    // Table body
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: data.rows.length,
                        itemBuilder: (context, index) {
                          final item = data.rows[index];
                          // Calculate delay based on index for staggered animation
                          final animationDelay = (index * 50).clamp(0, 500);

                          return Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  // Light feedback when tapping the row
                                  HapticFeedback.selectionClick();

                                  // Navigate to teacher assignment detail screen
                                  Get.toNamed(
                                    Routes.assignmentDetailMonitoringScreen,
                                    arguments: {
                                      'teacherId': item.id,
                                      'teacherName': item.teacherName,
                                    },
                                  );
                                },
                                splashColor: Colors.grey.withValues(alpha: 0.1),
                                highlightColor:
                                    Colors.grey.withValues(alpha: 0.05),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  child: Row(
                                    children: [
                                      // Number column with fixed width
                                      Container(
                                        width: 32,
                                        alignment: Alignment.center,
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: maroonPrimary.withValues(
                                                alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            item.no.toString(),
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: maroonPrimary,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 8), // Name column
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          (item.teacher?.firstName != null &&
                                                  item.teacher!.firstName!
                                                      .isNotEmpty)
                                              ? item.teacher!.firstName!
                                              : item.teacherName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),

                                      // Total assignments column with chevron
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            // Assignment count pill
                                            Expanded(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      maroonPrimary,
                                                      maroonLight
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                  border: Border.all(
                                                    color: maroonPrimary
                                                        .withValues(alpha: 0.3),
                                                    width: 1,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: maroonPrimary
                                                          .withValues(
                                                              alpha: 0.2),
                                                      blurRadius: 4,
                                                      offset:
                                                          const Offset(0, 2),
                                                      spreadRadius: 0,
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  item.totalAssignments
                                                      .toString(),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),

                                            // Chevron icon
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  left: 8),
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: maroonPrimary.withValues(
                                                    alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: 18,
                                                color: maroonPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(
                                  duration: 400.ms,
                                  delay: Duration(milliseconds: animationDelay))
                              .slideX(
                                  begin: 0.05,
                                  end: 0,
                                  duration: 400.ms,
                                  delay: Duration(milliseconds: animationDelay),
                                  curve: Curves.easeOutQuad);
                        },
                      ),
                    ),

                    // Pagination
                    if (state.totalPages > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 24.0, horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Previous button
                            ElevatedButton(
                              onPressed: state.currentPage > 1
                                  ? () {
                                      setState(() {
                                        _currentPage--;
                                      });
                                      _fetchAssignmentMonitoring();
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: state.currentPage > 1
                                    ? maroonPrimary.withValues(alpha: 0.9)
                                    : Colors.grey.withValues(alpha: 0.2),
                                foregroundColor: Colors.white,
                                elevation: state.currentPage > 1 ? 2 : 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.horizontal(
                                    left: Radius.circular(20),
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.chevron_left, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Prev',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Page indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.symmetric(
                                  horizontal: BorderSide(
                                      color:
                                          maroonPrimary.withValues(alpha: 0.1),
                                      width: 1),
                                  vertical: BorderSide(
                                      color:
                                          maroonPrimary.withValues(alpha: 0.1),
                                      width: 1),
                                ),
                              ),
                              child: Text(
                                '${state.currentPage} / ${state.totalPages}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textDarkColor,
                                ),
                              ),
                            ),

                            // Next button
                            ElevatedButton(
                              onPressed: state.currentPage < state.totalPages
                                  ? () {
                                      setState(() {
                                        _currentPage++;
                                      });
                                      _fetchAssignmentMonitoring();
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    state.currentPage < state.totalPages
                                        ? maroonPrimary.withValues(alpha: 0.9)
                                        : Colors.grey.withValues(alpha: 0.2),
                                foregroundColor: Colors.white,
                                elevation: state.currentPage < state.totalPages
                                    ? 2
                                    : 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.horizontal(
                                    right: Radius.circular(20),
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Next',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, size: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 600.ms),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms).scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.0, 1.0),
                  duration: 500.ms)
            ],
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildStatisticsCardSkeleton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: maroonPrimary.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with icon placeholder
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 140,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Summary content placeholder
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 80,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Progress bar placeholder
                        Container(
                          height: 8,
                          width: double.infinity,
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

            // Additional info section placeholder
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
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
                  Expanded(
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentRowSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              // Number column placeholder
              Container(
                width: 32,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(width: 8),

              // Name column placeholder
              Expanded(
                flex: 3,
                child: Container(
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Total assignments column placeholder
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 32,
                      height: 32,
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
      ),
    );
  }

  Widget _buildAssignmentMonitoringSkeleton() {
    return Column(
      children: [
        // Statistics card skeleton
        _buildStatisticsCardSkeleton(),

        // Data table skeleton
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Table header (static, no skeleton needed)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      maroonPrimary.withValues(alpha: 0.95),
                      maroonLight.withValues(alpha: 0.95),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: maroonPrimary.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        'No',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Nama Guru',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Total Tugas',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ],
                ),
              ),

              // Table body skeleton
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 8, // Show 8 skeleton rows
                  itemBuilder: (context, index) {
                    return _buildAssignmentRowSkeleton();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
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
        appBar: _buildHeaderSection(),
        body: BlocConsumer<SessionYearsCubit, SessionYearsState>(
          listener: (context, state) {
            if (state is SessionYearsFetchSuccess) {
              // Set default session year
              if (_selectedSessionYear == null &&
                  state.sessionYears.isNotEmpty) {
                setState(() {
                  _selectedSessionYear = state.sessionYears.first;
                });
                _fetchAssignmentMonitoring();
              }
            }
          },
          builder: (context, state) {
            if (state is SessionYearsFetchInProgress) {
              return SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: _buildAssignmentMonitoringSkeleton(),
              );
            }
            if (state is SessionYearsFetchFailure) {
              return CustomErrorWidget(
                message: state.errorMessage,
                onRetry: () {
                  context.read<SessionYearsCubit>().getSessionYears();
                },
                primaryColor: maroonPrimary,
              );
            }

            return SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: _buildDataTable(),
            );
          },
        ),
      ),
    );
  }
}
