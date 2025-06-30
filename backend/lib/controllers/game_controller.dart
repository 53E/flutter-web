import 'package:alfred/alfred.dart';
import 'dart:convert';
import 'dart:io';
import '../database/database.dart';
import '../models/game_session.dart';
import '../services/word_service.dart';
import '../services/ai_service.dart';
import '../services/score_service.dart';

class GameController {
  static Future<Map<String, dynamic>> startGame(
    HttpRequest req, 
    HttpResponse res
  ) async {
    try {
      final gameId = DateTime.now().millisecondsSinceEpoch.toString();
      final startWord = await AIService.generateStartWord();
      
      // 게임 세션 생성 (시작 단어 포함)
      await DatabaseManager.database.rawInsert(
        'INSERT INTO game_sessions (id, current_stage, score, player_turns, status, used_words, ai_turn_count) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [gameId, 1, 0, 0, 'active', startWord, 0]
      );
      
      print('🎮 새 게임 시작: $gameId, 시작 단어: $startWord');
      
      return {
        'success': true,
        'gameId': gameId,
        'aiWord': startWord,
        'stage': 1,
        'message': 'AI가 "$startWord"(으)로 게임을 시작했습니다!',
        'turn': 'player',
        'usedWords': [startWord],
        'playerTurns': 0,
        'score': 0
      };
    } catch (e) {
      print('❌ 게임 시작 오류: $e');
      return {
        'success': false,
        'message': '게임 시작 실패: $e'
      };
    }
  }
  
