import 'package:flutter/material.dart';
import '../theme/tournament_colors.dart';

/// A subtly pulsing skeleton placeholder shown while the tournament
/// stream is loading, so the list doesn't just show a bare spinner.
class TournamentSkeletonCard extends StatefulWidget {
  const TournamentSkeletonCard({super.key});

  @override
  State<TournamentSkeletonCard> createState() =>
      _TournamentSkeletonCardState();
}

class _TournamentSkeletonCardState extends State<TournamentSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
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
        final opacity = 0.35 + (_controller.value * 0.25);
        return Opacity(opacity: opacity, child: child);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TournamentColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: TournamentColors.surfaceSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: TournamentColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: 140,
                        decoration: BoxDecoration(
                          color: TournamentColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: TournamentColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 10,
              width: 200,
              decoration: BoxDecoration(
                color: TournamentColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}