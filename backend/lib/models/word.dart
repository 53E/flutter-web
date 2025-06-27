// 단어 모델
class Word {
  final int? id;
  final String word;
  final String firstChar;
  final String lastChar;
  final int frequency;
  final DateTime? createdAt;
  
  Word({
    this.id,
    required this.word,
    required this.firstChar,
    required this.lastChar,
    this.frequency = 1,
    this.createdAt,
  });
  
  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'firstChar': firstChar,
      'lastChar': lastChar,
      'frequency': frequency,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
  
  // JSON에서 생성
  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'],
      word: json['word'],
      firstChar: json['first_char'],
      lastChar: json['last_char'],
      frequency: json['frequency'] ?? 1,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
}

// AI 응답 모델
class AIResponse {
  final String word;
  final int responseTime; // 밀리초
  final bool success;
  final String? reason; // 실패 이유
  
  AIResponse({
    required this.word,
    required this.responseTime,
    required this.success,
    this.reason,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'responseTime': responseTime,
      'success': success,
      'reason': reason,
    };
  }
}
