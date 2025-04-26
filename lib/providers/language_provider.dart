import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../translation/en.dart'; // 영어 번역 파일 가져오기
import '../translation/afghanistan.dart'; // 아프가니스탄 번역 파일 가져오기
import '../translation/afrikaans.dart'; // 아프리칸스어 번역 파일 가져오기
import '../translation/south_korea.dart'; // 대한민국 번역 파일 가져오기
import '../translation/uganda.dart'; // 우간다 번역 파일 가져오기
import '../translation/trinidad.dart'; // 트리니다드 토바고 번역 파일 가져오기
import '../translation/togo.dart'; // 토고 번역 파일 가져오기
import '../translation/tonga.dart'; // 통가 번역 파일 가져오기
import '../translation/spain.dart'; // 스페인 번역 파일 가져오기
import '../translation/sri_lanka.dart'; // 스리랑카 번역 파일 가져오기
import '../translation/sri_lanka_ta.dart'; // 스리랑카 (타밀어) 번역 파일 가져오기
import '../translation/sudan.dart'; // 수단 번역 파일 가져오기
import '../translation/syria.dart'; // 시리아 번역 파일 가져오기
import '../translation/tajikistan.dart'; // 타지키스탄 번역 파일 가져오기
import '../translation/tanzania.dart'; // 탄자니아 번역 파일 가져오기
import '../translation/thailand.dart'; // 태국 번역 파일 가져오기
import '../translation/turkey.dart'; // 터키 번역 파일 가져오기
import '../translation/ukraine.dart'; // 우크라이나 번역 파일 가져오기
import '../translation/united_arab_emirates.dart'; // 아랍에미리트 번역 파일 가져오기
import '../translation/united_kingdom.dart'; // 영국 번역 파일 가져오기
import '../translation/united_states.dart'; // 미국 번역 파일 가져오기
import '../translation/uruguay.dart'; // 우루과이 번역 파일 가져오기
import '../translation/uzbekistan.dart'; // 우즈베키스탄 번역 파일 가져오기
import '../translation/vanuatu.dart'; // 바누아투 번역 파일 가져오기
import '../translation/vietnam.dart'; // 베트남 번역 파일 가져오기
import '../translation/yemen.dart'; // 예멘 번역 파일 가져오기
import '../translation/zambia.dart'; // 잠비아 번역 파일 가져오기
import '../translation/zimbabwe.dart'; // 짐바브웨 번역 파일 가져오기
import '../translation/japan.dart'; // 일본 번역 파일 가져오기
import '../translation/israel.dart'; // 이스라엘 번역 파일 가져오기
import '../translation/italy.dart'; // 이탈리아 번역 파일 가져오기
import '../translation/jordan.dart'; // 요르단 번역 파일 가져오기
import '../translation/kazakhstan.dart'; // 카자흐스탄 번역 파일 가져오기
import '../translation/kenya.dart'; // 케냐 번역 파일 가져오기
import '../translation/kyrgyzstan.dart'; // 키르기스스탄 번역 파일 가져오기
import '../translation/laos.dart'; // 라오스 번역 파일 가져오기
import '../translation/latvia.dart'; // 라트비아 번역 파일 가져오기
import '../translation/lebanon.dart'; // 레바논 번역 파일 가져오기
import '../translation/lesotho.dart'; // 레소토 번역 파일 가져오기
import '../translation/libya.dart'; // 리비아 번역 파일 가져오기
import '../translation/liechtenstein.dart'; // 리히텐슈타인 번역 파일 가져오기
import '../translation/lithuania.dart'; // 리투아니아 번역 파일 가져오기
import '../translation/luxembourg.dart'; // 룩셈부르크 번역 파일 가져오기
import '../translation/malaysia.dart'; // 말레이시아 번역 파일 가져오기
import '../translation/maldives.dart'; // 몰디브 번역 파일 가져오기
import '../translation/malta.dart'; // 몰타 번역 파일 가져오기
import '../translation/mauritania.dart'; // 모리타니아 번역 파일 가져오기
import '../translation/mauritius.dart'; // 모리셔스 번역 파일 가져오기
import '../translation/mexico.dart'; // 멕시코 번역 파일 가져오기
import '../translation/monaco.dart'; // 모나코 번역 파일 가져오기
import '../translation/mongolia.dart'; // 몽골 번역 파일 가져오기
import '../translation/morocco.dart'; // 모로코 번역 파일 가져오기
import '../translation/mozambique.dart'; // 모잠비크 번역 파일 가져오기
import '../translation/myanmar.dart'; // 미얀마 번역 파일 가져오기
import '../translation/namibia.dart'; // 나미비아 번역 파일 가져오기
import '../translation/nepal.dart'; // 네팔 번역 파일 가져오기
import '../translation/netherlands.dart'; // 네덜란드 번역 파일 가져오기
import '../translation/new_zealand.dart'; // 뉴질랜드 번역 파일 가져오기
import '../translation/nicaragua.dart'; // 니카라과 번역 파일 가져오기
import '../translation/nigeria.dart'; // 나이지리아 번역 파일 가져오기
import '../translation/north_korea.dart'; // 북한 번역 파일 가져오기
import '../translation/north_macedonia.dart'; // 북마케도니아 번역 파일 가져오기
import '../translation/norway.dart'; // 노르웨이 번역 파일 가져오기
import '../translation/oman.dart'; // 오만 번역 파일 가져오기
import '../translation/pakistan.dart'; // 파키스탄 번역 파일 가져오기
import '../translation/panama.dart'; // 파나마 번역 파일 가져오기
import '../translation/papua_new_guinea.dart'; // 파푸아뉴기니 번역 파일 가져오기
import '../translation/paraguay.dart'; // 파라과이 번역 파일 가져오기
import '../translation/peru.dart'; // 페루 번역 파일 가져오기
import '../translation/philippines.dart'; // 필리핀 번역 파일 가져오기
import '../translation/poland.dart'; // 폴란드 번역 파일 가져오기
import '../translation/portugal.dart'; // 포르투갈 번역 파일 가져오기
import '../translation/puerto_rico.dart'; // 푸에르토리코 번역 파일 가져오기
import '../translation/qatar.dart'; // 카타르 번역 파일 가져오기
import '../translation/romania.dart'; // 루마니아 번역 파일 가져오기
import '../translation/russia.dart'; // 러시아 번역 파일 가져오기
import '../translation/rwanda.dart'; // 르완다 번역 파일 가져오기
import '../translation/saudi_arabia.dart'; // 사우디아라비아 번역 파일 가져오기
import '../translation/senegal.dart'; // 세네갈 번역 파일 가져오기
import '../translation/serbia.dart'; // 세르비아 번역 파일 가져오기
import '../translation/singapore.dart'; // 싱가포르 번역 파일 가져오기
import '../translation/singapore_zh.dart'; // 싱가포르 (중국어) 번역 파일 가져오기
import '../translation/singapore_ms.dart'; // 싱가포르 (말레이어) 번역 파일 가져오기
import '../translation/singapore_ta.dart'; // 싱가포르 (타밀어) 번역 파일 가져오기
import '../translation/slovakia.dart'; // 슬로바키아 번역 파일 가져오기
import '../translation/slovenia.dart'; // 슬로베니아 번역 파일 가져오기
import '../translation/somalia.dart'; // 소말리아 번역 파일 가져오기
import '../translation/south_africa.dart'; // 남아프리카공화국 번역 파일 가져오기
import '../translation/france.dart'; // 프랑스 번역 파일 가져오기

