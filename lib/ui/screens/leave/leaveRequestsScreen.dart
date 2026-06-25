// filepath: d:\UBIG\eSchool\eschool_saas_staff\lib\ui\screens\leaveRequestsScreen.dart
import 'package:eschool_saas_staff/cubits/leave/approveOrRejectLeaveRequestCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/leave/approveOrRejectStudentLeaveRequestCubit.dart';
import 'package:eschool_saas_staff/cubits/leave/leaveRequestsCubit.dart';
import 'package:eschool_saas_staff/cubits/leave/studentLeaveRequestsCubit.dart';
import 'package:eschool_saas_staff/data/models/leave/leaveRequest.dart';
import 'package:eschool_saas_staff/data/models/academic/studyMaterial.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/homeContainer/homeContainer.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/studyMaterialContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customRoundedButton.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/leave/rejectReasonDialog.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/profileImageContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

/// Safely parse date string with multiple format support
DateTime? _safeParseDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return null;

  try {
    // Try standard ISO format first
    return DateTime.parse(dateString);
  } catch (e) {
    try {
      // Try dd-MM-yyyy format (common in Indonesian systems)
      if (dateString.contains('-') && dateString.length == 10) {
        final parts = dateString.split('-');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }
      // Try dd/MM/yyyy format
      if (dateString.contains('/') && dateString.length == 10) {
        final parts = dateString.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }
    } catch (parseError) {
      debugPrint('Error parsing date: $dateString - $parseError');
    }
    return null;
  }
}

class LeaveRequestsScreen extends StatefulWidget {
  const LeaveRequestsScreen({super.key});

  static Widget getRouteInstance() => const LeaveRequestsScreen();

  @override
  State<LeaveRequestsScreen> createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends State<LeaveRequestsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late AnimationController _slideAnimationController;
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  // Fresh Soft Maroon Palette - Consistent with allowancesAndDeductionsScreen
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  final Color _maroonLight = const Color(0xFFA6677A);
  final Color _neutralBg = const Color(0xFFFBFAFA);
  final Color _cardBg = const Color(0xFFFFFFFF);

