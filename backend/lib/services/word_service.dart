import '../database/database.dart';
import '../models/word.dart';

class WordService {
  // 두음법칙 매핑 테이블
  static const Map<String, List<String>> _doubleConsonantRules = {
    // ㄹ 계열
    '량': ['량', '양'],
    '려': ['려', '여'],
    '례': ['례', '예'],
    '로': ['로', '노'],
    '록': ['록', '녹'],
    '론': ['론', '논'],
    '롱': ['롱', '농'],
    '료': ['료', '요'],
    '룡': ['룡', '용'],
    '루': ['루', '누'],
    '류': ['류', '유'],
    '륙': ['륙', '육'],
    '륜': ['륜', '윤'],
    '률': ['률', '율'],
    '리': ['리', '이'],
    '린': ['린', '인'],
    '림': ['림', '임'], // "그림" → "림" 또는 "임"
    '립': ['립', '입'],
    '름': ['름', '음'], // "이름" → "름" 또는 "음"
    '력': ['력', '역'], // "능력" → "력" 또는 "역"
    '라': ['라', '나'],
    '락': ['락', '낙'],
    '란': ['란', '난'],
    '랑': ['랑', '낭'],
    '랍': ['랍', '납'],
    '래': ['래', '내'],
    '랭': ['랭', '냉'],
    '랜': ['랜', '낸'],
    '램': ['램', '남'],
    
    // ㄴ + ㅣ 계열  
    '니': ['니', '이'],
    '녀': ['녀', '여'],
    
    // 역방향 매핑도 포함
    '양': ['량', '양'],
    '여': ['려', '여'],
    '예': ['례', '예'],
    '노': ['로', '노'],
    '녹': ['록', '녹'],
    '논': ['론', '논'],
    '농': ['롱', '농'],
    '요': ['료', '요'],
    '용': ['룡', '용'],
    '누': ['루', '누'],
    '유': ['류', '유'],
    '육': ['륙', '육'],
    '윤': ['륜', '윤'],
    '율': ['률', '율'],
    '이': ['리', '이', '니'],
    '인': ['린', '인'],
    '임': ['림', '임'], // "임" → "림" 또는 "임" (역방향)
    '입': ['립', '입'],
    '음': ['름', '음'], // "음" → "름" 또는 "음" (역방향)
    '역': ['력', '역'], // "역" → "력" 또는 "역" (역방향)
    '나': ['라', '나'],
    '낙': ['락', '낙'],
    '난': ['란', '난'],
    '낭': ['랑', '낭'],
    '납': ['랍', '납'],
    '내': ['래', '내'],
    '냉': ['랭', '냉'],
    '낸': ['랜', '낸'],
    '남': ['램', '남'],
  };

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
  
  // 끝말잇기 규칙 검증 (두음법칙 적용)
  static bool validateWordChain(String previousWord, String currentWord) {
    if (previousWord.isEmpty || currentWord.isEmpty) return false;
    
    final previousLastChar = previousWord[previousWord.length - 1];
    final currentFirstChar = currentWord[0];
    
    // 1. 정확한 매칭
    if (previousLastChar == currentFirstChar) {
      return true;
    }
    
    // 2. 두음법칙 적용 검증 - "름" → "음", "림" → "임" 등
    final possibleFirstChars = _doubleConsonantRules[previousLastChar];
    if (possibleFirstChars != null && possibleFirstChars.contains(currentFirstChar)) {
      return true;
    }
    
    return false;
  }
  
  // 특정 글자로 시작하는 단어들 검색 (두음법칙 포함)
  static Future<List<Word>> searchWordsByFirstChar(String firstChar, {int limit = 50}) async {
    // 원래 글자로 시작하는 단어들
    List<Word> words = [];
    
    // 1. 정확한 글자로 시작하는 단어들
    final exactResult = await DatabaseManager.database.rawQuery(
      'SELECT * FROM words WHERE first_char = ? ORDER BY frequency DESC LIMIT ?',
      [firstChar, limit]
    );
    words.addAll(exactResult.map((row) => Word.fromJson(row)));
    
    // 2. 두음법칙 적용 단어들 추가
    final possibleChars = _doubleConsonantRules[firstChar] ?? [];
    for (String altChar in possibleChars) {
      if (altChar != firstChar) { // 중복 제거
        final altResult = await DatabaseManager.database.rawQuery(
          'SELECT * FROM words WHERE first_char = ? ORDER BY frequency DESC LIMIT ?',
          [altChar, limit ~/ 2] // 일부만 가져와서 균형 맞춤
        );
        words.addAll(altResult.map((row) => Word.fromJson(row)));
      }
    }
    
    // 중복 제거 및 빈도순 정렬
    final uniqueWords = <String, Word>{};
    for (Word word in words) {
      if (!uniqueWords.containsKey(word.word)) {
        uniqueWords[word.word] = word;
      }
    }
    
    final result = uniqueWords.values.toList();
    result.sort((a, b) => b.frequency.compareTo(a.frequency));
    
    return result.take(limit).toList();
  }
  
  // 두음법칙을 고려한 가능한 시작 글자들 반환
  static List<String> getPossibleFirstChars(String lastChar) {
    final possibleChars = _doubleConsonantRules[lastChar] ?? [lastChar];
    return possibleChars;
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
  
  // 두음법칙 정보 출력 (디버깅용)
  static void printDoubleConsonantInfo(String char) {
    final possibleChars = _doubleConsonantRules[char];
    if (possibleChars != null) {
      print('$char → 가능한 시작 글자: ${possibleChars.join(", ")}');
    } else {
      print('$char → 두음법칙 없음');
    }
  }
}