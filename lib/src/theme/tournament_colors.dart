import 'package:flutter/material.dart';

/// Centralized color palette for the CricTrax Tournament module.
/// Keeps the premium, sports-app aesthetic consistent across every
/// screen and widget in this module. Update here to re-theme globally.
class TournamentColors {
  TournamentColors._();

  static const Color background = Color(0xFF0E1023);
  static const Color surface = Color(0xFF181C36);
  static const Color surfaceSecondary = Color(0xFF22284A);

  static const Color primaryAccent = Color(0xFF00CFFF);
  static const Color secondaryAccent = Color(0xFF6A5CFF);

  static const Color success = Color(0xFF37D67A);
  static const Color warning = Color(0xFFFFB84D);
  static const Color error = Color(0xFFFF5B6E);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFAAB0C5);

  // rgba(255,255,255,0.08)
  static const Color divider = Color(0x14FFFFFF);

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryAccent, secondaryAccent],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceSecondary],
  );

  static Color statusColor(String status) {
    switch (status) {
      case 'Live':
        return success;
      case 'Upcoming':
        return primaryAccent;
      case 'Completed':
      default:
        return textSecondary;
    }
  }
}