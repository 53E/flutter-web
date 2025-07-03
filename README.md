# 🎮 끝말잇기 대전 - AI 챌린지 게임

Flutter Web과 Dart 백엔드로 구현한 실시간 끝말잇기 게임입니다.

## ✨ 주요 기능

### 🎯 단계별 적 시스템
- **1단계: 고블린** - 응답률 7%씩 감소
- **2단계: 골렘** - 응답률 4%씩 감소  
- **3단계: 드래곤** - 항상 100% 응답

### 🎨 캐릭터 이미지 시스템
- 각 캐릭터별 idle, attack, death 상태 애니메이션
- 상황에 따른 동적 캐릭터 상태 변화
- 단계별 서로 다른 적 캐릭터

### 🎪 타이핑 애니메이션
- 단어 길이에 따른 동적 타이핑 속도
- 캐릭터 위 말풍선 효과
- 타이핑 사운드 지원

### 🏆 랭킹 시스템
- 실시간 점수 기록
- 플레이어별 최고 기록 저장
- 상위 10명 랭킹 표시

### 🎵 사운드 시스템
- 배경음악 (메인 메뉴 / 게임 중)
- 타이핑 사운드 효과
- 볼륨 조절 및 음소거 지원

## 🛠️ 기술 스택

### Frontend
- **Framework**: Flutter Web
- **언어**: Dart
- **상태관리**: Provider
- **네트워크**: Dio HTTP 클라이언트
- **애니메이션**: flutter_animate
- **오디오**: audioplayers

### Backend
- **Framework**: Dart + Alfred
- **데이터베이스**: SQLite
- **API**: RESTful API
- **단어 데이터**: 국립국어원 표준국어대사전 txt 파일

## 🚀 로컬 실행

### 1. 필수 조건
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- Chrome 브라우저

### 2. 백엔드 실행
```bash
cd backend
dart pub get
dart run lib/main.dart
```

### 3. 프론트엔드 실행
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

## 🌐 배포하기

### 🚀 빠른 배포 (권장)
Windows:
```bash
./deploy.bat
```

Mac/Linux:
```bash
./deploy.sh
```


## 📁 프로젝트 구조

```
flutter-web/
├── frontend/                 # Flutter Web 앱
│   ├── lib/
│   │   ├── screens/         # 화면 위젯
│   │   ├── widgets/         # 공통 위젯
│   │   ├── services/        # API 서비스
│   │   ├── providers/       # 상태 관리
│   │   └── utils/          # 유틸리티
│   └── assets/             # 리소스 (이미지, 사운드)
├── backend/                 # Dart 백엔드 서버
│   ├── lib/
│   │   ├── controllers/    # API 컨트롤러
│   │   ├── services/       # 비즈니스 로직
│   │   ├── models/         # 데이터 모델
│   │   └── database/       # 데이터베이스
│   └── assets/             # 단어 데이터 (txt)
└── docs/                   # 문서
```

## 🎮 게임 규칙

1. **기본 규칙**: 상대방이 제시한 단어의 마지막 글자로 시작하는 단어를 입력
2. **제한 시간**: 각 턴마다 10초 시간 제한
3. **단어 조건**: 
   - 2글자 이상 한글 단어
   - 이전에 사용되지 않은 단어
   - 국립국어원 표준국어대사전 기준
4. **점수 계산**: 단어 길이 × 10점
5. **승리 조건**: 
   - 상대방이 시간 초과
   - 상대방이 단어를 찾지 못함
   - 모든 단계(3단계) 클리어

## 🎯 게임 팁

### 1단계 (고블린)
- 14턴 이상 버티면 AI가 답 못할 확률 높음
- 긴 단어로 점수 획득에 집중

### 2단계 (골렘)  
- 25턴 이상 버티면 승리 가능
- 어려운 글자로 끝나는 단어 선택

### 3단계 (드래곤)
- 항상 완벽한 답변을 하므로 전략적 플레이 필요
- 사용 가능한 단어를 모두 소진시켜야 승리

## 🐛 문제 해결

### 서버 연결 오류
1. 백엔드 서버가 실행 중인지 확인
2. 포트 8080이 사용 중인지 확인
3. 브라우저 개발자 도구에서 네트워크 오류 확인

### 게임이 시작되지 않음
1. 브라우저 콘솔에서 오류 메시지 확인
2. 데이터베이스 파일(`word_chain_game.db`) 삭제 후 재시작
3. 캐시 삭제 후 새로고침

## 📈 향후 개발 계획

- [ ] 멀티플레이어 지원
- [ ] 더 많은 단계 추가
- [ ] 캐릭터 커스터마이징
- [ ] Achievement 시스템
- [ ] 모바일 앱 버전

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📜 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참고하세요.

## 👨‍💻 개발자

- **최진우** - 2022105754
- 프로젝트 개발 및 유지보수

