# Railway 배포용 Dockerfile
FROM dart:stable

# SQLite 설치 (중요!)
RUN apt-get update && apt-get install -y \
    sqlite3 \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# 작업 디렉토리 설정
WORKDIR /app

# 종속성 파일 복사
COPY pubspec.yaml ./
COPY pubspec.lock ./

# 종속성 설치
RUN dart pub get

# 소스 코드 복사
COPY . .

# 빌드 실행
RUN dart pub get --offline

# 포트 설정 (Railway 환경 변수 사용)
EXPOSE 8080

# 서버 실행
CMD ["dart", "run", "lib/main.dart"]
