import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BrainHealthProvider with ChangeNotifier {
  int _brainHealthScore = 0;
  int _totalGamesPlayed = 0;
  int _totalMatchesFound = 0;
  int _bestTime = 0; // 초 단위, 0은 아직 기록 없음을 의미

  int get brainHealthScore => _brainHealthScore;
  int get totalGamesPlayed => _totalGamesPlayed;
  int get totalMatchesFound => _totalMatchesFound;
  int get bestTime => _bestTime;

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

  BrainHealthProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;
        String emailPrefix = user.email!.split('@')[0];
        String documentId = '$emailPrefix$uid';

        // Firestore에서 데이터 가져오기
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(documentId)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data() as Map<String, dynamic>;
          _brainHealthScore = userData['brainHealthScore'] ?? 0;
          _totalGamesPlayed = userData['totalGamesPlayed'] ?? 0;
          _totalMatchesFound = userData['totalMatchesFound'] ?? 0;
          _bestTime = userData['bestTime'] ?? 0;
        }
      } else {
        // 로그인하지 않은 경우 로컬 저장소에서 가져오기
        final prefs = await SharedPreferences.getInstance();
        _brainHealthScore = prefs.getInt('brainHealthScore') ?? 0;
        _totalGamesPlayed = prefs.getInt('totalGamesPlayed') ?? 0;
        _totalMatchesFound = prefs.getInt('totalMatchesFound') ?? 0;
        _bestTime = prefs.getInt('bestTime') ?? 0;
      }
      notifyListeners();
    } catch (e) {
      print('Brain Health 데이터 로드 중 오류 발생: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;
        String emailPrefix = user.email!.split('@')[0];
        String documentId = '$emailPrefix$uid';

        // Firestore에 저장
        await FirebaseFirestore.instance
            .collection('users')
            .doc(documentId)
            .set({
          'brainHealthScore': _brainHealthScore,
          'totalGamesPlayed': _totalGamesPlayed,
          'totalMatchesFound': _totalMatchesFound,
          'bestTime': _bestTime,
        }, SetOptions(merge: true));
      }

      // 로컬에도 저장 (로그인 여부 관계없이)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('brainHealthScore', _brainHealthScore);
      await prefs.setInt('totalGamesPlayed', _totalGamesPlayed);
      await prefs.setInt('totalMatchesFound', _totalMatchesFound);
      await prefs.setInt('bestTime', _bestTime);
    } catch (e) {
      print('Brain Health 데이터 저장 중 오류 발생: $e');
    }
  }

  // 게임 완료 시 점수 추가
  Future<int> addGameCompletion(int matchesFound, int timeInSeconds) async {
    _totalGamesPlayed++;
    _totalMatchesFound += matchesFound;

    // 시간 기록 (더 빠른 시간만 저장)
    if (_bestTime == 0 || (timeInSeconds < _bestTime && timeInSeconds > 0)) {
      _bestTime = timeInSeconds;
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

    await _saveData();
    notifyListeners();

    return pointsEarned;
  }
}
