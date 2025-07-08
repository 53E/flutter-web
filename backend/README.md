# Backend - Dart + Alfred 서버

끝말잇기 게임의 백엔드 서버입니다. Dart 언어와 Alfred 프레임워크를 사용하여 RESTful API를 제공합니다.

## 주요 기능

### API 서비스
- 끝말잇기 게임 로직
- 사용자 점수 관리
- 랭킹 시스템
- 단어 검증 시스템

### 데이터 관리
- SQLite 데이터베이스
- 한국어 단어 데이터 (txt 파일)
- 사용자 기록 저장
- 게임 상태 관리

### AI 시스템
- 단계별 AI 응답률 조절
- 한국어 끝말잇기 알고리즘
- 동적 난이도 조절

## 프로젝트 구조

```
backend/
├── assets/
│   └── korean_words.txt         # 한국어 단어 데이터
├── lib/
│   ├── controllers/             # API 컨트롤러
│   ├── database/               # 데이터베이스 설정
│   ├── models/                 # 데이터 모델
│   ├── services/               # 비즈니스 로직
│   └── main.dart               # 서버 진입점
├── word_chain_game.db          # SQLite 데이터베이스
├── Dockerfile                  # Docker 컨테이너 설정
├── railway.yml                 # Railway 배포 설정
└── pubspec.yaml               # Dart 의존성 관리
```

## 기술 스택

### 핵심 프레임워크
- **Alfred**: Dart용 웹 프레임워크
- **Dart**: 서버사이드 프로그래밍 언어

### 주요 패키지
- **alfred**: HTTP 서버 프레임워크
- **sqlite3**: SQLite 데이터베이스
- **shelf**: HTTP 미들웨어
- **shelf_cors**: CORS 지원

### 데이터베이스
- **SQLite**: 경량 데이터베이스
- **로컬 파일 기반**: 배포 간소화

## API 엔드포인트

### 게임 관련
```
POST /api/game/start          # 게임 시작
POST /api/game/submit-word    # 단어 제출
GET  /api/game/ai-word        # AI 단어 응답
POST /api/game/end            # 게임 종료
```

### 사용자 관련
```
POST /api/user/create         # 사용자 생성
GET  /api/user/:id            # 사용자 정보 조회
PUT  /api/user/:id/score      # 점수 업데이트
```

### 랭킹 관련
```
GET  /api/ranking/top         # 상위 랭킹 조회
GET  /api/ranking/user/:id    # 개인 랭킹 조회
```

### 단어 관련
```
GET  /api/word/validate       # 단어 유효성 검증
GET  /api/word/search         # 단어 검색
```

## 개발 환경 설정

### 1. 필수 조건
```bash
# Dart SDK 설치 확인
dart --version
```

### 2. 의존성 설치
```bash
cd backend
dart pub get
```

### 3. 데이터베이스 초기화
```bash
# 데이터베이스 파일이 없으면 자동 생성됨
dart run lib/main.dart
```

### 4. 개발 서버 실행
```bash
# 기본 포트 8080에서 실행
dart run lib/main.dart

# 다른 포트로 실행
PORT=3000 dart run lib/main.dart
```

## 데이터베이스 스키마

### users 테이블
```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    best_score INTEGER DEFAULT 0,
    games_played INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### game_records 테이블
```sql
CREATE TABLE game_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    score INTEGER,
    stage_reached INTEGER,
    words_used TEXT,
    game_duration INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id)
);
```

## AI 게임 로직

### 단계별 AI 설정
```dart
// 1단계: 고블린
class GoblinAI {
  double responseRate = 100.0;
  double decreaseRate = 7.0;
}

// 2단계: 골렘
class GolemAI {
  double responseRate = 100.0;
  double decreaseRate = 4.0;
}

// 3단계: 드래곤
class DragonAI {
  double responseRate = 100.0; // 항상 100%
}
```

### 단어 선택 알고리즘
1. 마지막 글자로 시작하는 단어 검색
2. 응답률에 따른 확률적 응답
3. 게임 진행에 따른 난이도 조절

## 배포

### Railway 배포
```yaml
# railway.yml
build:
  buildCommand: dart pub get
  startCommand: dart run lib/main.dart
```

### Docker 배포
```dockerfile
FROM dart:stable
WORKDIR /app
COPY . .
RUN dart pub get
EXPOSE 8080
CMD ["dart", "run", "lib/main.dart"]
```

### 환경 변수
```bash
PORT=8080                    # 서버 포트
DATABASE_PATH=word_chain_game.db  # 데이터베이스 경로
CORS_ORIGIN=*               # CORS 허용 도메인
```

## 성능 최적화

### 데이터베이스 최적화
- 인덱스 설정
- 쿼리 최적화
- 커넥션 풀링

### 메모리 관리
- 단어 데이터 캐싱
- 가비지 컬렉션 최적화

### API 응답 최적화
- 응답 압축
- 캐시 헤더 설정
- 적절한 HTTP 상태 코드
