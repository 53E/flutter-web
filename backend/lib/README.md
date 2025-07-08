# Backend 소스 코드 구조

Dart + Alfred 서버의 핵심 소스 코드입니다. MVC 패턴을 기반으로 구조화되어 있습니다.

## 폴더 구조

```
lib/
├── controllers/               # API 컨트롤러
├── database/                 # 데이터베이스 설정
├── models/                   # 데이터 모델
├── services/                 # 비즈니스 로직
└── main.dart                 # 서버 진입점
```

## 핵심 파일

### main.dart
- 서버 애플리케이션 진입점
- Alfred 서버 설정
- 라우트 등록
- 미들웨어 설정

## 폴더별 상세 설명

### controllers/
HTTP 요청을 처리하는 컨트롤러들입니다.

**주요 컨트롤러:**
- `GameController`: 게임 관련 API 엔드포인트
- `UserController`: 사용자 관련 API 엔드포인트
- `RankingController`: 랭킹 관련 API 엔드포인트
- `WordController`: 단어 검증 관련 API 엔드포인트

**컨트롤러 구조:**
```dart
class GameController {
  static Future<void> startGame(HttpRequest req, HttpResponse res) async {
    // 게임 시작 로직
  }
  
  static Future<void> submitWord(HttpRequest req, HttpResponse res) async {
    // 단어 제출 로직
  }
}
```

### database/
데이터베이스 연결과 스키마 관리를 담당합니다.

**주요 파일:**
- `database_helper.dart`: SQLite 연결 및 초기화
- `schema.dart`: 테이블 스키마 정의
- `migrations.dart`: 데이터베이스 마이그레이션

**데이터베이스 구조:**
```sql
-- users 테이블
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    best_score INTEGER DEFAULT 0,
    games_played INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- game_records 테이블
CREATE TABLE game_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    score INTEGER,
    stage_reached INTEGER,
    words_used TEXT,
    game_duration INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### models/
데이터 구조를 정의하는 모델 클래스들입니다.

**주요 모델:**
- `User`: 사용자 정보 모델
- `GameRecord`: 게임 기록 모델
- `GameState`: 게임 상태 모델
- `AIResponse`: AI 응답 모델

**모델 구조 예시:**
```dart
class User {
  final int? id;
  final String username;
  final int bestScore;
  final int gamesPlayed;
  final DateTime createdAt;

  User({
    this.id,
    required this.username,
    this.bestScore = 0,
    this.gamesPlayed = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'bestScore': bestScore,
    'gamesPlayed': gamesPlayed,
    'createdAt': createdAt.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    username: json['username'],
    bestScore: json['bestScore'] ?? 0,
    gamesPlayed: json['gamesPlayed'] ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
  );
}
```

### services/
비즈니스 로직과 데이터 처리를 담당합니다.

**주요 서비스:**
- `GameService`: 게임 로직 처리
- `WordService`: 단어 검증 및 관리
- `UserService`: 사용자 데이터 관리
- `RankingService`: 랭킹 계산 및 관리
- `AIService`: AI 응답 생성

**서비스 구조 예시:**
```dart
class GameService {
  static Future<String?> getAIWord(String lastChar, int stage) async {
    // AI 단어 생성 로직
    final words = await WordService.getWordsByFirstChar(lastChar);
    return _selectWordByDifficulty(words, stage);
  }

