import 'package:flutter/material.dart';

class GameProvider extends ChangeNotifier {
  bool _isGameStarted = false;
  int _currentStage = 1;
  String _currentWord = '';
  bool _stageClearInProgress = false;
  
  bool get isGameStarted => _isGameStarted;
  int get currentStage => _currentStage;
  String get currentWord => _currentWord;
  bool get stageClearInProgress => _stageClearInProgress;
  
  void startGame({bool resetStage = true}) {
    _isGameStarted = true;
    if (resetStage) {
      _currentStage = 1;
    }
    _stageClearInProgress = false;
    notifyListeners();
  }
  
  void endGame() {
    _isGameStarted = false;
    notifyListeners();
  }
  
  void updateWord(String word) {
    _currentWord = word;
    notifyListeners();
  }
  
  void updateStage(int stage) {
    _currentStage = stage;
    notifyListeners();
  }
  
  void setStageClearInProgress(bool inProgress) {
    _stageClearInProgress = inProgress;
    notifyListeners();
  }
}