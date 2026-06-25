import 'package:eschool_saas_staff/cubits/teacherAcademics/assignmentSubmissions/editAssignmetSubmissionCubit.dart';
import 'package:eschool_saas_staff/data/models/academic/assignmentSubmission.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customModernAppBar.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';

class TeacherEditAssignmentSubmissionScreen extends StatefulWidget {
  final AssignmentSubmission assignmentSubmission;

  static Widget getRouteInstance() {
    final arguments = Get.arguments as Map<String, dynamic>?;
    return BlocProvider(
      create: (context) => EditAssignmentSubmissionCubit(),
      child: TeacherEditAssignmentSubmissionScreen(
        assignmentSubmission: arguments?['assignmentSubmission'] ?? false,
      ),
    );
  }

  static Map<String, dynamic> buildArguments(
      {required AssignmentSubmission assignmentSubmission}) {
    return {"assignmentSubmission": assignmentSubmission};
  }

  const TeacherEditAssignmentSubmissionScreen(
      {super.key, required this.assignmentSubmission});

  @override
  State<TeacherEditAssignmentSubmissionScreen> createState() =>
      _TeacherEditAssignmentSubmissionScreenState();
}

class _TeacherEditAssignmentSubmissionScreenState
    extends State<TeacherEditAssignmentSubmissionScreen>
    with TickerProviderStateMixin {
  bool isAccepting = true;
  bool _isInEditMode = false; // Flag untuk mode edit
  late final TextEditingController _feedbackTextEditingController;
  late final TextEditingController _pointsTextEditingController;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _appBarAnimationController;

  // Status tracking
  bool get _isCurrentlyAcceptedOrRejected {
    final status = widget.assignmentSubmission.submissionStatus.filter;
    return status == AssignmentSubmissionFilters.accepted ||
        status == AssignmentSubmissionFilters.rejected;
  }

  @override
  void initState() {
    super.initState();

    // Initialize controllers dengan data existing
    _feedbackTextEditingController =
        TextEditingController(text: widget.assignmentSubmission.feedback);
    _pointsTextEditingController = TextEditingController(
        text: widget.assignmentSubmission.points.toString());

    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _appBarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    // Set initial state based on submission status
    final submissionStatus =
        widget.assignmentSubmission.submissionStatus.filter;
    if (submissionStatus == AssignmentSubmissionFilters.accepted) {
      isAccepting = true;
    } else if (submissionStatus == AssignmentSubmissionFilters.rejected) {
      isAccepting = false;
    }
  }

  @override
  void dispose() {
    _feedbackTextEditingController.dispose();
    _pointsTextEditingController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _appBarAnimationController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isInEditMode = !_isInEditMode;
    });
    HapticFeedback.mediumImpact();
  }

  void showErrorMessage(String errorMessageKey) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.redAccent,
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMessageKey,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showEditConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Edit Penilaian'),
          ],
        ),
        content: const Text(
          'Tugas ini sudah dinilai sebelumnya. Apakah Anda yakin ingin mengedit penilaian?',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleEditMode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditModeToggle() {
    if (!_isCurrentlyAcceptedOrRejected) {
      return const SizedBox.shrink(); // Tidak perlu toggle jika belum dinilai
    }

    return SlideInDown(
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isInEditMode ? Colors.orange.shade50 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                _isInEditMode ? Colors.orange.shade200 : Colors.blue.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isInEditMode
                    ? Colors.orange.shade100
                    : Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isInEditMode ? Icons.edit : Icons.info_outline,
                color: _isInEditMode
                    ? Colors.orange.shade700
                    : Colors.blue.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isInEditMode ? 'Mode Edit Aktif' : 'Tugas Sudah Dinilai',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isInEditMode
                          ? Colors.orange.shade800
                          : Colors.blue.shade800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isInEditMode
                        ? 'Anda dapat mengubah penilaian dan feedback'
                        : 'Klik tombol edit untuk mengubah penilaian',
                    style: TextStyle(
                      color: _isInEditMode
                          ? Colors.orange.shade600
                          : Colors.blue.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed:
                  _isInEditMode ? _toggleEditMode : _showEditConfirmationDialog,
              icon: Icon(
                _isInEditMode ? Icons.visibility : Icons.edit,
                size: 16,
                color: _isInEditMode
                    ? Colors.orange.shade700
                    : Colors.blue.shade700,
              ),
              label: Text(
                _isInEditMode ? 'View' : 'Edit',
                style: TextStyle(
                  color: _isInEditMode
                      ? Colors.orange.shade700
                      : Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: _isInEditMode
                    ? Colors.orange.shade100
                    : Colors.blue.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .slideY(begin: -0.3, end: 0, duration: 500.ms),
    );
  }

  Widget _buildStatusSection() {
    final isEditable = !_isCurrentlyAcceptedOrRejected || _isInEditMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Utils.getTranslatedLabel(statusKey),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        if (!isEditable) ...[
          // Read-only status display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: widget.assignmentSubmission.submissionStatus.filter ==
                      AssignmentSubmissionFilters.accepted
                  ? Colors.green.withValues(alpha: 0.08)
                  : Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.assignmentSubmission.submissionStatus.filter ==
                        AssignmentSubmissionFilters.accepted
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        widget.assignmentSubmission.submissionStatus.filter ==
                                AssignmentSubmissionFilters.accepted
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.assignmentSubmission.submissionStatus.filter ==
                            AssignmentSubmissionFilters.accepted
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color:
                        widget.assignmentSubmission.submissionStatus.filter ==
                                AssignmentSubmissionFilters.accepted
                            ? Colors.green
                            : Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    Utils.getTranslatedLabel(
                        widget.assignmentSubmission.submissionStatus.titleKey),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Editable status buttons
          Row(
            children: [
              Expanded(
                child: _buildStatusButton(
                  isSelected: isAccepting,
                  onTap: () {
                    setState(() => isAccepting = true);
                    HapticFeedback.lightImpact();
                  },
                  icon: Icons.check_circle_outline,
                  label: Utils.getTranslatedLabel(acceptKey),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusButton(
                  isSelected: !isAccepting,
                  onTap: () {
                    setState(() {
                      isAccepting = false;
                      _pointsTextEditingController.text = "0";
                    });
                    HapticFeedback.lightImpact();
                  },
                  icon: Icons.cancel_outlined,
                  label: Utils.getTranslatedLabel(rejectKey),
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatusButton({
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.4),
                    color.withValues(alpha: 0.6)
                  ],
                )
              : null,
          color: isSelected ? null : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.6)
                : Colors.grey.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsField() {
    final shouldShowPoints = (isAccepting ||
            (_isCurrentlyAcceptedOrRejected &&
                widget.assignmentSubmission.submissionStatus.filter ==
                    AssignmentSubmissionFilters.accepted)) &&
        widget.assignmentSubmission.assignment.points != 0;

    if (!shouldShowPoints) return const SizedBox.shrink();

    final isEditable = !_isCurrentlyAcceptedOrRejected || _isInEditMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              Utils.getTranslatedLabel(pointsKey),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: _pointsTextEditingController,
            readOnly: !isEditable,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(
                widget.assignmentSubmission.assignment.points.toString().length,
              ),
            ],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isEditable
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade600,
            ),
            decoration: InputDecoration(
              hintText: 'Masukkan poin nilai',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.star_outline,
                color: isEditable
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade500,
              ),
              suffixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.7),
                      Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "/ ${widget.assignmentSubmission.assignment.points}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackField() {
    final isEditable = !_isCurrentlyAcceptedOrRejected || _isInEditMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(
              Icons.comment_outlined,
              size: 18,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              Utils.getTranslatedLabel(feedbackKey),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (!isEditable) ...[
          // Read-only feedback display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  _feedbackTextEditingController.text.isEmpty
                      ? 'Tidak ada feedback'
                      : _feedbackTextEditingController.text,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                    letterSpacing: 0.2,
                    fontStyle: _feedbackTextEditingController.text.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "- Guru",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          // Editable feedback field
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: TextFormField(
              controller: _feedbackTextEditingController,
              maxLines: null,
              minLines: 4,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: "Berikan umpan balik yang konstruktif...",
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                alignLabelWithHint: true,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final shouldShowButton = !_isCurrentlyAcceptedOrRejected || _isInEditMode;

    if (!shouldShowButton) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 20.0),
      child: BlocConsumer<EditAssignmentSubmissionCubit,
          EditAssignmentSubmissionState>(
        listener: (context, state) {
          if (state is EditAssignmentSubmissionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        _isCurrentlyAcceptedOrRejected
                            ? 'Penilaian berhasil diperbarui!'
                            : Utils.getTranslatedLabel(
                                assignmentReviewAddedSuccessfullyKey),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                backgroundColor: Colors.green.shade400,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
            );

            Future.delayed(const Duration(milliseconds: 800), () {
              Get.back(
                result: widget.assignmentSubmission.copyWith(
                  feedback: _feedbackTextEditingController.text.trim(),
                  status: isAccepting ? 1 : 2,
                  points: int.tryParse(_pointsTextEditingController.text) ?? 0,
                ),
              );
            });
          } else if (state is EditAssignmentSubmissionFailure) {
            showErrorMessage(_isCurrentlyAcceptedOrRejected
                ? 'Gagal memperbarui penilaian'
                : Utils.getTranslatedLabel(assignmentReviewAddingFailedKey));
          }
        },
        builder: (context, state) {
          return Container(
            height: 54,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (state is EditAssignmentSubmissionInProgress) return;

                  // Validation
                  if (isAccepting &&
                      widget.assignmentSubmission.assignment.points != 0) {
                    if (_pointsTextEditingController.text.trim().isEmpty) {
                      showErrorMessage("Mohon masukkan poin nilai");
                      return;
                    } else if ((int.tryParse(
                                _pointsTextEditingController.text.trim()) ??
                            0) >
                        widget.assignmentSubmission.assignment.points) {
                      showErrorMessage(
                          "Tidak Dapat Memberikan Poin Lebih dari Total");
                      return;
                    }
                  }
                  if (_feedbackTextEditingController.text.trim().isEmpty) {
                    showErrorMessage("Mohon berikan umpan balik");
                    return;
                  }

                  context
                      .read<EditAssignmentSubmissionCubit>()
                      .updateAssignmentSubmission(
                        assignmentSubmissionId: widget.assignmentSubmission.id,
                        assignmentSubmissionStatus: isAccepting ? 1 : 0,
                        assignmentSubmissionPoints:
                            widget.assignmentSubmission.assignment.points <=
                                        0 ||
                                    !isAccepting
                                ? "0"
                                : _pointsTextEditingController.text.trim(),
                        assignmentSubmissionFeedBack:
                            _feedbackTextEditingController.text.trim(),
                      );
                },
                borderRadius: BorderRadius.circular(15),
                splashColor: Colors.white.withValues(alpha: 0.2),
                highlightColor: Colors.white.withValues(alpha: 0.1),
                child: Center(
                  child: state is EditAssignmentSubmissionInProgress
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Memproses...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isCurrentlyAcceptedOrRejected
                                  ? 'Update'
                                  : Utils.getTranslatedLabel(submitKey),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _isCurrentlyAcceptedOrRejected
                                  ? Icons.update
                                  : Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(
            kToolbarHeight + 40), // Memperbesar tinggi appBar
        child: CustomModernAppBar(
          title: "Tinjau Pengumpulan",
          icon: Icons.assignment_outlined,
          fabAnimationController: _appBarAnimationController,
          primaryColor: AppColorPalette.primaryMaroon,
          lightColor: const Color(0xFF5A2223),
          onBackPressed: () {
            HapticFeedback.mediumImpact();
            Get.back();
          },
        ),
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: BlocBuilder<EditAssignmentSubmissionCubit,
            EditAssignmentSubmissionState>(
          builder: (context, state) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.only(
                  top: kToolbarHeight + MediaQuery.of(context).padding.top - 25,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Edit Mode Toggle
                            _buildEditModeToggle(),

                            // Student Information Card
                            SlideInLeft(
                              duration: const Duration(milliseconds: 500),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Student avatar with animated border
                                    AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (context, child) {
                                        return Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 8 *
                                                    (1 +
                                                        _pulseAnimation.value /
                                                            3),
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 30,
                                            backgroundColor: Colors.white,
                                            child: Text(
                                              widget.assignmentSubmission
                                                  .student.fullName
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 16),
                                    // Student information
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'Informasi Siswa',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ),
                                          ).animate().fadeIn(duration: 400.ms),
                                          const SizedBox(height: 12),
                                          Text(
                                            widget.assignmentSubmission.student
                                                .fullName,
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.3,
                                            ),
                                          )
                                              .animate()
                                              .fadeIn(delay: 200.ms)
                                              .slideX(
                                                  begin: 0.2,
                                                  end: 0,
                                                  duration: 500.ms),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Assessment Section
                            SlideInRight(
                              duration: const Duration(milliseconds: 500),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Section title
                                    Row(
                                      children: [
                                        AnimatedBuilder(
                                          animation: _pulseAnimation,
                                          builder: (context, child) {
                                            return Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withValues(
                                                            alpha: 0.1 *
                                                                _pulseAnimation
                                                                    .value),
                                                    blurRadius: 4,
                                                    spreadRadius: 1 *
                                                        _pulseAnimation.value,
                                                  )
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.rate_review_outlined,
                                                size: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Penilaian Tugas',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ).animate().fadeIn(duration: 400.ms).slideY(
                                        begin: -0.2, end: 0, duration: 400.ms),

                                    // Divider with gradient
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      height: 2,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.1),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),

                                    // Status Section
                                    _buildStatusSection(),

                                    // Points Field
                                    _buildPointsField(),

                                    // Feedback Field
                                    _buildFeedbackField(),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Student Answer Section
                            if (widget
                                .assignmentSubmission.content.isNotEmpty) ...[
                              SlideInLeft(
                                duration: const Duration(milliseconds: 500),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.text_snippet_outlined,
                                              size: 18,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            "Jawaban Siswa",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        height: 2,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.1),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.format_quote,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.3),
                                                  size: 24,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              widget
                                                  .assignmentSubmission.content,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.black87,
                                                height: 1.6,
                                                letterSpacing: 0.3,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Attachments Section
                            if (widget
                                .assignmentSubmission.file.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 18,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          Utils.getTranslatedLabel(filesKey),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.attach_file,
                                                size: 14,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${widget.assignmentSubmission.file.length} ${widget.assignmentSubmission.file.length > 1 ? 'files' : 'file'}",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      height: 2,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.1),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    ...widget.assignmentSubmission.file
                                        .map((studyMaterial) {
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.2),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.03),
                                              blurRadius: 6,
                                              spreadRadius: 0,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 8),
                                          leading: Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Icon(
                                                _getFileIcon(
                                                    studyMaterial.fileName),
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                size: 22,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            studyMaterial.fileName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: Text(
                                            "Tap to open file",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _getFileExtension(
                                                      studyMaterial.fileName)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          onTap: () async {
                                            final url = studyMaterial.fileUrl;
                                            if (url.isNotEmpty) {
                                              if (url.startsWith('http')) {
                                                if (await canLaunchUrl(
                                                    Uri.parse(url))) {
                                                  await launchUrl(
                                                      Uri.parse(url),
                                                      mode: LaunchMode
                                                          .externalApplication);
                                                } else {
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Tidak dapat membuka link file.'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              } else {
                                                try {
                                                  await OpenFilex.open(url);
                                                } catch (e) {
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Gagal membuka file lokal.'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'File tidak tersedia.'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    // Submit button
                    _buildSubmitButton(context),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper function to get file icon
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
    } else {
      return Icons.insert_drive_file_outlined;
    }
  }

  // Helper function to get file extension
  String _getFileExtension(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return extension.length > 5 ? extension.substring(0, 3) : extension;
  }
}
