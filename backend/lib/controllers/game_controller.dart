import 'package:alfred/alfred.dart';
import 'dart:convert';
import 'dart:io';
import '../database/database.dart';
import '../models/game_session.dart';
import '../services/word_service.dart';
import '../services/ai_service.dart';
import '../services/score_service.dart';

class GameController {
  static Future<Map<String, dynamic>> startGame(HttpRequest req, HttpResponse res) async {
    try {
      final gameId = DateTime.now().millisecondsSinceEpoch.toString();
      final startWord = await AIService.generateStartWord();
      
      await DatabaseManager.database.rawInsert(
        'INSERT INTO game_sessions (id, current_stage, score, status) VALUES (?, ?, ?, ?)',
        [gameId, 1, 0, 'active']
      );
      
      print('🎮 새 게임 시작: $gameId');
      
      return {
        'success': true,
        'gameId': gameId,
        'startWord': startWord,
        'stage': 1,
        'message': '게임이 시작되었습니다! 첫 단어는 "$startWord"입니다.'
      };
    } catch (e) {
      print('❌ 게임 시작 오류: $e');
      return {
        'success': false,
        'message': '게임 시작에 실패했습니다: $e'
      };
    }
  }
  
  static Future<Map<String, dynamic>> submitWord(HttpRequest req, HttpResponse res) async {
    try {
      final body = await utf8.decoder.bind(req).join();
      final data = json.decode(body);
      
      final gameId = data['gameId'] as String;
      final playerWord = data['word'] as String;
      final previousWord = data['previousWord'] as String? ?? '';
      final responseTime = data['responseTime'] as int? ?? 5000;
      
      print('📝 단어 제출: $playerWord (게임: $gameId)');
      
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
      
      final session = GameSession.fromJson(sessionResult.first);
      
      if (!(await WordService.validateWord(playerWord))) {
        return {
          'success': false,
          'message': '"$playerWord"는 사전에 없는 단어입니다',
          'gameOver': false
        };
      }
      
      if (previousWord.isNotEmpty && !WordService.validateWordChain(previousWord, playerWord)) {
        final expectedChar = previousWord[previousWord.length - 1];
        return {
          'success': false,
          'message': '"$expectedChar"(으)로 시작하는 단어를 입력해주세요',
          'gameOver': false
        };
      }
      
      final wordScore = ScoreService.calculateWordScore(
        word: playerWord,
        stage: session.currentStage,
        responseTime: responseTime,
        consecutiveCorrect: 1,
      );
      
      final newScore = session.score + wordScore;
      final aiResponse = await AIService.generateResponse(playerWord, session.currentStage);
      
      if (!aiResponse.success) {
        final stageBonus = ScoreService.calculateStageClearBonus(session.currentStage);
        final finalScore = newScore + stageBonus;
        final nextStage = session.currentStage + 1;
        
        await DatabaseManager.database.rawUpdate(
          'UPDATE game_sessions SET score = ?, current_stage = ? WHERE id = ?',
          [finalScore, nextStage, gameId]
        );
        
        if (nextStage > 8) {
          final completionBonus = ScoreService.calculateGameCompletionBonus();
          final gameCompletionScore = finalScore + completionBonus;
          
          await DatabaseManager.database.rawUpdate(
            'UPDATE game_sessions SET score = ?, status = ?, ended_at = ? WHERE id = ?',
            [gameCompletionScore, 'completed', DateTime.now().toIso8601String(), gameId]
          );
          
          return {
            'success': true,
            'gameOver': true,
            'victory': true,
            'message': '🎉 모든 스테이지를 클리어했습니다!',
            'playerWord': playerWord,
            'aiResponse': aiResponse.toJson(),
            'score': gameCompletionScore,
            'stage': session.currentStage,
            'stageCleared': true,
            'finalStage': true
          };
        }
        
        return {
          'success': true,
          'gameOver': false,
          'victory': false,
          'message': '🎯 스테이지 ${session.currentStage} 클리어! 다음 스테이지로 진행합니다.',
          'playerWord': playerWord,
          'aiResponse': aiResponse.toJson(),
          'score': finalScore,
          'stage': nextStage,
          'stageCleared': true,
          'nextStageAI': AIService.getAIInfo(nextStage)
        };
      }
      
      await DatabaseManager.database.rawUpdate(
        'UPDATE game_sessions SET score = ? WHERE id = ?',
        [newScore, gameId]
      );
      
      return {
        'success': true,
        'gameOver': false,
        'victory': false,
        'message': 'AI가 "${aiResponse.word}"(으)로 응답했습니다',
        'playerWord': playerWord,
        'aiWord': aiResponse.word,
        'aiResponse': aiResponse.toJson(),
        'score': newScore,
        'stage': session.currentStage,
        'wordScore': wordScore,
        'scoreBreakdown': ScoreService.getScoreBreakdown(
          word: playerWord,
          stage: session.currentStage,
          responseTime: responseTime,
          consecutiveCorrect: 1,
        )
      };
      
    } catch (e) {
      print('❌ 단어 제출 오류: $e');
      return {
        'success': false,
        'message': '단어 제출 처리 중 오류가 발생했습니다: $e'
      };
    }
  }
  
  static Future<Map<String, dynamic>> getGameStatus(HttpRequest req, HttpResponse res) async {
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
      
      final session = GameSession.fromJson(result.first);
      
      return {
        'success': true,
        'session': session.toJson(),
        'aiInfo': AIService.getAIInfo(session.currentStage)
      };
    } catch (e) {
      return {
        'success': false,
        'message': '게임 상태 조회 실패: $e'
      };
    }
  }
  
  static Future<Map<String, dynamic>> endGame(HttpRequest req, HttpResponse res) async {
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
        final session = GameSession.fromJson(result.first);
        
        if (playerName != null && playerName.isNotEmpty) {
          await DatabaseManager.database.rawInsert(
            'INSERT INTO rankings (player_name, score, stage_reached) VALUES (?, ?, ?)',
            [playerName, session.score, session.currentStage]
          );
        }
        
        return {
          'success': true,
          'message': '게임이 종료되었습니다',
          'finalScore': session.score,
          'stageReached': session.currentStage,
          'grade': ScoreService.calculateGrade(session.score)
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
