# 📱 에뮬레이터 성능 최적화 가이드

## 🎯 현재 적용된 최적화

### 코드 레벨 최적화
- ✅ Debug 빌드에서 다중 아키텍처 지원 (`arm64-v8a`, `x86_64`, `armeabi-v7a`)
- ✅ Debug 빌드에서 코드 압축 비활성화
- ✅ Release 빌드는 16KB 페이지 크기 지원 유지

## 🔧 Android Studio 에뮬레이터 설정

### 1. 새 에뮬레이터 생성 시 권장 설정

#### 하드웨어 프로필
- **기기**: Pixel 7 Pro 또는 Pixel 8
- **API 레벨**: 34 (Android 14) 또는 35 (Android 15)
- **ABI**: x86_64 (Intel Mac) 또는 arm64-v8a (Apple Silicon Mac)

#### 고급 설정
```
RAM: 4096 MB (최소) / 8192 MB (권장)
VM Heap: 256 MB
Internal Storage: 8192 MB
SD Card: 1024 MB
Graphics: Hardware - GLES 2.0
Multi-Core CPU: 4
```

### 2. 기존 에뮬레이터 최적화

#### AVD Manager에서 설정 변경:
1. **Actions** → **Edit**
2. **Show Advanced Settings** 클릭
3. 다음 설정 적용:

```
RAM: 4096 MB 이상
VM Heap: 256 MB
Internal Storage: 8192 MB
Graphics: Hardware - GLES 2.0
Boot option: Cold boot
Multi-Core CPU: 4 이상
```

### 3. 에뮬레이터 실행 시 최적화

#### 명령어로 실행 (더 빠름):
```bash
# Intel Mac
emulator -avd YOUR_AVD_NAME -gpu host -memory 4096 -cores 4

# Apple Silicon Mac  
emulator -avd YOUR_AVD_NAME -gpu host -memory 4096 -cores 4 -qemu -machine virt
```

#### Android Studio에서 실행 시:
1. **Tools** → **AVD Manager**
2. 에뮬레이터 **Actions** → **Cold Boot Now**
3. 첫 실행 후에는 **Quick Boot** 사용

## ⚡ 추가 성능 팁

### Mac 시스템 설정
1. **에너지 절약** → **고성능 모드** 활성화
2. **메모리 정리**: 다른 무거운 앱들 종료
3. **SSD 공간 확보**: 최소 20GB 여유 공간 유지

### Android Studio 설정
1. **File** → **Settings** → **Build** → **Compiler**
   - `Compile independent modules in parallel` ✅
2. **Memory Settings** 증가:
   - **Help** → **Change Memory Settings**
   - IDE Heap Size: 4096 MB
   - Build process heap size: 2048 MB

### Flutter 개발 시
```bash
# Hot reload 대신 hot restart 사용 (더 안정적)
flutter run --hot

# 디버그 모드에서 성능 프로파일링
flutter run --profile
```

## 🚨 문제 해결

### 에뮬레이터가 여전히 느린 경우:
1. **Cold Boot** 실행
2. **Wipe Data** 후 재시작
3. **Snapshot** 기능 비활성화
4. **Intel HAXM** (Intel Mac) 또는 **Hypervisor Framework** (Apple Silicon) 확인

### 메모리 부족 오류 시:
1. 에뮬레이터 RAM을 2048MB로 감소
2. 다른 앱들 종료
3. Mac 재시작 후 다시 시도

## 📊 성능 측정

### 앱 시작 시간 측정:
```bash
flutter run --trace-startup --profile
```

### 메모리 사용량 확인:
```bash
flutter analyze --watch
```

이 설정들을 적용하면 에뮬레이터 성능이 크게 개선될 것입니다! 🚀
