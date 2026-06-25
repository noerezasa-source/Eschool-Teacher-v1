import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool_saas_staff/data/models/academic/classSection.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/data/models/academic/sessionYear.dart';
import 'package:eschool_saas_staff/data/models/student/studentDetails.dart';
import 'package:eschool_saas_staff/ui/widgets/system/profileImageContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customFilterModernAppbar.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StudentProfileScreen extends StatefulWidget {
  final StudentDetails studentDetails;
  final SessionYear sessionYear;
  final ClassSection classSection;
  const StudentProfileScreen({
    super.key,
    required this.studentDetails,
    required this.sessionYear,
    required this.classSection,
  });

  static Widget getRouteInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return StudentProfileScreen(
      classSection: arguments['classSection'],
      sessionYear: arguments['sessionYear'],
      studentDetails: arguments['studentDetails'],
    );
  }

  static Map<String, dynamic> buildArguments({
    required StudentDetails studentDetails,
    required SessionYear sessionYear,
    required ClassSection classSection,
  }) {
    return {
      "classSection": classSection,
      "studentDetails": studentDetails,
      "sessionYear": sessionYear
    };
  }

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {

  Widget _buildIcon(dynamic icon, {required Color color, double? size, List<Shadow>? shadows}) {
    if (icon is FaIconData) {
      return FaIcon(icon, color: color, size: size, shadows: shadows);
    }
    if (icon is IconData) {
      return Icon(icon, color: color, size: size, shadows: shadows);
    }
    if (icon is Widget) {
      return icon;
    }
    return const SizedBox();
  }

  late String _selectedTabTitleKey = generalKey;
  final ScrollController _scrollController = ScrollController();

  // Define theme colors with simplified palette
  static Color get maroonPrimary => AppColorPalette.primaryMaroon;
  static Color get maroonLight => AppColorPalette.secondaryMaroon;
  static Color get accentColor => AppColorPalette.lightMaroon;
  static Color get bgColor => AppColorPalette.accentPink;
  final Color cardColor = Colors.white;
  static const Color textDarkColor = Color(0xFF2D2D2D);
  static const Color textMediumColor = Color(0xFF717171);
  static const Color borderColor = Color(0xFFE8E8E8);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void changeTab(String value) {
    if (_selectedTabTitleKey == value) return;

    setState(() {
      _selectedTabTitleKey = value;
    });
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.green.shade300 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade500,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            isActive ? activeKey.tr : inactiveKey.tr,
            style: TextStyle(
              color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentDetailsTitleAndValueContainer({
    required String titleKey,
    required String valueKey,
    bool isHighlighted = false,
    dynamic icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      decoration: BoxDecoration(
        color:
            isHighlighted ? maroonPrimary.withValues(alpha: 0.08) : cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isHighlighted ? 0.08 : 0.05),
            blurRadius: isHighlighted ? 12 : 8,
            offset: Offset(0, isHighlighted ? 4 : 3),
            spreadRadius: 0,
          ),
        ],
        border: isHighlighted
            ? Border.all(color: maroonPrimary.withValues(alpha: 0.2))
            : Border.all(color: borderColor.withValues(alpha: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? maroonPrimary.withValues(alpha: 0.15)
                    : accentColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _buildIcon(
                icon,
                size: 18,
                color: isHighlighted ? maroonPrimary : maroonLight,
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleKey.tr,
                  style: const TextStyle(
                    color: textMediumColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valueKey.tr,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: isHighlighted ? maroonPrimary : textDarkColor,
                    fontFamily: 'Poppins',
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianDetails() {
    final guardian = widget.studentDetails.student?.guardian;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          child: Column(
            children: [
              Row(
                children: [
                  // Guardian profile image with tap to zoom
                  GestureDetector(
                    onTap: () {
                      final profileImage = guardian?.image ?? "";
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            backgroundColor: Colors.transparent,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.9,
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: Stack(
                                children: [
                                  InteractiveViewer(
                                    minScale: 0.5,
                                    maxScale: 4.0,
                                    child: profileImage.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: profileImage,
                                            fit: BoxFit.contain,
                                            placeholder: (context, url) =>
                                                Center(
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(maroonPrimary),
                                              ),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Center(
                                              child: Icon(
                                                Icons.error,
                                                color: maroonPrimary,
                                                size: 50,
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Icon(
                                              Icons.person,
                                              color: maroonPrimary,
                                              size: 100,
                                            ),
                                          ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Material(
                                      color:
                                          Colors.black.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(20),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: _buildProfileImage(
                      imageUrl: guardian?.image ?? "",
                      nameInitials: guardian?.firstName?.isNotEmpty == true
                          ? guardian!.firstName!.substring(0, 1).toUpperCase()
                          : "G",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guardian?.firstName ?? "-",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textDarkColor,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildBadge(guardianKey.tr),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildInfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Email row: tappable to open mail app
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                decoration: BoxDecoration(
                  color: maroonPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                  border:
                      Border.all(color: maroonPrimary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: maroonPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FaIcon(FontAwesomeIcons.envelope,
                        size: 18,
                        color: maroonPrimary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            emailKey.tr,
                            style: const TextStyle(
                              color: textMediumColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: (guardian?.email ?? "").isNotEmpty &&
                                    (guardian?.email ?? "-") != "-"
                                ? () {
                                    final email = guardian!.email!;
                                    Utils.openLinkInBrowser(
                                        url: 'mailto:$email', context: context);
                                  }
                                : null,
                            child: Text(
                              guardian?.email ?? "-",
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                                color: guardian?.email != null &&
                                        guardian!.email!.isNotEmpty &&
                                        guardian.email! != "-"
                                    ? maroonPrimary
                                    : textDarkColor,
                                fontFamily: 'Poppins',
                                letterSpacing: 0.2,
                                decoration: guardian?.email != null &&
                                        guardian!.email!.isNotEmpty &&
                                        guardian.email! != "-"
                                    ? TextDecoration.underline
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // no phone icon next to email
                  ],
                ),
              ),
              _buildStudentDetailsTitleAndValueContainer(
                titleKey: genderKey,
                valueKey: guardian?.getGender() ?? "-",
                icon: (guardian?.getGender() ?? "").toLowerCase() == "female"
                    ? FontAwesomeIcons.venus
                    : FontAwesomeIcons.mars,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildInfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: maroonPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(FontAwesomeIcons.phoneVolume,
                      size: 20,
                      color: maroonPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Kontak Wali",
                          style: TextStyle(
                            fontSize: 13,
                            color: textMediumColor,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          guardian?.mobile ?? "-",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textDarkColor,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCallButton(guardian?.mobile ?? "-"),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentGeneralDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          child: Column(
            children: [
              Row(
                children: [
                  // Profile image with tap to zoom
                  GestureDetector(
                    onTap: () {
                      final profileImage = widget.studentDetails.image ?? "";
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            backgroundColor: Colors.transparent,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.9,
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: Stack(
                                children: [
                                  InteractiveViewer(
                                    minScale: 0.5,
                                    maxScale: 4.0,
                                    child: profileImage.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: profileImage,
                                            fit: BoxFit.contain,
                                            placeholder: (context, url) =>
                                                Center(
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(maroonPrimary),
                                              ),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Center(
                                              child: Icon(
                                                Icons.error,
                                                color: maroonPrimary,
                                                size: 50,
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Icon(
                                              Icons.person,
                                              color: maroonPrimary,
                                              size: 100,
                                            ),
                                          ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Material(
                                      color:
                                          Colors.black.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(20),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: _buildProfileImage(
                      imageUrl: widget.studentDetails.image ?? "",
                      nameInitials:
                          widget.studentDetails.firstName?.isNotEmpty == true
                              ? widget.studentDetails.firstName!
                                  .substring(0, 1)
                                  .toUpperCase()
                              : "S",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.studentDetails.firstName ?? "-",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textDarkColor,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildStatusBadge(widget.studentDetails.isActive()),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Admission / registration number with copy-to-clipboard
                        Builder(builder: (context) {
                          final admissionNo =
                              widget.studentDetails.student?.admissionNo ?? '-';
                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "No. Pendaftaran: $admissionNo",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: textMediumColor,
                                    fontFamily: 'Poppins',
                                  ),
                                  // Ensure full text is visible/wraps
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                ),
                              ),
                              if (admissionNo != '-')
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: InkWell(
                                    onTap: () {
                                      Clipboard.setData(
                                          ClipboardData(text: admissionNo));
                                      ScaffoldMessenger.of(context)
                                          .removeCurrentSnackBar();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: const Text(
                                            'No. Pendaftaran disalin ke clipboard'),
                                        backgroundColor: maroonPrimary,
                                        duration: const Duration(seconds: 2),
                                      ));
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: maroonPrimary.withValues(
                                            alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.copy,
                                        size: 18,
                                        color: maroonPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildInfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: maroonPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(FontAwesomeIcons.phoneVolume,
                      size: 20,
                      color: maroonPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emergencyContactKey.tr,
                          style: const TextStyle(
                            fontSize: 13,
                            color: textMediumColor,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          widget.studentDetails.mobile ?? "-",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textDarkColor,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCallButton(widget.studentDetails.mobile ?? "-"),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildInfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Informasi Siswa"),
              const Divider(color: borderColor, thickness: 1),
              const SizedBox(height: 12),
              _buildStudentDetailsTitleAndValueContainer(
                titleKey: sessionYearKey,
                valueKey: widget.sessionYear.name ?? "-",
                isHighlighted: true,
                icon: FontAwesomeIcons.calendarDays,
              ),
              _buildStudentDetailsTitleAndValueContainer(
                titleKey: admissionDateKey,
                valueKey:
                    (widget.studentDetails.student?.admissionDate ?? "").isEmpty
                        ? "-"
                        : Utils.formatDate(DateTime.parse(
                            widget.studentDetails.student!.admissionDate!)),
                icon: FontAwesomeIcons.calendar,
              ),
              _buildStudentDetailsTitleAndValueContainer(
                titleKey: classSectionKey,
                valueKey: widget.classSection.name ?? "-",
                isHighlighted: true,
                icon: FontAwesomeIcons.graduationCap,
              ),
              _buildStudentDetailsTitleAndValueContainer(
                titleKey: rollNoKey,
                valueKey:
                    widget.studentDetails.student?.rollNumber?.toString() ??
                        "-",
                icon: FontAwesomeIcons.idCard,
              ),
              _buildStudentDetailsTitleAndValueContainer(
                titleKey: genderKey,
                valueKey: widget.studentDetails.getGender(),
                icon:
                    widget.studentDetails.getGender().toLowerCase() == "female"
                        ? FontAwesomeIcons.venus
                        : FontAwesomeIcons.mars,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            maroonPrimary,
            maroonLight,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: maroonPrimary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildProfileImage(
      {required String imageUrl, required String nameInitials}) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [maroonPrimary, maroonLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: maroonPrimary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: imageUrl.isEmpty
              ? Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [maroonLight, maroonPrimary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      nameInitials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : ProfileImageContainer.circular(
                  imageUrl: imageUrl,
                  size: 70,
                ),
        ),
      ),
    );
  }

  Widget _buildCallButton(String phoneNumber) {
    if (phoneNumber.isEmpty || phoneNumber == "-") {
      return const SizedBox(width: 0);
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: () => Utils.launchCallLog(context: context, mobile: phoneNumber),
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [maroonLight, maroonPrimary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: maroonPrimary.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.call,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  // Tab button removed - now using AppBar filter items instead

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: CustomFilterModernAppBar(
        title: studentProfileKey.tr,
        primaryColor: maroonPrimary,
        secondaryColor: maroonLight,
        titleIcon: Icons.person,
        onBackPressed: () => Navigator.of(context).pop(),
        showFiltersRow: true,
        height:
            200, // Increased height of the AppBar to create more spacing between title and filters
        firstFilterItem: FilterItemConfig(
          title: _selectedTabTitleKey == generalKey
              ? "${generalKey.tr} ✓"
              : generalKey.tr,
          icon: _selectedTabTitleKey == generalKey
              ? Icons.person_rounded
              : Icons.person_outline_rounded,
          onTap: () => changeTab(generalKey),
        ),
        secondFilterItem: FilterItemConfig(
          title: _selectedTabTitleKey == guardianKey
              ? "${guardianKey.tr} ✓"
              : guardianKey.tr,
          icon: _selectedTabTitleKey == guardianKey
              ? Icons.family_restroom
              : Icons.family_restroom_outlined,
          onTap: () => changeTab(guardianKey),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgColor,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            bottom: 32,
            top: 20, // Increased top padding for better spacing from the AppBar
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content based on selected tab
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _selectedTabTitleKey == generalKey
                      ? _buildStudentGeneralDetails()
                      : _buildGuardianDetails(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: maroonPrimary,
        fontFamily: 'Poppins',
      ),
    );
  }
}

