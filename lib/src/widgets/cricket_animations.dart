import 'package:flutter/material.dart';

// ============================================================================
// BOUNDARY ANIMATION FOR 4 RUNS
// ============================================================================
class BoundaryFourAnimation extends StatefulWidget {
  final Duration duration;

  const BoundaryFourAnimation({
    Key? key,
    this.duration = const Duration(milliseconds: 1200),
  }) : super(key: key);

  @override
  State<BoundaryFourAnimation> createState() => _BoundaryFourAnimationState();
}

class _BoundaryFourAnimationState extends State<BoundaryFourAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Scale animation - grows from center
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // Opacity animation - fades out
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInQuad),
    );

    // Slide animation - moves upward with rotation
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0, -1)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value * 100,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring - expanding
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withValues(alpha: _opacityAnimation.value),
                        width: 3,
                      ),
                    ),
                  ),
                  // Middle ring
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF8BC34A).withValues(alpha: _opacityAnimation.value * 0.7),
                        width: 2,
                      ),
                    ),
                  ),
                  // Center with text
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4CAF50).withValues(alpha: _opacityAnimation.value),
                          const Color(0xFF8BC34A).withValues(alpha: _opacityAnimation.value * 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withValues(alpha: _opacityAnimation.value * 0.6),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '4',
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: _opacityAnimation.value),
                            ),
                          ),
                          Text(
                            'BOUNDARY',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: _opacityAnimation.value * 0.8),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// BOUNDARY ANIMATION FOR 6 RUNS
// ============================================================================
class BoundarySixAnimation extends StatefulWidget {
  final Duration duration;

  const BoundarySixAnimation({
    Key? key,
    this.duration = const Duration(milliseconds: 1200),
  }) : super(key: key);

  @override
  State<BoundarySixAnimation> createState() => _BoundarySixAnimationState();
}

class _BoundarySixAnimationState extends State<BoundarySixAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation controller
    _scaleController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Rotation animation controller (continuous rotation)
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInQuad),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _rotationController]),
      builder: (context, child) {
        return Center(
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: ClipOval(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating background
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              const Color(0xFF2196F3).withValues(alpha: _opacityAnimation.value),
                              const Color(0xFF00BCD4).withValues(alpha: _opacityAnimation.value * 0.7),
                              const Color(0xFF2196F3).withValues(alpha: _opacityAnimation.value),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2196F3).withValues(alpha: _opacityAnimation.value * 0.8),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      // Inner circle
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF0288D1).withValues(alpha: _opacityAnimation.value),
                              const Color(0xFF0097A7).withValues(alpha: _opacityAnimation.value),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '6',
                                style: TextStyle(
                                  fontSize: 60,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withValues(alpha: _opacityAnimation.value),
                                ),
                              ),
                              Text(
                                'SIX!',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withValues(alpha: _opacityAnimation.value * 0.9),
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
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
      },
    );
  }
}

// ============================================================================
// WICKET ANIMATION
// ============================================================================
class WicketAnimation extends StatefulWidget {
  final Duration duration;

  const WicketAnimation({
    Key? key,
    this.duration = const Duration(milliseconds: 1400),
  }) : super(key: key);

  @override
  State<WicketAnimation> createState() => _WicketAnimationState();
}

class _WicketAnimationState extends State<WicketAnimation>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _scaleController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.8).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInQuad),
    );

    _shakeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shakeController, _scaleController]),
      builder: (context, child) {
        // Shake effect
        double shakeOffset = (_shakeAnimation.value - 0.5) * 20;

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Wicket sticks (three vertical lines)
                  CustomPaint(
                    painter: WicketPainter(_opacityAnimation.value),
                    size: const Size(120, 160),
                  ),
                  // Explosion effect particles
                  ..._buildParticles(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildParticles() {
    return List.generate(8, (index) {
      final distance = 80.0;
      final dx = distance * 1.5 * (index % 2 == 0 ? 1 : -1);
      final dy = distance * 1.5 * (index < 4 ? -1 : 1);

      return Positioned(
        left: 60 + dx * _opacityAnimation.value,
        top: 80 + dy * _opacityAnimation.value,
        child: Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index.isEven ? const Color(0xFFFF6B6B) : const Color(0xFFFF9800),
            ),
          ),
        ),
      );
    });
  }
}

