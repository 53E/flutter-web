@echo off
echo 1단계 적 이미지 설정 중...

REM 현재 enemy 폴더의 이미지를 stage1 폴더로 복사
copy "idle.png" "stage1\idle.png"
copy "attack.png" "stage1\attack.png"
copy "death.png" "stage1\death.png"

echo.
echo ✅ 1단계 적 이미지 설정 완료!
echo.
echo 📌 2단계와 3단계 적 이미지 설정:
echo    1. stage2 폴더에 중급 마법사 이미지 추가
echo    2. stage3 폴더에 전설의 드래곤 이미지 추가
echo    3. 각 폴더에 idle.png, attack.png, death.png 필요
echo.
pause
