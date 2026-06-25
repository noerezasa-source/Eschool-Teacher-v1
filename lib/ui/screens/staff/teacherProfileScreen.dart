import 'package:eschool_saas_staff/data/models/auth/userDetails.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/profileImageContainer.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/route_manager.dart';
import 'package:intl/intl.dart';

class TeacherProfileScreen extends StatefulWidget {
  final UserDetails teacher;
  const TeacherProfileScreen({super.key, required this.teacher});

  static Widget getRouteInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return TeacherProfileScreen(
      teacher: arguments['teacher'] as UserDetails,
    );
  }

  static Map<String, dynamic> buildArguments(
      {required UserDetails userDetails}) {
    return {"teacher": userDetails};
  }

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Color get primaryMaroonColor => AppColorPalette.primaryMaroon;
  Color get lightMaroonColor => AppColorPalette.secondaryMaroon;

  // Kamus terjemahan Bahasa Indonesia
  final Map<String, String> _translations = {
    joiningDateKey: "Tanggal Bergabung",
    emailKey: "Email",
    phoneKey: "Nomor Telepon",
    dateOfBirthKey: "Tanggal Lahir",
    genderKey: "Jenis Kelamin",
    qualificationKey: "Kualifikasi",
    salaryKey: "Gaji",
    teacherDetailsKey: "Detail Pengajar",
    activeKey: "Aktif",
    inactiveKey: "Tidak Aktif",
    teacherProfileKey: "Profil Pengajar"
  };

  // Map untuk ikon yang sesuai dengan setiap jenis data
  final Map<String, IconData> _detailIcons = {
    joiningDateKey: Icons.calendar_month_rounded,
    emailKey: Icons.email_rounded,
    phoneKey: Icons.phone_android_rounded,
    dateOfBirthKey: Icons.cake_rounded,
    genderKey: Icons.person_rounded,
    qualificationKey: Icons.school_rounded,
    salaryKey: Icons.payments_rounded,
  };

  // Fungsi untuk menerjemahkan label ke Bahasa Indonesia
  String _getIndonesianTitle(String titleKey) {
    // Menghapus "Key" dari akhir string jika ada
    String key = titleKey;
    if (titleKey.endsWith('Key')) {
      key = titleKey.substring(0, titleKey.length - 3);
    }

    return _translations[key] ?? titleKey;
  }

  // Fungsi untuk memformat gaji dengan titik pemisah ribuan dan mata uang rupiah
  String _formatSalary(double? salary) {
    if (salary == null) return "-";

    // Menggunakan NumberFormat untuk format Indonesia dengan titik sebagai pemisah ribuan
    final formatter = NumberFormat("#,##0", "id_ID");
    String formattedNumber = formatter.format(salary.toInt());

    // Mengganti koma dengan titik untuk format Indonesia
    formattedNumber = formattedNumber.replaceAll(',', '.');

    return 'Rp $formattedNumber';
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  ///[To show modern contact buttons]
  Widget _buildContactButton({
    required BuildContext context,
    required IconData iconData,
    required String label,
    required Color backgroundColor,
    required Function onTap,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => onTap.call(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          backgroundColor,
                          backgroundColor.withValues(alpha: 0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: backgroundColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      iconData,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: primaryMaroonColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 200.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildTeacherDetailCard(
      {required String titleKey,
      required String valueKey,
      IconData? icon,
      Widget? actionWidget}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryMaroonColor.withValues(alpha: 0.12),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.7),
            blurRadius: 8,
            offset: const Offset(-3, -3),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF8F4F6),
          ],
        ),
        border: Border.all(
          color: primaryMaroonColor.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              bottom: -15,
              child: Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryMaroonColor.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  if (icon != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryMaroonColor.withValues(alpha: 0.8),
                            primaryMaroonColor,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryMaroonColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      margin: const EdgeInsets.only(right: 14),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getIndonesianTitle(titleKey),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: primaryMaroonColor.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          valueKey,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryMaroonColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (actionWidget != null) ...[
                    const SizedBox(width: 12),
                    actionWidget,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: 100.ms)
        .fadeIn(duration: 500.ms)
        .slideX(begin: -0.2, end: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F7),
      body: Stack(
        children: [
          // Main content
          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: Utils.appContentTopScrollPadding(context: context) + 40,
              ),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Teacher Profile Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryMaroonColor.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Decorative header
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                primaryMaroonColor.withValues(alpha: 0.7),
                                primaryMaroonColor.withValues(alpha: 0.9),
                                primaryMaroonColor,
                                primaryMaroonColor.withValues(alpha: 0.9),
                                primaryMaroonColor.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                        ),
                        // Content padding
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Profile image with tap to zoom
                                  GestureDetector(
                                    onTap: () {
                                      final profileImage =
                                          widget.teacher.image ?? "";
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            backgroundColor: Colors.transparent,
                                            child: SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.9,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.7,
                                              child: Stack(
                                                children: [
                                                  InteractiveViewer(
                                                    minScale: 0.5,
                                                    maxScale: 4.0,
                                                    child: profileImage
                                                            .isNotEmpty
                                                        ? CachedNetworkImage(
                                                            imageUrl:
                                                                profileImage,
                                                            fit: BoxFit.contain,
                                                            placeholder:
                                                                (context,
                                                                        url) =>
                                                                    Center(
                                                              child:
                                                                  CircularProgressIndicator(
                                                                valueColor:
                                                                    AlwaysStoppedAnimation<
                                                                            Color>(
                                                                        primaryMaroonColor),
                                                              ),
                                                            ),
                                                            errorWidget:
                                                                (context, url,
                                                                        error) =>
                                                                    Center(
                                                              child: Icon(
                                                                Icons.error,
                                                                color:
                                                                    primaryMaroonColor,
                                                                size: 50,
                                                              ),
                                                            ),
                                                          )
                                                        : Center(
                                                            child: Icon(
                                                              Icons.person,
                                                              color:
                                                                  primaryMaroonColor,
                                                              size: 100,
                                                            ),
                                                          ),
                                                  ),
                                                  Positioned(
                                                    top: 10,
                                                    right: 10,
                                                    child: Material(
                                                      color: Colors.black
                                                          .withValues(alpha: 0.5),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        onTap: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child: Container(
                                                          width: 40,
                                                          height: 40,
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
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
                                    child: Hero(
                                      tag: 'teacher_image_${widget.teacher.id}',
                                      child: Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: primaryMaroonColor
                                                .withValues(alpha: 0.2),
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryMaroonColor
                                                  .withValues(alpha: 0.15),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: ProfileImageContainer(
                                            imageUrl:
                                                widget.teacher.image ?? "",
                                          ),
                                        ),
                                      ),
                                    ).animate().scale(
                                          begin: const Offset(0.9, 0.9),
                                          end: const Offset(1, 1),
                                          duration: 500.ms,
                                        ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ShaderMask(
                                          shaderCallback: (bounds) =>
                                              LinearGradient(
                                            colors: [
                                              primaryMaroonColor,
                                              const Color(0xFFAA3855),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ).createShader(bounds),
                                          child: Text(
                                            widget.teacher.firstName ?? "",
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: widget.teacher.isActive()
                                                    ? Colors.green
                                                        .withValues(alpha: 0.1)
                                                    : Colors.red
                                                        .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    widget.teacher.isActive()
                                                        ? Icons.check_circle
                                                        : Icons.cancel,
                                                    color: widget.teacher
                                                            .isActive()
                                                        ? Colors.green
                                                        : Colors.red,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    widget.teacher.isActive()
                                                        ? _getIndonesianTitle(
                                                            activeKey)
                                                        : _getIndonesianTitle(
                                                            inactiveKey),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: widget.teacher
                                                              .isActive()
                                                          ? Colors.green
                                                          : Colors.red,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.school,
                                              size: 16,
                                              color: primaryMaroonColor
                                                  .withValues(alpha: 0.7),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                widget.teacher.staff
                                                        ?.qualification ??
                                                    "-",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.black87,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                      .animate()
                                      .fadeIn(duration: 300.ms)
                                      .slideX(begin: 0.1, end: 0),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contact Buttons
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryMaroonColor.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Decorative header
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                lightMaroonColor.withValues(alpha: 0.7),
                                lightMaroonColor.withValues(alpha: 0.9),
                                lightMaroonColor,
                                lightMaroonColor.withValues(alpha: 0.9),
                                lightMaroonColor.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 4),
                          child: Text(
                            "Kontak Pengajar",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: lightMaroonColor,
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Row(
                            children: [
                              _buildContactButton(
                                context: context,
                                iconData: Icons.email_outlined,
                                label: _getIndonesianTitle(emailKey),
                                backgroundColor: primaryMaroonColor,
                                onTap: () {
                                  Utils.launchEmailLog(
                                      context: context,
                                      email: widget.teacher.email ?? "");
                                },
                              ),
                              _buildContactButton(
                                context: context,
                                iconData: Icons.call,
                                label: _getIndonesianTitle(phoneKey),
                                backgroundColor: lightMaroonColor,
                                onTap: () {
                                  Utils.launchCallLog(
                                      context: context,
                                      mobile: widget.teacher.mobile ?? "");
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Teacher Details Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryMaroonColor.withValues(alpha: 0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      primaryMaroonColor.withValues(alpha: 0.9),
                                      primaryMaroonColor,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          primaryMaroonColor.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_pin,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ).animate().scale(
                                    begin: const Offset(0.8, 0.8),
                                    end: const Offset(1.0, 1.0),
                                    duration: 400.ms,
                                  ),
                              const SizedBox(width: 12),
                              Text(
                                _getIndonesianTitle(teacherDetailsKey),
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: primaryMaroonColor,
                                ),
                              )
                                  .animate()
                                  .fadeIn(duration: 400.ms)
                                  .slideX(begin: 0.2, end: 0),
                            ],
                          ),
                        ),
                        Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                primaryMaroonColor.withValues(alpha: 0.05),
                                primaryMaroonColor.withValues(alpha: 0.3),
                                primaryMaroonColor.withValues(alpha: 0.5),
                                primaryMaroonColor.withValues(alpha: 0.3),
                                primaryMaroonColor.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 800.ms)
                            .slideX(begin: -0.1, end: 0),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildTeacherDetailCard(
                                titleKey: joiningDateKey,
                                valueKey: Utils.formatDate(
                                    DateTime.parse(widget.teacher.createdAt!)),
                                icon: _detailIcons[joiningDateKey],
                              ),
                              _buildTeacherDetailCard(
                                titleKey: emailKey,
                                valueKey: widget.teacher.email ?? "-",
                                icon: _detailIcons[emailKey],
                                actionWidget: (widget.teacher.email != null &&
                                        widget.teacher.email!.isNotEmpty &&
                                        widget.teacher.email! != "-")
                                    ? InkWell(
                                        onTap: () {
                                          final email = widget.teacher.email!;
                                          Clipboard.setData(
                                              ClipboardData(text: email));
                                          ScaffoldMessenger.of(context)
                                              .removeCurrentSnackBar();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: const Text(
                                                'Email disalin ke clipboard'),
                                            backgroundColor: primaryMaroonColor,
                                            duration: const Duration(seconds: 2),
                                          ));
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: primaryMaroonColor
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.copy,
                                            size: 18,
                                            color: primaryMaroonColor,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              _buildTeacherDetailCard(
                                titleKey: phoneKey,
                                valueKey: widget.teacher.mobile ?? "-",
                                icon: _detailIcons[phoneKey],
                                actionWidget: (widget.teacher.mobile != null &&
                                        widget.teacher.mobile!.isNotEmpty &&
                                        widget.teacher.mobile! != "-")
                                    ? InkWell(
                                        onTap: () {
                                          final mobile = widget.teacher.mobile!;
                                          Clipboard.setData(
                                              ClipboardData(text: mobile));
                                          ScaffoldMessenger.of(context)
                                              .removeCurrentSnackBar();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: const Text(
                                                'Nomor telepon disalin ke clipboard'),
                                            backgroundColor: primaryMaroonColor,
                                            duration: const Duration(seconds: 2),
                                          ));
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: lightMaroonColor
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.copy,
                                            size: 18,
                                            color: lightMaroonColor,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              _buildTeacherDetailCard(
                                titleKey: dateOfBirthKey,
                                valueKey: (widget.teacher.dob ?? "").isEmpty
                                    ? "-"
                                    : Utils.formatDate(
                                        DateTime.parse(widget.teacher.dob!)),
                                icon: _detailIcons[dateOfBirthKey],
                              ),
                              _buildTeacherDetailCard(
                                titleKey: genderKey,
                                valueKey: widget.teacher.getGender(),
                                icon: _detailIcons[genderKey],
                              ),
                              _buildTeacherDetailCard(
                                titleKey: qualificationKey,
                                valueKey:
                                    widget.teacher.staff?.qualification ?? "-",
                                icon: _detailIcons[qualificationKey],
                              ),
                              _buildTeacherDetailCard(
                                titleKey: salaryKey,
                                valueKey:
                                    _formatSalary(widget.teacher.staff?.salary),
                                icon: _detailIcons[salaryKey],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // Custom Modern AppBar
          Align(
            alignment: Alignment.topCenter,
            child: CustomModernAppBar(
              title: _getIndonesianTitle(teacherProfileKey),
              icon: Icons.person,
              fabAnimationController: _animationController,
              onBackPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
