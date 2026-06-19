import 'package:eschool_saas_staff/app/routes.dart';
import 'package:eschool_saas_staff/cubits/teacherAcademics/assignmentSubmissions/assignmentSubmissionsCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/assignment.dart';
import 'package:eschool_saas_staff/data/models/academic/assignmentSubmission.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/teacherEditAssignmentSubmission.dart';
import 'package:eschool_saas_staff/ui/screens/teacherAcademics/widgets/customExpandableContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customImageWidget.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/errorContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/skeleton/skeleton_widgets.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class TeacherManageAssignmentSubmissionScreen extends StatefulWidget {
  final Assignment assignment;

  static Widget getRouteInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return BlocProvider(
      create: (context) => AssignmentSubmissionsCubit(),
      child: TeacherManageAssignmentSubmissionScreen(
        assignment: arguments['assignment'],
      ),
    );
  }

  static Map<String, dynamic> buildArguments({required Assignment assignment}) {
    return {"assignment": assignment};
  }

  const TeacherManageAssignmentSubmissionScreen(
      {super.key, required this.assignment});

  @override
  State<TeacherManageAssignmentSubmissionScreen> createState() =>
      _TeacherManageAssignmentSubmissionScreenState();
}

class _TeacherManageAssignmentSubmissionScreenState
    extends State<TeacherManageAssignmentSubmissionScreen>
    with TickerProviderStateMixin {
  AssignmentSubmissionStatus selectedAssignmentSubmissionFilterStatus =
      allAssignmentSubmissionStatus.first;

  // Animation controllers
  late AnimationController _fabAnimationController;
  late AnimationController _containerAnimationController;

  @override
  void initState() {
    // Initialize animation controllers
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _containerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    Future.delayed(Duration.zero, () {
      fetchAssignmentSubmissions();
      _containerAnimationController.forward();
    });
    super.initState();
  }

  void fetchAssignmentSubmissions() {
    context
        .read<AssignmentSubmissionsCubit>()
        .fetchAssignmentSubmissions(assignmentId: widget.assignment.id);
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _containerAnimationController.dispose();
    super.dispose();
  }

  Widget _buildAssignmentSubmissionItem(
      {required AssignmentSubmission assignmentSubmission}) {
    final AssignmentSubmissionStatus status =
        Utils.getAssignmentSubmissionStatusFromTypeId(
            typeId: assignmentSubmission.status);

    // Menentukan warna status dengan gradasi yang lebih menarik
    final List<Color> statusGradient = _getStatusGradient(status.color);

    // Menentukan warna border card berdasarkan status submission
    Color borderColor = const Color(0xFFEADADA);
    Color highlightColor = Colors.transparent;
    double borderWidth = 1.0;

    // Customize border for different statuses
    if (status.typeStatusId == 1) {
      // Submitted
      borderColor = const Color(0xFF6A1B31).withValues(alpha: 0.3);
      highlightColor = const Color(0xFF6A1B31).withValues(alpha: 0.03);
      borderWidth = 1.5;
    } else if (status.typeStatusId == 2) {
      // Evaluated
      borderColor = const Color(0xFF9A4156).withValues(alpha: 0.3);
      highlightColor = const Color(0xFF9A4156).withValues(alpha: 0.03);
      borderWidth = 1.5;
    } else if (status.typeStatusId == 3) {
      // Resubmission Request
      borderColor = const Color(0xFFAA6976).withValues(alpha: 0.3);
      highlightColor = const Color(0xFFAA6976).withValues(alpha: 0.03);
      borderWidth = 1.5;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A1B31).withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 5,
            spreadRadius: -2,
            offset: Offset(-5, -5),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFF9F5F6).withValues(alpha: 0.5),
          ],
          stops: const [0.4, 1.0],
        ),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            highlightColor,
            Colors.transparent,
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: CustomExpandableContainer(
        titleText: "", // Required parameter
        customTitleWidget: Row(
          children: [
            // Foto Profil Siswa
            Container(
              width: 45,
              height: 45,
              margin: const EdgeInsets.only(left: 15, right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A1B31).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(45),
                child: assignmentSubmission.student.image.isNotEmpty
                    ? CustomImageWidget(
                        imagePath: assignmentSubmission.student.image,
                        boxFit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF6A1B31).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF6A1B31),
                            size: 24,
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A1B31).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF6A1B31),
                          size: 24,
                        ),
                      ),
              ),
            ).animate().fadeIn(duration: 500.ms).scale(
                begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),

            Expanded(
              child: Text(
                assignmentSubmission.student.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A2728),
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        contractedContentWidget: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nama siswa dengan tipografi yang ditingkatkan

              // Info pengiriman dan status dengan layout yang lebih modern
              Row(
                children: [
                  // Waktu pengiriman dengan ikon
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: Color(0xFF6A1B31),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextContainer(
                                textKey: submittedOnKey,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6A1B31)
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                              Text(
                                Utils.formatDateAndTime(
                                  DateTime.parse(
                                      assignmentSubmission.createdAt),
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Badge status dengan desain yang lebih menarik
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: statusGradient,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: status.color.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        CustomTextContainer(
                          textKey: status.titleKey,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        expandedContentWidget: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF6EDF0),
                Color(0xFFEFDFE4),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE7D2D9),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A1B31).withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section header
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: const Text(
                  "Detail Tugas",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6A1B31),
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              // Section untuk nilai dengan desain yang lebih menarik dan interaktif
              if (assignmentSubmission.points != 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFEADADA),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF800020).withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF6A1B31)
                                      .withValues(alpha: 0.08),
                                  const Color(0xFF6A1B31)
                                      .withValues(alpha: 0.12),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.grade_rounded,
                              size: 22,
                              color: Color(0xFF6A1B31),
                            ),
                          )
                              .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true),
                              )
                              .rotate(
                                duration: 5000.ms,
                                begin: -0.02,
                                end: 0.02,
                              ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomTextContainer(
                                  textKey: pointsKey,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF800020)
                                        .withValues(alpha: 0.8),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: assignmentSubmission.points
                                            .toString(),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF6A1B31),
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            " / ${assignmentSubmission.assignment.points}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: _getGradeColor(
                                    assignmentSubmission.points.toDouble(),
                                    assignmentSubmission.assignment.points
                                        .toDouble()),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _getGradeColor(
                                          assignmentSubmission.points
                                              .toDouble(),
                                          assignmentSubmission.assignment.points
                                              .toDouble())
                                      .withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _getGradeLabel(
                                    assignmentSubmission.points.toDouble(),
                                    assignmentSubmission.assignment.points
                                        .toDouble()),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getGradeColor(
                                      assignmentSubmission.points.toDouble(),
                                      assignmentSubmission.assignment.points
                                          .toDouble()),
                                ),
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 300.ms)
                              .scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1.0, 1.0)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Stack(
                        children: [
                          // Background track
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEADADA),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          // Progress indicator
                          Container(
                            height: 8,
                            width: MediaQuery.of(context).size.width *
                                ((assignmentSubmission.points /
                                            assignmentSubmission
                                                .assignment.points
                                                .toDouble()) *
                                        0.65)
                                    .clamp(0.0, 0.65),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  _getGradeColor(
                                      assignmentSubmission.points.toDouble(),
                                      assignmentSubmission.assignment.points
                                          .toDouble()
                                          .toDouble()),
                                  _getGradeColor(
                                          assignmentSubmission.points
                                              .toDouble(),
                                          assignmentSubmission.assignment.points
                                              .toDouble())
                                      .withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: _getGradeColor(
                                          assignmentSubmission.points
                                              .toDouble(),
                                          assignmentSubmission.assignment.points
                                              .toDouble())
                                      .withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms).slideX(
                              begin: -1.0,
                              end: 0.0,
                              duration: 800.ms,
                              curve: Curves.easeOutQuart),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "${((assignmentSubmission.points / assignmentSubmission.assignment.points) * 100).round()}%",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _getGradeColor(
                                  assignmentSubmission.points.toDouble(),
                                  assignmentSubmission.assignment.points
                                      .toDouble()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Section untuk umpan balik dengan desain yang lebih menarik dan modern
              if (assignmentSubmission.feedback.trim().isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFEADADA),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6A1B31).withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF6A1B31)
                                      .withValues(alpha: 0.08),
                                  const Color(0xFF6A1B31)
                                      .withValues(alpha: 0.12),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.comment_rounded,
                              size: 22,
                              color: Color(0xFF6A1B31),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: CustomTextContainer(
                                    textKey: feedbackKey,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6A1B31)
                                          .withValues(alpha: 0.8),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F5F6).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFEADADA),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF800020)
                                        .withValues(alpha: 0.1),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.format_quote,
                                      size: 14,
                                      color: Color(0xFF6A1B31),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Umpan Balik Guru",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              assignmentSubmission.feedback,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.black87,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 150.ms)
                          .slideY(begin: 0.05, end: 0),
                    ],
                  ),
                ),
              // Section untuk berkas yang dikirimkan dengan desain yang lebih modern
              if (assignmentSubmission.file.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFEADADA),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF800020).withValues(alpha: 0.03),
                        blurRadius: 6,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF800020)
                                  .withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.attachment_rounded,
                              size: 22,
                              color: Color(0xFF6A1B31),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Berkas Tugas",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6A1B31)
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6A1B31)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${assignmentSubmission.file.length}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6A1B31),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Render each file in the submission
                      ...assignmentSubmission.file
                            .map((fileItem) => GestureDetector(
                                  onTap: () {
                                    Utils.viewOrDownloadStudyMaterial(
                                      context: context,
                                      storeInExternalStorage: true,
                                      studyMaterial: fileItem,
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9F5F6)
                                          .withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFEADADA),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6A1B31)
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              _getFileIcon(fileItem.fileName),
                                              color: const Color(0xFF6A1B31),
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                fileItem.fileName,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              const Text(
                                                "Klik untuk mengunduh berkas",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6A1B31)
                                                .withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.download_rounded,
                                            size: 16,
                                            color: Color(0xFF6A1B31),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ))
                          .toList()
                          .animate(interval: 100.ms)
                          .fadeIn(duration: 400.ms, delay: 200.ms)
                          .slideY(begin: 0.1, end: 0),
                    ],
                  ),
                ),
            ],
          ),
        ),
        onEdit: () {
          Get.toNamed(Routes.teacherEditAssignmentSubmissionScreen,
                  arguments:
                      TeacherEditAssignmentSubmissionScreen.buildArguments(
                          assignmentSubmission: assignmentSubmission))
              ?.then((value) {
            if (value != null && value is AssignmentSubmission) {
              if (mounted) {
                context
                    .read<AssignmentSubmissionsCubit>()
                    .updateReviewAssignment(
                        updatedReviewAssignmentSubmission: value);
              }
            }
          });
        },
        isStudyMaterialFile: false,
        studyMaterials: const [],
