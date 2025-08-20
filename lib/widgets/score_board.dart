import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flag/flag.dart';
import 'player_flag.dart';

class ScoreBoard extends StatelessWidget {
  final int numberOfPlayers;
  final Map<String, int> playerScores;
  final bool isMultiplayerMode;
  final String? myNickname;
  final String? opponentNickname;
  final bool isMyTurn;
  final bool isGameStarted;
  final int currentPlayerIndex;
  final List<Map<String, dynamic>> selectedPlayers;
  final Map<String, dynamic> currentUserInfo;
  final Color instagramGradientStart;
  final Color instagramGradientEnd;
  final Function(int)? onPlayerTap;
  final bool Function(int)? isSelectedAsStartingPlayer;

  const ScoreBoard({
    Key? key,
    required this.numberOfPlayers,
    required this.playerScores,
    required this.isMultiplayerMode,
    this.myNickname,
    this.opponentNickname,
    required this.isMyTurn,
    required this.isGameStarted,
    required this.currentPlayerIndex,
    required this.selectedPlayers,
    required this.currentUserInfo,
    required this.instagramGradientStart,
    required this.instagramGradientEnd,
    this.onPlayerTap,
    this.isSelectedAsStartingPlayer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              child: numberOfPlayers > 1
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: playerScores.entries
                          .take(numberOfPlayers)
                          .map((entry) {
                        // Determine player name based on position
                        String displayName = entry.key;
                        bool isCurrentPlayerTurn = false;
                        int playerIndex =
                            playerScores.keys.toList().indexOf(entry.key);
                        int score = 0;

                        if (isMultiplayerMode) {
                          // 멀티플레이어 모드에서는 실제 닉네임 표시
                          if (playerIndex == 0) {
                            displayName = myNickname ?? 'You';
                          } else {
                            displayName = opponentNickname ?? 'Opponent';
                          }

                          // 현재 턴 표시 (내 턴일 때와 상대방 턴일 때)
                          isCurrentPlayerTurn =
                              (playerIndex == 0 && isMyTurn) ||
                                  (playerIndex == 1 && !isMyTurn);

                          // 온라인 멀티플레이어 모드에서는 widget의 점수 사용
                          score = entry.value;

                          return Flexible(
                            flex: isCurrentPlayerTurn
                                ? 70
                                : 30 ~/ (playerScores.length - 1),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: isCurrentPlayerTurn
                                      ? 12
                                      : (numberOfPlayers == 2 ? 4 : 2),
                                  vertical: isCurrentPlayerTurn
                                      ? 6
                                      : (numberOfPlayers == 2 ? 2 : 1)),
                              margin: EdgeInsets.all(isCurrentPlayerTurn
                                  ? 3
                                  : (numberOfPlayers == 2 ? 2 : 1)),
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
                                              child: PlayerFlag(
                                                playerName: entry.key,
                                                playerScores: playerScores,
                                                currentUserInfo:
                                                    currentUserInfo,
                                                selectedPlayers:
                                                    selectedPlayers,
                                              ),
                                            ),
                                            SizedBox(width: 1),
                                            // 플레이어 수에 따라 이름 표시 방식 변경
                                            if (numberOfPlayers == 2) ...[
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
                                            ] else if (numberOfPlayers ==
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
                                                  fontSize: numberOfPlayers == 2
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
                          isCurrentPlayerTurn =
                              playerIndex == currentPlayerIndex;

                          // 닉네임 설정
                          if (playerIndex == 0) {
                            // 첫 번째 플레이어 - 현재 사용자 닉네임 사용
                            User? user = FirebaseAuth.instance.currentUser;
                            if (user != null &&
                                user.displayName != null &&
                                user.displayName!.isNotEmpty) {
                              displayName = user.displayName!;
                            } else {
                              displayName =
                                  currentUserInfo['nickname'] as String? ??
                                      'You';
                            }
                          } else {
                            // 다른 플레이어들 - 선택된 플레이어 닉네임 사용
                            if (playerIndex > 0 &&
                                playerIndex <= selectedPlayers.length) {
                              displayName = selectedPlayers[playerIndex - 1]
                                  ['nickname'] as String;
                            } else {
                              displayName = 'Player ${playerIndex + 1}';
                            }
                          }

                          // 점수는 entry.value 사용
                          score = entry.value;

                          return Flexible(
                            flex: isCurrentPlayerTurn
                                ? 70
                                : 30 ~/ (playerScores.length - 1),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: isCurrentPlayerTurn
                                      ? 1
                                      : (numberOfPlayers == 2 ? 2 : 0)),
                              child: GestureDetector(
                                onTap: () {
                                  if (onPlayerTap != null) {
                                    onPlayerTap!(playerIndex);
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: isCurrentPlayerTurn
                                          ? 2
                                          : (numberOfPlayers == 2 ? 2 : 0),
                                      vertical: isCurrentPlayerTurn
                                          ? 6
                                          : (numberOfPlayers == 2 ? 2 : 1)),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        isCurrentPlayerTurn ? 16 : 10),
                                    // 게임이 시작되지 않았을 때 선택된 시작 플레이어에 테두리 추가
                                    border: !isGameStarted &&
                                            isSelectedAsStartingPlayer !=
                                                null &&
                                            isSelectedAsStartingPlayer!(
                                                playerIndex)
                                        ? Border.all(
                                            color: instagramGradientStart,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: isCurrentPlayerTurn
                                      // 현재 차례 플레이어: 더 크게 표시
                                      ? Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                PlayerFlag(
                                                  playerName: entry.key,
                                                  playerScores: playerScores,
                                                  currentUserInfo:
                                                      currentUserInfo,
                                                  selectedPlayers:
                                                      selectedPlayers,
                                                ),
                                                SizedBox(width: 1),
                                                Flexible(
                                                  child: Text(
                                                    displayName, // 전체 닉네임 표시
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      color: Colors.blue[800],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                      letterSpacing: 0.5,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                                SizedBox(width: 1),
                                                Text(
                                                  "($score)",
                                                  style: GoogleFonts.montserrat(
                                                    color: Colors.black87,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                      // 대기 중인 플레이어: 훨씬 작게 표시
                                      : Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Transform.scale(
                                                  scale: 0.7,
                                                  child: PlayerFlag(
                                                    playerName: entry.key,
                                                    playerScores: playerScores,
                                                    currentUserInfo:
                                                        currentUserInfo,
                                                    selectedPlayers:
                                                        selectedPlayers,
                                                  ),
                                                ),
                                                SizedBox(width: 1),
                                                // 플레이어 수에 따라 이름 표시 방식 변경
                                                if (numberOfPlayers == 2) ...[
                                                  Flexible(
                                                    child: Text(
                                                      displayName,
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        color: Colors.blue[800],
                                                        fontSize: 10,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  SizedBox(width: 1),
                                                ] else if (numberOfPlayers ==
                                                    3) ...[
                                                  Flexible(
                                                    child: Text(
                                                      displayName,
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        color: Colors.blue[800],
                                                        fontSize: 8,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  SizedBox(width: 1),
                                                ] else if (numberOfPlayers ==
                                                    4) ...[
                                                  Flexible(
                                                    child: Text(
                                                      displayName,
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        color: Colors.blue[800],
                                                        fontSize: 7,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                  SizedBox(width: 1),
                                                ],
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 2,
                                                      vertical: 1),
                                                  child: Text(
                                                    '$score',
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: Colors.black87,
                                                      fontSize:
                                                          numberOfPlayers == 2
                                                              ? 9
                                                              : 7,
                                                    ),
                                                  ),
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
                      }).toList(),
                    )
                  : Container(), // If only 1 player, don't show any player names
            ),
          ),
        ],
      ),
    );
  }
}
