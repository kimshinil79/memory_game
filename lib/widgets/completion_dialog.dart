import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CompletionDialog extends StatelessWidget {
  final int elapsedTime;
  final int flipCount;
  final int numberOfPlayers;
  final String winner;
  final bool isTimeAttackMode;
  final int finalPointsEarned;
  final int multiplier;
  final Color instagramGradientStart;
  final Color instagramGradientEnd;
  final VoidCallback onNewGame;
  final Map<String, String> translations;

  const CompletionDialog({
    super.key,
    required this.elapsedTime,
    required this.flipCount,
    required this.numberOfPlayers,
    required this.winner,
    required this.isTimeAttackMode,
    required this.finalPointsEarned,
    required this.multiplier,
    required this.instagramGradientStart,
    required this.instagramGradientEnd,
    required this.onNewGame,
    required this.translations,
  });

  @override
  Widget build(BuildContext context) {
    print('CompletionDialog build 메서드 호출됨');
    print('전달받은 번역 키 개수: ${translations.keys.length}');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85, // 화면 너비의 85%로 제한
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [instagramGradientStart, instagramGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          // 내용이 많을 경우 스크롤 가능하게 함
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  // 로컬 멀티플레이어일 경우 승자 표시, 싱글이면 "Congratulations!"
                  numberOfPlayers > 1
                      ? (winner != 'Tie' && winner.isNotEmpty
                          ? (translations['winner']
                                  ?.replaceAll('{name}', winner) ??
                              "Winner: $winner!")
                          : winner == 'Tie'
                              ? (translations['its_a_tie'] ?? "It's a Tie!")
                              : (translations['congratulations'] ??
                                  "Congratulations!"))
                      : (translations['congratulations'] ?? "Congratulations!"),
                  style: GoogleFonts.montserrat(
                    fontSize: 24, // 글씨 크기 조정
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              if (winner == 'Tie' && numberOfPlayers > 1)
                Text(
                  translations['points_divided'] ??
                      "Points are divided equally among tied players!",
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (winner == 'Tie' && numberOfPlayers > 1) const SizedBox(height: 8),
              if (isTimeAttackMode) ...[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    (translations['time_seconds'] ?? "Time: {seconds} seconds")
                        .replaceAll('{seconds}', elapsedTime.toString()),
                    style: GoogleFonts.montserrat(
                      fontSize: 18, // 글씨 크기 조정
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  (translations['flips'] ?? "Flips: {count}")
                      .replaceAll('{count}', flipCount.toString()),
                  style: GoogleFonts.montserrat(
                    fontSize: 18, // 글씨 크기 조정
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              // 로컬 멀티플레이어 점수 계산 설명 추가
              if (numberOfPlayers > 1) ...[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    winner == 'Tie'
                        ? (translations['points_divided_explanation'] ??
                            "(Points divided among tied players)")
                        : ((translations['players_score_multiplier'] ??
                                "({players} Players: Score x{multiplier})"))
                            .replaceAll('{players}', numberOfPlayers.toString())
                            .replaceAll('{multiplier}', multiplier.toString()),
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // 최종 획득 점수 표시 (Health Score)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    const Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 20,
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        // 최종 점수 표시
                        (translations['health_score'] ??
                                "Health Score: +{points}")
                            .replaceAll(
                                '{points}', finalPointsEarned.toString()),
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, // 버튼을 컨테이너 너비에 맞게 확장
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: instagramGradientStart,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: onNewGame,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      translations['new_game'] ?? "New Game",
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
}
