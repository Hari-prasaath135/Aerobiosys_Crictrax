// score_manager.dart
// ChangeNotifier used by ScoreCard (Board widget).
// Tracks the current over's ball-by-ball display and extras totals.

import 'package:flutter/foundation.dart';

class ScoreManager extends ChangeNotifier {
  final List<String> _ballsInOver = [];
  int _totalRuns = 0;
  int _legalBalls = 0;

  /// Balls in the current over for the rolling display strip.
  List<String> get ballsInOver => List.unmodifiable(_ballsInOver);

  /// Extra runs accumulated (wides, no-balls, byes) this innings.
  int get totalRuns => _totalRuns;

  /// Number of legal deliveries in the current over (resets at 6).
  int get legalBalls => _legalBalls;

  /// Call after every delivery.
  /// [score]   — display label e.g. '4', 'W', 'WD', 'NB', '*'
  /// [isLegal] — true for a legal ball (increments legalBalls)
  /// [runs]    — runs added to extras total (for wides/no-balls)
  void addBallScore(String score, {bool isLegal = true, int runs = 0}) {
    _ballsInOver.add(score);
    _totalRuns += runs;
    if (isLegal) _legalBalls++;
    notifyListeners();
  }

  /// Resets the over display and legal-ball counter (call at end of over).
  void resetOver() {
    _ballsInOver.clear();
    _legalBalls = 0;
    notifyListeners();
  }

  void reset() {
    _ballsInOver.clear();
    _totalRuns = 0;
    _legalBalls = 0;
    notifyListeners();
  }
}