  static Future<Map<String, dynamic>> submitWord(
    HttpRequest req, 
    HttpResponse res
  ) async {
    try {
      final body = await utf8.decoder.bind(req).join();
      final data = json.decode(body);
      
      final gameId = data['gameId'] as String;
      final playerWord = data['word'] as String;
      final responseTime = data['responseTime'] as int? ?? 5000;
      
      print('📝 플레이어 단어 제출: $playerWord (게임: $gameId)');
      
      // 게임 세션 확인
      final sessionResult = await DatabaseManager.database.rawQuery(
        'SELECT * FROM game_sessions WHERE id = ? AND status = ?',
        [gameId, 'active']
      );
      
      if (sessionResult.isEmpty) {
        return {
          'success': false,
          'message': '유효하지 않은 게임 세션입니다'
        };
      }
      
      final sessionData = sessionResult.first;
      print('📊 === 디버깅: 세션 데이터 상세 뷔열 ===');
      print('📊 current_stage 원본 값: ${sessionData['current_stage']} (타입: ${sessionData['current_stage'].runtimeType})');
      print('📊 전체 세션 데이터: $sessionData');
      print('📊 === 디버깅 끝 ===');
      
      final usedWordsString = sessionData['used_words'] as String? ?? '';
      final usedWords = usedWordsString.split(',').where((w) => w.isNotEmpty).toList();
      final lastWord = usedWords.isNotEmpty ? usedWords.last : '';
      final currentScore = sessionData['score'] as int? ?? 0;
      final currentPlayerTurns = sessionData['player_turns'] as int? ?? 0;
      
      // 🔧 더 상세한 디버깅
      final rawStage = sessionData['current_stage'];
      print('🔍 current_stage 원본 값: $rawStage (타입: ${rawStage.runtimeType})');
      
      final currentStage = sessionData['current_stage'] as int? ?? 1;
      print('🔍 캐스팅 후 currentStage: $currentStage');
      
      final aiTurnCount = sessionData['ai_turn_count'] as int? ?? 0;
      
      print('🔍 사용된 단어들: $usedWords');
      print('🔍 마지막 단어: $lastWord');
      
      // 1. 단어 유효성 검증
      if (!(await WordService.validateWord(playerWord))) {
        return {
          'success': false,
          'message': '"$playerWord"는 사전에 없는 단어입니다',
          'gameOver': false
        };
      }
      
      // 2. 중복 단어 검증
      if (usedWords.contains(playerWord)) {
        return {
          'success': false,
          'message': '"$playerWord"는 이미 사용된 단어입니다',
          'gameOver': false
        };
      }
      
      // 3. 끝말잇기 규칙 검증
      if (lastWord.isNotEmpty && !WordService.validateWordChain(lastWord, playerWord)) {
        final expectedChar = lastWord[lastWord.length - 1];
        return {
          'success': false,
          'message': '"$expectedChar"(으)로 시작하는 단어를 입력해주세요',
          'gameOver': false
        };
      }
      
      // 4. 플레이어 단어 추가
      usedWords.add(playerWord);
      
      // 5. 점수와 턴 계산
      final wordScore = playerWord.length * 10; // 글자수 x 10점
      final newScore = currentScore + wordScore;
      final newPlayerTurns = currentPlayerTurns + 1;
      
      print('🏆 플레이어 단어 "$playerWord" - 글자수: ${playerWord.length}, 점수: $wordScore, 총점: $newScore, 턴: $newPlayerTurns');
      
      // 6. AI 응답 생성
      final aiResponse = await AIService.generateResponse(
        playerWord, 
        currentStage, 
        usedWords,
        aiTurnCount: aiTurnCount
      );
      
      if (!aiResponse.success) {
        // AI가 응답하지 못함 - 두 경우 모두 단계 클리어 처리
        print('🏆 AI 응답 실패: ${aiResponse.reason}');
        
        // 단계 클리어 또는 승리 처리
        if (currentStage < 3) {
          // 다음 단계로 진행
          final nextStage = currentStage + 1;
          print('🎮 단계 클리어 상황: ${currentStage}단계 -> ${nextStage}단계 (이유: ${aiResponse.reason})');
          print('💾 데이터베이스 업데이트 시작... (gameId: $gameId)');
          
          final updateResult = await DatabaseManager.database.rawUpdate(
            'UPDATE game_sessions SET used_words = ?, score = ?, player_turns = ?, current_stage = ?, ai_turn_count = ? WHERE id = ?',
            [usedWords.join(','), newScore, newPlayerTurns, nextStage, 0, gameId] // AI 턴 카운트 리셋
          );
          
          print('💾 데이터베이스 업데이트 결과: $updateResult개 레코드 업데이트');
          
          if (updateResult == 0) {
            print('⚠️ 경고: 데이터베이스 업데이트 실패! gameId: $gameId');
          }
          
          // 업데이트 후 확인
          final verifyResult = await DatabaseManager.database.rawQuery(
            'SELECT current_stage FROM game_sessions WHERE id = ?',
            [gameId]
          );
          
          if (verifyResult.isNotEmpty) {
            final verifiedStage = verifyResult.first['current_stage'] as int?;
            print('🔍 업데이트 후 데이터베이스 단계: $verifiedStage');
          }
          
          return {
            'success': true,
            'gameOver': false,
            'stageClear': true,
            'message': '🎉 ${currentStage}단계 클리어! ${nextStage}단계로 진행합니다!',
            'playerWord': playerWord,
            'usedWords': usedWords,
            'score': newScore,
            'playerTurns': newPlayerTurns,
            'currentStage': nextStage, // 🔧 수정: 다음 단계 반환
            'nextStage': nextStage
          };
        } else {
          // 모든 단계 클리어 = 게임 승리
          await DatabaseManager.database.rawUpdate(
            'UPDATE game_sessions SET status = ?, ended_at = ?, used_words = ?, score = ?, player_turns = ? WHERE id = ?',
            ['victory', DateTime.now().toIso8601String(), usedWords.join(','), newScore, newPlayerTurns, gameId]
          );
          
          return {
            'success': true,
            'gameOver': true,
            'victory': true,
            'message': '🏆 축하합니다! 모든 단계를 클리어했습니다!',
            'playerWord': playerWord,
            'finalWords': usedWords,
            'score': newScore,
            'playerTurns': newPlayerTurns,
            'currentStage': currentStage
          };
        }
      }
      
      // 6. AI 단어 추가
      usedWords.add(aiResponse.word);
      
      // 7. 게임 세션 업데이트 (AI 턴 카운트 증가) - current_stage도 명시적으로 포함
      await DatabaseManager.database.rawUpdate(
        'UPDATE game_sessions SET used_words = ?, score = ?, player_turns = ?, ai_turn_count = ?, current_stage = ? WHERE id = ?',
        [usedWords.join(','), newScore, newPlayerTurns, aiTurnCount + 1, currentStage, gameId]
      );
      
      print('📊 AI 응답 후: 단계 유지 $currentStage (DB 명시적 업데이트)');
      
      // 8. 🔧 수정: DB 재조회 대신 현재 단계 사용 (데이터 일관성 보장)
      final latestStage = currentStage;
      
      return {
        'success': true,
        'gameOver': false,
        'victory': false,
        'message': 'AI가 "${aiResponse.word}"(으)로 응답했습니다',
        'playerWord': playerWord,
        'aiWord': aiResponse.word,
        'turn': 'player',
        'usedWords': usedWords,
        'score': newScore,
        'playerTurns': newPlayerTurns,
        'lastChar': aiResponse.word[aiResponse.word.length - 1],
        'currentStage': latestStage, // 최신 DB 단계 사용!
        'aiTurnCount': aiTurnCount + 1
      };
      
    } catch (e) {
      print('❌ 단어 제출 오류: $e');
      return {
        'success': false,
        'message': '단어 제출 처리 중 오류: $e'
      };
    }
  }
  
