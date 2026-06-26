import 'package:cached_network_image/cached_network_image.dart';
import 'package:eschool_saas_staff/cubits/authentication/authCubit.dart';
import 'package:eschool_saas_staff/cubits/settings/appThemeCubit.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';
import 'package:eschool_saas_staff/cubits/userDetails/staffAllowedPermissionsAndModulesCubit.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/academicsContainer/widgets/staffAcademicsContainer.dart';
import 'package:eschool_saas_staff/ui/screens/home/widgets/academicsContainer/widgets/teacherAcademicsContainer.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customCircularProgressIndicator.dart';
import 'package:eschool_saas_staff/ui/widgets/system/customErrorWidget.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class AcademicsContainer extends StatefulWidget {
  const AcademicsContainer({super.key});

  @override
  State<AcademicsContainer> createState() => _AcademicsContainerState();
}

class _AcademicsContainerState extends State<AcademicsContainer>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _glowAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _rotationAnimationController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _glowAnimationController.stop();
        _pulseAnimationController.stop();
        _rotationAnimationController.stop();
        break;
      case AppLifecycleState.resumed:
        if (!_glowAnimationController.isAnimating) {
          _glowAnimationController.repeat(reverse: true);
        }
        if (!_pulseAnimationController.isAnimating) {
          _pulseAnimationController.repeat(reverse: true);
        }
        if (!_rotationAnimationController.isAnimating) {
          _rotationAnimationController.repeat();
        }
        break;
      case AppLifecycleState.inactive:
        _glowAnimationController.stop();
        _pulseAnimationController.stop();
        _rotationAnimationController.stop();
        break;
      case AppLifecycleState.detached:
        _glowAnimationController.stop();
        _pulseAnimationController.stop();
        _rotationAnimationController.stop();
        break;
      case AppLifecycleState.hidden:
        _glowAnimationController.stop();
        _pulseAnimationController.stop();
        _rotationAnimationController.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _glowAnimationController.dispose();
    _pulseAnimationController.dispose();
    _rotationAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppThemeCubit, AppThemeState>(
      builder: (context, themeState) {
        final isDark = themeState.themeMode == 'dark';

        // Set system UI overlay style to ensure status bar is properly handled
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light, // Keep light for maroon background
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ));

        // Get profile image from AuthCubit
        final profileImage =
            context.read<AuthCubit>().getUserDetails().image ?? "";

        final maroonPrimary =
            AppColorPalette.getPrimaryColor(themeState.themeMode);
        final maroonLight =
            AppColorPalette.getSecondaryColor(themeState.themeMode);
        final maroonDark = maroonPrimary.withValues(alpha: 0.8);
        final maroonMiddle = maroonPrimary.withValues(alpha: 0.9);

        return Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: BlocBuilder<StaffAllowedPermissionsAndModulesCubit,
                  StaffAllowedPermissionsAndModulesState>(
                builder: (context, state) {
                  if (state is StaffAllowedPermissionsAndModulesFetchSuccess) {
                    return SingleChildScrollView(
                        padding: EdgeInsetsDirectional.only(
                            top: Utils.appContentTopScrollPadding(
                                    context: context) +
                                20,
                            end: appContentHorizontalPadding,
                            start: appContentHorizontalPadding,
                            bottom: 100),
                        child: context.read<AuthCubit>().isTeacher()
                            ? const TeacherAcademicsContainer()
                            : const StaffAcademicsContainer());
                  } else if (state
                      is StaffAllowedPermissionsAndModulesFetchFailure) {
                    return Center(
                      child: CustomErrorWidget(
                        message: state.errorMessage,
                        onRetry: () {
                          context
                              .read<StaffAllowedPermissionsAndModulesCubit>()
                              .getPermissionAndAllowedModules();
                        },
                        primaryColor: maroonPrimary,
                      ),
                    );
                  } else {
                    return Center(
                      child: CustomCircularProgressIndicator(
                        indicatorColor: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }
                },
              ),
            ),
            // New Stylish Appbar that matches homeContainerAppbar
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 140 + MediaQuery.of(context).padding.top,
                width: MediaQuery.of(context).size.width,
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    // Background with dramatically curved bottom that extends to the top edge
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: CustomPaint(
                        painter: DramaticCurvedGradientPainter(
                          colors: [
                            maroonDark,
                            maroonPrimary,
                            maroonMiddle,
                            maroonLight,
                          ],
                          stops: const [0.0, 0.3, 0.6, 1.0],
                        ),
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
                              color: Colors.white.withValues(
                                  alpha: 0.07 + (_glowAnimation.value * 0.05)),
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
                                  (math.sin(_glowAnimation.value *
                                          2 *
                                          math.pi) *
                                      5),
                              right: -60 +
                                  (math.cos(_glowAnimation.value *
                                          2 *
                                          math.pi) *
                                      3),
                              child: Transform.scale(
                                scale: 0.95 + (_pulseAnimation.value * 0.1),
                                child: Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.white.withValues(
                                            alpha: 0.15 +
                                                (_glowAnimation.value * 0.05)),
                                        Colors.white.withValues(
                                            alpha: 0.08 +
                                                (_glowAnimation.value * 0.03)),
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
                                  (math.sin(_glowAnimation.value *
                                              2 *
                                              math.pi +
                                          1.5) *
                                      4),
                              left: -30 +
                                  (math.cos(_glowAnimation.value *
                                              2 *
                                              math.pi +
                                          1.5) *
                                      2),
                              child: Transform.scale(
                                scale: 1.0 +
                                    (math.sin(_pulseAnimation.value *
                                            math.pi) *
                                        0.05),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.white.withValues(
                                            alpha: 0.12 +
                                                (_glowAnimation.value * 0.04)),
                                        Colors.white.withValues(
                                            alpha: 0.06 +
                                                (_glowAnimation.value * 0.02)),
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
                                  (math.sin(_glowAnimation.value *
                                              2 *
                                              math.pi +
                                          3) *
                                      3),
                              right: -15 +
                                  (math.cos(_glowAnimation.value *
                                              2 *
                                              math.pi +
                                          3) *
                                      2),
                              child: Transform.rotate(
                                angle: _rotationAnimation.value * 0.3,
                                child: Transform.scale(
                                  scale: 0.9 +
                                      (math.sin(_pulseAnimation.value *
                                              math.pi +
                                          2) *
                                          0.08),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.white.withValues(
                                              alpha: 0.1 +
                                                  (_glowAnimation.value *
                                                      0.03)),
                                          Colors.white.withValues(
                                              alpha: 0.05 +
                                                  (_glowAnimation.value *
                                                      0.02)),
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
                    ),

                    // Enhanced static wave pattern
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: CustomPaint(
                        painter: EnhancedWavePatternPainter(
                          color1: Colors.white.withValues(alpha: 0.1),
                          color2: Colors.white.withValues(alpha: 0.07),
                        ),
                        child: SizedBox(
                          height: 80,
                          width: MediaQuery.of(context).size.width,
                        ),
                      ),
                    ),

                    // Animated main content container with elevation and smooth entrance
                    Positioned(
                      bottom: 10,
                      left: 16,
                      right: 16,
                      child: Container(
                        height: 75,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: maroonPrimary.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: maroonLight.withValues(alpha: 0.15),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Profile image with tap to zoom
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      backgroundColor: Colors.transparent,
                                      child: SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.9,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.7,
                                        child: Stack(
                                          children: [
                                            InteractiveViewer(
                                              minScale: 0.5,
                                              maxScale: 4.0,
                                              child: profileImage.isNotEmpty
                                                  ? CachedNetworkImage(
                                                      imageUrl: profileImage,
                                                      fit: BoxFit.contain,
                                                      placeholder:
                                                          (context, url) =>
                                                              Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                      Color>(
                                                                  maroonPrimary),
                                                        ),
                                                      ),
                                                      errorWidget: (context,
                                                              url, error) =>
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
                                                color: Colors.black
                                                    .withValues(alpha: 0.5),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  onTap: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
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
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [maroonPrimary, maroonDark],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          maroonPrimary.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(2),
                                child: CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .scaffoldBackgroundColor,
                                  radius: 25,
                                  backgroundImage: profileImage.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          profileImage,
                                        )
                                      : null,
                                  child: profileImage.isEmpty
                                      ? Icon(
                                          Icons.person,
                                          color: isDark
                                              ? Colors.white
                                              : maroonPrimary,
                                          size: 30,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15.0),
                            // Title text without animations
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Akademik",
                                    style: GoogleFonts.poppins(
                                      height: 1.1,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          isDark ? Colors.white : maroonPrimary,
                                    ),
                                  ),
                                  Text(
                                    "Kelola konten akademik",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Back button without animations
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap: () {
                                  // Navigate back or perform any action when pressed
                                },
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [maroonPrimary, maroonDark],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: maroonPrimary.withValues(
                                            alpha: 0.25),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.grid_view_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        );
      },
    );
  }
}

// Custom painter for dramatically curved gradient background with a double-wave effect
class DramaticCurvedGradientPainter extends CustomPainter {
  final List<Color> colors;
  final List<double> stops;

  DramaticCurvedGradientPainter({
    required this.colors,
    required this.stops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Create gradient
    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
      stops: stops,
    ).createShader(rect);

    // Create dramatic double-curved path with deep valleys
    final path = Path();
    path.lineTo(
        0, size.height - 60); // Start from bottom-left with larger offset

    // First dramatic curve
    final firstControlPoint = Offset(
        size.width * 0.25, size.height + 30); // Control point below the bottom
    final firstEndPoint = Offset(size.width * 0.5, size.height - 40);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    // Second dramatic curve
    final secondControlPoint = Offset(size.width * 0.75,
        size.height - 110); // Higher control point for deeper curve
    final secondEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    // Complete the path
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Add more dramatic highlights for enhanced depth
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final highlightPath = Path();
    highlightPath.moveTo(0, size.height - 58);
    highlightPath.quadraticBezierTo(firstControlPoint.dx,
        firstControlPoint.dy - 4, firstEndPoint.dx, firstEndPoint.dy - 3);
    highlightPath.quadraticBezierTo(secondControlPoint.dx,
        secondControlPoint.dy - 3, secondEndPoint.dx, secondEndPoint.dy - 3);

    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant DramaticCurvedGradientPainter oldDelegate) {
    return colors != oldDelegate.colors || stops != oldDelegate.stops;
  }
}

// Enhanced wave pattern for more visual impact
class EnhancedWavePatternPainter extends CustomPainter {
  final Color color1;
  final Color color2;

  EnhancedWavePatternPainter({
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    // First enhanced wave with more dramatic peaks and valleys
    final path = Path();
    path.moveTo(0, size.height * 0.3);

    // First dramatic curve set - more pronounced waves
    path.cubicTo(size.width * 0.15, size.height * 0.1, size.width * 0.35,
        size.height * 0.6, size.width * 0.5, size.height * 0.2);

    // Second dramatic curve set
    path.cubicTo(
        size.width * 0.65,
        size.height * -0.2, // Negative value for more extreme peak
        size.width * 0.85,
        size.height * 0.4,
        size.width,
        size.height * 0.3);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    paint.color = color1;
    canvas.drawPath(path, paint);

    // Second enhanced wave with different pattern
    final secondPath = Path();
    secondPath.moveTo(0, size.height * 0.5);

    // First dramatic curve
    secondPath.cubicTo(size.width * 0.2, size.height * 0.3, size.width * 0.4,
        size.height * 0.8, size.width * 0.6, size.height * 0.4);

    // Second dramatic curve
    secondPath.cubicTo(size.width * 0.75, size.height * 0.1, size.width * 0.9,
        size.height * 0.6, size.width, size.height * 0.35);

    secondPath.lineTo(size.width, size.height);
    secondPath.lineTo(0, size.height);
    secondPath.close();

    paint.color = color2;
    canvas.drawPath(secondPath, paint);

    // Add more dramatic decorative elements
    final circlePaint = Paint()
      ..color = color1
      ..style = PaintingStyle.fill;

    // Larger circles for better visibility
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.2), 25, circlePaint);
    canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.7), 20, circlePaint);
    canvas.drawCircle(
        Offset(size.width * 0.6, size.height * 0.6), 15, circlePaint);
  }

  @override
  bool shouldRepaint(covariant EnhancedWavePatternPainter oldDelegate) {
    return color1 != oldDelegate.color1 || color2 != oldDelegate.color2;
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
        ..color = color.withValues(
            alpha: 0.4 + math.sin(glowValue * 2 * math.pi + i * 2) * 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(particleCenter, particleSize, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedAppBarDecorationPainter oldDelegate) {
    return oldDelegate.glowValue != glowValue ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.rotationValue != rotationValue ||
        oldDelegate.color != color;
  }
}
