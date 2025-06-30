# 테스트용 작은 이미지 생성 가이드

현재 이미지 파일이 3.2MB로 매우 큽니다. 
Flutter Web에서는 큰 이미지가 로딩 문제를 일으킬 수 있습니다.

## 해결 방법:

### 1. 이미지 크기 최적화 (권장)
- 이미지를 500KB 이하로 압축
- PNG 최적화 도구 사용: TinyPNG, Compressor.io
- 크기: 200x250px 정도로 리사이즈

### 2. 간단한 테스트
- 아무 작은 PNG 이미지(100KB 이하)를 
- idle.png로 이름 변경해서 테스트

### 3. 현재 수정사항
- pubspec.yaml에 assets 경로 추가됨
- flutter pub get 실행 필요
