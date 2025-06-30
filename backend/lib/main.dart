import 'package:alfred/alfred.dart';
import 'database/database.dart';
import 'controllers/game_controller.dart';
import 'controllers/ranking_controller.dart';
import 'controllers/word_controller.dart';

void main() async {
  print('🚀 서버 시작 중...');
  
  try {
    // 데이터베이스 초기화
    await DatabaseManager.initialize();
    
    final app = Alfred();

    // CORS 설정 (Flutter Web과 통신을 위해)
    app.all('*', cors(origin: '*', headers: '*'));

    // ==================== API 엔드포인트 ====================
    
    // 게임 관련 API
    app.post('/api/game/start', (HttpRequest req, HttpResponse res) async {
      return await GameController.startGame(req, res);
    });
    
    app.post('/api/game/submit-word', (HttpRequest req, HttpResponse res) async {
      return await GameController.submitWord(req, res);
    });
    
    app.get('/api/game/status/:sessionId', (HttpRequest req, HttpResponse res) async {
      return await GameController.getGameStatus(req, res);
    });
    
    app.post('/api/game/end', (HttpRequest req, HttpResponse res) async {
      return await GameController.endGame(req, res);
    });
    
    // 랭킹 관련 API
    app.get('/api/ranking', (HttpRequest req, HttpResponse res) async {
      return await RankingController.getRankingList(req, res);
    });
    
    app.post('/api/ranking/submit', (HttpRequest req, HttpResponse res) async {
      return await RankingController.submitScore(req, res);
    });
    
    app.get('/api/ranking/player/:playerName', (HttpRequest req, HttpResponse res) async {
      return await RankingController.getPlayerBestScore(req, res);
    });
    
    // 단어 관련 API
    app.get('/api/word/validate/:word', (HttpRequest req, HttpResponse res) async {
      return await WordController.validateWord(req, res);
    });
    
    app.get('/api/word/search/:startChar', (HttpRequest req, HttpResponse res) async {
      return await WordController.searchWords(req, res);
    });
    
    // 헬스체크
    app.get('/api/health', (HttpRequest req, HttpResponse res) {
      return {
        'status': 'OK',
        'message': '끝말잇기 대전 API 서버가 정상 작동 중입니다',
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'database': 'Connected'
      };
    });

    // 테스트 엔드포인트 (API 문서)
    app.get('/api/test', (HttpRequest req, HttpResponse res) {
      return {
        'message': 'Hello World - 끝말잇기 대전 API',
        'endpoints': [
          'POST /api/game/start - 게임 시작',
          'POST /api/game/submit-word - 단어 제출',
          'GET /api/game/status/:sessionId - 게임 상태 조회',
          'POST /api/game/end - 게임 종료',
          '',
          'GET /api/ranking - 랭킹 조회',
          'POST /api/ranking/submit - 점수 제출',
          'GET /api/ranking/player/:playerName - 플레이어 기록 조회',
          '',
          'GET /api/word/validate/:word - 단어 검증',
          'GET /api/word/search/:startChar - 단어 검색',
          '',
          'GET /api/health - 서버 상태 확인',
        ],
        'example_requests': {
          'start_game': {
            'method': 'POST',
            'url': '/api/game/start',
            'body': '{}'
          },
          'submit_word': {
            'method': 'POST',
            'url': '/api/game/submit-word',
            'body': '{"gameId": "1234", "word": "사과", "previousWord": "", "responseTime": 3000}'
          },
          'ranking': {
            'method': 'GET',
            'url': '/api/ranking?limit=10'
          }
        }
      };
    });

    // 루트 엔드포인트
    app.get('/', (HttpRequest req, HttpResponse res) {
      return {
        'title': '🎮 끝말잇기 대전 API 서버',
        'status': 'running',
        'docs': '/api/test',
        'health': '/api/health'
      };
    });

    // 서버 시작
    await app.listen(8080);
    
    print('✅ 서버 초기화 완료!');
    print('🌐 서버 주소: http://localhost:8080');
    print('📄 API 문서: http://localhost:8080/api/test');
    print('❤️ 헬스체크: http://localhost:8080/api/health');
    print('');
    print('게임 API 엔드포인트:');
    print('  POST /api/game/start');
    print('  POST /api/game/submit-word');
    print('  GET  /api/game/status/:sessionId');
    print('  POST /api/game/end');
    print('');
    print('랭킹 API 엔드포인트:');
    print('  GET  /api/ranking');
    print('  POST /api/ranking/submit');
    print('  GET  /api/ranking/player/:playerName');
    print('');
    print('단어 API 엔드포인트:');
    print('  GET  /api/word/validate/:word');
    print('  GET  /api/word/search/:startChar');
    
  } catch (e) {
    print('❌ 서버 시작 실패: $e');
    rethrow;
  }
}