// Kosongkan karena nama siswa sudah ditampilkan di card yang dirancang ulang
      ),
    );
  }

  Widget _buildAssignmentSubmissionList() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
            top: Utils.appContentTopScrollPadding(context: context) + 120),
        physics: const BouncingScrollPhysics(),
        child:
            BlocBuilder<AssignmentSubmissionsCubit, AssignmentSubmissionsState>(
          builder: (context, state) {
            if (state is AssignmentSubmissionsFetchedSuccess) {
              final List<AssignmentSubmission> filteredAssignmentSubmissions =
                  [];
              filteredAssignmentSubmissions.addAll(state.reviewAssignment);

              if (selectedAssignmentSubmissionFilterStatus.filter !=
                  AssignmentSubmissionFilters.all) {
                filteredAssignmentSubmissions.removeWhere((element) =>
                    element.status !=
                    selectedAssignmentSubmissionFilterStatus.typeStatusId);
              }

              if (filteredAssignmentSubmissions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF6A1B31).withValues(alpha: 0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFEADADA),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Color(0xFFF9F5F6),
                                  Color(0xFFEADADA),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.assignment_late_outlined,
                              size: 60,
                              color: const Color(0xFF6A1B31)
                                  .withValues(alpha: 0.7),
                            ),
                          ).animate().fadeIn(duration: 600.ms).scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.0, 1.0)),
                          const SizedBox(height: 20),
                          CustomTextContainer(
                            textKey: Utils.getTranslatedLabel(
                                noAssignmentSubmissionKey),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6A1B31),
                            ),
                          ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Container(
                padding: EdgeInsets.fromLTRB(
                    appContentHorizontalPadding,
                    appContentHorizontalPadding,
                    appContentHorizontalPadding,
                    20),
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF800020).withValues(alpha: 0.05),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.7),
                      blurRadius: 10,
                      spreadRadius: -5,
                      offset: const Offset(-5, -5),
                    ),
                  ],
                ),
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF6A1B31).withValues(alpha: 0.12),
                            const Color(0xFF9A4156).withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              const Color(0xFF6A1B31).withValues(alpha: 0.18),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF800020).withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF800020)
                                    .withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.assignment_turned_in,
                              color: Color(0xFF800020),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CustomTextContainer(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textKey: assignmentSubmissionListKey,
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF800020),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${filteredAssignmentSubmissions.length} pengumpulan',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: -0.1, end: 0.0),
                    const SizedBox(height: 20),
                    ...List.generate(
                      filteredAssignmentSubmissions.length,
                      (index) => _buildAssignmentSubmissionItem(
                              assignmentSubmission:
                                  filteredAssignmentSubmissions[index])
                          .animate()
                          .fadeIn(
                              duration: 400.ms,
                              delay: (80 * index).ms,
                              curve: Curves.easeOutQuad)
                          .slideY(begin: 0.1, end: 0.0)
                          .scale(
                              begin: const Offset(0.98, 0.98),
                              end: const Offset(1.0, 1.0)),
                    ),
                  ],
                ),
              );
            } else if (state is AssignmentSubmissionsFetchFailure) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.only(
                      top: topPaddingOfErrorAndLoadingContainer),
                  child: ErrorContainer(
                    errorMessage: state.errorMessage,
                    onTapRetry: () {
                      fetchAssignmentSubmissions();
                    },
                  ).animate().fadeIn(duration: 300.ms).scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1.0, 1.0)),
                ),
              );
            } else {
              return Container(
                padding: EdgeInsets.fromLTRB(
                    appContentHorizontalPadding,
                    0, // Remove top padding since scroll view already provides it
                    appContentHorizontalPadding,
                    20),
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: const SkeletonTeacherManageAssignmentSubmissionScreen(
                  itemCount: 6,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
          0xFFF8F1F3), // Soft dark maroon background yang lebih tajam
      body: Stack(
        children: [
          // Content area with submissions list
          _buildAssignmentSubmissionList(),

          // Modern AppBar with CustomModernAppBar
          Align(
            alignment: Alignment.topCenter,
            child: CustomModernAppBar(
              title: "Pengumpulan",
              icon: Icons.assignment_rounded,
              fabAnimationController: _fabAnimationController,
              primaryColor:
                  const Color(0xFF6A1B31), // Soft dark maroon yang lebih tajam
              lightColor: const Color(
                  0xFF9A4156), // Lighter maroon shade yang lebih tajam
              onBackPressed: () => Get.back(),
              showFilterButton: true,
              onFilterPressed: () {
                Utils.showBottomSheet(
                    child:
                        FilterSelectionBottomsheet<AssignmentSubmissionStatus>(
                      onSelection: (value) {
                        Get.back();
                        if (value != null) {
                          selectedAssignmentSubmissionFilterStatus = value;
                          setState(() {});
                        }
                      },
                      selectedValue: selectedAssignmentSubmissionFilterStatus,
                      titleKey: statusKey,
                      values: allAssignmentSubmissionStatus,
                    ),
                    context: context);
              },
            ),
          ),

          // Filter status indicator
          // Fixed position filter indicator
          Positioned(
            top: MediaQuery.of(context).padding.top + 90,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF800020).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF800020).withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list_rounded,
                    color: Color(0xFF800020),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const CustomTextContainer(
                    textKey: filterByKey,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF800020),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF800020).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF800020).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: CustomTextContainer(
                      textKey:
                          selectedAssignmentSubmissionFilterStatus.titleKey,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF800020),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(
                  duration: 600.ms, delay: 300.ms, curve: Curves.easeOutQuad)
              .slideY(begin: -0.2, end: 0.0),
        ],
      ),
    );
  }

  // Helper method untuk mendapatkan gradasi warna status yang lebih menarik dengan tema maroon
  List<Color> _getStatusGradient(Color baseColor) {
    // Untuk status tertentu berikan warna maroon yang lebih menarik
    if (baseColor == Colors.green) {
      return [
        const Color(0xFF2E8B57), // Sea Green
        const Color(0xFF228B22), // Forest Green
      ];
    } else if (baseColor == Colors.orange || baseColor == Colors.amber) {
      return [
        const Color(0xFF9A4156), // Medium Maroon
        const Color(0xFF7D3546), // Darker Medium Maroon
      ];
    } else if (baseColor == Colors.red) {
      return [
        const Color(0xFF470F1F), // Very Dark Maroon
        const Color(0xFF380D19), // Even Darker Maroon
      ];
    } else if (baseColor == Colors.blue) {
      return [
        const Color(0xFFAA6976), // Secondary Maroon
        const Color(0xFF8F5461), // Darker Secondary Maroon
      ];
    }

    // Default gradient for other colors - maroon themed
    return [const Color(0xFF6A1B31), const Color(0xFF57152A)];
  }

  // Helper method untuk mendapatkan warna grade berdasarkan nilai siswa dengan tema maroon
  Color _getGradeColor(double points, double totalPoints) {
    double percentage = (points / totalPoints) * 100;
    if (percentage >= 90) {
      return const Color(0xFF6A1B31); // Dark Maroon (main theme color)
    } else if (percentage >= 80) {
      return const Color(0xFF9A4156); // Medium Maroon
    } else if (percentage >= 70) {
      return const Color(0xFFBE7685); // Light Maroon
    } else if (percentage >= 60) {
      return const Color(0xFFD1919D); // Lighter Maroon
    } else if (percentage >= 50) {
      return const Color(0xFFAA6976); // Secondary Maroon
    } else {
      return const Color(0xFF470F1F); // Very Dark Maroon
    }
  }

  // Helper method untuk menentukan label grade berdasarkan nilai siswa
  String _getGradeLabel(double points, double totalPoints) {
    double percentage = (points / totalPoints) * 100;
    if (percentage >= 90) {
      return "A";
    } else if (percentage >= 80) {
      return "B";
    } else if (percentage >= 70) {
      return "C";
    } else if (percentage >= 60) {
      return "D";
    } else if (percentage >= 50) {
      return "E";
    } else {
      return "F";
    }
  }

  // Helper method untuk menentukan ikon berkas berdasarkan ekstensi file
  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
      return Icons.image_outlined;
    } else if (['pdf'].contains(extension)) {
      return Icons.picture_as_pdf_outlined;
    } else if (['doc', 'docx', 'txt', 'rtf'].contains(extension)) {
      return Icons.description_outlined;
    } else if (['xls', 'xlsx', 'csv'].contains(extension)) {
      return Icons.table_chart_outlined;
    } else if (['ppt', 'pptx'].contains(extension)) {
      return Icons.slideshow_outlined;
    } else if (['zip', 'rar', '7z', 'tar', 'gz'].contains(extension)) {
      return Icons.folder_zip_outlined;
    } else if (['mp3', 'wav', 'ogg', 'aac'].contains(extension)) {
      return Icons.audio_file_outlined;
    } else if (['mp4', 'avi', 'mov', 'mkv', 'wmv'].contains(extension)) {
      return Icons.video_file_outlined;
    }

    return Icons.insert_drive_file_outlined;
  }
}
