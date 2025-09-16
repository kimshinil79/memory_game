import 'package:flutter/material.dart';
import 'package:flag/flag.dart';

class PlayerFlag extends StatelessWidget {
  final String playerName;
  final Map<String, int> playerScores;
  final Map<String, dynamic> currentUserInfo;
  final List<Map<String, dynamic>> selectedPlayers;
  final double height;
  final double width;
  final double borderRadius;
  final FlagSize flagSize;
  final BoxFit fit;

  const PlayerFlag({
    super.key,
    required this.playerName,
    required this.playerScores,
    required this.currentUserInfo,
    required this.selectedPlayers,
    this.height = 16,
    this.width = 24,
    this.borderRadius = 2,
    this.flagSize = FlagSize.size_4x3,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    String countryCode = 'un'; // 기본값으로 UN 국가 코드 사용

    // 첫 번째 플레이어(현재 사용자)인 경우
    if (playerScores.keys.toList().indexOf(playerName) == 0) {
      countryCode = currentUserInfo['country'] as String? ?? 'un';
      print('플레이어 국기: $playerName(나) - 국가코드: $countryCode');
    }
    // 다른 플레이어인 경우
    else {
      int playerIndex = playerScores.keys.toList().indexOf(playerName) - 1;
      if (playerIndex >= 0 && playerIndex < selectedPlayers.length) {
        countryCode =
            selectedPlayers[playerIndex]['country'] as String? ?? 'un';
        print(
            '플레이어 국기: $playerName - 국가코드: $countryCode (selectedPlayers[$playerIndex])');
      } else {
        print(
            '플레이어 국기 오류: $playerName - 인덱스 범위 초과 ($playerIndex vs ${selectedPlayers.length})');
      }
    }

    // 소문자로 된 국가 코드를 대문자로 변환
    countryCode = countryCode.toUpperCase();

    return Flag.fromString(
      countryCode,
      height: height,
      width: width,
      borderRadius: borderRadius,
      flagSize: flagSize,
      fit: fit,
    );
  }
}
