#!/bin/bash

# 🚀 끝말잇기 대전 배포 스크립트

echo "🎮 끝말잇기 대전 배포 시작!"
echo ""

# 1. Backend 배포 확인
echo "📡 Backend 배포 상태 확인..."
read -p "Railway에서 Backend가 배포되었습니까? (y/n): " backend_deployed

if [ "$backend_deployed" != "y" ]; then
    echo "❌ 먼저 Backend를 Railway에 배포해주세요!"
    echo "가이드: https://railway.app"
    exit 1
fi

# 2. API URL 입력
echo ""
echo "🔗 Railway에서 제공받은 API URL을 입력하세요:"
echo "예: https://your-app-name.railway.app"
read -p "API URL: " api_url

if [ -z "$api_url" ]; then
    echo "❌ API URL을 입력해주세요!"
    exit 1
fi

# 3. Frontend 빌드
echo ""
echo "🏗️ Frontend 빌드 중..."
cd frontend

# Flutter 웹 빌드 (API URL 포함)
flutter build web --dart-define=API_BASE_URL="$api_url/api"

if [ $? -eq 0 ]; then
    echo "✅ Frontend 빌드 완료!"
else
    echo "❌ Frontend 빌드 실패!"
    exit 1
fi

# 4. 배포 가이드 출력
echo ""
echo "🎉 빌드 완료! 이제 Vercel에 배포하세요:"
echo ""
echo "1. https://vercel.com 접속"
echo "2. 'New Project' 클릭"
echo "3. GitHub 저장소 선택"
echo "4. Root Directory: frontend"
echo "5. Build Command: flutter build web --dart-define=API_BASE_URL=$api_url/api"
echo "6. Output Directory: build/web"
echo "7. Deploy 클릭"
echo ""
echo "🔗 Backend API: $api_url"
echo "📱 Frontend 빌드: ./frontend/build/web"
echo ""
echo "배포 완료 후 게임을 테스트해보세요! 🎮"
