import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // StreamSubscription을 위한 import
import 'dart:convert'; // For jsonEncode and jsonDecode

class ScoreRecord {
  final DateTime date;
  final int score;

  ScoreRecord(this.date, this.score);

  Map<String, dynamic> toMap() {
    return {
      'date': date.millisecondsSinceEpoch,
      'score': score,
    };
  }

  factory ScoreRecord.fromMap(Map<String, dynamic> map) {
    return ScoreRecord(
      DateTime.fromMillisecondsSinceEpoch(map['date']),
      map['score'],
    );
  }
}

class BrainHealthProvider with ChangeNotifier {
  int _brainHealthScore = 0;
  int _totalGamesPlayed = 0;
  int _totalMatchesFound = 0;
  int _bestTime = 0; // 초 단위, 0은 아직 기록 없음을 의미
  Map<String, int> _bestTimesByGridSize = {};
  List<ScoreRecord> _scoreHistory = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;
  StreamSubscription<User?>? _authStateSubscription;
  bool _migrationChecked = false; // 마이그레이션 확인 여부
  bool _disposed = false; // dispose 상태 추적

  int get brainHealthScore => _brainHealthScore;
  int get totalGamesPlayed => _totalGamesPlayed;
  int get totalMatchesFound => _totalMatchesFound;
  int get bestTime => _bestTime;
  Map<String, int> get bestTimesByGridSize => _bestTimesByGridSize;
  List<ScoreRecord> get scoreHistory => _scoreHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get best time for a specific grid size
  int getBestTimeForGrid(String gridSize) {
    return _bestTimesByGridSize[gridSize] ?? 0;
  }

  // 치매 예방 효과를 백분율로 계산 (최대 100%)
  double get preventionPercentage {
    // 1000점을 100%로 설정 (이 값은 조정 가능)
    const maxScore = 1000.0;
    double percentage = (_brainHealthScore / maxScore) * 100;
    return percentage > 100 ? 100 : percentage;
  }

  // 치매 예방 레벨 (1-5)
  int get preventionLevel {
    if (preventionPercentage < 20) return 1;
    if (preventionPercentage < 40) return 2;
    if (preventionPercentage < 60) return 3;
    if (preventionPercentage < 80) return 4;
    return 5;
  }

  // 다음 레벨까지 필요한 점수
  int get pointsToNextLevel {
    const maxScore = 1000.0;
    if (preventionLevel >= 5) return 0;

    int nextLevelThreshold = preventionLevel * 20;
    double pointsNeeded =
        (nextLevelThreshold / 100 * maxScore) - _brainHealthScore;
    return pointsNeeded.ceil();
  }

  // 새로운 뇌 건강 지수 계산 (사용자 나이, 최근 게임 활동, 그리드별 시간, 뒤집기 횟수 기반)
  Future<Map<String, dynamic>> calculateBrainHealthIndex() async {
    // 로그아웃 상태나 데이터 로드 중 안전한 호출을 위한 오류 처리
    try {
      // 기본 지수 값 (70에서 50으로 낮춤)
      double baseIndex = 50.0;

      // 현재 날짜
      DateTime now = DateTime.now();

      // 사용자 나이 가져오기 (Firebase 사용자 정보에서)
      int userAge = 30; // 기본값 30

      if (_userId != null) {
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(_userId)
              .get();

          if (userDoc.exists) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;
            if (userData.containsKey('age')) {
              userAge = userData['age'] as int;
            } else {
              // Firebase에 age 필드가 없는 경우 SharedPreferences에서 시도
              SharedPreferences prefs = await SharedPreferences.getInstance();
              userAge = prefs.getInt('user_age') ?? 30;
            }
          }
        } catch (e) {
          print('Error fetching user age from Firebase: $e');
          // 오류 발생 시 SharedPreferences에서 시도
          SharedPreferences prefs = await SharedPreferences.getInstance();
          userAge = prefs.getInt('user_age') ?? 30;
        }
      } else {
        // 로그인되지 않은 경우 SharedPreferences에서 가져옴
        SharedPreferences prefs = await SharedPreferences.getInstance();
        userAge = prefs.getInt('user_age') ?? 30;
      }

      // 나이 기반 조정 (35세 이상부터 점수 감소, 효과 증가)
      double ageAdjustment = 0;
      if (userAge > 35) {
        ageAdjustment = (userAge - 35) * 0.3; // 나이가 많을수록 지수 감소 (0.2에서 0.3으로 증가)
        ageAdjustment = ageAdjustment.clamp(0, 20); // 최대 감소량 15에서 20으로 증가
      }

      // 지난 일주일간 게임 활동 평가
      int recentGames = 0;

      // 점수 기록에서 최근 활동 확인
      for (ScoreRecord record in _scoreHistory) {
        if (now.difference(record.date).inDays <= 7) {
          recentGames++;
        }
      }

      // 최근 게임 활동 기반 조정 (보상 감소)
      double activityAdjustment = recentGames * 1.0; // 게임당 1.5점에서 1.0점으로 감소
      activityAdjustment = activityAdjustment.clamp(0, 12); // 최대 15점에서 12점으로 감소

      // 그리드 크기별 성능 평가
      double gridPerformance = 0;

      // 각 그리드 크기별 점수 계산 (난이도 증가)
      for (String gridSize in _bestTimesByGridSize.keys) {
        int? bestTime = _bestTimesByGridSize[gridSize];
        if (bestTime != null && bestTime > 0) {
          // 그리드 크기에 따른 기대 시간 (초 단위) - 조금 더 엄격한 기준 적용
          int expectedTime;
          switch (gridSize) {
            case "2x2":
              expectedTime = 10; // 15에서 10으로 감소
              break;
            case "4x2":
            case "2x4":
              expectedTime = 25; // 30에서 25로 감소
              break;
            case "4x3":
            case "3x4":
              expectedTime = 50; // 60에서 50으로 감소
              break;
            case "4x4":
              expectedTime = 75; // 90에서 75로 감소
              break;
            case "5x4":
            case "4x5":
              expectedTime = 100; // 120에서 100으로 감소
              break;
            case "6x5":
            case "5x6":
              expectedTime = 150; // 180에서 150으로 감소
              break;
            default:
              expectedTime = 50;
          }

          // 기대 시간보다 빠를수록 더 높은 점수 (보상 감소)
          double timeFactor =
              (expectedTime / bestTime).clamp(0.5, 1.8); // 최대 보상 2.0에서 1.8로 감소
          gridPerformance += timeFactor * 1.5; // 가중치 2에서 1.5로 감소
        }
      }

