import 'package:eschool_saas_staff/data/models/student/studentDetails.dart';
import 'package:eschool_saas_staff/ui/styles/themeExtensions/customColorsExtension.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentAttendanceItemContainer extends StatefulWidget {
  final bool showStatusPicker;
  final bool isPresent;
  final bool isSick;
  final bool isPermission;
  final bool isAlpa;
  final StudentDetails studentDetails;
  final Function(StudentAttendanceStatus status)? onChangeAttendance;
  final int index;

  const StudentAttendanceItemContainer({
    super.key,
    required this.studentDetails,
    this.showStatusPicker = false,
    required this.isPresent,
    required this.isSick,
    required this.isPermission,
    required this.isAlpa,
    required this.index,
    this.onChangeAttendance,
  });

  @override
  State<StudentAttendanceItemContainer> createState() =>
      _StudentAttendanceItemContainerState();
}

class _StudentAttendanceItemContainerState
    extends State<StudentAttendanceItemContainer>
    with SingleTickerProviderStateMixin {
  late StudentAttendanceStatus selectedValue = widget.isPresent
      ? StudentAttendanceStatus.present
      : widget.isSick
          ? StudentAttendanceStatus.sick
          : widget.isPermission
              ? StudentAttendanceStatus.permission
              : widget.isAlpa
                  ? StudentAttendanceStatus.alpa
                  : StudentAttendanceStatus.present;

  // Colors for the maroon theme to match teacherAddAttendanceSubjectScreen.dart
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;

  // Animation controller for interactive elements
  late AnimationController _animationController;

  // Flag to check if student is active or has resigned
  bool get isStudentActive =>
      !(widget.studentDetails.fullName?.contains("(nonaktif)") ?? false);

  String get cleanStudentName {
    final name = widget.studentDetails.firstName ?? "";
    return name.trim();
  }

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Fixed the overflow issue by using a more space-efficient layout
  Widget _buildStatusPicker(BuildContext context) {
    // If student isn't active, don't show status picker
    if (!isStudentActive) {
      return _buildResignedBadge();
    }

    // Use a Row for horizontal alignment with sufficient space
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min, // Take only as much space as needed
        children: [
          _buildAttendanceOption(
            context,
            status: StudentAttendanceStatus.sick,
            text: 'S',
            color: Theme.of(context)
                .extension<CustomColors>()!
                .sickBackgroundColor!,
          ),
          const SizedBox(width: 2), // Minimal spacing between buttons
          _buildAttendanceOption(
            context,
            status: StudentAttendanceStatus.permission,
            text: 'I',
            color: Theme.of(context)
                .extension<CustomColors>()!
                .permissionBackgroundColor!,
          ),
          const SizedBox(width: 2), // Minimal spacing between buttons
          _buildAttendanceOption(
            context,
            status: StudentAttendanceStatus.alpa,
            text: 'A',
            color: Theme.of(context)
                .extension<CustomColors>()!
                .totalStudentOverviewBackgroundColor!,
          ),
        ],
      ),
    );
  }

  // Badge to show when student has resigned
  Widget _buildResignedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        "Non-Aktif",
        style: GoogleFonts.poppins(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Circular attendance option button - made smaller to fix overflow
  Widget _buildAttendanceOption(
    BuildContext context, {
    required StudentAttendanceStatus status,
    required String text,
    required Color color,
  }) {
    final bool isSelected = selectedValue == status;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () {
          // Check if student is active before allowing attendance change
          if (!isStudentActive) {
            return;
          }

          // Provide haptic feedback for better user experience
          HapticFeedback.lightImpact();

          if (widget.onChangeAttendance != null) {
            setState(() {
              // Reset to present if tap same option again
              selectedValue = selectedValue == status
                  ? StudentAttendanceStatus.present
                  : status;
            });

            _animationController.forward(from: 0);
            widget.onChangeAttendance!(selectedValue);
          }
        },
        splashColor: color.withValues(alpha: 0.2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32, // Reduced from 36 to 32
          height: 32, // Reduced from 36 to 32
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : color,
                fontSize: 14, // Reduced from 16 to 14
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Apply animation based on index for staggered entry
    final animationDelay = (widget.index * 50).clamp(0, 500);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
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
          },
          splashColor: Colors.grey.withValues(alpha: 0.1),
          highlightColor: Colors.grey.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                      color: _maroonPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      (widget.index + 1).toString(),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _maroonPrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Student name column with more space and proper text handling
                Expanded(
                  flex:
                      5, // Reduced flex ratio to give more space to status column
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student name - without text ellipsis, allowing full name to be visible
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cleanStudentName,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isStudentActive
                                    ? Colors.grey[800]
                                    : Colors.grey[500],
                                decoration: isStudentActive
                                    ? TextDecoration.none
                                    : TextDecoration.lineThrough,
                              ),
                              // Make sure name is fully visible with no ellipsis
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Attendance status column with fixed width
                Expanded(
                  flex:
                      4, // Increased flex ratio for status column to prevent overflow
                  child: widget.showStatusPicker
                      ? _buildStatusPicker(context)
                      : isStudentActive
                          ? Center(child: _buildStatusBadge())
                          : Center(child: _buildResignedBadge()),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: Duration(milliseconds: animationDelay))
        .slideX(
            begin: 0.05,
            end: 0,
            duration: 400.ms,
            delay: Duration(milliseconds: animationDelay),
            curve: Curves.easeOutQuad);
  }

  Widget _buildStatusBadge() {
    // Get status details
    final String statusText = widget.isPresent
        ? "Hadir"
        : widget.isSick
            ? "Sakit"
            : widget.isPermission
                ? "Izin"
                : widget.isAlpa
                    ? "Alpa"
                    : "-";

    final Color statusColor = widget.isPresent
        ? Theme.of(context)
            .extension<CustomColors>()!
            .totalStaffOverviewBackgroundColor!
        : widget.isSick
            ? Theme.of(context).extension<CustomColors>()!.sickBackgroundColor!
            : widget.isPermission
                ? Theme.of(context)
                    .extension<CustomColors>()!
                    .permissionBackgroundColor!
                : widget.isAlpa
                    ? Theme.of(context)
                        .extension<CustomColors>()!
                        .totalStudentOverviewBackgroundColor!
                    : Theme.of(context)
                        .extension<CustomColors>()!
                        .totalStudentOverviewBackgroundColor!;

    final String statusLetter = widget.isPresent
        ? "H"
        : widget.isSick
            ? "S"
            : widget.isPermission
                ? "I"
                : widget.isAlpa
                    ? "A"
                    : "-";

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 6), // Reduced padding
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circle with letter
          Container(
            width: 22, // Reduced from 24 to 22
            height: 22, // Reduced from 24 to 22
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: statusColor,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              statusLetter,
              style: GoogleFonts.poppins(
                color: statusColor,
                fontSize: 11, // Reduced from 12 to 11
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4), // Reduced spacing
          Text(
            statusText,
            style: GoogleFonts.poppins(
              color: statusColor,
              fontSize: 12, // Reduced from 13 to 12
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis, // Added to handle overflow
          ),
        ],
      ),
    );
  }
}

