import 'package:flutter/material.dart';

class ScoreController extends ChangeNotifier {
  int _runs = 0;
  int _balls = 0;
  int _wickets = 0;

  final List<String> _currentOver = [];

  int get runs => _runs;
  int get balls => _balls;
  int get wickets => _wickets;
  List<String> get currentOver => List.unmodifiable(_currentOver);

  // Display overs as x.y (e.g. 3.2)
  String get overs => '${_balls ~/ 6}.${_balls % 6}';

  // Add normal runs
  void addRuns(int value) {
    _runs += value;
    _balls++;
    _currentOver.add(value.toString());
    _checkOverCompletion();
    notifyListeners();
  }

  // Add this method to your existing ScoreController class
double get oversAsDouble {
  List<String> parts = overs.split('.');
  int completedOvers = int.parse(parts[0]);
  int balls = parts.length > 1 ? int.parse(parts[1]) : 0;
  return completedOvers + (balls / 6.0);
}

  // Add extras (Wide or No Ball)
// Add extras (Wide or No Ball)
  void addExtra(String type, int runs) {
    // +1 for the extra itself (wide/no ball) + additional runs if any
    int extraRuns = 1 + runs;
    _runs += extraRuns;

    // Do not count this as a legal delivery
    _currentOver.add('$type+$runs');

    // Over not completed, since extras are not legal balls
    notifyListeners();
  }


  // Add a wicket (legal delivery)
  void addWicket({bool isLegal = true}) {
    if (isLegal) _balls++;
    _wickets++;
    _currentOver.add('W');
    _checkOverCompletion();
    notifyListeners();
  }

  // Check for over completion
  void _checkOverCompletion() {
    if (_balls % 6 == 0 && _balls != 0) {
      _currentOver.clear();
    }
  }

  // Reset everything
  void resetScore() {
    _runs = 0;
    _balls = 0;
    _wickets = 0;
    _currentOver.clear();
    notifyListeners();
  }
}
