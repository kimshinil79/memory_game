import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tabs/memory_game_page.dart';
import 'tabs/test_page.dart';
import 'tabs/brain_health_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/language_provider.dart';
import 'providers/brain_health_provider.dart';
import 'package:flag/flag.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'utils/route_observer.dart';
import 'data/countries.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/l10n.dart';
import 'l10n/app_localizations.dart';
import 'widgets/player_selection_dialog.dart';
import 'widgets/grid_selection_dialog.dart';
import 'widgets/country_selection_dialog.dart';
import 'widgets/auth/sign_in_dialog.dart';
import 'widgets/auth/sign_up_dialog.dart';
import 'widgets/auth/profile_edit_dialog.dart';
import 'widgets/auth/auth_dialogs.dart';
import 'widgets/buttons/profile_button.dart';
import 'widgets/buttons/control_button.dart';
import 'widgets/dialogs/language_dialog.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'services/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'item_list.dart' as images;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 앱이 백그라운드나 종료된 상태일 때 FCM 메시지를 처리하는 함수
  await Firebase.initializeApp();

  print('백그라운드 FCM 메시지 수신: ${message.messageId}');
  print('메시지 데이터: ${message.data}');

  // 여기서는 알림이 자동으로 표시되므로 별도 처리 필요 없음
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 렌더링 최적화 설정
  if (Platform.isAndroid) {
    // 세로 방향 고정 및 시스템 UI 최적화
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    // 렌더링 성능 최적화
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
  }

  try {
    print('Initializing Firebase app...');
    await Firebase.initializeApp();
    print('Firebase app initialized successfully');

    // FCM 백그라운드 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => BrainHealthProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize FCM after first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // FCM 서비스 초기화 (services/fcm_service.dart에 구현되어 있음)
        FCMService().initialize(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Game',
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          color: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      supportedLocales: L10n.all,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  String selectedLanguage = 'en-US';
  int _currentIndex = 0;
  int numberOfPlayers = 1;
  String gridSize = '4x4';
  int flipCount = 0;
  List<String> players = ['Genius', 'Idiot', 'Cute', 'Lovely'];
  Map<String, int> playerScores = {
    'Genius': 0,
    'Idiot': 0,
    'Cute': 0,
    'Lovely': 0
  };
  int currentPlayerIndex = 0;
  UniqueKey _memoryGameKey = UniqueKey();
  MemoryGamePage? _memoryGamePage;
  User? _user;
  String? _nickname;
  String? _profileImageUrl;
  int? _userAge;
  String? _userGender;
  String? _userCountryCode;
  StreamSubscription<User?>? _authSubscription;

  // FCM 메시지 구독
  StreamSubscription? _fcmMessageSubscription;

  // 게임 타이머 및 상태 변수 추가
  Timer? _gameTimer;
  bool _isGameActive = false;
  int _displayedGrid = 4;
  int _score = 0;

  // Add gradient color constants
  final Color instagramGradientStart = Color(0xFF833AB4);
  final Color instagramGradientEnd = Color(0xFFF77737);

  // 현재 게임 ID를 저장할 변수
  String? _currentGameId;

  // 알림 관련 변수 추가
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool isLocalNotificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 앱 시작 시 자동 로그인 확인
    _initializeAuth();

    // 사용자 데이터 마이그레이션
    _migrateUserData();

    // FCM 메시지 리스너 설정 (포그라운드 메시지 특별 처리용)
    _setupFCMMessageListener();

    // Firestore 게임 수락 알림 구독
    _listenForGameAcceptedNotifications();
  }

  @override
  void dispose() {
    // 구독 해제
    _authSubscription?.cancel();
    _fcmMessageSubscription?.cancel();
    super.dispose();
  }

  void _initializeAuth() {
    // 기존 구독이 있으면 취소
    _authSubscription?.cancel();

    // 새로운 구독 설정
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (!mounted) return;

      if (user == null) {
        setState(() {
          _user = null;
          _nickname = null;
        });
      } else {
        _fetchUserProfile(user);
      }
    });
  }

  Future<void> _fetchUserProfile(User user) async {
    if (!mounted) return;

    try {
      String uid = user.uid;

      // FCM 토큰 요청 및 저장
      _updateFCMToken(uid);

      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _user = user;
            _nickname = userData['nickname'] as String?;
            _userAge = userData['age'] as int?;
            _userGender = userData['gender'] as String?;
            _userCountryCode = userData['country'] as String?;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _user = user;
            _nickname = null;
            _userAge = null;
            _userGender = null;
            _userCountryCode = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _user = user;
          _nickname = null;
          _userAge = null;
          _userGender = null;
          _userCountryCode = null;
        });
      }
    }
  }

  // FCM 토큰을 요청하고 저장하는 함수
  Future<void> _updateFCMToken(String userId) async {
    try {
      print('Updating FCM token for user: $userId');

      // 현재 FCM 토큰 요청
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        String? token = await messaging.getToken();
        if (token != null) {
          print(
              'FCM token retrieved for user $userId: ${token.substring(0, 10)}...');

          // Firestore에 저장
          await _saveTokenToFirestore(userId, token);

          // 토큰 저장 확인
          DocumentSnapshot tokenDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('tokens')
              .doc('fcm')
              .get();

          if (tokenDoc.exists) {
            print(
                'FCM token successfully verified in database for user: $userId');
          } else {
            print('WARNING: FCM token verification failed for user: $userId');
          }
        } else {
          print('Failed to get FCM token for user: $userId');
        }
      } else {
        print('Notification permissions not granted for user: $userId');
        // 필요하다면 여기서 사용자에게 알림을 보여줄 수 있음
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  Future<void> _migrateUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        String uid = user.uid;
        String emailPrefix = user.email!.split('@')[0];
        String oldDocumentId = '$emailPrefix$uid';
        String newDocumentId = uid;

        DocumentSnapshot newUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(newDocumentId)
            .get();

        DocumentSnapshot oldUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(oldDocumentId)
            .get();

        if (!newUserDoc.exists && oldUserDoc.exists) {
          Map<String, dynamic> userData =
              oldUserDoc.data() as Map<String, dynamic>;

          await FirebaseFirestore.instance
              .collection('users')
              .doc(newDocumentId)
              .set(userData);
        }
      }
    } catch (e) {
      // Error handling without print
    }
  }

  Future<void> _signOut() async {
    try {
      setState(() {
        _user = null;
        _nickname = null;
      });

      await FirebaseAuth.instance.signOut();

      setState(() {
        _memoryGameKey = UniqueKey();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out. Please try again.')),
      );

      _initializeAuth();
    }
  }

  void _showLanguageSelectionDialog(BuildContext context) {
    LanguageDialog.show(context);
  }

  void updateFlipCount(int count) {
    if (mounted) {
      setState(() {
        flipCount = count;
      });
    }
  }

  void updatePlayerScore(String player, int score) {
    setState(() {
      // Apply grid size multiplier to the score
      int multiplier = getGridSizeMultiplier(gridSize);
      playerScores[player] = score * multiplier;
    });
  }

  // Calculate score multiplier based on grid size
  int getGridSizeMultiplier(String gridSize) {
    switch (gridSize) {
      case '4x4':
        return 1; // Base multiplier
      case '6x4':
        return 3; // Triple points for 6x4 grid
      case '6x6':
        return 5; // 5x points for 6x6 grid
      case '8x6':
        return 8; // 8x points for 8x6 grid
      default:
        return 1;
    }
  }

  void nextPlayer() {
    setState(() {
      currentPlayerIndex = (currentPlayerIndex + 1) % numberOfPlayers;
    });
  }

  void resetScores() {
    setState(() {
      for (String player in players) {
        playerScores[player] = 0;
      }
    });
  }

  void updateNumberOfPlayers(int newNumberOfPlayers) {
    setState(() {
      numberOfPlayers = newNumberOfPlayers;
      currentPlayerIndex = 0;
      resetScores();
    });
  }

  void updateGridSize(String newGridSize) {
    setState(() {
      gridSize = newGridSize;
    });
  }

  // FCM 메시지 리스너 설정
  void _setupFCMMessageListener() {
    // 앱이 실행 중일 때 FCM 메시지를 처리하는 리스너 설정
    _fcmMessageSubscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('포그라운드 FCM 메시지 수신: ${message.notification?.title}');
      print('FCM 메시지 데이터: ${message.data}');

      // 현재 컨텍스트가 유효한 경우에만 처리
      if (mounted) {
        // 메시지 타입에 따라 다른 처리
        String messageType = message.data['type'] ?? '';

        if (messageType == 'challenge') {
          // 도전 요청 메시지 처리
          _showChallengeDialog(message);
        } else if (messageType == 'game_accepted') {
          // 도전 수락 메시지 처리
          _handleGameAcceptedMessage(message);
        } else if (message.notification != null) {
          // 기타 일반 메시지 처리 - 포그라운드 알림 표시 (스낵바)
          _showForegroundNotification(message);
        }
      }
    });
  }

  // 포그라운드 알림 표시 메서드 (스낵바만 표시)
  void _showForegroundNotification(RemoteMessage message) {
    try {
      // 알림 정보가 있는 경우에만 처리
      if (message.notification != null) {
        final title = message.notification?.title ?? '새 알림';
        final body = message.notification?.body ?? '';

        print('포그라운드 알림 표시: $title - $body');

        // 스낵바로 알림 표시
        if (mounted && context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (body.isNotEmpty)
                    Text(body, overflow: TextOverflow.ellipsis, maxLines: 2),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: '닫기',
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }

        // 시스템 알림은 FCMService에서 처리
      }
    } catch (e) {
      print('포그라운드 알림 표시 오류: $e');
    }
  }

  // 도전 요청 대화상자 표시
  void _showChallengeDialog(RemoteMessage message) {
    // 도전자 정보 추출
    final String senderNickname =
        message.data['senderNickname'] ?? '알 수 없는 사용자';
    final String gridSize = message.data['gridSize'] ?? '4x4';
    final String challengeId = message.data['challengeId'] ?? '';

    print('도전 요청 대화상자 - 발신자 닉네임: $senderNickname, 도전 ID: $challengeId');

    if (challengeId.isEmpty) {
      print('도전 ID가 없어 처리할 수 없습니다');
      return;
    }

    // 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0.0, 10.0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '새로운 도전 요청!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      '$senderNickname님이\n메모리 게임 도전장을 보냈습니다!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '그리드 크기: $gridSize',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade100,
                            foregroundColor: Colors.red.shade800,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _rejectChallenge(challengeId);
                          },
                          child: Text('거절'),
                        ),
                        SizedBox(width: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _acceptChallenge(challengeId);
                          },
                          child: Text('수락'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: CircleAvatar(
                  backgroundColor: Colors.purple,
                  radius: 20,
                  child: Icon(
                    Icons.sports_mma,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 도전 수락
  void _acceptChallenge(String challengeId) async {
    if (_user != null && challengeId.isNotEmpty) {
      try {
        // 로딩 표시
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(),
          ),
        );

        print('도전 수락 시작 - challengeId: $challengeId');

        // 도전 정보 가져오기
        DocumentSnapshot challengeDoc = await FirebaseFirestore.instance
            .collection('challenges')
            .doc(challengeId)
            .get();

        if (!challengeDoc.exists) {
          // 도전 정보가 없으면 오류 처리
          Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('도전 정보를 찾을 수 없습니다.'), backgroundColor: Colors.red));
          return;
        }

        // 도전 정보 파싱
        Map<String, dynamic> challengeData =
            challengeDoc.data() as Map<String, dynamic>;
        String senderId = challengeData['senderId'] ?? '';

        // 도전 상태 업데이트 - challenges 컬렉션만 업데이트
        await FirebaseFirestore.instance
            .collection('challenges')
            .doc(challengeId)
            .update({
          'status': 'accepted',
          'responseTime': FieldValue.serverTimestamp(),
        });

        // 수신자(자신)의 알림 상태 업데이트 - 읽음 표시만
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('notifications')
            .doc(challengeId)
            .update({
          'read': true,
        });

        // 게임 세션 생성
        String gameId = await _createGameSession(challengeId);

        // 도전을 보낸 사람(sender)의 FCM 토큰 가져오기
        String? senderFcmToken = await _getSenderFcmToken(senderId);

        // 도전 보낸 사람에게 게임 수락 알림 추가 (참조만 저장)
        if (senderId.isNotEmpty) {
          // 게임 수락 알림 ID 생성
          String acceptanceNotificationId = 'game_acceptance_${gameId}';

          await FirebaseFirestore.instance
              .collection('users')
              .doc(senderId)
              .collection('notifications')
              .doc(acceptanceNotificationId)
              .set({
            'type': 'game_accepted',
            'challengeId': challengeId, // 원본 도전 ID 참조
            'gameId': gameId, // 새로 생성된 게임 ID
            'read': false,
            'timestamp': FieldValue.serverTimestamp(),
          });

          print('도전자에게 게임 수락 알림 저장 완료 - 알림 ID: $acceptanceNotificationId');

          // FCM 토큰이 있으면 FCM 알림 보내기 (Cloud Functions에서 처리)
          if (senderFcmToken != null && senderFcmToken.isNotEmpty) {
            // 도전을 보낸 사람에게 FCM 알림 전송을 위한 데이터 저장
            await FirebaseFirestore.instance
                .collection('fcm_notifications')
                .add({
              'to': senderFcmToken,
              'data': {
                'type': 'game_accepted',
                'gameId': gameId,
                'challengeId': challengeId,
                'receiverId': _user!.uid,
                'receiverNickname': _nickname ?? 'Player 2',
                'title': '도전 수락',
                'body': '${_nickname ?? '상대방'}님이 도전을 수락했습니다. 게임이 시작됩니다!',
              },
              'timestamp': FieldValue.serverTimestamp(),
            });

            print('FCM 알림 요청 저장 완료');
          }
        }

        // 로딩 다이얼로그 닫기
        Navigator.of(context).pop();

        // 수락 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('도전을 수락했습니다. 게임이 시작됩니다.'),
            backgroundColor: Colors.green,
          ),
        );

        print('도전을 수락했습니다: $challengeId, 게임 ID: $gameId');

        if (gameId.isNotEmpty) {
          // 도전 정보 로드 및 멀티플레이어 게임 시작
          _loadChallengeAndStartGame(challengeId, gameId);
        }
      } catch (e) {
        // 에러 발생 시 로딩 다이얼로그가 열려있다면 닫기
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        print('도전 수락 중 오류 발생: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('도전 수락 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 사용자의 FCM 토큰 가져오기
  Future<String?> _getSenderFcmToken(String userId) async {
    try {
      DocumentSnapshot tokenDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc('fcm')
          .get();

      if (tokenDoc.exists && tokenDoc.data() != null) {
        Map<String, dynamic> tokenData =
            tokenDoc.data() as Map<String, dynamic>;
        return tokenData['token'] as String?;
      }
      return null;
    } catch (e) {
      print('FCM 토큰 가져오기 오류: $e');
      return null;
    }
  }

  // 게임 세션 생성
  Future<String> _createGameSession(String challengeId) async {
    try {
      User? user = _user;
      if (user == null) return '';

      // 도전 정보 가져오기
      DocumentSnapshot challengeDoc = await FirebaseFirestore.instance
          .collection('challenges')
          .doc(challengeId)
          .get();

      if (!challengeDoc.exists) return '';

      Map<String, dynamic> challengeData =
          challengeDoc.data() as Map<String, dynamic>;
      String senderId = challengeData['senderId'];
      String gridSize = challengeData['gridSize'] ?? '4x4';

      // 도전자(sender) 정보 가져오기
      DocumentSnapshot senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();

      String senderNickname = 'Unknown Player';
      if (senderDoc.exists) {
        Map<String, dynamic> senderData =
            senderDoc.data() as Map<String, dynamic>;
        senderNickname = senderData['nickname'] ?? 'Unknown Player';
      }

      // 자신의 닉네임 가져오기
      String myNickname = 'Player 2';
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        myNickname = userData['nickname'] ?? 'Player 2';
      }

      // 게임 보드 초기화 - 실제 이미지 카드 조합 생성
      List<Map<String, dynamic>> gameBoard = _generateGameBoard(gridSize);

      // 게임 세션 ID 생성
      String gameId = "${challengeId}_${DateTime.now().millisecondsSinceEpoch}";

      // 게임 세션 데이터 생성
      Map<String, dynamic> gameSessionData = {
        'player1': {'id': senderId, 'nickname': senderNickname, 'score': 0},
        'player2': {'id': user.uid, 'nickname': myNickname, 'score': 0},
        'gridSize': gridSize,
        'currentTurn': senderId, // 도전자가 먼저 시작
        'gameState': 'active',
        'startTime': FieldValue.serverTimestamp(),
        'lastMoveTime': FieldValue.serverTimestamp(),
        'board': gameBoard,
        'moves': [],
        'challengeId': challengeId,
      };

      // Firestore에 게임 세션 데이터 저장
      await FirebaseFirestore.instance
          .collection('game_sessions')
          .doc(gameId)
          .set(gameSessionData);

      // 생성된 게임 ID를 challenge 문서에 추가
      await FirebaseFirestore.instance
          .collection('challenges')
          .doc(challengeId)
          .update({
        'gameId': gameId,
        'gameStartTime': FieldValue.serverTimestamp()
      });

      return gameId;
    } catch (e) {
      print('게임 세션 생성 중 오류: $e');
      return '';
    }
  }

  // 게임 보드 생성
  List<Map<String, dynamic>> _generateGameBoard(String gridSize) {
    // 그리드 크기에 따라 행과 열 계산
    List<int> dimensions =
        gridSize.split('x').map((e) => int.parse(e)).toList();
    // 첫 번째 숫자(가로)를 columns로, 두 번째 숫자(세로)를 rows로 할당
    int columns = dimensions[0]; // 가로(x)
    int rows = dimensions[1]; // 세로(y)
    int totalCards = rows * columns;
    int pairCount = totalCards ~/ 2;

    // 이미지 목록 복사
    List<String> tempList = List<String>.from(images.itemList);
    tempList.shuffle(); // 랜덤하게 섞기

    // 필요한 이미지 쌍 선택
    List<String> selectedImages = tempList.take(pairCount).toList();

    // 각 이미지 쌍을 두 번 포함시켜 매칭 쌍 생성
    List<String> gameImages = [...selectedImages, ...selectedImages];
    gameImages.shuffle(); // 최종 카드 배치 섞기

    // 보드 생성
    List<Map<String, dynamic>> board = [];
    for (int i = 0; i < totalCards; i++) {
      board.add({
        'id': i,
        'imageId': gameImages[i], // 실제 이미지 ID 저장
        'isFlipped': false,
        'matchedBy': null
      });
    }

    return board;
  }

  // 도전 거절
  void _rejectChallenge(String challengeId) async {
    if (_user != null && challengeId.isNotEmpty) {
      try {
        print('도전 거절 시작 - challengeId: $challengeId');

        // challenges 컬렉션의 문서 업데이트
        await FirebaseFirestore.instance
            .collection('challenges')
            .doc(challengeId)
            .update({
          'status': 'rejected',
          'responseTime': FieldValue.serverTimestamp(),
        });

        // 수신자(자신)의 알림 상태만 읽음으로 표시
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('notifications')
            .doc(challengeId)
            .update({
          'read': true,
        });

        // 거절 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('도전을 거절했습니다.'),
            backgroundColor: Colors.orange,
          ),
        );

        print('도전을 거절했습니다: $challengeId');
      } catch (e) {
        print('도전 거절 중 오류 발생: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('도전 거절 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 도전 정보 로드 및 멀티플레이어 게임 시작
  Future<void> _loadChallengeAndStartGame(
      String challengeId, String gameId) async {
    try {
      // 게임 세션 정보 가져오기
      DocumentSnapshot gameSessionDoc = await FirebaseFirestore.instance
          .collection('game_sessions')
          .doc(gameId)
          .get();

      if (!gameSessionDoc.exists || !mounted) {
        print('게임 세션 정보를 찾을 수 없습니다: $gameId');
        return;
      }

      Map<String, dynamic> gameSessionData =
          gameSessionDoc.data() as Map<String, dynamic>;

      // 그리드 크기 설정
      String gridSize = gameSessionData['gridSize']?.toString() ?? '4x4';

      // player1(sender) 정보 가져오기
      Map<String, dynamic> player1 = gameSessionData['player1'] ?? {};
      String senderId = player1['id'] ?? '';
      String senderNickname = player1['nickname'] ?? '상대방';

      // 멀티플레이어 게임을 위한 MemoryGamePage 초기화
      _resetAndStartMultiplayerGame(
        gameId: gameId,
        gridSize: gridSize,
        opponentId: senderId,
        opponentNickname: senderNickname,
      );
    } catch (e) {
      print('도전 정보 로드 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('게임 정보 로드 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Firestore에서 게임 수락 알림 구독
  void _listenForGameAcceptedNotifications() {
    // 로그인 상태가 아니면 구독 중단
    if (_user == null) {
      print('로그인되지 않아 게임 수락 알림 구독을 건너뜁니다');
      return;
    }

    print('Firestore 게임 수락 알림 구독 시작 - 사용자 ID: ${_user!.uid}');
    User user = _user!;

    // 사용자의 notifications 컬렉션 구독 - 게임 수락 알림 필터링
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('type', isEqualTo: 'game_accepted')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      print('Firestore 게임 수락 알림 변경 감지: ${snapshot.docs.length}개의 알림');

      // 새로운 게임 수락 알림이 있는지 확인
      for (var doc in snapshot.docs) {
        _processGameAcceptanceNotification(doc);
      }
    }, onError: (error) {
      print('게임 수락 알림 구독 오류: $error');
    });
  }

  // 게임 수락 알림 처리를 위한 별도 메서드
  Future<void> _processGameAcceptanceNotification(DocumentSnapshot doc) async {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String gameId = data['gameId'] ?? '';
      String challengeId = data['challengeId'] ?? '';

      print(
          '게임 수락 알림 처리 중 - 알림 ID: ${doc.id}, gameId: $gameId, challengeId: $challengeId');

      if (gameId.isEmpty) {
        print('gameId가 없어 처리할 수 없습니다');
        return;
      }

      // 알림을 읽음으로 표시
      await doc.reference.update({'read': true});
      print('알림을 읽음으로 표시 완료');

      // 도전 정보 가져오기
      DocumentSnapshot challengeDoc = await FirebaseFirestore.instance
          .collection('challenges')
          .doc(challengeId)
          .get();

      if (!challengeDoc.exists) {
        print('도전 정보가 존재하지 않습니다');
        // 도전 정보가 없어도 게임 시작은 가능하므로 계속 진행
        _showGameAcceptedDialog(gameId, '상대방');
        return;
      }

      // 수신자 닉네임 가져오기
      String receiverNickname = '상대방';
      Map<String, dynamic> challengeData =
          challengeDoc.data() as Map<String, dynamic>;
      String receiverId = challengeData['receiverId'] ?? '';

      if (receiverId.isNotEmpty) {
        DocumentSnapshot receiverDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(receiverId)
            .get();

        if (receiverDoc.exists) {
          Map<String, dynamic> receiverData =
              receiverDoc.data() as Map<String, dynamic>;
          receiverNickname = receiverData['nickname'] ?? '상대방';
        }
      }

      // 대화상자 표시
      if (mounted) {
        _showGameAcceptedDialog(gameId, receiverNickname);
      }
    } catch (error) {
      print('도전 정보 처리 중 오류: $error');
    }
  }

  // 게임 수락 대화상자 표시 메서드
  void _showGameAcceptedDialog(String gameId, String receiverNickname) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0.0, 10.0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '도전이 수락되었습니다!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      '$receiverNickname님이\n도전을 수락했습니다!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '게임이 곧 시작됩니다',
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        print('게임 시작하기 버튼 클릭(FCM) - gameId: $gameId');
                        Navigator.of(context).pop();
                        // 도전을 보낸 사람도 같은 게임 세션으로 게임 시작
                        _startGameAsSender(gameId);
                      },
                      child: Text('게임 시작하기'),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: CircleAvatar(
                  backgroundColor: Colors.green,
                  radius: 20,
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Create MemoryGamePage instance and save reference
    if (_memoryGamePage == null) {
      print(
          'build 시 새 MemoryGamePage 인스턴스 생성 - isMultiplayerMode: ${numberOfPlayers > 1}');
      _memoryGamePage = MemoryGamePage(
        key: _memoryGameKey,
        numberOfPlayers: numberOfPlayers,
        gridSize: gridSize,
        updateFlipCount: updateFlipCount,
        updatePlayerScore: updatePlayerScore,
        nextPlayer: nextPlayer,
        currentPlayer: players[currentPlayerIndex],
        playerScores: playerScores,
        resetScores: resetScores,
        isTimeAttackMode: true,
        timeLimit: numberOfPlayers > 1 ? 180 : 60, // 멀티플레이어는 3분, 싱글플레이어는 1분
        isMultiplayerMode: numberOfPlayers > 1,
        gameId: numberOfPlayers > 1 ? _getCurrentGameId() : null,
        myPlayerId: _user?.uid,
      );
    }

    List<Widget> _pages = [
      GestureDetector(
        onTap: () {
          if (_user == null) {
            _showLoginRequiredDialog(context);
          }
        },
        child: AbsorbPointer(
          absorbing: _user == null,
          child: _memoryGamePage!,
        ),
      ),
      BrainHealthPage(),
      TestPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: _currentIndex == 0 ? 90 : 60,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Memory Game',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (_currentIndex != 1) ...[
                  const SizedBox(width: 8),
                  Container(
                    height: 24,
                    width: 1,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showLanguageSelectionDialog(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Consumer<LanguageProvider>(
                            builder: (context, languageProvider, child) {
                              String countryCode = languageProvider
                                  .currentLanguage
                                  .split('-')
                                  .last
                                  .toLowerCase();
                              return Flag.fromString(
                                countryCode,
                                height: 16,
                                width: 24,
                                borderRadius: 4,
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down,
                              size: 16, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                ],
                Spacer(),
                _buildUserProfileButton(),
              ],
            ),
            if (_currentIndex == 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildControlButton(
                            icon: Icons.people,
                            label:
                                '$numberOfPlayers Player${numberOfPlayers > 1 ? 's' : ''}',
                            onTap: _showPlayerSelectionDialog,
                          ),
                          const SizedBox(width: 8),
                          _buildControlButton(
                            icon: Icons.grid_on,
                            label: gridSize,
                            onTap: _showGridSizeSelectionDialog,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  instagramGradientStart,
                                  instagramGradientEnd
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flip, size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  '$flipCount',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          if (_currentIndex == 1)
            Consumer<BrainHealthProvider>(
              builder: (context, brainHealthProvider, child) {
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBrainHealthColor(
                            brainHealthProvider.preventionLevel)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.psychology,
                        color: _getBrainHealthColor(
                            brainHealthProvider.preventionLevel),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${brainHealthProvider.brainHealthScore}',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _getBrainHealthColor(
                              brainHealthProvider.preventionLevel),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          _changeTab(index);
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_on),
            label: 'Game',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'Brain Health',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Test',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ControlButton(
      icon: icon,
      label: label,
      onTap: onTap,
    );
  }

  Widget _buildUserProfileButton() {
    return ProfileButton(
      user: _user,
      nickname: _nickname,
      onSignInPressed: () => _showSignInDialog(context),
      onProfilePressed: () => _showAccountEditDialog(context),
      gradientStart: instagramGradientStart,
      gradientEnd: instagramGradientEnd,
    );
  }

  void _showAccountEditDialog(BuildContext context) async {
    final result = await ProfileEditDialog.show(
      context,
      nickname: _nickname,
      userAge: _userAge,
      userGender: _userGender,
      userCountryCode: _userCountryCode,
    );

    if (result != null) {
      if (result['signOut'] == true) {
        _showSignOutConfirmDialog(context);
        return;
      }

      try {
        if (_user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .update({
            'nickname': result['nickname'],
            'age': result['age'],
            'gender': result['gender'],
            'country': result['country'],
          });

          setState(() {
            _nickname = result['nickname'];
            _userAge = result['age'];
            _userGender = result['gender'];
            _userCountryCode = result['country'];
          });
        }
      } catch (e) {
        print('Profile update error: $e');
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Failed to update profile. Please try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showSignOutConfirmDialog(BuildContext context) {
    SignOutConfirmDialog.show(context, _signOut);
  }

  void _showSignInDialog(BuildContext context) async {
    final result = await SignInDialog.show(context);
    if (result != null) {
      if (result['signUp'] == true) {
        _showSignUpDialog(context);
        return;
      }

      try {
        final userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: result['email'],
          password: result['password'],
        );

        if (userCredential.user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

          if (userDoc.exists) {
            setState(() {
              _user = userCredential.user;
              _nickname = userDoc.data()?['nickname'];
              _userAge = userDoc.data()?['age'];
              _userGender = userDoc.data()?['gender'];
              _userCountryCode = userDoc.data()?['countryCode'];
            });
          }
        }
      } catch (e) {
        print('Sign in error: $e');
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Failed to sign in. Please check your credentials.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showSignUpDialog(BuildContext context) async {
    final userData = await SignUpDialog.show(context);
    if (userData != null) {
      try {
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: userData['email'],
          password: userData['password'],
        );

        if (userCredential.user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'nickname': userData['nickname'],
            'age': userData['age'],
            'gender': userData['gender'],
            'country': userData['country'],
          });

          setState(() {
            _user = userCredential.user;
            _nickname = userData['nickname'];
            _userAge = userData['age'];
            _userGender = userData['gender'];
            _userCountryCode = userData['country'];
          });
        }
      } catch (e) {
        print('Sign up error: $e');
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Failed to create account. Please try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Color _getBrainHealthColor(int level) {
    switch (level) {
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orangeAccent;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  void _showLoginRequiredDialog(BuildContext context) {
    LoginRequiredDialog.show(context, () => _showSignInDialog(context));
  }

  void _showPlayerSelectionDialog() async {
    final selectedPlayers =
        await PlayerSelectionDialog.show(context, numberOfPlayers);
    if (selectedPlayers != null) {
      setState(() {
        numberOfPlayers = selectedPlayers;
        currentPlayerIndex = 0;
        resetScores();
      });
    }
  }

  void _showGridSizeSelectionDialog() async {
    final selectedGridSize = await GridSelectionDialog.show(context, gridSize);
    if (selectedGridSize != null) {
      setState(() {
        gridSize = selectedGridSize;
      });
    }
  }

  // 현재 게임 ID를 가져오는 메서드
  String? _getCurrentGameId() {
    // 멀티플레이어 모드일 때 사용될 게임 ID
    // 실제 구현에서는 클래스 변수로 현재 게임 ID를 관리해야 함
    return _currentGameId;
  }

  // 탭 전환 처리
  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;

      // 게임 탭으로 전환하고 멀티플레이어 모드인 경우, 메모리 게임 페이지를 새로 생성
      if (_currentIndex == 0 && numberOfPlayers > 1 && _currentGameId != null) {
        print('게임 탭으로 전환 - 멀티플레이어 게임 업데이트');
        _memoryGamePage = MemoryGamePage(
          key: _memoryGameKey,
          numberOfPlayers: numberOfPlayers,
          gridSize: gridSize,
          updateFlipCount: updateFlipCount,
          updatePlayerScore: updatePlayerScore,
          nextPlayer: nextPlayer,
          currentPlayer: players[currentPlayerIndex],
          playerScores: playerScores,
          resetScores: resetScores,
          isTimeAttackMode: true,
          timeLimit: 180, // 멀티플레이어는 3분으로 설정
          isMultiplayerMode: true,
          gameId: _currentGameId,
          myPlayerId: _user?.uid,
        );
      }
    });
  }

  void _handleGameAcceptedMessage(RemoteMessage message) async {
    try {
      // FCM 메시지에서 필요한 정보 추출
      String gameId = message.data['gameId'] ?? '';
      String challengeId = message.data['challengeId'] ?? '';
      String receiverNickname = message.data['receiverNickname'] ?? '상대방';

      print(
          '게임 수락 메시지 처리 - gameId: $gameId, challengeId: $challengeId, 수신자: $receiverNickname');

      // gameId가 비어있으면 로그 출력 후 종료
      if (gameId.isEmpty) {
        print('gameId가 비어있어 처리할 수 없습니다');
        return;
      }

      // 유효한 사용자가 로그인 상태인 경우 알림 정보 로깅
      if (_user != null) {
        // Firestore에 알림 로깅
        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'game_accepted',
          'gameId': gameId,
          'challengeId': challengeId,
          'receiverId': message.data['receiverId'] ?? '',
          'receiverNickname': receiverNickname,
          'userId': _user!.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'read': true,
        });
      }

      // 게임 수락 대화상자 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10.0,
                        offset: Offset(0.0, 10.0),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '도전이 수락되었습니다!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        '$receiverNickname님이\n도전을 수락했습니다!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '게임이 곧 시작됩니다',
                          style: TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          print('게임 시작하기 버튼 클릭(FCM) - gameId: $gameId');
                          Navigator.of(context).pop();
                          // 도전을 보낸 사람도 같은 게임 세션으로 게임 시작
                          _startGameAsSender(gameId);
                        },
                        child: Text('게임 시작하기'),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: CircleAvatar(
                    backgroundColor: Colors.green,
                    radius: 20,
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print('게임 수락 메시지 처리 중 오류: $e');
    }
  }

  Future<void> _startGameAsSender(String gameId) async {
    try {
      print('도전자로서 게임 시작 - 게임 ID: $gameId');

      if (gameId.isEmpty) {
        print('게임 ID가 없어 시작할 수 없습니다');
        return;
      }

      // 게임 세션 정보 가져오기
      DocumentSnapshot gameDoc = await FirebaseFirestore.instance
          .collection('game_sessions')
          .doc(gameId)
          .get();

      if (!gameDoc.exists) {
        print('게임 세션이 존재하지 않습니다: $gameId');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('게임 정보를 찾을 수 없습니다'), backgroundColor: Colors.red));
        return;
      }

      Map<String, dynamic> gameData = gameDoc.data() as Map<String, dynamic>;

      // 그리드 크기 설정 - 문자열 그대로 사용(예: "6x4")
      String gridSizeStr = gameData['gridSize']?.toString() ?? '4x4';

      // player2 정보 가져오기
      Map<String, dynamic> player2 = gameData['player2'] ?? {};
      String receiverId = player2['id'] ?? '';
      String receiverNickname = player2['nickname'] ?? '상대방';

      // 현재 게임 ID 설정
      _currentGameId = gameId;

      // 멀티플레이어 게임 설정 및 화면 전환
      setState(() {
        // 기존 게임 타이머 취소
        _gameTimer?.cancel();

        // 플레이어 설정 업데이트
        numberOfPlayers = 2;
        players = [_nickname ?? '나', receiverNickname];
        playerScores = {players[0]: 0, players[1]: 0};
        currentPlayerIndex = 0;

        // 그리드 크기 업데이트
        gridSize = gridSizeStr;

        // 새 게임 생성
        _memoryGamePage = MemoryGamePage(
          key: UniqueKey(),
          numberOfPlayers: 2,
          gridSize: gridSizeStr,
          updateFlipCount: updateFlipCount,
          updatePlayerScore: updatePlayerScore,
          nextPlayer: nextPlayer,
          currentPlayer: players[currentPlayerIndex],
          playerScores: playerScores,
          resetScores: resetScores,
          isTimeAttackMode: true,
          timeLimit: 180, // 멀티플레이어는 3분으로 설정
          isMultiplayerMode: true,
          gameId: gameId,
          myPlayerId: _user?.uid,
        );

        // 게임 화면으로 전환
        _currentIndex = 0;
      });

      // 약간의 지연 후 UI 업데이트 강제 (화면 전환 문제 방지)
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            // _currentIndex를 강제로 0으로 설정하여 UI 업데이트
            _currentIndex = 0;
          });
        }
      });

      print('도전자로서 게임 시작 완료 - 게임 ID: $gameId');
    } catch (e) {
      print('도전자로서 게임 시작 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('게임 시작 중 오류가 발생했습니다'), backgroundColor: Colors.red));
    }
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      print('FCM 토큰 Firestore에 저장 시작 - 사용자: $userId');

      // Firestore 'users' 컬렉션의 사용자 문서 내 'tokens' 하위 컬렉션에 토큰 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc('fcm')
          .set({
        'token': token,
        'device': Platform.isIOS ? 'iOS' : 'Android',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('FCM 토큰 저장 완료');
    } catch (e) {
      print('FCM 토큰 저장 오류: $e');
    }
  }

  void _resetAndStartMultiplayerGame({
    required String gameId,
    required String gridSize,
    required String opponentId,
    required String opponentNickname,
  }) {
    print('멀티플레이어 게임 초기화 시작 - gameId: $gameId, gridSize: $gridSize');

    // 기존 게임 타이머 취소
    if (_gameTimer != null && _gameTimer!.isActive) {
      _gameTimer!.cancel();
    }

    // 플레이어 설정 업데이트
    setState(() {
      // 멀티플레이어 모드로 설정
      numberOfPlayers = 2;

      // 플레이어 이름 설정 (자신과 상대방)
      players = [_nickname ?? '나', opponentNickname];

      // 점수 초기화
      playerScores = {players[0]: 0, players[1]: 0};

      // 시작 플레이어 설정
      currentPlayerIndex = 0;

      // 그리드 크기 업데이트
      this.gridSize = gridSize;

      // 현재 게임 ID 설정
      _currentGameId = gameId;

      // 새 게임 페이지 생성
      _memoryGamePage = MemoryGamePage(
        key: UniqueKey(),
        numberOfPlayers: 2,
        gridSize: this.gridSize,
        updateFlipCount: updateFlipCount,
        updatePlayerScore: updatePlayerScore,
        nextPlayer: nextPlayer,
        currentPlayer: players[currentPlayerIndex],
        playerScores: playerScores,
        resetScores: resetScores,
        isTimeAttackMode: true,
        timeLimit: 180, // 멀티플레이어는 3분으로 설정
        isMultiplayerMode: true,
        gameId: gameId,
        myPlayerId: _user?.uid,
      );

      // 게임 화면으로 전환
      _currentIndex = 0;
    });

    // 약간의 지연 후 UI 업데이트 강제 (화면 전환 문제 방지)
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          // _currentIndex를 강제로 0으로 설정하여 UI 업데이트
          _currentIndex = 0;
        });
      }
    });

    print('멀티플레이어 게임 초기화 완료');
  }
}
