class ScoreService {
  // 기본 점수 설정
  static const int baseScore = 100;
  static const int stageMultiplier = 50;
  static const int wordLengthBonus = 10;
  static const int speedBonus = 50;
  static const int comboBonus = 25;
  
  // 단어 제출 시 점수 계산
  static int calculateWordScore({
    required String word,
    required int stage,
    required int responseTime, // 밀리초
    required int consecutiveCorrect, // 연속 정답 수
  }) {
    int score = 0;
    
    // 1. 기본 점수
    score += baseScore;
    
    // 2. 단계별 보너스
    score += stage * stageMultiplier;
    
    // 3. 단어 길이 보너스 (2글자 이상부터 보너스)
    if (word.length > 2) {
      score += (word.length - 2) * wordLengthBonus;
    }
    
    // 4. 속도 보너스 (5초 이내)
    if (responseTime <= 5000) {
      final speedBonusMultiplier = (5000 - responseTime) / 1000;
      score += (speedBonus * speedBonusMultiplier).round();
    }
    
    // 5. 연속 정답 보너스
    if (consecutiveCorrect > 1) {
      score += (consecutiveCorrect - 1) * comboBonus;
    }
    
    return score;
  }
  
  // 단계 클리어 보너스
  static int calculateStageClearBonus(int stage) {
    return stage * 200; // 단계 * 200점
  }
  
  // 게임 완료 보너스 (모든 단계 클리어)
  static int calculateGameCompletionBonus() {
    return 1000; // 완주 보너스
  }
  
  // 점수에 따른 등급 계산
  static String calculateGrade(int score) {
    if (score >= 10000) return 'S+';
    if (score >= 8000) return 'S';
    if (score >= 6000) return 'A+';
    if (score >= 4000) return 'A';
    if (score >= 2500) return 'B+';
    if (score >= 1500) return 'B';
    if (score >= 800) return 'C+';
    if (score >= 400) return 'C';
    return 'D';
  }
  
  // 점수 상세 정보
  static Map<String, dynamic> getScoreBreakdown({
    required String word,
    required int stage,
    required int responseTime,
    required int consecutiveCorrect,
  }) {
    final wordScore = calculateWordScore(
      word: word,
      stage: stage,
      responseTime: responseTime,
      consecutiveCorrect: consecutiveCorrect,
    );
    
    return {
      'totalScore': wordScore,
      'breakdown': {
        'baseScore': baseScore,
        'stageBonus': stage * stageMultiplier,
        'wordLengthBonus': word.length > 2 ? (word.length - 2) * wordLengthBonus : 0,
        'speedBonus': responseTime <= 5000 ? 
          ((5000 - responseTime) / 1000 * speedBonus).round() : 0,
        'comboBonus': consecutiveCorrect > 1 ? 
          (consecutiveCorrect - 1) * comboBonus : 0,
      },
      'details': {
        'word': word,
        'wordLength': word.length,
        'stage': stage,
        'responseTimeMs': responseTime,
        'consecutiveCorrect': consecutiveCorrect,
      }
    };
  }
}
