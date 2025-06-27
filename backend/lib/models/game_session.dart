// 게임 세션 모델
class GameSession {
  final String id;
  final String? playerName;
  final int currentStage;
  final int score;
  final String status; // 'active', 'ended'
  final DateTime createdAt;
  final DateTime? endedAt;
  
  GameSession({
    required this.id,
    this.playerName,
    required this.currentStage,
    required this.score,
    required this.status,
    required this.createdAt,
    this.endedAt,
  });
  
  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerName': playerName,
      'currentStage': currentStage,
      'score': score,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
    };
  }
  
  // JSON에서 생성
  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'],
      playerName: json['player_name'],
      currentStage: json['current_stage'],
      score: json['score'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
    );
  }
}
