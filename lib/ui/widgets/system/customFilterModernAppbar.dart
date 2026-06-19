import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math' as math;

/// A modern, animated AppBar with customizable filters
/// Provides a premium look with frosted glass effects, animations, and custom gradients
class CustomFilterModernAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  /// The title to display in the appbar
  final String title;

  /// The icon to display next to the title
  final IconData titleIcon;

  /// Primary color for the AppBar gradient
  final Color primaryColor;

  /// Secondary color for the AppBar gradient
  final Color? secondaryColor;

  /// Optional callback when the back button is pressed
  final VoidCallback? onBackPressed;

  /// Optional callback to provide custom animation controller
  final AnimationController? animationController;

  /// First filter widget - shown on the left side of the filter row
  final FilterItemConfig? firstFilterItem;

  /// Second filter widget - shown in the middle of the filter row
  final FilterItemConfig? secondFilterItem;

  /// Third filter widget - shown on the right side of the filter row
  final FilterItemConfig? thirdFilterItem;

  /// Whether to enable animations on the AppBar
  final bool enableAnimations;

  /// Optional gradient colors for the background
  final List<Color>? gradientColors;

  /// Total height of the AppBar (including status bar)
  final double? height;

  /// Whether to show filters row or not
  final bool showFiltersRow;

  /// Whether to show search button
  final bool showSearchButton;

  /// Search button callback
  final VoidCallback? onSearchPressed;

  /// Whether search is currently active
  final bool isSearchActive;
  const CustomFilterModernAppBar({
    super.key,
    required this.title,
    this.titleIcon = Icons.dashboard_rounded,
    required this.primaryColor,
    this.secondaryColor,
    this.onBackPressed,
    this.animationController,
    this.firstFilterItem,
    this.secondFilterItem,
    this.thirdFilterItem,
    this.enableAnimations = true,
    this.gradientColors,
    this.height,
    this.showFiltersRow = true,
    this.showSearchButton = false,
    this.onSearchPressed,
    this.isSearchActive = false,
  });

  @override
  State<CustomFilterModernAppBar> createState() =>
      _CustomFilterModernAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(height ?? 150);
}

