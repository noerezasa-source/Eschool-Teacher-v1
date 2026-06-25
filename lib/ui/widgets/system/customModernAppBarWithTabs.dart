import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class CustomModernAppBarWithTabs extends StatefulWidget
    implements PreferredSizeWidget {
  final String title;
  final dynamic icon;
  final AnimationController fabAnimationController;
  final Color primaryColor;
  final Color lightColor;
  final VoidCallback? onBackPressed;
  final double height;
  final Widget? tabContent; // Tab content to show below the AppBar

  const CustomModernAppBarWithTabs({
    super.key,
    required this.title,
    required this.icon,
    required this.fabAnimationController,
    this.primaryColor = const Color(0xFF800020),
    this.lightColor = const Color(0xFFAA6976),
    this.onBackPressed,
    this.height = 120, // Default to larger height to accommodate tabs
    this.tabContent,
  });

  @override
  State<CustomModernAppBarWithTabs> createState() =>
      _CustomModernAppBarWithTabsState();

  @override
  Size get preferredSize => Size.fromHeight(height);
}

class _CustomModernAppBarWithTabsState
    extends State<CustomModernAppBarWithTabs> {
  Color get effectivePrimaryColor {
    if (widget.primaryColor == const Color(0xFF800020) || widget.primaryColor.toARGB32() == 0xFF800020) {
      return AppColorPalette.primaryMaroon;
    }
    return widget.primaryColor;
  }

  Color get effectiveLightColor {
    if (widget.lightColor == const Color(0xFFAA6976) || widget.lightColor.toARGB32() == 0xFFAA6976) {
      return AppColorPalette.secondaryMaroon;
    }
    return widget.lightColor;
  }

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

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: MediaQuery.of(context).padding.top + widget.height,
        child: Stack(
          children: [
            // Fancy gradient background with animated particles
            Positioned.fill(
              child: AnimatedBuilder(
                animation: widget.fabAnimationController,
                builder: (context, _) {
                  return ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          effectivePrimaryColor.withValues(alpha: 0.95),
                          effectivePrimaryColor,
                          effectiveLightColor.withValues(alpha: 0.95),
                          effectiveLightColor,
                        ],
                        stops: const [0.0, 0.3, 0.6, 1.0],
                        transform: GradientRotation(
                            widget.fabAnimationController.value * 0.02),
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcATop,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            effectivePrimaryColor,
                            effectivePrimaryColor.withValues(alpha: 0.85),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Decorative design elements
            Positioned.fill(
              child: CustomPaint(
                painter: AppBarDecorationPainter(
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),

            // Animated glowing effect
            AnimatedBuilder(
              animation: widget.fabAnimationController,
              builder: (context, _) {
                return Positioned(
                  top: -100 + (widget.fabAnimationController.value * 20),
                  right: -60 + (widget.fabAnimationController.value * 10),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.2),
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Main app bar content with tabs
            Positioned(
              bottom: 10,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main title bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Back button with ripple effect
                            widget.onBackPressed != null
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        highlightColor:
                                            Colors.white.withValues(alpha: 0.1),
                                        splashColor:
                                            Colors.white.withValues(alpha: 0.2),
                                        onTap: widget.onBackPressed,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.arrow_back_ios_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                    .animate()
                                    .fadeIn(
                                        duration: 400.ms, curve: Curves.easeOut)
                                    .slideX(begin: -0.3, end: 0)
                                : const SizedBox(),

                            // Animated divider
                            widget.onBackPressed != null
                                ? Container(
                                    height: 24,
                                    width: 1.5,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white.withValues(alpha: 0.0),
                                          Colors.white.withValues(alpha: 0.4),
                                          Colors.white.withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  )
                                : const SizedBox(),

                            // Title with animated badge
                            Expanded(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Main title
                                  Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Animated icon
                                        AnimatedBuilder(
                                          animation:
                                              widget.fabAnimationController,
                                          builder: (context, child) {
                                            return Transform.rotate(
                                              angle: widget
                                                      .fabAnimationController
                                                      .value *
                                                  0.05,
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Colors.white
                                                          .withValues(alpha: 0.9),
                                                      Colors.white
                                                          .withValues(alpha: 0.4),
                                                    ],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(alpha: 0.2),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: _buildIcon(widget.icon,
                                                  color: effectivePrimaryColor,
                                                  size: 20,
                                                ),
                                              ),
                                            );
                                          },
                                        ),

                                        const SizedBox(width: 12),

                                        // Title text with glowing effect
                                        ShaderMask(
                                          shaderCallback: (Rect bounds) {
                                            return LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.white,
                                                Colors.white.withValues(alpha: 0.9),
                                              ],
                                            ).createShader(bounds);
                                          },
                                          blendMode: BlendMode.srcIn,
                                          child: Text(
                                            widget.title,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                const Shadow(
                                                  color: Colors.black26,
                                                  offset: Offset(0, 1),
                                                  blurRadius: 3,
                                                ),
                                              ],
                                            ),
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
                    ),
                  ),

                  // Tab content if provided
                  if (widget.tabContent != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: widget.tabContent,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                          .scale(
                            begin: const Offset(0.95, 0.95),
                            end: const Offset(1.0, 1.0),
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

// Custom painter for decorative elements in the app bar
class AppBarDecorationPainter extends CustomPainter {
  final Color color;

  AppBarDecorationPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw decorative circles
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.2), 30, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 20, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.15), 15, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.7), 10, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.4), 8, paint);

    // Draw arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final arcRect = Rect.fromLTRB(size.width * 0.1, size.height * 0.2,
        size.width * 0.6, size.height * 0.6);
    canvas.drawArc(arcRect, 0.2, 1.5, false, arcPaint);

    // Draw another arc
    final arcRect2 = Rect.fromLTRB(size.width * 0.5, size.height * 0.4,
        size.width * 0.9, size.height * 0.8);
    canvas.drawArc(arcRect2, 3, 1.5, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
