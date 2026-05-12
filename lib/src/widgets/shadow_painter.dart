import 'package:flutter/material.dart';
import 'package:TURF_TOWN_/src/utils/animation_constants.dart';
import 'dart:math' as math;

class ShadowPainter extends CustomPainter {
  final String sportType; // 'cricket', 'badminton', 'football'
  final double morphValue; // 0.0 to 1.0
  final double shadowValue; // 0.0 to 1.0
  final double rotation;

  ShadowPainter({
    required this.sportType,
    required this.morphValue,
    required this.shadowValue,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw shadow first (behind the object)
    _drawShadow(canvas, center, size);

    // Draw the sport shape
    _drawSportShape(canvas, center, size);
  }

  void _drawShadow(Canvas canvas, Offset center, Size size) {
    // Calculate shadow blur and spread
    final blurRadius = AnimationConstants.shadowBaseBlur +
        (AnimationConstants.shadowMaxBlur - AnimationConstants.shadowBaseBlur) *
            shadowValue;

    final shadowSpread = AnimationConstants.shadowBaseSpread +
        (AnimationConstants.shadowMaxSpread - AnimationConstants.shadowBaseSpread) *
            shadowValue;

    // Shadow position (slightly offset down and right)
    final shadowOffset = Offset(
      center.dx + shadowSpread,
      center.dy + shadowSpread + 10,
    );

    // Draw shadow based on sport type
    switch (sportType) {
      case 'cricket':
        _drawCricketShadow(canvas, shadowOffset, blurRadius);
        break;
      case 'badminton':
        _drawBadmintonShadow(canvas, shadowOffset, blurRadius);
        break;
      case 'football':
        _drawFootballShadow(canvas, shadowOffset, blurRadius);
        break;
    }
  }

  void _drawCricketShadow(Canvas canvas, Offset offset, double blur) {
    final radius = AnimationConstants.cricketStartRadius +
        (AnimationConstants.cricketMaxRadius - AnimationConstants.cricketStartRadius) *
            morphValue;

    final paint = Paint()
      ..color = AnimationConstants.cricketShadowColor
          .withValues(alpha: AnimationConstants.shadowOpacity * shadowValue)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    canvas.drawCircle(offset, radius, paint);
  }

  void _drawBadmintonShadow(Canvas canvas, Offset offset, double blur) {
    final height = AnimationConstants.badmintonStartHeight +
        (AnimationConstants.badmintonMaxHeight - AnimationConstants.badmintonStartHeight) *
            morphValue;

    final paint = Paint()
      ..color = AnimationConstants.badmintonShadowColor
          .withValues(alpha: AnimationConstants.shadowOpacity * shadowValue)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    // Draw arc-shaped shadow
    canvas.drawOval(
      Rect.fromCenter(center: offset, width: height * 0.6, height: height * 0.3),
      paint,
    );
  }

  void _drawFootballShadow(Canvas canvas, Offset offset, double blur) {
    final width = AnimationConstants.footballStartWidth +
        (AnimationConstants.footballMaxWidth - AnimationConstants.footballStartWidth) *
            morphValue;

    final paint = Paint()
      ..color = AnimationConstants.footballColor
          .withValues(alpha: AnimationConstants.shadowOpacity * shadowValue)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    // Draw oval shadow
    canvas.drawOval(
      Rect.fromCenter(center: offset, width: width * 1.2, height: width * 0.6),
      paint,
    );
  }

  void _drawSportShape(Canvas canvas, Offset center, Size size) {
    switch (sportType) {
      case 'cricket':
        _drawCricketBall(canvas, center);
        break;
      case 'badminton':
        _drawBadmintonShuttlecock(canvas, center);
        break;
      case 'football':
        _drawFootball(canvas, center);
        break;
    }
  }

  void _drawCricketBall(Canvas canvas, Offset center) {
    // Calculate morphing radius
    final radius = AnimationConstants.cricketStartRadius +
        (AnimationConstants.cricketMaxRadius - AnimationConstants.cricketStartRadius) *
            morphValue;

    // Draw main circle
    final mainPaint = Paint()
      ..color = AnimationConstants.cricketColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, mainPaint);

    // Draw seam line (curved stitches)
    final seamPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw curved seam
    final seamPath = Path();
    seamPath.moveTo(center.dx - radius * 0.6, center.dy - radius * 0.3);
    seamPath.quadraticBezierTo(
      center.dx,
      center.dy - radius,
      center.dx + radius * 0.6,
      center.dy - radius * 0.3,
    );

    canvas.drawPath(seamPath, seamPaint);

    // Draw outer ring during morph
    if (morphValue > 0.5) {
      final ringPaint = Paint()
        ..color = Colors.white.withOpacity((morphValue - 0.5) * 2 * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, radius * 0.95, ringPaint);
    }
  }

