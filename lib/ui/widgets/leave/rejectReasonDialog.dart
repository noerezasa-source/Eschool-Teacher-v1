import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customRoundedButton.dart';

class RejectReasonDialog extends StatefulWidget {
  final Function(String reason) onReject;
  final VoidCallback? onCancel;

  const RejectReasonDialog({
    super.key,
    required this.onReject,
    this.onCancel,
  });

  @override
  State<RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<RejectReasonDialog>
    with TickerProviderStateMixin {
  late TextEditingController _reasonController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleReject() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        await Future.delayed(
            const Duration(milliseconds: 100)); // Small delay for UX
        widget.onReject(_reasonController.text.trim());
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _handleCancel() {
    _animationController.reverse().then((_) {
      if (widget.onCancel != null) {
        widget.onCancel!();
      } else {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final maroonPrimary = AppColorPalette.primaryMaroon;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!_isSubmitting) {
          _handleCancel();
        }
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: maroonPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.cancel_outlined,
                                color: maroonPrimary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Tolak Permohonan Cuti",
                                    style: TextStyle(
                                      fontFamily:
                                          GoogleFonts.poppins().fontFamily,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: maroonPrimary,
                                    ),
                                  ),
                                  Text(
                                    "Berikan alasan penolakan",
                                    style: TextStyle(
                                      fontFamily:
                                          GoogleFonts.poppins().fontFamily,
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Reason input field
                        Text(
                          "Alasan Penolakan *",
                          style: TextStyle(
                            fontFamily: GoogleFonts.poppins().fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: maroonPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        TextFormField(
                          controller: _reasonController,
                          maxLines: 4,
                          enabled: !_isSubmitting,
                          decoration: InputDecoration(
                            hintText:
                                "Masukkan alasan mengapa permohonan cuti ditolak...",
                            hintStyle: TextStyle(
                              fontFamily: GoogleFonts.poppins().fontFamily,
                              color: Colors.grey[500],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: maroonPrimary, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Colors.red, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          style: TextStyle(
                            fontFamily: GoogleFonts.poppins().fontFamily,
                            fontSize: 14,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Alasan penolakan wajib diisi";
                            }
                            if (value.trim().length < 10) {
                              return "Alasan penolakan minimal 10 karakter";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: CustomRoundedButton(
                                radius: 12,
                                height: 48,
                                widthPercentage: 1.0,
                                backgroundColor: Colors.grey[100]!,
                                buttonTitle: "Batal",
                                titleColor: Colors.grey[700]!,
                                showBorder: true,
                                borderColor: Colors.grey[300]!,
                                onTap: _isSubmitting ? null : _handleCancel,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomRoundedButton(
                                radius: 12,
                                height: 48,
                                widthPercentage: 1.0,
                                backgroundColor: maroonPrimary,
                                buttonTitle: "Tolak Cuti",
                                showBorder: false,
                                onTap: _isSubmitting ? null : _handleReject,
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : null,
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
      ),
    );
  }
}
