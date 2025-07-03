import 'package:dio/dio.dart';

class ApiService {
  // 배포 환경에 따라 API URL 설정
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );
  
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // 게임 시작
  static Future<Map<String, dynamic>?> startGame() async {
    try {
      print('🎮 게임 시작 API 호출...');
      final response = await _dio.post('/game/start');
      
      if (response.statusCode == 200) {
        print('✅ 게임 시작 성공: ${response.data}');
        return response.data;
      }
      return null;
    } catch (e) {
      print('❌ 게임 시작 실패: $e');
      return null;
    }
  }

  // 단어 제출
  static Future<Map<String, dynamic>?> submitWord({
    required String gameId,
    required String word,
    int? responseTime,
  }) async {
    try {
      print('📝 단어 제출 API 호출: $word');
      final response = await _dio.post('/game/submit-word', data: {
        'gameId': gameId,
        'word': word,
        'responseTime': responseTime ?? 5000,
      });
      
      if (response.statusCode == 200) {
        print('✅ 단어 제출 성공: ${response.data}');
        return response.data;
      }
      return null;
    } catch (e) {
      print('❌ 단어 제출 실패: $e');
      return null;
    }
  }

  // 게임 상태 조회
  static Future<Map<String, dynamic>?> getGameStatus(String gameId) async {
    try {
      final response = await _dio.get('/game/status/$gameId');
      
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('❌ 게임 상태 조회 실패: $e');
      return null;
    }
  }

  // 게임 종료
  static Future<Map<String, dynamic>?> endGame({
    required String gameId,
    String? playerName,
  }) async {
    try {
      final response = await _dio.post('/game/end', data: {
        'gameId': gameId,
        'playerName': playerName,
      });
      
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('❌ 게임 종료 실패: $e');
      return null;
    }
  }

  // 단어 검증
  static Future<bool> validateWord(String word) async {
    try {
      final response = await _dio.get('/word/validate/$word');
      
      if (response.statusCode == 200) {
        return response.data['valid'] ?? false;
      }
      return false;
    } catch (e) {
      print('❌ 단어 검증 실패: $e');
      return false;
    }
  }

  // 서버 헬스체크
  static Future<bool> checkServerHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ 서버 연결 실패: $e');
      return false;
    }
  }

  // 랭킹 등록
  static Future<Map<String, dynamic>?> submitScore({
    required String playerName,
    required int score,
    required int stageReached,
  }) async {
    try {
      print('🏆 랭킹 등록 API 호출: $playerName, 점수: $score');
      final response = await _dio.post('/ranking/submit', data: {
        'playerName': playerName,
        'score': score,
        'stageReached': stageReached,
      });
      
      if (response.statusCode == 200) {
        print('✅ 랭킹 등록 성공: ${response.data}');
        return response.data;
      }
      return null;
    } catch (e) {
      print('❌ 랭킹 등록 실패: $e');
      return null;
    }
  }

  // 랭킹 조회
  static Future<Map<String, dynamic>?> getRankings({int limit = 10}) async {
    try {
      final response = await _dio.get('/ranking?limit=$limit');
      
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('❌ 랭킹 조회 실패: $e');
      return null;
    }
  }
}
