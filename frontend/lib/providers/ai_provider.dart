import 'package:flutter/material.dart';

class AIProvider extends ChangeNotifier {
  String _aiName = 'AI Bot';
  int _aiStage = 1;
  bool _isAIThinking = false;
  
  String get aiName => _aiName;
  int get aiStage => _aiStage;
  bool get isAIThinking => _isAIThinking;
  
  void setAIStage(int stage) {
    _aiStage = stage;
    _aiName = 'AI Stage $stage';
    notifyListeners();
  }
  
  void setThinking(bool thinking) {
    _isAIThinking = thinking;
    notifyListeners();
  }
  
  Future<String> getAIResponse(String lastWord) async {
    setThinking(true);
    
    // 간단한 AI 응답 시뮬레이션
    await Future.delayed(Duration(seconds: 2));
    
    // 마지막 글자로 시작하는 임시 단어들
    final responses = {
      '가': ['가방', '가위', '가족'],
      '나': ['나무', '나비', '나라'],
      '다': ['다리', '달', '담배'],
      '라': ['라면', '라디오', '라이터'],
      '마': ['마음', '마케팅', '마법'],
      '바': ['바나나', '바다', '바람'],
      '사': ['사과', '사람', '사자'],
      '아': ['아기', '아빠', '아침'],
      '자': ['자동차', '자전거', '자료'],
      '차': ['차량', '차가운', '차이'],
      '카': ['카메라', '카드', '카페'],
      '타': ['타이어', '타자기', '타워'],
      '파': ['파일', '파랑', '파티'],
      '하': ['하늘', '하루', '학교']
    };
    
    String lastChar = lastWord.isNotEmpty ? lastWord[lastWord.length - 1] : '가';
    List<String>? wordList = responses[lastChar];
    String response = wordList?.isNotEmpty == true ? wordList!.first : '게임';
    
    setThinking(false);
    return response;
  }
}