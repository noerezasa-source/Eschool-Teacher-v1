import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Presidential {
  final String name;
  final String bio;
  final double xPercent; // Base horizontal position percentage
  final double yPercent; // Base vertical position percentage
  final double speed;
  final double phase;
  final String type;

  const Presidential({
    required this.name,
    required this.bio,
    required this.xPercent,
    required this.yPercent,
    required this.speed,
    required this.phase,
    required this.type,
  });
}

class PresidentialBackgroundHelper {
  static const List<Presidential> _presidents = [
    Presidential(name: 'Soekarno', bio: 'PRESIDEN PERTAMA INDONESIA', xPercent: 0.15, yPercent: 0.18, speed: 0.4, phase: 0.0, type: 'soekarno'),
    Presidential(name: 'Soeharto', bio: 'PRESIDEN KEDUA INDONESIA', xPercent: 0.82, yPercent: 0.22, speed: 0.35, phase: 1.2, type: 'soeharto'),
    Presidential(name: 'Habibie', bio: 'PRESIDEN KETIGA INDONESIA', xPercent: 0.25, yPercent: 0.40, speed: 0.45, phase: 2.5, type: 'habibie'),
    Presidential(name: 'Gus Dur', bio: 'PRESIDEN KEEMPAT INDONESIA', xPercent: 0.75, yPercent: 0.45, speed: 0.38, phase: 3.8, type: 'gusdur'),
    Presidential(name: 'Megawati', bio: 'PRESIDEN KELIMA INDONESIA', xPercent: 0.18, yPercent: 0.65, speed: 0.42, phase: 0.5, type: 'megawati'),
    Presidential(name: 'SBY', bio: 'PRESIDEN KEENAM INDONESIA', xPercent: 0.84, yPercent: 0.70, speed: 0.45, phase: 1.8, type: 'sby'),
    Presidential(name: 'Jokowi', bio: 'PRESIDEN KETUJUH INDONESIA', xPercent: 0.30, yPercent: 0.88, speed: 0.4, phase: 3.0, type: 'jokowi'),
    Presidential(name: 'Prabowo', bio: 'PRESIDEN KEDELAPAN INDONESIA', xPercent: 0.78, yPercent: 0.88, speed: 0.35, phase: 4.2, type: 'prabowo'),
  ];

  static final Map<String, ui.Image> _loadedImages = {};
  static final Set<String> _loadingKeys = {};

  static void _loadImage(String type) async {
    if (_loadedImages.containsKey(type) || _loadingKeys.contains(type)) return;
    _loadingKeys.add(type);
    try {
      final ByteData data = await rootBundle.load('assets/images/$type.jpg');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();
      _loadedImages[type] = fi.image;
    } catch (e) {
      debugPrint("Error loading image for $type: $e");
    }
  }

