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
import '../utils/route_observer.dart';
import 'package:flutter/rendering.dart';
import 'package:flag/flag.dart';

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
  final GlobalKey<_MemoryGamePageState> _stateKey =
      GlobalKey<_MemoryGamePageState>();
  final bool isMultiplayerMode;
  final String? gameId;
  final String? myPlayerId;

  MemoryGamePage({
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
    this.isMultiplayerMode = false,
    this.gameId,
    this.myPlayerId,
  }) : super(key: key ?? GlobalKey<State<MemoryGamePage>>());

  // Added methods to be called from main.dart
  double getRemainingTimeRatio() {
    return _stateKey.currentState?.getRemainingTimeRatio() ?? 1.0;
  }

  bool isTimeLow() {
    return _stateKey.currentState?.isTimeLow() ?? false;
  }

  bool isGameStarted() {
    return true;
  }

  void addExtraTime() {
    _stateKey.currentState?._addExtraTime();
  }

  // 탭이 보이게 될 때 호출되는 메서드
  void onTabVisible() {
    _stateKey.currentState?.onTabVisible();
  }

  // 탭이 보이지 않게 될 때 호출되는 메서드
  void onTabInvisible() {
    _stateKey.currentState?.onTabInvisible();
  }

  @override
  State<MemoryGamePage> createState() => _MemoryGamePageState();
}

