import 'dart:math';
import '../models/word.dart';
import 'word_service.dart';

class AIService {
  static final Random _random = Random();
  
  // 단계별 적 설정
  static const Map<int, Map<String, dynamic>> _stageConfig = {
    1: {
      'baseResponseRate': 1.0,
      'declineRate': 0.07, // 7% 하락
      'responseTime': 2000,
      'name': '초급 전사'
    },
    2: {
      'baseResponseRate': 1.0,
      'declineRate': 0.04, // 4% 하락
      'responseTime': 1500,
      'name': '중급 마법사'
    },
    3: {
      'baseResponseRate': 1.0,
      'declineRate': 0.0, // 0% 하락 (항상 100%)
      'responseTime': 1000,
      'name': '전설의 드래곤'
    },
  };
  
  // AI 응답 생성 (단계별 확률 적용)
  static Future<AIResponse> generateResponse(
    String lastWord, 
    int stage, 
    List<String> usedWords,
    {int aiTurnCount = 0} // AI가 응답한 횟수
  ) async {
    final config = _stageConfig[stage] ?? _stageConfig[1]!;
    print('🤖 ${config['name']}이(가) 응답을 생성 중... (마지막 단어: $lastWord, AI 턴: $aiTurnCount)');
    
    // 응답 확률 계산
    final baseRate = config['baseResponseRate'] as double;
    final declineRate = config['declineRate'] as double;
    final currentResponseRate = baseRate - (declineRate * aiTurnCount);
    
    print('📊 응답 확률: ${(currentResponseRate * 100).toStringAsFixed(1)}% (기본: ${baseRate * 100}%, 하락률: ${declineRate * 100}%/턴)');
    
    // 확률 체크 (첫 번째 응답은 항상 100%)
    if (aiTurnCount > 0 && _random.nextDouble() > currentResponseRate) {
      print('🎲 AI가 응답에 실패했습니다! (확률 실패)');
      // 시간이 끝날 때까지 기다리도록 플래그만 설정
      return AIResponse(
        word: '',
        responseTime: 100,
        success: false,
        reason: 'probability_fail' // 확률 실패 표시
      );
    }
    
    // 마지막 단어의 끝글자로 시작하는 단어 찾기 (두음법칙 포함)
    final lastChar = lastWord.isNotEmpty ? lastWord[lastWord.length - 1] : '';
    final possibleFirstChars = WordService.getPossibleFirstChars(lastChar);
    print('🔤 "$lastChar" → 가능한 시작 글자: ${possibleFirstChars.join(", ")}');
    
    final candidateWords = await WordService.searchWordsByFirstChar(lastChar, limit: 100);
    
    print('📝 $lastChar(으)로 시작하는 단어 ${candidateWords.length}개 발견 (두음법칙 포함)');
    
    // 사용하지 않은 단어만 필터링
    final availableWords = candidateWords.where((word) => !usedWords.contains(word.word)).toList();
    
    print('🔍 사용 가능한 단어: ${availableWords.length}개');
    
    if (availableWords.isEmpty) {
      print('❌ AI가 사용할 수 있는 단어가 없습니다');
      return AIResponse(
        word: '',
        responseTime: 100,
        success: false,
        reason: 'AI가 사용할 수 있는 단어가 없습니다'
      );
    }
    
    // 랜덤으로 단어 선택
    final selectedWord = availableWords[_random.nextInt(availableWords.length)];
    
    // 선택된 단어의 사용 빈도 증가
    await WordService.increaseWordFrequency(selectedWord.word);
    
    print('✅ AI가 선택한 단어: ${selectedWord.word}');
    
    return AIResponse(
      word: selectedWord.word,
      responseTime: 100, // 즉시 응답
      success: true,
    );
  }
  
  // 게임 시작용 랜덤 단어 생성
  static Future<String> generateStartWord() async {
    try {
      final randomWord = await WordService.getRandomWord();
      if (randomWord != null) {
        print('🎯 게임 시작 단어: ${randomWord.word}');
        return randomWord.word;
      }
    } catch (e) {
      print('랜덤 단어 생성 실패: $e');
    }
    
    // 기본 시작 단어들 중 랜덤 선택
    final defaultWords = ['사과', '학교', '컴퓨터', '음악', '책상', '나무', '바다', '구름'];
    final selectedWord = defaultWords[_random.nextInt(defaultWords.length)];
    print('🎯 기본 시작 단어: $selectedWord');
    return selectedWord;
  }
  
  // AI 정보 가져오기
  static Map<String, dynamic> getAIInfo(int stage) {
    final config = _stageConfig[stage] ?? _stageConfig[1]!;
    final descriptions = {
      1: '매 턴마다 응답 확률이 7%씩 감소하는 초보 전사입니다.',
      2: '매 턴마다 응답 확률이 4%씩 감소하는 숙련된 마법사입니다.',
      3: '항상 100% 확률로 응답하는 전설의 드래곤입니다.'
    };
    
    return {
      'stage': stage,
      'name': config['name'],
      'baseResponseRate': '${(config['baseResponseRate'] * 100).toInt()}%',
      'declineRate': '${(config['declineRate'] * 100).toInt()}%',
      'responseTime': '1-7초 (랜덤)',
      'description': descriptions[stage] ?? descriptions[1]!
    };
  }
}
