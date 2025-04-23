import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    // Asian Countries
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

    // European Countries
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

    // Middle Eastern Countries
    'SA': 'ar-SA', // 사우디아라비아 (아랍어)
    'AE': 'ar-SA', // 아랍에미리트 (아랍어 - 사우디 아랍어로 기본 설정)
    'EG': 'ar-SA', // 이집트 (아랍어 - 사우디 아랍어로 기본 설정)
    'IL': 'he-IL', // 이스라엘
    'IR': 'fa-IR', // 이란
    'TR': 'tr-TR', // 터키

    // African Countries
    'ZA': 'af-ZA', // 남아프리카 (아프리칸스어 기본)
    'ET': 'am-ET', // 에티오피아
    'KE': 'sw-KE', // 케냐 (스와힐리어)
    'TZ': 'sw-KE', // 탄자니아 (스와힐리어 - 케냐 스와힐리어로 기본 설정)
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
    // 기본 영어 번역
    Map<String, String> defaultTranslations = {
      'select_language': 'Select Language',
      'search_language': 'Search language',
      'all': 'All',
      'asian_languages': 'Asian Languages',
      'european_languages': 'European Languages',
      'middle_eastern_languages': 'Middle Eastern Languages',
      'african_languages': 'African Languages',
      'cancel': 'Cancel',
      // 앱 전체에서 사용하는 일반적인 텍스트 추가
      'ok': 'OK',
      'yes': 'Yes',
      'no': 'No',
      'save': 'Save',
      'app_title': 'Memory Game',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'back': 'Back',
      'next': 'Next',
      'continue': 'Continue',
      'settings': 'Settings',
      'profile': 'Profile',
      'home': 'Home',
      'game': 'Game',
      'ranking': 'Ranking',
      'brain_health': 'Brain Health',
      'player': 'Player',
      'players': 'Players',

      // Player Selection Dialog 텍스트
      'select_players': 'Select Players',
      'select_up_to_3_players': 'Select up to 3 other players',
      'you_will_be_included': 'You will always be included as a player',
      'confirm': 'Confirm',
      'retry': 'Retry',
      'no_other_users': 'No other users found',
      'failed_to_load_users': 'Failed to load users',
      'country': 'Country',
      'level': 'Level',
      'unknown': 'unknown',
      'unknown_player': 'Unknown Player',
      'multiplayer_verification': 'Multiplayer Verification',
      'create_pin': 'Create PIN',
      'enter_pin_for': 'Enter PIN for',
      'no_pin_for': 'No PIN for',
      'create_pin_for_multiplayer': 'Create a 2-digit PIN for multiplayer',
      'enter_2_digit_pin': 'Enter a 2-digit PIN',
      'pin_is_2_digits': 'PIN should be 2 digits',
      'wrong_pin': 'Wrong PIN',

      // Grid Selection Dialog 텍스트
      'select_grid_size': 'Select Grid Size',
      'choose_difficulty': 'Choose difficulty level',
      'multiplier': '×', // 곱셈 기호

      // Profile Edit Dialog 텍스트
      'edit_profile': 'Edit Profile',
      'nickname': 'Nickname',
      'enter_nickname': 'Enter nickname',
      'birthday': 'Birthday',
      'select_birthday': 'Select birthday',
      'gender': 'Gender',
      'male': 'Male',
      'female': 'Female',
      'select_country': 'Select country',
      'multi_game_pin': 'Multiplayer PIN',
      'enter_two_digit_pin': 'Enter two-digit PIN',
      'two_digit_pin_helper': 'This PIN is used for multiplayer game sessions',
      'change_password': 'Change Password',
      'current_password': 'Current Password',
      'enter_current_password': 'Enter current password',
      'new_password': 'New Password',
      'enter_new_password': 'Enter new password',
      'confirm_password': 'Confirm Password',
      'confirm_new_password': 'Confirm new password',
      'must_be_two_digit': 'Must be a two-digit number',
      'current_password_required': 'Current password is required',
      'password_length_error': 'Password must be at least 6 characters',
      'passwords_do_not_match': 'Passwords do not match',
      'incorrect_current_password': 'Incorrect current password',
      'error_changing_password': 'Error changing password',
      'error': 'Error',
      'sign_out': 'Sign Out',
      'random_shake': 'Random Shake!!',

      // Completion Dialog 텍스트
      'congratulations': 'Congratulations!',
      'winner': 'Winner: {name}!',
      'its_a_tie': 'It\'s a Tie!',
      'points_divided': 'Points are divided equally among tied players!',
      'time_seconds': 'Time: {seconds} seconds',
      'flips': 'Flips: {count}',
      'players_score_multiplier': '({players} Players: Score x{multiplier})',
      'points_divided_explanation': '(Points divided among tied players)',
      'health_score': 'Health Score: +{points}',
      'new_game': 'New Game',
      'times_up': 'Time\'s Up!',
      'retry': 'Retry',

      // Tutorial Overlay 텍스트
      'memory_game_guide': 'Memory Game Guide',
      'card_selection_title': 'Card Selection',
      'card_selection_desc': 'Tap cards to flip and find matching pairs.',
      'time_limit_title': 'Time Limit',
      'time_limit_desc':
          'Match all pairs within time limit. Faster matching earns higher score.',
      'add_time_title': 'Add Time',
      'add_time_desc': 'Tap "+30s" to add time (costs Brain Health points).',
      'multiplayer_title': 'Multiplayer',
      'multiplayer_desc': 'Change player count (1-4) to play with friends.',
      'dont_show_again': 'Don\'t show again',
      'start_game': 'Start Game',

      // Brain Health Dashboard Tutorial 텍스트
      'brain_health_dashboard': 'Brain Health Dashboard',
      'brain_health_index_title': 'Brain Health Index',
      'brain_health_index_desc':
          'Check your brain health score improved through memory games. Higher levels increase dementia prevention effect.',
      'activity_graph_title': 'Activity Graph',
      'activity_graph_desc':
          'View changes in your brain health score over time through the graph.',
      'ranking_system_title': 'Ranking System',
      'ranking_system_desc':
          'Compare your brain health score with other users and check your ranking.',
      'game_statistics_title': 'Game Statistics',
      'game_statistics_desc':
          'Check various statistics such as games played, matches found, and best records.',
      'got_it': 'Got it!',

      // Brain Health Dashboard 추가 텍스트
      'play_memory_games_description':
          'Play memory games to improve your brain health!',
      'calculating_brain_health_index':
          'Calculating your Brain Health Index...',
      'error_calculating_index': 'Error calculating Brain Health Index',
      'age': 'Age',
      'update': 'Update',
      'points_to_next_level':
          'You need {points} points to reach the next level',
      'maximum_level_reached': 'Maximum level reached',
      'index_components': 'Index Components',
      'age_factor': 'Age Factor',
      'recent_activity': 'Recent Activity',
      'game_performance': 'Game Performance',
      'persistence_bonus': 'Persistence Bonus',
      'inactivity_penalty': 'Inactivity Penalty',
      'inactivity_warning':
          'You haven\'t played for {days} day(s). Your score is decreasing each day!',
      'loading_data': 'Loading data...',
      'refresh_data': 'Refresh Data',

      // Login Prompt 텍스트
      'start_tracking_brain_health': 'Start Tracking Your Brain Health',
      'login_prompt_desc':
          'Sign in to record your brain health score and track your progress. Play memory games to improve your cognitive abilities.',
      'sign_in': 'Sign In',
      'create_account': 'Create Account',

      // User Rankings 텍스트
      'user_rankings': 'User Rankings',
      'rank': 'Rank',
      'user': 'User',
      'score': 'Score',
      'failed_to_load_rankings': 'Failed to load rankings',
      'no_ranking_data': 'No ranking data available',

      // Date format 텍스트
      'today': 'Today',
      'yesterday': 'Yesterday',

      // Activity Chart 텍스트
      'brain_health_progress': 'Brain Health Progress',
      'welcome_to_brain_health': 'Welcome to Brain Health!',
      'start_playing_memory_games':
          'Start playing memory games\nto track your progress',
      'score': 'Score',
      'date_range': 'Date Range',
      'last_7_days': 'Last 7 Days',
      'last_30_days': 'Last 30 Days',
      'all_time': 'All Time',
    };

    // 한국어 번역
    if (languageCode == 'ko-KR') {
      return {
        'select_language': '언어 선택',
        'search_language': '언어 검색',
        'all': '전체',
        'asian_languages': '아시아 언어',
        'european_languages': '유럽 언어',
        'middle_eastern_languages': '중동 언어',
        'african_languages': '아프리카 언어',
        'cancel': '취소',
        // 앱 전체에서 사용하는 일반적인 텍스트 추가
        'ok': '확인',
        'yes': '예',
        'no': '아니오',
        'save': '저장',
        'app_title': '메모리 게임',
        'delete': '삭제',
        'edit': '편집',
        'close': '닫기',
        'back': '뒤로',
        'next': '다음',
        'continue': '계속',
        'settings': '설정',
        'profile': '프로필',
        'home': '홈',
        'game': '게임',
        'ranking': '랭킹',
        'brain_health': '두뇌 건강',
        'player': '플레이어',
        'players': '플레이어',

        // Player Selection Dialog 텍스트
        'select_players': '플레이어 선택',
        'select_up_to_3_players': '최대 3명의 다른 플레이어를 선택하세요',
        'you_will_be_included': '당신은 항상 플레이어로 포함됩니다',
        'confirm': '확인',
        'retry': '다시 시도',
        'no_other_users': '다른 사용자를 찾을 수 없습니다',
        'failed_to_load_users': '사용자 목록을 불러오지 못했습니다',
        'country': '국가',
        'level': '레벨',
        'unknown': '알 수 없음',
        'unknown_player': '알 수 없는 플레이어',
        'multiplayer_verification': '멀티플레이어 인증',
        'create_pin': 'PIN 번호 생성',
        'enter_pin_for': '님의 PIN 번호를 입력하세요',
        'no_pin_for': '님에게 PIN 번호가 없습니다',
        'create_pin_for_multiplayer': '멀티플레이어를 위한 2자리 PIN 번호를 생성하세요',
        'enter_2_digit_pin': '2자리 숫자를 입력하세요',
        'pin_is_2_digits': 'PIN은 숫자 2자리로 설정해주세요',
        'wrong_pin': '잘못된 PIN 번호입니다',

        // Grid Selection Dialog 텍스트
        'select_grid_size': '그리드 크기 선택',
        'choose_difficulty': '난이도를 선택하세요',
        'multiplier': '×', // 곱셈 기호

        // Profile Edit Dialog 텍스트
        'edit_profile': '프로필 수정',
        'nickname': '닉네임',
        'enter_nickname': '닉네임을 입력하세요',
        'birthday': '생년월일',
        'select_birthday': '생년월일을 선택하세요',
        'gender': '성별',
        'male': '남성',
        'female': '여성',
        'select_country': '국가를 선택하세요',
        'multi_game_pin': '멀티플레이어 PIN',
        'enter_two_digit_pin': '두 자리 PIN을 입력하세요',
        'two_digit_pin_helper': '이 PIN은 멀티플레이어 게임 세션에 사용됩니다',
        'change_password': '비밀번호 변경',
        'current_password': '현재 비밀번호',
        'enter_current_password': '현재 비밀번호를 입력하세요',
        'new_password': '새 비밀번호',
        'enter_new_password': '새 비밀번호를 입력하세요',
        'confirm_password': '비밀번호 확인',
        'confirm_new_password': '새 비밀번호 확인',
        'must_be_two_digit': '두 자리 숫자여야 합니다',
        'current_password_required': '현재 비밀번호가 필요합니다',
        'password_length_error': '비밀번호는 최소 6자 이상이어야 합니다',
        'passwords_do_not_match': '비밀번호가 일치하지 않습니다',
        'incorrect_current_password': '현재 비밀번호가 올바르지 않습니다',
        'error_changing_password': '비밀번호 변경 오류',
        'error': '오류',
        'sign_out': '로그아웃',
        'random_shake': '카드 흔들어!!',

        // Completion Dialog 텍스트
        'congratulations': '축하합니다!',
        'winner': '승자: {name}!',
        'its_a_tie': '무승부입니다!',
        'points_divided': '점수가 동점자들에게 균등하게 나눠집니다!',
        'time_seconds': '시간: {seconds}초',
        'flips': '뒤집기: {count}',
        'players_score_multiplier': '({players}인 플레이: 점수 x{multiplier})',
        'points_divided_explanation': '(점수가 동점자들에게 나눠집니다)',
        'health_score': '두뇌 건강 점수: +{points}',
        'new_game': '새 게임',
        'times_up': '시간 종료!',
        'retry': '다시 시도',

        // Tutorial Overlay 텍스트
        'memory_game_guide': '메모리 게임 가이드',
        'card_selection_title': '카드 선택',
        'card_selection_desc': '카드를 탭하여 뒤집고 짝을 맞추세요.',
        'time_limit_title': '시간 제한',
        'time_limit_desc': '제한 시간 내에 모든 짝을 맞추세요. 빠르게 짝을 맞출수록 더 높은 점수를 얻습니다.',
        'add_time_title': '시간 추가',
        'add_time_desc': '"+30초"를 탭하여 시간을 추가하세요 (두뇌 건강 점수 소모).',
        'multiplayer_title': '멀티플레이어',
        'multiplayer_desc': '플레이어 수(1-4)를 변경하여 친구들과 함께 플레이하세요.',
        'dont_show_again': '다시 보지 않기',
        'start_game': '게임 시작',

        // Brain Health Dashboard Tutorial 텍스트
        'brain_health_dashboard': '두뇌 건강 대시보드',
        'brain_health_index_title': '두뇌 건강 지수',
        'brain_health_index_desc':
            '메모리 게임을 통해 향상된 두뇌 건강 점수를 확인하세요. 높은 레벨은 치매 예방 효과를 증가시킵니다.',
        'activity_graph_title': '활동 그래프',
        'activity_graph_desc': '그래프를 통해 시간에 따른 두뇌 건강 점수 변화를 볼 수 있습니다.',
        'ranking_system_title': '랭킹 시스템',
        'ranking_system_desc': '다른 사용자와 두뇌 건강 점수를 비교하고 랭킹을 확인하세요.',
        'game_statistics_title': '게임 통계',
        'game_statistics_desc': '플레이한 게임 수, 찾은 매치 수, 최고 기록 등의 다양한 통계를 확인하세요.',
        'got_it': '알겠습니다!',

        // Brain Health Dashboard 추가 텍스트
        'play_memory_games_description': '메모리 게임을 통해 두뇌 건강을 향상시키세요!',
        'calculating_brain_health_index': '두뇌 건강 지수를 계산 중입니다...',
        'error_calculating_index': '두뇌 건강 지수 계산 중 오류가 발생했습니다',
        'age': '나이',
        'update': '업데이트',
        'points_to_next_level': '다음 레벨까지 {points}점이 필요합니다',
        'maximum_level_reached': '최대 레벨에 도달했습니다',
        'index_components': '지수 구성 요소',
        'age_factor': '나이 요소',
        'recent_activity': '최근 활동',
        'game_performance': '게임 성능',
        'persistence_bonus': '지속성 보너스',
        'inactivity_penalty': '비활동 패널티',
        'inactivity_warning': '{days}일 동안 플레이하지 않았습니다. 점수가 매일 감소하고 있습니다!',
        'loading_data': '데이터 로딩 중...',
        'refresh_data': '데이터 새로고침',

        // Login Prompt 텍스트
        'start_tracking_brain_health': '두뇌 건강 추적 시작하기',
        'login_prompt_desc':
            '로그인하여 두뇌 건강 점수를 기록하고 진행 상황을 추적하세요. 메모리 게임을 통해 인지 능력을 향상시키세요.',
        'sign_in': '로그인',
        'create_account': '계정 만들기',

        // User Rankings 텍스트
        'user_rankings': '사용자 랭킹',
        'rank': '순위',
        'user': '사용자',
        'score': '점수',
        'failed_to_load_rankings': '랭킹 로드 실패',
        'no_ranking_data': '랭킹 데이터가 없습니다',

        // Date format 텍스트
        'today': '오늘',
        'yesterday': '어제',

        // Activity Chart 텍스트
        'brain_health_progress': '두뇌 건강 진행 상황',
        'welcome_to_brain_health': '두뇌 건강에 오신 것을 환영합니다!',
        'start_playing_memory_games': '메모리 게임을 시작하여\n두뇌 건강을 추적하세요',
        'score': '점수',
        'date_range': '날짜 범위',
        'last_7_days': '최근 7일',
        'last_30_days': '최근 30일',
        'all_time': '전체 기간',
      };
    }

    // 일본어 번역
    if (languageCode == 'ja-JP') {
      return {
        'select_language': '言語を選択',
        'search_language': '言語を検索',
        'all': 'すべて',
        'asian_languages': 'アジア言語',
        'european_languages': 'ヨーロッパ言語',
        'middle_eastern_languages': '中東言語',
        'african_languages': 'アフリカ言語',
        'cancel': 'キャンセル',
        // 앱 전체에서 사용하는 일반적인 텍스트 추가
        'ok': 'OK',
        'yes': 'はい',
        'no': 'いいえ',
        'save': '保存',
        'app_title': 'メモリーゲーム',
        'delete': '削除',
        'edit': '編集',
        'close': '閉じる',
        'back': '戻る',
        'next': '次へ',
        'continue': '続ける',
        'settings': '設定',
        'profile': 'プロフィール',
        'home': 'ホーム',
        'game': 'ゲーム',
        'ranking': 'ランキング',
        'brain_health': '脳の健康',
        'player': 'プレイヤー',
        'players': 'プレイヤー',

        // Player Selection Dialog 텍스트
        'select_players': 'プレイヤーを選択',
        'select_up_to_3_players': '最大3人の他のプレイヤーを選択してください',
        'you_will_be_included': 'あなたは常にプレイヤーとして含まれます',
        'confirm': '確認',
        'retry': '再試行',
        'no_other_users': '他のユーザーが見つかりません',
        'failed_to_load_users': 'ユーザーリストの読み込みに失敗しました',
        'country': '国',
        'level': 'レベル',
        'unknown': '不明',
        'unknown_player': '不明なプレイヤー',
        'multiplayer_verification': 'マルチプレイヤー認証',
        'create_pin': 'PINコードを作成',
        'enter_pin_for': 'のPINコードを入力してください',
        'no_pin_for': 'にはPINコードがありません',
        'create_pin_for_multiplayer': 'マルチプレイヤー用の2桁のPINコードを作成してください',
        'enter_2_digit_pin': '2桁の数字を入力してください',
        'pin_is_2_digits': 'PINは2桁の数字で設定してください',
        'wrong_pin': '間違ったPINコードです',

        // Grid Selection Dialog 텍스트
        'select_grid_size': 'グリッドサイズを選択',
        'choose_difficulty': '難易度を選択してください',
        'multiplier': '×', // 곱셈 기호

        // Profile Edit Dialog 텍스트
        'edit_profile': 'プロフィール編集',
        'nickname': 'ニックネーム',
        'enter_nickname': 'ニックネームを入力してください',
        'birthday': '生年月日',
        'select_birthday': '生年月日を選択してください',
        'gender': '性別',
        'male': '男性',
        'female': '女性',
        'select_country': '国を選択してください',
        'multi_game_pin': 'マルチプレイヤーPIN',
        'enter_two_digit_pin': '2桁のPINを入力してください',
        'two_digit_pin_helper': 'このPINはマルチプレイヤーゲームセッションで使用されます',
        'change_password': 'パスワード変更',
        'current_password': '現在のパスワード',
        'enter_current_password': '現在のパスワードを入力してください',
        'new_password': '新しいパスワード',
        'enter_new_password': '新しいパスワードを入力してください',
        'confirm_password': 'パスワード確認',
        'confirm_new_password': '新しいパスワードを確認',
        'must_be_two_digit': '2桁の数字である必要があります',
        'current_password_required': '現在のパスワードが必要です',
        'password_length_error': 'パスワードは最低6文字以上である必要があります',
        'passwords_do_not_match': 'パスワードが一致しません',
        'incorrect_current_password': '現在のパスワードが正しくありません',
        'error_changing_password': 'パスワード変更エラー',
        'error': 'エラー',
        'sign_out': 'ログアウト',
        'random_shake': 'カードをシャッフル!!',

        // Completion Dialog 텍스트
        'congratulations': 'おめでとうございます!',
        'winner': '勝者: {name}!',
        'its_a_tie': '引き分けです!',
        'points_divided': 'ポイントは同点のプレイヤー間で均等に分配されます!',
        'time_seconds': '時間: {seconds}秒',
        'flips': 'めくり回数: {count}',
        'players_score_multiplier': '({players}人プレイ: スコア x{multiplier})',
        'points_divided_explanation': '(ポイントは同点のプレイヤー間で分配されます)',
        'health_score': '脳の健康スコア: +{points}',
        'new_game': '新しいゲーム',
        'times_up': '時間切れ!',
        'retry': '再試行',

        // Tutorial Overlay 텍스트
        'memory_game_guide': 'メモリーゲームガイド',
        'card_selection_title': 'カード選択',
        'card_selection_desc': 'カードをタップしてめくり、一致するペアを見つけましょう。',
        'time_limit_title': '制限時間',
        'time_limit_desc': '制限時間内にすべてのペアを一致させてください。早く一致させるほど高いスコアが得られます。',
        'add_time_title': '時間追加',
        'add_time_desc': 'タップ "+30s" をタップして時間を追加します（脳の健康ポイントを消費）。',
        'multiplayer_title': 'マルチプレイヤー',
        'multiplayer_desc': 'プレイヤー数（1-4）を変更して友達と一緒にプレイしましょう。',
        'dont_show_again': '次回から表示しない',
        'start_game': 'ゲーム開始',

        // Brain Health Dashboard Tutorial 텍스트
        'brain_health_dashboard': '脳の健康ダッシュボード',
        'brain_health_index_title': '脳の健康指数',
        'brain_health_index_desc':
            'メモリーゲームを通じて向上した脳の健康スコアを確認しましょう。レベルが高いほど認知症予防効果が高まります。',
        'activity_graph_title': 'アクティビティグラフ',
        'activity_graph_desc': 'グラフで時間の経過に伴う脳の健康スコアの変化を確認できます。',
        'ranking_system_title': 'ランキングシステム',
        'ranking_system_desc': '他のユーザーと脳の健康スコアを比較し、ランキングを確認しましょう。',
        'game_statistics_title': 'ゲーム統計',
        'game_statistics_desc': 'プレイしたゲーム数、見つけたマッチ数、最高記録などの様々な統計を確認しましょう。',
        'got_it': '了解しました！',

        // Brain Health Dashboard 추가 텍스트
        'play_memory_games_description': 'メモリーゲームをプレイして脳の健康を向上させましょう！',
        'calculating_brain_health_index': '脳の健康指数を計算中です...',
        'error_calculating_index': '脳の健康指数の計算中にエラーが発生しました',
        'age': '年齢',
        'update': '更新',
        'points_to_next_level': '次のレベルに到達するには{points}ポイントが必要です',
        'maximum_level_reached': '最大レベルに到達しました',
        'index_components': '指数の構成要素',
        'age_factor': '年齢要因',
        'recent_activity': '最近の活動',
        'game_performance': 'ゲームパフォーマンス',
        'persistence_bonus': '持続ボーナス',
        'inactivity_penalty': '非活動ペナルティ',
        'inactivity_warning': '{days}日間プレイしていないと、スコアが毎日減少します！',
        'loading_data': 'データローディング中...',
        'refresh_data': 'データリフレッシュ',

        // Login Prompt 텍스트
        'start_tracking_brain_health': '脳の健康を追跡しましょう',
        'login_prompt_desc':
            'サインインして脳の健康スコアを記録し、進捗状況を追跡しましょう。メモリーゲームをプレイして認知能力を向上させましょう。',
        'sign_in': 'サインイン',
        'create_account': 'アカウント作成',

        // User Rankings 텍스트
        'user_rankings': 'ユーザーランキング',
        'rank': 'ランク',
        'user': 'ユーザー',
        'score': 'スコア',
        'failed_to_load_rankings': 'ランキングの読み込みに失敗しました',
        'no_ranking_data': 'ランキングデータがありません',

        // Date format 텍스트
        'today': '今日',
        'yesterday': '昨日',

        // Activity Chart 텍스트
        'brain_health_progress': '脳の健康状態の進捗',
        'welcome_to_brain_health': '脳の健康へようこそ！',
        'start_playing_memory_games': 'メモリーゲームを始めて\n進捗を追跡しましょう',
        'score': 'スコア',
        'date_range': '日付範囲',
        'last_7_days': '過去7日間',
        'last_30_days': '過去30日間',
        'all_time': '全期間',

        // Brain Health Dashboard 追加 텍스트
        'play_memory_games_description': 'メモリーゲームをプレイして脳の健康を向上させましょう！',
        'calculating_brain_health_index': '脳の健康指数を計算中...',
        'error_calculating_index': '脳の健康指数の計算中にエラーが発生しました',
        'age': '年齢',
        'update': '更新',
        'points_to_next_level': '次のレベルに到達するには{points}ポイントが必要です',
        'maximum_level_reached': '最大レベルに到達しました',
        'index_components': '指数の構成要素',
        'age_factor': '年齢要因',
        'recent_activity': '最近の活動',
        'game_performance': 'ゲームパフォーマンス',
        'persistence_bonus': '持続ボーナス',
        'inactivity_penalty': '非活動ペナルティ',
        'inactivity_warning': '{days}日間プレイしていないと、スコアが毎日減少します！',
      };
    }

    // 중국어(간체) 번역
    if (languageCode == 'zh-CN') {
      return {
        'select_language': '选择语言',
        'search_language': '搜索语言',
        'all': '全部',
        'asian_languages': '亚洲语言',
        'european_languages': '欧洲语言',
        'middle_eastern_languages': '中东语言',
        'african_languages': '非洲语言',
        'cancel': '取消',
        // 앱 전체에서 사용하는 일반적인 텍스트 추가
        'ok': '确认',
        'yes': '是',
        'no': '否',
        'save': '保存',
        'app_title': '记忆游戏',
        'delete': '删除',
        'edit': '编辑',
        'close': '关闭',
        'back': '返回',
        'next': '下一步',
        'continue': '继续',
        'settings': '设置',
        'profile': '个人资料',
        'home': '首页',
        'game': '游戏',
        'ranking': '排名',
        'brain_health': '脑健康',
        'player': '玩家',
        'players': '玩家',

        // Player Selection Dialog 텍스트
        'select_players': '选择玩家',
        'select_up_to_3_players': '最多选择3名其他玩家',
        'you_will_be_included': '您将始终被包括为玩家',
        'confirm': '确认',
        'retry': '重试',
        'no_other_users': '找不到其他用户',
        'failed_to_load_users': '加载用户列表失败',
        'country': '国家',
        'level': '等级',
        'unknown': '未知',
        'unknown_player': '未知玩家',
        'multiplayer_verification': '多人游戏验证',
        'create_pin': '创建PIN码',
        'enter_pin_for': '输入PIN码',
        'no_pin_for': '没有PIN码',
        'create_pin_for_multiplayer': '为多人游戏创建两位数PIN码',
        'enter_2_digit_pin': '输入两位数PIN码',
        'pin_is_2_digits': 'PIN必须是两位数',
        'wrong_pin': '错误的PIN码',

        // Grid Selection Dialog 텍스트
        'select_grid_size': '选择网格大小',
        'choose_difficulty': '选择难度',
        'multiplier': '×', // 곱셈 기호

        // Profile Edit Dialog 텍스트
        'edit_profile': '编辑个人资料',
        'nickname': '昵称',
        'enter_nickname': '请输入昵称',
        'birthday': '出生日期',
        'select_birthday': '请选择出生日期',
        'gender': '性别',
        'male': '男',
        'female': '女',
        'select_country': '请选择国家',
        'multi_game_pin': '多人游戏PIN',
        'enter_two_digit_pin': '请输入两位数PIN',
        'two_digit_pin_helper': '此PIN将用于多人游戏会话',
        'change_password': '更改密码',
        'current_password': '当前密码',
        'enter_current_password': '请输入当前密码',
        'new_password': '新密码',
        'enter_new_password': '请输入新密码',
        'confirm_password': '确认密码',
        'confirm_new_password': '请确认新密码',
        'must_be_two_digit': '必须是两位数',
        'current_password_required': '需要当前密码',
        'password_length_error': '密码长度必须至少为6个字符',
        'passwords_do_not_match': '密码不匹配',
        'incorrect_current_password': '当前密码不正确',
        'error_changing_password': '更改密码错误',
        'error': '错误',
        'sign_out': '退出登录',
        'random_shake': '随机洗牌!!',

        // Completion Dialog 텍스트
        'congratulations': '恭喜!',
        'winner': '获胜者: {name}!',
        'its_a_tie': '平局!',
        'points_divided': '积分在并列玩家之间平均分配!',
        'time_seconds': '时间: {seconds}秒',
        'flips': '翻牌次数: {count}',
        'players_score_multiplier': '({players}玩家: 得分 x{multiplier})',
        'points_divided_explanation': '(积分在并列玩家之间分配)',
        'health_score': '脑健康得分: +{points}',
        'new_game': '新游戏',
        'times_up': '时间到!',
        'retry': '重试',

        // Tutorial Overlay 텍스트
        'memory_game_guide': '记忆游戏指南',
        'card_selection_title': '卡片选择',
        'card_selection_desc': '点击卡片翻开，找到相匹配的对子。',
        'time_limit_title': '时间限制',
        'time_limit_desc': '在时间限制内找到所有配对。匹配得越快，得分越高。',
        'add_time_title': '添加时间',
        'add_time_desc': '点击"+30秒"添加时间（消耗脑健康点数）。',
        'multiplayer_title': '多人游戏',
        'multiplayer_desc': '更改玩家数量（1-4人）与朋友一起玩。',
        'dont_show_again': '不再显示',
        'start_game': '开始游戏',

        // Brain Health Dashboard Tutorial 텍스트
        'brain_health_dashboard': '脑健康仪表盘',
        'brain_health_index_title': '脑健康指数',
        'brain_health_index_desc': '通过记忆游戏检查您改善的脑健康得分。更高的水平增加预防痴呆的效果。',
        'activity_graph_title': '活动图表',
        'activity_graph_desc': '通过图表查看您的脑健康得分随时间的变化。',
        'ranking_system_title': '排名系统',
        'ranking_system_desc': '与其他用户比较您的脑健康得分并查看您的排名。',
        'game_statistics_title': '游戏统计',
        'game_statistics_desc': '查看各种统计数据，如已玩游戏、找到的匹配和最佳记录等。',
        'got_it': '知道了！',

        // Brain Health Dashboard 추가 텍스트
        'play_memory_games_description': '通过记忆游戏提高您的脑健康！',
        'calculating_brain_health_index': '正在计算您的脑健康指数...',
        'error_calculating_index': '计算脑健康指数时出错',
        'age': '年龄',
        'update': '更新',
        'points_to_next_level': '您需要{points}分才能达到下一个等级',
        'maximum_level_reached': '已达到最高等级',
        'index_components': '指数构成要素',
        'age_factor': '年龄因素',
        'recent_activity': '最近活动',
        'game_performance': '游戏表现',
        'persistence_bonus': '持续奖励',
        'inactivity_penalty': '非活动惩罚',
        'inactivity_warning': '您已经{days}天没有玩游戏了。您的分数每天都在下降！',
        'loading_data': '正在加载数据...',
        'refresh_data': '刷新数据',

        // Login Prompt 텍스트
        'start_tracking_brain_health': '开始追踪您的脑健康',
        'login_prompt_desc': '登录以记录您的脑健康得分并跟踪您的进步。玩记忆游戏来提高您的认知能力。',
        'sign_in': '登录',
        'create_account': '创建账户',

        // User Rankings 텍스트
        'user_rankings': '用户排名',
        'rank': '排名',
        'user': '用户',
        'score': '分数',
        'failed_to_load_rankings': '加载排名失败',
        'no_ranking_data': '没有可用的排名数据',

        // Date format 텍스트
        'today': '今天',
        'yesterday': '昨天',

        // Activity Chart 텍스트
        'brain_health_progress': '脑健康进展',
        'welcome_to_brain_health': '欢迎来到脑健康！',
        'start_playing_memory_games': '开始玩记忆游戏\n来追踪您的进展',
        'score': '分数',
        'date_range': '日期范围',
        'last_7_days': '最近7天',
        'last_30_days': '最近30天',
        'all_time': '全部时间',
      };
    }

    // 스페인어 번역
    if (languageCode == 'es-ES') {
      return {
        'select_language': 'Seleccionar idioma',
        'search_language': 'Buscar idioma',
        'all': 'Todos',
        'asian_languages': 'Idiomas asiáticos',
        'european_languages': 'Idiomas europeos',
        'middle_eastern_languages': 'Idiomas de Oriente Medio',
        'african_languages': 'Idiomas africanos',
        'cancel': 'Cancelar',
        'ok': 'Aceptar',
        'yes': 'Sí',
        'no': 'No',
        'save': 'Guardar',
        'app_title': 'Juego de Memoria',
        'delete': 'Eliminar',
        'edit': 'Editar',
        'close': 'Cerrar',
        'back': 'Atrás',
        'next': 'Siguiente',
        'continue': 'Continuar',
        'settings': 'Configuración',
        'profile': 'Perfil',
        'home': 'Inicio',
        'game': 'Juego',
        'ranking': 'Clasificación',
        'brain_health': 'Salud cerebral',
        'player': 'Jugador',
        'players': 'Jugadores',

        // Player Selection Dialog 텍스트
        'select_players': 'Seleccionar jugadores',
        'select_up_to_3_players': 'Selecciona hasta 3 jugadores más',
        'you_will_be_included': 'Siempre estarás incluido como jugador',
        'confirm': 'Confirmar',
        'retry': 'Reintentar',
        'no_other_users': 'No se encontraron otros usuarios',
        'failed_to_load_users': 'Error al cargar usuarios',
        'country': 'País',
        'level': 'Nivel',
        'unknown': 'desconocido',
        'unknown_player': 'Jugador desconocido',
        'multiplayer_verification': 'Verificación multijugador',
        'create_pin': 'Crear PIN',
        'enter_pin_for': 'Introduce el PIN para',
        'no_pin_for': 'No hay PIN para',
        'create_pin_for_multiplayer':
            'Crea un PIN de 2 dígitos para multijugador',
        'enter_2_digit_pin': 'Introduce un PIN de 2 dígitos',
        'pin_is_2_digits': 'El PIN debe tener 2 dígitos',
        'wrong_pin': 'PIN incorrecto',

        // Grid Selection Dialog 텍스트
        'select_grid_size': 'Seleccionar tamaño de cuadrícula',
        'choose_difficulty': 'Elige el nivel de dificultad',
        'multiplier': '×', // 곱셈 기호
        'random_shake': '¡¡Agitar Aleatorio!!',

        // Completion Dialog 텍스트
        'congratulations': '¡Felicitaciones!',
        'winner': '¡Ganador: {name}!',
        'its_a_tie': '¡Es un empate!',
        'points_divided':
            '¡Los puntos se dividen por igual entre los jugadores empatados!',
        'time_seconds': 'Tiempo: {seconds} segundos',
        'flips': 'Volteos: {count}',
        'players_score_multiplier':
            '({players} Jugadores: Puntuación x{multiplier})',
        'points_divided_explanation':
            '(Puntos divididos entre jugadores empatados)',
        'health_score': 'Puntos de Salud: +{points}',
        'new_game': 'Nuevo Juego',
        'times_up': '¡Tiempo Agotado!',
        'retry': 'Reintentar',

        // Tutorial Overlay 텍스트
        'memory_game_guide': 'Guía del Juego de Memoria',
        'card_selection_title': 'Selección de Cartas',
        'card_selection_desc':
            'Toca las cartas para voltearlas y encontrar pares coincidentes.',
        'time_limit_title': 'Límite de Tiempo',
        'time_limit_desc':
            'Encuentra todos los pares dentro del límite de tiempo. Cuanto más rápido los emparejes, mayor será tu puntuación.',
        'add_time_title': 'Añadir Tiempo',
        'add_time_desc':
            'Toca "+30s" para añadir tiempo (cuesta puntos de Salud Cerebral).',
        'multiplayer_title': 'Multijugador',
        'multiplayer_desc':
            'Cambia el número de jugadores (1-4) para jugar con amigos.',
        'dont_show_again': 'No mostrar de nuevo',
        'start_game': 'Iniciar Juego',

        // Brain Health Dashboard Tutorial 텍스트
        'brain_health_dashboard': 'Panel de Salud Cerebral',
        'brain_health_index_title': 'Índice de Salud Cerebral',
        'brain_health_index_desc':
            'Revise su puntuación de salud cerebral mejorada a través del juego de memoria. Un nivel más alto aumenta el efecto de prevención de la demencia.',
        'activity_graph_title': 'Gráfico de Actividad',
        'activity_graph_desc':
            'Vea cómo ha cambiado su puntuación de salud cerebral a lo largo del tiempo mediante gráficos.',
        'ranking_system_title': 'Sistema de Clasificación',
        'ranking_system_desc':
            'Compare su puntuación de salud cerebral con otros usuarios y vea su clasificación.',
        'game_statistics_title': 'Estadísticas de Juego',
        'game_statistics_desc':
            'Vea varias estadísticas como juegos jugados, coincidencias encontradas y mejores registros.',
        'got_it': '¡Entendido!',

        // Brain Health Dashboard 추가 텍스트
        'play_memory_games_description':
            '¡Juega juegos de memoria para mejorar tu salud cerebral!',
        'calculating_brain_health_index':
            'Calculando tu Índice de Salud Cerebral...',
        'error_calculating_index':
            'Error al calcular el Índice de Salud Cerebral',
        'age': 'Edad',
        'update': 'Actualizar',
        'points_to_next_level':
            'Necesitas {points} puntos para alcanzar el siguiente nivel',
        'maximum_level_reached': 'Nivel máximo alcanzado',
        'index_components': 'Componentes del Índice',
        'age_factor': 'Factor de Edad',
        'recent_activity': 'Actividad Reciente',
        'game_performance': 'Rendimiento del Juego',
        'persistence_bonus': 'Bono de Persistencia',
        'inactivity_penalty': 'Penalización por Inactividad',
        'inactivity_warning':
            '¡No has jugado durante {days} día(s). ¡Tu puntuación está disminuyendo cada día!',
        'loading_data': 'Cargando datos...',
        'refresh_data': 'Actualizar Datos',

        // Login Prompt 텍스트
        'start_tracking_brain_health': 'Comienza a Seguir tu Salud Cerebral',
        'login_prompt_desc':
            'Inicia sesión para registrar tu puntuación de salud cerebral y seguir tu progreso. Juega juegos de memoria para mejorar tus habilidades cognitivas.',
        'sign_in': 'Iniciar Sesión',
        'create_account': 'Crear Cuenta',

        // User Rankings 텍스트
        'user_rankings': 'Clasificación de Usuarios',
        'rank': 'Rango',
        'user': 'Usuario',
        'score': 'Puntuación',
        'failed_to_load_rankings': 'Error al cargar las clasificaciones',
        'no_ranking_data': 'No hay datos de clasificación disponibles',

        // Date format 텍스트
        'today': 'Hoy',
        'yesterday': 'Ayer',

        // Activity Chart 텍스트
        'brain_health_progress': 'Progreso de Salud Cerebral',
        'welcome_to_brain_health': '¡Bienvenido a Salud Cerebral!',
        'start_playing_memory_games':
            'Comience a jugar juegos de memoria\npara seguir su progreso',
        'score': 'Puntuación',
        'date_range': 'Rango de Fechas',
        'last_7_days': 'Últimos 7 Días',
        'last_30_days': 'Últimos 30 Días',
        'all_time': 'Todo el Tiempo',
      };
    }

    // 프랑스어 번역
    if (languageCode == 'fr-FR') {
      return {
        'select_language': 'Sélectionner la langue',
        'search_language': 'Rechercher une langue',
        'all': 'Tous',
        'asian_languages': 'Langues asiatiques',
        'european_languages': 'Langues européennes',
        'middle_eastern_languages': 'Langues du Moyen-Orient',
        'african_languages': 'Langues africaines',
        'cancel': 'Annuler',
        'ok': 'OK',
        'yes': 'Oui',
        'no': 'Non',
        'save': 'Enregistrer',
        'app_title': 'Jeu de Mémoire',
        'delete': 'Supprimer',
        'edit': 'Modifier',
        'close': 'Fermer',
        'back': 'Retour',
        'next': 'Suivant',
        'continue': 'Continuer',
        'settings': 'Paramètres',
        'profile': 'Profil',
        'home': 'Accueil',
        'game': 'Jeu',
        'ranking': 'Classement',
        'brain_health': 'Santé cérébrale',
        'player': 'Joueur',
        'players': 'Joueurs',

        // Player Selection Dialog 텍스트
        'select_players': 'Sélectionner les joueurs',
        'select_up_to_3_players': 'Sélectionnez jusqu\'à 3 autres joueurs',
        'you_will_be_included': 'Vous serez toujours inclus comme joueur',
        'confirm': 'Confirmer',
        'retry': 'Réessayer',
        'no_other_users': 'Aucun autre utilisateur trouvé',
        'failed_to_load_users': 'Échec du chargement des utilisateurs',
        'country': 'Pays',
        'level': 'Niveau',
        'unknown': 'inconnu',
        'unknown_player': 'Joueur inconnu',
        'multiplayer_verification': 'Vérification multijoueur',
        'create_pin': 'Créer un code PIN',
        'enter_pin_for': 'Entrez le code PIN pour',
        'no_pin_for': 'Pas de code PIN pour',
        'create_pin_for_multiplayer':
            'Créez un code PIN à 2 chiffres pour le multijoueur',
        'enter_2_digit_pin': 'Entrez un code PIN à 2 chiffres',
        'pin_is_2_digits': 'Le code PIN doit contenir 2 chiffres',
        'wrong_pin': 'Code PIN incorrect',

        // Grid Selection Dialog 텍스트
        'select_grid_size': 'Sélectionner la taille de la grille',
        'choose_difficulty': 'Choisissez le niveau de difficulté',
        'multiplier': '×', // 곱셈 기호
        'random_shake': 'Secousse Aléatoire!!',

        // Completion Dialog 텍스트
        'congratulations': 'Félicitations !',
        'winner': 'Gagnant : {name} !',
        'its_a_tie': 'C\'est une égalité !',
        'points_divided':
            'Les points sont divisés également entre les joueurs à égalité !',
        'time_seconds': 'Temps : {seconds} secondes',
        'flips': 'Retournements : {count}',
        'players_score_multiplier': '({players} Joueurs : Score x{multiplier})',
        'points_divided_explanation':
            '(Points divisés entre les joueurs à égalité)',
        'health_score': 'Score de Santé : +{points}',
        'new_game': 'Nouvelle Partie',
        'times_up': 'Temps Écoulé !',
        'retry': 'Réessayer',

        // Tutorial Overlay 텍스트
        'memory_game_guide': 'Guide du Jeu de Mémoire',
        'card_selection_title': 'Sélection de Cartes',
        'card_selection_desc':
            'Touchez les cartes pour les retourner et trouver des paires correspondantes.',
        'time_limit_title': 'Limite de Temps',
        'time_limit_desc':
            'Associez toutes les paires dans la limite de temps. Des associations plus rapides donnent un score plus élevé.',
        'add_time_title': 'Ajouter du Temps',
        'add_time_desc':
            'Touchez "+30s" pour ajouter du temps (coûte des points de Santé Cérébrale).',
        'multiplayer_title': 'Multijoueur',
        'multiplayer_desc':
            'Changez le nombre de joueurs (1-4) pour jouer avec des amis.',
        'dont_show_again': 'Ne plus afficher',
        'start_game': 'Commencer la partie',

        // Brain Health Dashboard Tutorial 텍스트
        'brain_health_dashboard': 'Tableau de Bord de Santé Cérébrale',
        'brain_health_index_title': 'Indice de Santé Cérébrale',
        'brain_health_index_desc':
            'Vérifiez votre score de santé cérébrale amélioré grâce au jeu de mémoire. Un niveau plus élevé augmente l\'effet de prévention de la démence.',
        'activity_graph_title': 'Graphique d\'Activité',
        'activity_graph_desc':
            'Visualisez l\'évolution de votre score de santé cérébrale au fil du temps à l\'aide de graphiques.',
        'ranking_system_title': 'Système de Classement',
        'ranking_system_desc':
            'Comparez votre score de santé cérébrale avec d\'autres utilisateurs et consultez votre classement.',
        'game_statistics_title': 'Statistiques de Jeu',
        'game_statistics_desc':
            'Consultez diverses statistiques comme les parties jouées, les paires trouvées et vos meilleurs records.',
        'got_it': 'Compris !',

        // Brain Health Dashboard 추가 텍스트
        'play_memory_games_description':
            'Jouez à des jeux de mémoire pour améliorer votre santé cérébrale !',
        'calculating_brain_health_index':
            'Calcul de votre Indice de Santé Cérébrale...',
        'error_calculating_index':
            'Erreur de calcul de l\'Indice de Santé Cérébrale',
        'age': 'Âge',
        'update': 'Mettre à jour',
        'points_to_next_level':
            'Vous avez besoin de {points} points pour atteindre le niveau suivant',
        'maximum_level_reached': 'Niveau maximum atteint',
        'index_components': 'Composants de l\'Indice',
        'age_factor': 'Facteur d\'Âge',
        'recent_activity': 'Activité Récente',
        'game_performance': 'Performance de Jeu',
        'persistence_bonus': 'Bonus de Persistance',
        'inactivity_penalty': 'Pénalité d\'Inactivité',
        'inactivity_warning':
            'Vous n\'avez pas joué depuis {days} jour(s). Votre score diminue chaque jour !',
        'loading_data': 'Chargement des données...',
        'refresh_data': 'Actualiser les Données',

        // Login Prompt 텍스트
        'start_tracking_brain_health':
            'Commencez à Suivre Votre Santé Cérébrale',
        'login_prompt_desc':
            'Connectez-vous pour enregistrer votre score de santé cérébrale et suivre vos progrès. Jouez à des jeux de mémoire pour améliorer vos capacités cognitives.',
        'sign_in': 'Se Connecter',
        'create_account': 'Créer un Compte',

        // User Rankings 텍스트
        'user_rankings': 'Classement des Utilisateurs',
        'rank': 'Rang',
        'user': 'Utilisateur',
        'score': 'Score',
        'failed_to_load_rankings': 'Échec du chargement des classements',
        'no_ranking_data': 'Aucune donnée de classement disponible',

        // Date format 텍스트
        'today': 'Aujourd\'hui',
        'yesterday': 'Hier',

        // Activity Chart 텍스트
        'brain_health_progress': 'Progrès de Santé Cérébrale',
        'welcome_to_brain_health': 'Bienvenue à la Santé Cérébrale !',
        'start_playing_memory_games':
            'Commencez à jouer aux jeux de mémoire\npour suivre votre progrès',
        'score': 'Score',
        'date_range': 'Plage de Dates',
        'last_7_days': '7 Derniers Jours',
        'last_30_days': '30 Derniers Jours',
        'all_time': 'Tout le Temps',
      };
    }

    // 독일어 번역
    if (languageCode == 'de-DE') {
      return {
        'select_language': 'Sprache auswählen',
        'search_language': 'Sprache suchen',
        'all': 'Alle',
        'asian_languages': 'Asiatische Sprachen',
        'european_languages': 'Europäische Sprachen',
        'middle_eastern_languages': 'Nahöstliche Sprachen',
        'african_languages': 'Afrikanische Sprachen',
        'cancel': 'Abbrechen',
        'ok': 'OK',
        'yes': 'Ja',
        'no': 'Nein',
        'save': 'Speichern',
        'app_title': 'Gedächtnisspiel',
        'delete': 'Löschen',
        'edit': 'Bearbeiten',
        'close': 'Schließen',
        'back': 'Zurück',
        'next': 'Weiter',
        'continue': 'Fortfahren',
        'settings': 'Einstellungen',
        'profile': 'Profil',
        'home': 'Startseite',
        'game': 'Spiel',
        'ranking': 'Rangliste',
        'brain_health': 'Gehirngesundheit',
        'player': 'Spieler',
        'players': 'Spieler',

        // Player Selection Dialog 텍스트
        'select_players': 'Spieler auswählen',
        'select_up_to_3_players': 'Wählen Sie bis zu 3 weitere Spieler aus',
        'you_will_be_included': 'Sie werden immer als Spieler einbezogen',
        'confirm': 'Bestätigen',
        'retry': 'Wiederholen',
        'no_other_users': 'Keine anderen Benutzer gefunden',
        'failed_to_load_users': 'Benutzer konnten nicht geladen werden',
        'country': 'Land',
        'level': 'Level',
        'unknown': 'unbekannt',
        'unknown_player': 'Unbekannter Spieler',
        'multiplayer_verification': 'Mehrspieler-Verifizierung',
        'create_pin': 'PIN erstellen',
        'enter_pin_for': 'PIN eingeben für',
        'no_pin_for': 'Keine PIN für',
        'create_pin_for_multiplayer':
            'Erstellen Sie eine 2-stellige PIN für den Mehrspielermodus',
        'enter_2_digit_pin': 'Geben Sie eine 2-stellige PIN ein',
        'pin_is_2_digits': 'Die PIN sollte 2 Ziffern haben',
        'wrong_pin': 'Falsche PIN',

        // Grid Selection Dialog 텍스트
        'select_grid_size': 'Rastergröße auswählen',
        'choose_difficulty': 'Schwierigkeitsgrad wählen',
        'multiplier': '×', // 곱셈 기호
        'random_shake': 'Zufälliges Schütteln!!',

        // Completion Dialog 텍스트
        'congratulations': 'Glückwunsch!',
        'winner': 'Gewinner: {name}!',
        'its_a_tie': 'Unentschieden!',
        'points_divided':
            'Punkte werden gleichmäßig unter den gleichauf liegenden Spielern aufgeteilt!',
        'time_seconds': 'Zeit: {seconds} Sekunden',
        'flips': 'Züge: {count}',
        'players_score_multiplier': '({players} Spieler: Punkte x{multiplier})',
        'points_divided_explanation':
            '(Punkte unter gleichauf liegenden Spielern aufgeteilt)',
        'health_score': 'Gesundheitspunkte: +{points}',
        'new_game': 'Neues Spiel',
        'times_up': 'Zeit Abgelaufen!',
        'retry': 'Wiederholen',

        // Tutorial Overlay 텍스트
        'memory_game_guide': 'Memory-Spiel Anleitung',
        'card_selection_title': 'Kartenauswahl',
        'card_selection_desc':
            'Tippen Sie auf Karten, um sie umzudrehen und passende Paare zu finden.',
        'time_limit_title': 'Zeitlimit',
        'time_limit_desc':
            'Finden Sie alle Paare innerhalb des Zeitlimits. Schnelleres Matching ergibt höhere Punktzahl.',
        'add_time_title': 'Zeit hinzufügen',
        'add_time_desc':
            'Tippen Sie auf "+30s", um Zeit hinzuzufügen (kostet Gehirngesundheitspunkte).',
        'multiplayer_title': 'Mehrspieler',
        'multiplayer_desc':
            'Ändern Sie die Spieleranzahl (1-4), um mit Freunden zu spielen.',
        'dont_show_again': 'Nicht mehr anzeigen',
        'start_game': 'Spiel starten',

        // Brain Health Dashboard Tutorial 텍스트
        'brain_health_dashboard': 'Gehirngesundheits-Dashboard',
        'brain_health_index_title': 'Gehirngesundheitsindex',
        'brain_health_index_desc':
            'Überprüfen Sie Ihren verbesserten Gehirngesundheits-Score durch das Memory-Spiel. Ein höheres Level erhöht die Demenzprävention.',
        'activity_graph_title': 'Aktivitätsdiagramm',
        'activity_graph_desc':
            'Sehen Sie anhand von Diagrammen, wie sich Ihr Gehirngesundheits-Score im Laufe der Zeit verändert hat.',
        'ranking_system_title': 'Rangsystem',
        'ranking_system_desc':
            'Vergleichen Sie Ihren Gehirngesundheits-Score mit anderen Benutzern und sehen Sie Ihren Rang.',
        'game_statistics_title': 'Spielstatistiken',
        'game_statistics_desc':
            'Sehen Sie verschiedene Statistiken wie gespielte Spiele, gefundene Paare und Bestleistungen.',
        'got_it': 'Verstanden!',

        // Brain Health Dashboard 추가 텍스트
        'play_memory_games_description':
            'Spielen Sie Gedächtnisspiele, um Ihre Gehirngesundheit zu verbessern!',
        'calculating_brain_health_index':
            'Berechnung Ihres Gehirngesundheitsindex...',
        'error_calculating_index':
            'Fehler bei der Berechnung des Gehirngesundheitsindex',
        'age': 'Alter',
        'update': 'Aktualisieren',
        'points_to_next_level':
            'Sie benötigen {points} Punkte, um die nächste Stufe zu erreichen',
        'maximum_level_reached': 'Maximale Stufe erreicht',
        'index_components': 'Index-Komponenten',
        'age_factor': 'Altersfaktor',
        'recent_activity': 'Aktuelle Aktivität',
        'game_performance': 'Spielleistung',
        'persistence_bonus': 'Ausdauerbonus',
        'inactivity_penalty': 'Inaktivitätsstrafe',
        'inactivity_warning':
            'Sie haben seit {days} Tag(en) nicht gespielt. Ihre Punktzahl sinkt jeden Tag!',
        'loading_data': 'Daten werden geladen...',
        'refresh_data': 'Daten aktualisieren',

        // Login Prompt 텍스트
        'start_tracking_brain_health':
            'Beginnen Sie, Ihre Gehirngesundheit zu verfolgen',
        'login_prompt_desc':
            'Melden Sie sich an, um Ihren Gehirngesundheitswert aufzuzeichnen und Ihren Fortschritt zu verfolgen. Spielen Sie Gedächtnisspiele, um Ihre kognitiven Fähigkeiten zu verbessern.',
        'sign_in': 'Anmelden',
        'create_account': 'Konto erstellen',

        // User Rankings 텍스트
        'user_rankings': 'Benutzerrangliste',
        'rank': 'Rang',
        'user': 'Benutzer',
        'score': 'Punktzahl',
        'failed_to_load_rankings': 'Rangliste konnte nicht geladen werden',
        'no_ranking_data': 'Keine Ranglistendaten verfügbar',

        // Date format 텍스트
        'today': 'Heute',
        'yesterday': 'Gestern',

        // Activity Chart 텍스트
        'brain_health_progress': 'Gehirngesundheitsfortschritt',
        'welcome_to_brain_health': 'Willkommen zur Gehirngesundheit!',
        'start_playing_memory_games':
            'Starten Sie Memory-Spiele\num Ihren Fortschritt zu verfolgen',
        'score': 'Punktzahl',
        'date_range': 'Datumsbereich',
        'last_7_days': 'Letzte 7 Tage',
        'last_30_days': 'Letzte 30 Tage',
        'all_time': 'Gesamte Zeit',
      };
    }

    // 러시아어 번역
    if (languageCode == 'ru-RU') {
      return {
        'select_language': 'Выбрать язык',
        'search_language': 'Поиск языка',
        'all': 'Все',
        'asian_languages': 'Азиатские языки',
        'european_languages': 'Европейские языки',
        'middle_eastern_languages': 'Ближневосточные языки',
        'african_languages': 'Африканские языки',
        'cancel': 'Отмена',
        'ok': 'OK',
        'yes': 'Да',
        'no': 'Нет',
        'save': 'Сохранить',
        'app_title': 'Игра на Память',
        'delete': 'Удалить',
        'edit': 'Редактировать',
        'close': 'Закрыть',
        'back': 'Назад',
        'next': 'Далее',
        'continue': 'Продолжить',
        'settings': 'Настройки',
        'profile': 'Профиль',
        'home': 'Главная',
        'game': 'Игра',
        'ranking': 'Рейтинг',
        'brain_health': 'Здоровье мозга',
        'player': 'Игрок',
        'players': 'Игроки',

        // Player Selection Dialog 텍스트
        'select_players': 'Выбрать игроков',
        'select_up_to_3_players': 'Выберите до 3 других игроков',
        'you_will_be_included': 'Вы всегда будете включены как игрок',
        'confirm': 'Подтвердить',
        'retry': 'Повторить',
        'no_other_users': 'Другие пользователи не найдены',
        'failed_to_load_users': 'Не удалось загрузить пользователей',
        'country': 'Страна',
        'level': 'Уровень',
        'unknown': 'неизвестно',
        'unknown_player': 'Неизвестный игрок',
        'multiplayer_verification': 'Проверка многопользовательского режима',
        'create_pin': 'Создать PIN-код',
        'enter_pin_for': 'Введите PIN-код для',
        'no_pin_for': 'Нет PIN-кода для',
        'create_pin_for_multiplayer':
            'Создайте 2-значный PIN-код для многопользовательской игры',
        'enter_2_digit_pin': 'Введите 2-значный PIN-код',
        'pin_is_2_digits': 'PIN-код должен состоять из 2 цифр',
        'wrong_pin': 'Неверный PIN-код',

        // Grid Selection Dialog 텍스트
        'select_grid_size': 'Выбрать размер сетки',
        'choose_difficulty': 'Выберите уровень сложности',
        'multiplier': '×', // 곱셈 기호
        'random_shake': 'Случайное Встряхивание!!',

        // Completion Dialog 텍스트
        'congratulations': 'Поздравляем!',
        'winner': 'Победитель: {name}!',
        'its_a_tie': 'Ничья!',
        'points_divided':
            'Очки равномерно распределяются между игроками с одинаковым результатом!',
        'time_seconds': 'Время: {seconds} секунд',
        'flips': 'Переворотов: {count}',
        'players_score_multiplier': '({players} Игроки: Очки x{multiplier})',
        'points_divided_explanation':
            '(Очки распределены между игроками с одинаковым результатом)',
        'health_score': 'Очки Здоровья: +{points}',
        'new_game': 'Новая Игра',
        'times_up': 'Время Вышло!',
        'retry': 'Повторить',

        // Tutorial Overlay 텍스트
        'memory_game_guide': 'Руководство по Игре Памяти',
        'card_selection_title': 'Выбор Карт',
        'card_selection_desc':
            'Нажмите на карты, чтобы перевернуть и найти совпадающие пары.',
        'time_limit_title': 'Ограничение по Времени',
        'time_limit_desc':
            'Сопоставьте все пары в пределах лимита времени. Более быстрое сопоставление приносит больше очков.',
        'add_time_title': 'Добавить Время',
        'add_time_desc':
            'Нажмите "+30с", чтобы добавить время (расходует очки здоровья мозга).',
        'multiplayer_title': 'Многопользовательский Режим',
        'multiplayer_desc':
            'Измените количество игроков (1-4), чтобы играть с друзьями.',
        'dont_show_again': 'Больше не показывать',
        'start_game': 'Начать Игру',

        // Brain Health Dashboard Tutorial 텍스트
        'brain_health_dashboard': 'Панель здоровья мозга',
        'brain_health_index_title': 'Индекс здоровья мозга',
        'brain_health_index_desc':
            'Проверьте свой улучшенный показатель здоровья мозга с помощью игры на память. Более высокий уровень увеличивает эффект профилактики деменции.',
        'activity_graph_title': 'График активности',
        'activity_graph_desc':
            'Посмотрите, как изменился ваш показатель здоровья мозга с течением времени с помощью графиков.',
        'ranking_system_title': 'Система рейтинга',
        'ranking_system_desc':
            'Сравните свой показатель здоровья мозга с другими пользователями и узнайте свой рейтинг.',
        'game_statistics_title': 'Статистика игры',
        'game_statistics_desc':
            'Просмотрите различные статистические данные, такие как сыгранные игры, найденные совпадения и лучшие рекорды.',
        'got_it': 'Понятно!',

        // Brain Health Dashboard 추가 텍스트
        'play_memory_games_description':
            'Играйте в игры на память, чтобы улучшить здоровье мозга!',
        'calculating_brain_health_index': 'Расчет индекса здоровья мозга...',
        'error_calculating_index': 'Ошибка при расчете индекса здоровья мозга',
        'age': 'Возраст',
        'update': 'Обновить',
        'points_to_next_level':
            'Вам нужно {points} очков, чтобы достичь следующего уровня',
        'maximum_level_reached': 'Достигнут максимальный уровень',
        'index_components': 'Компоненты индекса',
        'age_factor': 'Возрастной фактор',
        'recent_activity': 'Недавняя активность',
        'game_performance': 'Игровая производительность',
        'persistence_bonus': 'Бонус за настойчивость',
        'inactivity_penalty': 'Штраф за бездействие',
        'inactivity_warning':
            'Вы не играли в течение {days} дня(ей). Ваш счет уменьшается каждый день!',
        'loading_data': 'Загрузка данных...',
        'refresh_data': 'Обновить данные',

        // Login Prompt 텍스트
        'start_tracking_brain_health':
            'Начните отслеживать здоровье вашего мозга',
        'login_prompt_desc':
            'Войдите, чтобы записывать показатели здоровья мозга и отслеживать свой прогресс. Играйте в игры на память, чтобы улучшить когнитивные способности.',
        'sign_in': 'Войти',
        'create_account': 'Создать аккаунт',

        // User Rankings 텍스트
        'user_rankings': 'Рейтинг пользователей',
        'rank': 'Ранг',
        'user': 'Пользователь',
        'score': 'Очки',
        'failed_to_load_rankings': 'Не удалось загрузить рейтинги',
        'no_ranking_data': 'Нет доступных данных о рейтинге',

        // Date format 텍스트
        'today': 'Сегодня',
        'yesterday': 'Вчера',

        // Activity Chart 텍스트
        'brain_health_progress': 'Прогресс здоровья мозга',
        'welcome_to_brain_health': 'Добро пожаловать в здоровье мозга!',
        'start_playing_memory_games':
            'Начните играть в игры на память\nчтобы отслеживать свой прогресс',
        'score': 'Счет',
        'date_range': 'Диапазон дат',
        'last_7_days': 'Последние 7 дней',
        'last_30_days': 'Последние 30 дней',
        'all_time': 'За всё время',
      };
    }

    // 아랍어 번역
    if (languageCode == 'ar-SA') {
      return {
        'select_language': 'اختر اللغة',
        'search_language': 'البحث عن لغة',
        'all': 'الكل',
        'asian_languages': 'اللغات الآسيوية',
        'european_languages': 'اللغات الأوروبية',
        'middle_eastern_languages': 'لغات الشرق الأوسط',
        'african_languages': 'اللغات الأفريقية',
        'cancel': 'إلغاء',
        'ok': 'موافق',
        'yes': 'نعم',
        'no': 'لا',
        'save': 'حفظ',
        'app_title': 'لعبة الذاكرة',
        'delete': 'حذف',
        'edit': 'تعديل',
        'close': 'إغلاق',
        'back': 'رجوع',
        'next': 'التالي',
        'continue': 'استمرار',
        'settings': 'الإعدادات',
        'profile': 'الملف الشخصي',
        'home': 'الرئيسية',
        'game': 'اللعبة',
        'ranking': 'التصنيف',
        'brain_health': 'صحة الدماغ',
        'player': 'لاعب',
        'players': 'لاعبين',

        // Player Selection Dialog 텍스트
        'select_players': 'اختيار اللاعبين',
        'select_up_to_3_players': 'اختر حتى 3 لاعبين آخرين',
        'you_will_be_included': 'ستكون دائمًا مشمولًا كلاعب',
        'confirm': 'تأكيد',
        'retry': 'إعادة المحاولة',
        'no_other_users': 'لم يتم العثور على مستخدمين آخرين',
        'failed_to_load_users': 'فشل تحميل المستخدمين',
        'country': 'البلد',
        'level': 'المستوى',
        'unknown': 'غير معروف',
        'unknown_player': 'لاعب غير معروف',
        'multiplayer_verification': 'التحقق من اللعب المتعدد',
        'create_pin': 'إنشاء رمز PIN',
        'enter_pin_for': 'أدخل رمز PIN لـ',
        'no_pin_for': 'لا يوجد رمز PIN لـ',
        'create_pin_for_multiplayer':
            'قم بإنشاء رمز PIN مكون من رقمين للعب المتعدد',
        'enter_2_digit_pin': 'أدخل رمز PIN مكون من رقمين',
        'pin_is_2_digits': 'يجب أن يتكون رمز PIN من رقمين',
        'wrong_pin': 'رمز PIN غير صحيح',

        // Grid Selection Dialog 텍스트
        'select_grid_size': 'اختر حجم الشبكة',
        'choose_difficulty': 'اختر مستوى الصعوبة',
        'multiplier': '×', // 곱셈 기호
        'random_shake': 'هز عشوائي!!',

        // Completion Dialog 텍스트
        'congratulations': 'تهانينا!',
        'winner': 'الفائز: {name}!',
        'its_a_tie': 'إنه تعادل!',
        'points_divided': 'يتم تقسيم النقاط بالتساوي بين اللاعبين المتعادلين!',
        'time_seconds': 'الوقت: {seconds} ثانية',
        'flips': 'القلبات: {count}',
        'players_score_multiplier': '({players} لاعبين: النقاط x{multiplier})',
        'points_divided_explanation': '(النقاط مقسمة بين اللاعبين المتعادلين)',
        'health_score': 'نقاط الصحة: +{points}',
        'new_game': 'لعبة جديدة',
        'times_up': 'انتهى الوقت!',
        'retry': 'إعادة المحاولة',

        // Tutorial Overlay 텍스트
        'memory_game_guide': 'دليل لعبة الذاكرة',
        'card_selection_title': 'اختيار البطاقات',
        'card_selection_desc':
            'اضغط على البطاقات لقلبها والعثور على أزواج متطابقة.',
        'time_limit_title': 'الحد الزمني',
        'time_limit_desc':
            'طابق جميع الأزواج ضمن الحد الزمني. التطابق الأسرع يكسب نقاطًا أعلى.',
        'add_time_title': 'إضافة الوقت',
        'add_time_desc':
            'اضغط على "+30 ثانية" لإضافة الوقت (يكلف نقاط صحة الدماغ).',
        'multiplayer_title': 'متعدد اللاعبين',
        'multiplayer_desc': 'غيّر عدد اللاعبين (1-4) للعب مع الأصدقاء.',
        'dont_show_again': 'عدم الإظهار مرة أخرى',
        'start_game': 'ابدأ اللعبة',

        // Brain Health Dashboard Tutorial 텍스트
        'brain_health_dashboard': 'لوحة معلومات صحة الدماغ',
        'brain_health_index_title': 'مؤشر صحة الدماغ',
        'brain_health_index_desc':
            'تحقق من درجة صحة الدماغ المحسنة من خلال لعبة الذاكرة. يزيد المستوى الأعلى من تأثير الوقاية من الخرف.',
        'activity_graph_title': 'رسم بياني للنشاط',
        'activity_graph_desc':
            'شاهد كيف تغيرت درجة صحة الدماغ بمرور الوقت من خلال الرسوم البيانية.',
        'ranking_system_title': 'نظام التصنيف',
        'ranking_system_desc':
            'قارن درجة صحة الدماغ مع المستخدمين الآخرين واطلع على تصنيفك.',
        'game_statistics_title': 'إحصائيات اللعبة',
        'game_statistics_desc':
            'اطلع على إحصائيات متنوعة مثل الألعاب التي تم لعبها والتطابقات التي تم العثور عليها وأفضل السجلات.',
        'got_it': 'فهمت!',

        // Brain Health Dashboard 추가 텍스트
        'play_memory_games_description': 'العب ألعاب الذاكرة لتحسين صحة دماغك!',
        'calculating_brain_health_index': 'جاري حساب مؤشر صحة الدماغ...',
        'error_calculating_index': 'خطأ في حساب مؤشر صحة الدماغ',
        'age': 'العمر',
        'update': 'تحديث',
        'points_to_next_level':
            'تحتاج إلى {points} نقطة للوصول إلى المستوى التالي',
        'maximum_level_reached': 'تم الوصول إلى أقصى مستوى',
        'index_components': 'مكونات المؤشر',
        'age_factor': 'عامل العمر',
        'recent_activity': 'النشاط الأخير',
        'game_performance': 'أداء اللعبة',
        'persistence_bonus': 'مكافأة المثابرة',
        'inactivity_penalty': 'عقوبة عدم النشاط',
        'inactivity_warning':
            'لم تلعب منذ {days} يوم (أيام). نقاطك تنخفض كل يوم!',
        'loading_data': 'جار تحميل البيانات...',
        'refresh_data': 'تحديث البيانات',

        // Login Prompt 텍스트
        'start_tracking_brain_health': 'ابدأ بتتبع صحة دماغك',
        'login_prompt_desc':
            'قم بتسجيل الدخول لتسجيل درجة صحة الدماغ وتتبع تقدمك. العب ألعاب الذاكرة لتحسين قدراتك المعرفية.',
        'sign_in': 'تسجيل الدخول',
        'create_account': 'إنشاء حساب',

        // User Rankings 텍스트
        'user_rankings': 'تصنيفات المستخدمين',
        'rank': 'الرتبة',
        'user': 'المستخدم',
        'score': 'النقاط',
        'failed_to_load_rankings': 'فشل تحميل التصنيفات',
        'no_ranking_data': 'لا توجد بيانات تصنيف متاحة',

        // Date format 텍스트
        'today': 'اليوم',
        'yesterday': 'الأمس',

        // Activity Chart 텍스트
        'brain_health_progress': 'تقدم صحة الدماغ',
        'welcome_to_brain_health': 'مرحبًا بك في صحة الدماغ!',
        'start_playing_memory_games': 'ابدأ بلعب ألعاب الذاكرة\nلتتبع تقدمك',
        'score': 'النقاط',
        'date_range': 'نطاق التاريخ',
        'last_7_days': 'آخر 7 أيام',
        'last_30_days': 'آخر 30 يومًا',
        'all_time': 'كل الوقت',
      };
    }

    // 기본값 반환
    return defaultTranslations;
  }

  // 언어 그룹 이름 번역 (예: 'Asian Languages' -> '아시아 언어')
  String getTranslatedGroupName(String groupName) {
    String key = groupName.toLowerCase().replaceAll(' ', '_');
    Map<String, String> translations = getUITranslations();
    return translations[key] ?? groupName;
  }
}
