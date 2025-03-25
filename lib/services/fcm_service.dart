import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  factory FCMService() {
    return _instance;
  }

  FCMService._internal();

  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;

    try {
      print('FCM Service: Starting initialization');

      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        print('FCM Service: Firebase not initialized yet, initializing...');
        await Firebase.initializeApp();
      }

      print('FCM Service: Requesting notification permissions');

      // Request permission
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print(
          'FCM Service: Permission settings - ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('User granted permission: ${settings.authorizationStatus}');

        // Initialize local notifications
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        final DarwinInitializationSettings initializationSettingsIOS =
            DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

        final InitializationSettings initializationSettings =
            InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

        await _flutterLocalNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            // Handle notification tap
            _handleNotificationTap(response.payload, context);
          },
        );

        // Create channel for Android
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'game_challenges',
          'Game Challenges',
          importance: Importance.high,
          playSound: true,
          showBadge: true,
          enableLights: true,
        );

        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        // Get FCM token
        print('FCM Service: Getting FCM token');
        String? token = await _firebaseMessaging.getToken();

        if (token == null) {
          print('FCM Service: Failed to get FCM token');
          // 토큰을 가져오지 못한 경우 주기적으로 다시 시도
          _scheduleTokenRetry(context);
        } else {
          print(
              'FCM Service: FCM token received - ${token.substring(0, 10)}...');
          await _saveToken(token);

          // 사용자 로그인 상태 확인
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            // 토큰이 성공적으로 저장되었는지 확인
            bool tokenSaved = await _verifyTokenSaved(user.uid, token);
            if (!tokenSaved) {
              print('FCM Service: Token verification failed, scheduling retry');
              _scheduleTokenRetry(context);
            }
          }
        }

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) async {
          print('FCM Service: Token refreshed');
          await _saveToken(newToken);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('Got a message whilst in the foreground!');
          print('Message data: ${message.data}');

          if (message.notification != null) {
            print(
                'Message also contained a notification: ${message.notification}');

            _showLocalNotification(message);
          }
        });

        // Handle background/terminated state messages
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);

        _isInitialized = true;
        print('FCM Service: Initialization complete');
      } else {
        print('User declined or has not accepted permission');
        // 사용자가 권한을 거부했을 경우 처리
        _showPermissionDeniedMessage(context);
      }
    } catch (e, stackTrace) {
      print('FCM Service initialization error: $e');
      print('Stack trace: $stackTrace');

      // Set initialized to false to allow retry
      _isInitialized = false;

      // 초기화 실패 시 재시도
      Future.delayed(Duration(seconds: 30), () {
        if (!_isInitialized && context.mounted) {
          print('FCM Service: Retrying initialization after error');
          initialize(context);
        }
      });
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('FCM Service: Saving token for user ${user.uid}');
        print(
            'FCM Service: Token value (first 10 chars): ${token.substring(0, 10)}...');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('tokens')
            .doc('fcm')
            .set({
          'token': token,
          'device': getDeviceInfo(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('FCM Service: Token saved successfully');

        // 토큰이 제대로 저장되었는지 확인
        DocumentSnapshot savedToken = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('tokens')
            .doc('fcm')
            .get();

        if (savedToken.exists) {
          Map<String, dynamic>? data =
              savedToken.data() as Map<String, dynamic>?;
          String? savedTokenValue = data?['token'];
          print(
              'FCM Service: Verified saved token: ${savedTokenValue != null ? "${savedTokenValue.substring(0, 10)}..." : "null"}');
        } else {
          print(
              'FCM Service: ERROR - Token document does not exist after save attempt');
        }
      } else {
        print('FCM Service: Cannot save token - User not logged in');
      }
    } catch (e, stackTrace) {
      print('FCM Service: Error saving token: $e');
      print('FCM Service: Stack trace: $stackTrace');
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      // 발신자 닉네임 로그 출력
      String senderNickname = message.data['senderNickname'] ?? '알 수 없는 사용자';
      print('FCM Service: 메시지 발신자 닉네임: $senderNickname');

      // 앱이 포그라운드 상태일 때 인앱 대화상자 표시
      if (message.data['type'] == 'challenge') {
        _showInAppChallengeDialog(message);
      }

      // 로컬 알림도 함께 표시 (설정에 따라 조절 가능)
      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'game_challenges',
            'Game Challenges',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  // 앱이 포그라운드 상태일 때 도전 요청 팝업 대화상자 표시
  void _showInAppChallengeDialog(RemoteMessage message) {
    try {
      // 포그라운드 메시지 상세 정보 로깅
      print('포그라운드 메시지 수신: ${message.notification?.title}');
      print('메시지 데이터: ${message.data}');
      String senderNickname = message.data['senderNickname'] ?? '알 수 없는 사용자';
      print('발신자 닉네임: $senderNickname');

      // 포그라운드 메시지 이벤트 발행 (앱에서 구독 가능)
      final eventData = {
        'type': 'challenge',
        'title': message.notification?.title ?? '새로운 도전 요청',
        'body': message.notification?.body ?? '도전 요청이 도착했습니다',
        'data': message.data,
        'senderNickname': senderNickname, // 닉네임 정보 명시적으로 추가
      };

      // 1. 앱에서 사용할 수 있는 스트림 컨트롤러를 통해 전달하는 방법이 있지만,
      // 2. 여기서는 앱이 이미 실행 중이므로, 로컬 알림을 표시하여 사용자에게 알림
      // 대화상자는 앱의 MainScreen에서 처리하는 것이 더 적절함
    } catch (e) {
      print('도전 요청 팝업 표시 중 오류: $e');
    }
  }

  // 도전 수락
  void _acceptChallenge(String challengeId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && challengeId.isNotEmpty) {
      try {
        // 도전 상태 업데이트
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(challengeId)
            .update({
          'status': 'accepted',
          'read': true,
          'responseTime': FieldValue.serverTimestamp(),
        });

        // challenge 컬렉션의 문서도 업데이트
        await FirebaseFirestore.instance
            .collection('challenges')
            .doc(challengeId)
            .update({
          'status': 'accepted',
          'responseTime': FieldValue.serverTimestamp(),
        });

        print('도전을 수락했습니다: $challengeId');
      } catch (e) {
        print('도전 수락 중 오류 발생: $e');
      }
    }
  }

  // 도전 거절
  void _rejectChallenge(String challengeId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && challengeId.isNotEmpty) {
      try {
        // 도전 상태 업데이트
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(challengeId)
            .update({
          'status': 'rejected',
          'read': true,
          'responseTime': FieldValue.serverTimestamp(),
        });

        // challenge 컬렉션의 문서도 업데이트
        await FirebaseFirestore.instance
            .collection('challenges')
            .doc(challengeId)
            .update({
          'status': 'rejected',
          'responseTime': FieldValue.serverTimestamp(),
        });

        print('도전을 거절했습니다: $challengeId');
      } catch (e) {
        print('도전 거절 중 오류 발생: $e');
      }
    }
  }

  void _handleNotificationTap(String? payload, BuildContext context) {
    if (payload != null) {
      // Parse the payload and navigate accordingly
      print('Notification tapped with payload: $payload');

      // TODO: Implement navigation based on payload
      // This will be customized based on your app's navigation structure
    }
  }

  Map<String, String> getDeviceInfo() {
    // In a real app, you would use a package like device_info_plus
    // to get detailed device information
    return {
      'type': 'Mobile',
      'platform': 'Flutter',
    };
  }

  // 토큰이 실제로 저장되었는지 확인하는 함수
  Future<bool> _verifyTokenSaved(String userId, String token) async {
    try {
      DocumentSnapshot savedToken = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc('fcm')
          .get();

      if (savedToken.exists) {
        Map<String, dynamic>? data = savedToken.data() as Map<String, dynamic>?;
        String? savedTokenValue = data?['token'];
        if (savedTokenValue != null && savedTokenValue.isNotEmpty) {
          print(
              'FCM Service: Token verified in Firestore: ${savedTokenValue.substring(0, 10)}...');
          return true;
        }
      }
      print('FCM Service: Token not found in Firestore');
      return false;
    } catch (e) {
      print('FCM Service: Error verifying token: $e');
      return false;
    }
  }

  // 토큰 획득/저장 재시도를 예약하는 함수
  void _scheduleTokenRetry(BuildContext context) {
    Future.delayed(Duration(seconds: 10), () async {
      if (context.mounted) {
        print('FCM Service: Retrying to get and save FCM token');
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _saveToken(token);
        }
      }
    });
  }

  // 권한 거부 메시지 표시
  void _showPermissionDeniedMessage(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('알림 권한이 거부되었습니다. 설정에서 권한을 허용해주세요.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: '설정',
            textColor: Colors.white,
            onPressed: () {
              // 플랫폼에 맞는 설정 화면으로 이동 로직 구현 필요
            },
          ),
        ),
      );
    }
  }
}

// This function must be top-level (not a class member)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This function will handle background messages
  print('Handling a background message: ${message.messageId}');

  // Make sure you've initialized Firebase before using it
  // You may need to add Firebase initialization here if this function
  // is called before your app initializes Firebase
}