  /// Safely parse date string with multiple format support
  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    try {
      // Try standard ISO format first
      return DateTime.parse(dateString);
    } catch (e) {
      try {
        // Try dd-MM-yyyy format (common in Indonesian systems)
        if (dateString.contains('-') && dateString.length == 10) {
          final parts = dateString.split('-');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
        }
        // Try dd/MM/yyyy format
        if (dateString.contains('/') && dateString.length == 10) {
          final parts = dateString.split('/');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
        }
      } catch (parseError) {
        debugPrint('Error parsing date: $dateString - $parseError');
      }
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Start animations
    _slideAnimationController.forward();
    _fabAnimationController.repeat(reverse: true);

    // Note: Leave requests are now fetched when BlocProvider is created
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _slideAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void rejectOrApproveLeave(
      {required LeaveRequest leaveRequest,
      required bool approveLeave,
      required bool isStaffLeave}) {
    if (!approveLeave) {
      // Tampilkan dialog untuk input alasan penolakan
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => RejectReasonDialog(
          onReject: (String rejectReason) {
            Navigator.of(context).pop(); // Tutup dialog
            // Tampilkan bottomsheet dengan alasan penolakan
            _showApprovalBottomsheet(
              leaveRequest: leaveRequest,
              approveLeave: false,
              rejectReason: rejectReason,
              isStaffLeave: isStaffLeave,
            );
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      );
    } else {
      // Untuk approval, langsung tampilkan bottomsheet
      _showApprovalBottomsheet(
        leaveRequest: leaveRequest,
        approveLeave: true,
        isStaffLeave: isStaffLeave,
      );
    }
  }

  void _showApprovalBottomsheet({
    required LeaveRequest leaveRequest,
    required bool approveLeave,
    String? rejectReason,
    required bool isStaffLeave,
  }) {
    Utils.showBottomSheet(
            child: isStaffLeave
                ? BlocProvider<ApproveOrRejectLeaveRequestCubit>(
                    create: (context) => ApproveOrRejectLeaveRequestCubit(),
                    child: LeaveRequestDetailsBottomsheet(
                      approveLeave: approveLeave,
                      leaveRequest: leaveRequest,
                      rejectReason: rejectReason,
                      isStaffLeave: isStaffLeave,
                    ),
                  )
                : BlocProvider<ApproveOrRejectStudentLeaveRequestCubit>(
                    create: (context) =>
                        ApproveOrRejectStudentLeaveRequestCubit(),
                    child: LeaveRequestDetailsBottomsheet(
                      approveLeave: approveLeave,
                      leaveRequest: leaveRequest,
                      rejectReason: rejectReason,
                      isStaffLeave: isStaffLeave,
                    ),
                  ),
            context: context)
        .then((value) {
      final refreshLeaveRequests = (value as bool?) ?? false;
      if (refreshLeaveRequests) {
        if (mounted) {
          if (isStaffLeave) {
            context.read<LeaveRequestsCubit>().getLeaveRequests();
          } else {
            context.read<StudentLeaveRequestsCubit>().getStudentLeaveRequests();
          }
        }
      }
    });
  }

  Widget _buildFloatingTabBar() {
    return AnimatedBuilder(
      animation: _slideAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              0,
              Tween<double>(
                begin: -50.0,
                end: 0.0,
              )
                  .animate(CurvedAnimation(
                    parent: _slideAnimationController,
                    curve: Curves.elasticOut,
                  ))
                  .value),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: _maroonPrimary.withValues(alpha: 0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    title: 'Cuti Staff',
                    icon: Icons.person,
                    isSelected: _currentPageIndex == 0,
                    onTap: () => _switchTab(0),
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    title: 'Izin Siswa',
                    icon: Icons.school,
                    isSelected: _currentPageIndex == 1,
                    onTap: () => _switchTab(1),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? _maroonPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : _maroonPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : _maroonPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _switchTab(int index) {
    setState(() {
      _currentPageIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Modern card with soft shadows for leave request details
  Widget _buildLeaveRequestDetails(
      {required LeaveRequest leaveRequest, required bool isStaffLeave}) {
    final titleTextStyle = TextStyle(
        fontSize: Utils.getScaledValue(context, 13),
        fontFamily: GoogleFonts.poppins().fontFamily,
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.75));

    final dateTextStyle = TextStyle(
        fontSize: Utils.getScaledValue(context, 14),
        fontFamily: GoogleFonts.poppins().fontFamily,
        fontWeight: FontWeight.w600);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _maroonPrimary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Decorative accent element - left side gradient
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 8,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _maroonPrimary,
                      _maroonLight,
                    ],
                  ),
                ),
              ),
            ),

            // Decorative accent circle
            Positioned(
              right: -15,
              top: -15,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _maroonPrimary.withValues(alpha: 0.05),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: EdgeInsets.all(appContentHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with user info and days count
                  Row(
                    children: [
                      // User profile image with animated border
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  _maroonPrimary.withValues(alpha: 0.2),
                                  _maroonPrimary.withValues(alpha: 0.6),
                                  _maroonPrimary,
                                  _maroonLight,
                                  _maroonPrimary.withValues(alpha: 0.2),
                                ],
                              ),
                            ),
                          )
                              .animate(
                                  onPlay: (controller) => controller.repeat())
                              .rotate(
                                  duration: const Duration(seconds: 3),
                                  curve: Curves.linear),
                          Container(
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(23),
                              child: ProfileImageContainer(
                                imageUrl: leaveRequest.user?.image ?? "",
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 12),

                      // User name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomTextContainer(
                              textKey: leaveRequest.user?.fullName ??
                                  (leaveRequest.user?.firstName != null &&
                                          leaveRequest.user?.lastName != null
                                      ? "${leaveRequest.user?.firstName} ${leaveRequest.user?.lastName}"
                                      : leaveRequest.user?.firstName ??
                                          (leaveRequest.userId != null
                                              ? "Siswa ID: ${leaveRequest.userId}"
                                              : "Nama tidak tersedia")),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: Utils.getScaledValue(context, 16),
                                fontFamily: GoogleFonts.poppins().fontFamily,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Leave days count
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: _maroonPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CustomTextContainer(
                              textKey: (leaveRequest.leaveDetail?.length ?? 1)
                                  .toString(),
                              style: TextStyle(
                                color: _maroonPrimary,
                                fontFamily: GoogleFonts.poppins().fontFamily,
                                fontSize: Utils.getScaledValue(context, 20),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          CustomTextContainer(
                            textKey: totalKey,
                            style: TextStyle(
                              fontSize: Utils.getScaledValue(context, 13),
                              fontFamily: GoogleFonts.poppins().fontFamily,
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withValues(alpha: 0.76),
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(
                              delay: const Duration(milliseconds: 300),
                              duration: const Duration(milliseconds: 500))
                          .slideY(begin: 0.2, end: 0),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 400))
                      .slideX(begin: -0.1, end: 0),

                  const SizedBox(height: 16),

                  // Divider with gradient effect
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          _maroonLight.withValues(alpha: 0.3),
                          _maroonPrimary.withValues(alpha: 0.5),
                          _maroonLight.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Date information with modern design
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _maroonPrimary.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _maroonPrimary.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextContainer(
                                textKey: fromDateKey,
                                style: titleTextStyle.copyWith(
                                  color: _maroonPrimary.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              CustomTextContainer(
                                textKey:
                                    _parseDate(leaveRequest.fromDate) != null
                                        ? Utils.formatDate(
                                            _parseDate(leaveRequest.fromDate)!)
                                        : (leaveRequest.fromDate ??
                                            "Tanggal tidak tersedia"),
                                style: dateTextStyle,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _maroonPrimary.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _maroonPrimary.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CustomTextContainer(
                                textKey: toDateKey,
                                style: titleTextStyle.copyWith(
                                  color: _maroonPrimary.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              CustomTextContainer(
                                textKey: _parseDate(leaveRequest.toDate) != null
                                    ? Utils.formatDate(
                                        _parseDate(leaveRequest.toDate)!)
                                    : (leaveRequest.toDate ??
                                        "Tanggal tidak tersedia"),
                                style: dateTextStyle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(
                          delay: const Duration(milliseconds: 100),
                          duration: const Duration(milliseconds: 400))
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 16),

                  // Reason section with elegant styling
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _maroonPrimary.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _maroonPrimary.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextContainer(
                          textKey: leaveReasonKey,
                          style: titleTextStyle.copyWith(
                            color: _maroonPrimary.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        CustomTextContainer(
                          textKey: leaveRequest.reason ?? "",
                          style: dateTextStyle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(
                          delay: const Duration(milliseconds: 200),
                          duration: const Duration(milliseconds: 400))
                      .slideY(begin: 0.2, end: 0),

                  // Tampilkan alasan penolakan jika status = rejected dan ada reject_reason
                  if (leaveRequest.status == 2 &&
                      leaveRequest.rejectReason != null &&
                      leaveRequest.rejectReason!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.red[700],
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Alasan Penolakan",
                                  style: titleTextStyle.copyWith(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            CustomTextContainer(
                              textKey: leaveRequest.rejectReason ?? "",
                              style: dateTextStyle.copyWith(
                                color: Colors.red[800],
                              ),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(
                            delay: const Duration(milliseconds: 250),
                            duration: const Duration(milliseconds: 400))
                        .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 20),

                  // Action buttons with improved styling
                  LayoutBuilder(
                    builder: (context, boxConstraints) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Reject button with elegant styling
                          SizedBox(
                            width: boxConstraints.maxWidth * 0.48,
                            child: CustomRoundedButton(
                              radius: 12,
                              height: 45,
                              widthPercentage: 1.0,
                              backgroundColor: Colors.white,
                              buttonTitle: rejectKey,
                              borderColor: _maroonPrimary,
                              titleColor: _maroonPrimary,
                              showBorder: true,
                              onTap: () {
                                rejectOrApproveLeave(
                                  leaveRequest: leaveRequest,
                                  approveLeave: false,
                                  isStaffLeave: isStaffLeave,
                                );
                              },
                            ),
                          ),

                          // Approve button with elegant styling
                          SizedBox(
                            width: boxConstraints.maxWidth * 0.48,
                            child: CustomRoundedButton(
                              radius: 12,
                              height: 45,
                              widthPercentage: 1.0,
                              backgroundColor: _maroonPrimary,
                              buttonTitle: approveKey,
                              showBorder: false,
                              onTap: () {
                                rejectOrApproveLeave(
                                  leaveRequest: leaveRequest,
                                  approveLeave: true,
                                  isStaffLeave: isStaffLeave,
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  )
                      .animate()
                      .fadeIn(
                          delay: const Duration(milliseconds: 300),
                          duration: const Duration(milliseconds: 400))
                      .slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 500))
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _neutralBg,
      extendBodyBehindAppBar: false,
      body: Stack(
        children: [
          // Subtle background pattern for visual interest
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Image.network(
                'https://www.transparenttextures.com/patterns/cubes.png',
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),

          // Main content
          Column(
            children: [
              // Modern App Bar
              CustomModernAppBar(
                title: leaveRequestKey.tr,
                icon: Icons.pending_actions_rounded,
                fabAnimationController: _fabAnimationController,
                primaryColor: _maroonPrimary,
                lightColor: _maroonLight,
                onBackPressed: () => Navigator.of(context).pop(),
              ),

              // Floating Tab Bar
              Container(
                margin: const EdgeInsets.only(top: 0),
                child: _buildFloatingTabBar(),
              ),

              // Page Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index;
                    });
                  },
                  children: [
                    // Staff Leave Tab
                    BlocProvider(
                      create: (context) {
                        final cubit = LeaveRequestsCubit();
                        // Fetch leave requests when cubit is created
                        Future.microtask(() => cubit.getLeaveRequests());
                        return cubit;
                      },
                      child: _buildLeaveRequestsTab(isStaffLeave: true),
                    ),

                    // Student Leave Tab
                    BlocProvider(
                      create: (context) {
                        final cubit = StudentLeaveRequestsCubit();
                        // Fetch student leave requests when cubit is created
                        Future.microtask(() => cubit.getStudentLeaveRequests());
                        return cubit;
                      },
                      child: _buildLeaveRequestsTab(isStaffLeave: false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveRequestsTab({required bool isStaffLeave}) {
    if (isStaffLeave) {
      return BlocConsumer<LeaveRequestsCubit, LeaveRequestsState>(
        listener: (context, state) {
          if (state is LeaveRequestsFetchSuccess) {
            HomeContainer.widgetKey.currentState?.updateLeaveRequestCount(
                totalLeaveRequests: state.leaveRequests.length);
          }
        },
        builder: (context, state) {
          if (state is LeaveRequestsFetchSuccess) {
            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                    left: appContentHorizontalPadding,
                    right: appContentHorizontalPadding,
                    top: 20,
                    bottom: 30),
                child: Column(
                  children: [
                    // Animated intro text
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: _maroonPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Permintaan Cuti Staff",
                            style: TextStyle(
                              fontFamily: GoogleFonts.poppins().fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _maroonPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${state.leaveRequests.length} Permintaan",
                              style: TextStyle(
                                fontFamily: GoogleFonts.poppins().fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _maroonPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: const Duration(milliseconds: 400))
                        .slideY(begin: -0.2, end: 0),

                    // Leave request cards
                    ...state.leaveRequests
                        .map((leaveRequest) => _buildLeaveRequestDetails(
                            leaveRequest: leaveRequest, isStaffLeave: true))
                        ,
                  ],
                ),
              ),
            );
          }
          if (state is LeaveRequestsFetchFailure) {
            return Center(
              child: CustomErrorWidget(
                message: state.errorMessage,
                onRetry: () {
                  context.read<LeaveRequestsCubit>().getLeaveRequests();
                },
                primaryColor: _maroonPrimary,
              ),
            ).animate().fadeIn(duration: const Duration(milliseconds: 400));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(5, (index) {
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

                          // Leave details
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
                                // Date range
                                Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      height: 14,
                                      width: 150,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Reason
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 14,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            height: 14,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.6,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 80,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 80,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
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
          ).animate().fadeIn(duration: const Duration(milliseconds: 400));
        },
      );
    } else {
      // Student Leave Tab
      return BlocConsumer<StudentLeaveRequestsCubit, StudentLeaveRequestsState>(
        listener: (context, state) {
          // Handle student leave state changes if needed
        },
        builder: (context, state) {
          if (state is StudentLeaveRequestsFetchSuccess) {
            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                    left: appContentHorizontalPadding,
                    right: appContentHorizontalPadding,
                    top: 20,
                    bottom: 30),
                child: Column(
                  children: [
                    // Animated intro text
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.school,
                            color: _maroonPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Permintaan Izin Siswa",
                            style: TextStyle(
                              fontFamily: GoogleFonts.poppins().fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _maroonPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${state.leaveRequests.length} Permintaan",
                              style: TextStyle(
                                fontFamily: GoogleFonts.poppins().fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _maroonPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: const Duration(milliseconds: 400))
                        .slideY(begin: -0.2, end: 0),

                    // Leave request cards
                    ...state.leaveRequests
                        .map((leaveRequest) => _buildLeaveRequestDetails(
                            leaveRequest: leaveRequest, isStaffLeave: false))
                        ,
                  ],
                ),
              ),
            );
          }
          if (state is StudentLeaveRequestsFetchFailure) {
            return Center(
              child: CustomErrorWidget(
                message: state.errorMessage,
                onRetry: () {
                  context
                      .read<StudentLeaveRequestsCubit>()
                      .getStudentLeaveRequests();
                },
                primaryColor: _maroonPrimary,
              ),
            ).animate().fadeIn(duration: const Duration(milliseconds: 400));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(4, (index) {
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
                          // Header with student info and status
                          Row(
                            children: [
                              Container(
                                width: 45,
                                height: 45,
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
                                      width: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 75,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Student leave details
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
                                // Date range
                                Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      height: 14,
                                      width: 140,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Reason
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 14,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            height: 14,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.5,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 70,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 70,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
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
          ).animate().fadeIn(duration: const Duration(milliseconds: 400));
        },
      );
    }
  }
}

class LeaveRequestDetailsBottomsheet extends StatelessWidget {
  final bool approveLeave;
  final LeaveRequest leaveRequest;
  final String? rejectReason;
  final bool isStaffLeave;

  const LeaveRequestDetailsBottomsheet({
    super.key,
    required this.approveLeave,
    required this.leaveRequest,
    this.rejectReason,
    required this.isStaffLeave,
  });

  // Fungsi untuk menerjemahkan tipe cuti
  String translateLeaveType(String? type) {
    if (type == null) return "";

    switch (type) {
      case "Full":
        return "Sehari Penuh";
      case "First Half":
        return "Paruh Pertama";
      case "Second Half":
        return "Paruh Kedua";
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAttachments = leaveRequest.attachments?.isNotEmpty ?? false;
    final maroonPrimary = AppColorPalette.primaryMaroon;

    return CustomBottomsheet(
        titleLabelKey: leaveDetailsKey,
        child: Column(
          children: [
            // Enhanced list with better visual styling
            ...leaveRequest.leaveDetail
                    ?.map((leaveDetail) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: maroonPrimary.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: maroonPrimary.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: maroonPrimary.withValues(alpha: 0.1),
                              ),
                              child: Center(
                                child: Text(
                                  _safeParseDate(leaveDetail.date)
                                          ?.day
                                          .toString() ??
                                      "?",
                                  style: TextStyle(
                                    fontFamily:
                                        GoogleFonts.poppins().fontFamily,
                                    fontWeight: FontWeight.bold,
                                    color: maroonPrimary,
                                  ),
                                ),
                              ),
                            ),
                            title: CustomTextContainer(
                                textKey: _safeParseDate(leaveDetail.date) !=
                                        null
                                    ? "${Utils.formatDate(_safeParseDate(leaveDetail.date)!)}, ${Utils.weekDays[_safeParseDate(leaveDetail.date)!.weekday - 1].tr}"
                                    : "${leaveDetail.date ?? 'Tanggal tidak tersedia'}, -"),
                            subtitle: CustomTextContainer(
                                textKey: translateLeaveType(leaveDetail.type)),
                          ),
                        ).animate().fadeIn(
                            duration: const Duration(milliseconds: 300),
                            delay: Duration(
                                milliseconds: 100 *
                                    (leaveRequest.leaveDetail!
                                        .indexOf(leaveDetail)))))
                    .toList() ??
                [],
            const SizedBox(
              height: 25.0,
            ),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: appContentHorizontalPadding),
              child: LayoutBuilder(builder: (context, boxConstraints) {
                return Row(
                  children: [
                    hasAttachments
                        ? SizedBox(
                            width: boxConstraints.maxWidth * 0.475,
                            child: CustomRoundedButton(
                                radius: 12,
                                height: 45,
                                widthPercentage: 1.0,
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                                buttonTitle: attachmentsKey,
                                titleColor: maroonPrimary,
                                borderColor: maroonPrimary,
                                showBorder: true,
                                onTap: () {
                                  Utils.showBottomSheet(
                                      child: LeaveAttachmentsBottomsheet(
                                          files: leaveRequest.attachments!),
                                      context: context);
                                }),
                          )
                        : const SizedBox(),
                    hasAttachments ? const Spacer() : const SizedBox(),
                    isStaffLeave
                        ? BlocConsumer<ApproveOrRejectLeaveRequestCubit,
                            ApproveOrRejectLeaveRequestState>(
                            listener: (context, state) {
                              if (state is ApproveOrRejectLeaveRequestSuccess) {
                                Get.back(result: true);
                                Get.snackbar(
                                  'Sukses',
                                  approveLeave
                                      ? 'Cuti berhasil disetujui.'
                                      : 'Cuti berhasil ditolak.',
                                  backgroundColor: approveLeave
                                      ? Colors.green[50]
                                      : Colors.red[50],
                                  colorText: approveLeave
                                      ? Colors.green[900]
                                      : Colors.red[900],
                                );
                              } else if (state
                                  is ApproveOrRejectLeaveRequestFailure) {
                                Utils.showSnackBar(
                                    message: state.errorMessage,
                                    context: context);
                              }
                            },
                            builder: (context, state) {
                              return _buildApprovalButton(
                                  context,
                                  state,
                                  leaveRequest,
                                  approveLeave,
                                  rejectReason,
                                  isStaffLeave,
                                  boxConstraints,
                                  hasAttachments);
                            },
                          )
                        : BlocConsumer<ApproveOrRejectStudentLeaveRequestCubit,
                            ApproveOrRejectStudentLeaveRequestState>(
                            listener: (context, state) {
                              if (state
                                  is ApproveOrRejectStudentLeaveRequestSuccess) {
                                Get.back(result: true);
                                Get.snackbar(
                                  'Sukses',
                                  approveLeave
                                      ? 'Izin siswa berhasil disetujui.'
                                      : 'Izin siswa berhasil ditolak.',
                                  backgroundColor: approveLeave
                                      ? Colors.green[50]
                                      : Colors.red[50],
                                  colorText: approveLeave
                                      ? Colors.green[900]
                                      : Colors.red[900],
                                );
                              } else if (state
                                  is ApproveOrRejectStudentLeaveRequestFailure) {
                                Utils.showSnackBar(
                                    message: state.errorMessage,
                                    context: context);
                              }
                            },
                            builder: (context, state) {
                              return _buildApprovalButton(
                                  context,
                                  state,
                                  leaveRequest,
                                  approveLeave,
                                  rejectReason,
                                  isStaffLeave,
                                  boxConstraints,
                                  hasAttachments);
                            },
                          ),
                  ],
                );
              }),
            )
          ],
        ));
  }

  Widget _buildApprovalButton(
      BuildContext context,
      dynamic state,
      LeaveRequest leaveRequest,
      bool approveLeave,
      String? rejectReason,
      bool isStaffLeave,
      BoxConstraints boxConstraints,
      bool hasAttachments) {
    final maroonPrimary = AppColorPalette.primaryMaroon;
    final bool isInProgress =
        (isStaffLeave && state is ApproveOrRejectLeaveRequestInProgress) ||
            (!isStaffLeave &&
                state is ApproveOrRejectStudentLeaveRequestInProgress);

    return PopScope(
      canPop: !isInProgress,
      child: SizedBox(
        width: boxConstraints.maxWidth * (hasAttachments ? 0.475 : 1.0),
        child: CustomRoundedButton(
          radius: 12,
          height: 45,
          widthPercentage: 1.0,
          backgroundColor: maroonPrimary,
          buttonTitle: approveLeave ? approveKey : rejectKey,
          showBorder: false,
          child: isInProgress
              ? const CircularProgressIndicator(color: Colors.white)
              : null,
          onTap: () {
            if (isInProgress) {
              return;
            }
            if (isStaffLeave) {
              context
                  .read<ApproveOrRejectLeaveRequestCubit>()
                  .approveOrRejectLeaveRequest(
                      leaveRequestId: leaveRequest.id ?? 0,
                      approveLeave: approveLeave,
                      rejectReason: rejectReason);
            } else {
              context
                  .read<ApproveOrRejectStudentLeaveRequestCubit>()
                  .approveOrRejectStudentLeaveRequest(
                      leaveRequestId: leaveRequest.id ?? 0,
                      approveLeave: approveLeave,
                      rejectReason: rejectReason);
            }
          },
        ),
      ),
    );
  }
}

class LeaveAttachmentsBottomsheet extends StatelessWidget {
  final List<StudyMaterial> files;
  const LeaveAttachmentsBottomsheet({super.key, required this.files});

  @override
  Widget build(BuildContext context) {
    return CustomBottomsheet(
        titleLabelKey: viewAttachmentsKey,
        child: Column(
          children: files
              .map((file) => Padding(
                    padding: EdgeInsets.all(appContentHorizontalPadding),
                    child: StudyMaterialContainer(
                        studyMaterial: file, showEditAndDeleteButton: false),
                  ).animate().fadeIn(
                      duration: const Duration(milliseconds: 200),
                      delay: const Duration(milliseconds: 100)))
              .toList(),
        ));
  }
}