class LanguageProvider with ChangeNotifier {
  // 음성 언어 설정 (기존 currentLanguage) - 카드 뒤집을 때 음성 선택용
  String _currentLanguage = 'ko-KR'; // 기본값은 한국어로 변경

  // UI 언어 설정 (국적 기반)
  String _nationality = 'KR'; // 기본값 한국
  String _uiLanguage = 'ko-KR'; // UI 언어 코드

  bool _isInitialized = false;
  bool _isLoadingCountry = false;

  // Getters
  String get currentLanguage => _currentLanguage; // 음성 언어
  String get nationality => _nationality; // 국적 코드
  String get uiLanguage => _uiLanguage; // UI 언어 코드
  bool get isInitialized => _isInitialized;
  bool get isLoadingCountry => _isLoadingCountry;

  // Map country codes to language codes (모든 지원 언어에 대한 국가 코드 매핑)
  static final Map<String, String> countryToLanguageMap = {
    'KR': 'ko-KR', // 한국
    'JP': 'ja-JP', // 일본
    'CN': 'zh-CN', // 중국
    'PH': 'fil-PH', // 필리핀
    'IN': 'hi-IN', // 인도 (힌디어 기본)
    'BD': 'bn-BD', // 방글라데시
    'ID': 'id-ID', // 인도네시아
    'KH': 'km-KH', // 캄보디아
    'LA': 'lo-LA', // 라오스
    'MY': 'ms-MY', // 말레이시아
    'MM': 'my-MM', // 미얀마
    'NP': 'ne-NP', // 네팔
    'LK': 'si-LK', // 스리랑카
    'TH': 'th-TH', // 태국
    'VN': 'vi-VN', // 베트남

    'AD': 'ca-AD', // 안도라
    'BG': 'bg-BG', // 불가리아
    'HR': 'hr-HR', // 크로아티아
    'CZ': 'cs-CZ', // 체코
    'DK': 'da-DK', // 덴마크
    'NL': 'nl-NL', // 네덜란드
    'US': 'en-US', // 미국 (영어)
    'GB': 'en-US', // 영국 (영어 - 미국 영어로 기본 설정)
    'FI': 'fi-FI', // 핀란드
    'FR': 'fr-FR', // 프랑스
    'DE': 'de-DE', // 독일
    'GR': 'el-GR', // 그리스
    'HU': 'hu-HU', // 헝가리
    'IT': 'it-IT', // 이탈리아
    'LT': 'lt-LT', // 리투아니아
    'NO': 'no-NO', // 노르웨이
    'PL': 'pl-PL', // 폴란드
    'PT': 'pt-PT', // 포르투갈
    'RO': 'ro-RO', // 루마니아
    'RU': 'ru-RU', // 러시아
    'SK': 'sk-SK', // 슬로바키아
    'SI': 'sl-SI', // 슬로베니아
    'ES': 'es-ES', // 스페인
    'SE': 'sv-SE', // 스웨덴
    'UA': 'uk-UA', // 우크라이나

    'SA': 'ar-SA', // 사우디아라비아 (아랍어)
    'AE': 'ar-SA', // 아랍에미리트 (아랍어 - 사우디 아랍어로 기본 설정)
    'EG': 'ar-SA', // 이집트 (아랍어 - 사우디 아랍어로 기본 설정)
    'IL': 'he-IL', // 이스라엘
    'IR': 'fa-IR', // 이란
    'TR': 'tr-TR', // 터키
    'AF': 'fa-AF', // 아프가니스탄 (파슈토어)
    'AL': 'sq-AL', // 알바니아
    'DZ': 'ar-DZ', // 알제리 (아랍어)

    'ZA': 'af-ZA', // 남아프리카 (아프리칸스어 기본)
    'ET': 'am-ET', // 에티오피아
    'KE': 'sw-KE', // 케냐 (스와힐리어)
    'TZ': 'sw-KE', // 탄자니아 (스와힐리어 - 케냐 스와힐리어로 기본 설정)
    'UG': 'en-UG', // 우간다 (영어)
    'TT': 'en-TT', // 트리니다드 토바고 (영어)
    'TG': 'fr-TG', // 토고 (프랑스어)
    'TO': 'to-TO', // 통가 (통가어)
    'PY': 'es-PY', // 파라과이 (스페인어)
    'PE': 'es-PE', // 페루 (스페인어)
    'PH': 'fil-PH', // 필리핀 (필리핀어)
    'PL': 'pl-PL', // 폴란드 (폴란드어)
    'PR': 'es-PR', // 푸에르토리코 (스페인어)
    'QA': 'ar-QA', // 카타르 (아랍어)
    'RO': 'ro-RO', // 루마니아 (루마니아어)
    'RW': 'rw-RW', // 르완다 (르완다어)
    'SA': 'ar-SA', // 사우디아라비아 (아랍어)
    'SN': 'fr-SN', // 세네갈 (프랑스어)
    'RS': 'sr-RS', // 세르비아 (세르비아어)
    'SG': 'zh-SG', // 싱가포르 (중국어)
    'SK': 'sk-SK', // 슬로바키아 (슬로바키아어)
    'SI': 'sl-SI', // 슬로베니아 (슬로베니아어)
    'ZA': 'af-ZA', // 남아프리카 (아프리칸스어)
    'ES': 'es-ES', // 스페인 (스페인어)
    'LK': 'si-LK', // 스리랑카 (싱할라어)
    'SD': 'ar-SD', // 수단 (아랍어)
    'SE': 'sv-SE', // 스웨덴 (스웨덴어)
    'CH': 'de-CH', // 스위스 (독일어)
    'SY': 'ar-SY', // 시리아 (아랍어)
    'TW': 'zh-TW', // 대만 (중국어)
    'TJ': 'tg-TJ', // 타지키스탄 (타지크어)
    'TZ': 'sw-TZ', // 탄자니아 (스와힐리어)
    'TH': 'th-TH', // 태국 (태국어)
    'TL': 'pt-TL', // 동티모르 (포르투갈어)
    'TR': 'tr-TR', // 터키 (터키어)
    'TM': 'tk-TM', // 투르크메니스탄 (투르크멘어)
    'UA': 'uk-UA', // 우크라이나 (우크라이나어)
    'AE': 'ar-AE', // 아랍에미리트 (아랍어)
    'GB': 'en-GB', // 영국 (영어)
    'US': 'en-US', // 미국 (영어)
    'UY': 'es-UY', // 우루과이 (스페인어)
    'UZ': 'uz-UZ', // 우즈베키스탄 (우즈베크어)
    'VE': 'es-VE', // 베네수엘라 (스페인어)
    'VN': 'vi-VN', // 베트남 (베트남어)
    'YE': 'ar-YE', // 예멘 (아랍어)
    'ZM': 'en-ZM', // 잠비아 (영어)
    'ZW': 'en-ZW', // 짐바브웨 (영어)
  };

