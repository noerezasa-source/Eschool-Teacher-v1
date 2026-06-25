import 'package:eschool_saas_staff/data/models/system/holiday.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/ui/widgets/system/holidayContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math';

class HolidaysScreen extends StatefulWidget {
  final List<Holiday> holidays;
  const HolidaysScreen({super.key, required this.holidays});

  static Widget getRouteInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return HolidaysScreen(
      holidays: arguments['holidays'] as List<Holiday>,
    );
  }

  static Map<String, dynamic> buildArguments(
      {required List<Holiday> holidays}) {
    return {"holidays": List<Holiday>.from(holidays)};
  }

  @override
  State<HolidaysScreen> createState() => _HolidaysScreenState();
}



class _HolidaysScreenState extends State<HolidaysScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  List<Holiday> _filteredHolidays = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _controller.forward();
    _filteredHolidays = widget.holidays;
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.offset > 10 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 10 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, List<Holiday>> _groupHolidaysByMonth(List<Holiday> holidays) {
    final Map<String, List<Holiday>> grouped = {};

    // Sort holidays by startDate first
    final sortedHolidays = holidays.toList()
      ..sort((a, b) {
        final dateA = DateTime.parse(a.startDate ?? "");
        final dateB = DateTime.parse(b.startDate ?? "");
        return dateA.compareTo(dateB);
      });

    for (var holiday in sortedHolidays) {
      final dateTime = DateTime.parse(holiday.startDate ?? "");
      final monthYear =
          "${Utils.getMonthFullName(dateTime.month)} ${dateTime.year}";

      if (!grouped.containsKey(monthYear)) {
        grouped[monthYear] = [];
      }

      grouped[monthYear]!.add(holiday);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedHolidays = _groupHolidaysByMonth(_filteredHolidays);

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColorPalette.primaryMaroon,
              secondary: AppColorPalette.secondaryMaroon,
              surface: Colors.white,
            ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomModernAppBar(
          title: Utils.getTranslatedLabel(holidaysKey),
          icon: FontAwesomeIcons.calendarDays,
          fabAnimationController: _controller,
          primaryColor: AppColorPalette.primaryMaroon,
          lightColor: AppColorPalette.secondaryMaroon,
          onBackPressed: () => Navigator.of(context).pop(),
          height: 80,
        ),
        body: Stack(
          children: [
            // Enhanced Animated Background Pattern
            AnimatedPositioned(
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height,
              child: AnimatedOpacity(
                duration: const Duration(seconds: 1),
                opacity: 0.15,
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: BackgroundPatternPainter(
                        color: AppColorPalette.primaryMaroon,
                      ),
                    ),
                    // Decorative particles for modern look
                    ...List.generate(10, (index) {
                      return Positioned(
                        top: Random().nextDouble() *
                            MediaQuery.of(context).size.height,
                        left: Random().nextDouble() *
                            MediaQuery.of(context).size.width,
                        child: AnimatedContainer(
                          duration: Duration(seconds: 2 + index),
                          width: 4 + Random().nextDouble() * 8,
                          height: 4 + Random().nextDouble() * 8,
                          decoration: BoxDecoration(
                            color: AppColorPalette.primaryMaroon
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Main Content with Enhanced Animation
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - _controller.value) * 30),
                  child: Opacity(
                    opacity: _controller.value,
                    child: Column(
                      children: [
                        // Holiday List
                        Expanded(
                          child: _filteredHolidays.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FaIcon(FontAwesomeIcons.calendarXmark,
                                        size: 60,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ).animate().fadeIn(delay: 300.ms)
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: EdgeInsets.fromLTRB(
                                      appContentHorizontalPadding,
                                      8,
                                      appContentHorizontalPadding,
                                      30),
                                  itemCount: groupedHolidays.length,
                                  itemBuilder: (context, index) {
                                    final monthYear =
                                        groupedHolidays.keys.elementAt(index);
                                    final holidays =
                                        groupedHolidays[monthYear]!;

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 16, bottom: 12, left: 6),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: AppColorPalette
                                                      .primaryMaroon,
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                ),
                                                child: Text(
                                                  monthYear,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Divider(
                                                  height: 20,
                                                  thickness: 1,
                                                  indent: 14,
                                                  endIndent: 8,
                                                  color: Colors.grey[200],
                                                ),
                                              ),
                                              Text(
                                                '${holidays.length} hari',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ...List.generate(
                                          holidays.length,
                                          (i) => HolidayContainer(
                                            holiday: holidays[i],
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            margin: const EdgeInsetsDirectional
                                                .only(bottom: 16),
                                          )
                                              .animate(delay: (50 * i).ms)
                                              .fadeIn(duration: 400.ms)
                                              .slideY(
                                                  begin: 0.1,
                                                  end: 0,
                                                  duration: 400.ms,
                                                  curve: Curves.easeOutQuad),
                                        ),
                                      ],
                                    )
                                        .animate(delay: (100 * index).ms)
                                        .fadeIn(duration: 400.ms);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  final Color color;

  BackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Main wave
    final path = Path()
      ..moveTo(0, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.05,
        size.width * 0.5,
        size.height * 0.15,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.25,
        size.width,
        size.height * 0.2,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);

    // Secondary decorative waves
    final path2 = Path()
      ..moveTo(0, size.height * 0.45)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.4,
        size.width * 0.6,
        size.height * 0.55,
        size.width,
        size.height * 0.47,
      )
      ..lineTo(size.width, size.height * 0.45)
      ..lineTo(0, size.height * 0.45)
      ..close();

    canvas.drawPath(
      path2,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

