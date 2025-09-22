#!/bin/bash

echo "🔍 Memory Game v1.1.1+7 빌드 확인"
echo "=================================="

# AAB 파일 확인
if [ -f "memory_game_v1.1.1+7.aab" ]; then
    echo "✅ Android AAB 파일 존재"
    echo "   파일명: memory_game_v1.1.1+7.aab"
    echo "   크기: $(ls -lh memory_game_v1.1.1+7.aab | awk '{print $5}')"
else
    echo "❌ Android AAB 파일 없음"
fi

# 버전 정보 확인
echo ""
echo "📱 앱 정보:"
echo "   패키지명: com.brainhealth.memorygame"
echo "   버전: 1.1.1+7"
echo "   빌드 번호: 7"

# 파일 목록
echo ""
echo "📁 배포 파일 목록:"
ls -la

echo ""
echo "🚀 Google Play Console 업로드 준비 완료!"
echo "   - AAB 파일을 Google Play Console에 업로드하세요"
echo "   - 릴리즈 노트를 확인하고 업데이트하세요"
