import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/cubits/leave/approveOrRejectStudentPermissionCubit.dart';
import 'package:eschool_saas_staff/data/models/auth/permissionDetails.dart';
import 'package:eschool_saas_staff/ui/widgets/leave/rejectReasonDialog.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';

class PermissionDetailsContainer extends StatefulWidget {
  final PermissionDetails permissionDetails;
  final bool? overflow;
  final VoidCallback? onPermissionUpdated;

  const PermissionDetailsContainer({
    super.key,
    required this.permissionDetails,
    this.overflow,
    this.onPermissionUpdated,
  });

  @override
  State<PermissionDetailsContainer> createState() =>
      _PermissionDetailsContainerState();
}

class _PermissionDetailsContainerState extends State<PermissionDetailsContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isHovering = false;

  // Add cubit as class member to manage its lifecycle properly
  late ApproveOrRejectStudentPermissionCubit _approveRejectCubit;

  // Optimistic UI state
  int? _optimisticStatus;
  String? _optimisticRejectionReason;

  // Refined color palette - now dynamic based on theme
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  Color get _maroonLight => AppColorPalette.secondaryMaroon;
  Color get _maroonDark => _isDark ? Colors.white.withValues(alpha: 0.9) : _maroonPrimary.withValues(alpha: 0.85);
  Color get _maroonAccent => _maroonPrimary.withValues(alpha: 0.15);
  Color get _goldAccent => const Color(0xFFE6D2AA);

  Color get _surfaceColor => _isDark ? AppColorPalette.primaryMaroon : Colors.white;
  Color get _innerBgColor => _isDark ? AppColorPalette.lightMaroon : Colors.grey.shade50;
  Color get _innerBgWhiteColor => _isDark ? AppColorPalette.lightMaroon : Colors.white;
  Color get _borderColor => _isDark ? AppColorPalette.secondaryMaroon : Colors.grey.shade200;
  Color get _mainTextColor => _isDark ? Colors.white : Colors.black87;

  @override
  void initState() {
    super.initState();
    context.read<ClassesCubit>().getClasses();

    // Initialize the cubit
    _approveRejectCubit = ApproveOrRejectStudentPermissionCubit();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    // Load the current permission state
    if (safeLastLeave != null) {
      _optimisticStatus = safeLastLeave!.status;
    }

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuint,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(PermissionDetailsContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    debugPrint("DEBUG didUpdateWidget called");
    debugPrint("  - Old widget data: ${oldWidget.permissionDetails.hashCode}");
    debugPrint("  - New widget data: ${widget.permissionDetails.hashCode}");

    // If the permission data has been updated (e.g., after refresh),
    // update the optimistic status to match the new server data
    if (oldWidget.permissionDetails != widget.permissionDetails) {
      debugPrint("  - Permission data changed, checking status sync");
      final currentServerStatus = safeLastLeave?.status;
      debugPrint("  - Current server status: $currentServerStatus");
      debugPrint("  - Current optimistic status: $_optimisticStatus");

      if (currentServerStatus != null && _optimisticStatus != null) {
        // Only update if server status is different and not pending
        if (currentServerStatus != 0 &&
            currentServerStatus == _optimisticStatus) {
          debugPrint(
              "  - Server status matches optimistic, clearing optimistic state");
          // Server status now matches our optimistic status, clear optimistic state
          setState(() {
            _optimisticStatus = null;
            _optimisticRejectionReason = null;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    // Close the cubit when the widget is disposed
    _approveRejectCubit.close();
    super.dispose();
  }

  String getClassSectionName(int? classSectionId) {
    if (classSectionId == null) return '-';

    try {
      final classesCubit = context.read<ClassesCubit>();
      final allClasses = classesCubit.getAllClasses();

      // Check if allClasses is empty
      if (allClasses.isEmpty) {
        return '-';
      }

      // Use where().isNotEmpty to safely check if element exists
      final matchingClasses = allClasses.where(
        (classSection) => classSection.id == classSectionId,
      );

      if (matchingClasses.isNotEmpty) {
        return matchingClasses.first.name ?? 'Unknown Class';
      } else {
        return '-';
      }
    } catch (e) {
      debugPrint('Error in getClassSectionName: $e');
      return '-';
    }
  }

  String translateRole(String role) {
    final Map<String, String> roleTranslations = {
      "Teacher": "Guru",
    };
    return roleTranslations[role] ?? role;
  }

  Widget _buildLeaveTypeChip(String type) {
    Color backgroundColor;
    Color textColor;
    Color shadowColor;
    String translatedType;
    IconData iconData;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Set defaults based on type
    if (type.toLowerCase() == 'sick') {
      translatedType = 'Sakit';
      backgroundColor = isDark ? const Color(0xFF4A1212) : Colors.red.shade50;
      textColor = isDark ? Colors.red.shade300 : Colors.red.shade700;
      shadowColor = isDark ? Colors.transparent : Colors.red.shade200.withValues(alpha: 0.3);
      iconData = Icons.healing;
    } else {
      // Default to Leave or any other type
      translatedType = 'Izin';
      backgroundColor = isDark ? const Color(0xFF122C4A) : Colors.blue.shade50;
      textColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
      shadowColor = isDark ? Colors.transparent : Colors.blue.shade200.withValues(alpha: 0.3);
      iconData = Icons.event_busy;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: textColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: textColor, size: 18),
          const SizedBox(width: 8),
          Text(
            translatedType,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Commented out to prevent overflow in header
  // Widget _buildHeaderStatusBadge() {
  //   final lastLeave = safeLastLeave;
  //   if (lastLeave == null) return const SizedBox.shrink();

  //   // Get current status (use optimistic status if available)
  //   final int status = _optimisticStatus ?? lastLeave.status ?? 0;

  //   // Only show status badge if it's approved or rejected
  //   if (status == 0) return const SizedBox.shrink(); // Don't show for pending

  //   String statusText;
  //   Color statusColor;
  //   IconData statusIcon;

  //   switch (status) {
  //     case 1: // Approved
  //       statusText = "Disetujui";
  //       statusColor = Colors.green.shade600;
  //       statusIcon = Icons.check_circle_rounded;
  //       break;
  //     case 2: // Rejected
  //       statusText = "Ditolak";
  //       statusColor = Colors.red.shade600;
  //       statusIcon = Icons.cancel_rounded;
  //       break;
  //     default:
  //       return const SizedBox.shrink();
  //   }

  //   return AnimatedContainer(
  //     duration: const Duration(milliseconds: 300),
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     decoration: BoxDecoration(
  //       color: statusColor.withValues(alpha: 0.15),
  //       borderRadius: BorderRadius.circular(20),
  //       border: Border.all(
  //         color: statusColor.withValues(alpha: 0.4),
  //         width: 2,
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: statusColor.withValues(alpha: 0.3),
  //           blurRadius: 8,
  //           spreadRadius: 1,
  //           offset: const Offset(0, 3),
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Icon(
  //           statusIcon,
  //           color: statusColor,
  //           size: 18,
  //         ),
  //         const SizedBox(width: 6),
  //         Text(
  //           statusText,
  //           style: TextStyle(
  //             color: statusColor,
  //             fontWeight: FontWeight.bold,
  //             fontSize: 13,
  //             letterSpacing: 0.5,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _showAttachments(BuildContext context) {
    final lastLeave = safeLastLeave;
    if (lastLeave == null) {
      Utils.showSnackBar(message: noAttachmentKey, context: context);
      return;
    }

    final files = lastLeave.file;
    if (files == null || files.isEmpty) {
      Utils.showSnackBar(message: noAttachmentKey, context: context);
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: TweenAnimationBuilder(
                duration: const Duration(milliseconds: 400),
                tween: Tween<double>(begin: 0.8, end: 1.0),
                curve: Curves.easeOutQuad,
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _maroonDark.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: _maroonPrimary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.photo_library_rounded,
                                color: _maroonPrimary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Lampiran',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _maroonPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _maroonLight.withValues(alpha: 0.1),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: _maroonPrimary,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(
                        thickness: 1,
                        color: _maroonAccent.withValues(alpha: 0.5),
                        height: 24,
                      ),
                      const SizedBox(height: 8),
                      // Informative message about fullscreen view

                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.6,
                          maxWidth: MediaQuery.of(context).size.width * 0.8,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: files.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 20.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 15,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: TweenAnimationBuilder(
                                  duration: Duration(
                                      milliseconds: 500 + (index * 100)),
                                  tween: Tween<double>(begin: 0.0, end: 1.0),
                                  builder: (context, double value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: child,
                                    );
                                  },
                                  child: GestureDetector(
                                    onTap: () => _showFullScreenImage(
                                        context, files[index].fileUrl ?? ''),
                                    child: Stack(
                                      children: [
                                        Image.network(
                                          files[index].fileUrl ?? '',
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Container(
                                              height: 240,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Center(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      width: 40,
                                                      height: 40,
                                                      child:
                                                          CircularProgressIndicator(
                                                        value: loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                (loadingProgress
                                                                        .expectedTotalBytes ??
                                                                    1)
                                                            : null,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                    Color>(
                                                                _maroonPrimary),
                                                        strokeWidth: 3,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      "Memuat lampiran...",
                                                      style: TextStyle(
                                                        color: _maroonPrimary,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              height: 240,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: _maroonLight
                                                      .withValues(alpha: 0.2),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Center(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .broken_image_rounded,
                                                      color: _maroonPrimary,
                                                      size: 48,
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      "Tidak dapat memuat gambar",
                                                      style: TextStyle(
                                                        color: _maroonPrimary,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      "Coba lagi nanti",
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey.shade700,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        // Zoom indicator overlay
                                        Positioned(
                                          right: 10,
                                          bottom: 10,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withValues(alpha: 0.5),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Icon(
                                              Icons.zoom_out_map_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ],
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
          ),
        );
      },
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withValues(alpha: 0.85),
              child: Stack(
                children: [
                  // Fullscreen image with pinch-to-zoom
                  Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ??
                                            1)
                                    : null,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    _maroonPrimary),
                                strokeWidth: 3,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_rounded,
                                color: Colors.white,
                                size: 70,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Tidak dapat memuat gambar",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // Close button
                  Positioned(
                    top: 40,
                    right: 20,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.5),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClassesCubit, ClassesState>(
      builder: (context, state) {
        if (state is ClassesFetchSuccess) {
          // Start animation once data is loaded
          if (!_animationController.isCompleted) {
            _animationController.forward();
          }
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              try {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildSuccessUI(),
                  ),
                );
              } catch (e, stackTrace) {
                debugPrint('Error in AnimatedBuilder: $e');
                debugPrint('Stack trace: $stackTrace');
                debugPrint(
                    'Permission details: ${widget.permissionDetails.toJson()}');
                // Fallback to simple UI without animation
                return _buildSimpleUI();
              }
            },
          );
        } else if (state is ClassesFetchFailure) {
          return _buildErrorUI();
        } else {
          return _buildLoadingUI();
        }
      },
    );
  }

  Widget _buildSuccessUI() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        margin: EdgeInsets.symmetric(
          horizontal: appContentHorizontalPadding,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: _surfaceColor,
          boxShadow: [
            BoxShadow(
              color: _isHovering
                  ? _maroonPrimary.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: _isHovering ? 18 : 8,
              offset: Offset(0, _isHovering ? 6 : 4),
              spreadRadius: _isHovering ? 2 : 0,
            ),
          ],
          border: Border.all(
            color: _isHovering
                ? _maroonPrimary.withValues(alpha: 0.3)
                : _maroonLight.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background pattern and decorative elements
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _maroonAccent.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      radius: 0.7,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -15,
                left: -15,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _goldAccent.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                      radius: 0.7,
                    ),
                  ),
                ),
              ),

              // Main content
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with leave type and attachment button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLeaveTypeChip(getSafeLeaveType()),
                        // Commented out status badge to prevent overflow
                        // Row(
                        //   children: [
                        //     _buildLeaveTypeChip(getSafeLeaveType()),
                        //     const SizedBox(width: 12),
                        //     _buildHeaderStatusBadge(),
                        //   ],
                        // ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showAttachments(context),
                            borderRadius: BorderRadius.circular(50),
                            splashColor: _maroonPrimary.withValues(alpha: 0.1),
                            highlightColor: _maroonPrimary.withValues(alpha: 0.05),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isHovering
                                    ? _maroonPrimary.withValues(alpha: 0.15)
                                    : _maroonPrimary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                boxShadow: _isHovering
                                    ? [
                                        BoxShadow(
                                          color:
                                              _maroonPrimary.withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                Icons.attach_file_rounded,
                                size: 22,
                                color: _maroonPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Student info header section with enhanced styling
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _maroonPrimary.withValues(alpha: 0.8),
                                _maroonDark,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _maroonPrimary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.permissionDetails.user?.fullName ?? "",
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 20 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: _maroonDark,
                                  letterSpacing: 0.3,
                                  height: 1.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _innerBgColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _borderColor,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.class_outlined,
                                      size: 16,
                                      color: _maroonPrimary.withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Kelas: ${getClassSectionName(widget.permissionDetails.classSectionId)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _mainTextColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _innerBgColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _borderColor,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.format_list_numbered,
                                      size: 16,
                                      color: _maroonPrimary.withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Absen: ${widget.permissionDetails.rollNumber}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _mainTextColor,
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

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              _maroonLight.withValues(alpha: 0.6),
                              _maroonLight.withValues(alpha: 0.6),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.2, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Reason section with enhanced styling
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: _maroonLight.withValues(alpha: 0.05),
                        border: Border.all(
                          color: _maroonPrimary.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _maroonPrimary.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _maroonPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  color: _maroonPrimary,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Keterangan",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _maroonPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _innerBgWhiteColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _borderColor,
                              ),
                            ),
                            child: Text(
                              translateRole(safeLastLeave?.reason ?? ''),
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: _mainTextColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ), // Footer with date in a more elegant style
                    if (safeLastLeave?.fromDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // School branding indicator

                            const SizedBox(width: 8),

                            // Date container
                            Flexible(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 12 : 16,
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _maroonLight.withValues(alpha: 0.2),
                                      _goldAccent.withValues(alpha: 0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: _maroonLight.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 16,
                                      color: _maroonDark,
                                    ),
                                    SizedBox(width: isSmallScreen ? 6 : 10),
                                    Flexible(
                                      child: Text(
                                        safeLastLeave?.fromDate ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _maroonDark,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Action buttons section
                    _buildActionButtons(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorUI() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  margin: EdgeInsets.symmetric(
                      horizontal: appContentHorizontalPadding),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.shade50,
                        Colors.red.shade100,
                      ],
                    ),
                    border: Border.all(color: Colors.red.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade100.withValues(alpha: 0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.shade300.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red.shade700,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Gagal memuat data',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Silakan coba lagi dalam beberapa saat',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        );
      },
    );
  }

  Widget _buildLoadingUI() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 60 * value,
                          height: 60 * value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _maroonPrimary.withValues(alpha: 0.1 * value),
                          ),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(_maroonPrimary),
                            strokeWidth: 4,
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _maroonPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Memuat data...',
                  style: TextStyle(
                    color: _maroonPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 140,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.grey.shade200,
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeInOut,
                        left: value > 0.5 ? 0 : 140 * (1 - value * 2),
                        right: value > 0.5 ? 140 * (1 - (value - 0.5) * 2) : 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: _maroonPrimary,
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
      },
    );
  }

  Widget _buildSimpleUI() {
    // Simple fallback UI without animations

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: appContentHorizontalPadding,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _maroonLight.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leave type chip
              _buildLeaveTypeChip(getSafeLeaveType()),
              const SizedBox(height: 16),

              // Student name
              Text(
                widget.permissionDetails.user?.fullName ?? "",
                style: const TextStyle(
                  fontSize: 18.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Class and roll number
              Text(
                'Kelas: ${getClassSectionName(widget.permissionDetails.classSectionId)}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Absen: ${widget.permissionDetails.rollNumber}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),

              const Divider(thickness: 1),
              const SizedBox(height: 8),

              // Reason
              const Text(
                "Keterangan:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                translateRole(safeLastLeave?.reason ?? ''),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Action buttons for approve/reject
  Widget _buildActionButtons() {
    final lastLeave = safeLastLeave;
    if (lastLeave == null) return const SizedBox.shrink();

    // Check if leave is already approved or rejected (use optimistic status if available)
    final int status = _optimisticStatus ?? lastLeave.status ?? 0;

    // Debug logging
    debugPrint("DEBUG _buildActionButtons:");
    debugPrint("  - Server status: ${lastLeave.status}");
    debugPrint("  - Optimistic status: $_optimisticStatus");
    debugPrint("  - Final status: $status");

    if (status == 1 || status == 2) {
      return _buildStatusSection(status);
    }

    return BlocConsumer<ApproveOrRejectStudentPermissionCubit,
        ApproveOrRejectStudentPermissionState>(
      bloc: _approveRejectCubit,
      listener: (context, state) {
        if (state is ApproveOrRejectStudentPermissionSuccess) {
          Utils.showSnackBar(
            message: "Izin berhasil diperbarui",
            context: context,
          );
          // Don't clear optimistic state immediately - let it persist until refresh
          // The parent will refresh the data and rebuild this widget with new data
          widget.onPermissionUpdated?.call();
        } else if (state is ApproveOrRejectStudentPermissionFailure) {
          setState(() {
            _optimisticStatus = null;
            _optimisticRejectionReason = null;
          });
          Utils.showSnackBar(
            message: state.errorMessage,
            context: context,
          );
        }
      },
      builder: (context, state) {
        final bool isInProgress =
            state is ApproveOrRejectStudentPermissionInProgress;
        return Container(
          margin: const EdgeInsets.only(top: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildPrimaryButton(
                  onTap: isInProgress
                      ? null
                      : () => _approveLeave(context, lastLeave.id ?? 0),
                  label: "Setujui",
                  
                  primaryColor: Colors.green.shade600,
                  isLoading: isInProgress,
                  isApprove: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPrimaryButton(
                  onTap: isInProgress
                      ? null
                      : () => _rejectLeave(context, lastLeave.id ?? 0),
                  label: "Tolak",
                 
                  primaryColor: Colors.red.shade600,
                  isLoading: isInProgress,
                  isApprove: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusSection(int status) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          // Show rejection reason if available
          if (status == 2) ...[
            Builder(
              builder: (context) {
                final rejectionReason = _optimisticRejectionReason ??
                    safeLastLeave?.rejectionReason;
                if (rejectionReason != null && rejectionReason.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Alasan Penolakan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.shade200,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade100.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  rejectionReason,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red.shade800,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
          _buildEditButtons(status),
        ],
      ),
    );
  }

  Widget _buildEditButtons(int currentStatus) {
    final lastLeave = safeLastLeave;
    if (lastLeave == null) return const SizedBox.shrink();

    return BlocProvider(
      create: (context) => ApproveOrRejectStudentPermissionCubit(),
      child: BlocConsumer<ApproveOrRejectStudentPermissionCubit,
          ApproveOrRejectStudentPermissionState>(
        listener: (context, state) {
          if (state is ApproveOrRejectStudentPermissionSuccess) {
            // Show success message
            Utils.showSnackBar(
              message: "Keputusan izin berhasil diperbarui",
              context: context,
            );
            // Keep the optimistic state as it succeeded
            // Refresh parent data
            widget.onPermissionUpdated?.call();
          } else if (state is ApproveOrRejectStudentPermissionFailure) {
            // Rollback optimistic state on failure
            setState(() {
              _optimisticStatus = null;
              _optimisticRejectionReason = null;
            });

            // Show error message
            Utils.showSnackBar(
              message: state.errorMessage,
              context: context,
            );
          }
        },
        builder: (context, state) {
          final bool isInProgress =
              state is ApproveOrRejectStudentPermissionInProgress;

          return Container(
            margin: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                // Show "Change to Approve" button if currently rejected
                if (currentStatus == 2) ...[
                  Expanded(
                    child: _buildModernButton(
                      onTap: isInProgress
                          ? null
                          : () => _changeToApprove(context, lastLeave.id ?? 0),
                      label: "Ubah ke Setujui",
                      icon: Icons.check_circle_outline_rounded,
                      primaryColor: Colors.green.shade600,
                      backgroundColor: Colors.green.shade50,
                      isLoading: isInProgress,
                    ),
                  ),
                ],

                // Show "Change to Reject" button if currently approved
                if (currentStatus == 1) ...[
                  Expanded(
                    child: _buildModernButton(
                      onTap: isInProgress
                          ? null
                          : () => _changeToReject(context, lastLeave.id ?? 0),
                      label: "Ubah ke Tolak",
                      icon: Icons.highlight_remove_rounded,
                      primaryColor: Colors.red.shade600,
                      backgroundColor: Colors.red.shade50,
                      isLoading: isInProgress,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernButton({
    required VoidCallback? onTap,
    required String label,
    required IconData icon,
    required Color primaryColor,
    required Color backgroundColor,
    required bool isLoading,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: primaryColor.withValues(alpha: 0.1),
        highlightColor: primaryColor.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Memproses...",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ] else ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback? onTap,
    required String label,
    required Color primaryColor,
    required bool isLoading,
    required bool isApprove,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.8),
            primaryColor,
            primaryColor.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
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
                    if (isLoading) ...[
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Memproses...",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ] else ...[
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

  void _approveLeave(BuildContext context, int leaveId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text("Apakah Anda yakin ingin menyetujui izin ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();

              // Optimistic update
              setState(() {
                _optimisticStatus = 1; // Approved
                _optimisticRejectionReason = null;
              });

              // Make API call using class member cubit
              _approveRejectCubit.approveOrRejectStudentPermission(
                leaveId: leaveId,
                approveLeave: true,
              );
            },
            child: const Text("Setujui"),
          ),
        ],
      ),
    );
  }

  void _rejectLeave(BuildContext context, int leaveId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => RejectReasonDialog(
        onReject: (String rejectReason) {
          Navigator.of(dialogContext).pop();

          // Optimistic update
          setState(() {
            _optimisticStatus = 2; // Rejected
            _optimisticRejectionReason = rejectReason;
          });

          // Make API call
          context
              .read<ApproveOrRejectStudentPermissionCubit>()
              .approveOrRejectStudentPermission(
                leaveId: leaveId,
                approveLeave: false,
                rejectReason: rejectReason,
              );
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  void _changeToApprove(BuildContext context, int leaveId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Ubah Keputusan"),
        content: const Text(
            "Apakah Anda yakin ingin mengubah keputusan menjadi 'Disetujui'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();

              // Optimistic update
              setState(() {
                _optimisticStatus = 1; // Approved
                _optimisticRejectionReason = null; // Clear rejection reason
              });

              // Make API call
              context
                  .read<ApproveOrRejectStudentPermissionCubit>()
                  .approveOrRejectStudentPermission(
                    leaveId: leaveId,
                    approveLeave: true,
                  );
            },
            child: const Text("Ya, Ubah"),
          ),
        ],
      ),
    );
  }

  void _changeToReject(BuildContext context, int leaveId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => RejectReasonDialog(
        onReject: (String rejectReason) {
          Navigator.of(dialogContext).pop();

          // Optimistic update
          setState(() {
            _optimisticStatus = 2; // Rejected
            _optimisticRejectionReason = rejectReason;
          });

          // Make API call using class member cubit
          _approveRejectCubit.approveOrRejectStudentPermission(
            leaveId: leaveId,
            approveLeave: false,
            rejectReason: rejectReason,
          );
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  // Helper method to safely get the last leave
  dynamic get safeLastLeave {
    try {
      if (widget.permissionDetails.leaves.isEmpty) {
        debugPrint('Debug: leaves list is empty');
        return null;
      }
      final lastLeave = widget.permissionDetails.leaves.last;
      debugPrint(
          'Debug: found last leave with ${lastLeave.leaveDetail?.length ?? 0} leave details');
      return lastLeave;
    } catch (e) {
      debugPrint('Error in safeLastLeave: $e');
      return null;
    }
  }

  // Helper method to safely get leave type
  String getSafeLeaveType() {
    try {
      final lastLeave = safeLastLeave;
      if (lastLeave == null) {
        debugPrint('Debug: lastLeave is null');
        return '';
      }

      final leaveDetail = lastLeave.leaveDetail;
      if (leaveDetail == null) {
        debugPrint('Debug: leaveDetail is null');
        return '';
      }

      if (leaveDetail.isEmpty) {
        debugPrint('Debug: leaveDetail is empty');
        return '';
      }

      final type = leaveDetail.last?.type;
      debugPrint('Debug: leave type is $type');
      return type ?? '';
    } catch (e) {
      debugPrint('Error in getSafeLeaveType: $e');
      return '';
    }
  }
}
