import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../translation/algeria.dart'; // 알제리 번역 파일 가져오기
import '../translation/en.dart'; // 영어 번역 파일 가져오기
import '../translation/afghanistan.dart'; // 아프가니스탄 번역 파일 가져오기
import '../translation/afrikaans.dart'; // 아프리칸스어 번역 파일 가져오기
import '../translation/arabic.dart'; // 아랍어 번역 파일 가져오기
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
import '../translation/nigeria.dart'; // 나이지리아 번역 파일 가져오기
import '../translation/north_korea.dart'; // 북한 번역 파일 가져오기
import '../translation/north_macedonia.dart'; // 북마케도니아 번역 파일 가져오기
import '../translation/norway.dart'; // 노르웨이 번역 파일 가져오기
import '../translation/oman.dart'; // 오만 번역 파일 가져오기
import '../translation/pakistan.dart'; // 파키스탄 번역 파일 가져오기
import '../translation/papua_new_guinea.dart'; // 파푸아뉴기니 번역 파일 가져오기
import '../translation/philippines.dart'; // 필리핀 번역 파일 가져오기
import '../translation/poland.dart'; // 폴란드 번역 파일 가져오기
import '../translation/portugal.dart'; // 포르투갈 번역 파일 가져오기
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
// 남아프리카공화국 번역 파일 가져오기
import '../translation/france.dart'; // 프랑스 번역 파일 가져오기
// 키프로스 번역 파일 가져오기
import '../translation/denmark.dart'; // 덴마크 번역 파일 가져오기
import '../translation/madagascar.dart'; // 마다가스카르 번역 파일 가져오기
// 말리 번역 파일 가져오기
// 팔라우 번역 파일 가져오기
import '../translation/iran.dart'; // 이란 번역 파일 가져오기
import '../translation/iceland.dart'; // 아이슬란드 번역 파일 가져오기
// 말라위 번역 파일 가져오기
// 쿠웨이트 번역 파일 가져오기
// 라이베리아 번역 파일 가져오기
// 마카오 번역 파일 가져오기
// 나우루 번역 파일 가져오기
// 몰도바 번역 파일 가져오기
// 미크로네시아 번역 파일 가져오기
// 마셜 제도 번역 파일 가져오기
// 자메이카 번역 파일 가져오기
// 시에라리온 번역 파일 가져오기
// 솔로몬 제도 번역 파일 가져오기
import '../translation/austria.dart'; // 오스트리아 번역 파일 가져오기
import '../translation/armenia.dart'; // 아르메니아 번역 파일 가져오기
import '../translation/azerbaijan.dart'; // 아제르바이잔 번역 파일 가져오기
import '../translation/bosnia.dart'; // 보스니아 헤르체고비나 번역 파일 가져오기
import '../translation/bhutan.dart'; // 부탄 번역 파일 가져오기
// 노르웨이 번역 파일 가져오기
import '../translation/estonia.dart'; // 에스토니아 번역 파일 가져오기
import '../translation/finland.dart'; // 핀란드 번역 파일 가져오기
import '../translation/greece.dart'; // 그리스 번역 파일 가져오기
import '../translation/croatia.dart'; // 크로아티아 번역 파일 가져오기
import '../translation/hungary.dart'; // 헝가리 번역 파일 가져오기
import '../translation/sweden.dart'; // 스웨덴 번역 파일 가져오기
import '../translation/georgia.dart'; // 조지아 번역 파일 가져오기
import '../translation/albania.dart'; // 알바니아 번역 파일 가져오기
import '../translation/germany.dart'; // 독일 번역 파일 가져오기
import '../translation/china.dart'; // 중국 번역 파일 가져오기
import '../translation/belarus.dart'; // 벨라루스 번역 파일 가져오기
import '../translation/botswana.dart'; // 보츠와나 번역 파일 가져오기
import '../translation/burundi.dart'; // 부룬디 번역 파일 가져오기
import '../translation/eritrea.dart'; // 에리트레아 번역 파일 가져오기
import '../translation/andorra.dart'; // 안도라 번역 파일 가져오기

