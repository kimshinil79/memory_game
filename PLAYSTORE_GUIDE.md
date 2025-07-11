# 🚀 구글 플레이스토어 배포 가이드

## 📝 필수 준비사항

### 1. 앱 스토어 자료
- **앱 이름**: Brain Health Memory Game
- **짧은 설명**: 뇌 건강 개선을 위한 기억력 게임
- **전체 설명**: 
```
뇌 건강 개선을 위한 메모리 카드 매칭 게임입니다.

🧠 주요 기능:
- 다양한 난이도의 메모리 게임
- 뇌 건강 지수 추적
- 전 세계 사용자와의 랭킹 시스템
- 다국어 지원 (한국어, 영어, 일본어 등)
- 멀티플레이어 모드

🏆 혜택:
- 단기 기억력 향상
- 인지 기능 강화
- 반응 속도 개선
- 치매 예방 효과

🎮 게임 모드:
- 2x2부터 6x5까지 다양한 그리드 크기
- 시간 제한 모드
- 친구들과 함께하는 멀티플레이어

정기적인 뇌 운동으로 건강한 두뇌를 유지하세요!
```

### 2. 스크린샷 (필수)
다음 해상도로 준비:
- **핸드폰**: 1080 x 1920px (최소 2개, 최대 8개)
- **7인치 태블릿**: 1200 x 1920px (권장)
- **10인치 태블릿**: 1600 x 2560px (권장)

### 3. 그래픽 자료
- **고해상도 아이콘**: 512 x 512px (PNG)
- **피처 그래픽**: 1024 x 500px (필수)
- **TV 배너**: 1280 x 720px (선택)

### 4. 개인정보처리방침
웹사이트에 개인정보처리방침 페이지 생성 필요

## 🔑 키스토어 생성

1. 터미널에서 다음 명령어 실행:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. `android/key.properties` 파일의 비밀번호 업데이트:
```
storePassword=실제_키스토어_비밀번호
keyPassword=실제_키_비밀번호
keyAlias=upload
storeFile=../upload-keystore.jks
```

## 🏗️ 릴리즈 빌드

1. **AAB 빌드** (권장):
```bash
flutter build appbundle --release
```

2. **APK 빌드** (대안):
```bash
flutter build apk --release
```

빌드된 파일 위치:
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/flutter-apk/app-release.apk`

## 📱 구글 플레이 콘솔 설정

### 1. 개발자 계정 생성
- [Google Play Console](https://play.google.com/console) 접속
- 개발자 등록비 $25 결제

### 2. 앱 생성
1. "앱 만들기" 클릭
2. 앱 세부정보 입력:
   - 앱 이름: Brain Health Memory Game
   - 기본 언어: 한국어
   - 앱 또는 게임: 게임
   - 무료 또는 유료: 무료

### 3. 앱 설정
1. **앱 액세스 권한**
   - 모든 기능을 모든 사용자가 사용 가능

2. **광고**
   - 앱에 광고 포함: 예 (AdMob 사용)

3. **콘텐츠 등급**
   - 연령층: 만 3세 이상
   - 카테고리: 교육/퍼즐

4. **대상 고객 및 콘텐츠**
   - 주요 대상 연령층: 만 13세 이상

### 4. 프로덕션 트랙에 출시
1. "프로덕션" 탭 선택
2. "새 버전 만들기" 클릭
3. AAB 파일 업로드
4. 출시 노트 작성
5. 검토를 위해 출시

## ⚠️ 중요 확인사항

### AdMob 설정
현재 테스트 ID가 설정되어 있습니다. 실제 배포 전에 다음을 변경하세요:

1. [AdMob 콘솔](https://admob.google.com/)에서 앱 등록
2. 실제 App ID 발급받기
3. `AndroidManifest.xml`에서 ID 교체:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-실제번호~실제번호"/>
```

### Firebase 설정 확인
- `google-services.json` 파일이 올바른 패키지명으로 설정되어 있는지 확인
- Firebase 콘솔에서 새 패키지명(`com.brainhealth.memorygame`) 추가

### 개인정보처리방침
Firebase Auth, AdMob 사용으로 인해 개인정보처리방침이 필요합니다.
웹사이트에 다음 내용을 포함한 개인정보처리방침 페이지를 만드세요:
- 수집하는 정보 (이메일, 게임 데이터)
- 정보 사용 목적
- 제3자 공유 (Google Analytics, AdMob)
- 데이터 보관 기간
- 사용자 권리

## 🚀 출시 후 할 일

1. **앱 스토어 최적화 (ASO)**:
   - 키워드 최적화
   - 스크린샷 A/B 테스트
   - 설명 개선

2. **업데이트 주기**:
   - 버그 수정
   - 새 기능 추가
   - 사용자 피드백 반영

3. **모니터링**:
   - 크래시 리포트 확인
   - 사용자 리뷰 응답
   - 다운로드 및 수익 분석

## 📞 문제 해결

### 일반적인 문제들:
1. **앱 서명 문제**: 키스토어 파일 경로 확인
2. **빌드 실패**: `flutter clean` 후 재빌드
3. **업로드 실패**: AAB 파일 크기 확인 (100MB 이하)

### 도움이 되는 링크:
- [Flutter 공식 배포 가이드](https://docs.flutter.dev/deployment/android)
- [Google Play Console 도움말](https://support.google.com/googleplay/android-developer)
- [AdMob 정책](https://support.google.com/admob/answer/6128543)

---

**⚡ 팁**: 첫 배포는 검토에 시간이 걸릴 수 있습니다. 인내심을 갖고 기다리세요! 