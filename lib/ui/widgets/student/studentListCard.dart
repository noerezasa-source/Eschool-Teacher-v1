import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/data/models/academic/sessionYear.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/data/models/student/studentDetails.dart';
import 'package:eschool_saas_staff/ui/widgets/system/profileImageContainer.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StudentListCard extends StatelessWidget {
  final StudentDetails studentDetails;
  final VoidCallback onTap;
  final ClassSection? classSection;
  final SessionYear? sessionYear;

  // Define theme colors
  static Color get maroonPrimary => AppColorPalette.primaryMaroon;
  static Color get maroonLight => AppColorPalette.secondaryMaroon;
  static Color get accentColor => AppColorPalette.lightMaroon;
  final Color cardColor = Colors.white;
  static const Color textDarkColor = Color(0xFF2D2D2D);
  static const Color textMediumColor = Color(0xFF717171);
  static const Color borderColor = Color(0xFFE8E8E8);

  const StudentListCard({super.key, 
    required this.studentDetails,
    required this.onTap,
    this.classSection,
    this.sessionYear,
  });

  // Helper method to build info columns
  Widget _buildInfoColumn({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: textDarkColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'Poppins',
              color: textMediumColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  bool _isRTLEnabled(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Status indicator strip
            if (studentDetails.isActive())
              Positioned(
                top: 0,
                left: 0,
                bottom: 0,
                child: Container(
                  width: 8,
                  decoration: BoxDecoration(
                    color: maroonPrimary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
              )
            else
              Positioned(
                top: 0,
                left: 0,
                bottom: 0,
                child: Container(
                  width: 8,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
              ),

            // Main content
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                children: [
                  // Header section with profile image and name
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: borderColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Hero(
                          tag: "student_profile_${studentDetails.id}",
                          child: Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: maroonPrimary.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32.5),
                              child: ProfileImageContainer.circular(
                                imageUrl: studentDetails.image ?? "",
                                size: 65,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: studentDetails.isActive()
                                            ? Colors.green.withValues(alpha: 0.1)
                                            : Colors.grey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: studentDetails.isActive()
                                              ? Colors.green.withValues(alpha: 0.6)
                                              : Colors.grey.withValues(alpha: 0.6),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            studentDetails.isActive()
                                                ? Icons.check_circle_outline
                                                : Icons.cancel_outlined,
                                            color: studentDetails.isActive()
                                                ? Colors.green
                                                : Colors.grey,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              studentDetails.isActive()
                                                  ? activeKey.tr
                                                  : inactiveKey.tr,
                                              style: TextStyle(
                                                color: studentDetails.isActive()
                                                    ? Colors.green
                                                    : Colors.grey,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: studentDetails.gender
                                                    ?.toLowerCase() ==
                                                "male"
                                            ? const Color(
                                                0xFFDCEAFF) // Light blue background
                                            : const Color(
                                                0xFFFFE0F0), // Light pink background
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: studentDetails.gender
                                                      ?.toLowerCase() ==
                                                  "male"
                                              ? const Color(
                                                  0xFF0D47A1) // Darker blue border
                                              : const Color(
                                                  0xFFD81B60), // Darker pink border
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            studentDetails.gender
                                                        ?.toLowerCase() ==
                                                    "male"
                                                ? Icons.male_outlined
                                                : Icons.female_outlined,
                                            color: studentDetails.gender
                                                        ?.toLowerCase() ==
                                                    "male"
                                                ? const Color(
                                                    0xFF1976D2) // Strong blue for icon
                                                : const Color(
                                                    0xFFE91E63), // Strong pink for icon
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              studentDetails.getGender().tr,
                                              style: TextStyle(
                                                color: studentDetails.gender
                                                            ?.toLowerCase() ==
                                                        "male"
                                                    ? const Color(
                                                        0xFF1976D2) // Strong blue for text
                                                    : const Color(
                                                        0xFFE91E63), // Strong pink for text
                                                fontSize: 11,
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
                              const SizedBox(height: 6),
                              Text(
                                studentDetails.firstName ?? "-",
                                style: const TextStyle(
                                  fontSize: 17.0,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  color: textDarkColor,
                                ),
                                // No maxLines limit or ellipsis to allow full name display
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.badge_outlined,
                                    size: 14,
                                    color: textMediumColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "GR No : ${studentDetails.student?.admissionNo ?? '-'}",
                                    style: const TextStyle(
                                      color: textMediumColor,
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Information section
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoColumn(
                          icon: Icons.format_list_numbered,
                          iconColor: maroonPrimary,
                          label: rollNoKey.tr,
                          value:
                              studentDetails.student?.rollNumber?.toString() ??
                                  "-",
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: borderColor,
                        ),
                        _buildInfoColumn(
                          icon: Icons.school_outlined,
                          iconColor: Colors.blue,
                          label: classKey.tr,
                          value: classSection?.name ?? "-",
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: borderColor,
                        ),
                        _buildInfoColumn(
                          icon: Icons.calendar_today_outlined,
                          iconColor: Colors.orange,
                          label: "Tahun",
                          value: sessionYear?.name ?? "-",
                        ),
                      ],
                    ),
                  ),

                  // Action row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: maroonPrimary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Lihat profil lengkap",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: maroonPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: maroonPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isRTLEnabled(context)
                                ? CupertinoIcons.arrow_left
                                : CupertinoIcons.arrow_right,
                            size: 14,
                            color: Colors.white,
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
      ),
    );
  }
}

