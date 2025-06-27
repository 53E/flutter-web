import 'package:alfred/alfred.dart';
import 'dart:convert';
import '../database/database.dart';
import '../models/player_score.dart';
import '../services/score_service.dart';

class RankingController {
  // 랭킹 리스트 조회
  static Future<Map<String, dynamic>> getRankingList(HttpRequest req, HttpResponse res) async {
    try {
      final limitParam = req.uri.queryParameters['limit'];
      final limit = limitParam != null ? int.tryParse(limitParam) ?? 10 : 10;
      
      // 점수 순으로 정렬하여 랭킹 조회
      final result = await DatabaseManager.database.rawQuery(
        'SELECT * FROM rankings ORDER BY score DESC LIMIT ?',
        [limit]
      );
      
      final rankings = result.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;
        return {
          'rank': index + 1,
          'playerName': row['player_name'],
          'score': row['score'],
          'stageReached': row['stage_reached'],
          'grade': ScoreService.calculateGrade(row['score'] as int),
          'createdAt': row['created_at'],
        };
      }).toList();
      
      return {
        'success': true,
        'count': rankings.length,
        'rankings': rankings,
        'message': '랭킹 리스트를 가져왔습니다'
      };
    } catch (e) {
      return {
        'success': false,
        'message': '랭킹 조회 중 오류가 발생했습니다: $e'
      };
    }
  }
  
  // 점수 제출 (랭킹 등록)
  static Future<Map<String, dynamic>> submitScore(HttpRequest req, HttpResponse res) async {
    try {
      final body = await utf8.decoder.bind(req).join();
      final data = json.decode(body);
      
      final playerName = data['playerName'] as String;
      final score = data['score'] as int;
      final stageReached = data['stageReached'] as int;
      
      if (playerName.isEmpty) {
        return {
          'success': false,
          'message': '플레이어 이름을 입력해주세요'
        };
      }
      
      if (score < 0) {
        return {
          'success': false,
          'message': '유효하지 않은 점수입니다'
        };
      }
      
      // 랭킹에 추가
      await DatabaseManager.database.rawInsert(
        'INSERT INTO rankings (player_name, score, stage_reached) VALUES (?, ?, ?)',
        [playerName, score, stageReached]
      );
      
      // 추가된 랭킹의 순위 계산
      final rankResult = await DatabaseManager.database.rawQuery(
        'SELECT COUNT(*) + 1 as rank FROM rankings WHERE score > ?',
        [score]
      );
      
      final rank = rankResult.first['rank'] as int;
      final grade = ScoreService.calculateGrade(score);
      
      return {
        'success': true,
        'message': '랭킹에 등록되었습니다!',
        'playerName': playerName,
        'score': score,
        'stageReached': stageReached,
        'rank': rank,
        'grade': grade,
      };
    } catch (e) {
      return {
        'success': false,
        'message': '점수 제출 중 오류가 발생했습니다: $e'
      };
    }
  }
  
  // 플레이어 최고 기록 조회
  static Future<Map<String, dynamic>> getPlayerBestScore(HttpRequest req, HttpResponse res) async {
    try {
      final playerName = req.uri.pathSegments.last;
      
      if (playerName.isEmpty) {
        return {
          'success': false,
          'message': '플레이어 이름을 입력해주세요'
        };
      }
      
      final result = await DatabaseManager.database.rawQuery(
        'SELECT * FROM rankings WHERE player_name = ? ORDER BY score DESC LIMIT 1',
        [playerName]
      );
      
      if (result.isEmpty) {
        return {
          'success': false,
          'message': '해당 플레이어의 기록을 찾을 수 없습니다'
        };
      }
      
      final bestScore = PlayerScore.fromJson(result.first);
      
      // 순위 계산
      final rankResult = await DatabaseManager.database.rawQuery(
        'SELECT COUNT(*) + 1 as rank FROM rankings WHERE score > ?',
        [bestScore.score]
      );
      
      final rank = rankResult.first['rank'] as int;
      
      return {
        'success': true,
        'playerName': bestScore.playerName,
        'bestScore': bestScore.score,
        'stageReached': bestScore.stageReached,
        'rank': rank,
        'grade': ScoreService.calculateGrade(bestScore.score),
        'createdAt': bestScore.createdAt.toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': '플레이어 기록 조회 중 오류가 발생했습니다: $e'
      };
    }
  }
}
