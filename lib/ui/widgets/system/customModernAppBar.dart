import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/settings/appThemeCubit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math' as math;

class CustomModernAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final dynamic icon;
  final AnimationController fabAnimationController;
  final Color primaryColor;
  final Color lightColor;
  final VoidCallback? onBackPressed;
  final double height;
  final bool showAddButton; // New parameter to control add button visibility
  final VoidCallback? onAddPressed; // New parameter for add button action
  final bool
      showArchiveButton; // New parameter to control archive button visibility
  final VoidCallback?
      onArchivePressed; // New parameter for archive button action
  final dynamic archiveIcon; // New parameter to customize archive icon
  final bool
      showFilterButton; // New parameter to control filter button visibility
  final VoidCallback? onFilterPressed; // New parameter for filter button action
  final bool filterActive; // Whether the filter button should show active state
  final bool
      showSearchButton; // New parameter to control search button visibility
  final VoidCallback? onSearchPressed; // New parameter for search button action
  final bool
      showHelperButton; // New parameter to control helper button visibility
  final VoidCallback? onHelperPressed; // New parameter for helper button action
  final dynamic helperIcon; // New parameter to customize helper icon
  final Widget Function(BuildContext)?
      tabBuilder; // New parameter for custom tabs in AppBar

  const CustomModernAppBar({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.fabAnimationController,
    this.primaryColor = const Color(0xFF800020),
    this.lightColor = const Color(0xFFAA6976),
    this.onBackPressed,
    this.height = 80,
    this.showAddButton = false, // Default to hidden
    this.onAddPressed,
    this.showArchiveButton = false, // Default to hidden
    this.onArchivePressed,
    this.archiveIcon, // Default will be handled in build method
    this.showFilterButton = false, // Default to hidden
    this.onFilterPressed,
    this.filterActive = false,
    this.showSearchButton = false, // Default to hidden
    this.onSearchPressed,
    this.showHelperButton = false, // Default to hidden
    this.onHelperPressed,
    this.helperIcon, // Default will be handled in build method
    this.tabBuilder,
  });

  @override
  State<CustomModernAppBar> createState() => _CustomModernAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(height);
}

