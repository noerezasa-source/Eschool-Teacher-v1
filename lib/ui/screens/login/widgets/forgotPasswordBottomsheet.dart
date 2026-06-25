import 'package:eschool_saas_staff/cubits/authentication/sendPasswordResetEmailCubit.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customBottomsheet.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/route_manager.dart';
import 'dart:math' as math;

class ForgotPasswordBottomsheet extends StatefulWidget {
  const ForgotPasswordBottomsheet({super.key});

  @override
  State<ForgotPasswordBottomsheet> createState() =>
      _ForgotPasswordBottomsheetState();
}

class _ForgotPasswordBottomsheetState extends State<ForgotPasswordBottomsheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailEditingController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;

  bool _isEmailValid = true;

  // Skema warna maroon
  Color get _primaryMaroon => AppColorPalette.primaryMaroon;
  final Color _lightMaroon = const Color(0xFFE0C0C0);
  final Color _darkMaroon = const Color(0xFF5A0016);
  final Color _accentColor = const Color(0xFFFF9E80);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuad,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
    ));
    _emailFocusNode.addListener(() => setState(() {}));

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailEditingController.dispose();
    _emailFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomsheet(
      titleLabelKey: forgotPasswordKey,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              _lightMaroon.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: appContentHorizontalPadding,
                vertical: 20,
              ),
              child: Column(
                children: [
                  // Ilustrasi atas yang lebih menarik
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotateAnimation.value,
                        child: Container(
                          height: 120,
                          width: 120,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: _lightMaroon.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _primaryMaroon.withValues(alpha: 0.2),
                                blurRadius: 15,
                                spreadRadius: 1,
                              ),
                            ],
                            border: Border.all(
                              color: _primaryMaroon.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 80,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Icon(
                                Icons.lock_reset_rounded,
                                size: 60,
                                color: _primaryMaroon,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Teks deskripsi
                  Container(
                    margin: const EdgeInsets.only(bottom: 30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _lightMaroon.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _primaryMaroon.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Masukkan email Anda untuk menerima tautan reset password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),

                  // Field email
                  _buildInputField(
                    controller: _emailEditingController,
                    focusNode: _emailFocusNode,
                    hint: 'Alamat Email',
                    icon: Icons.email_outlined,
                    isValid: _isEmailValid,
                    errorText: 'Masukkan email yang valid',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      setState(() {
                        _isEmailValid = value.isEmpty || _validateEmail(value);
                      });
                    },
                    index: 0,
                  ),

                  const SizedBox(height: 30),

                  // Tombol reset dengan BLoC
                  BlocConsumer<SendPasswordResetEmailCubit,
                      SendPasswordResetEmailState>(
                    listener: (context, state) {
                      if (state is SendPasswordResetEmailSuccess) {
                        Get.back();
                        Utils.showSnackBar(
                            message: passwordResetLinkSentToYourEmailKey,
                            context: context);
                      } else if (state is SendPasswordResetEmailFailure) {
                        Utils.showSnackBar(
                            message: state.errorMessage, context: context);
                      }
                    },
                    builder: (context, state) {
                      return PopScope(
                        canPop: state is! SendPasswordResetEmailInProgress,
                        child: _buildSubmitButton(state),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Tautan kembali ke login
                  TextButton.icon(
                    onPressed: () => Get.back(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: _primaryMaroon,
                    ),
                    label: Text(
                      'Kembali ke Login',
                      style: TextStyle(
                        color: _primaryMaroon,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      backgroundColor: _lightMaroon.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required bool isValid,
    required String errorText,
    required Function(String) onChanged,
    required int index,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 300)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: focusNode.hasFocus
                  ? _primaryMaroon.withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
              spreadRadius: focusNode.hasFocus ? 2 : 0,
            ),
          ],
          border: Border.all(
            color: !isValid
                ? Colors.red.shade400
                : focusNode.hasFocus
                    ? _primaryMaroon
                    : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: focusNode.hasFocus
                        ? _primaryMaroon.withValues(alpha: 0.15)
                        : Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                  width: 50,
                  child: Icon(
                    icon,
                    color: focusNode.hasFocus
                        ? _primaryMaroon
                        : Colors.grey.shade600,
                    size: 22,
                  ),
                ),
                suffixIcon: focusNode.hasFocus
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey.shade400,
                          size: 18,
                        ),
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: onChanged,
            ),
            if (!isValid)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      errorText,
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  Widget _buildSubmitButton(SendPasswordResetEmailState state) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.7 + (0.3 * value),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [
              _primaryMaroon,
              _darkMaroon,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _primaryMaroon.withValues(alpha: 0.5),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            splashColor: _accentColor.withValues(alpha: 0.2),
            highlightColor: _accentColor.withValues(alpha: 0.1),
            onTap: () {
              if (state is SendPasswordResetEmailInProgress) {
                return;
              }

              final email = _emailEditingController.text.trim();

              setState(() {
                _isEmailValid = email.isNotEmpty && _validateEmail(email);
              });

              if (!_isEmailValid) {
                return;
              }

              context
                  .read<SendPasswordResetEmailCubit>()
                  .sendPasswordResetEmail(
                    email: email,
                  );
            },
            child: Center(
              child: state is SendPasswordResetEmailInProgress
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Kirim Tautan Reset',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Transform.translate(
                            offset: const Offset(0, 0),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
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
  }
}
