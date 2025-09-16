import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 멀티플레이어 게임을 위한 Firebase 관련 기능을 담당하는 서비스 클래스
class FirebaseGameService {
  // Firebase 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 게임 상태 구독
  StreamSubscription<DocumentSnapshot>? _gameSubscription;

  // 멀티플레이어 게임 정보
  String? gameId;
  String? myPlayerId;
  String? opponentId;
  String? myNickname;
  String? opponentNickname;
  bool isMyTurn = false;
  String currentTurn = '';

  // 콜백 함수들
  Function(Map<String, dynamic>)? onGameStateChanged;
  Function(String)? onGameError;
  Function(int)? onFlipCountChanged;
  Function(String)? onCardWordSpoken;
  Function(int)? onCardAnimationTriggered;

  FirebaseGameService({
    this.onGameStateChanged,
    this.onGameError,
    this.onFlipCountChanged,
    this.onCardWordSpoken,
    this.onCardAnimationTriggered,
  });

  /// 멀티플레이어 게임 데이터 로드
  Future<void> loadMultiplayerData(String gameId, String myPlayerId) async {
    this.gameId = gameId;
    this.myPlayerId = myPlayerId;

    try {
      DocumentSnapshot gameDoc =
          await _firestore.collection('game_sessions').doc(gameId).get();

      if (!gameDoc.exists) {
        throw Exception('게임 세션을 찾을 수 없습니다');
      }

      Map<String, dynamic> gameData = gameDoc.data() as Map<String, dynamic>;

      // 게임 상태 구독 시작
      subscribeToGameState();

      // 사용자 정보 설정
      if (gameData.containsKey('player1') && gameData.containsKey('player2')) {
        Map<String, dynamic> player1 = gameData['player1'] ?? {};
        Map<String, dynamic> player2 = gameData['player2'] ?? {};

        String player1Id = player1['id'] ?? '';
        String player2Id = player2['id'] ?? '';

        // 상대방 ID 설정
        opponentId = player1Id == myPlayerId ? player2Id : player1Id;

        // 닉네임 설정
        myNickname = player1Id == myPlayerId
            ? player1['nickname'] ?? 'Player 1'
            : player2['nickname'] ?? 'Player 2';

        opponentNickname = player1Id == myPlayerId
            ? player2['nickname'] ?? 'Player 2'
            : player1['nickname'] ?? 'Player 1';

        // 현재 턴 설정
        currentTurn = gameData['currentTurn'] ?? player1Id;
        isMyTurn = currentTurn == myPlayerId;
      }
    } catch (e) {
      if (onGameError != null) {
        onGameError!('멀티플레이어 게임 데이터 로드 오류: $e');
      }
    }
  }

