import 'package:flutter/material.dart';
import '../services/memory_game_service.dart';
import 'player_selection_dialog.dart';

class PlayerSelectionHandler {
  static Future<void> showPlayerSelectionDialog({
    required BuildContext context,
    required MemoryGameService memoryGameService,
    required Function(int) updateNumberOfPlayers,
    required Function(List<String>) updatePlayers,
    required Function(Map<String, int>) updatePlayerScores,
    required Function(int) updateCurrentPlayerIndex,
    required Function(List<Map<String, dynamic>>) updateSelectedPlayerData,
    required Function() rebuildMemoryGamePage,
  }) async {
    final selectedPlayers =
        await PlayerSelectionDialog.show(context, memoryGameService);

    // 선택된 플레이어를 서비스에 직접 설정 (이중 설정이지만 안전하게)
    memoryGameService.selectedPlayers = selectedPlayers ?? [];
  
    try {
      // 현재 사용자 정보 가져오기
      Map<String, dynamic> currentUserInfo =
          await memoryGameService.getCurrentUserInfo();

      print('플레이어 선택 대화상자 결과: ${selectedPlayers.length}명 선택됨');

      // 유저 수 설정 (본인 포함)
      int numberOfPlayers = selectedPlayers.length + 1;

      // 선택된 유저 정보 저장
      updateSelectedPlayerData(selectedPlayers);

      // 플레이어 이름 리스트 업데이트 (본인 포함)
      List<String> players = [currentUserInfo['nickname']];
      for (var player in selectedPlayers) {
        players.add(player['nickname'] as String);
      }

      // 총 플레이어 수 로그
      print('총 플레이어 수: $numberOfPlayers (본인 포함)');
      print('플레이어 목록: $players');
      print('현재 사용자 정보: $currentUserInfo');
      print('선택된 플레이어 정보:');
      for (var player in selectedPlayers) {
        print(
            '- ${player['nickname']} (국가: ${player['country']}, 성별: ${player['gender']}, 나이: ${player['age']}, 점수: ${player['brainHealthScore']})');
      }

      // 점수 초기화
      Map<String, int> playerScores = {};
      for (var playerName in players) {
        playerScores[playerName] = 0;
      }

      // 상태 업데이트
      updateNumberOfPlayers(numberOfPlayers);
      updatePlayers(players);
      updatePlayerScores(playerScores);
      updateCurrentPlayerIndex(0);

      // 게임 페이지 업데이트
      rebuildMemoryGamePage();

      // 플레이어가 변경되었음을 사용자에게 알림
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   content: Text('플레이어가 변경되어 새 게임이 시작됩니다'),
      //   duration: Duration(seconds: 2),
      //   backgroundColor: Colors.green,
      // ));
    } catch (e) {
      print('플레이어 정보 설정 중 오류 발생: $e');
      // ScaffoldMessenger.of(context)
      //     .showSnackBar(SnackBar(content: Text('플레이어 정보 설정 중 오류가 발생했습니다.')));
    }
    }
}
