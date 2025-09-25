import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';

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
  final int basePoints;
  final int streakBonus;
  final int currentStreak;

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
    this.basePoints = 0,
    this.streakBonus = 0,
    this.currentStreak = 0,
  });

  // 홍보 메시지 키 리스트
  static const List<String> _promotionalMessageKeys = [
    'promo_message_1',
    'promo_message_2',
    'promo_message_3',
    'promo_message_4',
    'promo_message_5',
    'promo_message_6',
    'promo_message_7',
    'promo_message_8',
    'promo_message_9',
    'promo_message_10',
  ];

  // 구글 플레이 스토어 링크
  static const String _playStoreLink = 'https://play.google.com/store/apps/details?id=com.brainhealth.memorygame&pcampaignid=web_share';

  @override
  Widget build(BuildContext context) {
    print('CompletionDialog build 메서드 호출됨');
    print('전달받은 번역 키 개수: ${translations.keys.length}');

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: screenWidth * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Stack(
          children: [
            // 메인 카드
            Container(
              margin: const EdgeInsets.only(top: 40),
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 타이틀
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Builder(
                        builder: (context) {
                          String titleText = numberOfPlayers > 1
                              ? (winner != 'Tie' && winner.isNotEmpty
                                  ? (translations['winner']
                                          ?.replaceAll('{name}', winner) ??
                                      "Winner: $winner!")
                                  : winner == 'Tie'
                                      ? (translations['its_a_tie'] ??
                                          "It's a Tie!")
                                      : (translations['congratulations'] ??
                                          "Congratulations!"))
                              : (translations['congratulations'] ??
                                  "Congratulations!");

                          return Text(
                            titleText,
                            style: GoogleFonts.poppins(
                              fontSize: _getDynamicFontSize(
                                  titleText, isSmallScreen ? 20 : 24, 16, 28),
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D3748),
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 게임 통계 카드들 (미니멀)
                    Row(
                      children: [
                        Expanded(
                          child: _buildMinimalStatCard(
                            icon: Icons.schedule,
                            label: translations['time'] ?? "Time",
                            value: "${elapsedTime}s",
                            color: const Color(0xFF4299E1),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildMinimalStatCard(
                            icon: Icons.flip_camera_android,
                            label: translations['flips'] ?? "Flips",
                            value: flipCount.toString(),
                            color: const Color(0xFF48BB78),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 점수 분해 표시 (컴팩트)
                    _buildCompactScoreBreakdown(),

                    const SizedBox(height: 20),

                    // 버튼
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            instagramGradientStart,
                            instagramGradientEnd
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: instagramGradientStart.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: onNewGame,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            translations['new_game'] ?? "New Game",
                            style: GoogleFonts.poppins(
                              fontSize: _getDynamicFontSize(
                                  translations['new_game'] ?? "New Game",
                                  16,
                                  14,
                                  18),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    // 홍보성 글과 복사하기 버튼
                    _buildPromotionalSection(),
                  ],
                ),
              ),
            ),

            // 상단 트로피/성공 아이콘
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [instagramGradientStart, instagramGradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: instagramGradientStart.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: _getDynamicFontSize(label, 10, 8, 12),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF718096),
              ),
            ),
          ),
          const SizedBox(width: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: _getDynamicFontSize(value, 14, 12, 16),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 텍스트 길이에 따른 동적 폰트 크기 계산
  double _getDynamicFontSize(
      String text, double baseSize, double minSize, double maxSize) {
    // 한글, 중국어, 일본어 등 동아시아 문자 감지
    bool hasEastAsianChars =
        RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF\uAC00-\uD7AF]')
            .hasMatch(text);

    // 아랍어, 히브리어 등 RTL 문자 감지
    bool hasRTLChars = RegExp(
            r'[\u0590-\u05FF\u0600-\u06FF\u0750-\u077F\uFB1D-\uFDFF\uFE70-\uFEFF]')
        .hasMatch(text);

    // 독일어, 러시아어 등 긴 단어가 많은 언어 감지
    bool hasLongWords = text.split(' ').any((word) => word.length > 15);

    double adjustedSize = baseSize;

    if (hasEastAsianChars) {
      // 동아시아 문자는 기본 크기 유지하되 약간 작게
      adjustedSize = baseSize * 0.9;
    } else if (hasRTLChars) {
      // RTL 문자는 더 작게
      adjustedSize = baseSize * 0.85;
    } else if (hasLongWords) {
      // 긴 단어가 있으면 작게
      adjustedSize = baseSize * 0.8;
    } else {
      // 영어 기준으로 길이에 따라 조정
      if (text.length > 15) {
        adjustedSize = baseSize * 0.8;
      } else if (text.length > 10) {
        adjustedSize = baseSize * 0.9;
      } else if (text.length < 5) {
        adjustedSize = baseSize * 1.1;
      }
    }

    // 최소/최대 크기 제한
    return adjustedSize.clamp(minSize, maxSize);
  }

  Widget _buildCompactScoreBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667EEA).withOpacity(0.1),
            const Color(0xFF764BA2).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF667EEA).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [

          // 기본 점수
          if (basePoints > 0)
            _buildCompactScoreRow(
              label: translations['base_score'] ?? "Base Score",
              value: "+$basePoints",
              color: const Color(0xFF48BB78),
            ),

          // 멀티플레이어 보너스
          if (numberOfPlayers > 1 && multiplier > 1)
            _buildCompactScoreRow(
              label: "${numberOfPlayers}P Bonus (x$multiplier)",
              value: "+${(basePoints * (multiplier - 1))}",
              color: const Color(0xFF4299E1),
            ),

          // 스트릭 보너스
          if (currentStreak > 1 && streakBonus > 0) ...[
            _buildCompactScoreRow(
              label: "$currentStreak ${translations['streak_bonus'] ?? 'Streak Bonus'} 🔥",
              value: "+$streakBonus",
              color: const Color(0xFFED8936),
              isHighlight: true,
            ),
          ],

          // 구분선
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),

          // 총합
          _buildCompactScoreRow(
            label: translations['total_earned'] ?? "Total Earned",
            value: "+$finalPointsEarned",
            color: const Color(0xFF667EEA),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactScoreRow({
    required String label,
    required String value,
    required Color color,
    bool isBold = false,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: _getDynamicFontSize(label, isBold ? 13 : 12,
                      isBold ? 10 : 9, isBold ? 15 : 14),
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
                  color: isHighlight ? color : const Color(0xFF4A5568),
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            flex: 1,
            child: Container(
              padding: isHighlight
                  ? const EdgeInsets.symmetric(horizontal: 6, vertical: 1)
                  : EdgeInsets.zero,
              decoration: isHighlight
                  ? BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    )
                  : null,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: _getDynamicFontSize(value, isBold ? 15 : 13,
                        isBold ? 12 : 11, isBold ? 17 : 15),
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionalSection() {
    // 랜덤으로 홍보 메시지 선택
    final random = Random();
    final selectedKey = _promotionalMessageKeys[random.nextInt(_promotionalMessageKeys.length)];
    final selectedMessage = translations[selectedKey] ?? selectedKey;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 홍보 메시지 (더 크게)
          Text(
            selectedMessage,
            style: GoogleFonts.poppins(
              fontSize: _getDynamicFontSize(selectedMessage, 15, 13, 17),
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4A5568),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          // SNS 공유 버튼
          GestureDetector(
            onTap: () => _shareToSNS(selectedMessage),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF667EEA), // 인스타그램 그라데이션과 맞춤
                    const Color(0xFF764BA2),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 공유 아이콘
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.share,
                      color: Color(0xFF667EEA),
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '공유하기',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareToSNS(String message) async {
    final shareText = '$message\n\n🧠 Brain Health Memory Game - 두뇌 건강을 위한 메모리 게임!\n구글 플레이 스토어에서 다운로드: $_playStoreLink';
    
    try {
      await Share.share(
        shareText,
        subject: 'Brain Health Memory Game - 두뇌 건강 게임',
      );
    } catch (e) {
      print('공유 기능을 사용할 수 없습니다: $e');
    }
  }
}