  LanguageProvider() {
    _loadLanguage();
    _loadNationality();
  }

  // 안전하게 리스너에게 알림
  void _safeNotifyListeners() {
    // 다음 마이크로태스크로 notifyListeners 호출을 지연
    Future.microtask(() {
      notifyListeners();
    });
  }

  // 음성 언어 로드
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString('selectedLanguage') ?? 'ko-KR';
      _isInitialized = true;
      _safeNotifyListeners();
    } catch (e) {
      print('Error loading language: $e');
      _isInitialized = true;
      _safeNotifyListeners();
    }
  }

  // 국적 로드
  Future<void> _loadNationality() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _nationality = prefs.getString('nationality') ?? 'KR';

      // 국적에 맞는 UI 언어 설정
      _updateUILanguage();

      _safeNotifyListeners();
    } catch (e) {
      print('Error loading nationality: $e');
    }
  }

  // 국적 코드에 맞는 UI 언어 업데이트
  void _updateUILanguage() {
    if (countryToLanguageMap.containsKey(_nationality)) {
      _uiLanguage = countryToLanguageMap[_nationality]!;
    } else {
      // 매핑이 없으면 기본값 사용
      _uiLanguage = 'en-US';
    }
  }

  // 음성 언어 설정 메서드 (기존 setLanguage)
  Future<void> setLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedLanguage', language);
      _currentLanguage = language;
      _safeNotifyListeners();
    } catch (e) {
      print('Error setting language: $e');
    }
  }

  // 새로운 메서드: 국적 설정
  Future<void> setNationality(String countryCode) async {
    try {
      if (countryCode == _nationality) return; // 변경 없으면 종료

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nationality', countryCode);
      _nationality = countryCode;

      // 국적 변경 시 UI 언어도 업데이트
      _updateUILanguage();

      // 즉시 UI 업데이트를 위해 notifyListeners 직접 호출
      notifyListeners();

      // 마이크로태스크를 이용한 _safeNotifyListeners도 함께 호출
      _safeNotifyListeners();
    } catch (e) {
      print('Error setting nationality: $e');
    }
  }

  // 사용자의 국적을 파이어베이스에서 가져와 설정하는 함수
  Future<void> getUserCountryFromFirebase() async {
    // 이미 로딩 중이면 중복 호출 방지
    if (_isLoadingCountry) return;

    // 로딩 상태 시작
    _isLoadingCountry = true;
    _safeNotifyListeners();

    try {
      // 현재 사용자 정보 가져오기
      User? currentUser = FirebaseAuth.instance.currentUser;

      // 로그인된 사용자가 없으면 로딩 종료하고 리턴
      if (currentUser == null) {
        _isLoadingCountry = false;
        _safeNotifyListeners();
        return;
      }

      // 시간 제한 설정 (5초)
      bool hasTimedOut = false;
      Future.delayed(Duration(seconds: 5)).then((_) {
        if (_isLoadingCountry) {
          hasTimedOut = true;
          _isLoadingCountry = false;
          _safeNotifyListeners();
        }
      });

      // 파이어스토어에서 사용자 정보 가져오기
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      // 타임아웃이 발생했으면 중단
      if (hasTimedOut) return;

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('country') && userData['country'] != null) {
          // 국가 코드 가져오기 (예: 'KR')
          String countryCode = userData['country'];

          // 국적 설정 (UI 언어에 영향)
          await setNationality(countryCode);

          // 필요한 경우 음성 언어도 설정 (옵션) - 음성 언어를 국적과 동기화하려면 주석 해제
          // if (countryToLanguageMap.containsKey(countryCode)) {
          //   await setLanguage(countryToLanguageMap[countryCode]!);
          // }
        }
      }
    } catch (e) {
      print('Error fetching user country: $e');
    } finally {
      // 항상 로딩 상태를 종료
      _isLoadingCountry = false;
      _safeNotifyListeners();
    }
  }

  // 현재 UI 언어에 따른 번역 텍스트 가져오기
  Map<String, String> getUITranslations() {
    return getTranslations(_uiLanguage);
  }

  // 특정 언어에 따른 번역 텍스트 가져오기 (기존 메서드)
  Map<String, String> getTranslations(String languageCode) {
    print('languageCode: $languageCode');
    // 영어 번역
    if (languageCode == 'en-US') {
      return enTranslations;
    }

    // 아프가니스탄 번역
    if (languageCode == 'fa-AF') {
      return afTranslations;
    }

    // 아프리칸스어 번역
    if (languageCode == 'af-ZA') {
      return afkTranslations;
    }

    // 한국어 번역
    if (languageCode == 'ko-KR') {
      return krTranslations;
    }

    // 우간다 번역 (영어)
    if (languageCode == 'en-UG') {
      return enUGTranslations;
    }

    // 트리니다드 토바고 번역 (영어)
    if (languageCode == 'en-TT') {
      return enTTTranslations;
    }

    // 토고 번역 (프랑스어)
    if (languageCode == 'fr-TG') {
      return frTGTranslations;
    }

    // 통가 번역 (통가어)
    if (languageCode == 'to-TO') {
      return toTOTranslations;
    }

    // 일본 번역 (일본어)
    if (languageCode == 'ja-JP') {
      return jaTranslations;
    }

    // 북한 번역 (한국어)
    if (languageCode == 'ko-KP') {
      return koKPTranslations;
    }

    // 네덜란드 번역 (네덜란드어)
    if (languageCode == 'nl-NL') {
      return nlTranslations;
    }

    // 스페인 번역 (스페인어)
    if (languageCode == 'es-ES') {
      return esESTranslations;
    }

    // 스리랑카 번역 (싱할라어)
    if (languageCode == 'si-LK') {
      return siLKTranslations;
    }

    // 스리랑카 타밀어 번역
    if (languageCode == 'ta-LK') {
      return taLKTranslations;
    }

    // 수단 번역 (아랍어)
    if (languageCode == 'ar-SD') {
      return arSDTranslations;
    }

    // 시리아 번역 (아랍어)
    if (languageCode == 'ar-SY') {
      return arSYTranslations;
    }

    // 타지키스탄 번역 (타지크어)
    if (languageCode == 'tg-TJ') {
      return tgTJTranslations;
    }

    // 탄자니아 번역 (스와힐리어)
    if (languageCode == 'sw-TZ') {
      return swTZTranslations;
    }

    // 태국 번역 (태국어)
    if (languageCode == 'th-TH') {
      return thTHTranslations;
    }

    // 터키 번역 (터키어)
    if (languageCode == 'tr-TR') {
      return trTRTranslations;
    }

    // 우크라이나 번역 (우크라이나어)
    if (languageCode == 'uk-UA') {
      return ukUATranslations;
    }

    // 아랍에미리트 번역 (아랍어)
    if (languageCode == 'ar-AE') {
      return arAETranslations;
    }

    // 영국 번역 (영어)
    if (languageCode == 'en-GB') {
      return enGBTranslations;
    }

    // 미국 번역 (영어)
    if (languageCode == 'en-US') {
      return enUSTranslations;
    }

    // 우루과이 번역 (스페인어)
    if (languageCode == 'es-UY') {
      return esUYTranslations;
    }

    // 우즈베키스탄 번역 (우즈베크어)
    if (languageCode == 'uz-UZ') {
      return uzUZTranslations;
    }

    // 바누아투 번역 (비슬라마어)
    if (languageCode == 'bi-VU') {
      return biVUTranslations;
    }

    // 베트남 번역 (베트남어)
    if (languageCode == 'vi-VN') {
      return viVNTranslations;
    }

    // 예멘 번역 (아랍어)
    if (languageCode == 'ar-YE') {
      return arYETranslations;
    }

    // 잠비아 번역 (영어)
    if (languageCode == 'en-ZM') {
      return enZMTranslations;
    }

    // 짐바브웨 번역 (영어)
    if (languageCode == 'en-ZW') {
      return enZWTranslations;
    }

    // 이스라엘 번역 (히브리어)
    if (languageCode == 'he-IL') {
      return heTranslations;
    }

    // 이탈리아 번역 (이탈리아어)
    if (languageCode == 'it-IT') {
      return itTranslations;
    }

    // 요르단 번역 (아랍어)
    if (languageCode == 'ar-JO') {
      return arJOTranslations;
    }

    // 카자흐스탄 번역 (카자흐어)
    if (languageCode == 'kk-KZ') {
      return kkKZTranslations;
    }

    // 케냐 번역 (스와힐리어)
    if (languageCode == 'sw-KE') {
      return swKETranslations;
    }

    // 키르기스스탄 번역 (키르기스어)
    if (languageCode == 'ky-KG') {
      return kyKGTranslations;
    }

    // 라오스 번역 (라오어)
    if (languageCode == 'lo-LA') {
      return loLATranslations;
    }

    // 라트비아 번역 (라트비아어)
    if (languageCode == 'lv-LV') {
      return lvLVTranslations;
    }

    // 레바논 번역 (아랍어)
    if (languageCode == 'ar-LB') {
      return arLBTranslations;
    }

    // 레소토 번역 (소토어)
    if (languageCode == 'st-LS') {
      return stLSTranslations;
    }

    // 리비아 번역 (아랍어)
    if (languageCode == 'ar-LY') {
      return arLYTranslations;
    }

    // 리히텐슈타인 번역 (독일어)
    if (languageCode == 'de-LI') {
      return deLITranslations;
    }

    // 리투아니아 번역 (리투아니아어)
    if (languageCode == 'lt-LT') {
      return ltTranslations;
    }

    // 룩셈부르크 번역 (룩셈부르크어)
    if (languageCode == 'lb-LU') {
      return deLUTranslations;
    }

    // 말레이시아 번역 (말레이어)
    if (languageCode == 'ms-MY') {
      return msTranslations;
    }

    // 몰디브 번역 (디베히어)
    if (languageCode == 'dv-MV') {
      return dvTranslations;
    }

    // 몰타 번역 (몰타어)
    if (languageCode == 'mt-MT') {
      return mtMTTranslations;
    }

    // 모리타니아 번역 (아랍어)
    if (languageCode == 'ar-MR') {
      return mrMRTranslations;
    }

    // 모리셔스 번역 (영어)
    if (languageCode == 'en-MU') {
      return muMUTranslations;
    }

    // 멕시코 번역 (스페인어)
    if (languageCode == 'es-MX') {
      return mxMEXTranslations;
    }

    // 모나코 번역 (프랑스어)
    if (languageCode == 'fr-MC') {
      return mcMCTTranslations;
    }

    // 몽골 번역 (몽골어)
    if (languageCode == 'mn-MN') {
      return mnMNGTranslations;
    }

    // 모로코 번역 (아랍어)
    if (languageCode == 'ar-MA') {
      return maTranslations;
    }

    // 모잠비크 번역 (포르투갈어)
    if (languageCode == 'pt-MZ') {
      return ptMOZTranslations;
    }

    // 미얀마 번역 (미얀마어)
    if (languageCode == 'my-MM') {
      return myTranslations;
    }

    // 나미비아 번역 (영어)
    if (languageCode == 'en-NA') {
      return naTranslations;
    }

    // 네팔 번역 (네팔어)
    if (languageCode == 'ne-NP') {
      return neTranslations;
    }

    // 뉴질랜드 번역 (영어)
    if (languageCode == 'en-NZ') {
      return enNZTranslations;
    }

    // 니카라과 번역 (스페인어)
    if (languageCode == 'es-NI') {
      return esNITranslations;
    }

    // 나이지리아 번역 (영어)
    if (languageCode == 'en-NG') {
      return enNGTranslations;
    }

    // 북마케도니아 번역 (마케도니아어)
    if (languageCode == 'mk-MK') {
      return mkMKTranslations;
    }

    // 노르웨이 번역 (노르웨이어)
    if (languageCode == 'nn-NO') {
      return nnNOTranslations;
    }

    // 오만 번역 (아랍어)
    if (languageCode == 'ar-OM') {
      return arOMTranslations;
    }

    // 파키스탄 번역 (우르두어)
    if (languageCode == 'ur-PK') {
      return urPKTranslations;
    }

    // 파나마 번역 (스페인어)
    if (languageCode == 'es-PA') {
      return esPATranslations;
    }

    // 파푸아뉴기니 번역 (영어)
    if (languageCode == 'en-PG') {
      return enPGTranslations;
    }

    // 파라과이 번역 (스페인어)
    if (languageCode == 'es-PY') {
      return esPYTranslations;
    }

    // 페루 번역 (스페인어)
    if (languageCode == 'es-PE') {
      return esPETranslations;
    }

    // 필리핀 번역 (필리핀어)
    if (languageCode == 'fil-PH') {
      return filPHTranslations;
    }

    // 폴란드 번역 (폴란드어)
    if (languageCode == 'pl-PL') {
      return plPLTranslations;
    }

    // 포르투갈 번역 (포르투갈어)
    if (languageCode == 'pt-PT') {
      return ptPTTranslations;
    }

    // 푸에르토리코 번역 (스페인어)
    if (languageCode == 'es-PR') {
      return esPRTranslations;
    }

    if (languageCode == 'fr-FR') {
      return frTranslations;
    }

    // 카타르 번역 (아랍어)
    if (languageCode == 'ar-QA') {
      return arQATranslations;
    }

    // 루마니아 번역 (루마니아어)
    if (languageCode == 'ro-RO') {
      return roROTranslations;
    }

    // 러시아 번역 (러시아어)
    if (languageCode == 'ru-RU') {
      return ruRUTranslations;
    }

    // 르완다 번역 (키냐르완다어)
    if (languageCode == 'rw-RW') {
      return rwRWTranslations;
    }

    // 사우디아라비아 번역 (아랍어)
    if (languageCode == 'ar-SA') {
      return arSATranslations;
    }

    // 세네갈 번역 (프랑스어)
    if (languageCode == 'fr-SN') {
      return frSNTranslations;
    }

    // 세르비아 번역 (세르비아어)
    if (languageCode == 'sr-RS') {
      return srRSTranslations;
    }

    // 싱가포르 번역 (영어)
    if (languageCode == 'en-SG') {
      return enSGTranslations;
    }

    // 싱가포르 번역 (중국어)
    if (languageCode == 'zh-SG') {
      return zhSGTranslations;
    }

    // 싱가포르 번역 (말레이어)
    if (languageCode == 'ms-SG') {
      return msSGTranslations;
    }

    // 싱가포르 번역 (타밀어)
    if (languageCode == 'ta-SG') {
      return taSGTranslations;
    }

    // 슬로바키아 번역 (슬로바키아어)
    if (languageCode == 'sk-SK') {
      return skSKTranslations;
    }

    // 슬로베니아 번역 (슬로베니아어)
    if (languageCode == 'sl-SI') {
      return slSITranslations;
    }

    // 소말리아 번역 (소말리어)
    if (languageCode == 'so-SO') {
      return soSOTranslations;
    }

    // 남아프리카공화국 번역 (아프리칸스어)
    if (languageCode == 'af-ZA') {
      return afkTranslations;
    }

    // 기본값은 영어 번역 반환
    return enTranslations;
  }

  String getTranslatedGroupName(String group) {
    final translations = getTranslations(_uiLanguage);
    switch (group) {
      case 'Asian Languages':
        return translations['asian_languages'] ?? 'Asian Languages';
      case 'European Languages':
        return translations['european_languages'] ?? 'European Languages';
      case 'Middle Eastern Languages':
        return translations['middle_eastern_languages'] ??
            'Middle Eastern Languages';
      case 'African Languages':
        return translations['african_languages'] ?? 'African Languages';
      default:
        return group;
    }
  }
}
