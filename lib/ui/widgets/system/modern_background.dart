import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';

class ModernBackground extends StatefulWidget {
  final Widget child;

  const ModernBackground({
    super.key,
    required this.child,
  });

  @override
  State<ModernBackground> createState() => _ModernBackgroundState();
}

class _ModernBackgroundState extends State<ModernBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryMaroon = AppColorPalette.primaryMaroon;
    const Color softMaroon = Color(0xFFD27D8F);
    const Color goldAccent = Color(0xFFFFD700);
    final themeName = AppColorPalette.currentTheme;

    return Stack(
      children: [
        SizedBox.expand(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: ModernCurvePainter(
                  animationValue: _controller.value,
                  primaryColor: primaryMaroon,
                  secondaryColor: softMaroon,
                  accentColor: goldAccent,
                  themeName: themeName,
                ),
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class ModernCurvePainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final String themeName;

  ModernCurvePainter({
    required this.animationValue,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.themeName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 0;

    final angle = animationValue * 2 * math.pi;

    // Adapt colors for Indonesia theme
    final Color activePrimary = themeName == 'indonesia' ? const Color(0xFFD32F2F) : primaryColor;
    final Color activeSecondary = themeName == 'indonesia' ? const Color(0xFFFFFFFF) : secondaryColor;
    final Color activeAccent = themeName == 'indonesia' ? const Color(0xFFD32F2F) : accentColor;

    // First wave (bottom layer)
    paint.color = activeSecondary.withValues(alpha: themeName == 'indonesia' ? 0.25 : 0.1);
    var path1 = Path();
    double dy1 = math.sin(angle) * 15;
    path1.moveTo(0, size.height * 0.75 + dy1);
    path1.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.85 + dy1 + math.cos(angle) * 10,
      size.width * 0.5,
      size.height * 0.75 + dy1,
    );
    path1.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.65 + dy1 - math.cos(angle) * 10,
      size.width,
      size.height * 0.75 + dy1,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    canvas.drawPath(path1, paint);

    // Second wave (middle layer)
    paint.color = activePrimary.withValues(alpha: themeName == 'indonesia' ? 0.15 : 0.1);
    var path2 = Path();
    double dy2 = math.cos(angle) * 15;
    path2.moveTo(0, size.height * 0.8 + dy2);
    path2.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.7 + dy2 + math.sin(angle) * 10,
      size.width * 0.5,
      size.height * 0.8 + dy2,
    );
    path2.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.9 + dy2 - math.sin(angle) * 10,
      size.width,
      size.height * 0.8 + dy2,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    canvas.drawPath(path2, paint);

    // Top decorative curves
    paint.color = activeAccent.withValues(alpha: 0.05);
    var path3 = Path();
    double dy3 = math.sin(angle + math.pi / 2) * 10;
    path3.moveTo(0, size.height * 0.2 + dy3);
    path3.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.1 + dy3 + math.cos(angle) * 8,
      size.width * 0.6,
      size.height * 0.2 + dy3,
    );
    path3.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.3 + dy3 - math.cos(angle) * 8,
      size.width,
      size.height * 0.2 + dy3,
    );
    path3.lineTo(size.width, 0);
    path3.lineTo(0, 0);
    canvas.drawPath(path3, paint);

    // Additional flowing curves
    paint.color = activeAccent.withValues(alpha: 0.03);
    var path4 = Path();
    double dy4 = math.cos(angle + math.pi / 2) * 10;
    path4.moveTo(0, size.height * 0.45 + dy4);
    path4.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.35 + dy4 + math.sin(angle) * 5,
      size.width * 0.7,
      size.height * 0.45 + dy4,
    );
    path4.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.5 + dy4 - math.sin(angle) * 5,
      size.width,
      size.height * 0.45 + dy4,
    );
    canvas.drawPath(path4, paint);

    // Floating circles decoration with floating/bobbing effect
    final decorPaint = Paint()
      ..color = activePrimary.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Large circle at top right
    canvas.drawCircle(
      Offset(
        size.width * 0.8 + math.sin(angle) * 10,
        size.height * 0.2 + math.cos(angle) * 10,
      ),
      30,
      decorPaint,
    );

    // Medium circle at bottom left
    canvas.drawCircle(
      Offset(
        size.width * 0.2 + math.cos(angle) * 12,
        size.height * 0.7 + math.sin(angle) * 12,
      ),
      40,
      decorPaint,
    );

    // Small floating circles
    canvas.drawCircle(
      Offset(
        size.width * 0.7 + math.sin(angle + math.pi / 4) * 8,
        size.height * 0.5 + math.cos(angle + math.pi / 4) * 8,
      ),
      15,
      decorPaint,
    );

    canvas.drawCircle(
      Offset(
        size.width * 0.3 + math.cos(angle + math.pi / 4) * 8,
        size.height * 0.3 + math.sin(angle + math.pi / 4) * 8,
      ),
      20,
      decorPaint,
    );

    // Additional flowing curves
    paint.color = activeSecondary.withValues(alpha: 0.03);
    var flowPath = Path();
    double dyFlow = math.sin(angle + math.pi) * 12;
    flowPath.moveTo(0, size.height * 0.4 + dyFlow);
    flowPath.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.5 + dyFlow + math.cos(angle) * 6,
      size.width * 0.6,
      size.height * 0.3 + dyFlow,
    );
    flowPath.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.1 + dyFlow - math.cos(angle) * 6,
      size.width,
      size.height * 0.4 + dyFlow,
    );
    canvas.drawPath(flowPath, paint);

    // DRAW WAVING INDONESIAN SASH (PITA RAKSASA MERAH PUTIH) IF THEME IS 'INDONESIA'
    if (themeName == 'indonesia') {
      final double width = size.width;
      final double yOffset = size.height * 0.16;
      const double bandHeight = 110.0;
      const double amplitude = 22.0;

      const int steps = 50;
      final double stepW = width / steps;

      // 1. Construct entire Sash Outline for shadow and overall framing
      final sashOutline = Path();
      for (int i = 0; i <= steps; i++) {
        final double x = i * stepW;
        final double slope = (x / width) * 45.0; // Soft diagonal slope downwards
        final double wave = math.sin((x / 60.0) - (angle * 2.6)) * amplitude;
        final double y = yOffset + slope + wave;
        if (i == 0) {
          sashOutline.moveTo(x, y);
        } else {
          sashOutline.lineTo(x, y);
        }
      }
      
      // Right boundary down to bottom edge of White band
      const double lastSlope = 45.0;
      final double lastWave = math.sin((width / 60.0) - (angle * 2.6)) * amplitude;
      sashOutline.lineTo(width, yOffset + lastSlope + lastWave + bandHeight);

      // Bottom boundary going backwards
      for (int i = steps; i >= 0; i--) {
        final double x = i * stepW;
        final double slope = (x / width) * 45.0;
        final double wave = math.sin((x / 60.0) - (angle * 2.6)) * amplitude;
        final double y = yOffset + slope + wave + bandHeight;
        sashOutline.lineTo(x, y);
      }
      sashOutline.close();

      // Draw premium floating drop shadow
      canvas.drawShadow(
        sashOutline,
        const Color(0xFF000000).withValues(alpha: 0.12),
        8.0,
        true,
      );

      // 2. Draw Red Top Half
      final redPath = Path();
      for (int i = 0; i <= steps; i++) {
        final double x = i * stepW;
        final double slope = (x / width) * 45.0;
        final double wave = math.sin((x / 60.0) - (angle * 2.6)) * amplitude;
        final double y = yOffset + slope + wave;
        if (i == 0) {
          redPath.moveTo(x, y);
        } else {
          redPath.lineTo(x, y);
        }
      }
      for (int i = steps; i >= 0; i--) {
        final double x = i * stepW;
        final double slope = (x / width) * 45.0;
        final double wave = math.sin((x / 60.0) - (angle * 2.6)) * amplitude;
        final double y = yOffset + slope + wave + (bandHeight / 2);
        redPath.lineTo(x, y);
      }
      redPath.close();

      final redPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD32F2F),
            Color(0xFFB71C1C),
          ],
        ).createShader(Rect.fromLTWH(0, yOffset - 30, width, bandHeight + 60))
        ..style = PaintingStyle.fill;
      canvas.drawPath(redPath, redPaint);

      // 3. Draw White Bottom Half
      final whitePath = Path();
      for (int i = 0; i <= steps; i++) {
        final double x = i * stepW;
        final double slope = (x / width) * 45.0;
        final double wave = math.sin((x / 60.0) - (angle * 2.6)) * amplitude;
        final double y = yOffset + slope + wave + (bandHeight / 2);
        if (i == 0) {
          whitePath.moveTo(x, y);
        } else {
          whitePath.lineTo(x, y);
        }
      }
      for (int i = steps; i >= 0; i--) {
        final double x = i * stepW;
        final double slope = (x / width) * 45.0;
        final double wave = math.sin((x / 60.0) - (angle * 2.6)) * amplitude;
        final double y = yOffset + slope + wave + bandHeight;
        whitePath.lineTo(x, y);
      }
      whitePath.close();

      final whitePaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF5F5F5),
          ],
        ).createShader(Rect.fromLTWH(0, yOffset - 30, width, bandHeight + 60))
        ..style = PaintingStyle.fill;
      canvas.drawPath(whitePath, whitePaint);

      // 4. Subtle Border Outline
      final outlinePaint = Paint()
        ..color = const Color(0xFFCCCCCC).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(sashOutline, outlinePaint);
    }

    // DRAW INDONESIAN CELEBRATORY BUNTINGS (BENDERA SEGITIGA) & PARTICLES
    if (themeName == 'indonesia') {
      final double width = size.width;
      const int sags = 4;
      final double sagW = width / sags;
      final buntingPaint = Paint()..style = PaintingStyle.fill;
      final linePaint = Paint()
        ..color = const Color(0xFF757575)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      for (int s = 0; s < sags; s++) {
        final double xStart = s * sagW;
        final double xEnd = (s + 1) * sagW;
        final double xMid = (xStart + xEnd) / 2;
        
        const double yStart = 12.0;
        const double yEnd = 12.0;
        const double yMid = 28.0;

        final path = Path()
          ..moveTo(xStart, yStart)
          ..quadraticBezierTo(xMid, yMid, xEnd, yEnd);
        canvas.drawPath(path, linePaint);

        const int numTriangles = 6;
        for (int t = 0; t < numTriangles; t++) {
          final double p = t / (numTriangles - 1);
          final double tx = (1 - p) * (1 - p) * xStart + 2 * (1 - p) * p * xMid + p * p * xEnd;
          final double ty = (1 - p) * (1 - p) * yStart + 2 * (1 - p) * p * yMid + p * p * yEnd;

          buntingPaint.color = (s * numTriangles + t) % 2 == 0 
              ? const Color(0xFFD32F2F) 
              : const Color(0xFFFFFFFF);

          final triPath = Path()
            ..moveTo(tx - 6, ty)
            ..lineTo(tx + 6, ty)
            ..lineTo(tx, ty + 14)
            ..close();

          canvas.drawPath(triPath, buntingPaint);

          if ((s * numTriangles + t) % 2 != 0) {
            final triOutline = Paint()
              ..color = const Color(0xFFCCCCCC)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.5;
            canvas.drawPath(triPath, triOutline);
          }
        }
      }

      // Add falling red and white stars/diamonds (confetti)
      final confettiPaint = Paint()..style = PaintingStyle.fill;
      for (int i = 0; i < 10; i++) {
        final double cx = size.width * ((i * 0.17 + 0.05) % 1.0);
        final double cy = (size.height * 0.1 + (i * 90) + (animationValue * 200)) % (size.height * 0.85);
        final double sizeConf = 6.0 + (i % 3) * 2.0;

        confettiPaint.color = i % 2 == 0 ? const Color(0xFFD32F2F) : const Color(0xFFFFFFFF);

        final confettiPath = Path()
          ..moveTo(cx, cy - sizeConf)
          ..lineTo(cx + sizeConf * 0.7, cy)
          ..lineTo(cx, cy + sizeConf)
          ..lineTo(cx - sizeConf * 0.7, cy)
          ..close();

        canvas.drawPath(confettiPath, confettiPaint);

        if (i % 2 != 0) {
          final outlineConf = Paint()
            ..color = const Color(0xFFE0E0E0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5;
          canvas.drawPath(confettiPath, outlineConf);
        }
      }
    }
  }

  @override
  bool shouldRepaint(ModernCurvePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.themeName != themeName;
  }
}
