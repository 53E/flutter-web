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

## 📜 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 


