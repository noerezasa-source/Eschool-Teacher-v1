import 'package:eschool_saas_staff/cubits/academics/classesCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/leave/leaveDetails.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

class LeaveDetailsContainer extends StatefulWidget {
  final LeaveDetails leaveDetails;
  final bool? overflow;

  const LeaveDetailsContainer({
    super.key,
    required this.leaveDetails,
    this.overflow,
  });

  @override
  State<LeaveDetailsContainer> createState() => _LeaveDetailsContainerState();
}

class _LeaveDetailsContainerState extends State<LeaveDetailsContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isHovering = false;
  OverlayEntry? _overlayEntry;

  // Refined color palette - now dynamic based on theme
  Color get _maroonPrimary => AppColorPalette.primaryMaroon;
  Color get _maroonLight => AppColorPalette.secondaryMaroon;
  Color get _maroonDark => _maroonPrimary.withValues(alpha: 0.85);
  Color get _maroonAccent => _maroonPrimary.withValues(alpha: 0.15);
  Color get _goldAccent => const Color(0xFFE6D2AA);

  @override
  void initState() {
    super.initState();
    context.read<ClassesCubit>().getClasses();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

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
  void dispose() {
    _animationController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  String getClassSectionName(int? classSectionId) {
    if (classSectionId == null) return '-';

    final classesCubit = context.read<ClassesCubit>();
    final allClasses = classesCubit.getAllClasses();

    final classSection = allClasses.firstWhere(
      (classSection) => classSection.id == classSectionId,
      orElse: () => ClassSection(name: '-'),
    );

    return classSection.name ?? 'Unknown Class';
  }

  String translateRole(String role) {
    final Map<String, String> roleTranslations = {
      "Teacher": "Guru",
    };
    return roleTranslations[role] ?? role;
  }

  String translateLeaveType(String type) {
    final Map<String, String> leaveTranslations = {
      "Full": "Sehari Penuh",
      "First Half": "Paruh Pertama",
      "Second Half": "Paruh Kedua",
      "sick": "Sakit",
    };
    return leaveTranslations[type] ?? type;
  }

  String formatDateToIndonesian(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';

    try {
      // Debug the incoming date string format
      debugPrint("Original date string: $dateString");

      // Special handling for "23 - May" format (day - english month)
      if (dateString.contains(' - ')) {
        List<String> parts = dateString.split(' - ');
        if (parts.length == 2) {
          String day = parts[0].trim();
          String englishMonth = parts[1].trim();

          // Map of English month names to Indonesian month names
          final Map<String, String> monthTranslations = {
            'January': 'Januari',
            'February': 'Februari',
            'March': 'Maret',
            'April': 'April',
            'May': 'Mei',
            'June': 'Juni',
            'July': 'Juli',
            'August': 'Agustus',
            'September': 'September',
            'October': 'Oktober',
            'November': 'November',
            'December': 'Desember',
            // Include short month names too
            'Jan': 'Januari',
            'Feb': 'Februari',
            'Mar': 'Maret',
            'Apr': 'April',
            // May is already included above
            'Jun': 'Juni',
            'Jul': 'Juli',
            'Aug': 'Agustus',
            'Sep': 'September',
            'Oct': 'Oktober',
            'Nov': 'November',
            'Dec': 'Desember'
          };

          String indonesianMonth =
              monthTranslations[englishMonth] ?? englishMonth;
          String currentYear = DateTime.now().year.toString();

          // Return in Indonesian format: day month year
          return '$day $indonesianMonth $currentYear';
        }
      }

      DateTime? date;

      // First try to manually parse common formats
      try {
        // Try dd-MM-yyyy format
        List<String> parts = dateString.split('-');
        if (parts.length == 3) {
          // Check if the first part could be a day (length 1-2, numeric)
          if (parts[0].length <= 2 && int.tryParse(parts[0]) != null) {
            date = DateTime(
              int.parse(parts[2]), // year
              int.parse(parts[1]), // month
              int.parse(parts[0]), // day
            );
          }
          // Try yyyy-MM-dd format which is common in APIs
          else if (parts[0].length == 4 && int.tryParse(parts[0]) != null) {
            date = DateTime(
              int.parse(parts[0]), // year
              int.parse(parts[1]), // month
              int.parse(parts[2]), // day
            );
          }
        }
      } catch (e) {
        debugPrint("Error parsing with split: $e");
      }

      // If manual parsing failed, try standard datetime parsing
      if (date == null) {
        try {
          date = DateTime.parse(dateString);
          debugPrint("Parsed with DateTime.parse: $date");
        } catch (e) {
          debugPrint("Error parsing with DateTime.parse: $e");

          // Try to handle localized date format that might already be in Indonesian
          List<String> indonesianMonths = [
            'Januari',
            'Februari',
            'Maret',
            'April',
            'Mei',
            'Juni',
            'Juli',
            'Agustus',
            'September',
            'Oktober',
            'November',
            'Desember'
          ];

          // Check if the date already contains Indonesian month names
          bool alreadyIndonesian =
              indonesianMonths.any((month) => dateString.contains(month));

          if (alreadyIndonesian) {
            debugPrint("Already in Indonesian format: $dateString");
            return dateString; // Already in the correct format
          }

          // If all parsing attempts fail, return the original string
          return dateString;
        }
      }

      // Define Indonesian month names
      final List<String> indonesianMonths = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];

      // Format the date in Indonesian
      final String day = date.day.toString();
      final String month = indonesianMonths[date.month - 1];
      final String year = date.year.toString();

      String result = '$day $month $year';
      debugPrint("Converted to Indonesian: $result");
      return result;
    } catch (e) {
      // If any error occurs, return the original string
      debugPrint("Error in formatDateToIndonesian: $e");
      return dateString;
    }
  }

  Widget _buildLeaveTypeChip(String type) {
    Color backgroundColor;
    Color textColor;
    Color shadowColor;
    String translatedType = translateLeaveType(type);
    IconData iconData;

    // Set defaults based on type
    if (type.toLowerCase() == 'sick') {
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      shadowColor = Colors.red.shade200.withValues(alpha: 0.3);
      iconData = Icons.healing;
    } else {
      // Default to Leave or any other type
      backgroundColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
      shadowColor = Colors.blue.shade200.withValues(alpha: 0.3);
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

  Widget _buildStatusChip(String statusText, Color statusColor) {
    IconData statusIcon;
    Color backgroundColor;

    // Set icon and background based on status
    switch (statusText) {
      case 'Ditolak':
        statusIcon = Icons.cancel_rounded;
        backgroundColor = statusColor.withValues(alpha: 0.15);
        break;
      case 'Disetujui':
        statusIcon = Icons.check_circle_rounded;
        backgroundColor = statusColor.withValues(alpha: 0.15);
        break;
      case 'Menunggu':
        statusIcon = Icons.schedule_rounded;
        backgroundColor = statusColor.withValues(alpha: 0.15);
        break;
      default:
        statusIcon = Icons.info_rounded;
        backgroundColor = statusColor.withValues(alpha: 0.15);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClassesCubit, ClassesState>(
      builder: (context, state) {
        if (state is ClassesFetchSuccess) {
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildSuccessUI(),
                ),
              );
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
          color: Colors.white,
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
                                widget.leaveDetails.leave?.user?.firstName ??
                                    "",
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

                              // Status chip - placed prominently at the top
                              if (widget.leaveDetails.status == 2 ||
                                  widget.leaveDetails.leave?.status == 2)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child:
                                      _buildStatusChip('Ditolak', Colors.red),
                                )
                              else if (widget.leaveDetails.status == 1 ||
                                  widget.leaveDetails.leave?.status == 1)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: _buildStatusChip(
                                      'Disetujui', Colors.green),
                                )
                              else if (widget.leaveDetails.status == 0 ||
                                  widget.leaveDetails.leave?.status == 0)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: _buildStatusChip(
                                      'Menunggu', Colors.orange),
                                ),

                              // Leave type and status chips
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    if (widget.leaveDetails.type != null)
                                      _buildLeaveTypeChip(
                                          widget.leaveDetails.type!),
                                    const SizedBox(width: 8),
                                    // Status chip code removed
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),
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
                    if (widget.leaveDetails.leave?.reason != null &&
                        widget.leaveDetails.leave!.reason!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alasan Cuti',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _maroonDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _maroonAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _maroonLight.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              widget.leaveDetails.leave!.reason!,
                              style: TextStyle(
                                fontSize: 14,
                                color: _maroonDark,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                    // Rejection reason section if status is rejected
                    if ((widget.leaveDetails.status == 2 ||
                            widget.leaveDetails.leave?.status == 2) &&
                        ((widget.leaveDetails.rejectionReason != null &&
                                widget.leaveDetails.rejectionReason!
                                    .isNotEmpty) ||
                            (widget.leaveDetails.leave?.rejectionReason !=
                                    null &&
                                widget.leaveDetails.leave!.rejectionReason!
                                    .isNotEmpty)))
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
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
                                      widget.leaveDetails.rejectionReason ??
                                          widget.leaveDetails.leave
                                              ?.rejectionReason ??
                                          'Alasan penolakan tidak tersedia',
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
                      ),

                    // Date range section if available
                    if (widget.leaveDetails.leave?.fromDate != null ||
                        widget.leaveDetails.leave?.toDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Periode Cuti',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _maroonDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 16 : 20,
                                  vertical: 14),
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
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 20,
                                    color: _maroonDark,
                                  ),
                                  SizedBox(width: isSmallScreen ? 10 : 14),
                                  Expanded(
                                    child: Text(
                                      '${formatDateToIndonesian(widget.leaveDetails.leave?.fromDate)} - ${formatDateToIndonesian(widget.leaveDetails.leave?.toDate)}',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 14,
                                        color: _maroonDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // File attachments - removed to use icon instead

                    // Footer with date in a more elegant style
                    Padding(
                      padding: const EdgeInsets.only(top: 27),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Attachment button at bottom left

                          if (widget.leaveDetails.leaveDate != null) ...[
                            const SizedBox(width: 8),
                            // Date container
                            _buildAttachmentIcon(),
                          ] else
                            const Spacer(),
                        ],
                      ),
                    ),
                    // Status chip
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getStatusColor(int? status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAttachmentIcon() {
    final files = widget.leaveDetails.leave?.file;
    if (files == null || files.isEmpty) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _maroonPrimary.withValues(alpha: 0.15),
                  _maroonLight.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                color: _maroonPrimary.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _maroonPrimary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showAttachmentsModal(files),
                splashColor: _maroonPrimary.withValues(alpha: 0.2),
                highlightColor: _maroonPrimary.withValues(alpha: 0.1),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Main attachment icon
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _maroonPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.attach_file_rounded,
                              color: _maroonPrimary,
                              size: 16,
                            ),
                          ),
                          // File count badge
                          if (files.length > 1)
                            Positioned(
                              top: -6,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: _maroonPrimary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${files.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lampiran',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _maroonDark,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            '${files.length} file${files.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 10,
                              color: _maroonPrimary.withValues(alpha: 0.8),
                              height: 1.0,
                            ),
                          ),
                        ],
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

  void _showAttachmentsModal(List<LeaveFile> files) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _maroonPrimary.withValues(alpha: 0.05),
                      _maroonLight.withValues(alpha: 0.03),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _maroonPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _maroonPrimary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.attach_file_rounded,
                        color: _maroonPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lampiran Dokumen',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _maroonDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${files.length} file${files.length > 1 ? 's' : ''} tersedia',
                            style: TextStyle(
                              fontSize: 14,
                              color: _maroonPrimary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: _maroonDark,
                        ),
                        splashRadius: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Files list
              Flexible(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: files.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return _buildAttachmentListItem(file, index);
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentListItem(LeaveFile file, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(40 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _maroonLight.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.of(context).pop();
                    _openFile(file);
                  },
                  splashColor: _maroonPrimary.withValues(alpha: 0.1),
                  highlightColor: _maroonPrimary.withValues(alpha: 0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        _buildFileIcon(file),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.fileName ?? 'File tidak diketahui',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _maroonDark,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _maroonPrimary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _maroonPrimary.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      file.fileExtension?.toUpperCase() ??
                                          'FILE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _maroonPrimary,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  if (file.isImage) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.green.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.image_rounded,
                                            size: 12,
                                            color: Colors.green.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Gambar',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _maroonPrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: _maroonPrimary,
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
    );
  }

  Widget _buildFileIcon(LeaveFile file) {
    IconData iconData;
    Color iconColor;
    Color backgroundColor;

    if (file.isImage) {
      iconData = Icons.image_rounded;
      iconColor = Colors.green.shade600;
      backgroundColor = Colors.green.shade50;
    } else {
      switch (file.fileExtension?.toLowerCase()) {
        case 'pdf':
          iconData = Icons.picture_as_pdf_rounded;
          iconColor = Colors.red.shade600;
          backgroundColor = Colors.red.shade50;
          break;
        case 'doc':
        case 'docx':
          iconData = Icons.description_rounded;
          iconColor = Colors.blue.shade600;
          backgroundColor = Colors.blue.shade50;
          break;
        case 'xls':
        case 'xlsx':
          iconData = Icons.table_chart_rounded;
          iconColor = Colors.green.shade600;
          backgroundColor = Colors.green.shade50;
          break;
        case 'txt':
          iconData = Icons.text_snippet_rounded;
          iconColor = Colors.orange.shade600;
          backgroundColor = Colors.orange.shade50;
          break;
        case 'zip':
        case 'rar':
          iconData = Icons.folder_zip_rounded;
          iconColor = Colors.purple.shade600;
          backgroundColor = Colors.purple.shade50;
          break;
        default:
          iconData = Icons.insert_drive_file_rounded;
          iconColor = _maroonPrimary;
          backgroundColor = _maroonPrimary.withValues(alpha: 0.1);
      }
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            iconData,
            color: iconColor,
            size: 28,
          ),
          // Add a subtle shine effect
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFile(LeaveFile file) async {
    if (file.isImage) {
      // Show image in dialog for images
      _showImageDialog(file);
    } else {
      // Open other file types with external app
      if (file.fileUrl != null && file.fileUrl!.isNotEmpty) {
        try {
          final Uri url = Uri.parse(file.fileUrl!);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            debugPrint('Could not launch ${file.fileUrl}');
          }
        } catch (e) {
          debugPrint('Error opening file: $e');
        }
      }
    }
  }

  void _showImageDialog(LeaveFile file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: Stack(
                children: [
                  // Background blur
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),

                  // Image content
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        file.fileUrl ?? '',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Gambar tidak dapat dimuat',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: _maroonPrimary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Memuat gambar...',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Close button
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  // File name at bottom
                  if (file.fileName != null)
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          file.fileName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
            ),
          ),
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
}