class _CustomModernAppBarState extends State<CustomModernAppBar>
    with TickerProviderStateMixin {
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

  late AnimationController _glowAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _rotationAnimationController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Refined glow animation - more subtle and elegant
    _glowAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowAnimationController,
        curve: Curves.easeInOutSine, // Smoother curve
      ),
    );

    // Gentle pulse animation - less aggressive
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOutCubic, // More elegant curve
      ),
    );

    // Slower, more graceful rotation
    _rotationAnimationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _rotationAnimationController,
        curve: Curves.linear,
      ),
    );

    // Start animations with delays for more natural feel
    _glowAnimationController.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 500), () {
      _pulseAnimationController.repeat(reverse: true);
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      _rotationAnimationController.repeat();
    });
  }

  @override
  void dispose() {
    _glowAnimationController.dispose();
    _pulseAnimationController.dispose();
    _rotationAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppThemeCubit, AppThemeState>(
      builder: (context, themeState) {
        // Use reactive colors if theme changes
        final primaryColor = widget.primaryColor == const Color(0xFF800020) || widget.primaryColor.toARGB32() == 0xFF800020
            ? AppColorPalette.getPrimaryColor(themeState.themeMode)
            : widget.primaryColor;
            
        final lightColor = widget.lightColor == const Color(0xFFAA6976) || widget.lightColor.toARGB32() == 0xFFAA6976
            ? AppColorPalette.getSecondaryColor(themeState.themeMode)
            : widget.lightColor;

        return SizedBox(
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
                            primaryColor.withValues(alpha: 0.95),
                            primaryColor,
                            lightColor.withValues(alpha: 0.95),
                            lightColor,
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
                              primaryColor,
                              primaryColor.withValues(alpha: 0.85),
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

          // Decorative design elements with enhanced animations
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _glowAnimationController,
                _pulseAnimationController,
                _rotationAnimationController,
              ]),
              builder: (context, _) {
                return CustomPaint(
                  painter: AnimatedAppBarDecorationPainter(
                    color: Colors.white
                        .withValues(alpha: 0.07 + (_glowAnimation.value * 0.05)),
                    glowValue: _glowAnimation.value,
                    pulseValue: _pulseAnimation.value,
                    rotationValue: _rotationAnimation.value,
                  ),
                );
              },
            ),
          ), // Refined animated glowing effect - more subtle and elegant
          AnimatedBuilder(
            animation: Listenable.merge([
              widget.fabAnimationController,
              _glowAnimationController,
              _pulseAnimationController,
            ]),
            builder: (context, _) {
              return Stack(
                children: [
                  // Primary glow circle - softer movement
                  Positioned(
                    top: MediaQuery.of(context).padding.top -
                        100 +
                        (widget.fabAnimationController.value * 15) +
                        (math.sin(_glowAnimation.value * 2 * math.pi) * 5),
                    right: -60 +
                        (widget.fabAnimationController.value * 8) +
                        (math.cos(_glowAnimation.value * 2 * math.pi) * 3),
                    child: Transform.scale(
                      scale: 0.95 + (_pulseAnimation.value * 0.1),
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 
                                  0.15 + (_glowAnimation.value * 0.05)),
                              Colors.white.withValues(alpha: 
                                  0.08 + (_glowAnimation.value * 0.03)),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Secondary glow circle - gentle floating
                  Positioned(
                    top: MediaQuery.of(context).padding.top -
                        70 +
                        (widget.fabAnimationController.value * 10) +
                        (math.sin(_glowAnimation.value * 2 * math.pi + 1.5) *
                            4),
                    left: -30 +
                        (widget.fabAnimationController.value * 5) +
                        (math.cos(_glowAnimation.value * 2 * math.pi + 1.5) *
                            2),
                    child: Transform.scale(
                      scale: 1.0 +
                          (math.sin(_pulseAnimation.value * math.pi) * 0.05),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 
                                  0.12 + (_glowAnimation.value * 0.04)),
                              Colors.white.withValues(alpha: 
                                  0.06 + (_glowAnimation.value * 0.02)),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Tertiary glow circle - micro floating animation
                  Positioned(
                    top: MediaQuery.of(context).padding.top +
                        25 +
                        (math.sin(_glowAnimation.value * 2 * math.pi + 3) * 3),
                    right: -15 +
                        (math.cos(_glowAnimation.value * 2 * math.pi + 3) * 2),
                    child: Transform.rotate(
                      angle: _rotationAnimation.value * 0.3,
                      child: Transform.scale(
                        scale: 0.9 +
                            (math.sin(_pulseAnimation.value * math.pi + 2) *
                                0.08),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(alpha: 
                                    0.08 + (_glowAnimation.value * 0.03)),
                                Colors.white.withValues(alpha: 
                                    0.04 + (_glowAnimation.value * 0.015)),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.8, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ), // Main app bar content with frosted glass effect
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main AppBar content
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
                                      onTap: widget.onBackPressed ??
                                          () => Navigator.of(context).pop(),
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
                                      // Refined animated icon - more subtle and elegant
                                      AnimatedBuilder(
                                        animation: Listenable.merge([
                                          widget.fabAnimationController,
                                          _glowAnimationController,
                                          _pulseAnimationController,
                                        ]),
                                        builder: (context, child) {
                                          return Transform.rotate(
                                            angle: widget.fabAnimationController
                                                        .value *
                                                    0.02 +
                                                (math.sin(_glowAnimation.value *
                                                        2 *
                                                        math.pi) *
                                                    0.01),
                                            child: Transform.scale(
                                              scale: 1.0 +
                                                  (math.sin(_pulseAnimation
                                                              .value *
                                                          math.pi) *
                                                      0.03),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Colors.white.withValues(alpha: 
                                                          0.92 +
                                                              (_glowAnimation
                                                                      .value *
                                                                  0.05)),
                                                      Colors.white.withValues(alpha: 
                                                          0.5 +
                                                              (_glowAnimation
                                                                      .value *
                                                                  0.1)),
                                                    ],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(alpha: 0.15 +
                                                              (_glowAnimation
                                                                      .value *
                                                                  0.05)),
                                                      blurRadius: 4 +
                                                          (_glowAnimation
                                                                  .value *
                                                              1.5),
                                                      offset: const Offset(0, 2),
                                                      spreadRadius:
                                                          _glowAnimation.value *
                                                              0.3,
                                                    ),
                                                    // Subtle glow shadow
                                                    BoxShadow(
                                                      color: Colors.white
                                                          .withValues(alpha: 0.2 *
                                                              _glowAnimation
                                                                  .value),
                                                      blurRadius: 6 +
                                                          (_glowAnimation
                                                                  .value *
                                                              2),
                                                      offset: const Offset(0, 0),
                                                      spreadRadius:
                                                          _glowAnimation.value *
                                                              1,
                                                    ),
                                                  ],
                                                ),
                                                child: _buildIcon(
                                                  widget.icon,
                                                  color: effectivePrimaryColor,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      const SizedBox(width: 12),

                                      // Title and subtitle with glowing effect
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
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
                                                fontSize: 15,
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
                                          if (widget.subtitle != null) ...[
                                            const SizedBox(height: 2),
                                            ShaderMask(
                                              shaderCallback: (Rect bounds) {
                                                return LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.white
                                                        .withValues(alpha: 0.8),
                                                    Colors.white
                                                        .withValues(alpha: 0.6),
                                                  ],
                                                ).createShader(bounds);
                                              },
                                              blendMode: BlendMode.srcIn,
                                              child: Text(
                                                widget.subtitle!,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w400,
                                                  shadows: [
                                                    const Shadow(
                                                      color: Colors.black26,
                                                      offset: Offset(0, 1),
                                                      blurRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Add divider before the Add button
                          widget.showAddButton
                              ? Container(
                                  height: 24,
                                  width: 1.5,
                                  margin: const EdgeInsets.only(right: 8.0),
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
                                ).animate().fadeIn(
                                  duration: 300.ms, curve: Curves.easeOut)
                              : const SizedBox(), // Refined Add Button - elegant and subtle animations
                          if (widget.showAddButton)
                            Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: AnimatedBuilder(
                                animation: Listenable.merge([
                                  _glowAnimationController,
                                  _pulseAnimationController,
                                ]),
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1.0 +
                                        (math.sin(_pulseAnimation.value *
                                                math.pi) *
                                            0.02),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(50),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(50),
                                        highlightColor:
                                            Colors.white.withValues(alpha: 0.15),
                                        splashColor:
                                            Colors.white.withValues(alpha: 0.25),
                                        onTap: widget.onAddPressed,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 
                                                    0.12 +
                                                        (_glowAnimation.value *
                                                            0.03)),
                                                blurRadius: 4 +
                                                    (_glowAnimation.value * 2),
                                                offset: const Offset(0, 2),
                                                spreadRadius: 0.3 +
                                                    (_glowAnimation.value *
                                                        0.2),
                                              ),
                                              // Subtle glow shadow
                                              BoxShadow(
                                                color: effectivePrimaryColor
                                                    .withValues(alpha: 0.15 *
                                                        _glowAnimation.value),
                                                blurRadius: 8 +
                                                    (_glowAnimation.value * 3),
                                                offset: const Offset(0, 0),
                                                spreadRadius:
                                                    _glowAnimation.value * 1,
                                              ),
                                            ],
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 
                                                  0.4 +
                                                      (_glowAnimation.value *
                                                          0.1)),
                                              width: 1.5,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                effectiveLightColor.withValues(alpha: 
                                                    0.75 +
                                                        (_glowAnimation.value *
                                                            0.05)),
                                                effectivePrimaryColor.withValues(alpha: 
                                                    0.75 +
                                                        (_glowAnimation.value *
                                                            0.05)),
                                              ],
                                            ),
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              // Refined glow effect
                                              Container(
                                                width: 22 +
                                                    (math.sin(_pulseAnimation
                                                                .value *
                                                            math.pi) *
                                                        2),
                                                height: 22 +
                                                    (math.sin(_pulseAnimation
                                                                .value *
                                                            math.pi) *
                                                        2),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: RadialGradient(
                                                    colors: [
                                                      Colors.white.withValues(alpha: 
                                                          0.25 +
                                                              (_glowAnimation
                                                                      .value *
                                                                  0.1)),
                                                      Colors.white
                                                          .withValues(alpha: 0.0),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Icon with subtle animation
                                              Transform.rotate(
                                                angle: math.sin(
                                                        _glowAnimation.value *
                                                            2 *
                                                            math.pi) *
                                                    0.03,
                                                child: Icon(
                                                  Icons.add_rounded,
                                                  color: Colors.white,
                                                  size: 24,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black
                                                          .withValues(alpha: 0.3),
                                                      offset: const Offset(0, 1),
                                                      blurRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                                .animate()
                                .fadeIn(
                                    duration: 400.ms,
                                    curve: Curves.easeOutCubic)
                                .slideX(
                                    begin: 0.2,
                                    end:
                                        0), // No divider between archive and add buttons
                          const SizedBox(),

                          // // Add divider before the Archive button
                          // widget.showArchiveButton
                          //     ? Container(
                          //         height: 24,
                          //         width: 1.5,
                          //         margin: const EdgeInsets.only(right: 8.0),
                          //         decoration: BoxDecoration(
                          //           gradient: LinearGradient(
                          //             begin: Alignment.topCenter,
                          //             end: Alignment.bottomCenter,
                          //             colors: [
                          //               Colors.white.withValues(alpha: 0.0),
                          //               Colors.white.withValues(alpha: 0.4),
                          //               Colors.white.withValues(alpha: 0.0),
                          //             ],
                          //           ),
                          //         ),
                          //       )
                          //         .animate()
                          //         .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                          // : SizedBox(),                          // Refined Archive Button - elegant and subtle animations
                          if (widget.showArchiveButton)
                            Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: AnimatedBuilder(
                                animation: Listenable.merge([
                                  _glowAnimationController,
                                  _pulseAnimationController,
                                ]),
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1.0 +
                                        (math.sin(_pulseAnimation.value *
                                                    math.pi +
                                                0.5) *
                                            0.015),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(50),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(50),
                                        highlightColor:
                                            Colors.white.withValues(alpha: 0.15),
                                        splashColor:
                                            Colors.white.withValues(alpha: 0.25),
                                        onTap: widget.onArchivePressed,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 
                                                    0.12 +
                                                        (_glowAnimation.value *
                                                            0.02)),
                                                blurRadius: 4 +
                                                    (_glowAnimation.value *
                                                        1.5),
                                                offset: const Offset(0, 2),
                                                spreadRadius: 0.3 +
                                                    (_glowAnimation.value *
                                                        0.15),
                                              ),
                                              // Subtle glow shadow
                                              BoxShadow(
                                                color: effectiveLightColor
                                                    .withValues(alpha: 0.12 *
                                                        _glowAnimation.value),
                                                blurRadius: 6 +
                                                    (_glowAnimation.value * 2),
                                                offset: const Offset(0, 0),
                                                spreadRadius:
                                                    _glowAnimation.value * 0.8,
                                              ),
                                            ],
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 
                                                  0.4 +
                                                      (_glowAnimation.value *
                                                          0.08)),
                                              width: 1.5,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                effectiveLightColor.withValues(alpha: 
                                                    0.75 +
                                                        (_glowAnimation.value *
                                                            0.04)),
                                                effectivePrimaryColor.withValues(alpha: 
                                                    0.75 +
                                                        (_glowAnimation.value *
                                                            0.04)),
                                              ],
                                            ),
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              // Refined glow effect
                                              Container(
                                                width: 22 +
                                                    (math.sin(_pulseAnimation
                                                                    .value *
                                                                math.pi +
                                                            0.5) *
                                                        1.5),
                                                height: 22 +
                                                    (math.sin(_pulseAnimation
                                                                    .value *
                                                                math.pi +
                                                            0.5) *
                                                        1.5),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: RadialGradient(
                                                    colors: [
                                                      Colors.white.withValues(alpha: 
                                                          0.25 +
                                                              (_glowAnimation
                                                                      .value *
                                                                  0.08)),
                                                      Colors.white
                                                          .withValues(alpha: 0.0),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Icon with gentle animation
                                              Transform.rotate(
                                                angle: math.sin(
                                                        _glowAnimation.value *
                                                                2 *
                                                                math.pi +
                                                            1) *
                                                    0.02,
                                                child: _buildIcon(
                                                  widget.archiveIcon ??
                                                      Icons.archive_rounded,
                                                  color: Colors.white,
                                                  size: 24,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black
                                                          .withValues(alpha: 0.3),
                                                      offset: const Offset(0, 1),
                                                      blurRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                                .animate()
                                .fadeIn(
                                    duration: 500.ms,
                                    curve: Curves.easeOutCubic)
                                .slideX(begin: 0.2, end: 0),

                          // Refined Filter Button - elegant and subtle animations
                          if (widget.showFilterButton)
                            Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: AnimatedBuilder(
                                animation: Listenable.merge([
                                  _glowAnimationController,
                                  _pulseAnimationController,
                                ]),
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1.0 +
                                        (math.sin(_pulseAnimation.value *
                                                    math.pi +
                                                1) *
                                            0.01),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(50),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(50),
                                        highlightColor:
                                            Colors.white.withValues(alpha: 0.15),
                                        splashColor:
                                            Colors.white.withValues(alpha: 0.25),
                                        onTap: widget.onFilterPressed,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: widget.filterActive
                                              ? BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(alpha: 0.12),
                                                      blurRadius: 6,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                  border: Border.all(
                                                      color: effectivePrimaryColor
                                                          .withValues(alpha: 0.12),
                                                      width: 1.0),
                                                )
                                              : BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(alpha: 0.12 +
                                                              (_glowAnimation
                                                                      .value *
                                                                  0.02)),
                                                      blurRadius: 4 +
                                                          (_glowAnimation
                                                                  .value *
                                                              1.2),
                                                      offset:
                                                          const Offset(0, 2),
                                                      spreadRadius: 0.3 +
                                                          (_glowAnimation
                                                                  .value *
                                                              0.12),
                                                    ),
                                                    // Subtle glow shadow
                                                    BoxShadow(
                                                      color: effectiveLightColor
                                                          .withValues(alpha: 0.1 *
                                                              _glowAnimation
                                                                  .value),
                                                      blurRadius: 5 +
                                                          (_glowAnimation
                                                                  .value *
                                                              1.5),
                                                      offset:
                                                          const Offset(0, 0),
                                                      spreadRadius:
                                                          _glowAnimation.value *
                                                              0.6,
                                                    ),
                                                  ],
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.4 +
                                                            (_glowAnimation
                                                                    .value *
                                                                0.06)),
                                                    width: 1.5,
                                                  ),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      effectiveLightColor
                                                          .withValues(alpha: 0.75 +
                                                              (_glowAnimation
                                                                      .value *
                                                                  0.03)),
                                                      effectivePrimaryColor
                                                          .withValues(alpha: 0.75 +
                                                              (_glowAnimation
                                                                      .value *
                                                                  0.03)),
                                                    ],
                                                  ),
                                                ),
                                          child: widget.filterActive
                                              ? Center(
                                                  child: Icon(
                                                    Icons.filter_list,
                                                    color: effectivePrimaryColor,
                                                    size: 24,
                                                  ),
                                                )
                                              : Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    // Refined glow effect
                                                    Container(
                                                      width: 22 +
                                                          (math.sin(_pulseAnimation
                                                                          .value *
                                                                      math.pi +
                                                                  1) *
                                                              1),
                                                      height: 22 +
                                                          (math.sin(_pulseAnimation
                                                                          .value *
                                                                      math.pi +
                                                                  1) *
                                                              1),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        gradient:
                                                            RadialGradient(
                                                          colors: [
                                                            Colors.white
                                                                .withValues(alpha: 0.25 +
                                                                    (_glowAnimation
                                                                            .value *
                                                                        0.06)),
                                                            Colors.white
                                                                .withValues(alpha: 
                                                                    0.0),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    // Icon with gentle floating animation
                                                    Transform.translate(
                                                      offset: Offset(
                                                          0,
                                                          math.sin(_glowAnimation
                                                                          .value *
                                                                      2 *
                                                                      math.pi +
                                                                  2) *
                                                              0.5),
                                                      child: Icon(
                                                        Icons.filter_list,
                                                        color: Colors.white,
                                                        size: 24,
                                                        shadows: [
                                                          Shadow(
                                                            color: Colors.black
                                                                .withValues(alpha: 
                                                                    0.3),
                                                            offset:
                                                                const Offset(0, 1),
                                                            blurRadius: 2,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                                .animate()
                                .fadeIn(
                                    duration: 600.ms,
                                    curve: Curves.easeOutCubic)
                                .slideX(begin: 0.2, end: 0),

                          // Refined Search Button - elegant and subtle animations
                          if (widget.showSearchButton)
                            Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: AnimatedBuilder(
                                animation: Listenable.merge([
                                  _glowAnimationController,
                                  _pulseAnimationController,
                                ]),
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1.0 +
                                        (math.sin(_pulseAnimation.value *
                                                    math.pi +
                                                1.2) *
                                            0.012),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(50),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(50),
                                        highlightColor:
                                            Colors.white.withValues(alpha: 0.15),
                                        splashColor:
                                            Colors.white.withValues(alpha: 0.25),
                                        onTap: widget.onSearchPressed,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 
                                                    0.12 +
                                                        (_glowAnimation.value *
                                                            0.02)),
                                                blurRadius: 4 +
                                                    (_glowAnimation.value *
                                                        1.3),
                                                offset: const Offset(0, 2),
                                                spreadRadius: 0.3 +
                                                    (_glowAnimation.value *
                                                        0.13),
                                              ),
                                              // Subtle glow shadow
                                              BoxShadow(
                                                color: effectivePrimaryColor
                                                    .withValues(alpha: 0.12 *
                                                        _glowAnimation.value),
                                                blurRadius: 6 +
                                                    (_glowAnimation.value * 2),
                                                offset: const Offset(0, 0),
                                                spreadRadius:
                                                    _glowAnimation.value * 0.7,
                                              ),
                                            ],
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 
                                                  0.4 +
                                                      (_glowAnimation.value *
                                                          0.07)),
                                              width: 1.5,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                effectiveLightColor.withValues(alpha: 
                                                    0.75 +
                                                        (_glowAnimation.value *
                                                            0.04)),
                                                effectivePrimaryColor.withValues(alpha: 
                                                    0.75 +
                                                        (_glowAnimation.value *
                                                            0.04)),
                                              ],
                                            ),
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              // Refined glow effect
                                              Container(
                                                width: 22 +
                                                    (math.sin(_pulseAnimation
                                                                    .value *
                                                                math.pi +
                                                            1.2) *
                                                        1.2),
                                                height: 22 +
                                                    (math.sin(_pulseAnimation
                                                                    .value *
                                                                math.pi +
                                                            1.2) *
                                                        1.2),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: RadialGradient(
                                                    colors: [
                                                      Colors.white.withValues(alpha: 
                                                          0.25 +
                                                              (_glowAnimation
                                                                      .value *
                                                                  0.07)),
                                                      Colors.white
                                                          .withValues(alpha: 0.0),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Icon with gentle rotation animation
                                              Transform.rotate(
                                                angle: math.sin(
                                                        _glowAnimation.value *
                                                                2 *
                                                                math.pi +
                                                            1.8) *
                                                    0.025,
                                                child: Icon(
                                                  Icons.search_rounded,
                                                  color: Colors.white,
                                                  size: 24,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black
                                                          .withValues(alpha: 0.3),
                                                      offset: const Offset(0, 1),
                                                      blurRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                                .animate()
                                .fadeIn(
                                    duration: 550.ms,
                                    curve: Curves.easeOutCubic)
                                .slideX(begin: 0.2, end: 0),

                          // Refined Helper Button - elegant and subtle animations
                          if (widget.showHelperButton)
                            Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: AnimatedBuilder(
                                animation: Listenable.merge([
                                  _glowAnimationController,
                                  _pulseAnimationController,
                                ]),
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1.0 +
                                        (math.sin(_pulseAnimation.value *
                                                    math.pi +
                                                1.5) *
                                            0.008),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(50),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(50),
                                        highlightColor:
                                            Colors.white.withValues(alpha: 0.15),
                                        splashColor:
                                            Colors.white.withValues(alpha: 0.25),
                                        onTap: widget.onHelperPressed,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 
                                                    0.12 +
                                                        (_glowAnimation.value *
                                                            0.015)),
                                                blurRadius: 4 +
                                                    (_glowAnimation.value * 1),
                                                offset: const Offset(0, 2),
                                                spreadRadius: 0.3 +
                                                    (_glowAnimation.value *
                                                        0.1),
                                              ),
                                              // Subtle glow shadow
                                              BoxShadow(
                                                color: effectivePrimaryColor
                                                    .withValues(alpha: 0.08 *
                                                        _glowAnimation.value),
                                                blurRadius: 4 +
                                                    (_glowAnimation.value * 1),
                                                offset: const Offset(0, 0),
                                                spreadRadius:
                                                    _glowAnimation.value * 0.5,
                                              ),
                                            ],
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 
                                                  0.4 +
                                                      (_glowAnimation.value *
                                                          0.04)),
                                              width: 1.5,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                effectiveLightColor.withValues(alpha: 
                                                    0.75 +
                                                        (_glowAnimation.value *
                                                            0.02)),
                                                effectivePrimaryColor.withValues(alpha: 
                                                    0.75 +
                                                        (_glowAnimation.value *
                                                            0.02)),
                                              ],
                                            ),
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              // Refined glow effect
                                              Container(
                                                width: 22 +
                                                    (math.sin(_pulseAnimation
                                                                    .value *
                                                                math.pi +
                                                            1.5) *
                                                        0.8),
                                                height: 22 +
                                                    (math.sin(_pulseAnimation
                                                                    .value *
                                                                math.pi +
                                                            1.5) *
                                                        0.8),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: RadialGradient(
                                                    colors: [
                                                      Colors.white.withValues(alpha: 
                                                          0.25 +
                                                              (_glowAnimation
                                                                      .value *
                                                                  0.05)),
                                                      Colors.white
                                                          .withValues(alpha: 0.0),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Icon with gentle pulsing
                                              Transform.scale(
                                                scale: 1.0 +
                                                    (math.sin(_glowAnimation
                                                                    .value *
                                                                2 *
                                                                math.pi +
                                                            3) *
                                                        0.02),
                                                child: _buildIcon(
                                                  widget.helperIcon ??
                                                      Icons.help,
                                                  color: Colors.white,
                                                  size: 24,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black
                                                          .withValues(alpha: 0.3),
                                                      offset: const Offset(0, 1),
                                                      blurRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                                .animate()
                                .fadeIn(
                                    duration: 700.ms,
                                    curve: Curves.easeOutCubic)
                                .slideX(begin: 0.2, end: 0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tab content if provided
                if (widget.tabBuilder != null)
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
                          child: widget.tabBuilder!(context),
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
    );
      },
    );
  }
}

// Enhanced custom painter for animated decorative elements in the app bar
class AnimatedAppBarDecorationPainter extends CustomPainter {
  final Color color;
  final double glowValue;
  final double pulseValue;
  final double rotationValue;

  AnimatedAppBarDecorationPainter({
    required this.color,
    required this.glowValue,
    required this.pulseValue,
    required this.rotationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Optimized decorative circles - reduced number and complexity to prevent buffer spam
    final circles = [
      {
        'center': Offset(
            size.width * (0.88 + math.sin(glowValue * 2 * math.pi) * 0.01),
            size.height * (0.22 + math.cos(glowValue * 2 * math.pi) * 0.008)),
        'radius': 20 * (0.9 + math.sin(pulseValue * math.pi) * 0.1),
      },
      {
        'center': Offset(
            size.width *
                (0.12 + math.cos(glowValue * 2 * math.pi + 1.5) * 0.008),
            size.height *
                (0.78 + math.sin(glowValue * 2 * math.pi + 1.5) * 0.01)),
        'radius': 15 * (0.95 + math.sin(pulseValue * math.pi + 0.5) * 0.08),
      },
      {
        'center': Offset(
            size.width * (0.52 + math.sin(glowValue * 2 * math.pi + 3) * 0.012),
            size.height *
                (0.18 + math.cos(glowValue * 2 * math.pi + 3) * 0.006)),
        'radius': 10 * (1.0 + math.sin(pulseValue * math.pi + 1) * 0.12),
      },
    ];

    // Draw optimized animated circles
    for (var circle in circles) {
      final center = circle['center'] as Offset;
      final radius = circle['radius'] as double;
      canvas.drawCircle(center, radius, paint);
    }

    // Simplified animated arc
    final arcPaint = Paint()
      ..color = color.withValues(alpha: color.a * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final arcRect = Rect.fromLTRB(
        size.width * (0.12 + math.sin(glowValue * 2 * math.pi) * 0.02),
        size.height * (0.25 + math.cos(glowValue * 2 * math.pi) * 0.015),
        size.width * (0.58 + math.sin(glowValue * 2 * math.pi + 1) * 0.025),
        size.height * (0.58 + math.cos(glowValue * 2 * math.pi + 1) * 0.02));

    final arcSweep = 1.1 + math.sin(glowValue * 2 * math.pi) * 0.15;
    canvas.drawArc(arcRect, 0.3 + rotationValue * 0.05, arcSweep, false, arcPaint);

    // Optimized floating particles
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2.094) + rotationValue * 0.3; // 2.094 = 2π/3
      final baseDistance = 25 + math.sin(glowValue * 2 * math.pi + i) * 8;
      
      final particleCenter = Offset(
        size.width * 0.5 + (baseDistance * math.cos(angle)),
        size.height * 0.5 + (baseDistance * math.sin(angle)),
      );

      canvas.drawCircle(particleCenter, 1.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedAppBarDecorationPainter oldDelegate) {
    return oldDelegate.glowValue != glowValue ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.rotationValue != rotationValue;
  }
}

// Keep the original painter for backward compatibility
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
