import 'package:flutter/material.dart';
import '../theme/tournament_colors.dart';

/// Visually distinctive status pill.
/// Live pulses gently to feel energetic, Upcoming reads calm,
/// Completed reads subtle/muted — per design spec.
class TournamentStatusBadge extends StatefulWidget {
  final String status; // 'Live' | 'Upcoming' | 'Completed'
  final double fontSize;

  const TournamentStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
  });

  @override
  State<TournamentStatusBadge> createState() => _TournamentStatusBadgeState();
}

class _TournamentStatusBadgeState extends State<TournamentStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  bool get _isLive => widget.status == 'Live';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (_isLive) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant TournamentStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isLive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!_isLive && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect reduced-motion accessibility preference.
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final color = TournamentColors.statusColor(widget.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLive)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final t = disableAnimations ? 0.0 : _pulseController.value;
                final scale = 0.85 + (t * 0.3);
                final opacity = (1.0 - (t * 0.5)).clamp(0.4, 1.0);
                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.6),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          else
            Icon(
              widget.status == 'Upcoming'
                  ? Icons.schedule_rounded
                  : Icons.check_circle_rounded,
              size: 10,
              color: color,
            ),
          const SizedBox(width: 6),
          Text(
            widget.status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}