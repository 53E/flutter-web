// 플레이어 점수 모델
class PlayerScore {
  final int? id;
  final String playerName;
  final int score;
  final int stageReached;
  final DateTime createdAt;
  
  PlayerScore({
    this.id,
    required this.playerName,
    required this.score,
    required this.stageReached,
    required this.createdAt,
  });
  
  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerName': playerName,
      'score': score,
      'stageReached': stageReached,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  // JSON에서 생성
  factory PlayerScore.fromJson(Map<String, dynamic> json) {
    return PlayerScore(
      id: json['id'],
      playerName: json['player_name'],
      score: json['score'],
      stageReached: json['stage_reached'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// 랭킹 리스트 아이템
class RankingItem {
  final int rank;
  final String playerName;
  final int score;
  final int stageReached;
  final DateTime createdAt;
  
  RankingItem({
    required this.rank,
    required this.playerName,
    required this.score,
    required this.stageReached,
    required this.createdAt,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'playerName': playerName,
      'score': score,
      'stageReached': stageReached,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
