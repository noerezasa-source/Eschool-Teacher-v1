import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/announcement/deleteNotificationCubit.dart';
import 'package:eschool_saas_staff/cubits/announcement/notificationsCubit.dart';
import 'package:eschool_saas_staff/cubits/userDetails/staffAllowedPermissionsAndModulesCubit.dart';
import 'package:eschool_saas_staff/data/models/system/notificationDetails.dart';
import 'package:eschool_saas_staff/ui/screens/manageAnnouncement/widgets/announcementDescriptionBottomsheet.dart';
import 'package:eschool_saas_staff/ui/screens/manageNotification/widgets/deleteNotificationConfirmationDialog.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/systemModulesAndPermissions.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class AdminNotificationDetailsContainer extends StatefulWidget {
  final int index;
  final NotificationDetails notificationDetails;
  const AdminNotificationDetailsContainer(
      {super.key, required this.index, required this.notificationDetails});

  @override
  State<AdminNotificationDetailsContainer> createState() =>
      _AdminNotificationDetailsContainerState();
}

class _AdminNotificationDetailsContainerState
    extends State<AdminNotificationDetailsContainer>
    with TickerProviderStateMixin {
  late final AnimationController _animationController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

  late final AnimationController _deleteAnimationController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 200));

  Color get _maroonPrimary => AppColorPalette.primaryMaroon;

  bool _isHovering = false;

  @override
  void dispose() {
    _animationController.dispose();
    _deleteAnimationController.dispose();
    super.dispose();
  }

  // Format date for display
  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return "";

    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  // Get icon based on notification type
  IconData _getNotificationIcon() {
    final title = widget.notificationDetails.title?.toLowerCase() ?? "";
    if (title.contains("absen")) return Icons.face;
    if (title.contains("ujian")) return Icons.school;
    if (title.contains("tugas")) return Icons.assignment;
    if (title.contains("acara")) return Icons.event;
    if (title.contains("bayar")) return Icons.payment;
    if (title.contains("libur")) return Icons.beach_access;
    return Icons.notifications;
  }

  @override
  Widget build(BuildContext context) {
    // Get icon and color for notification
    final iconData = _getNotificationIcon();
    final bool hasImage = (widget.notificationDetails.image ?? "").isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (_animationController.isAnimating) return;

        if (_animationController.isCompleted) {
          _animationController.reverse();
        } else {
          _animationController.forward();
        }
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovering ? Colors.grey.shade50 : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with number and title
                Row(
                  children: [
                    // Number badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _maroonPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (widget.index + 1).toString().padLeft(2, '0'),
                        style: GoogleFonts.poppins(
                          color: _maroonPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Icon for notification type
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _maroonPrimary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconData,
                        color: _maroonPrimary,
                        size: 18,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Title with expand/collapse indicator
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.notificationDetails.title ?? "-",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatDateTime(
                                      widget.notificationDetails.createdAt),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _animationController.value * pi,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: _animationController.value > 0
                                        ? _maroonPrimary.withValues(alpha: 0.1)
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: _animationController.value > 0
                                        ? _maroonPrimary
                                        : Colors.grey[600],
                                    size: 22,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Expandable content
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return ClipRect(
                      child: Align(
                        heightFactor: _animationController.value,
                        child: Opacity(
                          opacity: _animationController.value,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Message content
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.message_outlined,
                                    size: 16,
                                    color: _maroonPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    Utils.getTranslatedLabel(
                                        messageKey, ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _maroonPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.notificationDetails.message ?? "-",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (Utils.calculateLinesForGivenText(
                                      availableMaxWidth:
                                          MediaQuery.of(context).size.width -
                                              80,
                                      context: context,
                                      text:
                                          widget.notificationDetails.message ??
                                              "-",
                                      textStyle:
                                          GoogleFonts.poppins(fontSize: 14)) >
                                  4)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      Utils.showBottomSheet(
                                          child:
                                              AnnouncementDescriptionBottomsheet(
                                                  text: widget
                                                          .notificationDetails
                                                          .message ??
                                                      "-"),
                                          context: context);
                                    },
                                    child: Text(
                                      "Lihat Selengkapnya",
                                      style: GoogleFonts.poppins(
                                        color: _maroonPrimary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Footer with image and actions
                        Row(
                          children: [
                            // Image if available
                            if (hasImage)
                              Container(
                                width: 60,
                                height: 60,
                                margin: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: CachedNetworkImageProvider(
                                        widget.notificationDetails.image!),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        // Show image in fullscreen or larger view
                                        showDialog(
                                          context: context,
                                          builder: (context) => Dialog(
                                            backgroundColor: Colors.transparent,
                                            elevation: 0,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: CachedNetworkImage(
                                                    imageUrl: widget
                                                        .notificationDetails
                                                        .image!,
                                                    fit: BoxFit.contain,
                                                    placeholder:
                                                        (context, url) =>
                                                            Container(
                                                      color: Colors.grey[200],
                                                      child: Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          color: _maroonPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            Container(
                                                      color: Colors.grey[200],
                                                      child: const Icon(Icons.error,
                                                          color: Colors.red),
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  icon: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: const BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(Icons.close,
                                                        color: _maroonPrimary),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      splashColor:
                                          _maroonPrimary.withValues(alpha: 0.1),
                                    ),
                                  ),
                                ),
                              ),

                            const Spacer(),

                            // Delete button
                            if (context
                                .read<StaffAllowedPermissionsAndModulesCubit>()
                                .isPermissionGiven(
                                    permission:
                                        deleteNotificationPermissionKey))
                              MouseRegion(
                                onEnter: (_) =>
                                    _deleteAnimationController.forward(),
                                onExit: (_) =>
                                    _deleteAnimationController.reverse(),
                                child: AnimatedBuilder(
                                  animation: _deleteAnimationController,
                                  builder: (context, child) {
                                    return InkWell(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => BlocProvider(
                                            create: (context) =>
                                                DeleteNotificationCubit(),
                                            child:
                                                DeleteNotificationConfirmationDialog(
                                              notificationId: widget
                                                      .notificationDetails.id ??
                                                  0,
                                            ),
                                          ),
                                        ).then((value) {
                                          final notificationId = value as int?;
                                          if (notificationId != null &&
                                              context.mounted) {
                                            context
                                                .read<NotificationsCubit>()
                                                .deleteNotification(
                                                    notificationId:
                                                        notificationId);
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Color.lerp(
                                            Colors.red.withValues(alpha: 0.08),
                                            Colors.red.withValues(alpha: 0.15),
                                            _deleteAnimationController.value,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Color.lerp(
                                              Colors.red.withValues(alpha: 0.2),
                                              Colors.red.withValues(alpha: 0.3),
                                              _deleteAnimationController.value,
                                            )!,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: Colors.red[700],
                                            ),
                                            AnimatedContainer(
                                              duration:
                                                  const Duration(milliseconds: 200),
                                              width: _deleteAnimationController
                                                          .value >
                                                      0
                                                  ? 8
                                                  : 0,
                                            ),
                                            if (_deleteAnimationController
                                                    .value >
                                                0)
                                              SizeTransition(
                                                sizeFactor:
                                                    _deleteAnimationController,
                                                axis: Axis.horizontal,
                                                child: Text(
                                                  Utils.getTranslatedLabel(
                                                      deleteKey,),
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.red[700],
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                ),
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(
        effects: hasImage
            ? [
                ScaleEffect(
                  begin: const Offset(0.98, 0.98),
                  end: const Offset(1, 1),
                  duration: 300.ms,
                  curve: Curves.easeOutQuad,
                )
              ]
            : []);
  }
}
