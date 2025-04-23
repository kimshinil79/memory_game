import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemoryGameService extends ChangeNotifier {
  // 현재 그리드 크기
  String _gridSize = '4x4';

  // 그리드 크기 옵션들
  final List<String> gridSizeOptions = ['4x4', '4x6', '6x6', '6x8'];

  // 리스너들 (위젯에서 이벤트를 구독할 수 있게 함)
  final List<Function(String)> _gridChangeListeners = [];

  // 선택된 플레이어 목록
  List<Map<String, dynamic>> _selectedPlayers = [];

  // 선택된 플레이어 변경 리스너
  final List<Function(List<Map<String, dynamic>>)> _playerChangeListeners = [];

  // 그리드 크기 getter
  String get gridSize => _gridSize;

  // 선택된 플레이어 목록 getter
  List<Map<String, dynamic>> get selectedPlayers => List.from(_selectedPlayers);

  // 현재 로그인한 사용자 포함 총 플레이어 수
  int get totalPlayerCount => _selectedPlayers.length + 1;

  // 멀티플레이어 게임 관련 변수 추가
  int _currentPlayerIndex = 0; // 현재 턴인 플레이어의 인덱스
  final List<Function(int)> _playerTurnChangeListeners = []; // 턴 변경 리스너

  // 점수 관리를 위한 변수 추가
  Map<int, int> _playerScores = {}; // 플레이어 인덱스 -> 점수 맵핑
  final List<Function(Map<int, int>)> _scoreChangeListeners = []; // 점수 변경 리스너

  // 시간 관련 변수 추가
  int _gameStartTime = 0; // 게임 시작 시간 (밀리초)
  int _gameEndTime = 0; // 게임 종료 시간 (밀리초)
  final List<Function(int, int, int)> _timeBasedScoreListeners =
      []; // 시간 기반 점수 리스너 (완료시간, 기본점수, 보너스점수)

  // 현재 턴인 플레이어 인덱스 getter
  int get currentPlayerIndex => _currentPlayerIndex;

  // 플레이어 점수 맵 getter
  Map<int, int> get playerScores => Map.from(_playerScores);

  // 현재 턴인 플레이어 정보 getter
  Map<String, dynamic>? get currentPlayer {
    if (_currentPlayerIndex == 0) {
      // 첫 번째 플레이어는 현재 로그인한 사용자
      return null; // 현재 사용자 정보는 별도로 가져와야 함
    } else if (_currentPlayerIndex <= _selectedPlayers.length) {
      // 선택된 플레이어 중 하나 (인덱스는 1부터 시작)
      return _selectedPlayers[_currentPlayerIndex - 1];
    }
    return null;
  }

  // 게임 시작 시간 기록
  void recordGameStart() {
    _gameStartTime = DateTime.now().millisecondsSinceEpoch;
    print('게임 시작 시간 기록: $_gameStartTime');
  }

  // 게임 완료 시간 기록 및 보너스 점수 계산
  int recordGameCompletion(int winnerPlayerIndex) {
    _gameEndTime = DateTime.now().millisecondsSinceEpoch;
    int gameTimeInSeconds = (_gameEndTime - _gameStartTime) ~/ 1000;
    print('게임 완료 시간: $gameTimeInSeconds 초');
    print('우승자 인덱스: $winnerPlayerIndex, 총 플레이어 수: $totalPlayerCount');

    // 기존 점수 가져오기 (이미 게임 내에서 계산된 매치 성공 수)
    int baseScore = getPlayerScore(winnerPlayerIndex);
    print('기존 방식 기본 점수: $baseScore');

    // 팝업창 방식의 점수 계산 적용
    // 1. 시간 보너스 계산 (팝업창과 동일한 계산 방식 적용)
    int timeBonus = calculateTimeBonus(gameTimeInSeconds);
    print('시간 보너스: $timeBonus');

    // 2. 매치 성공 개수에 따른 기본 점수 (카드 쌍 수 * 50)
    // 현재 그리드 크기에 따른 카드 쌍 수 계산
    int totalPairs = 0;
    switch (_gridSize) {
      case '4x4':
        totalPairs = 8; // 4x4 그리드는 16장의 카드 = 8쌍
        break;
      case '4x6':
        totalPairs = 12; // 4x6 그리드는 24장의 카드 = 12쌍
        break;
      case '6x6':
        totalPairs = 18; // 6x6 그리드는 36장의 카드 = 18쌍
        break;
      case '6x8':
        totalPairs = 24; // 6x8 그리드는 48장의 카드 = 24쌍
        break;
      default:
        totalPairs = 8;
    }

    // 매치 성공 개수에 기반한 기본 점수 (매치당 50점)
    int matchPointsBase = totalPairs * 50;
    print('매치 포인트 베이스: $matchPointsBase');

    // 3. 그리드 크기에 따른 계수 적용
    int gridMultiplier = getGridSizeMultiplier(_gridSize);
    print('그리드 크기 계수: $gridMultiplier');

    // 4. 최종 기본 점수 계산 (매치 포인트 + 시간 보너스) * 그리드 계수
    int calculatedBaseScore = (matchPointsBase + timeBonus) * gridMultiplier;
    print('팝업창 방식 계산된 기본 점수: $calculatedBaseScore');

    // 5. 멀티플레이어 배수 적용
    int finalScore = calculatedBaseScore;
    if (totalPlayerCount > 1) {
      int playerMultiplier = totalPlayerCount;
      finalScore = calculatedBaseScore * playerMultiplier;
      print(
          '멀티플레이어 승자 보너스: $playerMultiplier배 (${totalPlayerCount}명 참가), 최종 점수: $finalScore');
    }

    // 계산된 점수를 playerScores에 설정
    setPlayerScore(winnerPlayerIndex, finalScore);
    print('최종 점수: $finalScore, 선택된 플레이어 목록: $_selectedPlayers');

    // 비로그인 플레이어(인덱스가 0이 아닌 플레이어)가 이긴 경우 해당 플레이어의 brainHealthScore 업데이트
    if (winnerPlayerIndex > 0) {
      print('비로그인 플레이어 승리 조건 확인: $winnerPlayerIndex > 0');
      if (winnerPlayerIndex <= _selectedPlayers.length) {
        print(
            '선택된 플레이어 범위 내 조건 확인: $winnerPlayerIndex <= ${_selectedPlayers.length}');
        try {
          Map<String, dynamic> winnerPlayer =
              _selectedPlayers[winnerPlayerIndex - 1];
          print('우승자 플레이어 정보: $winnerPlayer');
          if (winnerPlayer.containsKey('id')) {
            String playerId = winnerPlayer['id'];
            print('우승자 ID: $playerId, 최종 점수: $finalScore');
            print('⚠️ 점수 업데이트는 memory_game_page.dart에서 직접 처리됩니다.');
          } else {
            print('오류: 우승자 정보에 ID가 없습니다!');
          }
        } catch (e) {
          print('우승자 정보 처리 중 오류 발생: $e');
        }
      } else {
        print(
            '오류: 우승자 인덱스($winnerPlayerIndex)가 선택된 플레이어 수(${_selectedPlayers.length})를 초과합니다!');
      }
    } else {
      print('로그인된 사용자 승리 (인덱스 0)');
    }

    // 리스너들에게 알림
    for (var listener in _timeBasedScoreListeners) {
      listener(gameTimeInSeconds, calculatedBaseScore, timeBonus);
    }

    return timeBonus;
  }

  // 우승자의 헬스 점수 업데이트
  Future<void> updateWinnerHealthScore(String playerId, int score) async {
    print('우승자 점수 업데이트 시작 - ID: $playerId, 점수: $score');
    try {
      // Firebase에서 플레이어 문서 가져오기
      print('Firebase에서 플레이어 문서 조회 중...');
      DocumentSnapshot playerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(playerId)
          .get();

      if (!playerDoc.exists) {
        print('우승자 문서가 존재하지 않습니다: $playerId');
        return;
      }

      print('플레이어 문서 조회 성공');
      Map<String, dynamic> playerData =
          playerDoc.data() as Map<String, dynamic>;
      print('플레이어 데이터: $playerData');

      // 현재 brain_health 데이터 가져오기
      Map<String, dynamic> brainHealth = {};
      if (playerData.containsKey('brain_health') &&
          playerData['brain_health'] is Map) {
        brainHealth = Map<String, dynamic>.from(playerData['brain_health']);
        print('기존 brain_health 데이터: $brainHealth');
      } else {
        print('brain_health 데이터가 없어 새로 생성합니다.');
      }

      // 현재 brainHealthScore 가져오기
      int currentScore = 0;
      if (brainHealth.containsKey('brainHealthScore')) {
        currentScore = brainHealth['brainHealthScore'] as int;
      }

      // 점수 업데이트
      int newScore = currentScore + score;
      brainHealth['brainHealthScore'] = newScore;
      print('점수 업데이트: $currentScore → $newScore (+$score)');

      // Firebase에 업데이트된 brain_health 저장
      print('Firebase에 업데이트된 점수 저장 중...');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(playerId)
          .update({'brain_health': brainHealth});

      print('우승자 $playerId의 brainHealthScore 업데이트 완료: $newScore');
    } catch (e) {
      print('우승자 점수 업데이트 오류: $e');
      // 스택 트레이스 출력
      print(StackTrace.current);
    }
  }

  // 시간 기반 보너스 점수 계산 메서드
  int calculateTimeBonus(int timeInSeconds) {
    // 그리드 크기별 목표 시간 (초) 설정
    Map<String, Map<String, int>> gridTimeTiers = {
      '4x4': {
        'excellent': 30, // 30초 이하: 탁월함 (500 포인트)
        'veryGood': 45, // 45초 이하: 매우 좋음 (300 포인트)
        'good': 60, // 60초 이하: 좋음 (200 포인트)
        'average': 90, // 90초 이하: 평균 (100 포인트)
        'slow': 120, // 120초 이하: 느림 (50 포인트)
      },
      '4x6': {
        'excellent': 45, // 45초 이하: 탁월함 (800 포인트)
        'veryGood': 70, // 70초 이하: 매우 좋음 (500 포인트)
        'good': 100, // 100초 이하: 좋음 (300 포인트)
        'average': 140, // 140초 이하: 평균 (150 포인트)
        'slow': 180, // 180초 이하: 느림 (80 포인트)
      },
      '6x6': {
        'excellent': 60, // 60초 이하: 탁월함 (1200 포인트)
        'veryGood': 90, // 90초 이하: 매우 좋음 (800 포인트)
        'good': 150, // 150초 이하: 좋음 (500 포인트)
        'average': 210, // 210초 이하: 평균 (250 포인트)
        'slow': 270, // 270초 이하: 느림 (120 포인트)
      },
      '6x8': {
        'excellent': 90, // 90초 이하: 탁월함 (2000 포인트)
        'veryGood': 150, // 150초 이하: 매우 좋음 (1200 포인트)
        'good': 210, // 210초 이하: 좋음 (800 포인트)
        'average': 300, // 300초 이하: 평균 (400 포인트)
        'slow': 390, // 390초 이하: 느림 (200 포인트)
      },
    };

    // 그리드 크기별 보너스 점수 설정
    Map<String, Map<String, int>> gridBonusPoints = {
      '4x4': {
        'excellent': 500,
        'veryGood': 300,
        'good': 200,
        'average': 100,
        'slow': 50,
        'default': 10,
      },
      '4x6': {
        'excellent': 800,
        'veryGood': 500,
        'good': 300,
        'average': 150,
        'slow': 80,
        'default': 20,
      },
      '6x6': {
        'excellent': 1200,
        'veryGood': 800,
        'good': 500,
        'average': 250,
        'slow': 120,
        'default': 30,
      },
      '6x8': {
        'excellent': 2000,
        'veryGood': 1200,
        'good': 800,
        'average': 400,
        'slow': 200,
        'default': 50,
      },
    };

    // 현재 그리드 크기에 대한 시간 기준 및 보너스 점수 가져오기
    var timeTiers = gridTimeTiers[_gridSize] ?? gridTimeTiers['4x4']!;
    var bonusPoints = gridBonusPoints[_gridSize] ?? gridBonusPoints['4x4']!;

    // 시간에 따른 보너스 점수 결정
    int bonus = bonusPoints['default']!;
    String tier = 'default';

    if (timeInSeconds <= timeTiers['excellent']!) {
      bonus = bonusPoints['excellent']!;
      tier = 'excellent';
    } else if (timeInSeconds <= timeTiers['veryGood']!) {
      bonus = bonusPoints['veryGood']!;
      tier = 'veryGood';
    } else if (timeInSeconds <= timeTiers['good']!) {
      bonus = bonusPoints['good']!;
      tier = 'good';
    } else if (timeInSeconds <= timeTiers['average']!) {
      bonus = bonusPoints['average']!;
      tier = 'average';
    } else if (timeInSeconds <= timeTiers['slow']!) {
      bonus = bonusPoints['slow']!;
      tier = 'slow';
    }

    print('완료 시간: $timeInSeconds초, 등급: $tier, 보너스 점수: $bonus');
    return bonus;
  }

  // 시간 기반 보너스 점수 리스너 추가
  void addTimeBasedScoreListener(Function(int, int, int) listener) {
    if (!_timeBasedScoreListeners.contains(listener)) {
      _timeBasedScoreListeners.add(listener);
    }
  }

  // 시간 기반 보너스 점수 리스너 제거
  void removeTimeBasedScoreListener(Function(int, int, int) listener) {
    _timeBasedScoreListeners.remove(listener);
  }

  // 그리드 크기별 목표 시간 및 보너스 점수 정보 가져오기
  Map<String, dynamic> getTimeBonus() {
    // 그리드 크기별 목표 시간 (초) 설정
    Map<String, Map<String, int>> gridTimeTiers = {
      '4x4': {
        'excellent': 30,
        'veryGood': 45,
        'good': 60,
        'average': 90,
        'slow': 120,
      },
      '4x6': {
        'excellent': 45,
        'veryGood': 70,
        'good': 100,
        'average': 140,
        'slow': 180,
      },
      '6x6': {
        'excellent': 60,
        'veryGood': 90,
        'good': 150,
        'average': 210,
        'slow': 270,
      },
      '6x8': {
        'excellent': 90,
        'veryGood': 150,
        'good': 210,
        'average': 300,
        'slow': 390,
      },
    };

    // 그리드 크기별 보너스 점수 설정
    Map<String, Map<String, int>> gridBonusPoints = {
      '4x4': {
        'excellent': 500,
        'veryGood': 300,
        'good': 200,
        'average': 100,
        'slow': 50,
        'default': 10,
      },
      '4x6': {
        'excellent': 800,
        'veryGood': 500,
        'good': 300,
        'average': 150,
        'slow': 80,
        'default': 20,
      },
      '6x6': {
        'excellent': 1200,
        'veryGood': 800,
        'good': 500,
        'average': 250,
        'slow': 120,
        'default': 30,
      },
      '6x8': {
        'excellent': 2000,
        'veryGood': 1200,
        'good': 800,
        'average': 400,
        'slow': 200,
        'default': 50,
      },
    };

    // 현재 그리드 크기에 대한 정보 반환
    return {
      'timeTiers': gridTimeTiers[_gridSize] ?? gridTimeTiers['4x4']!,
      'bonusPoints': gridBonusPoints[_gridSize] ?? gridBonusPoints['4x4']!,
    };
  }

  // 점수 초기화 (게임 시작 시 호출)
  void initializeScores() {
    _playerScores.clear();

    // 모든 플레이어의 점수를 0으로 초기화
    for (int i = 0; i < totalPlayerCount; i++) {
      _playerScores[i] = 0;
    }

    print('점수 초기화 완료: $_playerScores, 총 플레이어 수: $totalPlayerCount');
    _notifyScoreChanged();
    notifyListeners();
  }

  // 현재 플레이어의 점수 증가
  void increaseCurrentPlayerScore() {
    print('점수 증가 시도 - 현재 플레이어: $_currentPlayerIndex, 현재 점수: $_playerScores');

    if (_playerScores.containsKey(_currentPlayerIndex)) {
      _playerScores[_currentPlayerIndex] =
          (_playerScores[_currentPlayerIndex] ?? 0) + 1;
      print('점수 증가 후: $_playerScores');
      _notifyScoreChanged();
      notifyListeners();
    } else {
      print('오류: 현재 플레이어($_currentPlayerIndex)의 점수 정보가 없습니다.');
      // 오류 복구 시도: 점수가 없으면 새로 초기화
      _playerScores[_currentPlayerIndex] = 1;
      _notifyScoreChanged();
      notifyListeners();
    }
  }

  // 특정 플레이어의 점수 설정
  void setPlayerScore(int playerIndex, int score) {
    if (playerIndex >= 0 && playerIndex < totalPlayerCount) {
      _playerScores[playerIndex] = score;
      _notifyScoreChanged();
      notifyListeners();
    }
  }

  // 특정 플레이어의 점수 가져오기
  int getPlayerScore(int playerIndex) {
    return _playerScores[playerIndex] ?? 0;
  }

  // 점수 변경 알림
  void _notifyScoreChanged() {
    for (var listener in _scoreChangeListeners) {
      listener(_playerScores);
    }
  }

  // 점수 변경 리스너 추가
  void addScoreChangeListener(Function(Map<int, int>) listener) {
    if (!_scoreChangeListeners.contains(listener)) {
      _scoreChangeListeners.add(listener);
    }
  }

  // 점수 변경 리스너 제거
  void removeScoreChangeListener(Function(Map<int, int>) listener) {
    _scoreChangeListeners.remove(listener);
  }

  // 현재 턴 초기화 (게임 시작 시 호출)
  void initializePlayerTurn() {
    _currentPlayerIndex = 0;
    notifyListeners();
    _notifyPlayerTurnChanged();
  }

  // 게임 초기화 (턴과 점수 모두 초기화)
  void initializeGame() {
    initializePlayerTurn();
    initializeScores();
    recordGameStart(); // 게임 시작 시간 기록
  }

  // 카드 매치 확인 후 턴과 점수 관리 메서드
  void handleCardMatchResult(bool isMatched) {
    if (isMatched) {
      // 매치 성공 시 현재 플레이어 점수 증가
      increaseCurrentPlayerScore();
      // 현재 플레이어가 계속 진행
    } else {
      // 매치 실패 시 다음 플레이어로 턴 넘기기
      moveToNextPlayer();
    }
  }

  // 턴을 다음 플레이어에게 넘기는 메서드
  void moveToNextPlayer() {
    _currentPlayerIndex = (_currentPlayerIndex + 1) % totalPlayerCount;
    notifyListeners();
    _notifyPlayerTurnChanged();
  }

  // 턴 변경 알림
  void _notifyPlayerTurnChanged() {
    for (var listener in _playerTurnChangeListeners) {
      listener(_currentPlayerIndex);
    }
  }

  // 플레이어 턴 변경 리스너 추가
  void addPlayerTurnChangeListener(Function(int) listener) {
    if (!_playerTurnChangeListeners.contains(listener)) {
      _playerTurnChangeListeners.add(listener);
    }
  }

  // 플레이어 턴 변경 리스너 제거
  void removePlayerTurnChangeListener(Function(int) listener) {
    _playerTurnChangeListeners.remove(listener);
  }

  // 그리드 크기 setter
  set gridSize(String newSize) {
    if (gridSizeOptions.contains(newSize) && _gridSize != newSize) {
      _gridSize = newSize;
      // 그리드 크기가 변경될 때 자동으로 게임 초기화
      initializeGame();
      // 모든 리스너에게 변경 알림
      for (var listener in _gridChangeListeners) {
        listener(newSize);
      }
      notifyListeners();
    }
  }

  // 선택된 플레이어 목록 setter
  set selectedPlayers(List<Map<String, dynamic>> players) {
    // null 또는 비어있는 리스트 처리
    if (players.isEmpty) {
      print('선택된 플레이어가 없어 목록 초기화');
      _selectedPlayers = [];
      notifyListeners();

      // 리스너들에게 변경 알림
      for (var listener in _playerChangeListeners) {
        listener(_selectedPlayers);
      }
      return;
    }

    // 플레이어 목록이 변경되었는지 확인
    bool playersChanged = _selectedPlayers.length != players.length;

    if (!playersChanged) {
      // 개수가 같은 경우 내용 비교
      for (int i = 0; i < _selectedPlayers.length; i++) {
        if (i >= players.length ||
            _selectedPlayers[i]['id'] != players[i]['id']) {
          playersChanged = true;
          break;
        }
      }
    }

    // 선택된 플레이어 로그 출력
    print('선택된 플레이어 정보 업데이트:');
    for (var player in players) {
      print(
          ' - ${player['nickname'] ?? 'Unknown'} (국가: ${player['country'] ?? 'un'})');
    }

    _selectedPlayers = List.from(players);

    // 플레이어 목록이 변경되었으면 게임 초기화
    if (playersChanged) {
      print('플레이어 목록이 변경되어 게임 초기화');
      initializeGame();
    }

    // 모든 리스너에게 변경 알림
    for (var listener in _playerChangeListeners) {
      listener(_selectedPlayers);
    }
    notifyListeners();
  }

  // 그리드 변경 리스너 추가
  void addGridChangeListener(Function(String) listener) {
    if (!_gridChangeListeners.contains(listener)) {
      _gridChangeListeners.add(listener);
    }
  }

  // 그리드 변경 리스너 제거
  void removeGridChangeListener(Function(String) listener) {
    _gridChangeListeners.remove(listener);
  }

  // 플레이어 변경 리스너 추가
  void addPlayerChangeListener(Function(List<Map<String, dynamic>>) listener) {
    if (!_playerChangeListeners.contains(listener)) {
      _playerChangeListeners.add(listener);
    }
  }

  // 플레이어 변경 리스너 제거
  void removePlayerChangeListener(
      Function(List<Map<String, dynamic>>) listener) {
    _playerChangeListeners.remove(listener);
  }

  // 그리드 크기에 따른 점수 계수 계산
  int getGridSizeMultiplier(String gridSize) {
    switch (gridSize) {
      case '4x4':
        return 1; // 기본 계수
      case '4x6':
        return 3; // 4x6 그리드에 대해 3배 점수
      case '6x6':
        return 5; // 6x6 그리드에 대해 5배 점수
      case '6x8':
        return 8; // 6x8 그리드에 대해 8배 점수
      default:
        return 1;
    }
  }

  // 플레이어 선택 관련 메서드들

  // 사용자 목록을 가져오는 메서드
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      // 현재 사용자 정보 가져오기
      User? currentUser = FirebaseAuth.instance.currentUser;
      String? currentUserId = currentUser?.uid;

      // Firebase에서 모든 사용자 가져오기
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      List<Map<String, dynamic>> users = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

        // 사용자 ID 포함
        userData['id'] = doc.id;

        // 현재 사용자는 목록에서 제외 (자신은 선택 목록에 포함시키지 않음)
        if (currentUserId != null && userData['id'] == currentUserId) {
          continue;
        }

        // 닉네임이 없는 경우 기본값 설정
        if (!userData.containsKey('nickname') || userData['nickname'] == null) {
          userData['nickname'] = 'Unknown Player';
        }

        // 국가 코드가 없는 경우 기본값 설정
        if (!userData.containsKey('country') || userData['country'] == null) {
          userData['country'] = 'un'; // UN 플래그를 기본값으로 사용
        }

        // 브레인 헬스 점수 (없는 경우 0으로 설정)
        if (userData.containsKey('brain_health') &&
            userData['brain_health'] is Map &&
            (userData['brain_health'] as Map).containsKey('brainHealthScore')) {
          userData['brainHealthScore'] =
              userData['brain_health']['brainHealthScore'];
        } else {
          userData['brainHealthScore'] = 0;
        }

        // 성별 정보 처리
        if (!userData.containsKey('gender') || userData['gender'] == null) {
          userData['gender'] = 'unknown';
        }

        // 나이 정보 처리
        if (!userData.containsKey('age') || userData['age'] == null) {
          userData['age'] = 0;
        }

        // shortPW 정보 처리
        if (userData.containsKey('shortPW')) {
          userData['hasShortPW'] = true;
        } else {
          userData['hasShortPW'] = false;
        }

        // 사용자를 목록에 추가
        users.add(userData);
      }

      return users;
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // 현재 로그인된 사용자 정보 가져오기
  Future<Map<String, dynamic>> getCurrentUserInfo() async {
    try {
      // 현재 사용자 정보 가져오기
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        return {
          'id': 'me',
          'nickname': 'Me',
          'country': 'un',
          'brainHealthScore': 0,
          'gender': 'unknown',
          'age': 0,
          'hasShortPW': false
        };
      }

      // Firebase에서 현재 사용자 문서 가져오기
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        return {
          'id': currentUser.uid,
          'nickname': 'Me',
          'country': 'un',
          'brainHealthScore': 0,
          'gender': 'unknown',
          'age': 0,
          'hasShortPW': false
        };
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // 사용자 ID 포함
      userData['id'] = currentUser.uid;

      // 닉네임이 없는 경우 기본값 설정
      if (!userData.containsKey('nickname') || userData['nickname'] == null) {
        userData['nickname'] = 'Me';
      }

      // 국가 코드가 없는 경우 기본값 설정
      if (!userData.containsKey('country') || userData['country'] == null) {
        userData['country'] = 'un'; // UN 플래그를 기본값으로 사용
      }

      // 브레인 헬스 점수 (없는 경우 0으로 설정)
      if (userData.containsKey('brain_health') &&
          userData['brain_health'] is Map &&
          (userData['brain_health'] as Map).containsKey('brainHealthScore')) {
        userData['brainHealthScore'] =
            userData['brain_health']['brainHealthScore'];
      } else {
        userData['brainHealthScore'] = 0;
      }

      // 성별 정보 처리
      if (!userData.containsKey('gender') || userData['gender'] == null) {
        userData['gender'] = 'unknown';
      }

      // 나이 정보 처리
      if (!userData.containsKey('age') || userData['age'] == null) {
        userData['age'] = 0;
      }

      // shortPW 정보 처리
      if (userData.containsKey('shortPW')) {
        userData['hasShortPW'] = true;
      } else {
        userData['hasShortPW'] = false;
      }

      return userData;
    } catch (e) {
      print('Error fetching current user: $e');
      return {
        'id': 'me',
        'nickname': 'Me',
        'country': 'un',
        'brainHealthScore': 0,
        'gender': 'unknown',
        'age': 0,
        'hasShortPW': false
      };
    }
  }

  // 사용자 shortPW 확인
  Future<String?> getUserShortPW(String userId) async {
    try {
      // Firebase에서 사용자 문서 가져오기
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      return userData['shortPW'] as String?;
    } catch (e) {
      print('Error fetching user shortPW: $e');
      return null;
    }
  }

  // 사용자 shortPW 설정
  Future<bool> setUserShortPW(String userId, String shortPW) async {
    try {
      // Firebase에 shortPW 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'shortPW': shortPW});
      return true;
    } catch (e) {
      print('Error setting user shortPW: $e');
      return false;
    }
  }

  // 사용자의 shortPW가 있는지 확인
  Future<bool> hasUserShortPW(String userId) async {
    String? shortPW = await getUserShortPW(userId);
    return shortPW != null && shortPW.isNotEmpty;
  }

  // 선택된 플레이어 추가
  void addSelectedPlayer(Map<String, dynamic> player) {
    if (!_selectedPlayers.any((p) => p['id'] == player['id'])) {
      _selectedPlayers.add(player);
      notifyListeners();

      // 리스너들에게 알림
      for (var listener in _playerChangeListeners) {
        listener(_selectedPlayers);
      }
    }
  }

  // 선택된 플레이어 제거
  void removeSelectedPlayer(String playerId) {
    _selectedPlayers.removeWhere((player) => player['id'] == playerId);
    notifyListeners();

    // 리스너들에게 알림
    for (var listener in _playerChangeListeners) {
      listener(_selectedPlayers);
    }
  }

  // 선택된 플레이어 목록 초기화
  void clearSelectedPlayers() {
    _selectedPlayers.clear();
    notifyListeners();

    // 리스너들에게 알림
    for (var listener in _playerChangeListeners) {
      listener(_selectedPlayers);
    }
  }
}