  /// Firestore에서 게임 상태 구독
  void subscribeToGameState() {
    if (gameId == null) {
      if (onGameError != null) {
        onGameError!('게임 상태 구독 불가: 게임 ID가 없음');
      }
      return;
    }

    // 기존 구독 취소
    _gameSubscription?.cancel();

    _gameSubscription = _firestore
        .collection('game_sessions')
        .doc(gameId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        Map<String, dynamic> gameData = snapshot.data() as Map<String, dynamic>;

        // UI 업데이트
        if (onGameStateChanged != null) {
          onGameStateChanged!(gameData);
        }
      } else {
        if (onGameError != null) {
          onGameError!('경고: 게임 데이터가 없거나 삭제됨');
        }
      }
    }, onError: (error) {
      if (onGameError != null) {
        onGameError!('게임 상태 구독 오류: $error');
      }

      // 오류 후 재연결 시도
      Future.delayed(const Duration(seconds: 5), () {
        subscribeToGameState();
      });
    });
  }

  /// 카드 탭 처리 - 멀티플레이어 모드
  Future<bool> onCardTap(int index, List<bool> cardFlips,
      List<int> selectedCards, List<String> gameImages, int flipCount) async {
    // 자신의 턴이 아니거나, 게임 ID가 없거나, 플레이어 ID가 없는 경우 처리 중단
    if (!isMyTurn || gameId == null || myPlayerId == null) {
      return false;
    }

    // 이미 뒤집힌 카드나, 이미 선택된 카드는 무시
    if (index >= cardFlips.length ||
        cardFlips[index] ||
        selectedCards.contains(index) ||
        selectedCards.length >= 2) {
      return false;
    }

    try {
      // 카드 상태 업데이트
      await updateCardStateInFirestore(index, true);

      // 플립 카운트 증가
      flipCount++;
      if (onFlipCountChanged != null) {
        onFlipCountChanged!(flipCount);
      }

      // 카드의 단어 발음
      if (index < gameImages.length && onCardWordSpoken != null) {
        onCardWordSpoken!(gameImages[index]);
      }

      // 두 개의 카드가 선택된 경우 매치 확인
      if (selectedCards.length == 2) {
        bool isMatch =
            gameImages[selectedCards[0]] == gameImages[selectedCards[1]];

        if (isMatch) {
          // 매치된 경우 애니메이션 트리거
          if (onCardAnimationTriggered != null) {
            onCardAnimationTriggered!(selectedCards[0]);
            onCardAnimationTriggered!(selectedCards[1]);
          }

          // Firebase에 매치 결과 업데이트
          await updateMatchInFirestore(true, selectedCards);
        } else {
          // 매치되지 않은 경우 처리
          await updateMatchInFirestore(false, selectedCards);
        }
      }

      return true;
    } catch (e) {
      if (onGameError != null) {
        onGameError!('카드 탭 처리 오류: $e');
      }
      return false;
    }
  }

  /// 카드 상태 업데이트
  Future<void> updateCardStateInFirestore(int index, bool isFlipped) async {
    if (gameId == null || myPlayerId == null) {
      return;
    }

    try {
      DocumentReference gameRef =
          _firestore.collection('game_sessions').doc(gameId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(gameRef);

        if (!snapshot.exists) {
          throw Exception('게임 세션이 존재하지 않습니다');
        }

        Map<String, dynamic> gameData = snapshot.data() as Map<String, dynamic>;
        List<dynamic> boardData = gameData['board'] ?? [];

        if (index < boardData.length) {
          Map<String, dynamic> cardData =
              boardData[index] as Map<String, dynamic>;
          cardData['isFlipped'] = isFlipped;
          cardData['lastFlippedBy'] = myPlayerId;
          boardData[index] = cardData;

          transaction.update(gameRef, {
            'board': boardData,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      if (onGameError != null) {
        onGameError!('Firestore 카드 상태 업데이트 오류: $e');
      }
    }
  }

  /// Firestore에 매치 결과 업데이트
  Future<void> updateMatchInFirestore(
      bool isMatch, List<int> selectedCards) async {
    if (gameId == null || myPlayerId == null || !isMyTurn) {
      return;
    }

    try {
      DocumentReference gameRef =
          _firestore.collection('game_sessions').doc(gameId);

      // 트랜잭션 사용하여 업데이트
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(gameRef);

        if (!snapshot.exists) {
          throw Exception('게임 세션이 존재하지 않습니다');
        }

        Map<String, dynamic> gameData = snapshot.data() as Map<String, dynamic>;
        List<dynamic> boardData = gameData['board'] ?? [];

        // 보드 업데이트
        for (int index in selectedCards) {
          if (index < boardData.length) {
            Map<String, dynamic> cardData =
                boardData[index] as Map<String, dynamic>;
            cardData['isFlipped'] = true;

            if (isMatch) {
              cardData['matchedBy'] = myPlayerId;
            }

            cardData['lastFlippedBy'] = myPlayerId;
            boardData[index] = cardData;
          }
        }

        // 매치 여부에 따라 다음 턴 결정
        String nextTurn = isMatch ? myPlayerId! : opponentId!;

        // 최근 액션 업데이트
        Map<String, dynamic> lastAction = {
          'type': isMatch ? 'match' : 'mismatch',
          'playerId': myPlayerId,
          'cards': selectedCards,
          'timestamp': FieldValue.serverTimestamp(),
        };

        // 점수 업데이트
        if (isMatch) {
          // 내 점수 증가
          if (gameData.containsKey('player1') &&
              gameData['player1']['id'] == myPlayerId) {
            transaction.update(gameRef, {
              'player1.score': FieldValue.increment(1),
            });
          } else if (gameData.containsKey('player2') &&
              gameData['player2']['id'] == myPlayerId) {
            transaction.update(gameRef, {
              'player2.score': FieldValue.increment(1),
            });
          }
        }

        // 보드, 턴, 액션 업데이트
        transaction.update(gameRef, {
          'board': boardData,
          'currentTurn': nextTurn,
          'lastAction': lastAction,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        // 게임 완료 여부 확인
        bool allMatched = boardData.every((card) {
          return (card as Map<String, dynamic>)['matchedBy'] != null;
        });

        if (allMatched) {
          // 게임 종료 처리
          transaction.update(gameRef, {
            'gameState': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      if (onGameError != null) {
        onGameError!('Firestore 업데이트 오류: $e');
      }
    }
  }

  /// 새 멀티플레이어 게임 세션 생성
  Future<String?> createGameSession(
      String opponentId, String gridSize, String opponentNickname) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 현재 사용자 정보 가져오기
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      String senderNickname = 'Unknown Player';
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        senderNickname = userData['nickname'] ??
            (currentUser.displayName ??
                currentUser.email?.split('@')[0] ??
                'Unknown Player');
      }

      // 게임 ID 생성
      DocumentReference gameRef = _firestore.collection('game_sessions').doc();
      String newGameId = gameRef.id;

      // 기본 게임 이미지 목록 생성
      List<Map<String, dynamic>> boardData = [];
      List<int> dimensions =
          gridSize.split('x').map((e) => int.parse(e)).toList();
      int columns = dimensions[0]; // 첫 번째 숫자는 열(column) 수
      int rows = dimensions[1]; // 두 번째 숫자는 행(row) 수
      int totalCards = rows * columns;

      // 이미지 ID 준비
      List<String> imageIds = [];
      for (int i = 1; i <= (totalCards ~/ 2); i++) {
        imageIds.add('img_$i');
        imageIds.add('img_$i');
      }

      // 이미지 섞기
      imageIds.shuffle();

      // 보드 데이터 생성
      for (int i = 0; i < totalCards; i++) {
        boardData.add({
          'imageId': i < imageIds.length ? imageIds[i] : 'default',
          'isFlipped': false,
          'matchedBy': null,
          'lastFlippedBy': null,
        });
      }

      // 게임 세션 데이터 생성
      await gameRef.set({
        'player1': {
          'id': currentUser.uid,
          'nickname': senderNickname,
          'score': 0,
        },
        'player2': {
          'id': opponentId,
          'nickname': opponentNickname,
          'score': 0,
        },
        'gridSize': gridSize,
        'currentTurn': currentUser.uid,
        'gameState': 'waiting', // waiting, started, completed
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'board': boardData,
      });

      return newGameId;
    } catch (e) {
      if (onGameError != null) {
        onGameError!('게임 세션 생성 오류: $e');
      }
      return null;
    }
  }

  /// 구독 해제
  void dispose() {
    _gameSubscription?.cancel();
  }
}
