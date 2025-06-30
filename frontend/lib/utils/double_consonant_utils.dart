/// 한국어 두음법칙 처리 유틸리티 클래스
class DoubleConsonantUtils {
  // 두음법칙 매핑 테이블
  static const Map<String, List<String>> _doubleConsonantRules = {
    // ㄹ 계열 (ㄹ로 시작하는 글자들이 ㄴ이나 무음으로 바뀜)
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

  /// 주어진 글자에 대한 두음법칙 변형들을 반환
  /// 
  /// [char] 변형을 찾을 글자
  /// 반환: 가능한 모든 변형 리스트 (원본 포함)
  static List<String> getPossibleChars(String char) {
    return _doubleConsonantRules[char] ?? [char];
  }

  /// 두 글자가 두음법칙에 의해 연결 가능한지 확인
  /// 
  /// [lastChar] 이전 단어의 마지막 글자
  /// [firstChar] 현재 단어의 첫 글자
  /// 반환: 연결 가능하면 true
  static bool isValidConnection(String lastChar, String firstChar) {
    // 정확한 매칭
    if (lastChar == firstChar) return true;
    
    // 두음법칙 적용 확인
    final possibleChars = _doubleConsonantRules[lastChar];
    return possibleChars?.contains(firstChar) ?? false;
  }

  /// 두음법칙이 적용되는 글자인지 확인
  /// 
  /// [char] 확인할 글자
  /// 반환: 두음법칙이 적용되면 true
  static bool hasDoubleConsonantRule(String char) {
    final possibleChars = _doubleConsonantRules[char];
    return possibleChars != null && possibleChars.length > 1;
  }

  /// 두음법칙 설명 텍스트 생성
  /// 
  /// [char] 설명할 글자
  /// 반환: 사용자에게 표시할 설명 텍스트
  static String getExplanationText(String char) {
    final possibleChars = getPossibleChars(char);
    
    if (possibleChars.length == 1) {
      return '"$char"(으)로 시작하는 단어';
    } else {
      final alternatives = possibleChars.where((c) => c != char).toList();
      if (alternatives.isNotEmpty) {
        return '"$char" 또는 "${alternatives.join(', ')}"(으)로 시작하는 단어';
      } else {
        return '"$char"(으)로 시작하는 단어';
      }
    }
  }

  /// UI 표시용 간단한 형태
  /// 
  /// [char] 표시할 글자
  /// 반환: UI에 표시할 텍스트 (예: "름/음")
  static String getDisplayText(String char) {
    final possibleChars = getPossibleChars(char);
    
    if (possibleChars.length == 1) {
      return char;
    } else {
      return possibleChars.join('/');
    }
  }
}
