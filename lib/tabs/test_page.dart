import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';
import '/item_list.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/rendering.dart';

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

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

  // Updated colors for a more refreshing and modern look
  final Color primaryColor = Color(0xFF5B86E5);
  final Color secondaryColor = Color(0xFF36D1DC);
  final Color accentColor = Color(0xFFFF9190);
  final Color bgColorLight = Color(0xFFF8FDFF);
  final Color bgColorDark = Color(0xFFEDF7FC);

  String _currentLanguage = '';

  // 언어 번역을 저장할 변수
  late Map<String, String> translations;

  // 화면 크기 기반 동적 크기 계산
  double get _screenWidth => MediaQuery.of(context).size.width;
  double get _screenHeight => MediaQuery.of(context).size.height;

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

  // 컨트롤 버튼 크기
  double get _controlButtonSize => _isSmallScreen
      ? _screenWidth * 0.12
      : _isMediumScreen
          ? _screenWidth * 0.13
          : _screenWidth * 0.14;

  double get _playButtonSize => _isSmallScreen
      ? _screenWidth * 0.16
      : _isMediumScreen
          ? _screenWidth * 0.17
          : _screenWidth * 0.18;

  double get _controlIconSize => _isSmallScreen
      ? _screenWidth * 0.045
      : _isMediumScreen
          ? _screenWidth * 0.048
          : _screenWidth * 0.05;

  double get _playIconSize => _isSmallScreen
      ? _screenWidth * 0.07
      : _isMediumScreen
          ? _screenWidth * 0.075
          : _screenWidth * 0.08;

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

  // 여백 및 간격
  double get _verticalSpacing => _screenHeight * 0.02;
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

  @override
  void initState() {
    super.initState();
    initializeQuestions();
    _loadLanguageAndInitTts();
    _checkTutorialStatus(); // Check if tutorial should be shown

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
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
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    String selectedLanguage = languageProvider.currentLanguage;
    await flutterTts.setLanguage(selectedLanguage);
    await flutterTts.setSpeechRate(0.5);
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

  String getLocalizedWord(String word) {
    final _currentLanguage =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage;

    switch (_currentLanguage) {
      case 'ko-KR':
        return korItemList[word] ?? word;
      case 'es-ES':
        return spaItemList[word] ?? word;
      case 'fr-FR':
        return fraItemList[word] ?? word;
      case 'de-DE':
        return deuItemList[word] ?? word;
      case 'ja-JP':
        return jpnItemList[word] ?? word;
      case 'zh-CN':
        return chnItemList[word] ?? word;
      case 'ru-RU':
        return rusItemList[word] ?? word;
      case 'it-IT':
        return itaItemList[word] ?? word;
      case 'pt-PT':
        return porItemList[word] ?? word;
      case 'ar-SA':
        return araItemList[word] ?? word;
      case 'tr-TR':
        return turItemList[word] ?? word;
      case 'vi-VN':
        return vieItemList[word] ?? word;
      case 'nl-NL':
        return dutItemList[word] ?? word;
      case 'pl-PL':
        return polItemList[word] ?? word;
      case 'cs-CZ':
        return czeItemList[word] ?? word;
      case 'hu-HU':
        return hunItemList[word] ?? word;
      default:
        return word; // 기본적으로 영어로 반환
    }
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _dialogWidth,
              maxHeight: _dialogMaxHeight,
            ),
            child: Container(
              padding: EdgeInsets.all(_dialogPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, bgColorLight],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(_dialogBorderRadius),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: _screenWidth * 0.2,
                    width: _screenWidth * 0.2,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      score > 7
                          ? Icons.emoji_events
                          : score > 4
                              ? Icons.thumb_up
                              : Icons.emoji_emotions,
                      size: _screenWidth * 0.1,
                      color: score > 7
                          ? Color(0xFFFFC107)
                          : score > 4
                              ? primaryColor
                              : accentColor,
                    ),
                  ),
                  SizedBox(height: _verticalSpacing),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      translations['test_result'] ?? 'Test Result',
                      style: GoogleFonts.poppins(
                        fontSize: _dialogTitleSize,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
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
                        color: Colors.black54,
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
                            color: primaryColor,
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
                            color: Colors.black45,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: _verticalSpacing),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(_dialogBorderRadius * 0.6),
                        ),
                        padding: EdgeInsets.symmetric(
                            vertical: _bottomButtonHeight * 0.25),
                        minimumSize: Size(double.infinity, _bottomButtonHeight),
                        elevation: 4,
                        shadowColor: primaryColor.withOpacity(0.5),
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
              duration: Duration(milliseconds: 300),
              width: _questionIndicatorSize,
              height: _questionIndicatorSize,
              decoration: BoxDecoration(
                color: index == currentQuestion
                    ? primaryColor
                    : isTestSubmitted
                        ? userAnswers[index] == correctAnswers[index]
                            ? Color(0xFF4CAF50)
                            : Color(0xFFFF5252)
                        : userAnswers[index] != null
                            ? Color(0xFFBBDEFB)
                            : Colors.white,
                borderRadius:
                    BorderRadius.circular(_questionIndicatorSize * 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: _screenWidth * 0.008,
                    offset: Offset(0, _screenHeight * 0.002),
                  ),
                ],
                border: Border.all(
                  color: index == currentQuestion
                      ? Colors.transparent
                      : Colors.grey.withOpacity(0.2),
                  width: _screenWidth * 0.003,
                ),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.poppins(
                      color: index == currentQuestion || isTestSubmitted
                          ? Colors.white
                          : Colors.black54,
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
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey.shade300,
                    width: 3,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/pictureDB_webp/$option.webp',
                    fit: BoxFit.contain,
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
      return Color(0xFF4CAF50); // Green for correct
    } else if (isWrong) {
      return Color(0xFFFF5252); // Red for wrong
    } else {
      return Colors
          .transparent; // No overlay for selected but not correct/wrong
    }
  }

  Widget buildControlButtons() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: _verticalSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: currentQuestion > 0 ? () => navigateQuestion(-1) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              elevation: 3,
              shape: CircleBorder(),
              padding: EdgeInsets.all(_controlButtonSize * 0.25),
              fixedSize: Size(_controlButtonSize, _controlButtonSize),
              shadowColor: Colors.black26,
            ),
            child: Icon(Icons.arrow_back_ios,
                color: primaryColor, size: _controlIconSize),
          ),
          Container(
            height: _playButtonSize,
            width: _playButtonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: _screenWidth * 0.025,
                  offset: Offset(0, _screenHeight * 0.005),
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
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              elevation: 3,
              shape: CircleBorder(),
              padding: EdgeInsets.all(_controlButtonSize * 0.25),
              fixedSize: Size(_controlButtonSize, _controlButtonSize),
              shadowColor: Colors.black26,
            ),
            child: Icon(Icons.arrow_forward_ios,
                color: primaryColor, size: _controlIconSize),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: EdgeInsets.symmetric(
                      vertical: _bottomButtonHeight * 0.25),
                  minimumSize: Size(double.infinity, _bottomButtonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(_bottomButtonHeight * 0.5),
                  ),
                  elevation: 5,
                  shadowColor: primaryColor.withOpacity(0.5),
                ),
                onPressed: showResultDialog,
              ),
            ),
          if (allAnswered && !isTestSubmitted)
            SizedBox(width: _screenWidth * 0.025),
          Expanded(
            child: ElevatedButton(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  translations['new_test'] ?? 'New Test',
                  style: GoogleFonts.poppins(
                    fontSize: _bottomButtonFontSize,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding:
                    EdgeInsets.symmetric(vertical: _bottomButtonHeight * 0.25),
                minimumSize: Size(double.infinity, _bottomButtonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(_bottomButtonHeight * 0.5),
                ),
                elevation: 3,
                shadowColor: Colors.black.withOpacity(0.1),
                side: BorderSide(
                    color: primaryColor.withOpacity(0.5),
                    width: _screenWidth * 0.003),
              ),
              onPressed: initializeQuestions,
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
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: FittedBox(
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
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  bgColorLight,
                  bgColorDark,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  SizedBox(height: _verticalSpacing),
                  buildQuestionIndicator(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: _verticalSpacing),
                          GridView.count(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
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
                          buildControlButtons(),
                        ],
                      ),
                    ),
                  ),
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

  // Tutorial overlay
  Widget _buildTutorialOverlay() {
    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            color: Colors.black54,
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: _dialogPadding, vertical: _dialogPadding * 2),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: _dialogWidth,
                      maxHeight: _dialogMaxHeight,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(_dialogBorderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(_dialogPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Transform.scale(
                                      scale: _isSmallScreen ? 0.8 : 0.9,
                                      child: Checkbox(
                                        value: _doNotShowAgain,
                                        onChanged: (value) {
                                          setState(() {
                                            _doNotShowAgain = value ?? false;
                                          });
                                        },
                                        activeColor: primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              _screenWidth * 0.008),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        translations['dont_show_again'] ??
                                            'Don\'t show again',
                                        style: GoogleFonts.poppins(
                                          fontSize: _tutorialDescSize,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.grey),
                                onPressed: _closeTutorial,
                              ),
                            ],
                          ),
                          SizedBox(height: _verticalSpacing),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(_screenWidth * 0.03),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.school,
                                  color: primaryColor,
                                  size: _tutorialIconSize,
                                ),
                              ),
                              SizedBox(width: _screenWidth * 0.03),
                              Expanded(
                                child: Text(
                                  translations['how_to_play'] ?? 'How to Play',
                                  style: GoogleFonts.poppins(
                                    fontSize: _tutorialTitleSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: _verticalSpacing),
                          _buildTutorialItem(
                            icon: Icons.quiz,
                            title: translations['visual_memory_test'] ??
                                'Visual Memory Test',
                            description: translations[
                                    'visual_memory_test_desc'] ??
                                'Test your memory with 10 questions. Select the image that matches the correct word.',
                          ),
                          _buildTutorialItem(
                            icon: Icons.volume_up,
                            title: translations['audio_assistance'] ??
                                'Audio Assistance',
                            description: translations[
                                    'audio_assistance_desc'] ??
                                'Tap the sound icon to hear the correct word. The audio plays in your selected language.',
                          ),
                          _buildTutorialItem(
                            icon: Icons.format_list_numbered,
                            title: translations['question_navigation'] ??
                                'Question Navigation',
                            description: translations[
                                    'question_navigation_desc'] ??
                                'Use the number indicators at the top to navigate between questions or use the arrow buttons.',
                          ),
                          _buildTutorialItem(
                            icon: Icons.check_circle_outline,
                            title: translations['select_and_submit'] ??
                                'Select and Submit',
                            description: translations[
                                    'select_and_submit_desc'] ??
                                'Select an image for each question. Once all questions are answered, the Submit button appears.',
                          ),
                          _buildTutorialItem(
                            icon: Icons.auto_graph,
                            title: translations['results_and_progress'] ??
                                'Results and Progress',
                            description: translations[
                                    'results_and_progress_desc'] ??
                                'After submitting, view your score and restart with a new test if desired.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Individual tutorial item
  Widget _buildTutorialItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: _verticalSpacing * 0.8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(_screenWidth * 0.02),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(_screenWidth * 0.025),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: _tutorialIconSize * 0.7,
            ),
          ),
          SizedBox(width: _screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: _tutorialTitleSize * 0.75,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: _screenHeight * 0.005),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: _tutorialDescSize,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
