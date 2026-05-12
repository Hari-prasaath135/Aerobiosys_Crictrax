import 'package:flutter/material.dart';

class AnimationConstants {
  // Cricket Ball Animation (2.5s)
  static const Duration cricketDuration = Duration(milliseconds: 2500);
  static const Curve cricketCurve = Curves.easeInOutQuad;
  static const double cricketStartRadius = 30.0;
  static const double cricketMaxRadius = 50.0;
  static const Color cricketColor = Color(0xFFFF0000); // Red
  static const Color cricketShadowColor = Color(0xFF8B0000); // Dark Red

  // Badminton Shuttlecock Animation (2.0s)
  static const Duration badmintonDuration = Duration(milliseconds: 2000);
  static const Curve badmintonCurve = Curves.easeInOutCubic;
  static const double badmintonStartHeight = 40.0;
  static const double badmintonMaxHeight = 60.0;
  static const Color badmintonColor = Color(0xFF0066FF); // Blue
  static const Color badmintonShadowColor = Color(0xFF003399); // Dark Blue

  // Football Animation (2.2s)
  static const Duration footballDuration = Duration(milliseconds: 2200);
  static const Curve footballCurve = Curves.elasticInOut;
  static const double footballStartWidth = 45.0;
  static const double footballMaxWidth = 65.0;
  static const Color footballColor = Color(0xFF8B4513); // Brown
  static const Color footballAccentColor = Color(0xFFFFD700); // Gold

  // Shadow Effects
  static const double shadowBaseBlur = 5.0;
  static const double shadowMaxBlur = 20.0;
  static const double shadowBaseSpread = 0.0;
  static const double shadowMaxSpread = 15.0;
  static const double shadowOpacity = 0.3;

  // Delays
  static const Duration cricketDelay = Duration(milliseconds: 0);
  static const Duration badmintonDelay = Duration(milliseconds: 300);
  static const Duration footballDelay = Duration(milliseconds: 600);

  // Canvas sizes
  static const double canvasWidth = 150.0;
  static const double canvasHeight = 150.0;
  static const Offset canvasCenter = Offset(75.0, 75.0);
}
