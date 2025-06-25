import 'package:flutter/material.dart';

class ScoreProvider extends ChangeNotifier {
  int _totalScore = 0;
  int _highScore = 0;
  List<int> _recentScores = [];
  
  int get totalScore => _totalScore;
  int get highScore => _highScore;
  List<int> get recentScores => _recentScores;
  
  void addScore(int points) {
    _totalScore += points;
    notifyListeners();
  }
  
  void saveCurrentScore() {
    _recentScores.add(_totalScore);
    if (_totalScore > _highScore) {
      _highScore = _totalScore;
    }
    notifyListeners();
  }
  
  void resetCurrentScore() {
    _totalScore = 0;
    notifyListeners();
  }
  
  void resetAllScores() {
    _totalScore = 0;
    _highScore = 0;
    _recentScores.clear();
    notifyListeners();
  }
}