import 'package:flutter/material.dart';

class PlayerProvider extends ChangeNotifier {
  String _playerName = 'Player';
  int _playerScore = 0;
  
  String get playerName => _playerName;
  int get playerScore => _playerScore;
  
  void setPlayerName(String name) {
    _playerName = name;
    notifyListeners();
  }
  
  void addScore(int points) {
    _playerScore += points;
    notifyListeners();
  }
  
  void resetScore() {
    _playerScore = 0;
    notifyListeners();
  }
}