  static Future<Map<String, dynamic>> getGameStatus(
    HttpRequest req, 
    HttpResponse res
  ) async {
    try {
      final sessionId = req.uri.pathSegments.last;
      
      final result = await DatabaseManager.database.rawQuery(
        'SELECT * FROM game_sessions WHERE id = ?',
        [sessionId]
      );
      
      if (result.isEmpty) {
        return {
          'success': false,
          'message': '게임 세션을 찾을 수 없습니다'
        };
      }
      
      final sessionData = result.first;
      final usedWordsString = sessionData['used_words'] as String? ?? '';
      final usedWords = usedWordsString.split(',').where((w) => w.isNotEmpty).toList();
      
      return {
        'success': true,
        'gameId': sessionData['id'],
        'status': sessionData['status'],
        'usedWords': usedWords,
        'totalTurns': usedWords.length,
        'lastWord': usedWords.isNotEmpty ? usedWords.last : '',
        'currentStage': sessionData['current_stage'] as int? ?? 1,
        'aiTurnCount': sessionData['ai_turn_count'] as int? ?? 0,
        'aiInfo': AIService.getAIInfo(sessionData['current_stage'] as int? ?? 1)
      };
    } catch (e) {
      return {
        'success': false,
        'message': '게임 상태 조회 실패: $e'
      };
    }
  }
  
  static Future<Map<String, dynamic>> endGame(
    HttpRequest req, 
    HttpResponse res
  ) async {
    try {
      final body = await utf8.decoder.bind(req).join();
      final data = json.decode(body);
      
      final gameId = data['gameId'] as String;
      final playerName = data['playerName'] as String?;
      
      await DatabaseManager.database.rawUpdate(
        'UPDATE game_sessions SET status = ?, ended_at = ?, player_name = ? WHERE id = ?',
        ['ended', DateTime.now().toIso8601String(), playerName, gameId]
      );
      
      final result = await DatabaseManager.database.rawQuery(
        'SELECT * FROM game_sessions WHERE id = ?',
        [gameId]
      );
      
      if (result.isNotEmpty) {
        final sessionData = result.first;
        final usedWordsString = sessionData['used_words'] as String? ?? '';
        final usedWords = usedWordsString.split(',').where((w) => w.isNotEmpty).toList();
        
        return {
          'success': true,
          'message': '게임이 종료되었습니다',
          'totalTurns': usedWords.length,
          'usedWords': usedWords

        };
      }
      
      return {
        'success': false,
        'message': '게임 세션을 찾을 수 없습니다'
      };
    } catch (e) {
      return {
        'success': false,
        'message': '게임 종료 처리 실패: $e'
      };
    }
  }
}
