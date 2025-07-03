# 🎵 배경음악(BGM) 가이드 - 업데이트됨

이 폴더에 배경음악 파일들을 넣어주세요.

## 📁 **새로운 파일 위치** (중요!)

다음 경로에 BGM 파일들을 넣어주세요:

```
frontend/assets/bgm/          <- 더 간단한 경로
├── main_menu.mp3      (메인 메뉴 전용)
├── game_battle.mp3    (게임 중 모든 상황)
└── README.md          (이 파일)
```

## 🔧 **지금 해야 할 일**

### 1. 파일 복사
기존 파일들을 새 위치로 복사해주세요:

**복사할 파일들:**
```
FROM: frontend/assets/sounds/bgm/main_menu.mp3
TO:   frontend/assets/bgm/main_menu.mp3

FROM: frontend/assets/sounds/bgm/game_battle.mp3  
TO:   frontend/assets/bgm/game_battle.mp3
```

### 2. Flutter 재시작
```bash
cd frontend
flutter clean
flutter pub get
flutter run -d chrome
```

### 3. BGM 테스트
1. 웹이 열리면 우측 상단 🔊 버튼 클릭
2. 콘솔에서 `✅ BGM 재생 성공: main_menu` 메시지 확인

## 🎼 파일 형식 요구사항

- **형식**: MP3 (표준 인코딩)
- **품질**: 128kbps, 44.1kHz 권장
- **크기**: 5MB 이하
- **길이**: 2-5분 (루프 재생)

## 🔧 문제 해결

### 여전히 404 에러가 날 때:
1. 파일이 정확한 위치에 있는지 확인
2. 파일명이 정확한지 확인 (대소문자 구분)
3. 다른 MP3 파일로 테스트

### Format Error가 날 때:
1. MP3 파일을 다시 인코딩
2. 더 작은 파일로 테스트
3. WAV 파일로 변환 후 테스트

---

**🎵 새로운 경로로 BGM이 정상 작동할 것입니다!**