      // 그리드 성능 점수 제한
      gridPerformance = gridPerformance.clamp(0, 18); // 최대 20에서 18로 감소

      // 추가: 플레이 횟수에 따른 보너스 (지속적인 플레이 필요)
      double persistenceBonus = 0;
      if (_totalGamesPlayed >= 5) persistenceBonus = 2;
      if (_totalGamesPlayed >= 10) persistenceBonus = 4;
      if (_totalGamesPlayed >= 20) persistenceBonus = 7;
      if (_totalGamesPlayed >= 50) persistenceBonus = 10;
      if (_totalGamesPlayed >= 100) persistenceBonus = 15;

      // 최종 지수 계산 (로그 함수 적용으로 상위 점수대 진입 어렵게)
      double rawIndex = baseIndex -
          ageAdjustment +
          activityAdjustment +
          gridPerformance +
          persistenceBonus;

      // 로그 함수를 사용해 높은 점수대에서 진행이 느려지도록 조정
      // 85점 이상부터 점수 획득이 급격히 어려워짐
      double finalIndex = rawIndex;
      if (rawIndex > 85) {
        double excess = rawIndex - 85;
        double logFactor =
            1 + (0.5 * (1 - (1 / (1 + 0.1 * excess)))); // 로그 기반 감쇠 함수
        finalIndex = 85 + (excess / logFactor);
      }

      finalIndex = finalIndex.clamp(0, 100);

      // 지수 레벨 계산 (1-5) - 상위 레벨 기준 상향
      int indexLevel;
      if (finalIndex < 35) {
        // 40에서 35로 감소
        indexLevel = 1;
      } else if (finalIndex < 60) {
        // 55에서 60으로 증가
        indexLevel = 2;
      } else if (finalIndex < 80) {
        // 70에서 80으로 증가
        indexLevel = 3;
      } else if (finalIndex < 95) {
        // 85에서 95로 증가
        indexLevel = 4;
      } else {
        indexLevel = 5;
      }

      // 다음 레벨까지 필요한 포인트 계산
      double pointsToNext = 0;
      if (indexLevel < 5) {
        List<double> thresholds = [0, 35, 60, 80, 95, 100]; // 기준 업데이트
        pointsToNext = thresholds[indexLevel] - finalIndex;
        pointsToNext = pointsToNext.abs().ceil().toDouble();
      }