  void _drawBadmintonShuttlecock(Canvas canvas, Offset center) {
    // Calculate morphing height
    final height = AnimationConstants.badmintonStartHeight +
        (AnimationConstants.badmintonMaxHeight - AnimationConstants.badmintonStartHeight) *
            morphValue;

    final width = height * 0.4;

    // Draw cork head (black circle)
    final headPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, width * 0.5, headPaint);

    // Draw feather skirt (curved cone shape)
    final featherPaint = Paint()
      ..color = AnimationConstants.badmintonColor
      ..style = PaintingStyle.fill;

    final featherPath = Path();
    featherPath.moveTo(center.dx - width * 0.3, center.dy);
    featherPath.quadraticBezierTo(
      center.dx - width * 0.6,
      center.dy + height * 0.5,
      center.dx,
      center.dy + height,
    );
    featherPath.quadraticBezierTo(
      center.dx + width * 0.6,
      center.dy + height * 0.5,
      center.dx + width * 0.3,
      center.dy,
    );
    featherPath.close();

    canvas.drawPath(featherPath, featherPaint);

    // Draw white stripes on feathers
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 3; i++) {
      final offset = (i - 1) * width * 0.3;
      canvas.drawLine(
        Offset(center.dx + offset, center.dy + height * 0.3),
        Offset(center.dx + offset * 0.7, center.dy + height),
        stripePaint,
      );
    }
  }

  void _drawFootball(Canvas canvas, Offset center) {
    // Calculate morphing width
    final width = AnimationConstants.footballStartWidth +
        (AnimationConstants.footballMaxWidth - AnimationConstants.footballStartWidth) *
            morphValue;

    final height = width * 0.6;

    // Draw main oval body
    final bodyPaint = Paint()
      ..color = AnimationConstants.footballColor
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: center, width: width, height: height),
      bodyPaint,
    );

    // Draw laces (white curved line)
    final lacesPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final lacesPath = Path();
    lacesPath.moveTo(center.dx - width * 0.3, center.dy - height * 0.2);
    lacesPath.quadraticBezierTo(center.dx, center.dy - height * 0.4, center.dx + width * 0.3, center.dy - height * 0.2);

    canvas.drawPath(lacesPath, lacesPaint);

    // Draw stitch marks along the lace
    for (int i = 0; i < 5; i++) {
      final x = center.dx - width * 0.25 + (i * width * 0.12);
      final y = center.dy - height * 0.25 + (math.sin(i * 0.5) * height * 0.1);

      canvas.drawCircle(Offset(x, y), 1.5, Paint()..color = Colors.white);
    }

    // Draw accent color (gold) panels
    if (morphValue > 0.3) {
      final accentPaint = Paint()
        ..color = AnimationConstants.footballAccentColor
            .withValues(alpha: (morphValue - 0.3) * 1.43 * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawOval(
        Rect.fromCenter(center: center, width: width * 0.8, height: height * 0.8),
        accentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ShadowPainter oldDelegate) {
    return oldDelegate.morphValue != morphValue ||
        oldDelegate.shadowValue != shadowValue ||
        oldDelegate.rotation != rotation ||
        oldDelegate.sportType != sportType;
  }

  @override
  bool shouldRebuildSemantics(ShadowPainter oldDelegate) => false;
}
