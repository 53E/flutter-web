# Frontend - Flutter Web 클라이언트

끝말잇기 게임의 웹 클라이언트입니다. Flutter Web을 사용하여 반응형 웹 인터페이스를 제공합니다.

## 주요 기능

### 게임 플레이
- 실시간 끝말잇기 게임
- 단계별 AI 적과의 대전
- 동적 점수 계산 시스템
- 게임 상태 실시간 동기화

### 사용자 인터페이스
- 반응형 웹 디자인
- 캐릭터 애니메이션 시스템
- 타이핑 효과 및 말풍선
- 사운드 및 배경음악 제어

### 상태 관리
- Provider 패턴을 사용한 상태 관리
- 게임 상태, 사운드 설정, 사용자 정보 관리
- 실시간 데이터 동기화

## 프로젝트 구조

```
frontend/
├── assets/                    # 정적 리소스
│   ├── bgm/                  # 배경음악 파일
│   ├── data/                 # 게임 데이터
│   ├── fonts/                # 폰트 파일
│   ├── images/               # 이미지 리소스
│   └── sounds/               # 효과음 파일
├── lib/                      # 소스 코드
│   ├── core/                 # 핵심 설정 및 상수
│   ├── providers/            # 상태 관리 Provider들
│   ├── routes/               # 라우팅 설정
│   ├── screens/              # 화면 구성 요소
│   ├── services/             # API 서비스
│   ├── utils/                # 유틸리티 함수
│   ├── widgets/              # 재사용 가능한 위젯
│   ├── app.dart              # 앱 설정
│   └── main.dart             # 진입점
├── web/                      # 웹 배포용 파일
├── build/                    # 빌드 결과물
├── pubspec.yaml              # Flutter 의존성 관리
└── .vercelignore            # Vercel 배포 설정
```

## 기술 스택

### 핵심 프레임워크
- **Flutter Web**: 크로스 플랫폼 웹 개발
- **Dart**: 프로그래밍 언어

### 주요 패키지
- **provider**: 상태 관리
- **dio**: HTTP 클라이언트
- **audioplayers**: 오디오 재생
- **flutter_animate**: 애니메이션
- **go_router**: 라우팅

### 개발 도구
- **Chrome DevTools**: 디버깅
- **Flutter Inspector**: 위젯 트리 분석

## 개발 환경 설정

### 1. 필수 조건
```bash
# Flutter SDK 설치 확인
flutter doctor

# Web 지원 활성화
flutter config --enable-web
```

### 2. 의존성 설치
```bash
cd frontend
flutter pub get
```

### 3. 개발 서버 실행
```bash
# 개발 모드로 실행
flutter run -d chrome

# 핫 리로드 지원
# 코드 변경 시 'r' 키로 핫 리로드
```

## 빌드 및 배포

### 개발 빌드
```bash
flutter build web --debug
```

### 프로덕션 빌드
```bash
flutter build web --release
```

### Vercel 배포
- `.vercelignore` 파일로 불필요한 파일 제외
- `build/web` 폴더가 정적 사이트로 배포됨

## 주요 화면

### 메인 메뉴
- 게임 시작
- 랭킹 조회
- 설정

### 게임 화면
- 캐릭터 애니메이션
- 입력 필드
- 점수 표시
- 게임 진행 상황

### 랭킹 화면
- 상위 10명 표시
- 개인 최고 기록

## 성능 최적화

### 이미지 최적화
- WebP 포맷 사용
- 적절한 해상도 설정
- 이미지 프리로딩

### 코드 분할
- 화면별 동적 로딩
- 불필요한 의존성 제거

### 캐싱 전략
- 정적 리소스 캐싱
- API 응답 캐싱
