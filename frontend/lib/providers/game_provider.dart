import 'package:flutter/material.dart';

class GameProvider extends ChangeNotifier {
  bool _isGameStarted = false;
  int _currentStage = 1;
  String _currentWord = '';
  
  bool get isGameStarted => _isGameStarted;
  int get currentStage => _currentStage;
  String get currentWord => _currentWord;
  
  void startGame() {
    _isGameStarted = true;
    _currentStage = 1;
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
}