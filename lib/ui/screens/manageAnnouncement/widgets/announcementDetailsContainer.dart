import 'dart:ui';
import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/announcement/announcementsCubit.dart';
import 'package:eschool_saas_staff/cubits/announcement/deleteAnnouncementCubit.dart';
import 'package:eschool_saas_staff/cubits/userDetails/staffAllowedPermissionsAndModulesCubit.dart';
import 'package:eschool_saas_staff/data/models/announcement/announcement.dart';
import 'package:eschool_saas_staff/ui/screens/system/editAnnouncementScreen.dart';
import 'package:eschool_saas_staff/ui/screens/manageAnnouncement/widgets/announcementDescriptionBottomsheet.dart';
import 'package:eschool_saas_staff/ui/screens/manageAnnouncement/widgets/announcementFilesBottomsheet.dart';
import 'package:eschool_saas_staff/ui/screens/manageAnnouncement/widgets/deleteAnnouncementDialog.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/systemModulesAndPermissions.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AnnouncementDetailsContainer extends StatefulWidget {
  final int index;
  final Announcement announcement;
  const AnnouncementDetailsContainer(
      {super.key, required this.index, required this.announcement});

  @override
  State<AnnouncementDetailsContainer> createState() =>
      _AnnouncementDetailsContainerState();
}

