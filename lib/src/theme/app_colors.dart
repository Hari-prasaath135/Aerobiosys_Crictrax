import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF050816);
  static const card = Color(0xFF10182A);
  static const primary = Color(0xFF00D4FF);
  static const secondary = Color(0xFF7C4DFF);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFB0B8C5);

  static const primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> glow([Color color = primary, double opacity = 0.35]) => [
        BoxShadow(
          color: color.withOpacity(opacity),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}