  static void paint(Canvas canvas, Size size, double animationValue, String themeMode, {Offset? tapPosition}) {
    if (themeMode != 'indonesia') return;

    // Premium styling tailored for the red & white Indonesian theme background (light red/white gradient)
    final strokeColor = const Color(0xFFD32F2F).withValues(alpha: 0.45);
    final glowColor = const Color(0xFFD32F2F).withValues(alpha: 0.18);
    final textColor = const Color(0xFFD32F2F).withValues(alpha: 0.88);

    for (final pres in _presidents) {
      // Calculate floating movements with slight breathing cycle scale
      final double offsetVal = animationValue * pres.speed + pres.phase;
      double dx = size.width * pres.xPercent + sin(offsetVal) * 15;
      double dy = size.height * pres.yPercent + cos(offsetVal * 0.7) * 15;
      
      // Breathing scaling effect
      double scale = 1.0 + sin(offsetVal * 1.5) * 0.08;
      
      var activeStrokeColor = strokeColor;
      var activeGlowColor = glowColor;
      var activeTextColor = textColor;

      if (tapPosition != null) {
        final dist = (Offset(dx, dy) - tapPosition).distance;
        if (dist < 100.0) {
          final factor = (100.0 - dist) / 100.0;
          final angle = (Offset(dx, dy) - tapPosition).direction;
          
          // Push away dynamically
          dx += cos(angle) * factor * 25;
          dy += sin(angle) * factor * 25;
          
          // Scale size up slightly under interaction
          scale += factor * 0.20;
          
          // Glow intensity increase & color shifts
          activeStrokeColor = const Color(0xFFD32F2F).withValues(alpha: 0.85);
          activeGlowColor = const Color(0xFFD32F2F).withValues(alpha: 0.45);
          activeTextColor = const Color(0xFFD32F2F);
        }
      }

      final center = Offset(dx, dy);
      const portraitSize = 34.0;

      final paintMain = Paint()
        ..color = activeStrokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      final paintGlow = Paint()
        ..color = activeGlowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(scale);

      // Draw double-stroke holographic glow first, then main line
      _drawPortrait(canvas, Offset.zero, portraitSize, paintGlow, pres.type);
      _drawPortrait(canvas, Offset.zero, portraitSize, paintMain, pres.type);

      canvas.restore();

      // Determine side to paint the biography to avoid screen clipping
      final bool drawOnLeft = center.dx > size.width / 2;
      final double currentRadius = portraitSize * scale;

      // Construct name & brief biodata next to portrait
      final textPainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${pres.name.toUpperCase()}\n',
              style: TextStyle(
                color: activeTextColor,
                fontSize: 9.0,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                shadows: [
                  Shadow(
                    color: activeGlowColor.withValues(alpha: 0.35),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
            TextSpan(
              text: pres.bio.toUpperCase(),
              style: TextStyle(
                color: activeTextColor.withValues(alpha: 0.70),
                fontSize: 6.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: activeGlowColor.withValues(alpha: 0.20),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
        textAlign: drawOnLeft ? TextAlign.end : TextAlign.start,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Dynamically position the text layout relative to scaling avatar
      final double textX = drawOnLeft
          ? center.dx - currentRadius - 10 - textPainter.width
          : center.dx + currentRadius + 10;
      final double textY = center.dy - textPainter.height / 2;

      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  static void _drawPortrait(Canvas canvas, Offset center, double size, Paint paint, String type) {
    if (_loadedImages.containsKey(type)) {
      final isGlow = paint.strokeWidth > 2.0;
      if (isGlow) {
        // Draw the neon glow/halo ring behind the image
        canvas.drawCircle(center, size, paint);
      } else {
        final image = _loadedImages[type]!;
        canvas.save();
        
        // Clip to a circle
        final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: size));
        canvas.clipPath(clipPath);
        
        // Center-crop logic
        final double minDim = min(image.width, image.height).toDouble();
        final double srcX = (image.width - minDim) / 2;
        final double srcY = (image.height - minDim) / 2;
        final src = Rect.fromLTWH(srcX, srcY, minDim, minDim);
        final dst = Rect.fromCircle(center: center, radius: size);
        
        canvas.drawImageRect(
          image,
          src,
          dst,
          Paint()..filterQuality = ui.FilterQuality.high,
        );
        canvas.restore();
        
        // Paint the beautiful outer border on top of the avatar
        canvas.drawCircle(center, size, paint);
      }
    } else {
      _loadImage(type);
      switch (type) {
        case 'soekarno':
          _drawSoekarno(canvas, center, size, paint);
          break;
        case 'soeharto':
          _drawSoeharto(canvas, center, size, paint);
          break;
        case 'habibie':
          _drawHabibie(canvas, center, size, paint);
          break;
        case 'gusdur':
          _drawGusDur(canvas, center, size, paint);
          break;
        case 'megawati':
          _drawMegawati(canvas, center, size, paint);
          break;
        case 'sby':
          _drawSby(canvas, center, size, paint);
          break;
        case 'jokowi':
          _drawJokowi(canvas, center, size, paint);
          break;
        case 'prabowo':
          _drawPrabowo(canvas, center, size, paint);
          break;
      }
    }
  }

  // 1. SOEKARNO: Charismatic look with signature Peci and suit
  static void _drawSoekarno(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final half = size / 2;

    // Face jawline
    path.moveTo(center.dx - half * 0.6, center.dy - half * 0.1);
    path.quadraticBezierTo(center.dx - half * 0.6, center.dy + half * 0.5, center.dx, center.dy + half * 0.65);
    path.quadraticBezierTo(center.dx + half * 0.6, center.dy + half * 0.5, center.dx + half * 0.6, center.dy - half * 0.1);

    // Peci (National Cap)
    path.moveTo(center.dx - half * 0.65, center.dy - half * 0.05);
    path.lineTo(center.dx - half * 0.55, center.dy - half * 0.65);
    path.quadraticBezierTo(center.dx, center.dy - half * 0.72, center.dx + half * 0.55, center.dy - half * 0.65);
    path.lineTo(center.dx + half * 0.65, center.dy - half * 0.05);
    path.quadraticBezierTo(center.dx, center.dy - half * 0.02, center.dx - half * 0.65, center.dy - half * 0.05);

    // Hair sticking out slightly at sideburns
    path.moveTo(center.dx - half * 0.6, center.dy - half * 0.1);
    path.lineTo(center.dx - half * 0.63, center.dy + half * 0.1);
    path.moveTo(center.dx + half * 0.6, center.dy - half * 0.1);
    path.lineTo(center.dx + half * 0.63, center.dy + half * 0.1);

    // Eyes/Eyebrows (charismatic line)
    path.moveTo(center.dx - half * 0.35, center.dy + half * 0.15);
    path.lineTo(center.dx - half * 0.1, center.dy + half * 0.15);
    path.moveTo(center.dx + half * 0.1, center.dy + half * 0.15);
    path.lineTo(center.dx + half * 0.35, center.dy + half * 0.15);

    // Nose bridge
    path.moveTo(center.dx, center.dy + half * 0.12);
    path.lineTo(center.dx, center.dy + half * 0.32);
    path.lineTo(center.dx - half * 0.08, center.dy + half * 0.35);

    // Smiling Mouth
    path.moveTo(center.dx - half * 0.25, center.dy + half * 0.45);
    path.quadraticBezierTo(center.dx, center.dy + half * 0.52, center.dx + half * 0.25, center.dy + half * 0.45);

    // Collar & Tie
    path.moveTo(center.dx - half * 0.3, center.dy + half * 0.65);
    path.lineTo(center.dx - half * 0.45, center.dy + half * 0.9);
    path.lineTo(center.dx + half * 0.45, center.dy + half * 0.9);
    path.lineTo(center.dx + half * 0.3, center.dy + half * 0.65);
    
    // Tie
    path.moveTo(center.dx, center.dy + half * 0.65);
    path.lineTo(center.dx - half * 0.08, center.dy + half * 0.9);
    path.moveTo(center.dx, center.dy + half * 0.65);
    path.lineTo(center.dx + half * 0.08, center.dy + half * 0.9);

    canvas.drawPath(path, paint);
  }

  // 2. SOEHARTO: Smiling portrait with combed hair
  static void _drawSoeharto(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final half = size / 2;

    // Jawline
    path.moveTo(center.dx - half * 0.55, center.dy - half * 0.2);
    path.quadraticBezierTo(center.dx - half * 0.55, center.dy + half * 0.5, center.dx, center.dy + half * 0.62);
    path.quadraticBezierTo(center.dx + half * 0.55, center.dy + half * 0.5, center.dx + half * 0.55, center.dy - half * 0.2);

    // Combed-back Hair outline
    path.moveTo(center.dx - half * 0.6, center.dy - half * 0.2);
    path.quadraticBezierTo(center.dx - half * 0.65, center.dy - half * 0.6, center.dx - half * 0.3, center.dy - half * 0.7);
    path.quadraticBezierTo(center.dx, center.dy - half * 0.75, center.dx + half * 0.3, center.dy - half * 0.7);
    path.quadraticBezierTo(center.dx + half * 0.65, center.dy - half * 0.6, center.dx + half * 0.6, center.dy - half * 0.2);

    // Eyes with warm smile wrinkles
    path.moveTo(center.dx - half * 0.38, center.dy + half * 0.1);
    path.quadraticBezierTo(center.dx - half * 0.22, center.dy + half * 0.05, center.dx - half * 0.12, center.dy + half * 0.1);
    path.moveTo(center.dx + half * 0.12, center.dy + half * 0.1);
    path.quadraticBezierTo(center.dx + half * 0.22, center.dy + half * 0.05, center.dx + half * 0.38, center.dy + half * 0.1);

    // Warm wide smile
    path.moveTo(center.dx - half * 0.3, center.dy + half * 0.4);
    path.quadraticBezierTo(center.dx, center.dy + half * 0.52, center.dx + half * 0.3, center.dy + half * 0.4);

    // Suit lapel
    path.moveTo(center.dx - half * 0.4, center.dy + half * 0.62);
    path.lineTo(center.dx - half * 0.55, center.dy + half * 0.9);
    path.moveTo(center.dx + half * 0.4, center.dy + half * 0.62);
    path.lineTo(center.dx + half * 0.55, center.dy + half * 0.9);

    canvas.drawPath(path, paint);
  }

  // 3. HABIBIE: Wavy hair with round iconic glasses and bowtie
  static void _drawHabibie(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final half = size / 2;

    // Slender Jawline
    path.moveTo(center.dx - half * 0.5, center.dy - half * 0.1);
    path.quadraticBezierTo(center.dx - half * 0.5, center.dy + half * 0.48, center.dx, center.dy + half * 0.6);
    path.quadraticBezierTo(center.dx + half * 0.5, center.dy + half * 0.48, center.dx + half * 0.5, center.dy - half * 0.1);

    // Fluffy/Wavy hair outline
    path.moveTo(center.dx - half * 0.55, center.dy - half * 0.1);
    path.quadraticBezierTo(center.dx - half * 0.7, center.dy - half * 0.5, center.dx - half * 0.3, center.dy - half * 0.68);
    path.quadraticBezierTo(center.dx, center.dy - half * 0.72, center.dx + half * 0.3, center.dy - half * 0.68);
    path.quadraticBezierTo(center.dx + half * 0.7, center.dy - half * 0.5, center.dx + half * 0.55, center.dy - half * 0.1);

    // Iconic round glasses
    final glR = half * 0.18;
    canvas.drawCircle(Offset(center.dx - half * 0.22, center.dy + half * 0.1), glR, paint);
    canvas.drawCircle(Offset(center.dx + half * 0.22, center.dy + half * 0.1), glR, paint);
    
    // Glasses bridge
    path.moveTo(center.dx - half * 0.04, center.dy + half * 0.1);
    path.lineTo(center.dx + half * 0.04, center.dy + half * 0.1);

    // Smile
    path.moveTo(center.dx - half * 0.2, center.dy + half * 0.42);
    path.quadraticBezierTo(center.dx, center.dy + half * 0.5, center.dx + half * 0.2, center.dy + half * 0.42);

    // Bowtie
    path.moveTo(center.dx, center.dy + half * 0.6);
    path.lineTo(center.dx - half * 0.2, center.dy + half * 0.7);
    path.lineTo(center.dx - half * 0.2, center.dy + half * 0.85);
    path.lineTo(center.dx, center.dy + half * 0.75);
    path.lineTo(center.dx + half * 0.2, center.dy + half * 0.85);
    path.lineTo(center.dx + half * 0.2, center.dy + half * 0.7);
    path.close();

    canvas.drawPath(path, paint);
  }

  // 4. GUS DUR: Round face with square-rounded glasses and Peci
  static void _drawGusDur(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final half = size / 2;

    // Round face
    path.moveTo(center.dx - half * 0.58, center.dy - half * 0.1);
    path.quadraticBezierTo(center.dx - half * 0.58, center.dy + half * 0.52, center.dx, center.dy + half * 0.65);
    path.quadraticBezierTo(center.dx + half * 0.58, center.dy + half * 0.52, center.dx + half * 0.58, center.dy - half * 0.1);

    // Peci
    path.moveTo(center.dx - half * 0.6, center.dy - half * 0.08);
    path.lineTo(center.dx - half * 0.5, center.dy - half * 0.65);
    path.quadraticBezierTo(center.dx, center.dy - half * 0.7, center.dx + half * 0.5, center.dy - half * 0.65);
    path.lineTo(center.dx + half * 0.6, center.dy - half * 0.08);
    path.quadraticBezierTo(center.dx, center.dy - half * 0.05, center.dx - half * 0.6, center.dy - half * 0.08);

    // Square-round intellectual glasses
    final glW = half * 0.35;
    final glH = half * 0.25;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - half * 0.42, center.dy + half * 0.05, glW, glH),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx + half * 0.07, center.dy + half * 0.05, glW, glH),
        const Radius.circular(3),
      ),
      paint,
    );

    // Bridge
    path.moveTo(center.dx - half * 0.07, center.dy + half * 0.15);
    path.lineTo(center.dx + half * 0.07, center.dy + half * 0.15);

    // Intellectual smile
    path.moveTo(center.dx - half * 0.22, center.dy + half * 0.45);
    path.quadraticBezierTo(center.dx, center.dy + half * 0.52, center.dx + half * 0.22, center.dy + half * 0.45);

    // Collar
    path.moveTo(center.dx - half * 0.35, center.dy + half * 0.65);
    path.lineTo(center.dx - half * 0.45, center.dy + half * 0.9);
    path.moveTo(center.dx + half * 0.35, center.dy + half * 0.65);
    path.lineTo(center.dx + half * 0.45, center.dy + half * 0.9);

    canvas.drawPath(path, paint);
  }

  // 5. MEGAWATI: Traditional hair bun (sanggul) and soft details
  static void _drawMegawati(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final half = size / 2;

    // Face jawline
    path.moveTo(center.dx - half * 0.52, center.dy - half * 0.15);
    path.quadraticBezierTo(center.dx - half * 0.52, center.dy + half * 0.48, center.dx, center.dy + half * 0.6);
    path.quadraticBezierTo(center.dx + half * 0.52, center.dy + half * 0.48, center.dx + half * 0.52, center.dy - half * 0.15);

    // Hair bun (Sanggul) behind
    canvas.drawCircle(Offset(center.dx + half * 0.52, center.dy - half * 0.2), half * 0.22, paint);

    // Hair bangs / front hair volume
    path.moveTo(center.dx - half * 0.55, center.dy - half * 0.15);
    path.quadraticBezierTo(center.dx - half * 0.6, center.dy - half * 0.6, center.dx - half * 0.25, center.dy - half * 0.65);
    path.quadraticBezierTo(center.dx, center.dy - half * 0.68, center.dx + half * 0.25, center.dy - half * 0.65);
    path.quadraticBezierTo(center.dx + half * 0.6, center.dy - half * 0.6, center.dx + half * 0.55, center.dy - half * 0.15);

    // Bangs split
    path.moveTo(center.dx, center.dy - half * 0.68);
    path.quadraticBezierTo(center.dx - half * 0.1, center.dy - half * 0.4, center.dx - half * 0.35, center.dy - half * 0.2);

    // Gentle smile
    path.moveTo(center.dx - half * 0.2, center.dy + half * 0.42);
    path.quadraticBezierTo(center.dx, center.dy + half * 0.49, center.dx + half * 0.2, center.dy + half * 0.42);

    // Kebaya collar neckline
    path.moveTo(center.dx - half * 0.42, center.dy + half * 0.6);
    path.quadraticBezierTo(center.dx, center.dy + half * 0.85, center.dx + half * 0.42, center.dy + half * 0.6);

    canvas.drawPath(path, paint);
  }

  // 6. SBY: Neat parted hair with rectangular glasses and structured jaw
  static void _drawSby(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final half = size / 2;

    // Structured jawline
    path.moveTo(center.dx - half * 0.54, center.dy - half * 0.18);
    path.quadraticBezierTo(center.dx - half * 0.54, center.dy + half * 0.48, center.dx, center.dy + half * 0.62);
    path.quadraticBezierTo(center.dx + half * 0.54, center.dy + half * 0.48, center.dx + half * 0.54, center.dy - half * 0.18);

    // Side-parted hair outline
    path.moveTo(center.dx - half * 0.56, center.dy - half * 0.18);
    path.quadraticBezierTo(center.dx - half * 0.6, center.dy - half * 0.65, center.dx - half * 0.15, center.dy - half * 0.72);
    path.lineTo(center.dx - half * 0.12, center.dy - half * 0.6); // Parting line
    path.moveTo(center.dx - half * 0.12, center.dy - half * 0.62);
    path.quadraticBezierTo(center.dx + half * 0.4, center.dy - half * 0.72, center.dx + half * 0.58, center.dy - half * 0.18);

    // Slim rectangular glasses
    final glW = half * 0.32;
    final glH = half * 0.16;
    canvas.drawRect(Rect.fromLTWH(center.dx - half * 0.38, center.dy + half * 0.08, glW, glH), paint);
    canvas.drawRect(Rect.fromLTWH(center.dx + half * 0.06, center.dy + half * 0.08, glW, glH), paint);
    
    // Bridge
    path.moveTo(center.dx - half * 0.06, center.dy + half * 0.14);
    path.lineTo(center.dx + half * 0.06, center.dy + half * 0.14);

    // Serious yet warm smile
    path.moveTo(center.dx - half * 0.22, center.dy + half * 0.42);
    path.quadraticBezierTo(center.dx, center.dy + half * 0.48, center.dx + half * 0.22, center.dy + half * 0.42);

    // Shirt & Tie collar
    path.moveTo(center.dx - half * 0.32, center.dy + half * 0.62);
    path.lineTo(center.dx - half * 0.45, center.dy + half * 0.9);
    path.moveTo(center.dx + half * 0.32, center.dy + half * 0.62);
    path.lineTo(center.dx + half * 0.45, center.dy + half * 0.9);

    canvas.drawPath(path, paint);
  }

  // 7. JOKOWI: Lean face, combed-side spiky hair, and prominent friendly wide smile
  static void _drawJokowi(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final half = size / 2;

    // Slender/thin jawline
    path.moveTo(center.dx - half * 0.48, center.dy - half * 0.1);
    path.quadraticBezierTo(center.dx - half * 0.48, center.dy + half * 0.46, center.dx, center.dy + half * 0.65);
    path.quadraticBezierTo(center.dx + half * 0.48, center.dy + half * 0.46, center.dx + half * 0.48, center.dy - half * 0.1);

    // Combed swept-up hair
    path.moveTo(center.dx - half * 0.52, center.dy - half * 0.1);
    path.quadraticBezierTo(center.dx - half * 0.58, center.dy - half * 0.62, center.dx - half * 0.15, center.dy - half * 0.7);
    path.quadraticBezierTo(center.dx + half * 0.35, center.dy - half * 0.72, center.dx + half * 0.52, center.dy - half * 0.1);

    // Spiky texture detail in hair
    path.moveTo(center.dx - half * 0.15, center.dy - half * 0.7);
    path.lineTo(center.dx - half * 0.1, center.dy - half * 0.55);

    // Wide friendly smile
    path.moveTo(center.dx - half * 0.32, center.dy + half * 0.4);
    path.quadraticBezierTo(center.dx, center.dy + half * 0.55, center.dx + half * 0.32, center.dy + half * 0.4);
    // Smile line bottom
    path.moveTo(center.dx - half * 0.22, center.dy + half * 0.44);
    path.quadraticBezierTo(center.dx, center.dy + half * 0.50, center.dx + half * 0.22, center.dy + half * 0.44);

    // High ears
    path.moveTo(center.dx - half * 0.48, center.dy + half * 0.05);
    path.quadraticBezierTo(center.dx - half * 0.58, center.dy + half * 0.18, center.dx - half * 0.48, center.dy + half * 0.3);
    path.moveTo(center.dx + half * 0.48, center.dy + half * 0.05);
    path.quadraticBezierTo(center.dx + half * 0.58, center.dy + half * 0.18, center.dx + half * 0.48, center.dy + half * 0.3);

    // Simple shirt collar
    path.moveTo(center.dx - half * 0.3, center.dy + half * 0.65);
    path.lineTo(center.dx - half * 0.45, center.dy + half * 0.9);
    path.moveTo(center.dx + half * 0.3, center.dy + half * 0.65);
    path.lineTo(center.dx + half * 0.45, center.dy + half * 0.9);

    canvas.drawPath(path, paint);
  }

  // 8. PRABOWO: Strong rounded-square jawline, military-style collar pins
  static void _drawPrabowo(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final half = size / 2;

    // Strong square jawline
    path.moveTo(center.dx - half * 0.55, center.dy - half * 0.15);
    path.lineTo(center.dx - half * 0.55, center.dy + half * 0.25);
    path.quadraticBezierTo(center.dx - half * 0.55, center.dy + half * 0.52, center.dx, center.dy + half * 0.62);
    path.quadraticBezierTo(center.dx + half * 0.55, center.dy + half * 0.52, center.dx + half * 0.55, center.dy + half * 0.25);
    path.lineTo(center.dx + half * 0.55, center.dy - half * 0.15);

    // Combed tidy hair
    path.moveTo(center.dx - half * 0.58, center.dy - half * 0.15);
    path.quadraticBezierTo(center.dx - half * 0.62, center.dy - half * 0.62, center.dx - half * 0.25, center.dy - half * 0.68);
    path.quadraticBezierTo(center.dx, center.dy - half * 0.7, center.dx + half * 0.3, center.dy - half * 0.68);
    path.quadraticBezierTo(center.dx + half * 0.62, center.dy - half * 0.62, center.dx + half * 0.58, center.dy - half * 0.15);

    // Hair parting line
    path.moveTo(center.dx - half * 0.25, center.dy - half * 0.68);
    path.quadraticBezierTo(center.dx - half * 0.28, center.dy - half * 0.48, center.dx - half * 0.35, center.dy - half * 0.25);

    // Firm smile
    path.moveTo(center.dx - half * 0.22, center.dy + half * 0.42);
    path.quadraticBezierTo(center.dx, center.dy + half * 0.48, center.dx + half * 0.22, center.dy + half * 0.42);

    // Military collar with pocket lines
    path.moveTo(center.dx - half * 0.32, center.dy + half * 0.62);
    path.lineTo(center.dx - half * 0.55, center.dy + half * 0.88);
    path.moveTo(center.dx + half * 0.32, center.dy + half * 0.62);
    path.lineTo(center.dx + half * 0.55, center.dy + half * 0.88);
    
    // Pocket flap lines
    path.moveTo(center.dx - half * 0.42, center.dy + half * 0.72);
    path.lineTo(center.dx - half * 0.18, center.dy + half * 0.72);
    path.moveTo(center.dx + half * 0.18, center.dy + half * 0.72);
    path.lineTo(center.dx + half * 0.42, center.dy + half * 0.72);

    canvas.drawPath(path, paint);
  }
}