class _CustomFilterModernAppBarState extends State<CustomFilterModernAppBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _glowAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _rotationAnimationController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = widget.animationController ??
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
          value: 1.0, // Start with full value when not externally controlled
        );

    if (widget.animationController == null && widget.enableAnimations) {
      _animationController.forward();
    }

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
      // Ditambahkan cek mounted
      if (mounted) {
        _pulseAnimationController.repeat(reverse: true);
      }
    });
    
    Future.delayed(const Duration(milliseconds: 1000), () {
      // Ditambahkan cek mounted
      if (mounted) {
        _rotationAnimationController.repeat();
      }
    });
  }

  @override
  void dispose() {
    // Only dispose if we created the controller internally
    if (widget.animationController == null) {
      _animationController.dispose();
    }
    _glowAnimationController.dispose();
    _pulseAnimationController.dispose();
    _rotationAnimationController.dispose();
    super.dispose();
  }

  Color get _secondaryColor =>
      widget.secondaryColor ?? _getLightenedColor(widget.primaryColor, 0.3);

  /// Helper function to generate a lighter version of a color
  Color _getLightenedColor(Color baseColor, double factor) {
    HSLColor hsl = HSLColor.fromColor(baseColor);
    return hsl
        .withLightness((hsl.lightness + factor).clamp(0.0, 1.0))
        .toColor();
  }

  /// Helper function to generate a darkened version of a color
  Color _getDarkenedColor(Color baseColor, double factor) {
    HSLColor hsl = HSLColor.fromColor(baseColor);
    return hsl
        .withLightness((hsl.lightness - factor).clamp(0.0, 1.0))
        .toColor();
  }

  List<Color> get _gradientColors =>
      widget.gradientColors ??
      [
        _getDarkenedColor(widget.primaryColor, 0.1),
        widget.primaryColor,
        _getLightenedColor(widget.primaryColor, 0.1),
        _secondaryColor,
      ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.preferredSize.height,
      child: Stack(
        children: [
          // Fancy gradient background with animated particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, _) {
                return ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _gradientColors,
                      stops: const [0.0, 0.3, 0.6, 1.0],
                      transform: GradientRotation(widget.enableAnimations
                          ? _animationController.value * 0.02
                          : 0),
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcATop,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.primaryColor,
                          _secondaryColor,
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
          ),
          // Refined animated glowing effect - more subtle and elegant
          AnimatedBuilder(
            animation: Listenable.merge([
              _animationController,
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
                        (_animationController.value * 15) +
                        (math.sin(_glowAnimation.value * 2 * math.pi) * 5),
                    right: -60 +
                        (_animationController.value * 8) +
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
                        (_animationController.value * 10) +
                        (math.sin(_glowAnimation.value * 2 * math.pi + 1.5) *
                            4),
                    left: -30 +
                        (_animationController.value * 5) +
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
          ), // Main app bar content with frosted glass effect - TOP ROW
          Positioned(
            top: MediaQuery.of(context).padding.top + 5, // Moved up slightly
            left: 16,
            right: 16,
            child: ClipRRect(
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
                      if (widget.onBackPressed != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              highlightColor: Colors.white.withValues(alpha: 0.1),
                              splashColor: Colors.white.withValues(alpha: 0.2),
                              onTap: widget.onBackPressed,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Animated divider when back button is present
                      if (widget.onBackPressed != null)
                        Container(
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
                        ),

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
                                  if (widget.enableAnimations)
                                    AnimatedBuilder(
                                      animation: _animationController,
                                      builder: (context, child) {
                                        return Transform.rotate(
                                          angle:
                                              _animationController.value * 0.05,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.white.withValues(alpha: 0.9),
                                                  Colors.white.withValues(alpha: 0.4),
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
                                            child: Icon(
                                              widget.titleIcon,
                                              color: widget.primaryColor,
                                              size: 20,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withValues(alpha: 0.9),
                                            Colors.white.withValues(alpha: 0.4),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withValues(alpha: 0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        widget.titleIcon,
                                        color: widget.primaryColor,
                                        size: 20,
                                      ),
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
                                        fontSize: 14,
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

                      // Search button (if enabled)
                      if (widget.showSearchButton &&
                          widget.onSearchPressed != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              highlightColor: Colors.white.withValues(alpha: 0.1),
                              splashColor: Colors.white.withValues(alpha: 0.2),
                              onTap: widget.onSearchPressed,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: widget.isSearchActive
                                      ? Border.all(
                                          color: Colors.white.withValues(alpha: 0.4),
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  transitionBuilder: (Widget child,
                                      Animation<double> animation) {
                                    return RotationTransition(
                                      turns: Tween<double>(begin: 0.5, end: 1.0)
                                          .animate(animation),
                                      child: ScaleTransition(
                                        scale: animation,
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                                  child: widget.isSearchActive
                                      ? const Icon(
                                          Icons.close_rounded,
                                          key: ValueKey<bool>(true),
                                          color: Colors.white,
                                          size: 22,
                                        )
                                      : const Icon(
                                          Icons.search_rounded,
                                          key: ValueKey<bool>(false),
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Optional space for action buttons
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
          ), // BOTTOM ROW - Filters with frosted glass effect (when filters are enabled)
          if (widget.showFiltersRow &&
              (widget.firstFilterItem != null ||
                  widget.secondFilterItem != null ||
                  widget.thirdFilterItem != null))
            Positioned(
              bottom: 16, // Position closer to the bottom
              left: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    // Use taller container and column layout when there are three filters
                    height: widget.thirdFilterItem != null
                        ? 120
                        : 70, // Increased height for better spacing
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: widget.thirdFilterItem != null
                        ? Column(
                            children: [
                              // Top row with two filters
                              Expanded(
                                child: Row(
                                  children: [
                                    // First filter item
                                    if (widget.firstFilterItem != null)
                                      Expanded(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap:
                                                widget.firstFilterItem!.onTap,
                                            highlightColor:
                                                Colors.white.withValues(alpha: 0.1),
                                            splashColor:
                                                Colors.white.withValues(alpha: 0.2),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    widget
                                                        .firstFilterItem!.icon,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      widget.firstFilterItem!
                                                          .title,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Divider between first and second filters
                                    if (widget.firstFilterItem != null &&
                                        widget.secondFilterItem != null)
                                      Container(
                                        height: 24,
                                        width: 1.5,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 8),
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
                                      ),

                                    // Second filter item
                                    if (widget.secondFilterItem != null)
                                      Expanded(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap:
                                                widget.secondFilterItem!.onTap,
                                            highlightColor:
                                                Colors.white.withValues(alpha: 0.1),
                                            splashColor:
                                                Colors.white.withValues(alpha: 0.2),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    widget
                                                        .secondFilterItem!.icon,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      widget.secondFilterItem!
                                                          .title,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Horizontal divider
                              Container(
                                height: 1.5,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.0),
                                      Colors.white.withValues(alpha: 0.4),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),

                              // Bottom row with third filter
                              if (widget.thirdFilterItem != null)
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: widget.thirdFilterItem!.onTap,
                                      highlightColor:
                                          Colors.white.withValues(alpha: 0.1),
                                      splashColor:
                                          Colors.white.withValues(alpha: 0.2),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              widget.thirdFilterItem!.icon,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                widget.thirdFilterItem!.title,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Row(
                            children: [
                              // First filter item
                              if (widget.firstFilterItem != null)
                                _buildFilterItem(
                                  widget.firstFilterItem!.icon,
                                  widget.firstFilterItem!.title,
                                  widget.firstFilterItem!.onTap,
                                  expanded: true,
                                ),

                              // Divider between first and second filters
                              if (widget.firstFilterItem != null &&
                                  widget.secondFilterItem != null)
                                Container(
                                  height: 24,
                                  width: 1.5,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal:
                                          12), // Increased horizontal margin for more spacing
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
                                ),

                              // Second filter item
                              if (widget.secondFilterItem != null)
                                _buildFilterItem(
                                  widget.secondFilterItem!.icon,
                                  widget.secondFilterItem!.title,
                                  widget.secondFilterItem!.onTap,
                                  expanded: true,
                                ),
                            ],
                          ),
                  ),
                ),
              ),
            )
                .animate(
                  controller: _animationController,
                )
                .fadeIn(
                  duration: 500.ms,
                  delay: 200.ms,
                )
                .slideY(
                  begin: -0.2,
                  end: 0,
                  curve: Curves.easeOutQuad,
                ),
        ],
      ),
    );
  }

  Widget _buildFilterItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool expanded = true,
  }) {
    return expanded
        ? Expanded(
            child: _buildFilterItemContent(icon, title, onTap),
          )
        : _buildFilterItemContent(icon, title, onTap);
  }

  Widget _buildFilterItemContent(
      IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Add haptic feedback for better UX
          HapticFeedback.lightImpact();
          onTap();
        },
        highlightColor: Colors.white.withValues(alpha: 0.1),
        splashColor: Colors.white.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 14), // Increased padding for more space
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 18, // Slightly larger icon
              ),
              const SizedBox(
                  width: 10), // Increased spacing between icon and text
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    letterSpacing:
                        0.3, // Added letter spacing for better readability
                    fontWeight: FontWeight.w500, // Slightly bolder text
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Configuration for a filter item in the AppBar
class FilterItemConfig {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  FilterItemConfig({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

/// Custom painter for decorative elements in the AppBar
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

    final glowPaint = Paint()
      ..color = color.withValues(alpha: color.a * (0.3 + glowValue * 0.3))
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1 + glowValue * 2);

    // Refined animated decorative circles - more subtle movement
    final circles = [
      {
        'center': Offset(
            size.width * (0.88 + math.sin(glowValue * 2 * math.pi) * 0.01),
            size.height * (0.22 + math.cos(glowValue * 2 * math.pi) * 0.008)),
        'radius': 25 * (0.9 + math.sin(pulseValue * math.pi) * 0.15),
        'hasGlow': true,
      },
      {
        'center': Offset(
            size.width *
                (0.12 + math.cos(glowValue * 2 * math.pi + 1.5) * 0.008),
            size.height *
                (0.78 + math.sin(glowValue * 2 * math.pi + 1.5) * 0.01)),
        'radius': 18 * (0.95 + math.sin(pulseValue * math.pi + 0.5) * 0.1),
        'hasGlow': false,
      },
      {
        'center': Offset(
            size.width * (0.52 + math.sin(glowValue * 2 * math.pi + 3) * 0.012),
            size.height *
                (0.18 + math.cos(glowValue * 2 * math.pi + 3) * 0.006)),
        'radius': 12 * (1.0 + math.sin(pulseValue * math.pi + 1) * 0.2),
        'hasGlow': true,
      },
      {
        'center': Offset(
            size.width *
                (0.72 + math.cos(glowValue * 2 * math.pi + 4.5) * 0.008),
            size.height *
                (0.68 + math.sin(glowValue * 2 * math.pi + 4.5) * 0.01)),
        'radius': 8 * (0.8 + math.sin(pulseValue * math.pi + 1.5) * 0.3),
        'hasGlow': false,
      },
      {
        'center': Offset(
            size.width * (0.25 + math.sin(glowValue * 2 * math.pi + 6) * 0.01),
            size.height *
                (0.42 + math.cos(glowValue * 2 * math.pi + 6) * 0.008)),
        'radius': 6 * (1.0 + math.sin(pulseValue * math.pi + 2) * 0.15),
        'hasGlow': true,
      },
    ];

    // Draw refined animated circles
    for (var circle in circles) {
      final center = circle['center'] as Offset;
      final radius = circle['radius'] as double;
      final hasGlow = circle['hasGlow'] as bool;

      if (hasGlow) {
        // Draw subtle glow effect
        canvas.drawCircle(center, radius * 1.3, glowPaint);
      }
      // Draw main circle
      canvas.drawCircle(center, radius, paint);
    }

    // Refined animated arcs - smoother movement
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 + glowValue * 0.5;

    final glowArcPaint = Paint()
      ..color = color.withValues(alpha: color.a * (0.2 + glowValue * 0.3))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 + glowValue * 1
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.5 + glowValue * 1.5);

    // First refined animated arc
    final arcRect = Rect.fromLTRB(
        size.width * (0.12 + math.sin(glowValue * 2 * math.pi) * 0.02),
        size.height * (0.25 + math.cos(glowValue * 2 * math.pi) * 0.015),
        size.width * (0.58 + math.sin(glowValue * 2 * math.pi + 1) * 0.025),
        size.height * (0.58 + math.cos(glowValue * 2 * math.pi + 1) * 0.02));

    final arcSweep = 1.2 + math.sin(glowValue * 2 * math.pi) * 0.2;
    final arcStart = 0.3 + rotationValue * 0.05;

    // Draw subtle glow arc
    canvas.drawArc(arcRect, arcStart, arcSweep, false, glowArcPaint);
    // Draw main arc
    canvas.drawArc(arcRect, arcStart, arcSweep, false, arcPaint);

    // Second refined animated arc
    final arcRect2 = Rect.fromLTRB(
        size.width * (0.48 + math.cos(glowValue * 2 * math.pi + 2) * 0.015),
        size.height * (0.42 + math.sin(glowValue * 2 * math.pi + 2) * 0.01),
        size.width * (0.88 + math.cos(glowValue * 2 * math.pi + 3) * 0.02),
        size.height * (0.78 + math.sin(glowValue * 2 * math.pi + 3) * 0.015));

    final arcSweep2 = 1.3 + math.sin(glowValue * 2 * math.pi + 1) * 0.15;
    final arcStart2 = 2.8 - rotationValue * 0.08;

    // Draw subtle glow arc
    canvas.drawArc(arcRect2, arcStart2, arcSweep2, false, glowArcPaint);
    // Draw main arc
    canvas.drawArc(arcRect2, arcStart2, arcSweep2, false, arcPaint);

    // Refined floating particles - gentler movement
    for (int i = 0; i < 6; i++) {
      final angle = (i * 1.047) + rotationValue * 0.3; // 1.047 = 2π/6
      final baseDistance = 25 + math.sin(glowValue * 2 * math.pi + i) * 8;
      final particleSize =
          1.5 + math.sin(glowValue * 2 * math.pi + i * 1.5) * 0.8;

      final particleCenter = Offset(
        size.width * 0.5 + (baseDistance * math.cos(angle)),
        size.height * 0.5 + (baseDistance * math.sin(angle)),
      );

      final particlePaint = Paint()
        ..color = color
            .withValues(alpha: 0.4 + math.sin(glowValue * 2 * math.pi + i * 2) * 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(particleCenter, particleSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedAppBarDecorationPainter oldDelegate) {
    return oldDelegate.glowValue != glowValue ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.rotationValue != rotationValue;
  }
}
