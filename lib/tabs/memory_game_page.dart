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
import '../services/memory_game_service.dart';
import 'package:flag/flag.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:math';

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
  final List<Map<String, dynamic>> selectedPlayers;
  final Map<String, dynamic> currentUserInfo;

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
    this.selectedPlayers = const [],
    this.currentUserInfo = const {
      'nickname': 'Me',
      'country': 'us',
      'gender': 'unknown',
      'age': 0,
      'brainHealthScore': 0
    },
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
    print('탭이 보이게 될 때 호출되는 메서드');
  }

  // 탭이 보이지 않게 될 때 호출되는 메서드
  void onTabInvisible() {
    _stateKey.currentState?.onTabInvisible();
    print('탭이 보이지 않게 될 때 호출되는 메서드');
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
  // 아이템 관련 상수 추가
  static const double ITEM_DROP_CHANCE = 0.2; // 20% 확률로 아이템 드롭
  static const String ITEM_SHAKE = 'shake';

  // 아이템 관련 상태 변수 추가
  bool _showItemPopup = false;
  String _currentItem = '';
  Timer? _itemPopupTimer;
  bool _itemUsedInCurrentGame = false; // 현재 게임에서 아이템 사용 여부 추적

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
  SharedPreferences? prefs;

  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  final Color instagramGradientStart = Color(0xFF833AB4);
  final Color instagramGradientEnd = Color(0xFFF77737);

  //final translator = GoogleTranslator();
  String targetLanguage = 'en-US';

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

  // late를 제거하고 nullable로 선언
  MemoryGameService? _memoryGameService;

  // Add a field to store the IndexedStack reference
  IndexedStack? _parentIndexedStack;

  @override
  void initState() {
    super.initState();

    // 선택된 플레이어 정보 디버그 출력
    print(
        'MemoryGamePage initState - 선택된 플레이어 수: ${widget.selectedPlayers.length}');
    for (var i = 0; i < widget.selectedPlayers.length; i++) {
      var player = widget.selectedPlayers[i];
      print('선택된 플레이어 #$i: ${player['nickname']} (국가: ${player['country']})');
    }

    // 기존 초기화 코드
    _loadUserLanguage();
    _checkTutorialStatus(); // 튜토리얼 표시 여부 확인
    _initializeGameWrapper(); // 게임 초기화
    // flutterTts.setLanguage("en-US"); // 오류가 있는 부분 제거
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

    // MemoryGameService 초기화 (한 번만)
    _initializeMemoryGameService();

    // 멀티플레이어 모드일 경우 추가 초기화
    if (widget.isMultiplayerMode && widget.gameId != null) {
      //_loadMultiplayerData();
      //_subscribeToGameState();
    }

    // 앱 생명주기 관찰자 등록
    WidgetsBinding.instance.addObserver(this);
  }

  // MemoryGameService 초기화 메서드
  void _initializeMemoryGameService() {
    try {
      _memoryGameService =
          Provider.of<MemoryGameService>(context, listen: false);

      // 그리드 크기 변경 리스너 등록
      _memoryGameService?.addGridChangeListener(_onGridSizeChanged);

      // 멀티플레이어 게임에서 턴 변경 리스너 등록
      _memoryGameService?.addPlayerTurnChangeListener(_onPlayerTurnChanged);

      // 점수 변경 리스너 등록
      _memoryGameService?.addScoreChangeListener(_onScoreChanged);

      // 로컬 멀티플레이어 모드에서 게임 초기화
      if (widget.numberOfPlayers > 1 && !widget.isMultiplayerMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _memoryGameService?.initializeGame();
          print('로컬 멀티플레이어 게임 초기화: 플레이어 ${widget.numberOfPlayers}명');
        });
      }

      print('MemoryGameService 초기화 성공');
    } catch (e) {
      print('MemoryGameService 초기화 오류: $e');
      // 나중에 다시 시도
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _memoryGameService =
              Provider.of<MemoryGameService>(context, listen: false);
          if (_memoryGameService != null) {
            _memoryGameService!.addGridChangeListener(_onGridSizeChanged);
            _memoryGameService!
                .addPlayerTurnChangeListener(_onPlayerTurnChanged);
            _memoryGameService!.addScoreChangeListener(_onScoreChanged);

            // 로컬 멀티플레이어 모드에서 게임 초기화
            if (widget.numberOfPlayers > 1 && !widget.isMultiplayerMode) {
              _memoryGameService!.initializeGame();
              print('로컬 멀티플레이어 게임 초기화(재시도): 플레이어 ${widget.numberOfPlayers}명');
            }
          }
        }
      });
    }
  }

  // UI 초기화 메서드
  void _initializeUI() {
    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _colorAnimation = ColorTween(
      begin: instagramGradientStart,
      end: instagramGradientEnd,
    ).animate(_animationController);

    // 텍스트 음성 변환 초기화 - 기존 인스턴스 사용
    flutterTts.setLanguage("en-US");

    // 언어 설정
    targetLanguage = 'en-US';

    // 추가 초기화
    _loadUserLanguage();
    _checkTutorialStatus(); // 튜토리얼 표시 여부 확인
    _subscribeToLanguageChanges();
    _loadGameTimeLimit();
  }

  // 그리드 사이즈 변경 리스너
  void _onGridSizeChanged(String newGridSize) {
    if (mounted) {
      // 게임 초기화
      setState(() {
        _initializeGameWrapper();
      });
    }
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

        if (userDoc.exists && userDoc.data() != null && mounted) {
          setState(() {
            targetLanguage =
                (userDoc.data() as Map<String, dynamic>)['language'] ?? 'ko-KR';
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
        if (snapshot.exists && snapshot.data() != null && mounted) {
          setState(() {
            targetLanguage =
                (snapshot.data() as Map<String, dynamic>)['language'] ??
                    'ko-KR';
          });
        }
      });
    }
  }

  void _showTimeUpDialog() {
    if (!mounted) return;

    // 번역 텍스트를 위한 언어 제공자
    final translations = Provider.of<LanguageProvider>(context, listen: false)
        .getUITranslations();

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
                  translations['times_up'] ?? "Time's Up!",
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
                  child: Text(translations['retry'] ?? "Retry"),
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
    // null 체크 추가
    if (_memoryGameService != null) {
      _memoryGameService!.removeGridChangeListener(_onGridSizeChanged);

      // 멀티플레이어 게임에서 턴 변경 리스너 제거
      //_memoryGameService?.removePlayerTurnChangeListener(_onPlayerTurnChanged);

      // 점수 변경 리스너 제거
      _memoryGameService?.removeScoreChangeListener(_onScoreChanged);
    }

    _languageSubscription?.cancel(); // null 체크 추가
    _gameSubscription?.cancel(); // 멀티플레이어 게임 구독 취소
    _timer?.cancel();
    audioPlayer.dispose();
    flutterTts.stop();
    _animationController.dispose();

    // 앱 생명주기 관찰자 제거
    WidgetsBinding.instance.removeObserver(this);

    // Clear the stored reference to IndexedStack
    _parentIndexedStack = null;

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MemoryGamePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 그리드 크기가 변경되었을 때 게임 재시작
    if (widget.gridSize != oldWidget.gridSize) {
      _initializeGameWrapper();
    }

    // 플레이어 수나 선택된 플레이어가 변경되었을 때 게임 재시작
    if (widget.numberOfPlayers != oldWidget.numberOfPlayers ||
        !_arePlayerListsEqual(
            widget.selectedPlayers, oldWidget.selectedPlayers)) {
      _initializeGameWrapper();
    }

    // 이 메서드는 위젯이 업데이트될 때마다 호출됩니다.
    // IndexedStack에서 현재 표시되는 탭이 변경될 때도 호출됩니다.
    // 따라서 이 메서드에서 탭 가시성을 확인하고 타이머를 제어할 수 있습니다.

    // 현재 위젯이 보이는지 확인 (IndexedStack에서 현재 표시되는 탭인지)
    bool isCurrentlyVisible = true; // 기본적으로 보이는 것으로 가정

    // Use the stored IndexedStack reference instead of finding it again
    if (_parentIndexedStack != null) {
      // 현재 인덱스가 0(메모리 게임 탭)인지 확인
      isCurrentlyVisible = _parentIndexedStack!.index == 0;
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

  // 두 플레이어 목록이 동일한지 비교하는 헬퍼 메서드
  bool _arePlayerListsEqual(
      List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i]['id'] != list2[i]['id']) {
        return false;
      }
    }

    return true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store a reference to the parent IndexedStack
    _parentIndexedStack = context.findAncestorWidgetOfExactType<IndexedStack>();

    final languageProvider = Provider.of<LanguageProvider>(context);
    if (targetLanguage != languageProvider.currentLanguage && mounted) {
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
          // Don't start timer here, wait for first card click instead
          // _startTimer();
        }
      } catch (e) {
        print('Error initializing game: $e');
        if (mounted) {
          setState(() {
            hasError = true;
          });
        }
      }
    });
  }

  Future<void> initializeGame() async {
    // 타이머 취소 추가
    _timer?.cancel();

    if (!mounted) return;

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
      _itemUsedInCurrentGame = false; // 아이템 사용 상태 초기화
    });

    widget.resetScores();

    List<String> dimensions = widget.gridSize.split('x');
    // 그리드 크기 파싱: 표기법은 "열x행" 형태임
    // 첫 번째 숫자는 열(column) 수, 두 번째 숫자는 행(row) 수로 할당
    gridColumns = int.parse(dimensions[0]); // 첫 번째 숫자를 열 수로 설정
    gridRows = int.parse(dimensions[1]); // 두 번째 숫자를 행 수로 설정

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
          //_subscribeToGameState();

          // 플레이어 정보 로드
          //await _loadMultiplayerData();
        } else {
          // 게임 세션 정보가 없으면 오류 표시
          if (mounted) {
            setState(() {
              hasError = true;
            });
          }
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

    if (!mounted) return;

    setState(() {
      isInitialized = true;
      // Don't set isGameStarted to true here
      // Wait for first card click instead
    });

    // 로컬 멀티플레이어 모드에서 MemoryGameService 초기화
    if (widget.numberOfPlayers > 1 && !widget.isMultiplayerMode) {
      print('로컬 멀티플레이어 초기화 시작: 총 플레이어 수 = ${widget.numberOfPlayers}');

      // 서비스 초기화 확인
      if (_memoryGameService == null) {
        print('서비스가 초기화되지 않았습니다. 다시 초기화합니다.');
        _memoryGameService =
            Provider.of<MemoryGameService>(context, listen: false);
      }

      // 게임 초기화
      _memoryGameService?.initializeGame();

      // 서비스 상태 확인을 위한 출력
      print('게임 초기화 후 현재 턴: ${_memoryGameService?.currentPlayerIndex}');
      print('게임 초기화 후 점수 상태: ${_memoryGameService?.playerScores}');
    }
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
      if (!mounted) return;

      setState(() {
        cardAnimationTriggers[index] = true;
      });
      Future.delayed(Duration(milliseconds: 500), () {
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
        if (!mounted) return;

        setState(() {
          isGameStarted = true;
          _remainingTime = _gameTimeLimit;
          _gameStartTime = DateTime.now(); // 게임 시작 시간 기록
        });
        _startTimer();
      }

      // 로컬 UI 업데이트 - 별 애니메이션 트리거 제거
      if (!mounted) return;

      setState(() {
        cardFlips[index] = true;
        selectedCards.add(index);
        // 카드 선택 시 별 애니메이션 트리거하지 않음
      });

      // 멀티플레이어 모드에서는 Firestore 업데이트
      if (widget.isMultiplayerMode &&
          widget.gameId != null &&
          widget.myPlayerId != null) {
        //await _updateCardStateInFirestore(index, true);

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
            //await _updateMatchInFirestore(isMatch);
          }
        }
      } else {
        // 싱글플레이어 모드 - 기존 로직 유지
        try {
          // 번역된 단어 가져오기 및 발음
          if (index < gameImages.length) {
            final translatedWord = getLocalizedWord(gameImages[index]);
            print('targetLanguage: $targetLanguage');
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
    if (!mounted) return;

    setState(() {
      bool isMatch =
          gameImages[selectedCards[0]] == gameImages[selectedCards[1]];

      if (isMatch) {
        // 카드가 매치될 때 양쪽 카드에 별 애니메이션 트리거
        _triggerStarAnimation(selectedCards[0]);
        _triggerStarAnimation(selectedCards[1]);

        // 아이템 드롭 처리 추가
        _handleItemDrop();

        // 멀티플레이어 모드에서는 점수 업데이트를 Firestore에 반영
        if (widget.isMultiplayerMode) {
          //_updateMatchInFirestore(true);
        } else if (widget.numberOfPlayers > 1) {
          // 로컬 멀티플레이어 모드에서는 memory_game_service를 통해 점수와 턴 관리
          print('매치 성공: memory_game_service.handleCardMatchResult(true) 호출 전');
          _memoryGameService?.handleCardMatchResult(true);
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
          //_updateMatchInFirestore(false);
        } else if (widget.numberOfPlayers > 1) {
          // 로컬 멀티플레이어 모드에서는 memory_game_service를 통해 턴 관리
          print('매치 실패: memory_game_service.handleCardMatchResult(false) 호출 전');
          _memoryGameService?.handleCardMatchResult(false);
          print(
              '매치 실패: 턴 변경 후 현재 플레이어 = ${_memoryGameService?.currentPlayerIndex}');
          // widget.nextPlayer() 호출 제거 - memory_game_service에서 모든 턴 관리 담당
        } else {
          // 싱글플레이어 모드에서는 로컬 턴 변경 없음
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
                SizedBox(height: 24),
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
    // 기존 TranslationService 코드 제거, LanguageProvider 직접 사용
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final languageCode = languageProvider.currentLanguage;

    switch (languageCode) {
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
      case '4x6':
        return 120; // 4x6는 2분
      case '6x6':
        return 180; // 6x6는 3분
      case '6x8':
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
    prefs = await SharedPreferences.getInstance();
    bool tutorialShown = prefs?.getBool(_tutorialPrefKey) ?? false;

    setState(() {
      _showTutorial = !tutorialShown;
    });
  }

  // 튜토리얼 표시 여부 저장
  Future<void> _saveTutorialPreference() async {
    if (_doNotShowAgain) {
      if (prefs != null) {
        await prefs!.setBool(_tutorialPrefKey, true);
      } else {
        prefs = await SharedPreferences.getInstance();
        await prefs!.setBool(_tutorialPrefKey, true);
      }
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
                        height: 45, // 높이 줄임
                        child: Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          child: Row(
                            children: [
                              // 시간 표시 텍스트
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getColorByTimeRatio(
                                          _remainingTime / _gameTimeLimit)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      size: 16,
                                      color: _getColorByTimeRatio(
                                          _remainingTime / _gameTimeLimit),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '$_remainingTime s',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: _getColorByTimeRatio(
                                            _remainingTime / _gameTimeLimit),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 10),
                              // 프로그레스 바
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: _remainingTime / _gameTimeLimit,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getColorByTimeRatio(
                                        _remainingTime / _gameTimeLimit),
                                  ),
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              SizedBox(width: 10),
                              // 시간 추가 버튼
                              if (widget.isTimeAttackMode)
                                ElevatedButton.icon(
                                  onPressed: _canAddTime &&
                                          isGameStarted &&
                                          _elapsedTime >= _timeAddMinElapsed
                                      ? _addExtraTime
                                      : null,
                                  icon: Icon(Icons.add, size: 14),
                                  label: Text('+30s',
                                      style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _canAddTime &&
                                            isGameStarted &&
                                            _elapsedTime >= _timeAddMinElapsed
                                        ? instagramGradientStart
                                        : Colors.grey,
                                    foregroundColor: Colors.white,
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8),
                                    minimumSize: Size(50, 30),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
                              'x')[0]), // 첫 번째 숫자(열 수)를 crossAxisCount로 설정
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
              // 아이템 팝업 추가
              _buildItemPopup(),
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
    if (!_showTutorial) return const SizedBox.shrink();

    // 언어 번역 가져오기
    final translations = Provider.of<LanguageProvider>(context, listen: false)
        .getUITranslations();

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Card(
          color: Colors.white,
          margin: const EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  translations['memory_game_guide'] ?? 'Memory Game Guide',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTutorialItem(
                    Icons.touch_app,
                    translations['card_selection_title'] ?? 'Card Selection',
                    translations['card_selection_desc'] ??
                        'Tap cards to flip and find matching pairs.'),
                _buildTutorialItem(
                    Icons.timer,
                    translations['time_limit_title'] ?? 'Time Limit',
                    translations['time_limit_desc'] ??
                        'Match all pairs within time limit. Faster matching earns higher score.'),
                _buildTutorialItem(
                    Icons.add_alarm,
                    translations['add_time_title'] ?? 'Add Time',
                    translations['add_time_desc'] ??
                        'Tap "+30s" to add time (costs Brain Health points).'),
                _buildTutorialItem(
                    Icons.people,
                    translations['multiplayer_title'] ?? 'Multiplayer',
                    translations['multiplayer_desc'] ??
                        'Change player count (1-4) to play with friends.'),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showTutorial = false;
                          prefs?.setBool('showMemoryGameTutorial', false);
                        });
                      },
                      child: Text(
                        translations['dont_show_again'] ?? 'Don\'t show again',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showTutorial = false;
                        });
                      },
                      child: Text(translations['start_game'] ?? 'Start Game'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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

  // 아이템 팝업 위젯
  Widget _buildItemPopup() {
    if (!_showItemPopup) return SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).size.height * 0.4,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [instagramGradientStart, instagramGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: instagramGradientStart.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shuffle,
                color: Colors.white,
                size: 40,
              ),
              SizedBox(height: 10),
              Text(
                Provider.of<LanguageProvider>(context)
                        .getUITranslations()['random_shake'] ??
                    'Random Shake!!',
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 아이템 드롭 처리
  void _handleItemDrop() {
    // 이미 아이템을 사용했으면 리턴
    if (_itemUsedInCurrentGame) return;

    if (Random().nextDouble() < ITEM_DROP_CHANCE) {
      setState(() {
        _currentItem = ITEM_SHAKE;
        _showItemPopup = true;
        _itemUsedInCurrentGame = true; // 아이템 사용 표시
      });

      // 2초 후 팝업 숨기기
      _itemPopupTimer?.cancel();
      _itemPopupTimer = Timer(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showItemPopup = false;
          });
        }
      });

      // Shake 아이템 효과 적용
      _applyShakeItem();
    }
  }

  // Shake 아이템 효과 적용
  void _applyShakeItem() {
    // 매치되지 않은 카드들의 인덱스 찾기
    List<int> unmatchedIndices = [];
    for (int i = 0; i < cardFlips.length; i++) {
      if (!cardFlips[i]) {
        unmatchedIndices.add(i);
      }
    }

    // 매치되지 않은 카드들의 이미지 ID 저장
    List<String> unmatchedImages = [];
    for (int index in unmatchedIndices) {
      unmatchedImages.add(gameImages[index]);
    }

    // 이미지 순서 섞기
    unmatchedImages.shuffle();

    // 섞인 이미지를 다시 할당
    for (int i = 0; i < unmatchedIndices.length; i++) {
      gameImages[unmatchedIndices[i]] = unmatchedImages[i];
    }

    // UI 업데이트
    setState(() {});
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

  Future<Map<String, dynamic>> _updateBrainHealthScore(int elapsedTime) async {
    // 매치된 카드 쌍의 개수 계산
    final int totalMatches = gameImages.length ~/ 2;
    int pointsEarned = 0;

    try {
      // 로컬 멀티플레이어 모드에서 승자 결정
      String winner = "";
      bool isLoggedInUserWinner = true;
      List<String> tiedPlayers = []; // 동점자 목록 저장 변수 추가

      if (widget.numberOfPlayers > 1 &&
          !widget.isMultiplayerMode &&
          _memoryGameService != null) {
        // 승자 결정
        List<MapEntry<String, int>> scoreEntries = [];

        // 첫 번째 플레이어(현재 사용자) 정보 추가
        User? user = FirebaseAuth.instance.currentUser;
        String currentUserName =
            user?.displayName ?? user?.email?.split('@')[0] ?? 'You';
        int currentUserScore = _memoryGameService!.getPlayerScore(0);
        scoreEntries.add(MapEntry(currentUserName, currentUserScore));

        // 나머지 플레이어 정보 추가
        for (int i = 0; i < widget.selectedPlayers.length; i++) {
          String playerName = widget.selectedPlayers[i]['nickname'] as String;
          int playerScore = _memoryGameService!.getPlayerScore(i + 1);
          scoreEntries.add(MapEntry(playerName, playerScore));
        }

        // 점수 기준으로 내림차순 정렬
        scoreEntries.sort((a, b) => b.value.compareTo(a.value));

        print(
            '정렬된 점수: ${scoreEntries.map((e) => "${e.key}: ${e.value}").join(', ')}');

        // 승자 결정
        if (scoreEntries.isNotEmpty &&
            (scoreEntries.length == 1 ||
                scoreEntries[0].value > scoreEntries[1].value)) {
          winner = scoreEntries[0].key;
          isLoggedInUserWinner = (winner == currentUserName);
          print('승자: $winner, 로그인된 유저가 우승자인가? $isLoggedInUserWinner');
        } else {
          // 동점 상황 처리
          int highestScore = scoreEntries[0].value;
          for (var entry in scoreEntries) {
            if (entry.value == highestScore) {
              tiedPlayers.add(entry.key);
            } else {
              break; // 같은 점수가 아니면 중단
            }
          }

          print('동점 플레이어: ${tiedPlayers.join(', ')}');
          winner = 'Tie';
          isLoggedInUserWinner = tiedPlayers.contains(currentUserName);
          print(
              '동점 상황: ${tiedPlayers.length}명이 동점, 로그인된 유저가 동점자인가? $isLoggedInUserWinner');
        }
      }

      // Brain Health Provider에 게임 완료 정보 추가
      final brainHealthProvider =
          Provider.of<BrainHealthProvider>(context, listen: false);

      // 기본 점수 계산 (배수 적용 전)
      int basePointsEarned = brainHealthProvider.calculateGameCompletionPoints(
          totalMatches, elapsedTime, widget.gridSize);

      // 멀티플레이어 배수 적용
      int multiplier = widget.numberOfPlayers > 1 ? widget.numberOfPlayers : 1;
      int finalPointsEarned = basePointsEarned;
      if (multiplier > 1 && !widget.isMultiplayerMode) {
        finalPointsEarned = basePointsEarned * multiplier;
        print(
            '멀티플레이어 배수 적용: $basePointsEarned × $multiplier = $finalPointsEarned');
      }

      // 동점인 경우 점수 분배
      int dividedPoints = finalPointsEarned;
      if (winner == 'Tie' && tiedPlayers.isNotEmpty) {
        dividedPoints = (finalPointsEarned / tiedPlayers.length).floor();
        print(
            '동점자 ${tiedPlayers.length}명에게 점수 분배: $finalPointsEarned ÷ ${tiedPlayers.length} = $dividedPoints');
      }

      if (isLoggedInUserWinner) {
        print('로그인된 유저가 우승자입니다. 점수를 업데이트합니다.');
        // 로그인된 유저는 멀티플레이어 배수가 적용된 점수를 Firebase에 업데이트
        if (widget.numberOfPlayers > 1 && !widget.isMultiplayerMode) {
          // 멀티플레이어인 경우 playerCount 인수 전달
          if (winner == 'Tie') {
            // 동점인 경우 분배된 점수를 업데이트
            pointsEarned = await brainHealthProvider.addGameCompletion(
                totalMatches,
                elapsedTime,
                widget.gridSize,
                widget.numberOfPlayers,
                dividedPoints); // 분배된 점수 전달
            print('로그인된 유저에게 추가된 점수(동점 분배 적용): $pointsEarned');
          } else {
            pointsEarned = await brainHealthProvider.addGameCompletion(
                totalMatches,
                elapsedTime,
                widget.gridSize,
                widget.numberOfPlayers);
            print('로그인된 유저에게 추가된 점수(멀티플레이어 배수 적용): $pointsEarned');
          }
        } else {
          // 싱글플레이어인 경우 기본 호출 방식 유지
          pointsEarned = await brainHealthProvider.addGameCompletion(
              totalMatches, elapsedTime, widget.gridSize);
          print('로그인된 유저에게 추가된 점수: $pointsEarned');
        }
      } else {
        print('로그인된 유저가 우승자가 아닙니다. 점수를 업데이트하지 않습니다.');
        // 팝업창 표시를 위한 계산된 점수 사용
        pointsEarned = winner == 'Tie' ? dividedPoints : finalPointsEarned;
        print('계산된 점수(DB 업데이트 안 함): $pointsEarned');
      }

      // 로컬 멀티플레이어에서 로그인되지 않은 유저가 우승한 경우 Firebase에 동일한 점수 업데이트
      if (widget.numberOfPlayers > 1 &&
          !widget.isMultiplayerMode &&
          _memoryGameService != null) {
        if (winner == 'Tie') {
          // 동점인 경우 각 동점자에게 분배된 점수 업데이트
          for (int i = 0; i < widget.selectedPlayers.length; i++) {
            String playerName = widget.selectedPlayers[i]['nickname'] as String;
            if (tiedPlayers.contains(playerName)) {
              String playerId = widget.selectedPlayers[i]['id'] as String;
              print(
                  '동점 플레이어에게 분배된 점수 업데이트 - 플레이어: $playerName, ID: $playerId, 점수: $dividedPoints');

              // 동점 플레이어에게 분배된 점수 업데이트
              _updateFirebaseDirectly(playerId, dividedPoints);
            }
          }
        } else if (!isLoggedInUserWinner) {
          // 동점이 아니고 로그인된 유저가 우승자가 아닌 경우
          // 승자의 인덱스 찾기
          for (int i = 0; i < widget.selectedPlayers.length; i++) {
            if (widget.selectedPlayers[i]['nickname'] == winner) {
              String playerId = widget.selectedPlayers[i]['id'] as String;
              print(
                  '팝업창 계산 점수로 직접 업데이트 - 플레이어: $winner, ID: $playerId, 점수: $finalPointsEarned');

              // 팝업창에서 계산된 점수로 Firebase 직접 업데이트
              _updateFirebaseDirectly(playerId, finalPointsEarned);
              break;
            }
          }
        }
      }

      // 점수 및 승자 정보를 completion dialog에서 표시하기 위해 반환
      return {
        'points': pointsEarned,
        'winner': winner,
        'isLoggedInUserWinner': isLoggedInUserWinner,
      };
    } catch (e) {
      print('Error updating Brain Health score: $e');
      return {
        'points': 0,
        'winner': '',
        'isLoggedInUserWinner': false,
      };
    }
  }

  // Firebase 점수 직접 업데이트 메서드
  Future<void> _updateFirebaseDirectly(String playerId, int score) async {
    try {
      print('Firebase 점수 직접 업데이트 시작 - ID: $playerId, 점수: $score');

      // Firebase에서 플레이어 문서 가져오기
      DocumentSnapshot playerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(playerId)
          .get();

      if (!playerDoc.exists) {
        print('플레이어 문서가 존재하지 않습니다: $playerId');
        return;
      }

      Map<String, dynamic> playerData =
          playerDoc.data() as Map<String, dynamic>;

      // 현재 brain_health 데이터 가져오기
      Map<String, dynamic> brainHealth = {};
      if (playerData.containsKey('brain_health') &&
          playerData['brain_health'] is Map) {
        brainHealth = Map<String, dynamic>.from(playerData['brain_health']);
      }

      // 현재 brainHealthScore 가져오기
      int currentScore = 0;
      if (brainHealth.containsKey('brainHealthScore')) {
        currentScore = brainHealth['brainHealthScore'] as int;
      }

      // 점수 업데이트
      int newScore = currentScore + score;
      brainHealth['brainHealthScore'] = newScore;
      print('점수 직접 업데이트: $currentScore → $newScore (+$score)');

      // Firebase에 업데이트된 brain_health 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(playerId)
          .update({'brain_health': brainHealth});

      print('플레이어 $playerId의 점수 직접 업데이트 완료: $newScore');
    } catch (e) {
      print('점수 직접 업데이트 오류: $e');
      print(StackTrace.current);
    }
  }

  // 게임 완료 대화상자 표시
  void _showCompletionDialog(int elapsedTime) async {
    String languageCode =
        Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    String gridSize = widget.gridSize;

    // 게임 통계 업데이트 및 획득 점수 가져오기
    Map<String, dynamic> result = await _updateBrainHealthScore(elapsedTime);
    int basePointsEarned = result['points'];
    String winner = result['winner'];
    bool isLoggedInUserWinner = result['isLoggedInUserWinner'];

    // 번역 텍스트를 위한 언어 제공자
    final translations = Provider.of<LanguageProvider>(context, listen: false)
        .getUITranslations();

    // winningScore 계산
    int winningScore = 0;

    if (widget.numberOfPlayers > 1 && winner != 'Tie' && winner.isNotEmpty) {
      // Firebase에 저장되는 실제 점수 계산
      final brainHealthProvider =
          Provider.of<BrainHealthProvider>(context, listen: false);
      // 매치된 카드 쌍의 개수 계산
      final int totalMatches = gameImages.length ~/ 2;

      // 승자의 표시 점수 계산 - 실제 Brain Health에 적용되는 점수 계산 방식 사용
      int calculatedScore = brainHealthProvider.calculateGameCompletionPoints(
          totalMatches, elapsedTime, widget.gridSize);

      // 멀티플레이어 점수 배율 적용
      int multiplier = widget.numberOfPlayers;
      winningScore = calculatedScore * multiplier;
    }

    // 플레이어 수에 따른 점수 배율 계산
    int multiplier = 1;
    if (widget.numberOfPlayers > 1) {
      multiplier = widget.numberOfPlayers;
    }

    // 최종 점수 계산 (팝업창에 표시할 점수)
    int finalPointsEarned = basePointsEarned;

    // 게임 통계 업데이트 (기본 점수 기준)
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
                  // 로컬 멀티플레이어일 경우 승자 표시, 싱글이면 "Congratulations!"
                  widget.numberOfPlayers > 1
                      ? (winner != 'Tie' && winner.isNotEmpty
                          ? translations['winner']
                                  ?.replaceAll('{name}', winner) ??
                              "Winner: $winner!"
                          : winner == 'Tie'
                              ? translations['its_a_tie'] ?? "It's a Tie!"
                              : translations['congratulations'] ??
                                  "Congratulations!")
                      : translations['congratulations'] ?? "Congratulations!",
                  style: GoogleFonts.montserrat(
                    fontSize: 24, // 글씨 크기 조정
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                if (winner == 'Tie' && widget.numberOfPlayers > 1)
                  Text(
                    translations['points_divided'] ??
                        "Points are divided equally among tied players!",
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (winner == 'Tie' && widget.numberOfPlayers > 1)
                  SizedBox(height: 8),
                if (widget.isTimeAttackMode) ...[
                  Text(
                    (translations['time_seconds'] ?? "Time: {seconds} seconds")
                        .replaceAll('{seconds}', elapsedTime.toString()),
                    style: GoogleFonts.montserrat(
                      fontSize: 18, // 글씨 크기 조정
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                ],
                Text(
                  (translations['flips'] ?? "Flips: {count}")
                      .replaceAll('{count}', flipCount.toString()),
                  style: GoogleFonts.montserrat(
                    fontSize: 18, // 글씨 크기 조정
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                // 로컬 멀티플레이어 점수 계산 설명 추가
                if (widget.numberOfPlayers > 1) ...[
                  Text(
                    winner == 'Tie'
                        ? translations['points_divided_explanation'] ??
                            "(Points divided among tied players)"
                        : (translations['players_score_multiplier'] ??
                                "({players} Players: Score x{multiplier})")
                            .replaceAll(
                                '{players}', widget.numberOfPlayers.toString())
                            .replaceAll('{multiplier}', multiplier.toString()),
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                ],
                // 최종 획득 점수 표시 (Health Score)
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
                        Icons.psychology, // 아이콘 변경 또는 유지
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        // 최종 점수 표시
                        (translations['health_score'] ??
                                "Health Score: +{points}")
                            .replaceAll(
                                '{points}', finalPointsEarned.toString()),
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
                    translations['new_game'] ?? "New Game",
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
                        bool isCurrentPlayerTurn = false;
                        int playerIndex = widget.playerScores.keys
                            .toList()
                            .indexOf(entry.key);
                        int score = 0;

                        if (widget.isMultiplayerMode) {
                          // 멀티플레이어 모드에서는 실제 닉네임 표시
                          if (playerIndex == 0) {
                            displayName = _myNickname ?? 'You';
                          } else {
                            displayName = _opponentNickname ?? 'Opponent';
                          }

                          // 현재 턴 표시 (내 턴일 때와 상대방 턴일 때)
                          isCurrentPlayerTurn =
                              (playerIndex == 0 && _isMyTurn) ||
                                  (playerIndex == 1 && !_isMyTurn);

                          // 온라인 멀티플레이어 모드에서는 widget의 점수 사용
                          score = entry.value;

                          return Flexible(
                            flex: isCurrentPlayerTurn
                                ? 70
                                : 30 ~/ (widget.playerScores.length - 1),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: isCurrentPlayerTurn
                                      ? 12
                                      : (widget.numberOfPlayers == 2 ? 4 : 2),
                                  vertical: isCurrentPlayerTurn
                                      ? 6
                                      : (widget.numberOfPlayers == 2 ? 2 : 1)),
                              margin: EdgeInsets.all(isCurrentPlayerTurn
                                  ? 3
                                  : (widget.numberOfPlayers == 2 ? 2 : 1)),
                              decoration: BoxDecoration(
                                color: isCurrentPlayerTurn
                                    ? null
                                    : Colors.transparent,
                                gradient: isCurrentPlayerTurn
                                    ? LinearGradient(
                                        colors: [
                                          instagramGradientStart
                                              .withOpacity(0.3),
                                          instagramGradientEnd.withOpacity(0.3)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(
                                    isCurrentPlayerTurn ? 20 : 10),
                                boxShadow: isCurrentPlayerTurn
                                    ? [
                                        BoxShadow(
                                          color: instagramGradientStart
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  isCurrentPlayerTurn
                                      ? FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            '$displayName: ${entry.value}',
                                            style: GoogleFonts.montserrat(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 18,
                                            ),
                                          ),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Transform.scale(
                                              scale: 0.7,
                                              child:
                                                  _buildPlayerFlag(entry.key),
                                            ),
                                            SizedBox(width: 1),
                                            // 플레이어 수에 따라 이름 표시 방식 변경
                                            if (widget.numberOfPlayers ==
                                                2) ...[
                                              Text(
                                                displayName.length > 5
                                                    ? displayName.substring(
                                                            0, 5) +
                                                        "..."
                                                    : displayName,
                                                style: GoogleFonts.montserrat(
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.white70,
                                                  fontSize: 10, // 2명일 때는 더 크게
                                                ),
                                              ),
                                              SizedBox(width: 1),
                                            ] else if (widget.numberOfPlayers ==
                                                3) ...[
                                              Text(
                                                displayName.length > 3
                                                    ? displayName.substring(
                                                            0, 3) +
                                                        ".."
                                                    : displayName,
                                                style: GoogleFonts.montserrat(
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.white70,
                                                  fontSize: 7,
                                                ),
                                              ),
                                              SizedBox(width: 1),
                                            ],
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 2, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                '${entry.value}',
                                                style: GoogleFonts.montserrat(
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.white60,
                                                  fontSize:
                                                      widget.numberOfPlayers ==
                                                              2
                                                          ? 9
                                                          : 7,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                  if (isCurrentPlayerTurn)
                                    Text(
                                      'Playing...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.yellow,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          // 로컬 멀티플레이어 모드
                          // 현재 플레이어 인덱스 확인
                          isCurrentPlayerTurn = playerIndex ==
                              _memoryGameService?.currentPlayerIndex;

                          // 닉네임 설정
                          if (playerIndex == 0) {
                            // 첫 번째 플레이어 - 현재 사용자 닉네임 사용
                            User? user = FirebaseAuth.instance.currentUser;
                            if (user != null &&
                                user.displayName != null &&
                                user.displayName!.isNotEmpty) {
                              displayName = user.displayName!;
                            } else {
                              displayName = user?.email?.split('@')[0] ?? 'You';
                            }
                          } else {
                            // 다른 플레이어들 - 선택된 플레이어 닉네임 사용
                            if (playerIndex > 0 &&
                                playerIndex <= widget.selectedPlayers.length) {
                              displayName =
                                  widget.selectedPlayers[playerIndex - 1]
                                      ['nickname'] as String;
                            } else {
                              displayName = 'Player ${playerIndex + 1}';
                            }
                          }

                          // memory_game_service에서 점수 가져오기
                          score =
                              _memoryGameService?.getPlayerScore(playerIndex) ??
                                  0;

                          return Flexible(
                            flex: isCurrentPlayerTurn
                                ? 70
                                : 30 ~/ (widget.playerScores.length - 1),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: isCurrentPlayerTurn
                                      ? 1
                                      : (widget.numberOfPlayers == 2 ? 2 : 0)),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: isCurrentPlayerTurn
                                        ? 2
                                        : (widget.numberOfPlayers == 2 ? 2 : 0),
                                    vertical: isCurrentPlayerTurn
                                        ? 6
                                        : (widget.numberOfPlayers == 2
                                            ? 2
                                            : 1)),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                      isCurrentPlayerTurn ? 16 : 10),
                                ),
                                child: isCurrentPlayerTurn
                                    // 현재 차례 플레이어: 더 크게 표시
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildPlayerFlag(entry.key),
                                          SizedBox(width: 1),
                                          Flexible(
                                            child: Text(
                                              displayName, // fullname 사용
                                              style: GoogleFonts.montserrat(
                                                color: Colors.blue[800],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18, // 크기 더 증가
                                                letterSpacing: 0.5,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: 1),
                                          Text(
                                            "($score)",
                                            style: GoogleFonts.montserrat(
                                              color: Colors.black87,
                                              fontSize: 16, // 크기 더 증가
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    // 대기 중인 플레이어: 훨씬 작게 표시
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Transform.scale(
                                            scale: 0.7,
                                            child: _buildPlayerFlag(entry.key),
                                          ),
                                          SizedBox(width: 1),
                                          // 플레이어 수에 따라 이름 표시 방식 변경
                                          if (widget.numberOfPlayers == 2) ...[
                                            Text(
                                              displayName.length > 5
                                                  ? displayName.substring(
                                                          0, 5) +
                                                      "..."
                                                  : displayName,
                                              style: GoogleFonts.montserrat(
                                                fontWeight: FontWeight.normal,
                                                color: Colors.blue[800],
                                                fontSize: 10, // 2명일 때는 더 크게
                                              ),
                                            ),
                                            SizedBox(width: 1),
                                          ] else if (widget.numberOfPlayers ==
                                              3) ...[
                                            Text(
                                              displayName.length > 3
                                                  ? displayName.substring(
                                                          0, 3) +
                                                      ".."
                                                  : displayName,
                                              style: GoogleFonts.montserrat(
                                                fontWeight: FontWeight.normal,
                                                color: Colors.blue[800],
                                                fontSize: 7,
                                              ),
                                            ),
                                            SizedBox(width: 1),
                                          ],
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 2, vertical: 1),
                                            child: Text(
                                              '$score',
                                              style: GoogleFonts.montserrat(
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black87,
                                                fontSize:
                                                    widget.numberOfPlayers == 2
                                                        ? 9
                                                        : 7,
                                              ),
                                            ),
                                          ),
                                        ],
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
      //_subscribeToGameState();

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

  Widget _buildPlayerFlag(String playerName) {
    String countryCode = 'un'; // 기본값으로 UN 국가 코드 사용

    // 첫 번째 플레이어(현재 사용자)인 경우
    if (widget.playerScores.keys.toList().indexOf(playerName) == 0) {
      countryCode = widget.currentUserInfo['country'] as String? ?? 'un';
      print('플레이어 국기: $playerName(나) - 국가코드: $countryCode');
    }
    // 다른 플레이어인 경우
    else {
      int playerIndex =
          widget.playerScores.keys.toList().indexOf(playerName) - 1;
      if (playerIndex >= 0 && playerIndex < widget.selectedPlayers.length) {
        countryCode =
            widget.selectedPlayers[playerIndex]['country'] as String? ?? 'un';
        print(
            '플레이어 국기: $playerName - 국가코드: $countryCode (selectedPlayers[$playerIndex])');
      } else {
        print(
            '플레이어 국기 오류: $playerName - 인덱스 범위 초과 ($playerIndex vs ${widget.selectedPlayers.length})');
      }
    }

    // 소문자로 된 국가 코드를 대문자로 변환
    countryCode = countryCode.toUpperCase();

    return Flag.fromString(
      countryCode,
      height: 16,
      width: 24,
      borderRadius: 2,
      flagSize: FlagSize.size_4x3,
      fit: BoxFit.cover,
    );
  }

  // 플레이어의 국가명을 반환하는 메서드
  String _getPlayerCountry(String playerName) {
    String countryCode = 'Unknown';

    // 첫 번째 플레이어(현재 사용자)인 경우
    if (widget.playerScores.keys.toList().indexOf(playerName) == 0) {
      countryCode = widget.currentUserInfo['country'] as String? ?? 'un';
    }
    // 다른 플레이어인 경우
    else {
      int playerIndex =
          widget.playerScores.keys.toList().indexOf(playerName) - 1;
      if (playerIndex >= 0 && playerIndex < widget.selectedPlayers.length) {
        countryCode =
            widget.selectedPlayers[playerIndex]['country'] as String? ?? 'un';
      }
    }

    // 국가 코드를 국가명으로 변환 (간단하게)
    Map<String, String> countryNames = {
      'us': 'United States',
      'kr': 'South Korea',
      'jp': 'Japan',
      'cn': 'China',
      'gb': 'United Kingdom',
      'fr': 'France',
      'de': 'Germany',
      'it': 'Italy',
      'es': 'Spain',
      'ru': 'Russia',
      'ca': 'Canada',
      'au': 'Australia',
      'un': 'Unknown'
    };

    return countryNames[countryCode.toLowerCase()] ?? 'Unknown';
  }

  // 플레이어 턴이 변경되었을 때 호출되는 메서드
  void _onPlayerTurnChanged(int newPlayerIndex) {
    if (!mounted) return;

    setState(() {
      // UI 업데이트
    });
  }

  // 점수가 변경되었을 때 호출되는 메서드
  void _onScoreChanged(Map<int, int> scores) {
    if (!mounted) return;

    setState(() {
      // UI 업데이트
    });
  }

  // 시간 비율에 따른 색상 계산 함수 추가
  Color _getColorByTimeRatio(double ratio) {
    if (ratio > 0.6) return Colors.green; // 60% 이상: 녹색
    if (ratio > 0.4) return Colors.blue; // 40% 이상: 파란색
    if (ratio > 0.25) return Colors.amber; // 25% 이상: 노란색
    if (ratio > 0.1) return Colors.orange; // 10% 이상: 주황색
    return Colors.red; // 10% 미만: 빨간색
  }
}
