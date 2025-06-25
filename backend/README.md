# 끝말잇기 대전 - Backend Server

Dart + Alfred를 사용한 RESTful API 서버

## 구조

```
backend/
├── bin/
│   └── server.dart          # 서버 진입점
├── lib/
│   ├── controllers/         # API 컨트롤러
│   ├── models/             # 데이터 모델
│   ├── services/           # 비즈니스 로직
│   └── utils/              # 유틸리티
├── data/
│   └── words.db            # SQLite 데이터베이스
└── pubspec.yaml
```

## API 엔드포인트

- `POST /api/word/validate` - 단어 검증
- `POST /api/game/start` - 게임 시작
- `POST /api/ai/response` - AI 응답
- `POST /api/score/save` - 점수 저장
- `GET /api/ranking` - 랭킹 조회

## 실행 방법

```bash
# 패키지 설치
dart pub get

# 서버 실행
dart run bin/server.dart
```
