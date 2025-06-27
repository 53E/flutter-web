# 끝말잇기 대전 - 백엔드 API 서버

Flutter Web 끝말잇기 게임을 위한 RESTful API 서버입니다.

## 🚀 시작하기

### 1. 의존성 설치
```bash
cd backend
dart pub get
```

### 2. 서버 실행
```bash
dart run lib/main.dart
```

### 3. 서버 확인
- 서버 주소: http://localhost:8080
- API 문서: http://localhost:8080/api/test
- 헬스체크: http://localhost:8080/api/health

## 📊 데이터베이스

자동으로 SQLite 데이터베이스가 생성되며, 다음과 같은 테이블이 포함됩니다:

- `words` - 단어 사전 (100개 이상의 기본 단어 포함)
- `game_sessions` - 게임 세션 정보
- `rankings` - 플레이어 랭킹

## 🎮 API 엔드포인트

### 게임 관련

#### 게임 시작
```http
POST /api/game/start
Content-Type: application/json

{}
```

**응답:**
```json
{
  "success": true,
  "gameId": "1234567890",
  "startWord": "사과",
  "stage": 1,
  "message": "게임이 시작되었습니다! 첫 단어는 \"사과\"입니다."
}
```

#### 단어 제출
```http
POST /api/game/submit-word
Content-Type: application/json

{
  "gameId": "1234567890",
  "word": "과일",
  "previousWord": "사과",
  "responseTime": 3000
}
```

**응답:**
```json
{
  "success": true,
  "gameOver": false,
  "victory": false,
  "message": "AI가 \"일기\"(으)로 응답했습니다",
  "playerWord": "과일",
  "aiWord": "일기",
  "score": 150,
  "stage": 1,
  "wordScore": 150
}
```

#### 게임 상태 조회
```http
GET /api/game/status/:sessionId
```

#### 게임 종료
```http
POST /api/game/end
Content-Type: application/json

{
  "gameId": "1234567890",
  "playerName": "플레이어1"
}
```

### 랭킹 관련

#### 랭킹 조회
```http
GET /api/ranking?limit=10
```

#### 점수 제출
```http
POST /api/ranking/submit
Content-Type: application/json

{
  "playerName": "플레이어1",
  "score": 2500,
  "stageReached": 3
}
```

#### 플레이어 기록 조회
```http
GET /api/ranking/player/:playerName
```

### 단어 관련

#### 단어 검증
```http
GET /api/word/validate/:word
```

#### 단어 검색
```http
GET /api/word/search/:startChar?limit=20
```

## 🤖 AI 시스템

8단계 AI 적이 구현되어 있습니다:

- **1단계**: 응답률 95%, 2초 이내 응답
- **2단계**: 응답률 90%, 1.8초 이내 응답
- **3단계**: 응답률 85%, 1.5초 이내 응답
- **4단계**: 응답률 80%, 1.2초 이내 응답
- **5단계**: 응답률 75%, 1초 이내 응답
- **6단계**: 응답률 70%, 0.8초 이내 응답
- **7단계**: 응답률 65%, 0.6초 이내 응답
- **8단계**: 응답률 60%, 0.4초 이내 응답

## 📈 점수 시스템

### 기본 점수 계산
- 기본 점수: 100점
- 단계 보너스: 단계 × 50점
- 단어 길이 보너스: (글자 수 - 2) × 10점 (3글자 이상)
- 속도 보너스: 최대 50점 (5초 이내)
- 연속 정답 보너스: (연속 수 - 1) × 25점

### 추가 보너스
- 단계 클리어 보너스: 단계 × 200점
- 게임 완주 보너스: 1000점

### 등급 시스템
- S+: 10,000점 이상
- S: 8,000점 이상
- A+: 6,000점 이상
- A: 4,000점 이상
- B+: 2,500점 이상
- B: 1,500점 이상
- C+: 800점 이상
- C: 400점 이상
- D: 400점 미만

## 🛠️ 개발 정보

### 기술 스택
- **프레임워크**: Dart + Alfred
- **데이터베이스**: SQLite (sqflite_common_ffi)
- **아키텍처**: RESTful API
- **구조**: MVC 패턴

### 프로젝트 구조
```
backend/
├── lib/
│   ├── controllers/     # API 컨트롤러
│   ├── models/          # 데이터 모델
│   ├── services/        # 비즈니스 로직
│   ├── database/        # 데이터베이스 관리
│   └── main.dart        # 서버 엔트리포인트
├── pubspec.yaml
└── README.md
```

## 🐛 트러블슈팅

### 일반적인 문제들

1. **포트 8080이 이미 사용 중**
   - 다른 서비스를 종료하거나 main.dart에서 포트 번호 변경

2. **데이터베이스 연결 오류**
   - 프로젝트 디렉토리 권한 확인
   - SQLite 파일 생성 권한 확인

3. **CORS 오류 (프론트엔드 연동 시)**
   - main.dart의 CORS 설정이 활성화되어 있는지 확인

### 로그 확인
서버 실행 시 다음과 같은 로그가 출력되어야 합니다:
```
✅ SQLite 데이터베이스 초기화 완료
✅ 모든 테이블 생성 완료
✅ 기본 단어 100개 삽입 완료
🚀 끝말잇기 대전 API 서버가 포트 8080에서 시작되었습니다!
```

## 📝 라이선스

이 프로젝트는 MIT 라이선스 하에 제공됩니다.
