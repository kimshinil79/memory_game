#!/bin/bash

# 시도할 비밀번호 목록
passwords=(
    "brainhealth"
    "brainhealth2024"
    "BrainHealth"
    "BRAINHEALTH"
    "memorygame"
    "MemoryGame"
    "MEMORYGAME"
    "memorygame2024"
    "upload"
    "Upload"
    "123456"
    "password"
    "Password"
    "shinilkim"
    "ShinilKim"
    "livinggod"
    "LivingGod"
)

KEYTOOL="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"
KEYSTORE="upload-keystore.jks"

echo "기존 keystore의 비밀번호를 찾는 중..."
echo ""

for pass in "${passwords[@]}"; do
    echo "시도 중: $pass"
    if echo "$pass" | "$KEYTOOL" -list -keystore "$KEYSTORE" 2>/dev/null | grep -q "키 저장소 유형"; then
        echo ""
        echo "=========================================="
        echo "✅ 비밀번호를 찾았습니다: $pass"
        echo "=========================================="
        echo ""
        echo "$pass" | "$KEYTOOL" -list -v -keystore "$KEYSTORE"
        exit 0
    fi
done

echo ""
echo "❌ 목록에서 비밀번호를 찾지 못했습니다."
echo "수동으로 비밀번호를 입력해보세요:"
echo "$KEYTOOL -list -v -keystore $KEYSTORE"

