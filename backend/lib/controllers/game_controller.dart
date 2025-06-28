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
        'INSERT INTO game_sessions (id, current_stage, score, player_turns, status, used_words) VALUES (?, ?, ?, ?, ?, ?)',
        [gameId, 1, 0, 0, 'active', startWord]
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
      final usedWordsString = sessionData['used_words'] as String? ?? '';
      final usedWords = usedWordsString.split(',').where((w) => w.isNotEmpty).toList();
      final lastWord = usedWords.isNotEmpty ? usedWords.last : '';
      final currentScore = sessionData['score'] as int? ?? 0;
      final currentPlayerTurns = sessionData['player_turns'] as int? ?? 0;
      
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
      final aiResponse = await AIService.generateResponse(playerWord, 1, usedWords);
      
      if (!aiResponse.success) {
        // AI가 응답하지 못함 = 플레이어 승리
        await DatabaseManager.database.rawUpdate(
          'UPDATE game_sessions SET status = ?, ended_at = ?, used_words = ?, score = ?, player_turns = ? WHERE id = ?',
          ['player_win', DateTime.now().toIso8601String(), usedWords.join(','), newScore, newPlayerTurns, gameId]
        );
        
        return {
          'success': true,
          'gameOver': true,
          'victory': true,
          'message': '🎉 축하합니다! AI가 답할 수 없어서 플레이어가 승리했습니다!',
          'playerWord': playerWord,
          'finalWords': usedWords,
          'score': newScore,
          'playerTurns': newPlayerTurns
        };
      }
      
      // 6. AI 단어 추가
      usedWords.add(aiResponse.word);
      
      // 7. 게임 세션 업데이트
      await DatabaseManager.database.rawUpdate(
        'UPDATE game_sessions SET used_words = ?, score = ?, player_turns = ? WHERE id = ?',
        [usedWords.join(','), newScore, newPlayerTurns, gameId]
      );
      
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
        'lastChar': aiResponse.word[aiResponse.word.length - 1]
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
        'aiInfo': AIService.getAIInfo(1)
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
