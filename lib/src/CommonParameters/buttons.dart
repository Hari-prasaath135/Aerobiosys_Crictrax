import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final TextStyle? textStyle;

  // 🎨 Common vertical gradient using int values (top to bottom)
  static const List<Color> _defaultGradient = [
    Color(0xFF93A3FF),
    Color(0xFF3D45E8),
    Color(0xFF2F37D4),// top color
    Color(0xFF000447), // bottom color
  ];

  const GradientButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.width = 50,
    this.height = 100,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _defaultGradient,
          begin: Alignment.topCenter,
           // 👈 top to bottom
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12), // 👈 curved corners
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: textStyle ??
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}