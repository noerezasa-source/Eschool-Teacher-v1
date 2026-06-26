import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';

class TimetableSlotContainer extends StatelessWidget {
  final String startTime;
  final String endTime;
  final String subjectName;
  final bool isForClass;
  final String? teacherName;
  final String note;
  final String? classSectionName;
  final Color? backgroundColor;
  final bool isActive;

  const TimetableSlotContainer(
      {super.key,
      required this.startTime,
      required this.endTime,
      required this.subjectName,
      required this.isForClass,
      required this.note,
      this.classSectionName,
      this.teacherName,
      this.backgroundColor,
      this.isActive = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color cardBg;
    if (isActive) {
      cardBg = Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08);
    } else if (backgroundColor != null) {
      cardBg = backgroundColor!;
    } else {
      cardBg = Theme.of(context).colorScheme.surface;
    }

    final cardBorderColor = isActive
        ? Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.45 : 0.3)
        : (isDark ? Colors.white12 : Colors.grey.shade200);

    final titleTextStyle = TextStyle(
      color: isDark ? Colors.white70 : Theme.of(context).colorScheme.secondary,
      fontSize: Utils.getScaledValue(context, 12),
    );
    final valueTextStyle = TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: Utils.getScaledValue(context, 15),
        fontWeight: FontWeight.w600);
    return Container(
      margin: const EdgeInsets.only(top: 10.0, bottom: 10.0),
      height: Utils().getResponsiveHeight(context, 150),
      child: LayoutBuilder(builder: (context, boxConstraints) {
        return Row(
          children: [
            SizedBox(
                width: boxConstraints.maxWidth * (0.2),
                child: Column(
                  children: [
                    CustomTextContainer(
                      textKey: (startTime).isEmpty
                          ? "-"
                          : Utils.formatTime(
                              timeOfDay: TimeOfDay(
                                  hour: Utils.getHourFromTimeDetails(
                                      time: startTime),
                                  minute: Utils.getMinuteFromTimeDetails(
                                      time: startTime)),
                              context: context),
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: Utils.getScaledValue(context, 15),
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Text(Utils.getTimezoneLabel(),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: Utils.getScaledValue(context, 12),
                        )),
                    const Spacer(),
                    Container(
                      height: Utils().getResponsiveHeight(context, 65),
                      width: Utils.getScaledValue(context, 1.5),
                      color: isDark ? Colors.white24 : Theme.of(context).colorScheme.tertiary,
                    ),
                    const Spacer(),
                    CustomTextContainer(
                      textKey: (endTime).isEmpty
                          ? "-"
                          : Utils.formatTime(
                              timeOfDay: TimeOfDay(
                                  hour: Utils.getHourFromTimeDetails(
                                      time: endTime),
                                  minute: Utils.getMinuteFromTimeDetails(
                                      time: endTime)),
                              context: context),
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: Utils.getScaledValue(context, 15.0),
                          fontWeight: FontWeight.bold),
                    ),
                    Text(Utils.getTimezoneLabel(),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: Utils.getScaledValue(context, 12.0),
                        )),
                  ],
                )),
            SizedBox(
              width: boxConstraints.maxWidth * (0.05),
            ),
            SizedBox(
              width: boxConstraints.maxWidth * (0.7),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    border: Border.all(color: cardBorderColor),
                    borderRadius: BorderRadius.circular(8),
                    color: cardBg),
                child: Row(
                  children: [
                    if (isActive)
                      Container(
                        width: 4,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: appContentHorizontalPadding, vertical: 10),
                        child: Stack(
                          children: [
                            note.isNotEmpty
                                ? Center(
                                    child: CustomTextContainer(
                                      textKey: note.toLowerCase() == "break"
                                          ? "istirahat"
                                          : note,
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ///[Subject name]
                                      CustomTextContainer(
                                        textKey: subjectKey,
                                        style: titleTextStyle,
                                      ),
                                      CustomTextContainer(
                                        textKey: subjectName,
                                        style: valueTextStyle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),

                                      ///[Class and teacher name]
                                      CustomTextContainer(
                                        textKey: isForClass ? teacherKey : classKey,
                                        style: titleTextStyle,
                                      ),
                                      CustomTextContainer(
                                        textKey: isForClass
                                            ? (teacherName ?? "-")
                                            : (classSectionName ?? "-"),
                                        style: valueTextStyle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                            if (isActive)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    Utils.getTranslatedLabel(onGoingKey),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: Utils.getScaledValue(context, 8.5),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          ],
        );
      }),
    );
  }
}