class _MemoryGamePageState extends State<MemoryGamePage>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        TabNavigationObserver,
        AutomaticKeepAliveClientMixin {
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

  // 멀티플레이어 모드 관련 변수
  bool get isMultiplayerMode => widget.isMultiplayerMode;
  String? get gameId => widget.gameId;
  String? get myPlayerId => widget.myPlayerId;
  String? _opponentId;
  String? _opponentNickname;
  String? _myNickname;
  bool _isMyTurn = false;
  StreamSubscription<DocumentSnapshot>? _gameSubscription;
  String _currentTurn = '';

  // 튜토리얼 관련 변수
  bool _showTutorial = false;
  bool _doNotShowAgain = false;
  final String _tutorialPrefKey = 'memory_game_tutorial_shown';

  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  final Color instagramGradientStart = Color(0xFF833AB4);
  final Color instagramGradientEnd = Color(0xFFF77737);

  //final translator = GoogleTranslator();
  String targetLanguage = 'en';

  Timer? _timer;
  int _remainingTime = 60; // 기본 남은 시간 설정
  bool isGameStarted = false;
  int _elapsedTime = 0; // 경과 시간을 저장할 변수 추가
  bool _isTimerPaused = false; // 타이머 일시정지 상태 추적
  DateTime? _pauseTime; // 일시정지된 시간 기록

  final Color timerNormalColor =
      Color.fromARGB(255, 84, 113, 230); // 기본 상태일 때 초록색
  final Color timerWarningColor =
      Color.fromARGB(255, 190, 60, 233); // 10초 미만일 때 주황색

  StreamSubscription<DocumentSnapshot>? _languageSubscription;

  int _gameTimeLimit = 60; // 기본 시간 제한 설정

  // 시간 추가 버튼의 쿨다운 관리
  bool _canAddTime = true;
  int _timeAddCost = 5; // 시간 추가 시 차감되는 Brain Health 점수
  int _timeAddMinElapsed = 30; // 시간 추가 버튼이 활성화되기 위한 최소 경과 시간(초)

  DateTime? _gameStartTime; // 게임 시작 시점을 기록할 변수

  // 탭 활성화 상태 추적
  bool _isTabActive = true;

  @override
  void initState() {
    super.initState();

    // 기존 초기화 코드
    _loadUserLanguage();
    _checkTutorialStatus(); // 튜토리얼 표시 여부 확인
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

    // 멀티플레이어 모드일 경우 추가 초기화
    if (widget.isMultiplayerMode && widget.gameId != null) {
      _loadMultiplayerData();
      _subscribeToGameState();
    }

    // 앱 생명주기 관찰자 등록
    WidgetsBinding.instance.addObserver(this);
  }

  // 앱 생명주기 변경 처리
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 활성화될 때
    if (state == AppLifecycleState.resumed) {
      _onTabVisible(true);
    }
    // 앱이 비활성화될 때
    else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _onTabVisible(false);
    }
  }

  // 탭 가시성 변경 처리
  void _onTabVisible(bool visible) {
    if (!mounted) return;

    setState(() {
      _isTabActive = visible;

      // 탭이 보이지 않게 되면 타이머 일시 정지
      if (!visible && isGameStarted && _timer != null) {
        _pauseTimer();
      }
      // 탭이 다시 보이면 타이머 재개
      else if (visible && isGameStarted && _isTimerPaused) {
        _resumeTimer();
      }
    });
  }

  // 타이머 일시정지
  void _pauseTimer() {
    if (_timer != null && !_isTimerPaused) {
      _timer!.cancel();
      _isTimerPaused = true;
      _pauseTime = DateTime.now();
    }
  }

  // 타이머 재개
  void _resumeTimer() {
    if (_isTimerPaused) {
      _isTimerPaused = false;
      _startTimer();

      // 게임 시작 시간 조정 (경과 시간 계산에 사용됨)
      if (_gameStartTime != null && _pauseTime != null) {
        Duration pauseDuration = DateTime.now().difference(_pauseTime!);
        _gameStartTime = _gameStartTime!.add(pauseDuration);
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      // 탭이 활성화되지 않았으면 타이머를 진행하지 않음
      if (!_isTabActive) {
        return;
      }

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

    // Ensure the UI updates immediately when the timer starts
    if (mounted) {
      setState(() {
        isGameStarted = true;
      });
    }
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

  // 멀티플레이어 게임 데이터 로드
  Future<void> _loadMultiplayerData() async {
    if (!widget.isMultiplayerMode ||
        widget.gameId == null ||
        widget.myPlayerId == null) return;

    try {
      // 게임 세션 정보 가져오기
      DocumentSnapshot gameDoc = await FirebaseFirestore.instance
          .collection('game_sessions')
          .doc(widget.gameId)
          .get();

      if (gameDoc.exists && gameDoc.data() != null) {
        Map<String, dynamic> gameData = gameDoc.data() as Map<String, dynamic>;

        // 플레이어 정보 설정
        // 플레이어 정보 설정 - 데이터 구조에 따라 적절하게 변경
        if (gameData.containsKey('player1') &&
            gameData.containsKey('player2')) {
          // 새로운 데이터 구조 (player1, player2 객체)
          Map<String, dynamic> player1 = gameData['player1'] ?? {};
          Map<String, dynamic> player2 = gameData['player2'] ?? {};

          String player1Id = player1['id'] ?? '';
          String player2Id = player2['id'] ?? '';

          setState(() {
            // 상대방 ID 설정
            _opponentId =
                player1Id == widget.myPlayerId ? player2Id : player1Id;

            // 닉네임 설정
            _myNickname = player1Id == widget.myPlayerId
                ? player1['nickname'] ?? 'Player 1'
                : player2['nickname'] ?? 'Player 2';

            _opponentNickname = player1Id == widget.myPlayerId
                ? player2['nickname'] ?? 'Player 2'
                : player1['nickname'] ?? 'Player 1';

            // 현재 턴 설정
            _currentTurn = gameData['currentTurn'] ?? player1Id;
            _isMyTurn = _currentTurn == widget.myPlayerId;
          });
        } else {
          // 기존 데이터 구조 (player1Id, player2Id)
          String player1Id = gameData['player1Id'] ?? '';
          String player2Id = gameData['player2Id'] ?? '';

          setState(() {
            // 상대방 ID 설정
            _opponentId =
                player1Id == widget.myPlayerId ? player2Id : player1Id;

            // 닉네임 설정
            _myNickname = player1Id == widget.myPlayerId
                ? gameData['player1Nickname'] ?? 'Player 1'
                : gameData['player2Nickname'] ?? 'Player 2';

            _opponentNickname = player1Id == widget.myPlayerId
                ? gameData['player2Nickname'] ?? 'Player 2'
                : gameData['player1Nickname'] ?? 'Player 1';

            // 현재 턴 설정
            _currentTurn = gameData['currentTurn'] ?? player1Id;
            _isMyTurn = _currentTurn == widget.myPlayerId;
          });
        }

        // 디버그 정보 출력
        print(
            '멀티플레이어 게임 로드: 내 ID=${widget.myPlayerId}, 턴=${_currentTurn}, 내 턴=${_isMyTurn}');
      }
    } catch (e) {
      print('멀티플레이어 게임 데이터 로드 오류: $e');
    }
  }

  // Firestore에서 게임 상태 구독
  void _subscribeToGameState() {
    if (!widget.isMultiplayerMode || widget.gameId == null) {
      print('게임 상태 구독 불가: 멀티플레이어가 아니거나 게임 ID가 없음');
      return;
    }

    // 디버그 정보 출력
    print('게임 상태 구독 시작: 게임 ID=${widget.gameId}');

    // 기존 구독 취소
    _gameSubscription?.cancel();

    _gameSubscription = FirebaseFirestore.instance
        .collection('game_sessions')
        .doc(widget.gameId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        Map<String, dynamic> gameData = snapshot.data() as Map<String, dynamic>;

        // 마지막 업데이트 시간 출력 (있는 경우)
        if (gameData.containsKey('lastUpdated') &&
            gameData['lastUpdated'] != null) {
          print('Firestore 데이터 수신: lastUpdated=${gameData['lastUpdated']}');
        } else {
          print('Firestore 데이터 수신: 타임스탬프 정보 없음');
        }

        // UI 업데이트를 즉시 실행하여 지연 시간 최소화
        if (mounted) {
          // 중요: 상태 업데이트를 메인 스레드에서 즉시 처리
          setState(() {
            _updateGameStateFromFirestore(gameData);
          });
        }
      } else {
        print('경고: 게임 데이터가 없거나 삭제됨 - gameId=${widget.gameId}');
      }
    }, onError: (error) {
      print('게임 상태 구독 오류: $error');

      // 오류 발생 시 UI에 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error. Please check your network.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // 오류 후 재연결 시도 - 5초 후 다시 구독 시도
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) {
          print('재연결 시도 중...');
          _subscribeToGameState();
        }
      });
    });
  }

  // Firestore 데이터로 게임 상태 업데이트
  void _updateGameStateFromFirestore(Map<String, dynamic> gameData) {
    try {
      // 직접 호출 시 마운트되지 않은 상태일 수 있으므로 확인
      if (!mounted) return;

      // 디버그 정보 출력
      print(
          '게임 상태 업데이트 시작: gameId=${widget.gameId}, myId=${widget.myPlayerId}');
      print('업데이트 시간: ${DateTime.now().toIso8601String()}');

      // 플레이어 정보 가져오기
      Map<String, dynamic> player1 = gameData['player1'] ?? {};
      Map<String, dynamic> player2 = gameData['player2'] ?? {};
      String player1Id = player1['id'] ?? '';
      String player2Id = player2['id'] ?? '';

      // 현재 턴 업데이트
      String currentTurn = gameData['currentTurn'] ?? '';
      bool previousTurn = _isMyTurn; // 이전 턴 상태 저장
      _isMyTurn = currentTurn == widget.myPlayerId;
      _currentTurn = currentTurn;

      // 턴이 변경되었으면 알림
      if (previousTurn != _isMyTurn && mounted) {
        if (_isMyTurn) {
          // 시각적, 청각적 피드백 추가
          _animationController.forward(from: 0);
          // 오디오 플레이 - 호환성 이슈로 제거
          // audioPlayer.play(AssetSource('sounds/notification.mp3'), volume: 0.5);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Your turn now!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }

      // 상대방 정보 설정
      _opponentId = player1Id == widget.myPlayerId ? player2Id : player1Id;
      _myNickname = player1Id == widget.myPlayerId
          ? player1['nickname'] ?? 'Player 1'
          : player2['nickname'] ?? 'Player 2';
      _opponentNickname = player1Id == widget.myPlayerId
          ? player2['nickname'] ?? 'Player 2'
          : player1['nickname'] ?? 'Player 1';

      // 게임 보드 상태 업데이트
      if (gameData.containsKey('board') && gameData['board'] is List) {
        List<dynamic> boardData = gameData['board'];

        // 디버그 정보 - 보드 데이터 크기 확인
        print(
            '보드 데이터 크기: ${boardData.length}, 카드 플립 크기: ${cardFlips.length}, 게임 이미지 크기: ${gameImages.length}');

        // 게임 이미지 리스트 업데이트 (중요!)
        // 항상 서버에서 최신 이미지 ID 목록 가져오기
        if (gameImages.isEmpty || gameImages.length != boardData.length) {
          gameImages = List.generate(boardData.length, (index) {
            if (index < boardData.length && boardData[index] is Map) {
              Map<String, dynamic> cardData =
                  boardData[index] as Map<String, dynamic>;
              return cardData['imageId'] as String? ?? 'default';
            }
            return 'default';
          });
          print('게임 이미지 리스트 업데이트됨: ${gameImages.length}개');
        }

        // 보드 데이터가 cardFlips 보다 많으면 cardFlips 크기 조정
        if (boardData.length > cardFlips.length) {
          cardFlips = List.generate(boardData.length,
              (i) => i < cardFlips.length ? cardFlips[i] : false);
          cardAnimationTriggers = List.generate(
              boardData.length,
              (i) => i < cardAnimationTriggers.length
                  ? cardAnimationTriggers[i]
                  : false);

          print('카드 플립 배열 크기 조정됨: ${cardFlips.length}개');
        }

        // 카드 상태 변경 여부 플래그
        bool hasCardStateChanged = false;

        // 카드 상태 업데이트
        for (int i = 0; i < boardData.length && i < cardFlips.length; i++) {
          if (boardData[i] is Map) {
            Map<String, dynamic> cardData =
                boardData[i] as Map<String, dynamic>;

            // 이전 상태와 다를 경우에만 업데이트하여 불필요한 렌더링 방지
            bool newFlipState = cardData['isFlipped'] ?? false;

            // 카드 상태가 변경되었으면 디버그 정보 출력
            if (cardFlips[i] != newFlipState) {
              print(
                  '카드 $i 상태 변경: ${cardFlips[i]} -> $newFlipState, lastFlippedBy=${cardData['lastFlippedBy']}');

              hasCardStateChanged = true;
              cardFlips[i] = newFlipState;

              // 상대방이 카드를 뒤집었을 때 애니메이션 효과 추가
              // null-safety 처리 추가
              String? lastFlippedBy = cardData['lastFlippedBy'] as String?;
              if (newFlipState &&
                  !selectedCards.contains(i) &&
                  lastFlippedBy != null &&
                  lastFlippedBy != widget.myPlayerId) {
                _triggerStarAnimation(i);

                // 애니메이션 및 소리 효과
                // audioPlayer.play(AssetSource('sounds/card_flip.mp3'), volume: 0.3);

                // 디버그 - 애니메이션 트리거됨
                print('카드 $i에 애니메이션 트리거 - 상대방이 뒤집음');
              }

              // 상대방이 뒤집은 카드를 selectedCards에 추가
              if (newFlipState && !selectedCards.contains(i)) {
                // 이미 매치된 카드는 selectedCards에 추가하지 않음
                if (cardData['matchedBy'] == null) {
                  selectedCards.add(i);
                  print('카드 $i를 selectedCards에 추가: $selectedCards');

                  // 두 카드가 선택되면 매치 여부 확인
                  if (selectedCards.length == 2) {
                    // 이미 Firestore에서 매치 결과가 처리되므로
                    // 여기서는 UI 업데이트를 위한 로직만 실행
                    flipCount++;
                    widget.updateFlipCount(flipCount);
                  }
                }
              }
            }

            // 매치된 카드 정보 업데이트 - null-safety 처리 추가
            var matchedByValue = cardData['matchedBy'];
            // matchedBy가 존재하고 빈 문자열이 아닌 경우에만 처리
            if (matchedByValue != null &&
                matchedByValue is String &&
                matchedByValue.isNotEmpty) {
              // 매치된 카드는 계속 뒤집힌 상태로 유지
              if (!cardFlips[i]) {
                print('매치된 카드 $i 강제 뒤집기: matchedBy=$matchedByValue');
                cardFlips[i] = true;
                hasCardStateChanged = true;
              }
            }
          }
        }

        // 카드 상태가 변경되었으면 UI 새로고침 강제
        if (hasCardStateChanged && mounted) {
          print('카드 상태 변경되어 UI 리프레시 강제');
        }
      } else {
        print('경고: 게임 데이터에 보드 정보가 없거나 형식이 잘못됨');
      }

      // 점수 업데이트
      int player1Score = player1['score'] ?? 0;
      int player2Score = player2['score'] ?? 0;

      if (widget.myPlayerId == player1Id) {
        widget.updatePlayerScore(widget.currentPlayer, player1Score);
        widget.updatePlayerScore(
            widget.playerScores.keys.elementAt(1), player2Score);
      } else {
        widget.updatePlayerScore(widget.currentPlayer, player2Score);
        widget.updatePlayerScore(
            widget.playerScores.keys.elementAt(1), player1Score);
      }

      // 매치 결과 처리 (불일치인 경우 카드 다시 뒤집기)
      if (gameData.containsKey('lastAction') && gameData['lastAction'] is Map) {
        Map<String, dynamic> lastAction = gameData['lastAction'];
        String actionType = lastAction['type'] ?? '';

        // 액션 정보 출력
        print('마지막 액션: $actionType, 플레이어: ${lastAction['playerId']}');

        if (actionType == 'mismatch' && lastAction.containsKey('cards')) {
          List<dynamic> mismatchedCards = lastAction['cards'];
          print('불일치 카드: $mismatchedCards');

          // 약간의 지연 후에 불일치 카드 뒤집기
          if (mismatchedCards.length == 2) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {
                  for (var index in mismatchedCards) {
                    if (index is int && index < cardFlips.length) {
                      print('불일치 카드 다시 뒤집기: $index');
                      cardFlips[index] = false;
                    }
                  }
                  selectedCards.clear();
                  print('selectedCards 초기화');
                });
              }
            });
          }
        } else if (actionType == 'match' && lastAction.containsKey('cards')) {
          List<dynamic> matchedCards = lastAction['cards'];
          print('일치 카드: $matchedCards');

          // 매치 성공 효과음
          // if (lastAction['playerId'] != widget.myPlayerId) {
          //   audioPlayer.play(AssetSource('sounds/match_success.mp3'), volume: 0.3);
          // }

          // 매치 성공 시 selectedCards 초기화
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                selectedCards.clear();
                print('일치 후 selectedCards 초기화');
              });
            }
          });
        }
      }

      // 게임 종료 체크
      if (gameData['gameState'] == 'completed' &&
          cardFlips.every((flip) => flip)) {
        _timer?.cancel(); // 타이머 중지
        if (_gameStartTime != null) {
          _elapsedTime = DateTime.now().difference(_gameStartTime!).inSeconds;
        }

        // 게임 완료 다이얼로그 표시
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            _showMultiplayerGameCompleteDialog();
          }
        });
      }
    } catch (e) {
      // 예기치 않은 오류 처리
      print('게임 상태 업데이트 중 오류: $e');
    }
  }

  // 멀티플레이어 모드에서 카드 상태 Firestore에 업데이트
  Future<void> _updateCardStateInFirestore(int index, bool flipped) async {
    if (!widget.isMultiplayerMode ||
        widget.gameId == null ||
        widget.myPlayerId == null) {
      print('카드 상태 업데이트 불가: 멀티플레이어 모드가 아니거나 유효하지 않은 ID');
      return;
    }

    try {
      // 디버그 정보 상세화
      final requestTime = DateTime.now().toIso8601String();
      print(
          '카드 $index 상태 업데이트 시작 [시간: $requestTime]: flipped=$flipped, player=${widget.myPlayerId}');

      // 즉시 로컬 UI에도 반영 (Firebase 업데이트 대기 없이)
      if (mounted) {
        setState(() {
          // 로컬 UI 먼저 업데이트
          if (index < cardFlips.length) {
            cardFlips[index] = flipped;
            print('로컬 카드 상태 즉시 업데이트: 카드 $index -> $flipped');
          }
        });
      }

      // 현재 게임 데이터를 가져와서 board 내의 해당 카드 정보를 유지하면서 업데이트
      DocumentSnapshot gameDoc = await FirebaseFirestore.instance
          .collection('game_sessions')
          .doc(widget.gameId)
          .get();

      if (gameDoc.exists && gameDoc.data() != null) {
        Map<String, dynamic> gameData = gameDoc.data() as Map<String, dynamic>;
        if (gameData.containsKey('board') && gameData['board'] is List) {
          List<dynamic> boardData =
              List.from(gameData['board'] as List<dynamic>);

          // 카드 인덱스가 유효한지 확인
          if (index < boardData.length && boardData[index] is Map) {
            // 기존 카드 데이터 유지하면서 isFlipped와 lastFlippedBy만 업데이트
            Map<String, dynamic> cardData =
                Map.from(boardData[index] as Map<String, dynamic>);
            cardData['isFlipped'] = flipped;
            cardData['lastFlippedBy'] = widget.myPlayerId;

            // 보드 배열 업데이트
            boardData[index] = cardData;

            // 업데이트할 데이터 준비 - 전체 보드 배열을 업데이트
            Map<String, dynamic> updateData = {
              'board': boardData,
              'lastMoveTime': FieldValue.serverTimestamp(),
              'lastAction': {
                'type': 'flip',
                'cardIndex': index,
                'playerId': widget.myPlayerId,
                'timestamp': FieldValue.serverTimestamp(),
              },
              'lastUpdated': FieldValue.serverTimestamp(),
            };

            // Firebase에 업데이트 - 배치 모드로 실행
            await FirebaseFirestore.instance
                .collection('game_sessions')
                .doc(widget.gameId)
                .update(updateData);

            final responseTime = DateTime.now().toIso8601String();
            print('카드 $index 상태 업데이트 완료 [시간: $responseTime]');
          } else {
            print('오류: 카드 인덱스 $index가 유효하지 않습니다. 보드 크기: ${boardData.length}');
            throw Exception('유효하지 않은 카드 인덱스');
          }
        } else {
          print('오류: 게임 데이터에 보드 정보가 없거나 유효하지 않습니다');
          throw Exception('보드 데이터가 유효하지 않습니다');
        }
      } else {
        print('오류: 게임 데이터를 찾을 수 없습니다');
        throw Exception('게임 데이터를 찾을 수 없습니다');
      }

      // 업데이트 후 확인 (선택 사항 - 디버깅을 위한 용도)
      DocumentSnapshot updatedDoc = await FirebaseFirestore.instance
          .collection('game_sessions')
          .doc(widget.gameId)
          .get();

      if (updatedDoc.exists && updatedDoc.data() != null) {
        Map<String, dynamic> data = updatedDoc.data() as Map<String, dynamic>;
        if (data.containsKey('board') && data['board'] is List) {
          List<dynamic> board = data['board'];
          if (index < board.length && board[index] is Map) {
            Map<String, dynamic> card = board[index];
            bool currentState = card['isFlipped'] ?? false;
            String? lastFlippedBy = card['lastFlippedBy'] as String?;
            String? imageId = card['imageId'] as String?;

            print(
                '확인: 카드 $index 현재 상태 = $currentState, 마지막 플레이어 = $lastFlippedBy, imageId = $imageId');

            // 서버 상태와 로컬 상태가 일치하는지 확인
            if (currentState != cardFlips[index]) {
              print(
                  '경고: 서버-로컬 상태 불일치! 로컬=${cardFlips[index]}, 서버=$currentState');

              // 불일치하면 서버 상태로 강제 업데이트
              if (mounted) {
                setState(() {
                  cardFlips[index] = currentState;
                  print('로컬 상태를 서버 상태로 동기화: 카드 $index -> $currentState');
                });
              }
            }
          }
        }
      }
    } catch (e) {
      print('카드 상태 업데이트 오류: $e');

      // 오류 시 UI에 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('카드 상태 업데이트 중 오류가 발생했습니다. 다시 시도하세요.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // 멀티플레이어 모드에서 매치된 카드 업데이트 및 턴 변경
  Future<void> _updateMatchInFirestore(bool isMatch) async {
    if (!widget.isMultiplayerMode ||
        widget.gameId == null ||
        widget.myPlayerId == null ||
        selectedCards.length != 2) return;

    try {
      DocumentSnapshot gameDoc = await FirebaseFirestore.instance
          .collection('game_sessions')
          .doc(widget.gameId)
          .get();

      if (gameDoc.exists && gameDoc.data() != null) {
        Map<String, dynamic> gameData = gameDoc.data() as Map<String, dynamic>;

        // 플레이어 정보 가져오기
        Map<String, dynamic> player1 = gameData['player1'] ?? {};
        Map<String, dynamic> player2 = gameData['player2'] ?? {};
        String player1Id = player1['id'] ?? '';
        String player2Id = player2['id'] ?? '';

        // 현재 플레이어의 ID 및 점수 필드 결정
        String currentPlayerId = widget.myPlayerId ?? '';
        String scoreField = '';
        String nextTurnPlayerId = '';

        if (currentPlayerId == player1Id) {
          scoreField = 'player1.score';
          nextTurnPlayerId = player2Id;
        } else if (currentPlayerId == player2Id) {
          scoreField = 'player2.score';
          nextTurnPlayerId = player1Id;
        } else {
          print('현재 플레이어 ID를 찾을 수 없습니다: $currentPlayerId');
          return;
        }

        int currentScore = currentPlayerId == player1Id
            ? (player1['score'] as int?) ?? 0
            : (player2['score'] as int?) ?? 0;

        Map<String, dynamic> updateData = {
          'lastAction': {
            'type': isMatch ? 'match' : 'mismatch',
            'cards': selectedCards,
            'playerId': currentPlayerId,
            'timestamp': FieldValue.serverTimestamp(),
          },
          'lastMoveTime': FieldValue.serverTimestamp(),
        };

        if (isMatch) {
          // 매치 성공 시 점수 증가 및 턴 유지
          updateData[scoreField] = currentScore + 1;
          updateData['lastMatchedBy'] = currentPlayerId;

          // 보드 데이터 가져와서 업데이트
          if (gameData.containsKey('board') && gameData['board'] is List) {
            List<dynamic> boardData =
                List.from(gameData['board'] as List<dynamic>);

            // 매치된 카드들 업데이트
            for (int cardIndex in selectedCards) {
              if (cardIndex < boardData.length && boardData[cardIndex] is Map) {
                // 기존 카드 데이터 복사하고 matchedBy 필드만 업데이트
                Map<String, dynamic> cardData =
                    Map.from(boardData[cardIndex] as Map<String, dynamic>);
                cardData['matchedBy'] = currentPlayerId;

                // 업데이트된 카드 데이터를 배열에 다시 저장
                boardData[cardIndex] = cardData;
              }
            }

            // 업데이트 데이터에 전체 보드 추가
            updateData['board'] = boardData;
          }
        } else {
          // 매치 실패 시 턴 변경
          updateData['currentTurn'] = nextTurnPlayerId;

          // 보드 데이터 가져와서 업데이트
          if (gameData.containsKey('board') && gameData['board'] is List) {
            List<dynamic> boardData =
                List.from(gameData['board'] as List<dynamic>);

            // 매치 실패한 카드들 업데이트 - isFlipped를 false로 설정
            for (int cardIndex in selectedCards) {
              if (cardIndex < boardData.length && boardData[cardIndex] is Map) {
                // 기존 카드 데이터 복사하고 isFlipped 필드 업데이트
                Map<String, dynamic> cardData =
                    Map.from(boardData[cardIndex] as Map<String, dynamic>);
                cardData['isFlipped'] = false;
                cardData['matchedBy'] = null;

                // 업데이트된 카드 데이터를 배열에 다시 저장
                boardData[cardIndex] = cardData;
              }
            }

            // 업데이트 데이터에 전체 보드 추가
            updateData['board'] = boardData;
          }
        }

        await FirebaseFirestore.instance
            .collection('game_sessions')
            .doc(widget.gameId)
            .update(updateData);

        // 모든 카드가 매치되었는지 확인
        bool allMatched = true;
        if (gameData.containsKey('board') && gameData['board'] is List) {
          List<dynamic> board = gameData['board'] ?? [];

          for (var card in board) {
            if (card is Map<String, dynamic> && card['matchedBy'] == null) {
              allMatched = false;
              break;
            }
          }

          // 게임 종료 조건
          if (allMatched) {
            await FirebaseFirestore.instance
                .collection('game_sessions')
                .doc(widget.gameId)
                .update({
              'gameState': 'completed',
              'completedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      print('매치 업데이트 오류: $e');

      // UI에 오류 알림 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게임 진행 중 오류가 발생했습니다. 다시 시도하세요.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _languageSubscription?.cancel(); // null 체크 추가
    _gameSubscription?.cancel(); // 멀티플레이어 게임 구독 취소
    _timer?.cancel();
    audioPlayer.dispose();
    flutterTts.stop();
    _animationController.dispose();

    // 앱 생명주기 관찰자 제거
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didUpdateWidget(MemoryGamePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reinitialize the game if the grid size has changed
    if (widget.gridSize != oldWidget.gridSize) {
      _initializeGameWrapper();
    }

    // 이 메서드는 위젯이 업데이트될 때마다 호출됩니다.
    // IndexedStack에서 현재 표시되는 탭이 변경될 때도 호출됩니다.
    // 따라서 이 메서드에서 탭 가시성을 확인하고 타이머를 제어할 수 있습니다.

    // 현재 위젯이 보이는지 확인 (IndexedStack에서 현재 표시되는 탭인지)
    bool isCurrentlyVisible = true; // 기본적으로 보이는 것으로 가정

    // 부모 위젯 구조를 확인하여 현재 위젯이 보이는지 확인
    BuildContext? context = this.context;
    if (context != null) {
      // 부모 위젯 중에 IndexedStack이 있는지 확인
      IndexedStack? indexedStack =
          context.findAncestorWidgetOfExactType<IndexedStack>();
      if (indexedStack != null) {
        // 현재 인덱스가 0(메모리 게임 탭)인지 확인
        isCurrentlyVisible = indexedStack.index == 0;
      }
    }

    // 탭 가시성이 변경되었을 때 타이머 제어
    if (isCurrentlyVisible != _isTabActive) {
      _isTabActive = isCurrentlyVisible;
      if (_isTabActive) {
        // 탭이 보이게 되었을 때 타이머 재개
        if (isGameStarted && _isTimerPaused) {
          _resumeTimer();
        }
      } else {
        // 탭이 보이지 않게 되었을 때 타이머 일시정지
        if (isGameStarted && !_isTimerPaused && _timer != null) {
          _pauseTimer();
        }
      }
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
        if (mounted && widget.isTimeAttackMode) {
          setState(() {
            _remainingTime = _gameTimeLimit;
            _gameStartTime =
                null; // Don't set game start time until first card click
          });
          // Don't start timer here, wait for first card click
          // _startTimer();
        }
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
      // 그리드 크기에 맞게 시간 설정
      _gameTimeLimit = _getDefaultTimeForGridSize(widget.gridSize);
      _remainingTime = _gameTimeLimit;

      isInitialized = false;
      hasError = false;
      _elapsedTime = 0; // 경과 시간도 초기화
      _gameStartTime = null; // 게임 시작 시간 초기화
      _canAddTime = true; // 시간 추가 버튼 초기화
      isGameStarted = false; // Reset game started state
    });

    widget.resetScores();

    List<String> dimensions = widget.gridSize.split('x');
    // 그리드 크기 파싱: 표기법은 "가로x세로"이지만 UI에서는 세로x가로로 사용해야 함
    // 따라서 첫 번째 숫자(가로)를 gridColumns로, 두 번째 숫자(세로)를 gridRows로 할당
    gridColumns = int.parse(dimensions[0]); // 가로를 열 수로 설정
    gridRows = int.parse(dimensions[1]); // 세로를 행 수로 설정

    flipCount = 0;
    widget.updateFlipCount(flipCount);
    pairCount = (gridRows * gridColumns) ~/ 2;

    // 카드 배열 초기화
    cardFlips = List.generate(gridRows * gridColumns, (_) => false);
    cardAnimationTriggers = List.generate(gridRows * gridColumns, (_) => false);
    selectedCards.clear();

    // 멀티플레이어 모드일 경우
    if (widget.isMultiplayerMode && widget.gameId != null) {
      try {
        // 게임 세션 정보 가져오기
        DocumentSnapshot gameSessionDoc = await FirebaseFirestore.instance
            .collection('game_sessions')
            .doc(widget.gameId)
            .get();

        if (gameSessionDoc.exists) {
          Map<String, dynamic> gameSessionData =
              gameSessionDoc.data() as Map<String, dynamic>;

          // 게임 상태 확인
          String gameState = gameSessionData['gameState'] ?? '';

          if (gameState == 'pending' || gameState == '') {
            // 게임이 아직 시작되지 않았으면 새로운 게임 보드 초기화
            await _initializeMultiplayerGameBoard();
          } else {
            // 이미 게임이 시작된 경우 기존 보드 데이터 로드
            List<dynamic> boardData = gameSessionData['board'] ?? [];

            if (boardData.isNotEmpty) {
              // 카드 이미지 ID 추출
              gameImages = [];
              for (var card in boardData) {
                if (card is Map) {
                  gameImages.add(card['imageId'] as String);
                }
              }
            } else {
              // 보드 데이터가 없으면 새로 초기화
              await _initializeMultiplayerGameBoard();
            }
          }

          // 멀티플레이어 게임 세션 구독
          _subscribeToGameState();

          // 플레이어 정보 로드
          await _loadMultiplayerData();
        } else {
          // 게임 세션 정보가 없으면 오류 표시
          setState(() {
            hasError = true;
          });
        }
      } catch (e) {
        print('멀티플레이어 게임 초기화 오류: $e');
        // 오류 발생 시 기본 방식으로 초기화
        _initializeDefaultGameImages();
      }
    } else {
      // 싱글플레이어 모드는 기존 방식대로 초기화
      _initializeDefaultGameImages();
    }

    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      isInitialized = true;
      // Don't set isGameStarted to true here
      // Wait for first card click instead
    });
  }

  // 기본 게임 이미지 초기화 메소드 (싱글플레이어 모드 또는 로드 실패 시)
  void _initializeDefaultGameImages() {
    List<String> tempList = List<String>.from(itemList);
    tempList.shuffle();
    gameImages = tempList.take(pairCount).toList();
    gameImages = List<String>.from(gameImages)
      ..addAll(List<String>.from(gameImages));
    gameImages.shuffle();
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
    try {
      // 기본 유효성 검사
      if (index >= gameImages.length || index < 0) {
        print('유효하지 않은 카드 인덱스: $index');
        return;
      }

      // 카드가 이미 뒤집혔거나, 두 카드가 선택된 상태면 리턴
      if (cardFlips[index] || selectedCards.length == 2) return;

      // 멀티플레이어 모드에서는 내 턴일 때만 카드 선택 가능
      if (widget.isMultiplayerMode && !_isMyTurn) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('It\'s not your turn yet!'),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }

      // 첫 번째 카드를 클릭할 때만 타이머 시작
      if (!isGameStarted && widget.isTimeAttackMode) {
        setState(() {
          isGameStarted = true;
          _remainingTime = _gameTimeLimit;
          _gameStartTime = DateTime.now(); // 게임 시작 시간 기록
        });
        _startTimer();
      }

      // 로컬 UI 업데이트
      setState(() {
        cardFlips[index] = true;
        selectedCards.add(index);
        _triggerStarAnimation(index);
      });

      // 멀티플레이어 모드에서는 Firestore 업데이트
      if (widget.isMultiplayerMode &&
          widget.gameId != null &&
          widget.myPlayerId != null) {
        await _updateCardStateInFirestore(index, true);

        // 두 카드가 선택되었으면 매치 여부 확인
        if (selectedCards.length == 2) {
          flipCount++;
          widget.updateFlipCount(flipCount);

          // 약간의 지연 후 매치 확인
          await Future.delayed(const Duration(milliseconds: 750));

          // 매치 여부 확인 및 Firestore 업데이트
          if (selectedCards.length == 2 &&
              selectedCards[0] < gameImages.length &&
              selectedCards[1] < gameImages.length) {
            bool isMatch =
                gameImages[selectedCards[0]] == gameImages[selectedCards[1]];
            await _updateMatchInFirestore(isMatch);
          }
        }
      } else {
        // 싱글플레이어 모드 - 기존 로직 유지
        try {
          // 번역된 단어 가져오기 및 발음
          if (index < gameImages.length) {
            final translatedWord = getLocalizedWord(gameImages[index]);
            await flutterTts.setLanguage(targetLanguage);
            await flutterTts.speak(translatedWord);
          }
        } catch (e) {
          print('번역 또는 음성 재생 오류: $e');
        }

        if (selectedCards.length == 2) {
          flipCount++;
          widget.updateFlipCount(flipCount);
          Future.delayed(const Duration(milliseconds: 750), () {
            if (mounted) {
              setState(() {
                checkMatch();
              });
            }
          });
        }
      }

      // 멀티플레이어 모드에서도 번역된 단어 발음하기
      if (widget.isMultiplayerMode && index < gameImages.length) {
        try {
          final translatedWord = getLocalizedWord(gameImages[index]);
          await flutterTts.setLanguage(targetLanguage);
          await flutterTts.speak(translatedWord);
        } catch (e) {
          print('멀티플레이어 모드 음성 재생 오류: $e');
        }
      }
    } catch (e) {
      print('카드 탭 처리 중 예기치 않은 오류: $e');
      // 오류 발생 시 UI에 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게임 진행 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void checkMatch() {
    setState(() {
      if (gameImages[selectedCards[0]] == gameImages[selectedCards[1]]) {
        // 멀티플레이어 모드에서는 점수 업데이트를 Firestore에 반영
        if (widget.isMultiplayerMode) {
          _updateMatchInFirestore(true);
        } else {
          // 싱글플레이어 모드에서는 로컬 점수 업데이트
          widget.updatePlayerScore(widget.currentPlayer,
              widget.playerScores[widget.currentPlayer]! + 1);
        }

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

          // 멀티플레이어 모드와 싱글플레이어 모드에 따라 다른 결과 다이얼로그 표시
          if (widget.isMultiplayerMode) {
            _showMultiplayerGameCompleteDialog();
          } else {
            showWinnerDialog();
          }
        }
      } else {
        // 매치 실패 시 카드 뒤집기 및 턴 변경
        for (var index in selectedCards) {
          cardFlips[index] = false;
        }

        // 멀티플레이어 모드에서는 턴 변경을 Firestore에 반영
        if (widget.isMultiplayerMode) {
          _updateMatchInFirestore(false);
        } else {
          // 싱글플레이어 모드에서는 로컬 턴 변경
          widget.nextPlayer();
        }

        selectedCards.clear();
      }
    });
  }

  // 멀티플레이어 게임 완료 다이얼로그
  void _showMultiplayerGameCompleteDialog() {
    // 게임 종료 시간 계산
    if (_gameStartTime != null) {
      _elapsedTime = DateTime.now().difference(_gameStartTime!).inSeconds;
    }

    // 점수 계산
    int myScore = 0;
    int opponentScore = 0;

    if (widget.myPlayerId == widget.playerScores.keys.first) {
      myScore = widget.playerScores[widget.playerScores.keys.first]!;
      opponentScore =
          widget.playerScores[widget.playerScores.keys.elementAt(1)]!;
    } else {
      myScore = widget.playerScores[widget.playerScores.keys.elementAt(1)]!;
      opponentScore = widget.playerScores[widget.playerScores.keys.first]!;
    }

    String result;
    if (myScore > opponentScore) {
      result = "You Win!";
    } else if (myScore < opponentScore) {
      result = "You Lost";
    } else {
      result = "It's a Tie!";
    }

    if (!mounted) return;

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
                  result,
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _myNickname ?? 'You',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "$myScore",
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _opponentNickname ?? 'Opponent',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "$opponentScore",
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Time: ${_elapsedTime} seconds",
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
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
                      'assets/pictureDB_webp/${gameImages[index]}.webp',
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    'assets/icon/memoryGame.png',
                    fit: BoxFit.cover,
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

  // 그리드 크기에 맞는 시간 설정 함수 추가
  int _getDefaultTimeForGridSize(String gridSize) {
    switch (gridSize) {
      case '2x2':
        return 30; // 2x2는 30초
      case '3x3':
        return 45; // 3x3는 45초
      case '4x4':
        return 60; // 4x4는 1분
      case '5x5':
        return 120; // 5x5는 2분
      case '6x4':
        return 120; // 6x4는 2분
      case '6x6':
        return 180; // 6x6는 3분
      case '8x6':
        return 240; // 6x8는 4분
      default:
        return 60; // 기본값 1분
    }
  }

  // 시간 추가 함수 추가
  Future<void> _addExtraTime() async {
    // 게임이 시작되지 않았거나, 쿨다운 중이면 리턴
    if (!_canAddTime || !isGameStarted) return;

    // 게임 시작 후 최소 경과 시간 체크
    if (_gameStartTime != null) {
      int elapsedSeconds = DateTime.now().difference(_gameStartTime!).inSeconds;
      if (elapsedSeconds < _timeAddMinElapsed) {
        // 최소 경과 시간이 지나지 않았으면 알림 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Wait at least $_timeAddMinElapsed seconds before adding time'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final brainHealthProvider =
        Provider.of<BrainHealthProvider>(context, listen: false);
    final currentPoints = await brainHealthProvider.getCurrentPoints();

    if (currentPoints < _timeAddCost) {
      // 점수가 부족하면 알림 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Not enough Brain Health points! You need $_timeAddCost points.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 점수 차감 및 시간 추가
    await brainHealthProvider.deductPoints(_timeAddCost);

    setState(() {
      _remainingTime += 30; // 30초 추가
      _canAddTime = false; // 쿨다운 시작
    });

    // 시간 추가 알림
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('+30 seconds added! -$_timeAddCost Brain Health points'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // 10초 후 다시 시간 추가 가능하게 설정
    Future.delayed(Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _canAddTime = true;
        });
      }
    });
  }

  // 버튼 활성화 여부 확인 함수 추가
  bool _isAddTimeButtonEnabled() {
    // 게임이 시작되지 않았으면 비활성화
    if (!isGameStarted) return false;
    // 쿨다운 중이면 비활성화
    if (!_canAddTime) return false;

    // 게임 시작 후 경과 시간 체크
    if (_gameStartTime != null) {
      int elapsedSeconds = DateTime.now().difference(_gameStartTime!).inSeconds;
      // 최소 경과 시간이 지나지 않았으면 비활성화
      if (elapsedSeconds < _timeAddMinElapsed) return false;
    }

    return true;
  }

  // 튜토리얼 표시 여부 확인
  Future<void> _checkTutorialStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool tutorialShown = prefs.getBool(_tutorialPrefKey) ?? false;

    if (!tutorialShown) {
      setState(() {
        _showTutorial = true;
      });
    }
  }

  // 튜토리얼 표시 여부 저장
  Future<void> _saveTutorialPreference() async {
    if (_doNotShowAgain) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tutorialPrefKey, true);
    }
  }

  // 튜토리얼 닫기
  void _closeTutorial() {
    setState(() {
      _showTutorial = false;
    });
    _saveTutorialPreference();
  }

  @override
  Widget build(BuildContext context) {
    super.build(
        context); // Call super.build to integrate keep-alive functionality
    if (hasError) {
      return Center(child: Text('게임 초기화 중 오류가 발생했습니다. 다시 시도해 주세요.'));
    }

    if (!isInitialized) {
      return Center(child: Text('Initializing...'));
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
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  await initializeGame();
                },
                child: Column(
                  children: [
                    if (widget.numberOfPlayers > 1) this.buildScoreBoard(),
                    if (widget.isTimeAttackMode) ...[
                      // Add timer bar
                      SizedBox(
                        height: 75, // 전체 영역의 고정 높이 설정
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch, // 세로 방향으로 확장
                          children: [
                            Expanded(
                              flex: 4, // 타이머 영역이 4/5 차지
                              child: Container(
                                margin: EdgeInsets.only(
                                    top: 8.0,
                                    bottom: 8.0,
                                    left: 16.0,
                                    right: 4.0),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center, // 수직 중앙 정렬
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Time: $_remainingTime s',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: _remainingTime < 10
                                                ? Colors.red
                                                : Colors.black87,
                                          ),
                                        ),
                                        if (widget.isTimeAttackMode) ...[
                                          // 메인 화면에서 시간 추가 버튼 추가
                                          ElevatedButton.icon(
                                            onPressed: _canAddTime &&
                                                    isGameStarted &&
                                                    _elapsedTime >=
                                                        _timeAddMinElapsed
                                                ? _addExtraTime
                                                : null,
                                            icon: Icon(Icons.add, size: 16),
                                            label: Text('+30s'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _canAddTime &&
                                                      isGameStarted &&
                                                      _elapsedTime >=
                                                          _timeAddMinElapsed
                                                  ? instagramGradientStart
                                                  : Colors.grey,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8),
                                              minimumSize: Size(60, 32),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Container(
                                      width: double.infinity,
                                      child: LinearProgressIndicator(
                                        value: _remainingTime / _gameTimeLimit,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          _remainingTime < 10
                                              ? Colors.red
                                              : Colors.blue,
                                        ),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1, // Fight 버튼 영역이 1/5 차지
                              child: Container(
                                margin: EdgeInsets.only(
                                    top: 8.0,
                                    bottom: 8.0,
                                    left: 4.0,
                                    right: 16.0),
                                child: _buildFightButton(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                          height:
                              8), // Add some spacing when not in time attack mode
                    ],
                    Expanded(
                      child: GridView.builder(
                        physics: AlwaysScrollableScrollPhysics(), // 스크롤 가능하게 설정
                        padding: EdgeInsets.all(4),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: int.parse(widget.gridSize.split(
                              'x')[0]), // 가로(첫 번째 숫자)를 crossAxisCount로 설정
                          crossAxisSpacing: 0,
                          mainAxisSpacing: 0,
                        ),
                        itemCount: gameImages.length,
                        itemBuilder: (context, index) {
                          return buildCard(index);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 튜토리얼 오버레이
              if (_showTutorial) _buildTutorialOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // 튜토리얼 오버레이 위젯
  Widget _buildTutorialOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Memory Game Guide',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: instagramGradientStart,
                  ),
                ),
                SizedBox(height: 12),
                _buildTutorialItem(
                  Icons.grid_on,
                  'Card Selection',
                  'Tap cards to flip and find matching pairs.',
                ),
                SizedBox(height: 10),
                _buildTutorialItem(
                  Icons.timer,
                  'Time Limit',
                  'Match all pairs within time limit. Faster matching earns higher score.',
                ),
                SizedBox(height: 10),
                _buildTutorialItem(
                  Icons.add_circle_outline,
                  'Add Time',
                  'Tap "+30s" to add time (costs Brain Health points).',
                ),
                SizedBox(height: 10),
                _buildTutorialItem(
                  Icons.people,
                  'Multiplayer',
                  'Change player count (1-4) to play with friends.',
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Checkbox(
                      value: _doNotShowAgain,
                      onChanged: (value) {
                        setState(() {
                          _doNotShowAgain = value ?? false;
                        });
                      },
                      activeColor: instagramGradientStart,
                    ),
                    Text(
                      'Don\'t show again',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _closeTutorial,
                  child: Text(
                    'Start Game',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: instagramGradientStart,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 튜토리얼 항목 위젯
  Widget _buildTutorialItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: instagramGradientStart.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: instagramGradientStart,
            size: 20,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Override TabNavigationObserver methods
  @override
  void onTabVisible() {
    if (mounted) {
      setState(() {
        _isTabActive = true;
        // Resume timer if game was already started
        if (isGameStarted && _isTimerPaused) {
          _resumeTimer();
        }
      });
    }
  }

  @override
  void onTabInvisible() {
    if (mounted) {
      setState(() {
        _isTabActive = false;
        // Pause timer if game was running
        if (isGameStarted && !_isTimerPaused && _timer != null) {
          _pauseTimer();
        }
      });
    }
  }

  @override
  bool get wantKeepAlive => true; // Ensure the state is kept alive

  // Add methods to be called from the widget
  double getRemainingTimeRatio() {
    // 남은 시간 비율 계산, 0.0~1.0 사이의 값을 반환
    double ratio = _remainingTime / _gameTimeLimit;
    if (ratio < 0.0) ratio = 0.0;
    if (ratio > 1.0) ratio = 1.0;
    return ratio;
  }

  bool isTimeLow() {
    return _remainingTime < 10;
  }

  bool getGameStartedStatus() {
    return true;
  }

  // Fight 버튼 위젯
  Widget _buildFightButton() {
    return ElevatedButton(
      onPressed: () {
        _showOpponentSelectionDialog(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 61, 137, 224),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        minimumSize: Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Fight!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Icon(Icons.sports_mma, size: 16, color: Colors.white),
        ],
      ),
    );
  }

  // 상대 선택 대화상자
  void _showOpponentSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // 선택된 사용자와 그리드 크기를 위한 변수
        String? selectedUser;
        String selectedGrid = widget.gridSize; // 현재 그리드 크기를 기본값으로 설정
        String searchQuery = '';
        List<Map<String, dynamic>> filteredUsers = [];
        bool isLoading = true;

        return StatefulBuilder(builder: (context, setState) {
          // 사용자 목록을 로드하는 함수
          void loadUsers() async {
            setState(() => isLoading = true);

            try {
              // 현재 사용자 ID 가져오기
              String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

              // Firestore에서 사용자 목록 가져오기
              QuerySnapshot querySnapshot = await FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('nickname')
                  .get();

              List<Map<String, dynamic>> users = [];

              for (var doc in querySnapshot.docs) {
                Map<String, dynamic> userData =
                    doc.data() as Map<String, dynamic>;
                // 현재 사용자는 제외
                if (doc.id != currentUserId &&
                    userData.containsKey('nickname')) {
                  users.add({
                    'id': doc.id,
                    'nickname': userData['nickname'] ?? 'Unknown',
                    'country': userData['country'],
                  });
                }
              }

              // 검색어로 필터링
              if (searchQuery.isNotEmpty) {
                filteredUsers = users
                    .where((user) => user['nickname']
                        .toString()
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase()))
                    .toList();
              } else {
                filteredUsers = users;
              }

              setState(() => isLoading = false);
            } catch (e) {
              print('Error loading users: $e');
              setState(() {
                isLoading = false;
                filteredUsers = [];
              });

              // 에러 알림
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Failed to load users. Please try again.'),
                backgroundColor: Colors.red,
              ));
            }
          }

          // 처음 대화상자가 열릴 때 사용자 목록 로드
          if (isLoading && filteredUsers.isEmpty) {
            loadUsers();
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: 340,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 대화상자 헤더
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Select Opponent',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 검색 텍스트 필드
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search users...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.purple),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 0, horizontal: 16),
                          ),
                          onChanged: (value) {
                            // 검색어가 변경될 때마다 필터링
                            setState(() {
                              searchQuery = value;
                              loadUsers(); // 검색어로 사용자 목록 다시 로드
                            });
                          },
                        ),

                        SizedBox(height: 16),

                        // 사용자 목록 레이블
                        Text(
                          'Registered Users',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 12),

                        // 사용자 목록
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: isLoading
                              ? Center(child: CircularProgressIndicator())
                              : filteredUsers.isEmpty
                                  ? Center(child: Text('No users found'))
                                  : ListView.builder(
                                      itemCount: filteredUsers.length,
                                      itemBuilder: (context, index) {
                                        final user = filteredUsers[index];
                                        final bool isSelected =
                                            selectedUser == user['id'];

                                        return ListTile(
                                          leading: user['country'] != null
                                              ? Container(
                                                  width: 40,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? Colors.purple
                                                          : Colors
                                                              .grey.shade300,
                                                      width: 1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    boxShadow: isSelected
                                                        ? [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .purple
                                                                  .withOpacity(
                                                                      0.3),
                                                              spreadRadius: 1,
                                                              blurRadius: 2,
                                                            )
                                                          ]
                                                        : null,
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    child: Flag.fromString(
                                                      user['country']
                                                          .toString()
                                                          .toLowerCase(),
                                                      height: 30,
                                                      width: 40,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                )
                                              : CircleAvatar(
                                                  backgroundColor: isSelected
                                                      ? Colors.purple
                                                      : Colors.grey.shade200,
                                                  child: Text(
                                                    user['nickname']
                                                        .toString()
                                                        .substring(0, 1)
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      color: isSelected
                                                          ? Colors.white
                                                          : Colors.black54,
                                                    ),
                                                  ),
                                                ),
                                          title: Text(
                                            user['nickname'].toString(),
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          trailing: isSelected
                                              ? Icon(Icons.check_circle,
                                                  color: Colors.purple)
                                              : null,
                                          onTap: () {
                                            setState(() {
                                              selectedUser = user['id'];
                                            });
                                          },
                                          tileColor: isSelected
                                              ? Colors.purple.withOpacity(0.1)
                                              : null,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        );
                                      },
                                    ),
                        ),

                        SizedBox(height: 24),

                        // 그리드 선택 레이블
                        Text(
                          'Select Grid Size',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 12),

                        // 그리드 선택 버튼들 - 첫 번째 행 (4x4, 6x4)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: ['4x4', '6x4'].map((String value) {
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: InkWell(
                                onTap: () {
                                  setState(() => selectedGrid = value);
                                },
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: value == selectedGrid
                                          ? [
                                              Color(0xFF833AB4),
                                              Color(0xFFF77737)
                                            ]
                                          : [
                                              Colors.grey.shade200,
                                              Colors.grey.shade300
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.grid_4x4,
                                        size: 28,
                                        color: value == selectedGrid
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        value,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: value == selectedGrid
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        '×${_getGridSizeMultiplier(value)} points',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: value == selectedGrid
                                              ? Colors.white.withOpacity(0.9)
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        SizedBox(height: 16),

                        // 그리드 선택 버튼들 - 두 번째 행 (6x6, 8x6)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: ['6x6', '8x6'].map((String value) {
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: InkWell(
                                onTap: () {
                                  setState(() => selectedGrid = value);
                                },
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: value == selectedGrid
                                          ? [
                                              Color(0xFF833AB4),
                                              Color(0xFFF77737)
                                            ]
                                          : [
                                              Colors.grey.shade200,
                                              Colors.grey.shade300
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.grid_on,
                                        size: 28,
                                        color: value == selectedGrid
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        value,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: value == selectedGrid
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        '×${_getGridSizeMultiplier(value)} points',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: value == selectedGrid
                                              ? Colors.white.withOpacity(0.9)
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        SizedBox(height: 24),

                        // 확인 버튼
                        Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: selectedUser == null
                                ? null
                                : () {
                                    Navigator.of(context).pop();
                                    // 선택된 사용자의 닉네임 찾기
                                    String selectedNickname = filteredUsers
                                        .firstWhere((user) =>
                                            user['id'] ==
                                            selectedUser)['nickname']
                                        .toString();
                                    _startMultiplayerGame(selectedUser!,
                                        selectedGrid, selectedNickname);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Fight!!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
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
          );
        });
      },
    );
  }

  // 그리드 크기별 점수 배율 계산
  int _getGridSizeMultiplier(String gridSize) {
    switch (gridSize) {
      case '4x4':
        return 1; // 기본 배율
      case '6x4':
        return 3; // 6x4 그리드는 3배 점수
      case '6x6':
        return 5; // 6x6 그리드는 5배 점수
      case '8x6':
        return 8; // 8x6 그리드는 8배 점수
      default:
        return 1;
    }
  }

  // 멀티플레이어 게임 시작 메서드
  void _startMultiplayerGame(
      String opponentId, String gridSize, String opponentNickname) async {
    try {
      // Get current user info
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You must be logged in to send challenges')),
        );
        return;
      }

      // Get current user's nickname
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      String senderNickname = 'Unknown Player';
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        senderNickname = userData['nickname'] ??
            (currentUser.displayName ??
                currentUser.email?.split('@')[0] ??
                'Unknown Player');
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Sending challenge request...")
              ],
            ),
          );
        },
      );

      // Get opponent's FCM token first
      String? fcmToken;
      DocumentSnapshot tokenDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(opponentId)
          .collection('tokens')
          .doc('fcm')
          .get();

      if (tokenDoc.exists && tokenDoc.data() != null) {
        Map<String, dynamic> tokenData =
            tokenDoc.data() as Map<String, dynamic>;
        fcmToken = tokenData['token'];
        print(
            'FCM Token retrieved: ${fcmToken != null ? fcmToken.substring(0, 10) + "..." : "null"}');
      } else {
        print(
            'FCM Token document does not exist or is empty for user: $opponentId');
      }

      // Create a unique challenge ID
      String challengeId =
          FirebaseFirestore.instance.collection('challenges').doc().id;

      // Get timestamp
      final timestamp = FieldValue.serverTimestamp();

      // Create challenge document
      await FirebaseFirestore.instance
          .collection('challenges')
          .doc(challengeId)
          .set({
        'senderId': currentUser.uid,
        'senderNickname': senderNickname,
        'receiverId': opponentId,
        'receiverNickname': opponentNickname,
        'gridSize': gridSize,
        'status': 'pending', // pending, accepted, rejected, completed
        'timestamp': timestamp,
        'language': Provider.of<LanguageProvider>(context, listen: false)
            .currentLanguage,
        'expiresAt': DateTime.now()
            .add(Duration(hours: 24))
            .millisecondsSinceEpoch, // Expires in 24 hours
      });

      // Also add to the receiver's notifications collection for easier querying
      Map<String, dynamic> notificationData = {
        'type': 'challenge',
        'challengeId': challengeId,
        'senderId': currentUser.uid,
        'senderNickname': senderNickname,
        'gridSize': gridSize,
        'status': 'pending',
        'read': false,
        'timestamp': timestamp,
      };

      // FCM 토큰이 있을 경우에만 포함
      if (fcmToken != null && fcmToken.isNotEmpty) {
        notificationData['recipientFcmToken'] = fcmToken;
        print(
            'Added FCM token to notification document: ${fcmToken.substring(0, 10)}...');
      } else {
        print(
            'WARNING: FCM token is missing, push notification will not be sent');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(opponentId)
          .collection('notifications')
          .doc(challengeId)
          .set(notificationData);

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Challenge request sent to $opponentNickname!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Challenge notifications 컬렉션에 문서가 생성되었으므로
      // _sendChallengeNotification 함수 호출은 더 이상 필요하지 않음
      // 이미 FCM 토큰이 포함되어 있어 Cloud Function이 자동으로 트리거됨
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      print('Error sending challenge: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send challenge. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showWinnerDialog() {
    String winner = widget.playerScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // 게임 종료 시간 계산
    if (_gameStartTime != null) {
      _elapsedTime = DateTime.now().difference(_gameStartTime!).inSeconds;
    }

    // Brain Health Score update은 _showCompletionDialog에서만 수행
    _showCompletionDialog(_elapsedTime);
  }

  Future<int> _updateBrainHealthScore(int elapsedTime) async {
    // 매치된 카드 쌍의 개수 계산
    final int totalMatches = gameImages.length ~/ 2;

    try {
      // Brain Health Provider에 게임 완료 정보 추가
      final brainHealthProvider =
          Provider.of<BrainHealthProvider>(context, listen: false);
      final int pointsEarned = await brainHealthProvider.addGameCompletion(
          totalMatches, elapsedTime, widget.gridSize);

      // 점수 획득 정보를 completion dialog에서 표시하기 위해 반환
      return pointsEarned;
    } catch (e) {
      print('Error updating Brain Health score: $e');
      return 0;
    }
  }

  // 게임 완료 대화상자 표시
  void _showCompletionDialog(int elapsedTime) async {
    String languageCode =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    String gridSize = widget.gridSize;

    // 게임 통계 업데이트 및 획득 점수 가져오기
    final int pointsEarned = await _updateBrainHealthScore(elapsedTime);

    // 게임 통계 업데이트
    _updateGameStatistics(languageCode, gridSize, elapsedTime, flipCount);

    if (!mounted) return;

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
                SizedBox(height: 16),
                if (widget.isTimeAttackMode) ...[
                  Text(
                    "Time: ${elapsedTime} seconds",
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: 8),
                Text(
                  "Flips: $flipCount",
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "+$pointsEarned points",
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
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

  // 점수판 구성 위젯
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
              child: widget.numberOfPlayers > 1
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: widget.playerScores.entries
                          .take(widget.numberOfPlayers)
                          .map((entry) {
                        // Determine player name based on position
                        String displayName = entry.key;

                        if (widget.isMultiplayerMode) {
                          // 멀티플레이어 모드에서는 실제 닉네임 표시
                          int playerIndex = widget.playerScores.keys
                              .toList()
                              .indexOf(entry.key);

                          if (playerIndex == 0) {
                            displayName = _myNickname ?? 'You';
                          } else {
                            displayName = _opponentNickname ?? 'Opponent';
                          }

                          // 현재 턴 표시 (내 턴일 때와 상대방 턴일 때)
                          bool isCurrentPlayerTurn =
                              (playerIndex == 0 && _isMyTurn) ||
                                  (playerIndex == 1 && !_isMyTurn);

                          return Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCurrentPlayerTurn
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '$displayName: ${entry.value}',
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (isCurrentPlayerTurn)
                                    Text(
                                      'Playing...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          // 기존 싱글플레이어 모드 코드 유지
                          if (widget.playerScores.keys
                                  .toList()
                                  .indexOf(entry.key) ==
                              0) {
                            // First player - try to get user's nickname
                            User? user = FirebaseAuth.instance.currentUser;
                            if (user != null &&
                                user.displayName != null &&
                                user.displayName!.isNotEmpty) {
                              displayName = user.displayName!;
                            } else {
                              // If no display name, try to get email
                              displayName = user?.email?.split('@')[0] ?? 'You';
                            }
                          } else {
                            // For other players, use predefined names
                            int playerIndex = widget.playerScores.keys
                                .toList()
                                .indexOf(entry.key);

                            // Use these names for AI players in this specific order
                            List<String> aiPlayerNames = [
                              "Genious",
                              "Cute",
                              "Lovely"
                            ];
                            if (playerIndex > 0 &&
                                playerIndex <= aiPlayerNames.length) {
                              displayName = aiPlayerNames[playerIndex - 1];
                            }
                          }

                          return Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: entry.key == widget.currentPlayer
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$displayName: ${entry.value}',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                      }).toList(),
                    )
                  : Container(), // If only 1 player, don't show any player names
            ),
          ),
        ],
      ),
    );
  }

  // 멀티플레이어 게임 보드 초기화 메서드 추가
  Future<void> _initializeMultiplayerGameBoard() async {
    if (!widget.isMultiplayerMode || widget.gameId == null) {
      print('멀티플레이어 게임 보드 초기화 불가: 유효하지 않은 게임 ID 또는 모드');
      return;
    }

    try {
      // 현재 게임 세션 데이터 먼저 확인
      DocumentSnapshot gameDoc = await FirebaseFirestore.instance
          .collection('game_sessions')
          .doc(widget.gameId)
          .get();

      if (!gameDoc.exists) {
        throw Exception('게임 세션을 찾을 수 없습니다');
      }

      Map<String, dynamic> gameData = gameDoc.data() as Map<String, dynamic>;

      // 플레이어 정보 확인
      String player1Id = '';
      String player2Id = '';
      String initialTurn = '';

      if (gameData.containsKey('player1') && gameData.containsKey('player2')) {
        // 새로운 데이터 구조
        Map<String, dynamic> player1 = gameData['player1'] ?? {};
        Map<String, dynamic> player2 = gameData['player2'] ?? {};
        player1Id = player1['id'] ?? '';
        player2Id = player2['id'] ?? '';
      } else {
        // 기존 데이터 구조
        player1Id = gameData['player1Id'] ?? '';
        player2Id = gameData['player2Id'] ?? '';
      }

      // 첫 번째 턴을 설정 (일반적으로 챌린지를 받은 사람이 먼저 시작)
      initialTurn = player1Id; // 기본값은 player1이 먼저 시작

      // 기본 게임 이미지 초기화 (카드 준비)
      _initializeDefaultGameImages();

      // gameImages가 제대로 초기화되었는지 확인
      if (gameImages.isEmpty) {
        throw Exception('게임 이미지를 초기화하지 못했습니다');
      }

      print('카드 초기화 완료: ${gameImages.length}개');

      // 각 카드에 대한 보드 데이터 생성
      List<Map<String, dynamic>> boardData = [];
      for (int i = 0; i < gameImages.length; i++) {
        if (gameImages[i].isNotEmpty) {
          boardData.add({
            'imageId': gameImages[i],
            'isFlipped': false,
            'matchedBy': null,
            'lastFlippedBy': null,
          });
        } else {
          print('경고: 인덱스 $i에 빈 이미지 ID가 있습니다');
          boardData.add({
            'imageId': 'default', // 기본값 사용
            'isFlipped': false,
            'matchedBy': null,
            'lastFlippedBy': null,
          });
        }
      }

      // 게임 세션 업데이트 데이터 준비
      Map<String, dynamic> updateData = {
        'board': boardData,
        'gameState': 'active',
        'startedAt': FieldValue.serverTimestamp(),
        'currentTurn': initialTurn,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // player1, player2 구조를 사용하는 경우, 점수 초기화
      if (gameData.containsKey('player1') && gameData.containsKey('player2')) {
        updateData['player1.score'] = 0;
        updateData['player2.score'] = 0;
      }

      // Firestore에 게임 보드 데이터 업데이트
      await FirebaseFirestore.instance
          .collection('game_sessions')
          .doc(widget.gameId)
          .update(updateData);

      print('멀티플레이어 게임 보드 초기화 성공: ${boardData.length}개 카드, 첫 턴: $initialTurn');

      // 플레이어 턴 상태 설정
      setState(() {
        _currentTurn = initialTurn;
        _isMyTurn = initialTurn == widget.myPlayerId;
      });

      // 게임 세션 구독 시작
      _subscribeToGameState();

      // 알림 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Game started! ${_isMyTurn ? "Your turn!" : "Opponent's turn first!"}'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('멀티플레이어 게임 보드 초기화 오류: $e');

      // 오류 발생 시 UI에 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게임 보드 초기화 중 오류가 발생했습니다. 다시 시도하세요.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );

        // 상태 업데이트
        setState(() {
          hasError = true;
        });
      }
    }
  }
}
