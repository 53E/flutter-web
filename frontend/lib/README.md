# Frontend 소스 코드 구조

Flutter Web 클라이언트의 핵심 소스 코드입니다. 각 폴더는 특정 역할과 책임을 가지고 있습니다.

## 폴더 구조

```
lib/
├── core/                      # 핵심 설정 및 상수
├── providers/                 # 상태 관리 Provider
├── routes/                    # 라우팅 설정
├── screens/                   # 화면 구성 요소
├── services/                  # API 서비스
├── utils/                     # 유틸리티 함수
├── widgets/                   # 재사용 가능한 위젯
├── app.dart                   # 앱 설정
└── main.dart                  # 앱 진입점
```

## 핵심 파일

### main.dart
- 애플리케이션 진입점
- Provider 설정
- 앱 초기화

### app.dart
- MaterialApp 설정
- 테마 및 라우팅 구성
- 전역 설정

## 폴더별 상세 설명

### core/
애플리케이션의 핵심 설정과 상수들을 관리합니다.

**주요 파일:**
- `constants.dart`: 앱 전반에서 사용되는 상수
- `colors.dart`: 컬러 팔레트 정의
- `app_config.dart`: 앱 설정 정보

### providers/
Provider 패턴을 사용한 상태 관리 클래스들입니다.

**주요 Provider:**
- `GameProvider`: 게임 상태 관리
- `AudioProvider`: 사운드 설정 관리
- `UserProvider`: 사용자 정보 관리
- `RankingProvider`: 랭킹 데이터 관리

### routes/
앱의 네비게이션과 라우팅을 관리합니다.

**주요 파일:**
- `app_routes.dart`: 라우트 정의
- `route_generator.dart`: 동적 라우트 생성

### screens/
각 화면의 UI 구성 요소들입니다.

**주요 화면:**
- `MainMenuScreen`: 메인 메뉴
- `GameScreen`: 게임 플레이 화면
- `RankingScreen`: 랭킹 화면
- `SettingsScreen`: 설정 화면

### services/
백엔드 API와의 통신을 담당합니다.

**주요 서비스:**
- `ApiService`: HTTP 통신 기본 클래스
- `GameService`: 게임 관련 API
- `UserService`: 사용자 관련 API
- `RankingService`: 랭킹 관련 API

### utils/
공통으로 사용되는 유틸리티 함수들입니다.

**주요 유틸리티:**
- `audio_utils.dart`: 오디오 관련 유틸리티
- `validation_utils.dart`: 입력값 검증
- `format_utils.dart`: 데이터 포맷팅

### widgets/
재사용 가능한 커스텀 위젯들입니다.

**주요 위젯:**
- `CharacterWidget`: 캐릭터 애니메이션
- `GameInputField`: 게임 입력 필드
- `SoundButton`: 사운드 토글 버튼
- `AnimatedBackground`: 배경 애니메이션

## 아키텍처 패턴

### Provider 패턴
상태 관리를 위해 Provider 패턴을 사용합니다.

```dart
// Provider 등록
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => GameProvider()),
    ChangeNotifierProvider(create: (_) => AudioProvider()),
    ChangeNotifierProvider(create: (_) => UserProvider()),
  ],
  child: MyApp(),
)
```

### Service Layer
API 통신과 비즈니스 로직을 분리합니다.

```dart
// Service 사용 예시
class GameProvider extends ChangeNotifier {
  final GameService _gameService = GameService();
  
  Future<void> submitWord(String word) async {
    final result = await _gameService.submitWord(word);
    // 상태 업데이트
  }
}
```

### Widget Composition
재사용 가능한 작은 위젯들로 구성합니다.

```dart
// 화면 구성 예시
class GameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CharacterWidget(),
          GameInputField(),
          ScoreDisplay(),
        ],
      ),
    );
  }
}
```

## 개발 가이드라인

### 명명 규칙
- **파일명**: snake_case (예: `game_screen.dart`)
- **클래스명**: PascalCase (예: `GameProvider`)
- **변수명**: camelCase (예: `currentScore`)
- **상수명**: UPPER_SNAKE_CASE (예: `API_BASE_URL`)

### 폴더 구조 규칙
- 각 폴더는 단일 책임 원칙을 따름
- 관련된 파일들을 같은 폴더에 그룹화
- 공통 기능은 utils나 core에 배치

### 상태 관리 규칙
- UI 상태는 StatefulWidget 사용
- 전역 상태는 Provider 사용
- 복잡한 상태는 별도 Provider로 분리

### 에러 처리
- try-catch 블록으로 예외 처리
- 사용자 친화적인 에러 메시지
- 로깅을 통한 디버깅 지원

## 성능 고려사항

### 위젯 최적화
- const 생성자 사용
- 불필요한 rebuild 방지
- ListView.builder 사용

### 메모리 관리
- 컨트롤러 적절한 dispose
- 스트림 구독 해제
- 이미지 캐싱 관리

### 네트워크 최적화
- API 호출 중복 방지
- 적절한 타임아웃 설정
- 오프라인 상태 처리
