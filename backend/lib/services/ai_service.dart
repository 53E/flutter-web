import 'dart:math';
import '../models/word.dart';
import 'word_service.dart';

class AIService {
  static final Random _random = Random();
  
  // 테스트 적 설정 (무조건 대답)
  static const Map<int, Map<String, dynamic>> _stageConfig = {
    1: {'responseRate': 1.0, 'responseTime': 2000, 'name': '테스트 적'},
  };
  
  // AI 응답 생성 (테스트 적 - 무조건 대답)
  static Future<AIResponse> generateResponse(String lastWord, int stage, List<String> usedWords) async {
    print('🤖 테스트 적이 응답을 생성 중... (마지막 단어: $lastWord)');
    
    // 즉시 응답 (프론트엔드에서 지연 관리)
    print('⚡ AI 즉시 응답 모드');
    
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
        responseTime: 100, // 즉시
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
    return {
      'stage': 1,
      'name': '테스트 적',
      'responseRate': '100%',
      'responseTime': '1-7초 (랜덤)',
      'description': '답할 수 있는 단어가 있으면 무조건 대답하는 테스트용 적입니다. 자연스러운 응답 시간을 위해 랜덤한 지연을 가집니다.'
    };
  }
}