class LanguageProvider with ChangeNotifier {
  // 음성 언어 설정 (기존 currentLanguage) - 카드 뒤집을 때 음성 선택용
  String _currentLanguage = 'ko-KR'; // 기본값은 한국어로 변경

  // UI 언어 설정 (국적 기반)
  String _nationality = 'KR'; // 기본값 한국
  String _uiLanguage = 'ko-KR'; // UI 언어 코드

  bool _isInitialized = false;
  bool _isLoadingCountry = false;

  // 폴더블폰 상태 관리
  bool _isFolded = false;
  Size _lastScreenSize = Size.zero;

  // Getters
  String get currentLanguage => _currentLanguage; // 음성 언어
  String get nationality => _nationality; // 국적 코드
  String get uiLanguage => _uiLanguage; // UI 언어 코드
  bool get isInitialized => _isInitialized;
  bool get isLoadingCountry => _isLoadingCountry;
  bool get isFolded => _isFolded; // 폴더블폰 상태

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

    // 새로 추가된 국가들
    'AO': 'pt-AO', // 앙골라 (포르투갈어)
    'AG': 'en-AG', // 앤티가 바부다 (영어)
    'AR': 'es-AR', // 아르헨티나 (스페인어)
    'AM': 'hy-AM', // 아르메니아 (아르메니아어)
    'AU': 'en-AU', // 오스트레일리아 (영어)
    'AT': 'de-AT', // 오스트리아 (독일어)
    'AZ': 'az-AZ', // 아제르바이잔 (아제르바이잔어)
    'BS': 'en-BS', // 바하마 (영어)
    'BH': 'ar-BH', // 바레인 (아랍어)
    'BB': 'en-BB', // 바베이도스 (영어)
    'BY': 'be-BY', // 벨라루스 (벨라루스어)
    'BE': 'nl-BE', // Belgium (Dutch)
    'BZ': 'en-BZ', // 벨리즈 (영어)
    'BJ': 'fr-BJ', // 베냉 (프랑스어)
    'BT': 'dz-BT', // 부탄 (종카어)
    'BO': 'es-BO', // 볼리비아 (스페인어)
    'BA': 'bs-BA', // 보스니아 헤르체고비나 (보스니아어)
    'BW': 'tn-BW', // 보츠와나 (영어)
    'BR': 'pt-BR', // 브라질 (포르투갈어)
    'BN': 'ms-BN', // 브루나이 (말레이어)
    'BF': 'fr-BF', // 부르키나파소 (프랑스어)
    'BI': 'rn-BI', // Burundi (Kirundi, French)
    'CM': 'fr-CM', // 카메룬 (프랑스어)
    'CA': 'en-CA', // 캐나다 (영어)
    'CV': 'pt-CV', // 카보베르데 (포르투갈어)
    'CF': 'fr-CF', // 중앙아프리카공화국 (프랑스어)
    'TD': 'fr-TD', // 차드 (프랑스어)
    'CL': 'es-CL', // 칠레 (스페인어)
    'CO': 'es-CO', // 콜롬비아 (스페인어)
    'KM': 'ar-KM', // 코모로 (아랍어)
    'CG': 'fr-CG', // 콩고 (프랑스어)
    'CR': 'es-CR', // 코스타리카 (스페인어)
    'CU': 'es-CU', // 쿠바 (스페인어)
    'DJ': 'ar-DJ', // 지부티 (아랍어)
    'DM': 'en-DM', // 도미니카 (영어)
    'DO': 'es-DO', // 도미니카 공화국 (스페인어)
    'EC': 'es-EC', // 에콰도르 (스페인어)
    'SV': 'es-SV', // 엘살바도르 (스페인어)
    'GQ': 'es-GQ', // 적도기니 (스페인어)
    'ER': 'ti-ER', // 에리트레아 (티그리냐어)
    'EE': 'et-EE', // 에스토니아 (에스토니아어)
    'FJ': 'en-FJ', // 피지 (영어)
    'GA': 'fr-GA', // 가봉 (프랑스어)
    'GM': 'en-GM', // 감비아 (영어)
    'GE': 'ka-GE', // 조지아 (조지아어)
    'GH': 'en-GH', // 가나 (영어)
    'GD': 'en-GD', // 그레나다 (영어)
    'GT': 'es-GT', // 과테말라 (스페인어)
    'GN': 'fr-GN', // 기니 (프랑스어)
    'GW': 'pt-GW', // 기니비사우 (포르투갈어)
    'GY': 'en-GY', // 가이아나 (영어)
    'HT': 'fr-HT', // 아이티 (프랑스어)
    'HN': 'es-HN', // 온두라스 (스페인어)
    'IE': 'en-IE', // 아일랜드 (영어)
    'IQ': 'ar-IQ', // 이라크 (아랍어)
    'KI': 'en-KI', // 키리바시 (영어)
    'KP': 'ko-KP', // 북한 (한국어)
    'KN': 'en-KN', // 세인트키츠 네비스 (영어)
    'LC': 'en-LC', // 세인트루시아 (영어)
    'VC': 'en-VC', // 세인트빈센트 그레나딘 (영어)
    'WS': 'en-WS', // 사모아 (영어)
    'SM': 'it-SM', // 산마리노 (이탈리아어)
    'ST': 'pt-ST', // 상투메 프린시페 (포르투갈어)
    'SC': 'en-SC', // 세이셸 (영어)
    'SS': 'en-SS', // 남수단 (영어)
    'SR': 'nl-SR', // 수리남 (네덜란드어)
    'SZ': 'en-SZ', // 에스와티니 (영어)
    'CH': 'de-CH', // 스위스 (독일어)
    'VA': 'it-VA', // 바티칸 시국 (이탈리아어)
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
      // 1. SharedPreferences에서 언어 설정 읽기 (우선순위 1)
      final prefs = await SharedPreferences.getInstance();
      String? savedLanguage = prefs.getString('selectedLanguage');
      print('LanguageProvider: 로컬 저장소에서 읽은 언어: $savedLanguage');

