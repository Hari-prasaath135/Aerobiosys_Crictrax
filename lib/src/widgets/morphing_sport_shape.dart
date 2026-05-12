import 'package:flutter/material.dart';
import 'package:TURF_TOWN_/src/utils/animation_constants.dart';
import 'shadow_painter.dart';

class MorphingSportShape extends StatelessWidget {
  final String sportType; // 'cricket', 'badminton', 'football'
  final Animation<double> morphValue;
  final Animation<double> shadowValue;
  final Animation<double> rotationValue;
  final Offset position;
  final double? scale;

  const MorphingSportShape({
    required this.sportType,
    required this.morphValue,
    required this.shadowValue,
    required this.rotationValue,
    required this.position,
    this.scale,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate responsive scale based on screen size
    final screenSize = MediaQuery.of(context).size;
    final baseScale = (screenSize.width / 375.0).clamp(0.8, 1.2); // 375 is standard mobile width
    final finalScale = scale ?? baseScale;

    // Scale position based on screen size for responsive positioning
    final scaledX = position.dx * finalScale;
    final scaledY = position.dy * finalScale;

    return Positioned(
      left: scaledX,
      top: scaledY,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([morphValue, shadowValue, rotationValue]),
          builder: (context, child) {
            return Transform.scale(
              scale: finalScale,
              child: Transform.rotate(
                angle: rotationValue.value,
                child: SizedBox(
                  width: AnimationConstants.canvasWidth,
                  height: AnimationConstants.canvasHeight,
                  child: CustomPaint(
                    painter: ShadowPainter(
                      sportType: sportType,
                      morphValue: morphValue.value,
                      shadowValue: shadowValue.value,
                      rotation: rotationValue.value,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Wrapper widget for animated sport item with listeners
class AnimatedSportItem extends StatelessWidget {
  final String sportType;
  final Animation<double> morphValue;
  final Animation<double> shadowValue;
  final Animation<double> rotationValue;
  final Offset position;
  final VoidCallback? onAnimationUpdate;

  const AnimatedSportItem({
    required this.sportType,
    required this.morphValue,
    required this.shadowValue,
    required this.rotationValue,
    required this.position,
    this.onAnimationUpdate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    morphValue.addListener(onAnimationUpdate ?? () {});

    return MorphingSportShape(
      sportType: sportType,
      morphValue: morphValue,
      shadowValue: shadowValue,
      rotationValue: rotationValue,
      position: position,
    );
  }
}