  static int calculateScore(String word, int stage, int combo) {
    // 점수 계산 로직
    return (word.length * stage * combo * 10);
  }
}
```

## 아키텍처 패턴

### MVC 패턴
Model-View-Controller 패턴을 따릅니다.

- **Model**: 데이터 구조 및 비즈니스 로직
- **View**: JSON 응답 (프론트엔드가 View 역할)
- **Controller**: HTTP 요청 처리

### Service Layer
비즈니스 로직을 별도 서비스 레이어로 분리합니다.

```dart
// Controller -> Service -> Database 흐름
class GameController {
  static Future<void> submitWord(HttpRequest req, HttpResponse res) async {
    final word = req.body['word'];
    final result = await GameService.validateAndProcess(word);
    res.json(result);
  }
}
```

### Repository Pattern
데이터베이스 접근을 추상화합니다.

```dart
abstract class UserRepository {
  Future<User> create(User user);
  Future<User?> findById(int id);
  Future<List<User>> findAll();
  Future<void> update(User user);
  Future<void> delete(int id);
}
```

## API 엔드포인트

### 게임 관련
```dart
// POST /api/game/start
app.post('/api/game/start', GameController.startGame);

// POST /api/game/submit-word
app.post('/api/game/submit-word', GameController.submitWord);

// GET /api/game/ai-word
app.get('/api/game/ai-word', GameController.getAIWord);

// POST /api/game/end
app.post('/api/game/end', GameController.endGame);
```

### 사용자 관련
```dart
// POST /api/user
app.post('/api/user', UserController.createUser);

// GET /api/user/:id
app.get('/api/user/:id', UserController.getUser);

// PUT /api/user/:id/score
app.put('/api/user/:id/score', UserController.updateScore);
```

### 랭킹 관련
```dart
// GET /api/ranking/top
app.get('/api/ranking/top', RankingController.getTopRanking);

// GET /api/ranking/user/:id
app.get('/api/ranking/user/:id', RankingController.getUserRanking);
```

## AI 게임 로직

### 단계별 AI 설정
```dart
enum GameStage {
  goblin(responseRate: 100.0, decreaseRate: 7.0),
  golem(responseRate: 100.0, decreaseRate: 4.0),
  dragon(responseRate: 100.0, decreaseRate: 0.0);

  const GameStage({
    required this.responseRate,
    required this.decreaseRate,
  });

  final double responseRate;
  final double decreaseRate;
}
```

### 단어 선택 알고리즘
```dart
class AIService {
  static Future<String?> selectWord(String lastChar, GameStage stage) async {
    final words = await WordService.getValidWords(lastChar);
    final currentRate = _calculateResponseRate(stage);
    
    if (Random().nextDouble() * 100 > currentRate) {
      return null; // AI가 응답하지 않음
    }
    
    return words.isNotEmpty ? words[Random().nextInt(words.length)] : null;
  }
}
```

## 에러 처리

### HTTP 에러 응답
```dart
class ErrorHandler {
  static void handleError(HttpResponse res, dynamic error) {
    if (error is ValidationException) {
      res.statusCode = 400;
      res.json({'error': 'Validation failed', 'message': error.message});
    } else if (error is NotFoundException) {
      res.statusCode = 404;
      res.json({'error': 'Not found', 'message': error.message});
    } else {
      res.statusCode = 500;
      res.json({'error': 'Internal server error'});
    }
  }
}
```

### 커스텀 예외
```dart
class GameException implements Exception {
  final String message;
  GameException(this.message);
}

class InvalidWordException extends GameException {
  InvalidWordException(String word) : super('Invalid word: $word');
}
```

## 성능 최적화

### 데이터베이스 최적화
- 적절한 인덱스 설정
- 쿼리 최적화
- 커넥션 풀링

### 메모리 관리
- 단어 데이터 캐싱
- 불필요한 객체 생성 최소화

### API 응답 최적화
- 적절한 HTTP 상태 코드
- 압축 적용
- 캐시 헤더 설정

## 개발 가이드라인

### 코딩 스타일
- Dart 공식 스타일 가이드 준수
- dartfmt를 사용한 코드 포맷팅
- dartanalyzer를 사용한 정적 분석

### 테스트
- 단위 테스트 작성
- 통합 테스트 구현
- API 엔드포인트 테스트

### 보안
- 입력값 검증
- SQL 인젝션 방지
- CORS 설정
- 적절한 HTTP 헤더 설정