      return {
        'brainHealthIndex': finalIndex,
        'indexLevel': indexLevel,
        'pointsToNextLevel': pointsToNext,
        'ageComponent': ageAdjustment,
        'activityComponent': activityAdjustment,
        'performanceComponent': gridPerformance,
        'persistenceBonus': persistenceBonus, // 추가: 지속적 플레이 보너스
        'details': {
          'age': userAge,
          'recentGames': recentGames,
          'totalGames': _totalGamesPlayed, // 추가: 전체 게임 수
          'gridPerformances': _bestTimesByGridSize,
        }
      };
    } catch (e) {
      print('Error calculating brain health index: $e');
      return {
        'brainHealthIndex': 0,
        'indexLevel': 1,
        'pointsToNextLevel': 0,
        'ageComponent': 0,
        'activityComponent': 0,
        'performanceComponent': 0,
        'persistenceBonus': 0,
        'details': {
          'age': 30,
          'recentGames': 0,
          'totalGames': 0,
          'gridPerformances': {},
        }
      };
    }
  }

  BrainHealthProvider() {
    _initialize();
    _setupAuthListener();
  }

  Future<void> _initialize() async {
    if (_disposed) return;

    print('Initializing BrainHealthProvider...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 먼저 사용자 인증 확인 - userId 확보
      await _ensureUserAuthenticated();
      if (_disposed) return; // dispose 체크 추가

      // 사용자 ID가 확인된 후에 로컬 데이터 로드
      await _loadLocalData();
      if (_disposed) return; // dispose 체크 추가

      // 데이터 마이그레이션 확인 (brain_health_users에서 users로 이전)
      if (_userId != null && !_migrationChecked) {
        await _checkAndMigrateData();
        _migrationChecked = true;
      }
      if (_disposed) return; // dispose 체크 추가

      // Firebase 데이터 로드 및 동기화
      if (_userId != null) {
        await _loadFirebaseData();
      } else {
        print('Unable to load Firebase data: Authentication failed');
      }
    } catch (e) {
      print('Initialization error: $e');
      _error = 'Failed to initialize: $e';
    } finally {
      if (!_disposed) {
        // dispose 체크 추가
        _isLoading = false;
        notifyListeners();
        print(
            'Initialization completed. User ID: $_userId, Score: $_brainHealthScore');
      }
    }
  }

  // 이전 brain_health_users 컬렉션에서 users 컬렉션으로 데이터 마이그레이션
  Future<void> _checkAndMigrateData() async {
    if (_userId == null) return;

    try {
      print('Checking for data migration needs...');

      // 이전 컬렉션에서 데이터 확인
      DocumentSnapshot oldUserDoc = await FirebaseFirestore.instance
          .collection('brain_health_users')
          .doc(_userId)
          .get();

      // 현재 users 컬렉션의 사용자 문서 확인
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      bool needsMigration = false;

      // 마이그레이션 필요 여부 확인
      if (oldUserDoc.exists) {
        if (!userDoc.exists) {
          needsMigration = true;
        } else {
          var userData = userDoc.data();
          if (userData != null && userData is Map<String, dynamic>) {
            if (!userData.containsKey('brain_health')) {
              needsMigration = true;
            }
          }
        }
      }

      // 이전 컬렉션에 데이터가 있고, 현재 컬렉션에 brain_health 필드가 없는 경우 마이그레이션 진행
      if (needsMigration && oldUserDoc.exists) {
        print(
            'Migration needed: Moving data from brain_health_users to users collection');

        Map<String, dynamic> oldData = {};
        var rawData = oldUserDoc.data();
        if (rawData != null && rawData is Map<String, dynamic>) {
          oldData = rawData;
        }

        Map<String, dynamic> brainHealthData = {};

        // 기본 필드 복사
        brainHealthData['brainHealthScore'] = oldData['brainHealthScore'] ?? 0;
        brainHealthData['totalGamesPlayed'] = oldData['totalGamesPlayed'] ?? 0;
        brainHealthData['totalMatchesFound'] =
            oldData['totalMatchesFound'] ?? 0;
        brainHealthData['bestTime'] = oldData['bestTime'] ?? 0;
        brainHealthData['bestTimesByGridSize'] =
            oldData['bestTimesByGridSize'] ?? {};
        brainHealthData['updated'] = FieldValue.serverTimestamp();

        // users 컬렉션에 업데이트
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .set({'brain_health': brainHealthData}, SetOptions(merge: true));

        print('Basic brain health data migrated to users collection');

        // 점수 기록 마이그레이션
        QuerySnapshot scoreSnapshot = await FirebaseFirestore.instance
            .collection('brain_health_users')
            .doc(_userId)
            .collection('scoreHistory')
            .get();

        if (scoreSnapshot.docs.isNotEmpty) {
          int migratedCount = 0;
          for (var doc in scoreSnapshot.docs) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_userId)
                .collection('brain_health_history')
                .add(doc.data() as Map<String, dynamic>);
            migratedCount++;
          }
          print('$migratedCount score records migrated');
        }

        print('Migration completed successfully');
      } else {
        print(
            'Migration not needed: Data already in users collection or no old data found');
      }
    } catch (e) {
      print('Error during data migration check: $e');
    }
  }

  // 사용자 인증 확인 (익명 로그인 포함)
  Future<void> _ensureUserAuthenticated() async {
    try {
      print('Ensuring user authentication...');

      // 현재 인증 상태 확인
      User? user = FirebaseAuth.instance.currentUser;

      // 로그인되어 있지 않다면 익명 로그인 시도
      if (user == null) {
        print('No current user, attempting anonymous login');
        try {
          UserCredential result =
              await FirebaseAuth.instance.signInAnonymously();
          user = result.user;
          print('Anonymous user logged in successfully: ${user?.uid}');
        } catch (e) {
          print('Anonymous login failed with error: $e');
          _error = 'Cannot connect to server: $e';
          return;
        }
      } else {
        print('User already authenticated: ${user.uid}');
      }

      if (user != null) {
        _userId = user.uid;
        print('User ID set: $_userId');

        // 사용자 문서가 존재하는지 확인하고 없으면 생성
        try {
          DocumentReference userRef =
              FirebaseFirestore.instance.collection('users').doc(_userId);

          DocumentSnapshot userDoc = await userRef.get();
          if (!userDoc.exists) {
            print('Creating new user document in Firebase');

            // 기본 사용자 데이터 - 항상 0으로 시작
            Map<String, dynamic> userData = {
              'brain_health': {
                'brainHealthScore': 0,
                'totalGamesPlayed': 0,
                'totalMatchesFound': 0,
                'bestTime': 0,
                'bestTimesByGridSize': {},
                'created': FieldValue.serverTimestamp(),
              }
            };

            // 익명 사용자가 아닌 경우 추가 정보 저장
            if (!user.isAnonymous && user.email != null) {
              userData['email'] = user.email;

              // 닉네임 설정 (이메일 앞부분 또는 displayName 사용)
              String nickname = user.displayName ?? user.email!.split('@')[0];
              userData['nickname'] = nickname;
            } else {
              // 익명 사용자인 경우
              userData['isAnonymous'] = true;
              if (!userData.containsKey('nickname')) {
                userData['nickname'] = 'Anonymous User';
              }
            }

            if (!userData.containsKey('language')) {
              userData['language'] = 'en'; // 기본 언어 설정
            }

            await userRef.set(userData);
            print(
                'New user document created successfully with data: $userData');
          } else {
            print('User document already exists in Firebase');

            // 기존 문서에 brain_health 필드가 없는 경우 추가
            Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
            Map<String, dynamic> updates = {};

            if (!data.containsKey('brain_health')) {
              updates['brain_health'] = {
                'brainHealthScore': _brainHealthScore,
                'totalGamesPlayed': _totalGamesPlayed,
                'totalMatchesFound': _totalMatchesFound,
                'bestTime': _bestTime,
                'bestTimesByGridSize': _bestTimesByGridSize,
                'created': FieldValue.serverTimestamp(),
              };
            }

            if (!data.containsKey('language')) {
              updates['language'] = 'en';
            }

            if (!user.isAnonymous &&
                user.email != null &&
                !data.containsKey('email')) {
              updates['email'] = user.email;
            }

            if (!data.containsKey('nickname')) {
              String nickname = 'Anonymous User';
              if (!user.isAnonymous && user.email != null) {
                nickname = user.displayName ?? user.email!.split('@')[0];
              }
              updates['nickname'] = nickname;
            }

            if (updates.isNotEmpty) {
              await userRef.update(updates);
              print('Updated user document with missing fields: $updates');
            }
          }
        } catch (e) {
          print('Error checking/creating user document: $e');
        }
      } else {
        _error = 'Failed to authenticate user';
        print('Authentication process completed but user is still null');
      }
    } catch (e) {
      print('Error during authentication process: $e');
      _error = 'Authentication error: $e';
    }
  }

  Future<void> _loadData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('Starting data load process...');

      // 먼저 로컬 데이터 로드 시도
      await _loadLocalData();

      // 사용자 인증 확인
      await _ensureUserAuthenticated();

      // Firebase에서 데이터 로드 시도
      if (_userId != null) {
        await _loadFirebaseData();
      } else {
        print('Unable to load Firebase data: No user ID available');
      }

      _isLoading = false;
      notifyListeners();
      print(
          'Data load process completed. Brain Health Score: $_brainHealthScore');
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load data: $e';
      print('Brain Health 데이터 로드 중 오류 발생: $e');
      notifyListeners();
    }
  }

  Future<void> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 사용자 ID가 있는 경우에만 해당 사용자의 데이터 로드
      if (_userId != null) {
        print('Loading local data for user: $_userId');

        // 사용자별 키 생성
        final userKeyPrefix = 'user_${_userId}_';

        _brainHealthScore =
            prefs.getInt('${userKeyPrefix}brainHealthScore') ?? 0;
        _totalGamesPlayed =
            prefs.getInt('${userKeyPrefix}totalGamesPlayed') ?? 0;
        _totalMatchesFound =
            prefs.getInt('${userKeyPrefix}totalMatchesFound') ?? 0;
        _bestTime = prefs.getInt('${userKeyPrefix}bestTime') ?? 0;

        // Load best times by grid size
        String? bestTimesJson =
            prefs.getString('${userKeyPrefix}bestTimesByGridSize');
        if (bestTimesJson != null) {
          final Map<String, dynamic> jsonData = jsonDecode(bestTimesJson);
          _bestTimesByGridSize =
              jsonData.map((key, value) => MapEntry(key, value as int));
        } else {
          _bestTimesByGridSize = {};
        }

        // 로컬에서 점수 기록 가져오기
        List<String>? scoreHistory =
            prefs.getStringList('${userKeyPrefix}scoreHistory');
        if (scoreHistory != null && scoreHistory.isNotEmpty) {
          _scoreHistory = scoreHistory.map((item) {
            // Format: "timestamp|score"
            List<String> parts = item.split('|');
            int timestamp = int.parse(parts[0]);
            int score = int.parse(parts[1]);
            return ScoreRecord(
              DateTime.fromMillisecondsSinceEpoch(timestamp),
              score,
            );
          }).toList();
        } else {
          _scoreHistory = [];
        }

        print(
            'Local data loaded for user $_userId. Score: $_brainHealthScore, Games: $_totalGamesPlayed');
      } else {
        // 사용자 ID가 없는 경우 초기화
        print('No user ID available, initializing with default values');
        _brainHealthScore = 0;
        _totalGamesPlayed = 0;
        _totalMatchesFound = 0;
        _bestTime = 0;
        _bestTimesByGridSize = {};
        _scoreHistory = [];
      }
    } catch (e) {
      print('Local data load error: $e');
      // 에러 발생 시 초기값으로 설정
      _brainHealthScore = 0;
      _totalGamesPlayed = 0;
      _totalMatchesFound = 0;
      _bestTime = 0;
      _bestTimesByGridSize = {};
      _scoreHistory = [];
    }
  }

  Future<void> _loadFirebaseData() async {
    if (_userId == null) {
      print('Cannot load Firebase data: No user ID available');
      return;
    }

    try {
      print('Loading Firebase data for user: $_userId');

      // Firestore 참조 설정
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(_userId);

      // 사용자 문서 가져오기
      DocumentSnapshot userDoc = await userRef.get();

      // 데이터 변경 여부 추적
      bool dataChanged = false;

      // 사용자 문서가 없으면 초기 문서 생성
      if (!userDoc.exists) {
        print('Creating new user document in Firebase during load');
        await userRef.set({
          'brain_health': {
            'brainHealthScore': _brainHealthScore,
            'totalGamesPlayed': _totalGamesPlayed,
            'totalMatchesFound': _totalMatchesFound,
            'bestTime': _bestTime,
            'bestTimesByGridSize': _bestTimesByGridSize,
            'created': FieldValue.serverTimestamp(),
          }
        });
        print('New user document created during load');
      } else {
        // 기존 문서에서 데이터 로드
        final userData = userDoc.data() as Map<String, dynamic>;

        if (userData.containsKey('brain_health')) {
          final brainHealthData =
              userData['brain_health'] as Map<String, dynamic>;

          // Firebase 데이터를 메모리로 로드
          if (brainHealthData.containsKey('brainHealthScore')) {
            int firebaseScore = brainHealthData['brainHealthScore'] ?? 0;
            if (_brainHealthScore != firebaseScore) {
              _brainHealthScore = firebaseScore;
              dataChanged = true;
            }
          }

          if (brainHealthData.containsKey('totalGamesPlayed')) {
            int firebaseGames = brainHealthData['totalGamesPlayed'] ?? 0;
            if (_totalGamesPlayed != firebaseGames) {
              _totalGamesPlayed = firebaseGames;
              dataChanged = true;
            }
          }

          if (brainHealthData.containsKey('totalMatchesFound')) {
            int firebaseMatches = brainHealthData['totalMatchesFound'] ?? 0;
            if (_totalMatchesFound != firebaseMatches) {
              _totalMatchesFound = firebaseMatches;
              dataChanged = true;
            }
          }

          if (brainHealthData.containsKey('bestTime')) {
            int firebaseBestTime = brainHealthData['bestTime'] ?? 0;
            if (firebaseBestTime > 0 &&
                (_bestTime == 0 || firebaseBestTime < _bestTime)) {
              _bestTime = firebaseBestTime;
              dataChanged = true;
            }
          }

          if (brainHealthData.containsKey('bestTimesByGridSize')) {
            final fbBestTimes = brainHealthData['bestTimesByGridSize']
                    as Map<String, dynamic>? ??
                {};

            Map<String, int> firebaseBestTimesByGridSize =
                fbBestTimes.map((key, value) => MapEntry(key, value as int));

            firebaseBestTimesByGridSize.forEach((gridSize, time) {
              if (time > 0 &&
                  (!_bestTimesByGridSize.containsKey(gridSize) ||
                      _bestTimesByGridSize[gridSize] == 0 ||
                      time < _bestTimesByGridSize[gridSize]!)) {
                _bestTimesByGridSize[gridSize] = time;
                dataChanged = true;
              }
            });
          }
        }

        print(
            'Firebase data loaded for user $_userId. Data changed: $dataChanged');
        print('Current score: $_brainHealthScore, Games: $_totalGamesPlayed');
      }

      // 점수 기록 가져오기
      QuerySnapshot scoreSnapshot = await userRef
          .collection('brain_health_history')
          .orderBy('date', descending: false)
          .get();

      print(
          'Loaded ${scoreSnapshot.docs.length} score records from Firebase for user $_userId');

      // Firebase의 점수 기록이 있으면 로컬 메모리의 점수 기록을 대체
      if (scoreSnapshot.docs.isNotEmpty) {
        _scoreHistory = [];
        for (var doc in scoreSnapshot.docs) {
          ScoreRecord record =
              ScoreRecord.fromMap(doc.data() as Map<String, dynamic>);
          _scoreHistory.add(record);
        }

        // 점수 기록 날짜순 정렬
        _scoreHistory.sort((a, b) => a.date.compareTo(b.date));

        // 로컬 스토리지에 업데이트된 기록 저장
        final prefs = await SharedPreferences.getInstance();
        final userKeyPrefix = 'user_${_userId}_';
        List<String> formattedHistory = _scoreHistory.map((record) {
          return "${record.date.millisecondsSinceEpoch}|${record.score}";
        }).toList();

        await prefs.setStringList(
            '${userKeyPrefix}scoreHistory', formattedHistory);
        print(
            'Updated local storage with ${_scoreHistory.length} score records for user $_userId');
        dataChanged = true;
      }

      // 변경된 데이터가 있으면 로컬에 저장
      if (dataChanged) {
        print('Saving updated data to local storage');
        await _saveData();
      }
    } catch (e) {
      print('Firebase data load error: $e');
      _error = 'Failed to load data from server: $e';
    }
  }

  Future<void> _saveData() async {
    if (_disposed) return;

    try {
      // 사용자 ID가 있는 경우에만 저장
      if (_userId != null) {
        print('Saving brain health data for user: $_userId...');

        // 사용자별 키 생성
        final userKeyPrefix = 'user_${_userId}_';

        // 로컬 저장소에 데이터 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
            '${userKeyPrefix}brainHealthScore', _brainHealthScore);
        await prefs.setInt(
            '${userKeyPrefix}totalGamesPlayed', _totalGamesPlayed);
        await prefs.setInt(
            '${userKeyPrefix}totalMatchesFound', _totalMatchesFound);
        await prefs.setInt('${userKeyPrefix}bestTime', _bestTime);

        // Save best times by grid size
        await prefs.setString('${userKeyPrefix}bestTimesByGridSize',
            jsonEncode(_bestTimesByGridSize));

        print('Data saved to local storage for user: $_userId');

        // Firebase에 데이터 저장
        try {
          print('Saving brain health data to Firebase: $_userId');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_userId)
              .update({
            'brain_health.brainHealthScore': _brainHealthScore,
            'brain_health.totalGamesPlayed': _totalGamesPlayed,
            'brain_health.totalMatchesFound': _totalMatchesFound,
            'brain_health.bestTime': _bestTime,
            'brain_health.bestTimesByGridSize': _bestTimesByGridSize,
            'brain_health.lastUpdated': FieldValue.serverTimestamp(),
          });
          print('Brain health data saved to Firebase for user: $_userId');
        } catch (e) {
          print('Failed to save data to Firebase: $e');
          // Firebase 저장 실패 시 필요한 복구 로직을 추가할 수 있음
          // 로컬에는 이미 저장되었으므로 사용자 데이터는 손실되지 않음
        }
      } else {
        print('Cannot save data: No user ID available');
      }
    } catch (e) {
      print('Data save error: $e');
    }
  }

  Future<void> _saveScoreRecord(ScoreRecord record) async {
    if (_userId == null) {
      print('Cannot save score record: No user ID available');
      return;
    }

    try {
      // 사용자별 키 생성
      final userKeyPrefix = 'user_${_userId}_';

      // 로컬에 저장
      final prefs = await SharedPreferences.getInstance();
      List<String> scoreHistory =
          prefs.getStringList('${userKeyPrefix}scoreHistory') ?? [];

      // Format: "timestamp|score"
      String newRecord =
          "${record.date.millisecondsSinceEpoch}|${record.score}";
      scoreHistory.add(newRecord);

      await prefs.setStringList('${userKeyPrefix}scoreHistory', scoreHistory);

      // 메모리에 기록 업데이트
      _scoreHistory.add(record);

      print(
          'Score record saved locally for user $_userId: date=${record.date}, score=${record.score}');

      // Firebase에 저장 시도
      try {
        print('Saving score record to Firebase for user: $_userId');
        DocumentReference docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('brain_health_history')
            .add(record.toMap());

        print(
            'Score record saved to Firebase successfully for user $_userId. Doc ID: ${docRef.id}');
      } catch (e) {
        print('Failed to save score record to Firebase: $e');
        // Firebase 저장 실패 시 필요한 복구 로직을 추가할 수 있음
        // 로컬에는 이미 저장되었으므로 사용자 데이터는 손실되지 않음
      }
    } catch (e) {
      print('Score record save error: $e');
      throw e; // 상위 메서드에서 처리할 수 있도록 예외 다시 던지기
    }
  }

  // 게임 완료 시 점수 추가
  Future<int> addGameCompletion(
      int matchesFound, int timeInSeconds, String gridSize) async {
    if (_disposed) return 0;

    print(
        'Adding game completion: matches=$matchesFound, time=$timeInSeconds, grid=$gridSize');

    // 사용자 인증 확인
    if (_userId == null) {
      print('No user ID found, attempting to authenticate first');
      await _ensureUserAuthenticated();
      if (_userId == null || _disposed) {
        print(
            'Warning: Still unable to get user ID, data will only be saved locally');
        if (_disposed) return 0;
      }
    }

    _totalGamesPlayed++;
    _totalMatchesFound += matchesFound;

    // 시간 기록 (더 빠른 시간만 저장) - 전체 최고 기록
    if (_bestTime == 0 || (timeInSeconds < _bestTime && timeInSeconds > 0)) {
      _bestTime = timeInSeconds;
    }

    // 그리드 크기별 최고 기록 업데이트
    if (!_bestTimesByGridSize.containsKey(gridSize) ||
        _bestTimesByGridSize[gridSize] == 0 ||
        (timeInSeconds < _bestTimesByGridSize[gridSize]! &&
            timeInSeconds > 0)) {
      _bestTimesByGridSize[gridSize] = timeInSeconds;
    }

    // 점수 계산 로직
    // 기본 점수: 매치당 2점
    int baseScore = matchesFound * 2;

    // 시간 보너스: 빠를수록 보너스 점수 (예: 60초 이내 완료 시 추가 보너스)
    int timeBonus = 0;
    if (timeInSeconds > 0) {
      if (timeInSeconds <= 30) {
        timeBonus = 20; // 30초 이내 완료
      } else if (timeInSeconds <= 60) {
        timeBonus = 10; // 60초 이내 완료
      } else if (timeInSeconds <= 120) {
        timeBonus = 5; // 2분 이내 완료
      }
    }

    // 총 획득 점수
    int pointsEarned = baseScore + timeBonus;
    _brainHealthScore += pointsEarned;

    // 점수 기록 저장
    try {
      print('Saving score record with value: ${_brainHealthScore}');
      await _saveScoreRecord(ScoreRecord(DateTime.now(), _brainHealthScore));
      if (_disposed) return pointsEarned;
      print('Score record saved successfully');
    } catch (e) {
      print('Error saving score record: $e');
    }

    try {
      print('Saving other game data');
      await _saveData();
      if (_disposed) return pointsEarned;
      print('Game data saved successfully');
    } catch (e) {
      print('Error saving game data: $e');
    }

    if (!_disposed) {
      notifyListeners();
    }
    return pointsEarned;
  }

  // 데이터 새로고침
  Future<void> refreshData() async {
    if (_disposed) return;

    print('Refreshing brain health data...');
    await _initialize();
    print('Brain health data refresh completed.');
  }

  // 실제 데이터만 사용하여 주간 데이터 가져오기
  List<ScoreRecord> getWeeklyData() {
    // 기록이 없는 경우 기본값 반환
    if (_scoreHistory.isEmpty) {
      print('No score history available, starting with default data');
      return [ScoreRecord(DateTime.now(), 0)]; // 기본값으로 0점 반환
    }

    // 데이터 정렬 (날짜순)
    List<ScoreRecord> sortedHistory = List.from(_scoreHistory);
    sortedHistory.sort((a, b) => a.date.compareTo(b.date));

    print('Using actual score history: ${sortedHistory.length} records');

    // 최근 6개월 이내의 데이터만 필터링
    DateTime sixMonthsAgo = DateTime.now().subtract(Duration(days: 180));
    List<ScoreRecord> recentRecords = sortedHistory
        .where((record) => record.date.isAfter(sixMonthsAgo))
        .toList();

    // 데이터가 너무 많으면 7개 정도로 샘플링
    if (recentRecords.length > 7) {
      print('Sampling from ${recentRecords.length} records');
      List<ScoreRecord> sampledRecords = [];

      // 첫 번째 레코드는 항상 포함
      sampledRecords.add(recentRecords.first);

      // 중간 레코드 샘플링 (5개)
      int step = (recentRecords.length - 2) ~/ 5;
      for (int i = 1; i <= 5; i++) {
        int index = step * i;
        if (index < recentRecords.length - 1) {
          sampledRecords.add(recentRecords[index]);
        }
      }

      // 마지막 레코드는 항상 포함
      sampledRecords.add(recentRecords.last);

      return sampledRecords;
    }

    // 데이터가 7개 이하면 그대로 반환
    print(
        'Using all ${recentRecords.length} records for brain health progress');
    return recentRecords;
  }

  // Firebase 인증 상태 변경 감지 리스너 설정
  void _setupAuthListener() {
    _authStateSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (_disposed) return; // dispose 체크 추가

      print('Auth state changed: ${user?.uid ?? 'logged out'}');
      if (user != null) {
        // 이전 사용자 ID와 다르면 (새로 로그인 했거나 사용자가 변경됨)
        if (_userId != user.uid) {
          String? previousUserId = _userId;
          _userId = user.uid;
          print('User ID changed from $previousUserId to $_userId');

          // 새 사용자는 기본값(0)으로 시작 - 데이터 마이그레이션 없음
          _migrateDataToNewUser(previousUserId);
        }
      } else {
        print('User logged out');
      }
    });
  }

  // 로그인 시 로컬 데이터를 새 사용자 계정으로 마이그레이션
  Future<void> _migrateDataToNewUser(String? previousUserId) async {
    if (_disposed) return;

    print('User ID changed to $_userId - loading user-specific data');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 기존 사용자 데이터 초기화
      _brainHealthScore = 0;
      _totalGamesPlayed = 0;
      _totalMatchesFound = 0;
      _bestTime = 0;
      _bestTimesByGridSize = {};
      _scoreHistory = [];

      // 현재 사용자의 로컬 데이터가 있으면 로드
      await _loadLocalData();
      if (_disposed) return; // dispose 체크 추가

      // Firebase에서 사용자 데이터 로드
      await _loadFirebaseData();
      if (_disposed) return; // dispose 체크 추가

      print('User-specific data loaded successfully for user $_userId');
    } catch (e) {
      print('Error loading user-specific data: $e');
      _error = 'Failed to load user data: $e';
    } finally {
      if (!_disposed) {
        // dispose 체크 추가
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // 사용자가 로그인할 때 호출할 메서드
  Future<void> handleUserLogin(User newUser) async {
    if (_disposed) return; // dispose된 경우 진행하지 않음

    print('Handling user login: ${newUser.uid}');
    if (_userId == newUser.uid) {
      print('User already using this account');

      // 기존 사용자의 정보가 업데이트되었는지 확인
      await _updateUserInfo(newUser);
      return;
    }

    // 기존 데이터 백업
    final oldUserId = _userId;

    // 새 사용자 ID 설정
    _userId = newUser.uid;

    // 새 사용자 정보 업데이트
    await _updateUserInfo(newUser);

    // 로컬 데이터와 새 사용자 계정의 Firebase 데이터 마이그레이션
    await _migrateDataToNewUser(oldUserId);
  }

  // 사용자 정보를 최신 상태로 업데이트
  Future<void> _updateUserInfo(User user) async {
    if (user.isAnonymous) {
      print('Not updating user info for anonymous user');
      return;
    }

    try {
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      DocumentSnapshot userDoc = await userRef.get();
      Map<String, dynamic> updates = {};

      // 이메일 업데이트
      if (user.email != null) {
        updates['email'] = user.email;
      }

      // 닉네임 업데이트 (displayName이 있을 경우)
      if (user.displayName != null) {
        updates['nickname'] = user.displayName;
      } else if (user.email != null &&
          (!userDoc.exists ||
              !(userDoc.data() as Map<String, dynamic>)
                  .containsKey('nickname'))) {
        // 닉네임이 없는 경우 이메일 앞부분 사용
        updates['nickname'] = user.email!.split('@')[0];
      }

      // 익명 계정 여부 업데이트
      updates['isAnonymous'] = false;

      // 마지막 로그인 시간 업데이트
      updates['lastLogin'] = FieldValue.serverTimestamp();

      if (updates.isNotEmpty) {
        await userRef.set(updates, SetOptions(merge: true));
        print('Updated user info: $updates');
      }
    } catch (e) {
      print('Error updating user info: $e');
    }
  }

  // 사용자가 로그아웃할 때 호출할 메서드
  Future<void> handleUserLogout() async {
    if (_disposed) return;

    print('Handling user logout');

    String? previousUserId = _userId;

    // 마지막 상태 저장
    try {
      if (_userId != null) {
        await _saveData();
        print('Saved data before logout for user: $_userId');
      }
    } catch (e) {
      print('Error saving data before logout: $e');
    }

    // 사용자 ID 초기화
    _userId = null;

    try {
      // 현재 로그인된 사용자 로그아웃
      await FirebaseAuth.instance.signOut();
      if (_disposed) return;

      print('User signed out successfully');

      // 익명 로그인 시도
      await _ensureUserAuthenticated();
      if (_disposed) return;

      if (_userId != null && _userId != previousUserId) {
        print('Switched to anonymous account: $_userId');

        // 이전 계정의 데이터 로드 (점수 이력 위함)
        if (previousUserId != null) {
          try {
            DocumentReference prevUserRef = FirebaseFirestore.instance
                .collection('users')
                .doc(previousUserId);

            DocumentSnapshot prevUserDoc = await prevUserRef.get();
            if (_disposed) return;

            if (prevUserDoc.exists) {
              Map<String, dynamic> prevData =
                  prevUserDoc.data() as Map<String, dynamic>;

              // 이전 계정의 점수 데이터를 새 익명 계정으로 복사 (옵션)
              bool shouldTransferData = false; // 데이터 이전을 건너뜀 - 새 계정은 항상 0에서 시작

              if (shouldTransferData) {
                // 익명 계정에 기존 데이터 복사
                DocumentReference newUserRef =
                    FirebaseFirestore.instance.collection('users').doc(_userId);

                Map<String, dynamic> dataToTransfer = {
                  'brain_health': {
                    'brainHealthScore': prevData['brainHealthScore'] ?? 0,
                    'totalGamesPlayed': prevData['totalGamesPlayed'] ?? 0,
                    'totalMatchesFound': prevData['totalMatchesFound'] ?? 0,
                    'bestTime': prevData['bestTime'] ?? 0,
                    'bestTimesByGridSize':
                        prevData['bestTimesByGridSize'] ?? {},
                    'transferredFrom': previousUserId,
                    'transferredAt': FieldValue.serverTimestamp(),
                  }
                };

                await newUserRef.set(dataToTransfer, SetOptions(merge: true));
                if (_disposed) return;

                print(
                    'Transferred data from previous user to anonymous account');

                // 메모리 상의 데이터 업데이트
                _brainHealthScore = prevData['brainHealthScore'] ?? 0;
                _totalGamesPlayed = prevData['totalGamesPlayed'] ?? 0;
                _totalMatchesFound = prevData['totalMatchesFound'] ?? 0;
                _bestTime = prevData['bestTime'] ?? 0;
                _bestTimesByGridSize = prevData['bestTimesByGridSize'] ?? {};

                // 점수 기록 이전
                try {
                  QuerySnapshot scoreSnapshot = await prevUserRef
                      .collection('brain_health_history')
                      .orderBy('date', descending: false)
                      .get();
                  if (_disposed) return;

                  if (scoreSnapshot.docs.isNotEmpty) {
                    int transferCount = 0;

                    for (var doc in scoreSnapshot.docs) {
                      if (_disposed) return;

                      Map<String, dynamic> scoreData =
                          doc.data() as Map<String, dynamic>;
                      await newUserRef
                          .collection('brain_health_history')
                          .add(scoreData);
                      transferCount++;
                    }

                    print(
                        'Transferred $transferCount score records to anonymous account');

                    // 로컬 메모리에 점수 기록 로드
                    await _loadFirebaseData();
                  }
                } catch (e) {
                  print('Error transferring score history: $e');
                }
              }
            }
          } catch (e) {
            print('Error accessing previous user data: $e');
          }
        }
      }
    } catch (e) {
      print('Error during logout process: $e');
    }

    if (!_disposed) {
      notifyListeners();
    }
  }

  // 현재 사용자 정보 가져오기
  Map<String, dynamic> getUserInfo() {
    return {
      'isLoggedIn': _userId != null,
      'userId': _userId,
      'isAnonymous': FirebaseAuth.instance.currentUser?.isAnonymous ?? true,
      'brainHealthScore': _brainHealthScore,
      'totalGamesPlayed': _totalGamesPlayed,
      'scoreHistoryCount': _scoreHistory.length,
    };
  }

  // 현재 Brain Health 점수 가져오기
  Future<int> getCurrentPoints() async {
    // 사용자 인증 확인
    if (_userId == null) {
      print('No user ID found, attempting to authenticate first');
      await _ensureUserAuthenticated();
      if (_userId == null || _disposed) {
        print(
            'Warning: Unable to get user ID, returning only local brain health score');
        if (_disposed) return 0;
      }
    }

    // 오프라인 상태에서도 동작하도록 로컬 값 반환
    return _brainHealthScore;
  }

  // Brain Health 점수 차감
  Future<bool> deductPoints(int points) async {
    if (_disposed) return false;
    if (points <= 0) return true; // 차감할 점수가 0 이하면 성공으로 간주

    // 사용자 인증 확인
    if (_userId == null) {
      print('No user ID found, attempting to authenticate first');
      await _ensureUserAuthenticated();
      if (_userId == null || _disposed) {
        print('Warning: Unable to get user ID, cannot deduct points');
        return false;
      }
    }

    // 현재 점수가 차감할 점수보다 적으면 실패
    if (_brainHealthScore < points) {
      print('Not enough points: current=$_brainHealthScore, required=$points');
      return false;
    }

    // 점수 차감
    _brainHealthScore -= points;

    // 데이터 저장
    try {
      print(
          'Saving updated brain health score after deduction: $_brainHealthScore');
      await _saveData();
      if (_disposed) return true;

      // 점수 차감 기록 저장
      await _saveScoreRecord(ScoreRecord(DateTime.now(), _brainHealthScore));
      if (_disposed) return true;

      print(
          'Points deducted successfully: -$points, new score: $_brainHealthScore');
      notifyListeners();
      return true;
    } catch (e) {
      print('Error while deducting points: $e');
      return false;
    }
  }

  // 명시적으로 데이터 동기화 요청
  Future<void> syncData() async {
    if (_disposed) return;

    print('Manually syncing data...');
    _isLoading = true;
    notifyListeners();

    try {
      await _ensureUserAuthenticated();
      if (_disposed) return;

      if (_userId != null) {
        // 로컬 및 Firebase 데이터 로드 및 병합
        await _loadFirebaseData();
        print('Manual data sync completed');
      } else {
        print('Cannot sync data: No user ID available');
        _error = 'Failed to authenticate for data sync';
      }
    } catch (e) {
      print('Manual data sync error: $e');
      _error = 'Failed to sync data: $e';
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // notifyListeners 안전하게 호출
  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;

    // 리소스 정리
    try {
      // Firebase 리스너 정리
      _authStateSubscription?.cancel();

      // 메모리 정리
      _scoreHistory.clear();
      _bestTimesByGridSize.clear();

      print('BrainHealthProvider resources cleaned up successfully');
    } catch (e) {
      print('Error during resource cleanup: $e');
    } finally {
      super.dispose();
    }
  }

  // 에러 핸들링 개선
  void _handleError(String operation, dynamic error) {
    final errorMessage = 'Error during $operation: $error';
    print(errorMessage);
    _error = errorMessage;

    // 에러가 발생해도 앱이 계속 작동하도록 기본값 설정
    if (operation == 'data_load') {
      _brainHealthScore = 0;
      _totalGamesPlayed = 0;
      _totalMatchesFound = 0;
      _bestTime = 0;
      _bestTimesByGridSize = {};
      _scoreHistory = [];
    }

    if (!_disposed) {
      notifyListeners();
    }
  }

  // 사용자 랭킹 데이터를 가져오는 메서드
  Future<List<Map<String, dynamic>>> getUserRankings() async {
    if (_disposed) return [];

    try {
      // Firestore에서 상위 10명의 사용자 랭킹을 가져옵니다
      QuerySnapshot rankingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('brain_health.brainHealthScore', descending: true)
          .limit(10)
          .get();

      List<Map<String, dynamic>> rankings = [];
      int rank = 1;

      for (var doc in rankingSnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        Map<String, dynamic> brainHealthData = {};

        // brain_health 필드가 있는지 확인
        if (userData.containsKey('brain_health') &&
            userData['brain_health'] is Map) {
          brainHealthData = userData['brain_health'] as Map<String, dynamic>;
        }

        // 사용자 정보 가져오기
        String displayName = 'Anonymous';
        if (userData.containsKey('nickname') && userData['nickname'] != null) {
          displayName = userData['nickname'];
        } else if (userData.containsKey('displayName') &&
            userData['displayName'] != null) {
          displayName = userData['displayName'];
        } else if (userData.containsKey('email') && userData['email'] != null) {
          displayName = userData['email'].toString().split('@')[0];
        }

        // 국가 코드 가져오기
        String countryCode = 'un'; // UN 플래그를 기본값으로 설정
        if (userData.containsKey('country') && userData['country'] != null) {
          countryCode = userData['country'].toString().toLowerCase();
        }

        // 현재 사용자인지 확인
        bool isCurrentUser = doc.id == _userId;

        rankings.add({
          'rank': rank,
          'userId': doc.id,
          'displayName': displayName,
          'score': brainHealthData['brainHealthScore'] ?? 0,
          'isCurrentUser': isCurrentUser,
          'countryCode': countryCode, // 국가 코드 추가
        });

        rank++;
      }

      return rankings;
    } catch (e) {
      print('Error fetching user rankings: $e');
      return [];
    }
  }
}
