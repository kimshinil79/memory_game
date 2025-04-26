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
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, bgColorLight],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 80,
                  width: 80,
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
                    size: 40,
                    color: score > 7
                        ? Color(0xFFFFC107)
                        : score > 4
                            ? primaryColor
                            : accentColor,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  translations['test_result'] ?? 'Test Result',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  translations['your_score'] ?? 'Your score',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      ' / $totalQuestions',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      elevation: 4,
                      shadowColor: primaryColor.withOpacity(0.5),
                    ),
                    child: Text(
                      translations['continue'] ?? "Continue",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          totalQuestions,
          (index) => GestureDetector(
            onTap: () => goToQuestion(index),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: 28,
              height: 28,
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
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
                border: Border.all(
                  color: index == currentQuestion
                      ? Colors.transparent
                      : Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.poppins(
                    color: index == currentQuestion || isTestSubmitted
                        ? Colors.white
                        : Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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
    bool isCorrect =
        isTestSubmitted && option == correctAnswers[currentQuestion];
    bool isWrong = isTestSubmitted &&
        isSelected &&
        option != correctAnswers[currentQuestion];

    return GestureDetector(
      onTap: isTestSubmitted ? null : () => selectAnswer(option),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? isWrong
                    ? Color(0xFFFF5252)
                    : isCorrect
                        ? Color(0xFF4CAF50)
                        : primaryColor
                : isCorrect && isTestSubmitted
                    ? Color(0xFF4CAF50)
                    : Colors.transparent,
            width: 3,
          ),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/pictureDB_webp/$option.webp',
                  fit: BoxFit.cover,
                ),
              ),
              if (isTestSubmitted)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Color(0xFF4CAF50)
                          : isWrong
                              ? Color(0xFFFF5252)
                              : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCorrect
                          ? Icons.check
                          : isWrong
                              ? Icons.close
                              : null,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildControlButtons() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
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
              padding: EdgeInsets.all(16),
              shadowColor: Colors.black26,
            ),
            child: Icon(Icons.arrow_back_ios, color: primaryColor, size: 18),
          ),
          Container(
            height: 65,
            width: 65,
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
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.volume_up,
                size: 30,
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
              padding: EdgeInsets.all(16),
              shadowColor: Colors.black26,
            ),
            child: Icon(Icons.arrow_forward_ios, color: primaryColor, size: 18),
          ),
        ],
      ),
    );
  }

  Widget buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (allAnswered && !isTestSubmitted)
            Expanded(
              child: ElevatedButton(
                child: Text(
                  translations['submit'] ?? 'Submit',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                  shadowColor: primaryColor.withOpacity(0.5),
                ),
                onPressed: showResultDialog,
              ),
            ),
          if (allAnswered && !isTestSubmitted) SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              child: Text(
                translations['new_test'] ?? 'New Test',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 3,
                shadowColor: Colors.black.withOpacity(0.1),
                side:
                    BorderSide(color: primaryColor.withOpacity(0.5), width: 1),
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
        title: Text(
          translations['memory_test'] ?? 'Memory Test',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
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
                  SizedBox(height: 16),
                  buildQuestionIndicator(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            margin: EdgeInsets.only(top: 30, bottom: 10),
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: primaryColor,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "${translations['question'] ?? 'Question'} ${currentQuestion + 1}",
                                  style: GoogleFonts.poppins(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          GridView.count(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 1.1,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            padding: EdgeInsets.symmetric(horizontal: 20),
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
    return Container(
      color: Colors.black54,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.school,
                          color: primaryColor,
                          size: 30,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        translations['how_to_play'] ?? 'How to Play',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTutorialItem(
                        icon: Icons.quiz,
                        title: translations['visual_memory_test'] ??
                            'Visual Memory Test',
                        description: translations['visual_memory_test_desc'] ??
                            'Test your memory with 10 questions. Select the image that matches the correct word.',
                      ),
                      _buildTutorialItem(
                        icon: Icons.volume_up,
                        title: translations['audio_assistance'] ??
                            'Audio Assistance',
                        description: translations['audio_assistance_desc'] ??
                            'Tap the sound icon to hear the correct word. The audio plays in your selected language.',
                      ),
                      _buildTutorialItem(
                        icon: Icons.format_list_numbered,
                        title: translations['question_navigation'] ??
                            'Question Navigation',
                        description: translations['question_navigation_desc'] ??
                            'Use the number indicators at the top to navigate between questions or use the arrow buttons.',
                      ),
                      _buildTutorialItem(
                        icon: Icons.check_circle_outline,
                        title: translations['select_and_submit'] ??
                            'Select and Submit',
                        description: translations['select_and_submit_desc'] ??
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
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Transform.scale(
                        scale: 0.9,
                        child: Checkbox(
                          value: _doNotShowAgain,
                          onChanged: (value) {
                            setState(() {
                              _doNotShowAgain = value ?? false;
                            });
                          },
                          activeColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      Text(
                        translations['dont_show_again'] ?? 'Don\'t show again',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        elevation: 5,
                        shadowColor: primaryColor.withOpacity(0.5),
                      ),
                      child: Text(
                        translations['start_learning'] ?? 'Start Learning',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _closeTutorial,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
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
