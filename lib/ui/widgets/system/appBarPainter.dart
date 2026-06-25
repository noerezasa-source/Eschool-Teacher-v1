import 'package:flutter/material.dart';
import 'package:eschool_saas_staff/utils/system/colorPalette.dart';

class AppBarPainter extends CustomPainter {
  double x;
  Color circleColor;
  Color navigationBarColor;
  int selectedIndex;

  AppBarPainter(
    this.x, {
    Color? circleColor,
    this.navigationBarColor = Colors.white,
    this.selectedIndex = 0, // Default to home (first tab)
  }) : circleColor = circleColor ?? AppColorPalette.primaryMaroon;

  double height = 100.0; // Meningkatkan dari 90.0 ke 100.0
  double start = 40.0;
  double end = 140; // Meningkatkan dari 130 ke 140

  @override
  void paint(Canvas canvas, Size size) {
    // Determine circle offset based on selected menu
    double circleOffsetX;
    switch (selectedIndex) {
      case 0: // Home menu
        circleOffsetX = 77.0;
        break;
      case 1: // Academic menu
        circleOffsetX = 84.0;
        break;
      case 2: // Profile menu
        circleOffsetX = 93.0;
        break;
      default:
        circleOffsetX = 77.0; // Default to home offset
    }

    // Center of the circle is directly under the selected icon
    double circleCenterX = x + circleOffsetX;

    // Main navigation bar with shadow
    var paint = Paint()
      ..color = navigationBarColor
      ..style = PaintingStyle.fill;

    // Add a shadow effect to make it more attractive
    var shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    Path path = Path();
    path.moveTo(0.0, start);

    // Calculate the left and right bounds for the DROP path
    // These values should be relative to the circle position
    double leftBound = circleCenterX - 70.0; // Left side of the drop
    double rightBound = circleCenterX + 70.0; // Right side of the drop

    /// DROP paths, now adjusted to follow the circle position
    path.lineTo(leftBound < 20.0 ? 20.0 : leftBound, start);
    path.quadraticBezierTo(
        leftBound + 20.0, start, leftBound + 30.0, start + 30.0);
    path.quadraticBezierTo(
        circleCenterX - 30.0, start + 55.0, circleCenterX, start + 55.0);
    path.quadraticBezierTo(
        circleCenterX + 30.0, start + 55.0, rightBound - 30.0, start + 30.0);
    path.quadraticBezierTo(
        rightBound - 20.0,
        start,
        (rightBound) > (size.width - 20.0) ? (size.width - 20.0) : rightBound,
        start);
    path.lineTo(size.width - 20.0, start);

    /// Box with BorderRadius
    path.quadraticBezierTo(size.width, start, size.width, start + 25.0);
    path.lineTo(size.width, end - 25.0);
    path.quadraticBezierTo(size.width, end, size.width - 25.0, end);
    path.lineTo(25.0, end);
    path.quadraticBezierTo(0.0, end, 0.0, end - 25.0);
    path.lineTo(0.0, start + 25.0);
    path.quadraticBezierTo(0.0, start, 20.0, start);
    path.close();

    // Draw shadow first
    canvas.drawPath(path, shadowPaint);
    // Then draw the actual path
    canvas.drawPath(path, paint);

    /// Circle to show at the top of the drop with gradient
    var circleGradient = RadialGradient(
      center: Alignment.topLeft,
      radius: 1.0,
      colors: [
        circleColor,
        circleColor.withValues(alpha: 0.8),
      ],
    );

    double circleCenterY = 59.0; // Adjusted to better position the circle

    var circlePaint = Paint()
      ..shader = circleGradient.createShader(Rect.fromCircle(
          center: Offset(circleCenterX, circleCenterY), radius: 35.0))
      ..style = PaintingStyle.fill;

    // Draw circle shadow
    canvas.drawCircle(
        Offset(circleCenterX, circleCenterY),
        38.0,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0));

    // Draw main circle
    canvas.drawCircle(Offset(circleCenterX, circleCenterY), 35.0, circlePaint);

    // Add subtle highlight to circle
    canvas.drawCircle(
        Offset(circleCenterX - 10.0, circleCenterY - 10.0),
        15.0,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
