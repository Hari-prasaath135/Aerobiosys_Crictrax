// score_controller.dart
// ChangeNotifier used by ScoreCard (Board widget).
// Tracks runs, wickets, and overs for the simple board display.

import 'package:flutter/foundation.dart';

class ScoreController extends ChangeNotifier {
  int _runs = 0;
  int _wickets = 0;
  int _balls = 0; // legal balls faced this innings

  int get runs => _runs;
  int get wickets => _wickets;

  /// Overs as a display string, e.g. "3.4"
  String get overs {
    final completed = _balls ~/ 6;
    final partial = _balls % 6;
    return '$completed.$partial';
  }

  /// Overs as a decimal for CRR calculation, e.g. 3.667
  double get oversAsDouble {
    final completed = _balls ~/ 6;
    final partial = _balls % 6;
    return completed + (partial / 6.0);
  }

  void addRuns(int r) {
    _runs += r;
    notifyListeners();
  }

  void addWicket({bool isLegal = true}) {
    _wickets++;
    if (isLegal) _balls++;
    notifyListeners();
  }

  void addExtra(String extraType, int runsByBatsman) {
    // NB / WD always add 1 penalty run + any batsman runs
    _runs += 1 + runsByBatsman;
    notifyListeners();
  }

  void reset() {
    _runs = 0;
    _wickets = 0;
    _balls = 0;
    notifyListeners();
  }
}