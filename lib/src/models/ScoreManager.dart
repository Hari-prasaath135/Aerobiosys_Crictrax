import 'package:flutter/material.dart';

class ScoreManager with ChangeNotifier {
  int totalRuns = 0;
  int legalBalls = 0;
  List<String> ballsInOver = [];


  void addBallScore(String score, {bool isLegal = true, int runs = 0}) {
    // Step 1: If the ball is legal, increment the legal ball count
    if (isLegal) {
      legalBalls++;
    }


    totalRuns += runs;


    ballsInOver.add(score);


    notifyListeners();
  }


  void resetOver() {
    ballsInOver.clear();
    legalBalls = 0;
    notifyListeners();
  }
}
