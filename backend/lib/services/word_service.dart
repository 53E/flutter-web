import '../database/database.dart';
import '../models/word.dart';

class WordService {
  // 단어가 유효한지 검증
  static Future<bool> validateWord(String word) async {
    if (word.isEmpty) return false;
    if (word.length < 2) return false;
    
    // 데이터베이스에서 단어 검색
    final result = await DatabaseManager.database.rawQuery(
      'SELECT COUNT(*) as count FROM words WHERE word = ?',
      [word]
    );
    
    final count = result.first['count'] as int;
    return count > 0;
  }
  
  // 끝말잇기 규칙 검증 (이전 단어의 끝글자 = 현재 단어의 첫글자)
  static bool validateWordChain(String previousWord, String currentWord) {
    if (previousWord.isEmpty || currentWord.isEmpty) return false;
    
    final previousLastChar = previousWord[previousWord.length - 1];
    final currentFirstChar = currentWord[0];
    
    return previousLastChar == currentFirstChar;
  }
  
  // 특정 글자로 시작하는 단어들 검색
  static Future<List<Word>> searchWordsByFirstChar(String firstChar, {int limit = 50}) async {
    final result = await DatabaseManager.database.rawQuery(
      'SELECT * FROM words WHERE first_char = ? ORDER BY frequency DESC LIMIT ?',
      [firstChar, limit]
    );
    
    return result.map((row) => Word.fromJson(row)).toList();
  }
  
  // 랜덤 단어 가져오기 (게임 시작용)
  static Future<Word?> getRandomWord() async {
    final result = await DatabaseManager.database.rawQuery(
      'SELECT * FROM words ORDER BY RANDOM() LIMIT 1'
    );
    
    if (result.isEmpty) return null;
    return Word.fromJson(result.first);
  }
  
  // 단어 추가 (새로운 단어 학습)
  static Future<bool> addWord(String word) async {
    if (word.isEmpty || word.length < 2) return false;
    
    final firstChar = word[0];
    final lastChar = word[word.length - 1];
    
    try {
      await DatabaseManager.database.rawInsert(
        'INSERT INTO words (word, first_char, last_char) VALUES (?, ?, ?)',
        [word, firstChar, lastChar]
      );
      return true;
    } catch (e) {
      // 중복 단어 등의 오류
      print('단어 추가 실패: $e');
      return false;
    }
  }
  
  // 단어 사용 빈도 증가
  static Future<void> increaseWordFrequency(String word) async {
    try {
      await DatabaseManager.database.rawUpdate(
        'UPDATE words SET frequency = frequency + 1 WHERE word = ?',
        [word]
      );
    } catch (e) {
      print('빈도수 업데이트 실패: $e');
    }
  }
}
