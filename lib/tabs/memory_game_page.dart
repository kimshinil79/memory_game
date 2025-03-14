import 'package:flutter/material.dart';
import 'package:memory_game/widgets/star_animation.dart';
import '/item_list.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/brain_health_provider.dart';

class MemoryGamePage extends StatefulWidget {
  final int numberOfPlayers;
  final String gridSize;
  final Function(int) updateFlipCount;
  final Function(String, int) updatePlayerScore;
  final Function() nextPlayer;
  final String currentPlayer;
  final Map<String, int> playerScores;
  final Function() resetScores;
  final bool isTimeAttackMode;
  final int timeLimit;

  const MemoryGamePage({
    Key? key,
    required this.numberOfPlayers,
    required this.gridSize,
    required this.updateFlipCount,
    required this.updatePlayerScore,
    required this.nextPlayer,
    required this.currentPlayer,
    required this.playerScores,
    required this.resetScores,
    this.isTimeAttackMode = true,
    this.timeLimit = 60,
  }) : super(key: key);

  @override
  State<MemoryGamePage> createState() => _MemoryGamePageState();
}

class _MemoryGamePageState extends State<MemoryGamePage>
    with SingleTickerProviderStateMixin {
  List<bool> cardAnimationTriggers = [];

  bool isInitialized = false;
  bool hasError = false;

  int gridRows = 0;
  int gridColumns = 0;
  late int pairCount;
  late List<String> gameImages;
  List<bool> cardFlips = [];
  List<int> selectedCards = [];
  final AudioPlayer audioPlayer = AudioPlayer();
  final FlutterTts flutterTts = FlutterTts();
  int flipCount = 0;

  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  final Color instagramGradientStart = Color(0xFF833AB4);
  final Color instagramGradientEnd = Color(0xFFE1306C);

  //final translator = GoogleTranslator();
  String targetLanguage = 'en';

  Timer? _timer;
  int _remainingTime = 60; // 기본 남은 시간 설정
  bool isGameStarted = false;
  int _elapsedTime = 0; // 경과 시간을 저장할 변수 추가

  final Color timerNormalColor =
      Color.fromARGB(255, 84, 113, 230); // 기본 상태일 때 초록색
  final Color timerWarningColor =
      Color.fromARGB(255, 190, 60, 233); // 10초 미만일 때 주황색

  StreamSubscription<DocumentSnapshot>? _languageSubscription;

  int _gameTimeLimit = 60; // 기본 시간 제한 설정

  DateTime? _gameStartTime; // 게임 시작 시점을 기록할 변수

  @override
  void initState() {
    super.initState();

    // 기존 초기화 코드
    _loadUserLanguage();
    _initializeGameWrapper(); // 게임 초기화
    flutterTts.setLanguage("en-US");
    _subscribeToLanguageChanges();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _colorAnimation = ColorTween(
      begin: instagramGradientStart,
      end: instagramGradientEnd,
    ).animate(_animationController);

    _loadGameTimeLimit();
  }

  Future<void> _loadUserLanguage() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;
        // String emailPrefix = user.email!.split('@')[0];
        String documentId = uid; // uid만 사용

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(documentId)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          setState(() {
            targetLanguage =
                (userDoc.data() as Map<String, dynamic>)['language'] ?? 'ko';
          });
        }
      }
    } catch (e) {
      print("Failed to load user language: $e");
    }
  }

  void _subscribeToLanguageChanges() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      // String emailPrefix = user.email!.split('@')[0];
      String documentId = uid; // uid만 사용

      _languageSubscription?.cancel(); // 기존 구독이 있다면 취소
      _languageSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(documentId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          setState(() {
            targetLanguage =
                (snapshot.data() as Map<String, dynamic>)['language'] ?? 'ko';
          });
        }
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;

          // 경과 시간 업데이트
          if (_gameStartTime != null) {
            _elapsedTime = DateTime.now().difference(_gameStartTime!).inSeconds;
          }
        } else {
          _timer?.cancel();
          _showTimeUpDialog();
        }
      });
    });
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [instagramGradientStart, instagramGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Time's Up!",
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: instagramGradientStart,
                  ),
                  child: Text("Retry"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    initializeGame();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _languageSubscription?.cancel(); // null 체크 추가
    _timer?.cancel();
    audioPlayer.dispose();
    flutterTts.stop();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MemoryGamePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gridSize != oldWidget.gridSize) {
      _initializeGameWrapper();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageProvider = Provider.of<LanguageProvider>(context);
    if (targetLanguage != languageProvider.currentLanguage) {
      setState(() {
        targetLanguage = languageProvider.currentLanguage;
      });
    }
  }

  void _initializeGameWrapper() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await initializeGame();
      } catch (e) {
        print('Error initializing game: $e');
        setState(() {
          hasError = true;
        });
      }
    });
  }

  Future<void> initializeGame() async {
    // 타이머 취소 추가
    _timer?.cancel();

    setState(() {
      _remainingTime = _gameTimeLimit;
      isInitialized = false;
      hasError = false;
      isGameStarted = false; // 게임 시작 상태 초기화
      _elapsedTime = 0; // 경과 시간도 초기화
      _gameStartTime = null; // 게임 시작 시간 초기화
    });

    widget.resetScores();

    List<String> dimensions = widget.gridSize.split('x');
    gridRows = int.parse(dimensions[0]);
    gridColumns = int.parse(dimensions[1]);

    flipCount = 0;
    widget.updateFlipCount(flipCount);
    pairCount = (gridRows * gridColumns) ~/ 2;
    List<String> tempList = List<String>.from(itemList);
    tempList.shuffle();
    gameImages = tempList.take(pairCount).toList();
    gameImages = List<String>.from(gameImages)
      ..addAll(List<String>.from(gameImages));
    gameImages.shuffle();

    cardFlips = List.generate(gridRows * gridColumns, (_) => false);
    cardAnimationTriggers = List.generate(gridRows * gridColumns, (_) => false);
    selectedCards.clear();

    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      isInitialized = true;
    });
  }

  void _triggerStarAnimation(int index) {
    if (index >= 0 && index < cardAnimationTriggers.length) {
      setState(() {
        cardAnimationTriggers[index] = true;
      });
      Future.delayed(Duration(milliseconds: 1000), () {
        if (mounted && index < cardAnimationTriggers.length) {
          setState(() {
            cardAnimationTriggers[index] = false;
          });
        }
      });
    }
  }

  void onCardTap(int index) async {
    // 카드가 이미 뒤집혔거나, 두 카드가 선택된 상태면 리턴
    if (index >= gameImages.length ||
        cardFlips[index] ||
        selectedCards.length == 2) return;

    // 첫 번째 카드를 클릭할 때만 타이머 시작
    if (!isGameStarted && widget.isTimeAttackMode) {
      setState(() {
        isGameStarted = true;
        _remainingTime = _gameTimeLimit;
        _gameStartTime = DateTime.now(); // 게임 시작 시간 기록
      });
      _startTimer();
    }

    setState(() {
      cardFlips[index] = true;
      selectedCards.add(index);
      _triggerStarAnimation(index);
    });

    try {
      // korItemList에서 번역된 단어 가져오기
      final translatedWord = getLocalizedWord(gameImages[index]);
      print('translatedWord in onCardTap function: $translatedWord');

      // 번역된 텍스트 읽기
      print('targetLanguage in onCardTap function: $targetLanguage');
      await flutterTts.setLanguage(targetLanguage);
      await flutterTts.speak(translatedWord);
    } catch (e) {
      print('번역 또는 음성 재생 오류: $e');
    }

    if (selectedCards.length == 2) {
      flipCount++;
      widget.updateFlipCount(flipCount);
      Future.delayed(const Duration(milliseconds: 750), () {
        setState(() {
          checkMatch();
        });
      });
    }
  }

  void checkMatch() {
    setState(() {
      if (gameImages[selectedCards[0]] == gameImages[selectedCards[1]]) {
        widget.updatePlayerScore(widget.currentPlayer,
            widget.playerScores[widget.currentPlayer]! + 1);
        selectedCards.clear();

        // 모든 카드가 뒤집혔는지 확인
        if (cardFlips.every((flip) => flip)) {
          if (widget.isTimeAttackMode) {
            _timer?.cancel(); // 타이머 중지
            // 최종 경과 시간 계산
            if (_gameStartTime != null) {
              _elapsedTime =
                  DateTime.now().difference(_gameStartTime!).inSeconds;
            }
          }
          showWinnerDialog();
        }
      } else {
        for (var index in selectedCards) {
          cardFlips[index] = false;
        }
        selectedCards.clear();
        widget.nextPlayer();
      }
    });
  }

  void showWinnerDialog() {
    String winner = widget.playerScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // 게임 종료 시간 계산
    if (_gameStartTime != null) {
      _elapsedTime = DateTime.now().difference(_gameStartTime!).inSeconds;
      print('Game completed in: $_elapsedTime seconds'); // 디버깅용
    }

    // Brain Health Score update
    _updateBrainHealthScore(_elapsedTime);

    _showCompletionDialog(_elapsedTime);
  }

  Future<void> _updateBrainHealthScore(int elapsedTime) async {
    // 매치된 카드 쌍의 개수 계산
    final int totalMatches = gameImages.length ~/ 2;

    try {
      // Brain Health Provider에 게임 완료 정보 추가
      final brainHealthProvider =
          Provider.of<BrainHealthProvider>(context, listen: false);
      final int pointsEarned = await brainHealthProvider.addGameCompletion(
          totalMatches, elapsedTime);

      // 점수 획득 토스트 메시지 표시 (선택적)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You earned $pointsEarned Brain Health points!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating Brain Health score: $e');
    }
  }

  void _showCompletionDialog(int elapsedTime) {
    String languageCode =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    String gridSize = widget.gridSize; // 현재 그리드 크기

    // 게임 통계 업데이트
    _updateGameStatistics(languageCode, gridSize, elapsedTime, flipCount);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [instagramGradientStart, instagramGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Congratulations!",
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 24),
                if (widget.isTimeAttackMode) ...[
                  Text(
                    "Elapsed Time: ${elapsedTime} seconds",
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: instagramGradientStart,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(
                    "New Game",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    initializeGame();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTimeSettingDialog() {
    int selectedTime = _remainingTime;
    final TextEditingController timeController =
        TextEditingController(text: selectedTime.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Set Time',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 30),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF833AB4),
                            Color(0xFFF77737),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_drop_down,
                                color: Colors.white, size: 40),
                            onPressed: () {
                              setDialogState(() {
                                if (selectedTime > 10) {
                                  selectedTime -= 10;
                                  timeController.text = selectedTime.toString();
                                }
                              });
                            },
                          ),
                          SizedBox(width: 10),
                          InkWell(
                            onTap: () async {
                              // Show keyboard
                              FocusScope.of(context).requestFocus(FocusNode());
                              String? result = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                  content: Container(
                                    width: 300,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.white,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 20),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF833AB4),
                                                Color(0xFFF77737)
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(20)),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Enter Time',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
                                              24, 30, 24, 20),
                                          child: Column(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.05),
                                                      blurRadius: 10,
                                                      offset: Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: TextField(
                                                  controller: timeController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF833AB4),
                                                  ),
                                                  decoration: InputDecoration(
                                                    hintText: '10-300',
                                                    hintStyle: TextStyle(
                                                      color:
                                                          Colors.grey.shade400,
                                                      fontSize: 20,
                                                    ),
                                                    suffixText: 'seconds',
                                                    suffixStyle: TextStyle(
                                                      color: Color(0xFF833AB4),
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15),
                                                      borderSide:
                                                          BorderSide.none,
                                                    ),
                                                    filled: true,
                                                    fillColor:
                                                        Colors.grey.shade100,
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Please enter a value between 10-300 seconds',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
                                              24, 0, 24, 24),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  style: TextButton.styleFrom(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 12),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    backgroundColor:
                                                        Colors.grey.shade200,
                                                  ),
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade700,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: TextButton(
                                                  onPressed: () {
                                                    int? newTime = int.tryParse(
                                                        timeController.text);
                                                    if (newTime != null &&
                                                        newTime >= 10 &&
                                                        newTime <= 300) {
                                                      Navigator.pop(context,
                                                          timeController.text);
                                                    } else {
                                                      // Feedback for invalid input
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'Please enter a value between 10-300 seconds'),
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  style: TextButton.styleFrom(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 12),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    backgroundColor:
                                                        Color(0xFF833AB4),
                                                  ),
                                                  child: Text(
                                                    'Confirm',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );

                              if (result != null) {
                                int? newTime = int.tryParse(result);
                                if (newTime != null &&
                                    newTime >= 10 &&
                                    newTime <= 300) {
                                  setDialogState(() {
                                    selectedTime = newTime;
                                    timeController.text =
                                        selectedTime.toString();
                                  });
                                }
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$selectedTime sec',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.arrow_drop_up,
                                color: Colors.white, size: 40),
                            onPressed: () {
                              setDialogState(() {
                                if (selectedTime < 300) {
                                  selectedTime += 10;
                                  timeController.text = selectedTime.toString();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey[200],
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _remainingTime = selectedTime;
                              _gameTimeLimit = selectedTime;
                              if (!isGameStarted) {
                                _timer?.cancel();
                              }
                            });
                            SharedPreferences.getInstance().then((prefs) {
                              prefs.setInt('gameTimeLimit', selectedTime);
                            });
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF833AB4),
                                  Color(0xFFF77737),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Text(
                              'Confirm',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildScoreBoard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [instagramGradientStart, instagramGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              width: MediaQuery.of(context).size.width * 2 / 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: widget.playerScores.entries
                    .take(widget.numberOfPlayers)
                    .map((entry) {
                  return Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: entry.key == widget.currentPlayer
                            ? Colors.white.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (widget.isTimeAttackMode) ...[
            GestureDetector(
              onTap: isGameStarted ? null : _showTimeSettingDialog,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(2),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _remainingTime / _gameTimeLimit,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _remainingTime < 10
                            ? timerWarningColor
                            : timerNormalColor,
                      ),
                      strokeWidth: 4,
                    ),
                    Text(
                      '$_remainingTime',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _remainingTime < 10
                            ? timerWarningColor
                            : timerNormalColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildCard(int index) {
    if (index >= gameImages.length) {
      return SizedBox();
    }

    return StarAnimation(
      trigger: cardAnimationTriggers.isNotEmpty &&
              index < cardAnimationTriggers.length
          ? cardAnimationTriggers[index]
          : false,
      child: GestureDetector(
        onTap: () => onCardTap(index),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: cardFlips[index] ? Colors.white : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (!cardFlips[index])
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
            ],
          ),
          child: cardFlips[index]
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                              'assets/pictureDB/${gameImages[index]}.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Image.asset(
                    'assets/icon/memoryGame.png',
                    width: 40,
                    height: 40,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _loadGameTimeLimit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gameTimeLimit = prefs.getInt('gameTimeLimit') ?? 60;
      _remainingTime = _gameTimeLimit; // 남은 시간도 초기화
    });
  }

  String getLocalizedWord(String word) {
    final language =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    print('language in getLocalizedWord function: $language');

    switch (language) {
      case 'af-ZA':
        return afrikaansItemList[word] ?? word;
      case 'am-ET':
        return amharicItemList[word] ?? word;
      case 'zu-ZA':
        return zuluItemList[word] ?? word;
      case 'sw-KE':
        return swahiliItemList[word] ?? word;
      case 'hi-IN':
        return hindiItemList[word] ?? word;
      case 'bn-IN':
        return bengaliItemList[word] ?? word;
      case 'id-ID':
        return indonesianItemList[word] ?? word;
      case 'km-KH':
        return khmerItemList[word] ?? word;
      case 'ne-NP':
        return nepaliItemList[word] ?? word;
      case 'si-LK':
        return sinhalaItemList[word] ?? word;
      case 'th-TH':
        return thaiItemList[word] ?? word;
      case 'my-MM':
        return myanmarItemList[word] ?? word;
      case 'lo-LA':
        return laoItemList[word] ?? word;
      case 'fil-PH':
        return filipinoItemList[word] ?? word;
      case 'ms-MY':
        return malayItemList[word] ?? word;
      case 'jv-ID':
        return javaneseItemList[word] ?? word;
      case 'su-ID':
        return sundaneseItemList[word] ?? word;
      case 'ta-IN':
        return tamilItemList[word] ?? word;
      case 'te-IN':
        return teluguItemList[word] ?? word;
      case 'ml-IN':
        return malayalamItemList[word] ?? word;
      case 'gu-IN':
        return gujaratiItemList[word] ?? word;
      case 'kn-IN':
        return kannadaItemList[word] ?? word;
      case 'mr-IN':
        return marathiItemList[word] ?? word;
      case 'pa-IN':
        return punjabiItemList[word] ?? word;
      case 'ur-PK':
        return urduItemList[word] ?? word;
      case 'ur-IN':
        return urduItemList[word] ?? word;
      case 'ur-AR':
        return urduItemList[word] ?? word;
      case 'ur-SA':
        return urduItemList[word] ?? word;
      case 'ur-AE':
        return urduItemList[word] ?? word;
      case 'sv-SE':
        return swedishItemList[word] ?? word;
      case 'no-NO':
        return norwegianItemList[word] ?? word;
      case 'da-DK':
        return danishItemList[word] ?? word;
      case 'fi-FI':
        return finnishItemList[word] ?? word;
      case 'nb-NO':
        return norwegianItemList[word] ?? word;
      case 'bg-BG':
        return bulgarianItemList[word] ?? word;
      case 'el-GR':
        return greekItemList[word] ?? word;
      case 'ro-RO':
        return romanianItemList[word] ?? word;
      case 'sk-SK':
        return slovakItemList[word] ?? word;
      case 'uk-UA':
        return ukrainianItemList[word] ?? word;
      case 'hr-HR':
        return croatianItemList[word] ?? word;
      case 'sl-SI':
        return slovenianItemList[word] ?? word;
      case 'fa-IR':
        return persianItemList[word] ?? word;
      case 'he-IL':
        return hebrewItemList[word] ?? word;
      case 'mn-MN':
        return mongolianItemList[word] ?? word;
      case 'sq-AL':
        return albanianItemList[word] ?? word;
      case 'sr-RS':
        return serbianItemList[word] ?? word;
      case 'uz-UZ':
        return uzbekItemList[word] ?? word;

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
        return word; // 기본적으로 영어
    }
  }

  Future<void> _updateGameStatistics(
      String languageCode, String gridSize, int timeTaken, int flips) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // String emailPrefix = user.email!.split('@')[0];
      // String documentId = '$emailPrefix${user.uid}';
      String documentId = user.uid; // uid만 사용

      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(documentId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userDoc);

        if (!snapshot.exists) {
          transaction.set(userDoc, {
            'statistics': {
              languageCode: {
                'memory_game': {
                  'total_games': 1,
                  'avg_time': timeTaken.toDouble(),
                  'avg_flips': flips.toDouble(),
                  'grid_stats': {
                    gridSize: {
                      'avg_time': timeTaken.toDouble(),
                      'avg_flips': flips.toDouble(),
                      'total_games': 1
                    }
                  }
                }
              }
            }
          });
        } else {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          Map<String, dynamic> stats = data['statistics'] ?? {};
          Map<String, dynamic> langStats = stats[languageCode] ?? {};
          Map<String, dynamic> memoryStats = langStats['memory_game'] ?? {};
          Map<String, dynamic> gridStats = memoryStats['grid_stats'] ?? {};

          int totalGames = (memoryStats['total_games'] ?? 0) + 1;
          double totalTime =
              (memoryStats['avg_time'] ?? 0.0) * (totalGames - 1) + timeTaken;
          double totalFlips =
              (memoryStats['avg_flips'] ?? 0.0) * (totalGames - 1) + flips;

          Map<String, dynamic> currentGridStats = gridStats[gridSize] ?? {};
          int gridTotalGames = (currentGridStats['total_games'] ?? 0) + 1;
          double gridTotalTime =
              (currentGridStats['avg_time'] ?? 0.0) * (gridTotalGames - 1) +
                  timeTaken;
          double gridTotalFlips =
              (currentGridStats['avg_flips'] ?? 0.0) * (gridTotalGames - 1) +
                  flips;

          transaction.update(userDoc, {
            'statistics.$languageCode.memory_game.total_games': totalGames,
            'statistics.$languageCode.memory_game.avg_time':
                totalTime / totalGames,
            'statistics.$languageCode.memory_game.avg_flips':
                totalFlips / totalGames,
            'statistics.$languageCode.memory_game.grid_stats.$gridSize.total_games':
                gridTotalGames,
            'statistics.$languageCode.memory_game.grid_stats.$gridSize.avg_time':
                gridTotalTime / gridTotalGames,
            'statistics.$languageCode.memory_game.grid_stats.$gridSize.avg_flips':
                gridTotalFlips / gridTotalGames,
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return Center(child: Text('게임 초기화 중 오류가 발생했습니다. 다시 시도해 주세요.'));
    }

    if (!isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5F7FA), // 밝은 회색빛 하얀색
              Color(0xFFE3E6E8), // 은은한 회색
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await initializeGame();
            },
            child: Column(
              children: [
                buildScoreBoard(),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(0), // 카드 주변 여백
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: int.parse(widget.gridSize.split('x')[1]),
                      crossAxisSpacing: 0, // 가로 방향 카드 간격
                      mainAxisSpacing: 0, // 세로 방향 카드 간격
                    ),
                    itemCount: gameImages.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => onCardTap(index),
                        child: Card(
                          elevation: 4, // 그림자 효과 추가
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // 모서리 둥글게
                          ),
                          key: ValueKey(index),
                          color: Colors.white,
                          child: Center(
                            child: cardFlips[index]
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      'assets/pictureDB/${gameImages[index]}.jpg',
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/icon/memoryGame.png',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
