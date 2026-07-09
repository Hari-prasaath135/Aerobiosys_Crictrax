import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/tournament_colors.dart';

/// Premium logo upload component: dashed circular border, trophy
/// illustration empty state, tap-scale "upload" animation, and a
/// small edit badge once an image is chosen.
///
/// Purely presentational — the parent still owns [logoFile]/[logoPath]
/// state and the image-picking/cropping logic (unchanged business logic).
class TournamentLogoPicker extends StatefulWidget {
  final File? logoFile;
  final String? logoPath;
  final VoidCallback onTap;
  final double size;

  const TournamentLogoPicker({
    super.key,
    required this.logoFile,
    required this.logoPath,
    required this.onTap,
    this.size = 108,
  });

  bool get hasImage =>
      logoFile != null || (logoPath != null && logoPath!.isNotEmpty);

  @override
  State<TournamentLogoPicker> createState() => _TournamentLogoPickerState();
}

class _TournamentLogoPickerState extends State<TournamentLogoPicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ImageProvider? get _image {
    if (widget.logoFile != null) return FileImage(widget.logoFile!);
    if (widget.logoPath != null && widget.logoPath!.isNotEmpty) {
      return FileImage(File(widget.logoPath!));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.hasImage;
    final image = _image;

    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) => _controller.forward(),
      onTapCancel: () => _controller.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _controller,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasImage ? null : TournamentColors.cardGradient,
                    image: image != null
                        ? DecorationImage(image: image, fit: BoxFit.cover)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: !hasImage
                      ? CustomPaint(
                          painter: _DashedCirclePainter(
                            color:
                                TournamentColors.primaryAccent.withOpacity(0.6),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.emoji_events_rounded,
                                  color: TournamentColors.primaryAccent,
                                  size: 30,
                                ),
                                const SizedBox(height: 4),
                                Icon(
                                  Icons.add_circle_rounded,
                                  color: TournamentColors.secondaryAccent
                                      .withOpacity(0.85),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        )
                      : null,
                ),
                if (hasImage)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: TournamentColors.primaryAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 14),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              hasImage ? 'Tap to change logo' : 'Upload tournament logo',
              style: const TextStyle(
                color: TournamentColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    const dashSpace = 4.0;
    const dashWidth = 6.0;
    final circumference = 2 * 3.14159265 * radius;
    final dashCount = (circumference / (dashWidth + dashSpace)).floor();
    final angleStep = (2 * 3.14159265) / dashCount;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * angleStep;
      final sweep = angleStep * (dashWidth / (dashWidth + dashSpace));
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}