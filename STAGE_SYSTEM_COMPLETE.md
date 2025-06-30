# 🎮 끝말잇기 대전 - 단계별 적 시스템 구현 완료

## ✅ 구현된 기능

### 1. **3단계 적 시스템**
- **1단계: 초급 전사** - 응답률 7%씩 감소
- **2단계: 중급 마법사** - 응답률 4%씩 감소  
- **3단계: 전설의 드래곤** - 항상 100% 응답

### 2. **단계별 이미지 시스템**
- 각 단계별로 다른 적 캐릭터 이미지 표시
- idle, attack, death 상태별 이미지 지원

### 3. **단계 전환 애니메이션**
- 적이 죽으면 3초 후 다음 단계 적 등장
- 레벨 표시 팝업 (2초간 표시)

### 4. **게임 진행**
- 모든 단계에서 사용한 단어는 누적되어 재사용 불가
- 단계별 점수와 상태 표시

## 🚀 실행 방법

### 1. **데이터베이스 초기화** (중요!)
```bash
# backend 폴더에서 기존 DB 삭제
cd backend
del word_chain_game.db
```

### 2. **Backend 실행**
```bash
cd backend
dart pub get
dart run lib/main.dart
```

### 3. **Frontend 실행**
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

## 🖼️ 이미지 설정

### 1단계 적 (초급 전사)
- 현재 기본 이미지 사용 중
- `frontend/assets/images/characters/enemy/` 폴더의 이미지 사용

### 2단계 적 (중급 마법사) - 설정 필요
```
frontend/assets/images/characters/enemy/stage2/
├── idle.png    (대기 상태)
├── attack.png  (공격 상태)
└── death.png   (죽는 상태)
```

### 3단계 적 (전설의 드래곤) - 설정 필요
```
frontend/assets/images/characters/enemy/stage3/
├── idle.png    (대기 상태)
├── attack.png  (공격 상태)
└── death.png   (죽는 상태)
```

## 📁 변경된 파일들

### Backend
- `lib/services/ai_service.dart` - 단계별 AI 확률 시스템
- `lib/controllers/game_controller.dart` - 단계 전환 로직
- `lib/database/database.dart` - ai_turn_count 필드 추가

### Frontend
- `lib/providers/game_provider.dart` - 단계 관리
- `lib/widgets/character_image.dart` - 단계별 이미지 표시
- `lib/screens/home_screen.dart` - 단계 시스템 UI

## 🎯 게임 플레이 팁

1. **단어 선택 전략**
   - 초반엔 긴 단어로 점수 획득
   - 단계가 올라갈수록 AI가 답하기 어려운 글자로 끝나는 단어 선택

2. **단계별 전략**
   - 1단계: 14턴 이상 버티면 AI가 답 못할 확률 높음
   - 2단계: 25턴 이상 버티면 승리 가능
   - 3단계: 사용 가능한 단어를 모두 소진시켜야 승리

## 🐛 문제 해결

### "ai_turn_count" 오류 발생 시
1. Backend 종료 (Ctrl+C)
2. `backend/word_chain_game.db` 파일 삭제
3. Backend 재시작

### 이미지가 표시되지 않을 때
1. 이미지 파일명 확인 (idle.png, attack.png, death.png)
2. 폴더 경로 확인 (stage2/, stage3/)
3. Flutter 재시작 (R 키)
