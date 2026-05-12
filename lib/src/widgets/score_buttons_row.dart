import 'package:flutter/material.dart';
import 'package:TURF_TOWN_/src/widgets/buttons.dart';

class ScoreButtonsRow extends StatelessWidget {
  final Function(int) onScoreSelected;

  const ScoreButtonsRow({super.key, required this.onScoreSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButton('4', top: 100, value: 4),
        _buildButton('3', top: 75, value: 3),
        _buildButton('1', top: 50, value: 1),
        _buildButton('0', top: 25, value: 0),
        _buildButton('2', top: 50, value: 2),
        _buildButton('5', top: 75, value: 5),
        _buildButton('6', top: 100, value: 6),
      ],
    );
  }

  Widget _buildButton(String label, {required double top, required int value}) {
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: GradientButton(
        label: label,
        onPressed: () => onScoreSelected(value),
      ),
    );
  }
}