      // 2. Firebase에서 언어 설정 읽기 (우선순위 2, 인터넷 연결 시에만)
      String? firebaseLanguage;
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            firebaseLanguage =
                (userDoc.data() as Map<String, dynamic>)['language'];
            print('LanguageProvider: Firebase에서 읽은 언어: $firebaseLanguage');

            // Firebase에서 읽은 언어를 로컬에 저장 (다음 오프라인 사용을 위해)
            if (firebaseLanguage != null) {
              await prefs.setString('selectedLanguage', firebaseLanguage);
            }
          }
        }
      } catch (firebaseError) {
        print(
            'LanguageProvider: Firebase 연결 실패 (오프라인 상태일 수 있음): $firebaseError');
      }

      // 3. 기기 기본 언어 감지 (우선순위 3 - 최초 실행 시)
      String? deviceLanguage;
      try {
        final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
        final lang = deviceLocale.languageCode;
        final country = deviceLocale.countryCode?.toUpperCase();
        if (lang.isNotEmpty && country != null && country.isNotEmpty) {
          deviceLanguage = '$lang-$country';
        } else if (lang.isNotEmpty) {
          // 국가 코드가 없으면 언어 기준으로 합리적 기본값 설정
          deviceLanguage =
              lang == 'en' ? 'en-US' : (lang == 'ko' ? 'ko-KR' : 'en-US');
        }
        // 지원되지 않는 언어라면 영어로 폴백
        if (deviceLanguage == null ||
            !_isSupportedLanguageCode(deviceLanguage)) {
          deviceLanguage = 'en-US';
        }
        print('LanguageProvider: 기기 기본 언어 감지: $deviceLanguage');
      } catch (e) {
        print('LanguageProvider: 기기 언어 감지 실패: $e');
      }

      // 우선순위에 따라 언어 선택
      _currentLanguage = savedLanguage ?? // 로컬 저장소
          firebaseLanguage ?? // Firebase
          deviceLanguage ?? // 기기 언어
          'ko-KR'; // 기본값

      print('LanguageProvider: 최종 선택된 언어: $_currentLanguage');

      _isInitialized = true;
      _safeNotifyListeners();

      // 선택된 언어를 다시 로컬에 저장 (안전을 위해)
      await prefs.setString('selectedLanguage', _currentLanguage);
    } catch (e) {
      print('LanguageProvider: 언어 로드 실패: $e');
      // 오류 발생 시 기본 언어로 설정
      _currentLanguage = 'ko-KR';
      print('LanguageProvider: 오류로 인해 기본 언어 ko-KR로 설정했습니다.');

      // 오류 발생 시에도 기본 언어를 로컬에 저장
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selectedLanguage', 'ko-KR');
      } catch (storageError) {
        print('LanguageProvider: 기본 언어 저장 실패: $storageError');
      }

      _isInitialized = true;
      _safeNotifyListeners();
    }
  }

  // 국적 로드
  Future<void> _loadNationality() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNationality = prefs.getString('nationality');
      if (savedNationality != null) {
        _nationality = savedNationality;
      } else {
        // 저장된 국적이 없다면 기기 Locale 기반으로 기본값 설정
        try {
          final deviceLocale =
              WidgetsBinding.instance.platformDispatcher.locale;
          final deviceCountry = deviceLocale.countryCode?.toUpperCase();
          if (deviceCountry != null &&
              countryToLanguageMap.containsKey(deviceCountry)) {
            _nationality = deviceCountry;
            await prefs.setString('nationality', _nationality);
            print('LanguageProvider: 기기 기본 국적 설정: $_nationality');
          } else {
            // 지원되지 않는 국가는 영어 UI가 되도록 미국으로 기본 설정
            _nationality = 'US';
            await prefs.setString('nationality', _nationality);
          }
        } catch (e) {
          print('LanguageProvider: 기기 국적 감지 실패: $e');
          _nationality = 'US';
          await prefs.setString('nationality', _nationality);
        }
      }

      // 국적에 맞는 UI 언어 설정
      _updateUILanguage();

      _safeNotifyListeners();
    } catch (e) {
      print('Error loading nationality: $e');
    }
  }

  // 지원하는 언어 코드인지 판단 (일부 대표 코드 + 국가 매핑값 기준)
  bool _isSupportedLanguageCode(String code) {
    if (code == 'en-US' || code == 'ko-KR') return true;
    if (countryToLanguageMap.values.contains(code)) return true;
    const Set<String> additionalSupported = {
      'ja-JP',
      'zh-CN',
      'zh-TW',
      'fr-FR',
      'de-DE',
      'es-ES',
      'it-IT',
      'pt-PT',
      'pt-BR',
      'ru-RU',
      'ar-SA',
      'tr-TR',
      'vi-VN',
      'th-TH',
      'ms-MY',
      'pl-PL',
      'uk-UA',
      'sv-SE',
      'nl-NL',
      'he-IL',
      'hi-IN',
      'bn-BD',
      'id-ID',
      'lo-LA',
      'si-LK',
      'ta-LK',
      'en-GB'
    };
    return additionalSupported.contains(code);
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

      // 언어 변경 시 로그 출력
      print('LanguageProvider: 언어가 $language로 변경되었습니다.');

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
      Future.delayed(const Duration(seconds: 5)).then((_) {
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

    // 에티오피아 번역
    if (languageCode == 'am-ET') {
      return amTranslations;
    }

    // 아프리칸스어 번역
    if (languageCode == 'af-ZA') {
      return afkTranslations;
    }

    //알바니아 번역
    if (languageCode == 'sq-AL') {
      return sqTranslations;
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

    if (languageCode == 'ca-AD') {
      return caADTranslations;
    }

    // 토고 번역 (프랑스어)
    if (languageCode == 'fr-TG') {
      return frTGTranslations;
    }

    //중국 번역 (중국어)
    if (languageCode == 'zh-CN') {
      return zhCNTranslations;
    }

    if (languageCode == 'ar-DZ') {
      return arDZTranslations;
    }

    // 통가 번역 (통가어)
    if (languageCode == 'to-TO') {
      return toTOTranslations;
    }

    // 핀란드 번역 (핀란드어)
    if (languageCode == 'fi-FI') {
      return fiTranslations;
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

    //독일 번역 (독일어)
    if (languageCode == 'de-DE') {
      return deDETranslations;
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
      return esTranslations;
    }

    // 우즈베키스탄 번역 (우즈베크어)
    if (languageCode == 'uz-UZ') {
      return uzUZTranslations;
    }

    // 바누아투 번역 (비슬라마어)
    if (languageCode == 'bi-VU') {
      return biVUTranslations;
    }

    //스웨덴 번역 (스웨덴어)
    if (languageCode == 'sv-SE') {
      return svSETranslations;
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

    //크로아티아 번역 (크로아티아어)
    if (languageCode == 'hr-HR') {
      return hrTranslations;
    }

    //헝가리 번역 (헝가리어)
    if (languageCode == 'hu-HU') {
      return huTranslations;
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
      return esTranslations;
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
    if (languageCode == 'no-NO') {
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
      return esTranslations;
    }

    // 파푸아뉴기니 번역 (영어)
    if (languageCode == 'en-PG') {
      return enPGTranslations;
    }

    // 파라과이 번역 (스페인어)
    if (languageCode == 'es-PY') {
      return esTranslations;
    }

    // 페루 번역 (스페인어)
    if (languageCode == 'es-PE') {
      return esTranslations;
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
      return esTranslations;
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

    // 키프로스 번역 (그리스어)
    if (languageCode == 'el-CY') {
      return elGRTranslations; //
    }

    // 덴마크 번역 (덴마크어)
    if (languageCode == 'da-DK') {
      return daTranslations; //
    }

    // 마다가스카르 번역 (말라가시어)
    if (languageCode == 'mg-MG') {
      return mgTranslations; //
    }

    // 말리 번역 (프랑스어)
    if (languageCode == 'fr-ML') {
      return frTranslations; //
    }

    // 팔라우 번역 (영어)
    if (languageCode == 'en-PW') {
      return enTranslations; //
    }

    // 이란 번역 (페르시아어)
    if (languageCode == 'fa-IR') {
      return faTranslations; // 아직 구현되지 않음
    }

    // 아이슬란드 번역 (아이슬란드어)
    if (languageCode == 'is-IS') {
      return isISTranslations;
    }

    // 말라위 번역 (영어)
    if (languageCode == 'en-MW') {
      return enTranslations; //
    }

    // 쿠웨이트 번역 (아랍어)
    if (languageCode == 'ar-KW') {
      return arTranslations; //
    }

    // 라이베리아 번역 (영어)
    if (languageCode == 'en-LR') {
      return enTranslations; //
    }

    // 마카오 번역 (중국어)
    if (languageCode == 'zh-MO') {
      return zhCNTranslations; //
    }

    // 나우루 번역 (영어)
    if (languageCode == 'en-NR') {
      return enTranslations; //
    }

    // 몰도바 번역 (루마니아어)
    if (languageCode == 'ro-MD') {
      return roROTranslations; //
    }

    // 미크로네시아 번역 (영어)
    if (languageCode == 'en-FM') {
      return enTranslations; //
    }

    // 마셜 제도 번역 (영어)
    if (languageCode == 'en-MH') {
      return enTranslations; // 아직 구현되지 않음
    }

    // 자메이카 번역 (영어)
    if (languageCode == 'en-JM') {
      return enTranslations; // 영어 번역 재사용
    }

    // 시에라리온 번역 (영어)
    if (languageCode == 'en-SL') {
      return enTranslations; // 아직 구현되지 않음
    }

    // 솔로몬 제도 번역 (영어)
    if (languageCode == 'en-SB') {
      return enTranslations; // 영어 번역 재사용
    }

    // 앙골라 번역 (포르투갈어)
    if (languageCode == 'pt-AO') {
      return ptPTTranslations; // 포르투갈어 번역 재사용
    }

    // 앤티가 바부다 번역 (영어)
    if (languageCode == 'en-AG') {
      return enTranslations; // 영어 번역 재사용
    }

    // 아르헨티나 번역 (스페인어)
    if (languageCode == 'es-AR') {
      return esESTranslations; // 스페인어 번역 재사용
    }

    // 아르메니아 번역 (아르메니아어)
    if (languageCode == 'hy-AM') {
      return amTranslations;
    }

    // 오스트레일리아 번역 (영어)
    if (languageCode == 'en-AU') {
      return enTranslations; // 영어 번역 재사용
    }

    // 오스트리아 번역 (독일어)
    if (languageCode == 'de-AT') {
      return deATTranslations; // 독일어 번역 재사용
    }

    // 아제르바이잔 번역 (아제르바이잔어)
    if (languageCode == 'az-AZ') {
      return azTranslations;
    }

    // 바하마 번역 (영어)
    if (languageCode == 'en-BS') {
      return enTranslations; // 영어 번역 재사용
    }

    // 바레인 번역 (아랍어)
    if (languageCode == 'ar-BH') {
      return arSATranslations; // 아랍어 번역 재사용
    }

    // 바베이도스 번역 (영어)
    if (languageCode == 'en-BB') {
      return enTranslations; // 영어 번역 재사용
    }

    // 벨라루스 번역 (벨라루스어)
    if (languageCode == 'be-BY') {
      return beTranslations; //
    }

    // 벨기에 번역 (네덜란드어)
    if (languageCode == 'nl-BE') {
      return nlTranslations; // 네덜란드어 번역 재사용
    }

    // 벨리즈 번역 (영어)
    if (languageCode == 'en-BZ') {
      return enTranslations; // 영어 번역 재사용
    }

    // 베냉 번역 (프랑스어)
    if (languageCode == 'fr-BJ') {
      return frTranslations; // 프랑스어 번역 재사용
    }

    // 부탄 번역 (종카어)
    if (languageCode == 'dz-BT') {
      return dzTranslations;
    }

    // 볼리비아 번역 (스페인어)
    if (languageCode == 'es-BO') {
      return esESTranslations; // 스페인어 번역 재사용
    }

    // 보스니아 헤르체고비나 번역 (보스니아어)
    if (languageCode == 'bs-BA') {
      return bsBATranslations;
    }

    // 보츠와나 번역 (세츠와나어)
    if (languageCode == 'tn-BW') {
      return tnTranslations;
    }

    // 브라질 번역 (포르투갈어)
    if (languageCode == 'pt-BR') {
      return ptPTTranslations; // 포르투갈어 번역 재사용
    }

    // 브루나이 번역 (말레이어)
    if (languageCode == 'ms-BN') {
      return msTranslations; // 말레이어 번역 재사용
    }

    // 부르키나파소 번역 (프랑스어)
    if (languageCode == 'fr-BF') {
      return frTranslations; // 프랑스어 번역 재사용
    }

    // 부룬디 번역 (키룬디어)
    if (languageCode == 'rn-BI') {
      return rnTranslations; // 아직 구현되지 않음
    }

    // 카메룬 번역 (프랑스어)
    if (languageCode == 'fr-CM') {
      return frTranslations; // 프랑스어 번역 재사용
    }

    // 캐나다 번역 (영어)
    if (languageCode == 'en-CA') {
      return enTranslations; // 영어 번역 재사용
    }

    // 캐나다 번역 (프랑스어)
    if (languageCode == 'fr-CA') {
      return frTranslations; // 프랑스어 번역 재사용
    }

    // 카보베르데 번역 (포르투갈어)
    if (languageCode == 'pt-CV') {
      return ptPTTranslations; // 포르투갈어 번역 재사용
    }

    // 중앙아프리카공화국 번역 (프랑스어)
    if (languageCode == 'fr-CF') {
      return frTranslations; // 프랑스어 번역 재사용
    }

    // 차드 번역 (프랑스어)
    if (languageCode == 'fr-TD') {
      return frTranslations; // 프랑스어 번역 재사용
    }

    // 칠레 번역 (스페인어)
    if (languageCode == 'es-CL') {
      return esESTranslations; // 스페인어 번역 재사용
    }

    // 콜롬비아 번역 (스페인어)
    if (languageCode == 'es-CO') {
      return esESTranslations; // 스페인어 번역 재사용
    }

    // 코모로 번역 (아랍어)
    if (languageCode == 'ar-KM') {
      return arSATranslations; // 아랍어 번역 재사용
    }

    // 콩고 번역 (프랑스어)
    if (languageCode == 'fr-CG') {
      return frTranslations; // 프랑스어 번역 재사용
    }

    // 코스타리카 번역 (스페인어)
    if (languageCode == 'es-CR') {
      return esESTranslations; // 스페인어 번역 재사용
    }

    // 쿠바 번역 (스페인어)
    if (languageCode == 'es-CU') {
      return esESTranslations; // 스페인어 번역 재사용
    }

    // 지부티 번역 (아랍어)
    if (languageCode == 'ar-DJ') {
      return arSATranslations; // 아랍어 번역 재사용
    }

    // 도미니카 번역 (영어)
    if (languageCode == 'en-DM') {
      return enTranslations; // 도미니카 영어 번역
    }

    // 도미니카 공화국 번역 (스페인어)
    if (languageCode == 'es-DO') {
      return esESTranslations; // 도미니카 공화국 스페인어 번역
    }

    // 에콰도르 번역 (스페인어)
    if (languageCode == 'es-EC') {
      return esESTranslations; // 스페인어 번역 재사용
    }

    // 엘살바도르 번역 (스페인어)
    if (languageCode == 'es-SV') {
      return esESTranslations; // 스페인어 번역 재사용
    }

    // 적도기니 번역 (스페인어)
    if (languageCode == 'es-GQ') {
      return esESTranslations; // 스페인어 번역 재사용
    }

    // 에리트레아 번역 (티그리냐어)
    if (languageCode == 'ti-ER') {
      return tiERTranslations; // 아직 구현되지 않음
    }

    // 에스토니아 번역 (에스토니아어)
    if (languageCode == 'et-EE') {
      return etTranslations; // 아직 구현되지 않음
    }

    // 피지 번역 (영어)
    if (languageCode == 'en-FJ') {
      return enTranslations; // 영어 번역 재사용
    }

    // 가봉 번역 (프랑스어)
    if (languageCode == 'fr-GA') {
      return frTranslations; // 프랑스어 번역 재사용
    }

    // 감비아 번역 (영어)
    if (languageCode == 'en-GM') {
      return enTranslations; // 영어 번역 재사용
    }

    // 조지아 번역 (조지아어)
    if (languageCode == 'ka-GE') {
      return kaGETranslations;
    }

    //그리스 번역 (그리스어)
    if (languageCode == 'el-GR') {
      return elGRTranslations;
    }

    // 가나 번역 (영어)
    if (languageCode == 'en-GH') {
      return enTranslations; // 영어 번역 재사용
    }

    // 그레나다 번역 (영어)
    if (languageCode == 'en-GD') {
      return enTranslations; // 영어 번역 재사용
    }

    // 과테말라 번역 (스페인어)
    if (languageCode == 'es-GT') {
      return esESTranslations; // 스페인어 번역 재사용
    }

    // 기니 번역 (프랑스어)
    if (languageCode == 'fr-GN') {
      return frTranslations; // 프랑스어 번역 재사용
    }

    // 기니비사우 번역 (포르투갈어)
    if (languageCode == 'pt-GW') {
      return ptPTTranslations; // 포르투갈어 번역 재사용
    }

    // 가이아나 번역 (영어)
    if (languageCode == 'en-GY') {
      return enTranslations; // 영어 번역 재사용
    }

    // 아이티 번역 (프랑스어)
    if (languageCode == 'fr-HT') {
      return frTranslations; // 프랑스어 번역 재사용
    }

    // 온두라스 번역 (스페인어)
    if (languageCode == 'es-HN') {
      return esESTranslations; // 스페인어 번역 재사용
    }

    // 아일랜드 번역 (영어)
    if (languageCode == 'en-IE') {
      return enTranslations; // 영어 번역 재사용
    }

    // 이라크 번역 (아랍어)
    if (languageCode == 'ar-IQ') {
      return arSATranslations; // 아랍어 번역 재사용
    }

    // 키리바시 번역 (영어)
    if (languageCode == 'en-KI') {
      return enTranslations; // 영어 번역 재사용
    }

    // 세인트키츠 네비스 번역 (영어)
    if (languageCode == 'en-KN') {
      return enTranslations; // 영어 번역 재사용
    }

    // 세인트루시아 번역 (영어)
    if (languageCode == 'en-LC') {
      return enTranslations; // 영어 번역 재사용
    }

    // 세인트빈센트 그레나딘 번역 (영어)
    if (languageCode == 'en-VC') {
      return enTranslations; // 영어 번역 재사용
    }

    // 사모아 번역 (영어)
    if (languageCode == 'en-WS') {
      return enTranslations; // 영어 번역 재사용
    }

    // 산마리노 번역 (이탈리아어)
    if (languageCode == 'it-SM') {
      return itTranslations; // 이탈리아어 번역 재사용
    }

    // 상투메 프린시페 번역 (포르투갈어)
    if (languageCode == 'pt-ST') {
      return ptPTTranslations; // 포르투갈어 번역 재사용
    }

    // 세이셸 번역 (영어)
    if (languageCode == 'en-SC') {
      return enTranslations; // 영어 번역 재사용
    }

    // 남수단 번역 (영어)
    if (languageCode == 'en-SS') {
      return enTranslations; // 영어 번역 재사용
    }

    // 수리남 번역 (네덜란드어)
    if (languageCode == 'nl-SR') {
      return nlTranslations; // 네덜란드어 번역 재사용
    }

    // 에스와티니 번역 (영어)
    if (languageCode == 'en-SZ') {
      return enTranslations; // 영어 번역 재사용
    }

    // 바티칸 시국 번역 (이탈리아어)
    if (languageCode == 'it-VA') {
      return itTranslations; // 이탈리아어 번역 재사용
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

  // 폴더블폰 상태 업데이트
  void updateFoldableState(Size screenSize) {
    // 화면 크기가 변경되었는지 확인
    if (_lastScreenSize != screenSize) {
      _lastScreenSize = screenSize;

      // 폴더블 상태 감지 (화면 비율로 판단)
      final aspectRatio = screenSize.width / screenSize.height;
      // 상하로 매우 긴 화면이거나, 접힘으로 인해 유효 높이가 낮아 극단적으로 넓은 경우만 폴드로 간주
      final newFoldedState = aspectRatio < 0.65 || aspectRatio > 2.4;

      if (_isFolded != newFoldedState) {
        _isFolded = newFoldedState;
        notifyListeners();
      }
    }
  }
}