class WicketPainter extends CustomPainter {
  final double opacity;

  WicketPainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B6B).withValues(alpha: opacity)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final bailPaint = Paint()
      ..color = const Color(0xFFFFB74D).withValues(alpha: opacity)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final topY = 30.0;
    final bottomY = size.height - 30;

    // Left stick
    canvas.drawLine(
      Offset(centerX - 30, topY),
      Offset(centerX - 30, bottomY),
      paint,
    );

    // Middle stick
    canvas.drawLine(
      Offset(centerX, topY),
      Offset(centerX, bottomY),
      paint,
    );

    // Right stick
    canvas.drawLine(
      Offset(centerX + 30, topY),
      Offset(centerX + 30, bottomY),
      paint,
    );

    // Top bail (horizontal line)
    canvas.drawLine(
      Offset(centerX - 30, topY + 10),
      Offset(centerX + 30, topY + 10),
      bailPaint,
    );

    // Bottom bail (horizontal line)
    canvas.drawLine(
      Offset(centerX - 30, topY + 30),
      Offset(centerX + 30, topY + 30),
      bailPaint,
    );
  }

  @override
  bool shouldRepaint(WicketPainter oldDelegate) => oldDelegate.opacity != opacity;
}

// ============================================================================
// DUCK ANIMATION
// ============================================================================
class DuckAnimation extends StatefulWidget {
  final Duration duration;

  const DuckAnimation({
    Key? key,
    this.duration = const Duration(milliseconds: 1200),
  }) : super(key: key);

  @override
  State<DuckAnimation> createState() => _DuckAnimationState();
}

class _DuckAnimationState extends State<DuckAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInQuad),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF9800).withValues(alpha: _opacityAnimation.value),
                      const Color(0xFFFF6F00).withValues(alpha: _opacityAnimation.value * 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9800).withValues(alpha: _opacityAnimation.value * 0.6),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '🦆',
                        style: TextStyle(
                          fontSize: 60,
                          color: Colors.white.withValues(alpha: _opacityAnimation.value),
                        ),
                      ),
                      Text(
                        'DUCK',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: _opacityAnimation.value * 0.9),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// VICTORY ANIMATION
// ============================================================================
class VictoryAnimation extends StatefulWidget {
  final Duration duration;

  const VictoryAnimation({
    Key? key,
    this.duration = const Duration(milliseconds: 2000),
  }) : super(key: key);

  @override
  State<VictoryAnimation> createState() => _VictoryAnimationState();
}

class _VictoryAnimationState extends State<VictoryAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInQuad),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, -0.5), end: const Offset(0, 0)).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _rotationController]),
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value * 50,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Trophy icon with rotation
                      Transform.rotate(
                        angle: _rotationAnimation.value * 0.5,
                        child: Text(
                          '🏆',
                          style: TextStyle(
                            fontSize: 100,
                            color: Colors.white.withValues(alpha: _opacityAnimation.value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Victory text
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFD700).withValues(alpha: _opacityAnimation.value),
                              const Color(0xFFFFA500).withValues(alpha: _opacityAnimation.value * 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: _opacityAnimation.value * 0.6),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'MATCH',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black.withValues(alpha: _opacityAnimation.value),
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'WON!',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.black.withValues(alpha: _opacityAnimation.value),
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Celebration particles (in Stack, no overflow)
                  ..._buildConfetti(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildConfetti() {
    return List.generate(12, (index) {
      final distance = 80.0;
      final dx = distance * (index % 2 == 0 ? 1 : -1);
      final dy = distance * (index < 6 ? -1 : 1);

      return Positioned(
        left: 80 + dx * _opacityAnimation.value,
        top: 120 + dy * _opacityAnimation.value,
        child: Opacity(
          opacity: _opacityAnimation.value,
          child: Text(
            index % 3 == 0 ? '⭐' : index % 3 == 1 ? '🎉' : '✨',
            style: const TextStyle(fontSize: 20),
          ),
        ),
      );
    });
  }
}
