import 'package:eschool_saas_staff/data/models/system/holiday.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customBottomsheet.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HolidayContainer extends StatefulWidget {
  final Holiday holiday;
  final double width;
  final EdgeInsetsDirectional? margin;
  final Function()? onTap;

  const HolidayContainer({
    super.key,
    required this.width,
    this.margin,
    required this.holiday,
    this.onTap,
  });

  @override
  State<HolidayContainer> createState() => _HolidayContainerState();
}

class _HolidayContainerState extends State<HolidayContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final holidayStartDate = DateTime.parse(widget.holiday.startDate ?? "");
    final holidayEndDate = widget.holiday.endDate != null
        ? DateTime.parse(widget.holiday.endDate!)
        : holidayStartDate;
    final maroonColor = AppColorPalette.primaryMaroon;
    final maroonLight = AppColorPalette.secondaryMaroon;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          widget.onTap?.call() ??
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) =>
                    HolidayDetailsBottomsheet(holiday: widget.holiday),
              );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: widget.margin,
          width: widget.width,
          constraints: const BoxConstraints(minHeight: 150),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: _isHovered
                  ? maroonLight
                  : (isDark
                      ? AppColorPalette.secondaryMaroon
                      : Colors.grey.shade200),
              width: 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          maroonColor,
                          maroonLight,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -5,
                          right: -5,
                          child: FaIcon(FontAwesomeIcons.calendar,
                            size: 30,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Center(
                                child: CustomTextContainer(
                                  textKey: holidayStartDate.day.toString(),
                                  style: TextStyle(
                                    fontSize: Utils.getScaledValue(context, 34),
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Center(
                                child: Text(
                                  Utils.getMonthFullName(
                                      holidayStartDate.month),
                                  style: TextStyle(
                                    height: 1.2,
                                    fontSize: Utils.getScaledValue(context, 18),
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${holidayStartDate.year}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 3.0),
                                child: FaIcon(FontAwesomeIcons.tag,
                                  size: 14,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: CustomTextContainer(
                                  textKey: widget.holiday.title ?? "",
                                  style: TextStyle(
                                    height: 1.2,
                                    fontSize: Utils.getScaledValue(context, 16),
                                    color: isDark
                                        ? Colors.white
                                        : Colors.grey.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (widget.holiday.endDate != null)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                FaIcon(FontAwesomeIcons.calendar,
                                  size: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    holidayStartDate == holidayEndDate
                                        ? "1 hari"
                                        : "${holidayEndDate.difference(holidayStartDate).inDays + 1} hari (sampai ${holidayEndDate.day} ${Utils.getMonthFullName(holidayEndDate.month)})",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Lihat Detail',
                                style: TextStyle(
                                  color: maroonColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 10,
                                color: maroonColor,
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
        ).animate(target: _isHovered ? 1 : 0).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.01, 1.01),
            duration: 300.ms),
      ),
    );
  }
}

class HolidayDetailsBottomsheet extends StatelessWidget {
  final Holiday holiday;
  const HolidayDetailsBottomsheet({super.key, required this.holiday});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maroonColor = AppColorPalette.primaryMaroon;
    final titleColor = isDark ? Colors.white : AppColorPalette.primaryMaroon;
    final iconColor = isDark ? Colors.white70 : AppColorPalette.primaryMaroon;
    final holidayStartDate = DateTime.parse(holiday.startDate ?? "");
    final holidayEndDate = holiday.endDate != null
        ? DateTime.parse(holiday.endDate!)
        : holidayStartDate;

    final bool isMultiDayHoliday = holidayStartDate != holidayEndDate;

    return CustomBottomsheet(
      titleLabelKey: holidayKey,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.only(
          left: appContentHorizontalPadding,
          right: appContentHorizontalPadding,
          bottom: MediaQuery.of(context).padding.bottom +
              24, // Add safe area padding
        ),
        // Ensure we have a ConstrainedBox with unconstrained height for the scroll view
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height * 0.85, // Limit max height
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Use minimum size
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [maroonColor, AppColorPalette.secondaryMaroon],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              holidayStartDate.day.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              Utils.getMonthFullName(holidayStartDate.month),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${holidayStartDate.year}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMultiDayHoliday
                                  ? "${Utils.formatDate(holidayStartDate)} - ${Utils.formatDate(holidayEndDate)}"
                                  : Utils.formatDate(holidayStartDate),
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              holiday.title ?? "",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                                letterSpacing: 0.3,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark
                            ? AppColorPalette.secondaryMaroon
                            : Colors.grey[200]),
                  ),
                  if (isMultiDayHoliday)
                    Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FaIcon(FontAwesomeIcons.calendarDay,
                              size: 16,
                              color: iconColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    'Durasi: ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    '${holidayEndDate.difference(holidayStartDate).inDays + 1} hari',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white70 : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FaIcon(FontAwesomeIcons.circleInfo,
                        size: 16,
                        color: iconColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Detail Liburan:',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColorPalette.lightMaroon : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark
                              ? AppColorPalette.secondaryMaroon
                              : Colors.grey[200]!),
                    ),
                    child: CustomTextContainer(
                      textKey: holiday.description ?? "",
                      style: TextStyle(
                        height: 1.4,
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 100), // Extra padding at bottom
                ],
              ),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).moveY(
          begin: 20, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
    );
  }
}

