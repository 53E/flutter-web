import 'package:alfred/alfred.dart';
import '../services/word_service.dart';

class WordController {
  // 단어 유효성 검증
  static Future<Map<String, dynamic>> validateWord(HttpRequest req, HttpResponse res) async {
    try {
      final word = req.uri.pathSegments.last;
      
      if (word.isEmpty) {
        return {
          'success': false,
          'valid': false,
          'message': '단어를 입력해주세요'
        };
      }
      
      final isValid = await WordService.validateWord(word);
      
      return {
        'success': true,
        'valid': isValid,
        'word': word,
        'message': isValid ? '유효한 단어입니다' : '사전에 없는 단어입니다'
      };
    } catch (e) {
      return {
        'success': false,
        'valid': false,
        'message': '단어 검증 중 오류가 발생했습니다: $e'
      };
    }
  }
  
  // 특정 글자로 시작하는 단어 검색
  static Future<Map<String, dynamic>> searchWords(HttpRequest req, HttpResponse res) async {
    try {
      final startChar = req.uri.pathSegments.last;
      final limitParam = req.uri.queryParameters['limit'];
      final limit = limitParam != null ? int.tryParse(limitParam) ?? 20 : 20;
      
      if (startChar.isEmpty) {
        return {
          'success': false,
          'message': '검색할 글자를 입력해주세요'
        };
      }
      
      final words = await WordService.searchWordsByFirstChar(startChar, limit: limit);
      
      return {
        'success': true,
        'startChar': startChar,
        'count': words.length,
        'words': words.map((w) => w.toJson()).toList(),
        'message': '$startChar(으)로 시작하는 단어 ${words.length}개를 찾았습니다'
      };
    } catch (e) {
      return {
        'success': false,
        'message': '단어 검색 중 오류가 발생했습니다: $e'
      };
    }
  }
}