class _AnnouncementDetailsContainerState
    extends State<AnnouncementDetailsContainer> with TickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));

  late final AnimationController _deleteAnimationController =
      AnimationController(
          vsync: this, duration: const Duration(milliseconds: 200));

  late final AnimationController _editAnimationController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200));

  late final AnimationController _shimmerController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
    ..repeat();

  // Action button animation controllers
  late final AnimationController _editButtonAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  late final AnimationController _deleteButtonAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  Color get _maroonPrimary => AppColorPalette.primaryMaroon;

  // Action button hover states
  bool _editHovered = false;
  bool _deleteHovered = false;

  @override
  void initState() {
    super.initState();
    // Automatically show details when the component is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _deleteAnimationController.dispose();
    _editAnimationController.dispose();
    _shimmerController.dispose();
    _editButtonAnimation.dispose();
    _deleteButtonAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFiles = (widget.announcement.files ?? []).isNotEmpty;
    final accentColor =
        _maroonPrimary; // Default color instead of icon-based color

    return GestureDetector(
      onTap: () {
        // Remove toggle behavior - details are always shown
        // Could add other actions here if needed
      },
      child: MouseRegion(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuint,
          margin: const EdgeInsets.symmetric(
            horizontal: 12, // Always use expanded margin
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white, // Always use white background
            borderRadius:
                BorderRadius.circular(16), // Always use rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              )
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Close button in top right corner
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),

              // Main content container
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                    // No border needed since we're always expanded
                    ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Add padding for close button
                    const SizedBox(height: 8),

                    // Header row with number and title - icon removed
                    Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left section with number badge only (icon removed)
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _maroonPrimary,
                                borderRadius: BorderRadius.circular(
                                    10), // Always use expanded radius
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        _maroonPrimary.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                    spreadRadius: -1,
                                  )
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                (widget.index + 1).toString().padLeft(2, '0'),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ).animate().scale(
                                    begin: const Offset(1, 1),
                                    end: const Offset(1.1, 1.1),
                                    curve: Curves.easeOutQuint,
                                    duration: 400.ms,
                                  ),
                            ),

                            // Title column - moved closer to number since icon is removed
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title (always expanded style)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 12, top: 4, bottom: 2),
                                    child: Text(
                                      widget.announcement.title ?? "-",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight
                                            .w700, // Always use expanded weight
                                        fontSize:
                                            16, // Always use expanded size
                                        letterSpacing:
                                            0.2, // Always use expanded spacing
                                        color:
                                            _maroonPrimary, // Always use expanded color
                                        height: 1.3,
                                      ),
                                      maxLines:
                                          4, // Always use expanded max lines
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ).animate().slideX(
                                        begin: 0.02,
                                        end: 0,
                                        duration: 300.ms,
                                        curve: Curves.easeOutQuint,
                                      ),

                                  // Date row
                                  const Row(
                                    children: [
                                      // Date text
                                      // Text(
                                      //   widget.announcement.createdAt ?? "-",
                                      //   style: GoogleFonts.poppins(
                                      //     fontSize: 12,
                                      //     color: Colors.grey[600],
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Info indicator (replaces expand/collapse button)
                            Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: _maroonPrimary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ).animate().fadeIn(delay: 50.ms, duration: 400.ms).slideY(
                          begin: 0.2,
                          end: 0,
                          delay: 50.ms,
                          duration: 400.ms,
                          curve: Curves.easeOutQuad,
                        ),
                    const SizedBox(height: 8),

                    // Detail content (always visible)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Content divider with gradient
                          Container(
                            height: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade300,
                                  _maroonPrimary,
                                  accentColor,
                                  _maroonPrimary,
                                  Colors.grey.shade300,
                                ],
                                stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                          // Description content with fancy box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _maroonPrimary.withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Description header
                                Row(
                                  children: [
                                    // Description icon
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: _maroonPrimary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.description_outlined,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // Description label
                                    Text(
                                      Utils.getTranslatedLabel(
                                        descriptionKey,
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _maroonPrimary,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Description text
                                Text(
                                  widget.announcement.description ?? "-",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                // Read more button if needed
                                if (Utils.calculateLinesForGivenText(
                                        availableMaxWidth:
                                            MediaQuery.of(context).size.width -
                                                80,
                                        context: context,
                                        text: widget.announcement.description ??
                                            "-",
                                        textStyle:
                                            GoogleFonts.poppins(fontSize: 14)) >
                                    4)
                                  GestureDetector(
                                    onTap: () {
                                      Utils.showBottomSheet(
                                        child:
                                            AnnouncementDescriptionBottomsheet(
                                          text:
                                              widget.announcement.description ??
                                                  "-",
                                        ),
                                        context: context,
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 12),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _maroonPrimary.withValues(
                                            alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _maroonPrimary,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.visibility_outlined,
                                            size: 16,
                                            color: _maroonPrimary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Lihat Selengkapnya",
                                            style: GoogleFonts.poppins(
                                              color: _maroonPrimary,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 150.ms, duration: 400.ms)
                              .slideY(
                                begin: 0.2,
                                end: 0,
                                delay: 150.ms,
                                duration: 400.ms,
                                curve: Curves.easeOutQuad,
                              ),

                          // Files section with card
                          if (hasFiles)
                            Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: accentColor,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Files icon with container
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accentColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withValues(
                                              alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.attach_file_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  // File details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // File count
                                        Text(
                                          "${widget.announcement.files?.length ?? 0} ${widget.announcement.files?.length == 1 ? "File Terlampir" : "Files Terlampir"}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),

                                        // Instruction to tap
                                        Text(
                                          "Tap untuk melihat atau download",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // View files button
                                  ElevatedButton(
                                    onPressed: () {
                                      Utils.showBottomSheet(
                                        child: AnnouncementFilesBottomsheet(
                                          files:
                                              widget.announcement.files ?? [],
                                        ),
                                        context: context,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 4,
                                      shadowColor:
                                          accentColor.withValues(alpha: 0.4),
                                    ),
                                    child: Text(
                                      "Lihat Files",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 250.ms, duration: 400.ms)
                                .slideY(
                                  begin: 0.2,
                                  end: 0,
                                  delay: 250.ms,
                                  duration: 400.ms,
                                  curve: Curves.easeOutQuad,
                                ),

                          // Action buttons and footer
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status indicator
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: const Row(
                                    children: [],
                                  ),
                                ),

                                // Action buttons row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Edit button with hover effect and glassmorphism
                                    if (context
                                        .read<
                                            StaffAllowedPermissionsAndModulesCubit>()
                                        .isPermissionGiven(
                                          permission:
                                              editAnnouncementPermissionKey,
                                        ))
                                      MouseRegion(
                                        onEnter: (_) {
                                          setState(() => _editHovered = true);
                                          _editButtonAnimation.forward();
                                        },
                                        onExit: (_) {
                                          setState(() => _editHovered = false);
                                          _editButtonAnimation.reverse();
                                        },
                                        child: AnimatedBuilder(
                                          animation: _editButtonAnimation,
                                          builder: (context, _) {
                                            // Calculate lerp values for smooth transitions
                                            final double lerpValue =
                                                _editButtonAnimation.value;
                                            final Color textColor = Color.lerp(
                                                _maroonPrimary,
                                                Colors.white,
                                                lerpValue)!;

                                            return Container(
                                              decoration: BoxDecoration(
                                                color: _editHovered
                                                    ? _maroonPrimary.withValues(
                                                        alpha: 0.9)
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: _maroonPrimary,
                                                  width: 1.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _maroonPrimary
                                                        .withValues(
                                                            alpha: _editHovered
                                                                ? 0.25
                                                                : 0),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                    spreadRadius: -2,
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(13),
                                                child: BackdropFilter(
                                                  filter: _editHovered
                                                      ? ImageFilter.blur(
                                                          sigmaX: 0, sigmaY: 0)
                                                      : ImageFilter.blur(
                                                          sigmaX: 0, sigmaY: 0),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: () {
                                                        Get.toNamed(
                                                            Routes
                                                                .editAnnouncementScreen,
                                                            arguments: EditAnnouncementScreen
                                                                .buildArguments(
                                                                    announcement:
                                                                        widget
                                                                            .announcement));
                                                      },
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              13),
                                                      splashColor:
                                                          _maroonPrimary
                                                              .withValues(
                                                                  alpha: 0.2),
                                                      highlightColor:
                                                          _maroonPrimary
                                                              .withValues(
                                                                  alpha: 0.1),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 16,
                                                                vertical: 10),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            // Icon with animated container
                                                            Stack(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              children: [
                                                                // Pulsing circle background
                                                                if (_editHovered)
                                                                  Container(
                                                                    width: 28,
                                                                    height: 28,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      color: Colors
                                                                          .white
                                                                          .withValues(
                                                                              alpha: 0.2),
                                                                    ),
                                                                  )
                                                                      .animate(
                                                                        onPlay: (controller) =>
                                                                            controller.repeat(),
                                                                      )
                                                                      .scale(
                                                                        duration:
                                                                            1000.ms,
                                                                        curve: Curves
                                                                            .easeInOut,
                                                                        begin: const Offset(
                                                                            0.8,
                                                                            0.8),
                                                                        end: const Offset(
                                                                            1.2,
                                                                            1.2),
                                                                      )
                                                                      .fade(
                                                                        begin:
                                                                            0.7,
                                                                        end: 0,
                                                                        curve: Curves
                                                                            .easeOut,
                                                                      ),

                                                                // Icon
                                                                Icon(
                                                                  Icons
                                                                      .edit_rounded,
                                                                  size: 20,
                                                                  color:
                                                                      textColor,
                                                                ),
                                                              ],
                                                            ),

                                                            // Animated spacing
                                                            AnimatedContainer(
                                                              duration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          300),
                                                              curve: Curves
                                                                  .easeOutQuint,
                                                              width:
                                                                  _editHovered
                                                                      ? 10
                                                                      : 0,
                                                            ),

                                                            // Animated text appearance
                                                            ClipRect(
                                                              child:
                                                                  AnimatedContainer(
                                                                duration:
                                                                    const Duration(
                                                                        milliseconds:
                                                                            300),
                                                                curve: Curves
                                                                    .easeOutQuint,
                                                                width:
                                                                    _editHovered
                                                                        ? 50
                                                                        : 0,
                                                                child: Opacity(
                                                                  opacity:
                                                                      _editHovered
                                                                          ? 1.0
                                                                          : 0.0,
                                                                  child: Text(
                                                                    Utils.getTranslatedLabel(
                                                                        editKey),
                                                                    style: GoogleFonts
                                                                        .poppins(
                                                                      color:
                                                                          textColor,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .clip,
                                                                    softWrap:
                                                                        false,
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
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                    const SizedBox(width: 12),

                                    // Delete button with hover effect and glassmorphism
                                    if (context
                                        .read<
                                            StaffAllowedPermissionsAndModulesCubit>()
                                        .isPermissionGiven(
                                            permission:
                                                deleteAnnouncementPermissionKey))
                                      MouseRegion(
                                        onEnter: (_) {
                                          setState(() => _deleteHovered = true);
                                          _deleteButtonAnimation.forward();
                                        },
                                        onExit: (_) {
                                          setState(
                                              () => _deleteHovered = false);
                                          _deleteButtonAnimation.reverse();
                                        },
                                        child: AnimatedBuilder(
                                          animation: _deleteButtonAnimation,
                                          builder: (context, _) {
                                            // Calculate lerp values for smooth transitions
                                            final double lerpValue =
                                                _deleteButtonAnimation.value;
                                            final Color textColor = Color.lerp(
                                                Colors.red.shade700,
                                                Colors.white,
                                                lerpValue)!;

                                            return Container(
                                              decoration: BoxDecoration(
                                                color: _deleteHovered
                                                    ? Colors.red.shade700
                                                        .withValues(alpha: 0.9)
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: Colors.red.shade700,
                                                  width: 1.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.red.shade700
                                                        .withValues(
                                                            alpha:
                                                                _deleteHovered
                                                                    ? 0.25
                                                                    : 0),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                    spreadRadius: -2,
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(13),
                                                child: BackdropFilter(
                                                  filter: _deleteHovered
                                                      ? ImageFilter.blur(
                                                          sigmaX: 0, sigmaY: 0)
                                                      : ImageFilter.blur(
                                                          sigmaX: 0, sigmaY: 0),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: () {
                                                        showDialog(
                                                            context: context,
                                                            builder: (_) =>
                                                                BlocProvider(
                                                                  create: (_) =>
                                                                      DeleteAnnouncementCubit(),
                                                                  child:
                                                                      DeleteAnnouncementDialog(
                                                                    announcementId:
                                                                        widget.announcement.id ??
                                                                            0,
                                                                  ),
                                                                )).then(
                                                            (value) {
                                                          final announcementId =
                                                              value as int?;
                                                          if (announcementId !=
                                                              null) {
                                                            if (context
                                                                .mounted) {
                                                              context
                                                                  .read<
                                                                      AnnouncementsCubit>()
                                                                  .deleteAnnouncement(
                                                                      announcementId:
                                                                          announcementId);
                                                            }
                                                          }
                                                        });
                                                      },
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              13),
                                                      splashColor: Colors
                                                          .red.shade700
                                                          .withValues(
                                                              alpha: 0.2),
                                                      highlightColor: Colors
                                                          .red.shade700
                                                          .withValues(
                                                              alpha: 0.1),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 16,
                                                                vertical: 10),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            // Icon with animated container
                                                            Stack(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              children: [
                                                                // Pulsing circle background
                                                                if (_deleteHovered)
                                                                  Container(
                                                                    width: 28,
                                                                    height: 28,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      color: Colors
                                                                          .white
                                                                          .withValues(
                                                                              alpha: 0.2),
                                                                    ),
                                                                  )
                                                                      .animate(
                                                                        onPlay: (controller) =>
                                                                            controller.repeat(),
                                                                      )
                                                                      .scale(
                                                                        duration:
                                                                            1000.ms,
                                                                        curve: Curves
                                                                            .easeInOut,
                                                                        begin: const Offset(
                                                                            0.8,
                                                                            0.8),
                                                                        end: const Offset(
                                                                            1.2,
                                                                            1.2),
                                                                      )
                                                                      .fade(
                                                                        begin:
                                                                            0.7,
                                                                        end: 0,
                                                                        curve: Curves
                                                                            .easeOut,
                                                                      ),

                                                                // Icon
                                                                Icon(
                                                                  Icons
                                                                      .delete_outline_rounded,
                                                                  size: 20,
                                                                  color:
                                                                      textColor,
                                                                ),
                                                              ],
                                                            ),

                                                            // Animated spacing
                                                            AnimatedContainer(
                                                              duration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          300),
                                                              curve: Curves
                                                                  .easeOutQuint,
                                                              width:
                                                                  _deleteHovered
                                                                      ? 10
                                                                      : 0,
                                                            ),

                                                            // Animated text appearance
                                                            ClipRect(
                                                              child:
                                                                  AnimatedContainer(
                                                                duration:
                                                                    const Duration(
                                                                        milliseconds:
                                                                            300),
                                                                curve: Curves
                                                                    .easeOutQuint,
                                                                width:
                                                                    _deleteHovered
                                                                        ? 65
                                                                        : 0,
                                                                child: Opacity(
                                                                  opacity:
                                                                      _deleteHovered
                                                                          ? 1.0
                                                                          : 0.0,
                                                                  child: Text(
                                                                    Utils.getTranslatedLabel(
                                                                        deleteKey),
                                                                    style: GoogleFonts
                                                                        .poppins(
                                                                      color:
                                                                          textColor,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .clip,
                                                                    softWrap:
                                                                        false,
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
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 350.ms, duration: 400.ms)
                              .slideY(
                                begin: 0.2,
                                end: 0,
                                delay: 350.ms,
                                duration: 400.ms,
                                curve: Curves.easeOutQuad,
                              ),
                        ],
                      ),
                    ),

                    // End of detail content padding
                  ],
                ),
              ),

              // Edge highlight (always visible)
              Positioned(
                top: 0,
                left: 16,
                right: 16,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: _maroonPrimary,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                ).animate().fadeIn(duration: 300.ms),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1, 1),
          curve: Curves.easeOutQuint,
          duration: 400.ms,
        );
  }
}

// Custom painter for ripple effect
class CircleRipplePainter extends CustomPainter {
  final Color color;
  final double animationValue;

  CircleRipplePainter({
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw ripples
    for (var i = 0; i < 3; i++) {
      final rippleValue = (animationValue - (i * 0.3)).clamp(0.0, 1.0);
      if (rippleValue <= 0) continue;

      final paint = Paint()
        ..color = color.withValues(alpha: (1 - rippleValue) * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * (1 - rippleValue);

      canvas.drawCircle(center, radius * rippleValue, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
