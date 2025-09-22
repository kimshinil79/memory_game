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
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_update/in_app_update.dart';
import 'utils/route_observer.dart';
import 'data/countries.dart';
import 'widgets/player_selection_dialog.dart';
import 'widgets/player_selection_handler.dart';
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
import 'item_list.dart' as images;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/memory_game_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:dynamic_color/dynamic_color.dart';

// Constants for SharedPreferences keys
const String PREF_USER_COUNTRY_CODE = 'user_country_code';

// FCM background handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  // Background message received
  print('📩 [BG] FCM message: id=${message.messageId}, data=${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp();

  // FCM init (mobile only)
  if (Platform.isAndroid || Platform.isIOS) {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission (iOS)
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Get and persist FCM token to Firestore
    try {
      final token = await messaging.getToken();
      print('🔑 FCM token: $token');
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .set({
            'fcmToken': newToken,
            'fcmUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      });
    } catch (e) {
      print('FCM init error: $e');
    }
  }

  // Local Notifications setup (mobile only)
  if (Platform.isAndroid || Platform.isIOS) {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Android channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // iOS foreground notification presentation options
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // AdMob 초기화 (모바일 플랫폼에서만)
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await MobileAds.instance.initialize();
      print('✅ AdMob 초기화 완료');

      // 실행 환경 확인 및 광고 모드 안내
      if (Platform.isAndroid) {
        print('📱 Android 기기에서 실행 중');
        // 에뮬레이터인지 실제 기기인지 확인
        print('🔍 실행 환경 확인:');
        print('   - 에뮬레이터: 항상 테스트 광고 표시');
        print('   - 실제 기기: 실제 광고 표시 (설정 후 최대 24시간 소요)');
        print('   - 새 광고 단위: 처음에는 테스트 광고 표시될 수 있음');
      } else if (Platform.isIOS) {
        print('📱 iOS 기기에서 실행 중');
        print('🔍 실행 환경 확인:');
        print('   - 시뮬레이터: 항상 테스트 광고 표시');
        print('   - 실제 기기: 실제 광고 표시 (설정 후 최대 24시간 소요)');
        print('   - 새 광고 단위: 처음에는 테스트 광고 표시될 수 있음');
      }

      // AdMob 설정 업데이트 (실제 광고용)
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          // 실제 광고를 위해 테스트 기기 ID 제거
          testDeviceIds: <String>[],
          tagForChildDirectedTreatment:
              TagForChildDirectedTreatment.unspecified,
          // 최대 광고 콘텐츠 등급 설정 (선택사항)
          maxAdContentRating: MaxAdContentRating.t,
        ),
      );
      print('✅ AdMob 실제 광고 설정 완료');
      print('💡 참고: 에뮬레이터에서는 항상 "Test Ad"가 표시됩니다.');
      print('   실제 광고를 보려면 실제 기기에서 테스트하세요.');
    } catch (e) {
      print('❌ AdMob 초기화 실패: $e');
    }
  } else {
    print('🌐 웹 플랫폼에서 실행 중 - AdMob 초기화 건너뜀');
  }

  // Configure Google Fonts to use local fonts as fallbacks
  GoogleFonts.config.allowRuntimeFetching = true;

  // 렌더링 최적화 설정 (모바일 플랫폼에서만)
  if (Platform.isAndroid || Platform.isIOS) {
    // 세로 방향 고정 및 시스템 UI 최적화
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Android 15+ edge-to-edge compatible system UI configuration
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
    );

    // Use immersive mode to hide navigation bar completely
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top],
    );
  }

  try {
    print('Initializing Firebase app...');
    await Firebase.initializeApp();
    print('Firebase app initialized successfully');

    // Firebase Auth 설정 확인
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      print('Firebase Auth instance ready');

      // Firebase Auth의 언어 코드 설정 (선택사항)
      auth.setLanguageCode('ko');
    } catch (authError) {
      print('Firebase Auth setup error: $authError');
    }
  } catch (e) {
    print('Firebase initialization error: $e');
    print('Stack trace: ${StackTrace.current}');
  }

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Memory Game',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => BrainHealthProvider()),
          ChangeNotifierProvider(create: (context) => MemoryGameService()),
        ],
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String selectedLanguage = 'en-US';
  int _currentIndex = 0;
  int numberOfPlayers = 1;
  String gridSize = '4x4';
  int flipCount = 0;

  // PageController 추가
  late PageController _pageController;

  // 기존 하드코딩된 플레이어 리스트 대신 실제 유저 정보를 담을 리스트로 변경
  List<Map<String, dynamic>> selectedPlayerData = [];
  // 선택된 플레이어 닉네임 리스트 (UI 표시용)
  List<String> players = [''];

  Map<String, int> playerScores = {'': 0};

  // 다른 멤버 변수들
  int currentPlayerIndex = 0;
  UniqueKey _memoryGameKey = UniqueKey();
  MemoryGamePage? _memoryGamePage;
  User? _user;
  String? _nickname;
  String? _profileImageUrl;
  int? _userAge;
  String? _userGender;
  String? _userCountryCode;
  String? _shortPW;
  StreamSubscription<User?>? _authSubscription;
  MemoryGameService? _memoryGameService;

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
  bool isMultiplayerMode = false;

  // 폴더블폰 지원을 위한 변수
  bool _isFolded = false;
  Size _lastScreenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // FCM foreground message handling
    if (Platform.isAndroid || Platform.isIOS) {
      _setupFCM();
      _setupRemoteConfig();
    }

    // 초기 화면 크기 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFoldableState();
    });

    // PageController 초기화
    _pageController = PageController(initialPage: _currentIndex);

    // 앱 시작 시 자동 로그인 확인
    _initializeAuth();

    // Load saved country code from SharedPreferences
    _loadSavedUserCountry();

    // 사용자 데이터 마이그레이션
    _migrateUserData();

    // MemoryGameService 초기화 - 바로 초기화하도록 변경
    try {
      _memoryGameService =
          Provider.of<MemoryGameService>(context, listen: false);
    } catch (e) {
      print('MemoryGameService 초기화 오류: $e');
      // 나중에 다시 시도
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _memoryGameService =
              Provider.of<MemoryGameService>(context, listen: false);
        }
      });
    }

    // 앱 시작 시 TTS 언어 초기화
    _initializeTTSLanguage();
  }

  void _setupFCM() {
    // 1. App is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 [FG] FCM message received: ${message.notification?.title}');
      final notification = message.notification;
      if (notification != null) {
        // Use flutter_local_notifications to show notification
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel', // channel id
                'High Importance Notifications', // channel name
                channelDescription:
                    'This channel is used for important notifications.',
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ));
      }
    });

    // 2. App is in background and user taps on notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📩 Notification tapped (background): ${message.data}');
      // You can navigate to a specific page based on message data
    });

    // 3. App is terminated and user taps on notification
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        print('📩 Notification tapped (terminated): ${message.data}');
        // You can navigate to a specific page based on message data
      }
    });
  }

  Future<void> _setupRemoteConfig() async {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    await remoteConfig.setDefaults(const {
      "latest_version": "1.0.0",
    });

    await remoteConfig.fetchAndActivate();

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final latestVersion = remoteConfig.getString('latest_version');

    if (_isUpdateRequired(currentVersion, latestVersion)) {
      _showUpdateDialog();
    }
  }

  bool _isUpdateRequired(String currentVersion, String latestVersion) {
    final currentParts = currentVersion.split('.').map(int.parse).toList();
    final latestParts = latestVersion.split('.').map(int.parse).toList();

    for (var i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length || latestParts[i] > currentParts[i]) {
        return true;
      }
      if (latestParts[i] < currentParts[i]) {
        return false;
      }
    }
    return false;
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must choose an option
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Available'),
          content: const Text(
              'A new version of the app is available. Please update to continue.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Update Now'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog first
                _performUpdate();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performUpdate() async {
    if (Platform.isAndroid) {
      await _performInAppUpdate();
    } else if (Platform.isIOS) {
      await _launchStoreURL();
    }
  }

  Future<void> _performInAppUpdate() async {
    try {
      // Check if in-app update is available
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Flexible update (user can continue using the app)
        if (updateInfo.immediateUpdateAllowed) {
          // Immediate update (blocks the app until update is complete)
          await InAppUpdate.performImmediateUpdate();
        } else {
          // Flexible update (downloads in background)
          await InAppUpdate.startFlexibleUpdate();
        }
      } else {
        // Fallback to Play Store
        await _launchStoreURL();
      }
    } catch (e) {
      print('In-app update failed: $e');
      // Fallback to Play Store
      await _launchStoreURL();
    }
  }

  Future<void> _launchStoreURL() async {
    // App Store URLs
    final String appStoreUrl =
        'https://apps.apple.com/app/idYOUR_APP_ID'; // iOS App Store ID needed
    final String playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.brainhealth.memorygame';

    String url = '';
    if (Platform.isIOS) {
      url = appStoreUrl;
    } else if (Platform.isAndroid) {
      url = playStoreUrl;
    }

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void dispose() {
    // PageController 해제
    _pageController.dispose();

    // dispose 안에 추가 - null 체크 추가
    if (_memoryGameService != null) {
      _memoryGameService!.removeGridChangeListener(_onGridSizeChanged);
    }
    // 구독 해제
    _authSubscription?.cancel();
    super.dispose();
  }

  // 폴더블폰 상태 감지 및 업데이트
  void _updateFoldableState() {
    if (!mounted) return;

    final mediaQuery = MediaQuery.of(context);
    final currentSize = mediaQuery.size;

    // 화면 크기가 변경되었는지 확인
    if (_lastScreenSize != currentSize) {
      _lastScreenSize = currentSize;

      // 폴더블 상태 감지 (화면 비율로 판단)
      final aspectRatio = currentSize.width / currentSize.height;
      final newFoldedState = aspectRatio < 0.7 || aspectRatio > 1.8;

      if (_isFolded != newFoldedState) {
        setState(() {
          _isFolded = newFoldedState;
        });

        // LanguageProvider를 통해 폴더블 상태 업데이트
        try {
          final languageProvider =
              Provider.of<LanguageProvider>(context, listen: false);
          languageProvider.updateFoldableState(currentSize);
        } catch (e) {
          print('LanguageProvider 업데이트 실패: $e');
        }

        print('🔄 폴더블 상태 변경: ${_isFolded ? "폴드됨" : "펼쳐짐"}');
        print('📐 화면 크기: ${currentSize.width}x${currentSize.height}');
        print('📊 화면 비율: ${aspectRatio.toStringAsFixed(2)}');
      }
    }
  }

  void _initializeAuth() {
    // 기존 구독이 있으면 취소
    _authSubscription?.cancel();

    // 새로운 구독 설정
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (!mounted) return;

      if (user == null) {
        print('❌ 로그인된 사용자가 없습니다.');
        setState(() {
          _user = null;
          _nickname = null;
        });
      } else {
        print('✅ 로그인된 사용자 발견: ${user.uid}');
        _fetchUserProfile(user);
      }
    });
  }

  Future<void> _fetchUserProfile(User user) async {
    if (!mounted) return;

    try {
      String uid = user.uid;

      // 현재 로그인된 사용자의 문서 이름 출력
      print('🔑 현재 로그인된 사용자 문서 이름: $uid');

      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String? nickname = userData['nickname'] as String?;

        // 닉네임도 함께 출력
        print('👤 사용자 닉네임: ${nickname ?? '없음'}');
        if (mounted) {
          setState(() {
            _user = user;
            _nickname = userData['nickname'] as String?;
            _userAge = userData['age'] as int?;
            _userGender = userData['gender'] as String?;
            _userCountryCode = userData['country'] as String?;
            _shortPW = userData['shortPW'] as String?;
          });

          // Set nationality in LanguageProvider based on user's country code
          if (_userCountryCode != null) {
            final languageProvider =
                Provider.of<LanguageProvider>(context, listen: false);
            await languageProvider.setNationality(_userCountryCode!);

            // Save user's country code to SharedPreferences
            _saveUserCountryToLocalStorage(_userCountryCode!);
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _user = user;
            _nickname = null;
            _userAge = null;
            _userGender = null;
            _userCountryCode = null;
            _shortPW = null;
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
          _shortPW = null;
        });
      }
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
      // 1. 메모리 게임 관련 리소스 정리
      if (_memoryGamePage != null) {
        // 메모리 게임 페이지가 있는 경우 상태 정리 시도
        try {
          // 타이머 종료
          _gameTimer?.cancel();

          // 현재 멀티플레이어 게임 상태 초기화
          _currentGameId = null;
          isMultiplayerMode = false;

          // 메모리 게임 서비스 초기화
          if (_memoryGameService != null) {
            _memoryGameService!.gridSize = '4x4'; // 기본값으로 리셋
            _memoryGameService!.clearSelectedPlayers(); // 선택된 플레이어 목록 초기화
          }
        } catch (gameError) {
          print('메모리 게임 리소스 정리 중 오류: $gameError');
          // 오류가 발생해도 로그아웃은 계속 진행
        }
      }

      // Save country code before clearing user data
      String? countryCodeToSave = _userCountryCode;

      // 2. 상태 초기화 (첫 번째 단계)
      setState(() {
        // 사용자 정보 초기화
        _user = null;
        _nickname = null;
        _userAge = null;
        _userGender = null;
        _userCountryCode = null;
        _shortPW = null;

        // 게임 상태 초기화
        numberOfPlayers = 1;
        players = [''];
        playerScores = {'': 0};
        currentPlayerIndex = 0;
        gridSize = '4x4'; // 그리드 크기도 초기화
      });

      // 3. Firebase 로그아웃 수행
      await FirebaseAuth.instance.signOut();

      // Save the last used country code to SharedPreferences
      if (countryCodeToSave != null) {
        await _saveUserCountryToLocalStorage(countryCodeToSave);
      }

      // 4. UI 업데이트를 마이크로태스크 큐에 추가하여 프레임 경합 방지
      Future.microtask(() {
        if (mounted) {
          // 메모리 게임 페이지 완전히 재생성
          setState(() {
            // 새로운 키로 메모리 게임을 강제로 재생성
            _memoryGameKey = UniqueKey();
            _memoryGamePage = null; // 기존 인스턴스 명시적으로 해제
          });

          // 별도의 마이크로태스크로 메모리 게임 페이지 다시 생성
          Future.microtask(() {
            if (mounted) {
              setState(() {
                _memoryGamePage = _buildMemoryGamePage();
              });
            }
          });
        }
      });

      // 5. 로그아웃 성공 메시지 표시
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('로그아웃되었습니다.'),
      //     backgroundColor: Colors.green,
      //     duration: Duration(seconds: 2),
      //   ),
      // );
    } catch (e) {
      print('로그아웃 중 오류 발생: $e');

      // 오류 메시지 표시
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('로그아웃 중 오류가 발생했습니다: $e'),
      //     backgroundColor: Colors.red,
      //     duration: Duration(seconds: 3),
      //   ),
      // );

      // 인증 상태 초기화 재시도
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
      int multiplier = _memoryGameService?.getGridSizeMultiplier(gridSize) ?? 1;
      playerScores[player] = score * multiplier;
    });
  }

  void nextPlayer() {
    setState(() {
      currentPlayerIndex = (currentPlayerIndex + 1) % numberOfPlayers;
    });
  }

  void resetScores() {
    setState(() {
      playerScores.clear();
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
      if (_memoryGameService != null) {
        _memoryGameService!.gridSize = newGridSize;
      }
      // UI에 반영하기 위해 로컬 변수도 업데이트
      gridSize = newGridSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 폴더블폰 상태 업데이트
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFoldableState();
    });

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
        currentPlayer: players.isNotEmpty && currentPlayerIndex < players.length
            ? players[currentPlayerIndex]
            : '',
        playerScores: playerScores,
        resetScores: resetScores,
        isTimeAttackMode: true,
        timeLimit: isMultiplayerMode ? 180 : 60, // 멀티플레이어는 3분, 그 외는 60초
        isMultiplayerMode: isMultiplayerMode,
        gameId: _currentGameId,
        myPlayerId: _user?.uid,
        // 플레이어 목록 정보 추가
        selectedPlayers: _memoryGameService?.selectedPlayers ?? [],
        currentUserInfo: {
          'id': _user?.uid ?? 'me',
          'nickname': _nickname ?? '나',
          'country': _userCountryCode ?? 'us',
          'gender': _userGender ?? 'unknown',
          'age': _userAge ?? 0,
          'brainHealthScore':
              Provider.of<BrainHealthProvider>(context, listen: false)
                  .brainHealthScore,
        },
      );
    }

    List<Widget> _pages = [
      _memoryGamePage!,
      BrainHealthPage(),
      TestPage(),
    ];

    // Return Scaffold directly since MaterialApp is now in main()
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: (_currentIndex == 0 && _user != null) ? 100 : 70,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFF5F5F5),
                ],
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        instagramGradientStart,
                        instagramGradientEnd,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Consumer<LanguageProvider>(
                      builder: (context, languageProvider, child) {
                        final translations =
                            languageProvider.getUITranslations();
                        return Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.6,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              translations['app_title'] ?? 'Memory Game',
                              style: GoogleFonts.montserrat(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Spacer(),
                  _buildUserProfileButton(),
                ],
              ),
              if (_currentIndex == 0 && _user != null) ...[
                const SizedBox(height: 12),
                Container(
                  height: 44,
                  child: _buildDynamicControlButtons(),
                ),
              ],
            ],
          ),
          actions: [
            SizedBox(width: 16),
          ],
        ),
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const PageScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: _pages,
            ),
            if (_user == null && (_currentIndex == 0 || _currentIndex == 2))
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    // 게임 탭(0)에서는 튜토리얼이 켜져 있으면 스크롤 방해하지 않도록 오버레이 비활성화
                    if (_currentIndex == 0) {
                      final tutorialVisible =
                          _memoryGamePage?.isTutorialVisible() ?? false;
                      if (tutorialVisible) return const SizedBox.shrink();
                    }
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _showSignInDialog(context);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _changeTab(0),
                  child: SizedBox(
                    height: 50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _currentIndex == 0
                                ? Color(0xFF833AB4).withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset(
                            'assets/icon/memory.png',
                            width: 22,
                            height: 22,
                            color: _currentIndex == 0
                                ? Color(0xFF833AB4)
                                : Colors.grey.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _changeTab(1),
                  child: SizedBox(
                    height: 50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _currentIndex == 1
                                ? Color(0xFF833AB4).withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset(
                            'assets/icon/brain.png',
                            width: 22,
                            height: 22,
                            color: _currentIndex == 1
                                ? Color(0xFF833AB4)
                                : Colors.grey.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _changeTab(2),
                  child: SizedBox(
                    height: 50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _currentIndex == 2
                                ? Color(0xFF833AB4).withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset(
                            'assets/icon/exam.png',
                            width: 22,
                            height: 22,
                            color: _currentIndex == 2
                                ? Color(0xFF833AB4)
                                : Colors.grey.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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

  // 동적 크기 조절이 가능한 컨트롤 버튼들을 빌드하는 메서드
  Widget _buildDynamicControlButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // 화면 크기 분류
        final isSmallScreen = screenWidth < 360;
        final isMediumScreen = screenWidth < 414;

        // 동적 크기 계산 - 폴더블 최적화
        final buttonSpacing = isSmallScreen
            ? screenWidth * 0.015
            : isMediumScreen
                ? screenWidth * 0.02
                : screenWidth * 0.025;

        // 버튼 높이를 44px로 고정하여 일관성 확보
        final buttonHeight = 44.0;

        final buttonPadding = isSmallScreen
            ? EdgeInsets.symmetric(horizontal: screenWidth * 0.025, vertical: 8)
            : isMediumScreen
                ? EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03, vertical: 8)
                : EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.035, vertical: 8);

        final borderRadius = isSmallScreen
            ? screenWidth * 0.03
            : isMediumScreen
                ? screenWidth * 0.035
                : screenWidth * 0.04;

        // 아이콘 크기를 버튼 높이에 맞춰 조정
        final iconSize = isSmallScreen
            ? 16.0
            : isMediumScreen
                ? 18.0
                : 20.0;

        final fontSize = isSmallScreen
            ? screenWidth * 0.03
            : isMediumScreen
                ? screenWidth * 0.032
                : screenWidth * 0.035;

        final flagHeight = isSmallScreen
            ? 12.0
            : isMediumScreen
                ? 14.0
                : 16.0;

        final flagWidth = isSmallScreen
            ? 18.0
            : isMediumScreen
                ? 20.0
                : 24.0;

        // 사용 가능한 너비 계산 (4개 버튼 + 3개 간격)
        final totalSpacing = buttonSpacing * 3;
        final availableWidth = screenWidth - totalSpacing;
        final buttonWidth = availableWidth / 4;

        return Row(
          children: [
            // 플레이어 선택 버튼
            Expanded(
              child: Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  final translations = languageProvider.getUITranslations();
                  final playerText = numberOfPlayers > 1
                      ? (translations['players'] ?? 'Players')
                      : (translations['player'] ?? 'Player');

                  return _buildDynamicControlButton(
                    icon: Icons.group_rounded,
                    label: '$numberOfPlayers $playerText',
                    onTap: _showPlayerSelectionDialog,
                    buttonHeight: buttonHeight,
                    buttonPadding: buttonPadding,
                    borderRadius: borderRadius,
                    iconSize: iconSize,
                    fontSize: fontSize,
                    isGradient: false,
                  );
                },
              ),
            ),
            SizedBox(width: buttonSpacing),

            // 그리드 크기 선택 버튼
            Expanded(
              child: _buildDynamicControlButton(
                icon: Icons.dashboard_rounded,
                label: gridSize,
                onTap: _showGridSizeSelectionDialog,
                buttonHeight: buttonHeight,
                buttonPadding: buttonPadding,
                borderRadius: borderRadius,
                iconSize: iconSize,
                fontSize: fontSize,
                isGradient: false,
              ),
            ),
            SizedBox(width: buttonSpacing),

            // Flip Count 버튼
            Expanded(
              child: _buildDynamicControlButton(
                icon: Icons.flip_rounded,
                label: '$flipCount',
                onTap: () {}, // 클릭 불가
                buttonHeight: buttonHeight,
                buttonPadding: buttonPadding,
                borderRadius: borderRadius,
                iconSize: iconSize,
                fontSize: fontSize,
                isGradient: true,
              ),
            ),
            SizedBox(width: buttonSpacing),

            // 언어 선택 버튼
            Expanded(
              child: _buildLanguageButton(
                buttonHeight: buttonHeight,
                buttonPadding: buttonPadding,
                borderRadius: borderRadius,
                iconSize: iconSize,
                flagHeight: flagHeight,
                flagWidth: flagWidth,
              ),
            ),
          ],
        );
      },
    );
  }

  // 개별 컨트롤 버튼을 빌드하는 헬퍼 메서드
  Widget _buildDynamicControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double buttonHeight,
    required EdgeInsets buttonPadding,
    required double borderRadius,
    required double iconSize,
    required double fontSize,
    required bool isGradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: buttonHeight,
        padding: buttonPadding,
        decoration: BoxDecoration(
          color: isGradient ? instagramGradientStart : Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isGradient ? instagramGradientStart : Color(0xFFE1E8ED),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: Offset(0, 2),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: isGradient ? Colors.white : Color(0xFF657786),
            ),
            SizedBox(width: buttonPadding.horizontal * 0.3),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: fontSize,
                    color: isGradient ? Colors.white : Color(0xFF14171A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 언어 선택 버튼을 빌드하는 헬퍼 메서드
  Widget _buildLanguageButton({
    required double buttonHeight,
    required EdgeInsets buttonPadding,
    required double borderRadius,
    required double iconSize,
    required double flagHeight,
    required double flagWidth,
  }) {
    return GestureDetector(
      onTap: () => _showLanguageSelectionDialog(context),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: buttonHeight,
        padding: buttonPadding,
        decoration: BoxDecoration(
          color: Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: Color(0xFFE1E8ED),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: Offset(0, 2),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            String currentLanguage = languageProvider.currentLanguage;
            String forFlag = currentLanguage.split('-')[1].toLowerCase();

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.volume_up_rounded,
                  size: iconSize,
                  color: Color(0xFF657786),
                ),
                SizedBox(width: buttonPadding.horizontal * 0.3),
                Flag.fromString(
                  forFlag,
                  height: flagHeight,
                  width: flagWidth,
                  borderRadius: 2,
                ),
              ],
            );
          },
        ),
      ),
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
      countryCode: _userCountryCode, // 사용자 국가 코드 전달
    );
  }

  void _showAccountEditDialog(BuildContext context) async {
    // Get user document to retrieve birthday
    Timestamp? userBirthday;
    if (_user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          if (userData.containsKey('birthday')) {
            userBirthday = userData['birthday'] as Timestamp;
          }
        }
      } catch (e) {
        print('Error fetching user birthday: $e');
      }
    }

    final result = await ProfileEditDialog.show(
      context,
      nickname: _nickname,
      userAge: _userAge,
      userGender: _userGender,
      userCountryCode: _userCountryCode,
      userBirthday: userBirthday,
      shortPW: _shortPW,
    );

    if (result != null) {
      if (result['signOut'] == true) {
        _showSignOutConfirmDialog(context);
        return;
      }

      if (result['deleteAccount'] == true) {
        _showDeleteAccountConfirmDialog(context);
        return;
      }

      try {
        if (_user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .update({
            'nickname': result['nickname'],
            'birthday': result['birthday'],
            'age': result['age'],
            'gender': result['gender'],
            'country': result['country'],
            'shortPW': result['shortPW'],
          });

          // Check if country was changed
          String newCountryCode = result['country'];
          bool countryChanged = _userCountryCode != newCountryCode;

          setState(() {
            _nickname = result['nickname'];
            _userAge = result['age'];
            _userGender = result['gender'];
            _userCountryCode = result['country'];
            _shortPW = result['shortPW'];
          });

          // If country was changed, update language provider and save to local storage
          if (countryChanged && _userCountryCode != null) {
            final languageProvider =
                Provider.of<LanguageProvider>(context, listen: false);
            await languageProvider.setNationality(_userCountryCode!);

            // Save the updated country code to SharedPreferences
            _saveUserCountryToLocalStorage(_userCountryCode!);
          }

          // Show success message if password was changed
          // if (result.containsKey('passwordChanged') &&
          //     result['passwordChanged'] == true) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: Text('Profile and password updated successfully'),
          //       backgroundColor: Colors.green,
          //     ),
          //   );
          // } else {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: Text('Profile updated successfully'),
          //       backgroundColor: Colors.green,
          //     ),
          //   );
          // }
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

  void _showDeleteAccountConfirmDialog(BuildContext context) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final translations = languageProvider.getUITranslations();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.shade50,
                    ),
                    child: Icon(
                      Icons.delete_forever_rounded,
                      size: 24,
                      color: Colors.red.shade400,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        translations['delete_account'] ?? 'Delete Account',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          translations['no'] ?? 'No',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deleteUserAccount();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          translations['yes'] ?? 'Yes',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteUserAccount() async {
    try {
      if (_user != null) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Deleting account...'),
              ],
            ),
          ),
        );

        // Delete user data from Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .delete();

        // Delete user account from Firebase Auth
        await _user!.delete();

        // Close loading dialog
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Force sign out by clearing all state
        await _forceSignOut();
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      print('Account deletion error: $e');

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to delete account. Please try again.'),
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

  Future<void> _forceSignOut() async {
    try {
      // Clear all local state
      setState(() {
        _user = null;
        _nickname = null;
        _userAge = null;
        _userGender = null;
        _userCountryCode = null;
        _shortPW = null;
      });

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear Firebase Auth state
      await FirebaseAuth.instance.signOut();

      // Reset language provider
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      await languageProvider.setNationality('KR'); // Reset to default

      print('Force sign out completed - all state cleared');
    } catch (e) {
      print('Force sign out error: $e');
      // Even if there's an error, try to sign out from Firebase
      try {
        await FirebaseAuth.instance.signOut();
      } catch (signOutError) {
        print('Firebase sign out error: $signOutError');
      }
    }
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
            final userData = userDoc.data() as Map<String, dynamic>;
            setState(() {
              _user = userCredential.user;
              _nickname = userData['nickname'];
              _userAge = userData['age'];
              _userGender = userData['gender'];
              _userCountryCode = userData['country'];
            });

            // Set nationality in LanguageProvider based on user's country code
            if (_userCountryCode != null) {
              final languageProvider =
                  Provider.of<LanguageProvider>(context, listen: false);
              await languageProvider.setNationality(_userCountryCode!);

              // Save user's country code to SharedPreferences
              _saveUserCountryToLocalStorage(_userCountryCode!);
            }
          }
          // Update FCM token after successful sign-in
          await _updateFCMTokenForCurrentUser();
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
            'birthday': userData['birthday'],
            'gender': userData['gender'],
            'country': userData['country'],
            'shortPW': userData['shortPW'],
          });

          setState(() {
            _user = userCredential.user;
            _nickname = userData['nickname'];
            // Calculate age from birthday
            _userAge = userData['birthday'] != null
                ? (DateTime.now()
                            .difference(userData['birthday'].toDate())
                            .inDays /
                        365)
                    .floor()
                : null;
            _userGender = userData['gender'];
            _userCountryCode = userData['country'];
          });
          // Update FCM token after successful sign-up
          await _updateFCMTokenForCurrentUser();
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

  void _showPlayerSelectionDialog() async {
    if (_memoryGameService == null) return;

    await PlayerSelectionHandler.showPlayerSelectionDialog(
      context: context,
      memoryGameService: _memoryGameService!,
      updateNumberOfPlayers: (int newNumberOfPlayers) {
        setState(() {
          numberOfPlayers = newNumberOfPlayers;
        });
      },
      updatePlayers: (List<String> newPlayers) {
        setState(() {
          players = newPlayers;
        });
      },
      updatePlayerScores: (Map<String, int> newPlayerScores) {
        setState(() {
          playerScores = newPlayerScores;
        });
      },
      updateCurrentPlayerIndex: (int newCurrentPlayerIndex) {
        setState(() {
          currentPlayerIndex = newCurrentPlayerIndex;
        });
      },
      updateSelectedPlayerData:
          (List<Map<String, dynamic>> newSelectedPlayerData) {
        setState(() {
          selectedPlayerData = newSelectedPlayerData;
        });
      },
      rebuildMemoryGamePage: () {
        setState(() {
          if (_currentIndex == 0) {
            _memoryGamePage = _buildMemoryGamePage();
          }
        });
      },
    );
  }

  void _showGridSizeSelectionDialog() async {
    if (_memoryGameService == null) return;

    final selectedGridSize =
        await GridSelectionDialog.show(context, _memoryGameService!.gridSize);
    if (selectedGridSize != null) {
      setState(() {
        // MemoryGameService에 그리드 크기 설정
        _memoryGameService!.gridSize = selectedGridSize;

        // UI 변경을 위해 기존 변수도 업데이트
        gridSize = selectedGridSize;

        // 게임 페이지 업데이트 - 공통 메서드 사용
        if (_currentIndex == 0) {
          _memoryGamePage = _buildMemoryGamePage();
        }
      });

      // 그리드 크기가 변경되었음을 사용자에게 알림
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text('그리드 크기가 변경되어 새 게임이 시작됩니다'),
      //   duration: Duration(seconds: 2),
      //   backgroundColor: Colors.green,
      // ));
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

      // PageController를 사용하여 애니메이션으로 페이지 전환
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // 특별한 경우(멀티플레이어 게임 참가, 게임 ID 변경 등)에만 메모리 게임 페이지를 갱신
      // 그 외 일반적인 탭 이동에서는 기존 상태 유지를 위해 페이지를 다시 생성하지 않음
      if (_currentIndex == 0 && numberOfPlayers > 1 && _currentGameId != null) {
        // 멀티플레이어 게임 ID가 변경되었을 때만 업데이트
        if (_memoryGamePage == null ||
            (_memoryGamePage!.gameId != _currentGameId) ||
            (_memoryGamePage!.isMultiplayerMode != isMultiplayerMode)) {
          print('게임 탭으로 전환 - 멀티플레이어 게임 업데이트 (상태 변경 감지)');
          _memoryGamePage = _buildMemoryGamePage();
        }
      }
    });
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
      players = [_nickname ?? '나', opponentNickname];
      playerScores = {players[0]: 0, players[1]: 0};
      currentPlayerIndex = 0;

      // 그리드 크기 업데이트
      if (_memoryGameService != null) {
        _memoryGameService!.gridSize = gridSize;
      }
      // UI 변경을 위해 로컬 변수도 업데이트
      gridSize = gridSize;

      // 현재 게임 ID 설정
      _currentGameId = gameId;
      isMultiplayerMode = true;

      // 새 게임 생성
      _memoryGamePage = MemoryGamePage(
        key: UniqueKey(),
        numberOfPlayers: 2,
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
        gameId: gameId,
        myPlayerId: _user?.uid,
        // 플레이어 목록 정보 추가
        selectedPlayers: _memoryGameService?.selectedPlayers ?? [],
        currentUserInfo: {
          'id': _user?.uid ?? 'me',
          'nickname': _nickname ?? '나',
          'country': _userCountryCode ?? 'us',
          'gender': _userGender ?? 'unknown',
          'age': _userAge ?? 0,
          'brainHealthScore':
              Provider.of<BrainHealthProvider>(context, listen: false)
                  .brainHealthScore,
        },
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

  // 새로운 메서드 추가
  void _onGridSizeChanged(String newGridSize) {
    if (mounted) {
      setState(() {
        // UI 변경을 위해 로컬 변수 업데이트
        gridSize = newGridSize;

        // 그리드 크기가 변경될 때 필요한 작업 수행
        if (_currentIndex == 0) {
          _memoryGamePage = _buildMemoryGamePage();
        }
      });
    }
  }

  // _memoryGamePage 생성 로직을 분리하는 helper 메서드 추가
  MemoryGamePage _buildMemoryGamePage() {
    final selectedPlayers = _memoryGameService?.selectedPlayers ?? [];

    // 선택된 플레이어 로그 출력
    print('_buildMemoryGamePage - 선택된 플레이어 수: ${selectedPlayers.length}');
    for (var player in selectedPlayers) {
      print(' - 플레이어: ${player['nickname']} (국가: ${player['country']})');
    }

    return MemoryGamePage(
      key: _memoryGameKey,
      numberOfPlayers: numberOfPlayers,
      gridSize: gridSize,
      updateFlipCount: updateFlipCount,
      updatePlayerScore: updatePlayerScore,
      nextPlayer: nextPlayer,
      currentPlayer: players.isNotEmpty && currentPlayerIndex < players.length
          ? players[currentPlayerIndex]
          : '',
      playerScores: playerScores,
      resetScores: resetScores,
      isTimeAttackMode: true,
      timeLimit: isMultiplayerMode ? 180 : 60, // 멀티플레이어는 3분, 그 외는 60초
      isMultiplayerMode: isMultiplayerMode,
      gameId: _currentGameId,
      myPlayerId: _user?.uid,
      // 플레이어 목록 정보 추가
      selectedPlayers: selectedPlayers,
      currentUserInfo: {
        'id': _user?.uid ?? 'me',
        'nickname': _nickname ?? '나',
        'country': _userCountryCode ?? 'us',
        'gender': _userGender ?? 'unknown',
        'age': _userAge ?? 0,
        'brainHealthScore':
            Provider.of<BrainHealthProvider>(context, listen: false)
                .brainHealthScore,
      },
    );
  }

  // Add method to load saved country code
  Future<void> _loadSavedUserCountry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCountryCode = prefs.getString(PREF_USER_COUNTRY_CODE);

      if (savedCountryCode != null && _user == null) {
        // Only use saved country if user is not logged in
        print('Loaded country code from local storage: $savedCountryCode');

        // Update language provider with saved nationality
        final languageProvider =
            Provider.of<LanguageProvider>(context, listen: false);
        await languageProvider.setNationality(savedCountryCode);
      }
    } catch (e) {
      print('Error loading country code from local storage: $e');
    }
  }

  Future<void> _saveUserCountryToLocalStorage(String countryCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PREF_USER_COUNTRY_CODE, countryCode);
      print('User country code saved to local storage: $countryCode');
    } catch (e) {
      print('Error saving country code to local storage: $e');
    }
  }

  // TTS 언어 초기화 메서드
  Future<void> _initializeTTSLanguage() async {
    try {
      // LanguageProvider에서 현재 언어 가져오기
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);

      // 앱 시작 시 약간의 지연을 두어 LanguageProvider가 완전히 초기화되도록 함
      await Future.delayed(Duration(milliseconds: 1000));

      String currentLanguage = languageProvider.currentLanguage;
      print('앱 시작 시 TTS 언어 설정: $currentLanguage');

      // LanguageProvider가 초기화되지 않았으면 기본 언어 사용
      if (currentLanguage.isEmpty) {
        currentLanguage = 'ko-KR';
        print('LanguageProvider가 초기화되지 않아 기본 언어 ko-KR을 사용합니다.');
      }

      // 모든 TTS 인스턴스에 대해 언어 설정을 강제로 적용
      // MemoryGamePage의 TTS 설정
      if (_memoryGamePage != null) {
        // MemoryGamePage의 TTS 언어 설정을 강제로 업데이트
        setState(() {
          // MemoryGamePage를 다시 생성하여 TTS 언어를 새로 설정
          _memoryGamePage = _buildMemoryGamePage();
        });
      }

      // TestPage의 TTS 설정도 업데이트 (탭이 변경될 때 적용됨)
      // TestPage는 didChangeDependencies에서 자동으로 언어를 설정하므로 별도 처리 불필요

      // 추가로 2초 후에 한 번 더 확인하여 확실하게 설정
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          String finalLanguage = languageProvider.currentLanguage;
          if (finalLanguage.isEmpty) {
            finalLanguage = 'ko-KR';
          }
          print('최종 TTS 언어 확인: $finalLanguage');
        }
      });
    } catch (e) {
      print('TTS 언어 초기화 오류: $e');
    }
  }

  Future<void> _updateFCMTokenForCurrentUser() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        final token = await FirebaseMessaging.instance.getToken();
        if (user != null && token != null) {
          print('🔄 Updating FCM token for user ${user.uid}');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'fcmToken': token,
            'fcmUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } catch (e) {
        print('❌ Failed to update FCM token: $e');
      }
    }
  }
}
