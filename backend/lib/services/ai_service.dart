import 'dart:math';
import '../models/word.dart';
import 'word_service.dart';

class AIService {
  static final Random _random = Random();
  
  // 단계별 AI 설정
  static const Map<int, Map<String, dynamic>> _stageConfig = {
    1: {'responseRate': 0.95, 'responseTime': 2000, 'name': '테스트 적 1'},
    2: {'responseRate': 0.90, 'responseTime': 1800, 'name': '테스트 적 2'}, 
    3: {'responseRate': 0.85, 'responseTime': 1500, 'name': '테스트 적 3'},
    4: {'responseRate': 0.80, 'responseTime': 1200, 'name': '테스트 적 4'},
    5: {'responseRate': 0.75, 'responseTime': 1000, 'name': '테스트 적 5'},
    6: {'responseRate': 0.70, 'responseTime': 800, 'name': '테스트 적 6'},
    7: {'responseRate': 0.65, 'responseTime': 600, 'name': '테스트 적 7'},
    8: {'responseRate': 0.60, 'responseTime': 400, 'name': '테스트 적 8'},
  };
  
  // AI 응답 생성
  static Future<AIResponse> generateResponse(String lastWord, int stage) async {
    print('🤖 AI가 응답을 생성 중... (Stage: $stage, 마지막 단어: $lastWord)');
    
    // 단계 설정 가져오기
    final config = _stageConfig[stage] ?? _stageConfig[1]!;
    final responseRate = config['responseRate'] as double;
    final maxResponseTime = config['responseTime'] as int;
    
    // 응답 시간 시뮬레이션 (실제로는 즉시 처리)
    final responseTime = _random.nextInt(maxResponseTime ~/ 2) + maxResponseTime ~/ 2;
    await Future.delayed(Duration(milliseconds: responseTime));
    
    // 응답 확률 체크
    final willRespond = _random.nextDouble() < responseRate;
    
    if (!willRespond) {
      // AI가 응답하지 못함 (플레이어 승리)
      return AIResponse(
        word: '',
        responseTime: responseTime,
        success: false,
        reason: 'AI가 단어를 찾지 못했습니다'
      );
    }
    
    // 마지막 단어의 끝글자로 시작하는 단어 찾기
    final lastChar = lastWord.isNotEmpty ? lastWord[lastWord.length - 1] : '';
    final candidateWords = await WordService.searchWordsByFirstChar(lastChar, limit: 20);
    
    if (candidateWords.isEmpty) {
      return AIResponse(
        word: '',
        responseTime: responseTime,
        success: false,
        reason: '사용 가능한 단어가 없습니다'
      );
    }
    
    // 난이도에 따른 단어 선택
    final selectedWord = _selectWordByDifficulty(candidateWords, stage);
    
    // 선택된 단어의 사용 빈도 증가
    await WordService.increaseWordFrequency(selectedWord.word);
    
    return AIResponse(
      word: selectedWord.word,
      responseTime: responseTime,
      success: true,
    );
  }
  
  // 난이도에 따른 단어 선택 로직
  static Word _selectWordByDifficulty(List<Word> words, int stage) {
    if (words.isEmpty) throw Exception('선택할 단어가 없습니다');
    
    // 낮은 단계: 빈도가 높은(쉬운) 단어 선택
    // 높은 단계: 빈도가 낮은(어려운) 단어도 선택
    
    if (stage <= 2) {
      // 1-2단계: 상위 50% 단어에서만 선택
      final easyWords = words.take((words.length * 0.5).ceil()).toList();
      return easyWords[_random.nextInt(easyWords.length)];
    } else if (stage <= 4) {
      // 3-4단계: 상위 75% 단어에서 선택
      final mediumWords = words.take((words.length * 0.75).ceil()).toList();
      return mediumWords[_random.nextInt(mediumWords.length)];
    } else {
      // 5단계 이상: 모든 단어에서 선택 (어려운 단어 포함)
      return words[_random.nextInt(words.length)];
    }
  }
  
  // 게임 시작용 랜덤 단어 생성
  static Future<String> generateStartWord() async {
    try {
      final randomWord = await WordService.getRandomWord();
      if (randomWord != null) {
        return randomWord.word;
      }
    } catch (e) {
      print('랜덤 단어 생성 실패: $e');
    }
    
    // 기본 시작 단어들 중 랜덤 선택
    final defaultWords = ['사과', '학교', '컴퓨터', '음악', '책상', '나무', '바다', '구름'];
    return defaultWords[_random.nextInt(defaultWords.length)];
  }
  
  // AI 정보 가져오기
  static Map<String, dynamic> getAIInfo(int stage) {
    final config = _stageConfig[stage] ?? _stageConfig[1]!;
    return {
      'stage': stage,
      'name': config['name'],
      'responseRate': '${((config['responseRate'] as double) * 100).toInt()}%',
      'responseTime': '${config['responseTime']}ms 이하',
    };
  }
}
