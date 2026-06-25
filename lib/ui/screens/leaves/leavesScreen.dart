import 'package:eschool_saas_staff/cubits/academics/sessionYearsCubit.dart';
import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/leave/userLeavesCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/sessionYear.dart';
import 'package:eschool_saas_staff/data/models/auth/userDetails.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customFilterModernAppbar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:eschool_saas_staff/utils/system/errorMessageUtils.dart';

class LeavesScreen extends StatefulWidget {
  final bool showMyLeaves;
  final UserDetails? userDetails;
  const LeavesScreen({super.key, required this.showMyLeaves, this.userDetails});

  static Widget getRouteInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SessionYearsCubit(),
        ),
        BlocProvider(
          create: (context) => UserLeavesCubit(),
        ),
      ],
      child: LeavesScreen(
        userDetails: arguments['userDetails'],
        showMyLeaves: arguments['showMyLeaves'],
      ),
    );
  }

  static Map<String, dynamic> buildArguments(
      {required bool showMyLeaves, UserDetails? userDetails}) {
    return {"showMyLeaves": showMyLeaves, "userDetails": userDetails};
  }

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen>
    with TickerProviderStateMixin {
  SessionYear? _selectedSessionYear;
  late String _selectedMonthKey;
  final ScrollController _scrollController = ScrollController();

  // Animation controllers
  late final AnimationController _animationController;

  // Additional animations for enhanced visuals
  late final AnimationController _cardAnimationController;

  // Define theme colors - modern palette
  static Color get maroonPrimary => AppColorPalette.primaryMaroon;
  static Color get maroonLight => AppColorPalette.secondaryMaroon;
  static Color get bgColor => AppColorPalette.warmBeige;
  final Color cardColor = Colors.white;
  static const Color textDarkColor = Color(0xFF2D2D2D);
  static const Color textMediumColor = Color(0xFF717171);
  static const Color borderColor = Color(0xFFEFE2E5);

  // Additional modern UI colors
  static const Color shadowColor = Color(0x29000000);

  DateTime _parseDate(String dateStr) {
    try {
      // Handle both DD-MM-YYYY and YYYY-MM-DD formats
      List<String> parts = dateStr.split('-');
      if (parts.length == 3) {
        int first = int.parse(parts[0]);
        int second = int.parse(parts[1]);
        int third = int.parse(parts[2]);

        // If first part is year (4 digits), assume YYYY-MM-DD
        if (first > 31) {
          return DateTime(first, second, third);
        } else {
          // Assume DD-MM-YYYY
          return DateTime(third, second, first);
        }
      }
    } catch (e) {
      debugPrint('Error parsing date: $dateStr, error: $e');
    }
    throw FormatException('Invalid date format: $dateStr');
  }

  @override
  void initState() {
    super.initState();

    // Primary animation controller for fade effects
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Card animations controller for more dynamic UI elements
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Start animations
    _animationController.forward();
    _cardAnimationController.forward();

    // Set default month to current month using the key
    _selectedMonthKey = months[DateTime.now().month - 1];

    // Initialize data loading pipeline
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Get session years first
        context.read<SessionYearsCubit>().getSessionYears();
        // The BlocConsumer in build method will handle selecting the default session year
        // and triggering the leaves data fetch after session years are available
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void changeSelectedSessionYear(SessionYear sessionYear) {
    HapticFeedback.lightImpact();
    _selectedSessionYear = sessionYear;
    setState(() {});
    getLeaves();
  }

  void changeSelectedMonth(String month) {
    HapticFeedback.lightImpact();
    _selectedMonthKey = month;
    setState(() {});
    getLeaves();
  }

  int getSelectedMonthNumber() {
    // Map English month keys to their numeric values
    final Map<String, int> monthMap = {
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'may': 5,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
    };

    return monthMap[_selectedMonthKey] ??
        DateTime.now().month; // Return current month as fallback
  }

  void getLeaves() {
    debugPrint("=== Fetching leaves data ===");
    debugPrint("Month: $_selectedMonthKey (${getSelectedMonthNumber()})");
    debugPrint(
        "Session Year: ${_selectedSessionYear?.name ?? 'Not selected'} (ID: ${_selectedSessionYear?.id ?? 0})");
    debugPrint(
        "User ID: ${widget.showMyLeaves ? (context.read<AuthCubit>().getUserDetails().id ?? 0) : (widget.userDetails?.id ?? 0)}");
    debugPrint("===============================");

    context.read<UserLeavesCubit>().getUserLeaves(
        monthNumber: getSelectedMonthNumber(),
        userId: widget.showMyLeaves
            ? (context.read<AuthCubit>().getUserDetails().id ?? 0)
            : (widget.userDetails?.id ?? 0),
        sessionYearId: (_selectedSessionYear?.id ?? 0));
  }

  Widget _buildLeaveCountContainer(
      {required double width, required String title, required String value}) {
    return Container(
      width: width,
      height: Utils().getResponsiveHeight(context, 120),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: title == allowedLeavesKey
              ? maroonPrimary.withValues(alpha: 0.1)
              : maroonLight.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: title == allowedLeavesKey
                  ? maroonPrimary.withValues(alpha: 0.08)
                  : maroonLight.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // No icon neede
                const SizedBox(width: 6),
                Text(
                  title.tr,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color:
                        title == allowedLeavesKey ? maroonPrimary : maroonLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 32,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: title == allowedLeavesKey
                          ? maroonPrimary
                          : maroonLight,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      "hari",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: textMediumColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: 0.7,
                  backgroundColor:
                      (title == allowedLeavesKey ? maroonPrimary : maroonLight)
                          .withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(
                    title == allowedLeavesKey ? maroonPrimary : maroonLight,
                  ),
                  minHeight: 3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveListContainer() {
    return BlocConsumer<UserLeavesCubit, UserLeavesState>(
      listener: (context, state) {
        if (state is UserLeavesInitial && _selectedSessionYear != null) {
          getLeaves();
        }
      },
      builder: (context, state) {
        if (state is UserLeavesFetchSuccess) {
          // Filter leaves by selected month
          final filteredLeaves = state.leaves.where((leave) {
            if (leave.leaveDetail != null && leave.leaveDetail!.isNotEmpty) {
              return leave.leaveDetail!.any((leaveDetail) {
                if (leaveDetail.date != null) {
                  try {
                    final leaveDate = DateTime.parse(leaveDetail.date!);
                    return leaveDate.month == getSelectedMonthNumber();
                  } catch (e) {
                    debugPrint(
                        'Error parsing leave detail date: ${leaveDetail.date}, error: $e');
                    return false;
                  }
                }
                return false;
              });
            }
            return false;
          }).toList();

          if (filteredLeaves.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: maroonPrimary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Tidak ada pengajuan cuti",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textMediumColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          double remainingLeaves = (state.monthlyAllowedLeaves -
              context
                  .read<UserLeavesCubit>()
                  .getTakenLeavesCount(monthNumber: getSelectedMonthNumber()));
          remainingLeaves = remainingLeaves < 0 ? 0 : remainingLeaves;

          return SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: maroonPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.event_note_rounded,
                              color: maroonPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Ringkasan Cuti",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: textDarkColor,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                Text(
                                  "Informasi jatah cuti bulan ini",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: textMediumColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(builder: (context, boxConstraints) {
                        return Row(
                          children: [
                            _buildLeaveCountContainer(
                              width: boxConstraints.maxWidth * 0.48,
                              title: allowedLeavesKey,
                              value:
                                  state.monthlyAllowedLeaves.toStringAsFixed(0),
                            ),
                            SizedBox(width: boxConstraints.maxWidth * 0.04),
                            _buildLeaveCountContainer(
                              width: boxConstraints.maxWidth * 0.48,
                              title: remainingLeavesKey,
                              value: remainingLeaves.toStringAsFixed(0),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

                // Leave History Section
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                        spreadRadius: 0,
                      )
                    ],
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: maroonPrimary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.list_alt_rounded,
                                color: maroonPrimary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Riwayat Pengajuan",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: textDarkColor,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                  Text(
                                    "${filteredLeaves.length} pengajuan",
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: textMediumColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: maroonPrimary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${filteredLeaves.length} Cuti",
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
                      const Divider(height: 1, color: borderColor),
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: filteredLeaves.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          color: borderColor,
                        ),
                        itemBuilder: (context, index) {
                          final leave = filteredLeaves[index];
                          return Container(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color:
                                        maroonPrimary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${index + 1}",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: maroonPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        leave.fromDate != null
                                            ? Utils.formatDate(
                                                _parseDate(leave.fromDate!))
                                            : '',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: textDarkColor,
                                        ),
                                      ),
                                      if (leave.fromDate != leave.toDate)
                                        Text(
                                          "s/d ${leave.toDate != null ? Utils.formatDate(_parseDate(leave.toDate!)) : ''}",
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            color: textMediumColor,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (state is UserLeavesFetchFailure) {
          return Center(
            child: CustomErrorWidget(
              message:
                  ErrorMessageUtils.getReadableErrorMessage(state.errorMessage),
              onRetry: () {
                getLeaves();
              },
              primaryColor: maroonPrimary,
            ),
          );
        }

        return const SkeletonLeavesCard();
      },
    );
  }

  PreferredSizeWidget _buildHeaderSection() {
    return CustomFilterModernAppBar(
      title: "Detail Cuti",
      titleIcon: Icons.event_available_rounded,
      primaryColor: maroonPrimary,
      secondaryColor: maroonLight,
      onBackPressed: () {
        Navigator.pop(context);
      },
      animationController: _animationController,
      enableAnimations: true,
      height: 190.0, // Increased height for better spacing
      firstFilterItem: FilterItemConfig(
        title: _selectedSessionYear?.name ?? "Tahun Ajaran",
        icon: Icons.calendar_today_rounded,
        onTap: () {
          if (context.read<SessionYearsCubit>().state
              is SessionYearsFetchSuccess) {
            final state = context.read<SessionYearsCubit>().state
                as SessionYearsFetchSuccess;
            if (state.sessionYears.isNotEmpty) {
              _showSessionYearFilter(context, state.sessionYears);
            }
          }
        },
      ),
      secondFilterItem: FilterItemConfig(
        title: _selectedMonthKey.tr,
        icon: Icons.date_range_rounded,
        onTap: () {
          _showMonthFilter(context);
        },
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: sessionYears.length,
                  itemBuilder: (context, index) {
                    final year = sessionYears[index];
                    return ListTile(
                      title: Text(year.name ?? ""),
                      trailing: _selectedSessionYear?.id == year.id
                          ? Icon(Icons.check_circle, color: maroonPrimary)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        changeSelectedSessionYear(year);
                      },
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

  void _showMonthFilter(BuildContext context) {
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
                  "Pilih Bulan",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: months.length,
                  itemBuilder: (context, index) {
                    final month = months[index];
                    return ListTile(
                      title: Text(month.tr),
                      trailing: _selectedMonthKey == month
                          ? Icon(Icons.check_circle, color: maroonPrimary)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        changeSelectedMonth(month);
                      },
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
              if (state.sessionYears.isNotEmpty &&
                  _selectedSessionYear == null) {
                // Automatically select default session year when data is first loaded
                final defaultYear = state.sessionYears.firstWhere(
                    (element) => element.isThisDefault(),
                    orElse: () => state.sessionYears.first);
                _selectedSessionYear = defaultYear;
                // Fetch leaves data once we have the session year
                getLeaves();
              }
            }
          },
          builder: (context, state) {
            if (state is SessionYearsFetchSuccess) {
              return _buildLeaveListContainer();
            }

            if (state is SessionYearsFetchFailure) {
              return Center(
                child: CustomErrorWidget(
                  message: ErrorMessageUtils.getReadableErrorMessage(
                      state.errorMessage),
                  onRetry: () {
                    context.read<SessionYearsCubit>().getSessionYears();
                  },
                  primaryColor: maroonPrimary,
                ),
              );
            }

            return const SkeletonLeavesCard();
          },
        ),
      ),
    );
  }
}
