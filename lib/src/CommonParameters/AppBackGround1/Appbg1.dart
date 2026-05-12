import 'package:flutter/material.dart';

class Appbg1 {
  // Common gradient for all pages
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF140088), // deep purple
      Color(0xFF000000), // black
    ],
    stops: [0.0,0.3]
  );
}
