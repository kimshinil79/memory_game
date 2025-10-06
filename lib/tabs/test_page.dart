import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';
import '/item_list.dart';
import '/card_item_data/index.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/widgets/tutorials/test_tutorial_overlay.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final int totalQuestions = 10;
  List<List<String>> questionOptions = [];
  List<String> correctAnswers = [];
  List<String?> userAnswers = List.filled(10, null);
  int currentQuestion = 0;
  bool allAnswered = false;
  final FlutterTts flutterTts = FlutterTts();
  bool isTestSubmitted = false;

  // Tutorial related variables
  bool _showTutorial = false;
  bool _doNotShowAgain = false;
  final String _tutorialPrefKey = 'testPageTutorialShown';

  late AnimationController _animationController;

  // K-pop Demon Hunters theme colors
  final Color primaryColor = const Color(0xFFFF2D95); // Neon Pink
  final Color secondaryColor = const Color(0xFF00E5FF); // Neon Cyan
  final Color accentColor = const Color(0xFF9C27B0); // Neon Purple
  final Color bgColorLight = const Color(0xFF0B0D13); // Dark background
  final Color bgColorDark = const Color(0xFF1A1D26); // Darker background

  String _currentLanguage = '';

  // 언어 번역을 저장할 변수
  late Map<String, String> translations;

  // 화면 크기 기반 동적 크기 계산
  double get _screenWidth => MediaQuery.of(context).size.width;
  double get _screenHeight => MediaQuery.of(context).size.height;

  // 폴더블 상태 확인
  bool get _isFolded =>
      Provider.of<LanguageProvider>(context, listen: false).isFolded;
  bool get _isUnfolded => !_isFolded;

  // 화면 크기 분류
  bool get _isSmallScreen => _screenWidth < 360 || _screenHeight < 640;
  bool get _isMediumScreen => _screenWidth < 414 || _screenHeight < 736;
  bool get _isLargeScreen => _screenWidth >= 768;

  // 앱바 제목 폰트 크기
  double get _appBarTitleSize => _isSmallScreen
      ? _screenWidth * 0.055
      : _isMediumScreen
          ? _screenWidth * 0.058
          : _screenWidth * 0.06;

  // 질문 인디케이터 크기
  double get _questionIndicatorSize => _isSmallScreen
      ? _screenWidth * 0.065
      : _isMediumScreen
          ? _screenWidth * 0.068
          : _screenWidth * 0.07;

  double get _questionIndicatorFontSize => _isSmallScreen
      ? _screenWidth * 0.028
      : _isMediumScreen
          ? _screenWidth * 0.03
          : _screenWidth * 0.032;

  // 그리드 관련 크기
  double get _gridSpacing => _screenWidth * 0.04;
  double get _gridHorizontalPadding => _screenWidth * 0.05;
  double get _gridChildAspectRatio => _isSmallScreen ? 1.0 : 1.1;

  // 컨트롤 버튼 크기 (폴더블 상태에 따른 동적 조절)
  double get _controlButtonSize {
    if (_isUnfolded) {
      return _availableContentHeight * 0.06; // 사용 가능한 높이의 6%로 더 작게
    }
    return _isSmallScreen
        ? _screenWidth * 0.12
        : _isMediumScreen
            ? _screenWidth * 0.13
            : _screenWidth * 0.14;
  }

  double get _playButtonSize {
    if (_isUnfolded) {
      return _availableContentHeight * 0.08; // 사용 가능한 높이의 8%로 더 작게
    }
    return _isSmallScreen
        ? _screenWidth * 0.16
        : _isMediumScreen
            ? _screenWidth * 0.17
            : _screenWidth * 0.18;
  }

  double get _controlIconSize {
    if (_isUnfolded) {
      return _controlButtonSize * 0.4; // 버튼 크기의 40%
    }
    return _isSmallScreen
        ? _screenWidth * 0.045
        : _isMediumScreen
            ? _screenWidth * 0.048
            : _screenWidth * 0.05;
  }

  double get _playIconSize {
    if (_isUnfolded) {
      return _playButtonSize * 0.45; // 버튼 크기의 45%
    }
    return _isSmallScreen
        ? _screenWidth * 0.07
        : _isMediumScreen
            ? _screenWidth * 0.075
            : _screenWidth * 0.08;
  }

  // 하단 버튼 크기
  double get _bottomButtonHeight => _isSmallScreen
      ? _screenHeight * 0.055
      : _isMediumScreen
          ? _screenHeight * 0.058
          : _screenHeight * 0.06;

  double get _bottomButtonFontSize => _isSmallScreen
      ? _screenWidth * 0.035
      : _isMediumScreen
          ? _screenWidth * 0.038
          : _screenWidth * 0.04;

  // 여백 및 간격 (폴더블 상태에 따른 동적 조절)
  double get _verticalSpacing {
    if (_isUnfolded) {
      return _availableContentHeight * 0.008; // 사용 가능한 높이의 0.8%로 더 줄임
    }
    return _screenHeight * 0.02;
  }

  double get _sectionPadding => _screenWidth * 0.04;

  // 다이얼로그 크기
  double get _dialogMaxHeight => _screenHeight * 0.8;
  double get _dialogWidth =>
      _isLargeScreen ? _screenWidth * 0.5 : _screenWidth * 0.85;
  double get _dialogPadding => _screenWidth * 0.06;
  double get _dialogBorderRadius => _screenWidth * 0.05;

  // 다이얼로그 폰트 크기
  double get _dialogTitleSize => _isSmallScreen
      ? _screenWidth * 0.055
      : _isMediumScreen
          ? _screenWidth * 0.058
          : _screenWidth * 0.06;

  double get _dialogSubtitleSize => _isSmallScreen
      ? _screenWidth * 0.035
      : _isMediumScreen
          ? _screenWidth * 0.038
          : _screenWidth * 0.04;

  double get _dialogScoreSize => _isSmallScreen
      ? _screenWidth * 0.08
      : _isMediumScreen
          ? _screenWidth * 0.085
          : _screenWidth * 0.09;

  // 튜토리얼 오버레이 크기
  double get _tutorialIconSize => _isSmallScreen
      ? _screenWidth * 0.06
      : _isMediumScreen
          ? _screenWidth * 0.065
          : _screenWidth * 0.07;

  double get _tutorialTitleSize => _isSmallScreen
      ? _screenWidth * 0.045
      : _isMediumScreen
          ? _screenWidth * 0.048
          : _screenWidth * 0.05;

  double get _tutorialDescSize => _isSmallScreen
      ? _screenWidth * 0.03
      : _isMediumScreen
          ? _screenWidth * 0.032
          : _screenWidth * 0.035;

  // 폴더블 상태에 따른 사용 가능한 높이 계산
  double get _availableContentHeight {
    // AppBar 높이 (약 56px + status bar)
    final appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;

    // 기본 세로 간격 (순환 참조 방지)
    final baseVerticalSpacing = _screenHeight * 0.02;

    // 질문 인디케이터 영역 높이
    final questionIndicatorHeight =
        _questionIndicatorSize + (baseVerticalSpacing * 2);

    // 하단 버튼 영역 높이
    final bottomButtonsHeight = _bottomButtonHeight + (baseVerticalSpacing * 2);

    // 사용 가능한 콘텐츠 높이 계산
    return _screenHeight -
        appBarHeight -
        questionIndicatorHeight -
        bottomButtonsHeight;
  }

  // 폴더블 상태에 따른 동적 크기 조절
  double get _dynamicGridChildAspectRatio {
    if (_isUnfolded) {
      // 펼쳤을 때: 컨트롤 버튼 높이를 고려한 정확한 계산
      final controlButtonsHeight = _playButtonSize + (_verticalSpacing * 2);
      final availableGridHeight = _availableContentHeight -
          controlButtonsHeight -
          (_verticalSpacing * 2);

      final gridItemHeight =
          (availableGridHeight - _dynamicGridSpacing) / 2; // 2행
      final gridItemWidth = (_screenWidth -
              (_dynamicGridHorizontalPadding * 2) -
              _dynamicGridSpacing) /
          2; // 2열
      return gridItemWidth / gridItemHeight;
    }
    return _gridChildAspectRatio; // 기본값
  }

  // 폴더블 상태에 따른 동적 그리드 간격
  double get _dynamicGridSpacing {
    if (_isUnfolded) {
      return _availableContentHeight * 0.01; // 사용 가능한 높이의 1%로 줄임
    }
    return _gridSpacing;
  }

  // 폴더블 상태에 따른 동적 그리드 패딩
  double get _dynamicGridHorizontalPadding {
    if (_isUnfolded) {
      return _screenWidth * 0.03; // 화면 너비의 3%
    }
    return _gridHorizontalPadding;
  }

  @override
  void initState() {
    super.initState();
    initializeQuestions();
    _loadLanguageAndInitTts();
    _checkTutorialStatus(); // Check if tutorial should be shown

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageProvider = Provider.of<LanguageProvider>(context);
    if (_currentLanguage != languageProvider.currentLanguage) {
      _currentLanguage = languageProvider.currentLanguage;
      _initTts();
    }
    // 언어 번역 업데이트
    translations = languageProvider.getUITranslations();
  }

  Future<void> _loadLanguageAndInitTts() async {
    final prefs = await SharedPreferences.getInstance();
    String savedLanguage = prefs.getString('selectedLanguage') ?? 'en-US';
    await flutterTts.setLanguage(savedLanguage);
    await flutterTts.setSpeechRate(0.5);
  }

  void _initTts() async {
    try {
      // 1. SharedPreferences에서 언어 설정 읽기 (우선순위 1)
      final prefs = await SharedPreferences.getInstance();
      String? languageFromPrefs = prefs.getString('selectedLanguage');
      print('로컬 저장소에서 읽은 언어: $languageFromPrefs');

      // 2. LanguageProvider에서 현재 언어 가져오기 (우선순위 2)
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      String languageFromProvider = languageProvider.currentLanguage;
      print('LanguageProvider에서 읽은 언어: $languageFromProvider');

      // 우선순위에 따라 언어 선택
      String selectedLanguage = languageFromPrefs ?? // 로컬 저장소
          (languageFromProvider.isNotEmpty
              ? languageFromProvider
              : 'ko-KR'); // LanguageProvider 또는 기본값

      print('최종 선택된 언어: $selectedLanguage');

      await flutterTts.setLanguage(selectedLanguage);
      await flutterTts.setSpeechRate(0.5);
      print('TestPage TTS 언어 설정 완료: $selectedLanguage');

      // 선택된 언어를 다시 로컬에 저장 (안전을 위해)
      await prefs.setString('selectedLanguage', selectedLanguage);
    } catch (e) {
      print('TestPage TTS 초기화 오류: $e');
      // 오류 발생 시 기본 언어로 설정
      try {
        await flutterTts.setLanguage('ko-KR');
        await flutterTts.setSpeechRate(0.5);
        print('오류로 인해 기본 언어(ko-KR)로 설정됨');

        // 오류 발생 시에도 기본 언어를 로컬에 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selectedLanguage', 'ko-KR');
      } catch (fallbackError) {
        print('TestPage TTS 기본 언어 설정 실패: $fallbackError');
      }
    }
  }

  void initializeQuestions() {
    Random random = Random();
    List<String> availableItems = List.from(itemList);
    availableItems.shuffle();

    questionOptions.clear();
    correctAnswers.clear();
    userAnswers = List.filled(10, null);
    currentQuestion = 0;
    allAnswered = false;
    isTestSubmitted = false;

    for (int i = 0; i < totalQuestions; i++) {
      String correctAnswer = availableItems[i];
      correctAnswers.add(correctAnswer);

      List<String> options = [correctAnswer];
      while (options.length < 4) {
        String option = itemList[random.nextInt(itemList.length)];
        if (!options.contains(option) && !correctAnswers.contains(option)) {
          options.add(option);
        }
      }
      options.shuffle();
      questionOptions.add(options);
    }

    setState(() {});
  }

  // 언어 코드와 맵을 매핑하는 Map
  static final Map<String, Map<String, String>> _languageMaps = {
    'af-ZA': afrikaansItemList,
    'am-ET': amharicItemList,
    'zu-ZA': zuluItemList,
    'sw-KE': swahiliItemList,
    'hi-IN': hindiItemList,
    'bn-IN': bengaliItemList,
    'id-ID': indonesianItemList,
    'km-KH': khmerItemList,
    'ne-NP': nepaliItemList,
    'si-LK': sinhalaItemList,
    'th-TH': thaiItemList,
    'my-MM': myanmarItemList,
    'lo-LA': laoItemList,
    'fil-PH': filipinoItemList,
    'ms-MY': malayItemList,
    'jv-ID': javaneseItemList,
    'su-ID': sundaneseItemList,
    'ta-IN': tamilItemList,
    'te-IN': teluguItemList,
    'ml-IN': malayalamItemList,
    'gu-IN': gujaratiItemList,
    'kn-IN': kannadaItemList,
    'mr-IN': marathiItemList,
    'pa-IN': punjabiItemList,
    'ur-PK': urduItemList,
    'ur-IN': urduItemList,
    'ur-AR': urduItemList,
    'ur-SA': urduItemList,
    'ur-AE': urduItemList,
    'sv-SE': swedishItemList,
    'no-NO': norwegianItemList,
    'da-DK': danishItemList,
    'fi-FI': finnishItemList,
    'nb-NO': norwegianItemList,
    'bg-BG': bulgarianItemList,
    'el-GR': greekItemList,
    'ro-RO': romanianItemList,
    'sk-SK': slovakItemList,
    'uk-UA': ukrainianItemList,
    'hr-HR': croatianItemList,
    'sl-SI': slovenianItemList,
    'fa-IR': persianItemList,
    'he-IL': hebrewItemList,
    'mn-MN': mongolianItemList,
    'sq-AL': albanianItemList,
    'sr-RS': serbianItemList,
    'uz-UZ': uzbekItemList,
    'ko-KR': korItemList,
    'es-ES': spaItemList,
    'fr-FR': fraItemList,
    'de-DE': deuItemList,
    'ja-JP': jpnItemList,
    'zh-CN': chnItemList,
    'ru-RU': rusItemList,
    'it-IT': itaItemList,
    'pt-PT': porItemList,
    'ar-SA': araItemList,
    'tr-TR': turItemList,
    'vi-VN': vieItemList,
    'nl-NL': dutItemList,
    'pl-PL': polItemList,
    'cs-CZ': czeItemList,
    'hu-HU': hunItemList,
  };

  String getLocalizedWord(String word) {
    final currentLanguage =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    
    final languageMap = _languageMaps[currentLanguage];
    return languageMap?[word] ?? word;
  }

  void playAudio(int questionIndex) async {
    try {
      String originalWord = correctAnswers[questionIndex];
      String translatedWord = getLocalizedWord(originalWord);
      print('originalWord in playAudio function: $originalWord');
      print('_currentLanguage in playAudio function: $_currentLanguage');
      await flutterTts.setLanguage(_currentLanguage);
      await flutterTts.speak(translatedWord);
    } catch (e) {
      print('TTS 오류: $e');
    }
  }

  void selectAnswer(String answer) {
    setState(() {
      userAnswers[currentQuestion] = answer;
      allAnswered = !userAnswers.contains(null);
    });
  }

  void showResultDialog() {
    int score = 0;
    for (int i = 0; i < totalQuestions; i++) {
      if (userAnswers[i] == correctAnswers[i]) {
        score++;
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_dialogBorderRadius),
          ),
          elevation: 8,
          backgroundColor: const Color(0xFF0B0D13),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _dialogWidth,
              maxHeight: _dialogMaxHeight,
            ),
            child: Container(
              padding: EdgeInsets.all(_dialogPadding),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E2430), Color(0xFF2A2F3A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(_dialogBorderRadius),
                border: Border.all(
                  color: const Color(0xFF00E5FF),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: _screenWidth * 0.2,
                    width: _screenWidth * 0.2,
                    decoration: BoxDecoration(
                      gradient: score > 7
                          ? const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : score > 4
                              ? const LinearGradient(
                                  colors: [Color(0xFFFF2D95), Color(0xFF00E5FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: score > 7
                              ? const Color(0xFFFFD700).withOpacity(0.4)
                              : score > 4
                                  ? const Color(0xFFFF2D95).withOpacity(0.4)
                                  : const Color(0xFF9C27B0).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      score > 7
                          ? Icons.emoji_events
                          : score > 4
                              ? Icons.thumb_up
                              : Icons.emoji_emotions,
                      size: _screenWidth * 0.1,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: _verticalSpacing),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFF2D95), Color(0xFF00E5FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        translations['test_result'] ?? 'Test Result',
                        style: GoogleFonts.poppins(
                          fontSize: _dialogTitleSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: _verticalSpacing * 0.6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      translations['your_score'] ?? 'Your score',
                      style: GoogleFonts.poppins(
                        fontSize: _dialogSubtitleSize,
                        color: const Color(0xFF00E5FF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: _verticalSpacing * 0.4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$score',
                          style: GoogleFonts.poppins(
                            fontSize: _dialogScoreSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF2D95),
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          ' / $totalQuestions',
                          style: GoogleFonts.poppins(
                            fontSize: _dialogScoreSize * 0.67,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _verticalSpacing),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A2F3A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(_dialogBorderRadius * 0.6),
                        ),
                        padding: EdgeInsets.symmetric(
                            vertical: _bottomButtonHeight * 0.25),
                        minimumSize: Size(double.infinity, _bottomButtonHeight),
                        elevation: 4,
                        shadowColor: const Color(0xFFFF2D95).withOpacity(0.5),
                        side: BorderSide(
                          color: const Color(0xFFFF2D95),
                          width: 2,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          translations['continue'] ?? "Continue",
                          style: GoogleFonts.poppins(
                            fontSize: _bottomButtonFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          isTestSubmitted = true;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void navigateQuestion(int direction) {
    setState(() {
      currentQuestion =
          (currentQuestion + direction).clamp(0, totalQuestions - 1);
      playAudio(currentQuestion);
    });
  }

  void goToQuestion(int index) {
    setState(() {
      currentQuestion = index;
      playAudio(currentQuestion);
    });
  }

  Widget buildQuestionIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _gridHorizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          totalQuestions,
          (index) => GestureDetector(
            onTap: () => goToQuestion(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _questionIndicatorSize,
              height: _questionIndicatorSize,
              decoration: BoxDecoration(
                gradient: index == currentQuestion
                    ? const LinearGradient(
                        colors: [Color(0xFFFF2D95), Color(0xFF00E5FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : isTestSubmitted
                        ? userAnswers[index] == correctAnswers[index]
                            ? const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [Color(0xFFFF5252), Color(0xFFFF6B6B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                        : userAnswers[index] != null
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFF00E5FF).withOpacity(0.3),
                                  const Color(0xFFFF2D95).withOpacity(0.3),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF2A2F3A), Color(0xFF1E2430)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                borderRadius:
                    BorderRadius.circular(_questionIndicatorSize * 0.5),
                boxShadow: [
                  BoxShadow(
                    color: index == currentQuestion
                        ? const Color(0xFFFF2D95).withOpacity(0.4)
                        : const Color(0xFF00E5FF).withOpacity(0.2),
                    blurRadius: _screenWidth * 0.012,
                    offset: Offset(0, _screenHeight * 0.003),
                  ),
                ],
                border: Border.all(
                  color: index == currentQuestion
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF00E5FF).withOpacity(0.3),
                  width: _screenWidth * 0.003,
                ),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: _questionIndicatorFontSize,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildOptionCard(String option) {
    bool isSelected = userAnswers[currentQuestion] == option;
    return GestureDetector(
      onTap: isTestSubmitted ? null : () => selectAnswer(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFFF2D95).withOpacity(0.3)
                  : const Color(0xFF00E5FF).withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  // 선택된 그림에 네온 테두리 표시
                  border: isSelected
                      ? Border.all(
                          color: const Color(0xFFFF2D95), // 네온 핑크 테두리
                          width: 4,
                        )
                      : Border.all(
                          color: const Color(0xFF00E5FF).withOpacity(0.3), // 네온 시안 테두리
                          width: 2,
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  // 이미지를 컨테이너 중앙에 배치
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Image.asset(
                      'assets/pictureDB_webp/$option.webp',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              if (isTestSubmitted)
                Positioned.fill(
                  child: Container(
                    color: _getOverlayColor(option),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getOverlayColor(String option) {
    bool isCorrect = correctAnswers[currentQuestion] == option;
    bool isWrong =
        isTestSubmitted && userAnswers[currentQuestion] == option && !isCorrect;
    if (isCorrect) {
      return const Color(0xFF4CAF50).withOpacity(0.3); // Green for correct
    } else if (isWrong) {
      return const Color(0xFFFF5252).withOpacity(0.3); // Red for wrong
    } else {
      return Colors
          .transparent; // No overlay for selected but not correct/wrong
    }
  }

  Widget buildControlButtons() {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: _isUnfolded
            ? _verticalSpacing * 0.5
            : _verticalSpacing, // 폴더를 펼쳤을 때 간격 절반으로
      ),
      constraints: BoxConstraints(
        maxHeight: _isUnfolded
            ? _availableContentHeight * 0.12
            : double.infinity, // 폴더를 펼쳤을 때 최대 높이를 12%로 더 줄임
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: currentQuestion > 0 ? () => navigateQuestion(-1) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A2F3A),
              foregroundColor: const Color(0xFF00E5FF),
              elevation: 4,
              shape: const CircleBorder(),
              padding: EdgeInsets.all(_controlButtonSize * 0.25),
              fixedSize: Size(_controlButtonSize, _controlButtonSize),
              shadowColor: const Color(0xFF00E5FF).withOpacity(0.3),
              side: BorderSide(
                color: const Color(0xFF00E5FF).withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Icon(Icons.arrow_back_ios,
                color: const Color(0xFF00E5FF), size: _controlIconSize),
          ),
          Container(
            height: _playButtonSize,
            width: _playButtonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF2D95), Color(0xFF00E5FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF2D95).withOpacity(0.4),
                  blurRadius: _screenWidth * 0.025,
                  offset: Offset(0, _screenHeight * 0.005),
                ),
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.3),
                  blurRadius: _screenWidth * 0.015,
                  offset: Offset(0, _screenHeight * 0.003),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.volume_up,
                size: _playIconSize,
                color: Colors.white,
              ),
              onPressed: () => playAudio(currentQuestion),
            ),
          ),
          ElevatedButton(
            onPressed: currentQuestion < totalQuestions - 1
                ? () => navigateQuestion(1)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A2F3A),
              foregroundColor: const Color(0xFF00E5FF),
              elevation: 4,
              shape: const CircleBorder(),
              padding: EdgeInsets.all(_controlButtonSize * 0.25),
              fixedSize: Size(_controlButtonSize, _controlButtonSize),
              shadowColor: const Color(0xFF00E5FF).withOpacity(0.3),
              side: BorderSide(
                color: const Color(0xFF00E5FF).withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Icon(Icons.arrow_forward_ios,
                color: const Color(0xFF00E5FF), size: _controlIconSize),
          ),
        ],
      ),
    );
  }

  Widget buildBottomButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: _verticalSpacing, horizontal: _sectionPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (allAnswered && !isTestSubmitted)
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A2F3A),
                  padding: EdgeInsets.symmetric(
                      vertical: _bottomButtonHeight * 0.25),
                  minimumSize: Size(double.infinity, _bottomButtonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(_bottomButtonHeight * 0.5),
                  ),
                  elevation: 5,
                  shadowColor: const Color(0xFFFF2D95).withOpacity(0.5),
                  side: BorderSide(
                    color: const Color(0xFFFF2D95),
                    width: 2,
                  ),
                ),
                onPressed: showResultDialog,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    translations['submit'] ?? 'Submit',
                    style: GoogleFonts.poppins(
                      fontSize: _bottomButtonFontSize,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          if (allAnswered && !isTestSubmitted)
            SizedBox(width: _screenWidth * 0.025),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2F3A),
                padding:
                    EdgeInsets.symmetric(vertical: _bottomButtonHeight * 0.25),
                minimumSize: Size(double.infinity, _bottomButtonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(_bottomButtonHeight * 0.5),
                ),
                elevation: 3,
                shadowColor: const Color(0xFF00E5FF).withOpacity(0.3),
                side: BorderSide(
                    color: const Color(0xFF00E5FF),
                    width: 2),
              ),
              onPressed: initializeQuestions,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  translations['new_test'] ?? 'New Test',
                  style: GoogleFonts.poppins(
                    fontSize: _bottomButtonFontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF00E5FF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF0B0D13),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B0D13), Color(0xFF1A1D26)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF2D95), Color(0xFF00E5FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              translations['memory_test'] ?? 'Memory Test',
              style: GoogleFonts.poppins(
                fontSize: _appBarTitleSize,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0B0D13),
                  Color(0xFF1A1D26),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  SizedBox(height: _verticalSpacing),
                  buildQuestionIndicator(),
                  Expanded(
                    child: _isUnfolded
                        ? Column(
                            children: [
                              SizedBox(
                                  height:
                                      _verticalSpacing * 0.5), // 간격을 절반으로 줄임
                              // 사용 가능한 높이를 동적으로 계산하여 각 요소 크기 결정
                              _buildDynamicGrid(),
                              //SizedBox(height: _verticalSpacing),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                SizedBox(height: _verticalSpacing),
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  childAspectRatio: _gridChildAspectRatio,
                                  mainAxisSpacing: _gridSpacing,
                                  crossAxisSpacing: _gridSpacing,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: _gridHorizontalPadding),
                                  children: questionOptions[currentQuestion]
                                      .map((option) => buildOptionCard(option))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                  ),
                  buildControlButtons(),
                  buildBottomButtons(),
                ],
              ),
            ),
          ),
          if (_showTutorial) _buildTutorialOverlay(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    _animationController.dispose();
    super.dispose();
  }

  // Check if tutorial should be shown
  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final tutorialShown = prefs.getBool(_tutorialPrefKey) ?? false;

    setState(() {
      _showTutorial = !tutorialShown;
    });
  }

  // Save tutorial preference
  Future<void> _saveTutorialPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialPrefKey, true);
  }

  // Close tutorial overlay
  void _closeTutorial() {
    setState(() {
      _showTutorial = false;
    });

    if (_doNotShowAgain) {
      _saveTutorialPreference();
    }
  }

  // 동적 그리드 빌드 메서드
  Widget _buildDynamicGrid() {
    // buildQuestionIndicator와 buildControlButtons 사이의 사용 가능한 높이 계산
    // buildControlButtons의 실제 높이를 정확히 계산
    final controlButtonsHeight = _controlButtonSize + (_verticalSpacing * 2);
    final availableHeight = _availableContentHeight - controlButtonsHeight;

    // 컨테이너 높이를 사용 가능한 높이의 60%로 설정 (더 많은 여백 확보)
    final containerHeight = availableHeight * 0.7;

    // 그리드 아이템 크기 계산 (컨테이너 높이 기준)
    final gridSpacing = containerHeight * 0.04; // 간격은 컨테이너 높이의 4%
    const double epsilon = 4.0; // 라운딩 오차 방지를 위한 여유분
    final gridItemHeight = (containerHeight - gridSpacing - epsilon) / 2; // 2행
    final gridItemWidth =
        (_screenWidth - (_dynamicGridHorizontalPadding * 2) - gridSpacing) /
            2; // 2열

    return Container(
      // height 제거하여 필요한 만큼만 차지하도록 함
      child: Align(
        alignment: Alignment.topCenter, // 위쪽에서 시작, 좌우는 중앙
        child: Container(
          width: _screenWidth - (_dynamicGridHorizontalPadding * 2),
          height: containerHeight,
          decoration: BoxDecoration(
            // 컨테이너 스타일링
            border: Border.all(
              color: const Color(0xFF00E5FF).withOpacity(0.5), // 네온 시안 테두리
              width: 2, // 테두리 두께
            ),
            borderRadius: BorderRadius.circular(16), // 둥근 모서리
            color: const Color(0xFF1E2430).withOpacity(0.3), // 어두운 배경
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 첫 번째 행 (2개 이미지)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: gridItemWidth,
                    height: gridItemHeight,
                    child: buildOptionCard(questionOptions[currentQuestion][0]),
                  ),
                  SizedBox(
                    width: gridItemWidth,
                    height: gridItemHeight,
                    child: buildOptionCard(questionOptions[currentQuestion][1]),
                  ),
                ],
              ),
              SizedBox(height: gridSpacing),
              // 두 번째 행 (2개 이미지)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: gridItemWidth,
                    height: gridItemHeight,
                    child: buildOptionCard(questionOptions[currentQuestion][2]),
                  ),
                  SizedBox(
                    width: gridItemWidth,
                    height: gridItemHeight,
                    child: buildOptionCard(questionOptions[currentQuestion][3]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tutorial overlay
  Widget _buildTutorialOverlay() {
    return TestTutorialOverlay(
      isSmallScreen: _isSmallScreen,
      screenWidth: _screenWidth,
      screenHeight: _screenHeight,
      verticalSpacing: _verticalSpacing,
      dialogPadding: _dialogPadding,
      dialogWidth: _dialogWidth,
      dialogMaxHeight: _dialogMaxHeight,
      dialogBorderRadius: _dialogBorderRadius,
      tutorialIconSize: _tutorialIconSize,
      tutorialTitleSize: _tutorialTitleSize,
      tutorialDescSize: _tutorialDescSize,
      primaryColor: primaryColor,
      doNotShowAgain: _doNotShowAgain,
      onDoNotShowAgainChanged: (value) {
        setState(() {
          _doNotShowAgain = value ?? false;
        });
      },
      onClose: _closeTutorial,
      translations: translations,
    );
  }

  @override
  bool get wantKeepAlive => true;
}
