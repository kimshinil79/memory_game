import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flag/flag.dart';
import '../providers/brain_health_provider.dart';
import '../providers/language_provider.dart';

class UserRankingWidget extends StatelessWidget {
  final BrainHealthProvider provider;
  final double textScaleFactor;

  const UserRankingWidget({
    Key? key,
    required this.provider,
    required this.textScaleFactor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get translations from language provider
    final translations =
        Provider.of<LanguageProvider>(context).getUITranslations();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: provider.getUserRankings(),
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    translations['user_rankings'] ?? 'User Rankings',
                    style: GoogleFonts.notoSans(
                      fontSize: 20 * textScaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (snapshot.hasError)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      translations['failed_to_load_rankings'] ??
                          'Failed to load rankings',
                      style: GoogleFonts.notoSans(
                        fontSize: 16 * textScaleFactor,
                        color: Colors.red,
                      ),
                    ),
                  ),
                )
              else if (!snapshot.hasData || snapshot.data!.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      translations['no_ranking_data'] ??
                          'No ranking data available',
                      style: GoogleFonts.notoSans(
                        fontSize: 16 * textScaleFactor,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    // 랭킹 헤더
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 8.0),
                      child: Row(
                        children: [
                          SizedBox(
                              width: 40 * textScaleFactor,
                              child: Text(translations['rank'] ?? 'Rank',
                                  style: GoogleFonts.notoSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14 * textScaleFactor))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Text(translations['user'] ?? 'User',
                                style: GoogleFonts.notoSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14 * textScaleFactor)),
                          )),
                          // 뇌 이미지에 대한 설명 추가
                          InkWell(
                            onTap: () => _showBrainLevelInfo(context),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.help_outline,
                                color: Colors.purple,
                                size: 16 * textScaleFactor,
                              ),
                            ),
                          ),
                          SizedBox(
                              width: 80 * textScaleFactor,
                              child: Text(translations['score'] ?? 'Score',
                                  style: GoogleFonts.notoSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14 * textScaleFactor),
                                  textAlign: TextAlign.end)),
                        ],
                      ),
                    ),
                    const Divider(),
                    // 랭킹 목록을 Container로 감싸서 높이 제한
                    SizedBox(
                      height: 300, // 고정된 높이 설정
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final ranking = snapshot.data![index];
                          bool isCurrentUser =
                              ranking['isCurrentUser'] ?? false;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 8.0),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? Colors.blue.withOpacity(0.1)
                                  : null,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40 * textScaleFactor,
                                  child: Text(
                                    '#${ranking['rank']}',
                                    style: GoogleFonts.notoSans(
                                      fontWeight: isCurrentUser
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 14 * textScaleFactor,
                                      color: _getRankColor(ranking['rank']),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    children: [
                                      // 국가 국기 표시
                                      if (ranking['countryCode'] != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8.0),
                                          child: Builder(
                                            builder: (context) {
                                              try {
                                                return Flag.fromString(
                                                  ranking['countryCode']
                                                      .toString()
                                                      .toUpperCase(),
                                                  height: 16 * textScaleFactor,
                                                  width: 24 * textScaleFactor,
                                                  borderRadius: 4,
                                                );
                                              } catch (e) {
                                                // 오류 발생 시 간단한 컨테이너로 대체
                                                return Container(
                                                  height: 16 * textScaleFactor,
                                                  width: 24 * textScaleFactor,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      // 사용자 닉네임
                                      Expanded(
                                        child: Text(
                                          ranking['displayName'],
                                          style: GoogleFonts.notoSans(
                                            fontWeight: isCurrentUser
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 14 * textScaleFactor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      // Brain level icon
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 4.0, right: 4.0),
                                        child: Image.asset(
                                          'assets/icon/level${ranking['brainHealthIndexLevel'] ?? 1}_brain.png',
                                          width: 18 * textScaleFactor,
                                          height: 18 * textScaleFactor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 80 * textScaleFactor,
                                  child: Text(
                                    '${ranking['score']}',
                                    style: GoogleFonts.notoSans(
                                      fontWeight: isCurrentUser
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 14 * textScaleFactor,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  // 랭킹에 따른 색상 반환
  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber.shade700; // 금메달
    if (rank == 2) return Colors.blueGrey.shade400; // 은메달
    if (rank == 3) return Colors.brown.shade400; // 동메달
    return Colors.black87; // 기본 색상
  }

  void _showBrainLevelInfo(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 350;

    // 번역을 위한 LanguageProvider 사용
    final translations = Provider.of<LanguageProvider>(context, listen: false)
        .getUITranslations();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          elevation: 12,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.grey.shade50],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with improved styling
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.shade100.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.psychology,
                          color: Colors.purple.shade700,
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              translations['brain_level_guide'] ??
                                  'Brain Level Guide',
                              style: GoogleFonts.notoSans(
                                fontSize: isSmallScreen ? 18 : 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade800,
                              ),
                            ),
                            Text(
                              translations['understand_level_means'] ??
                                  'Understand what each level means',
                              style: GoogleFonts.notoSans(
                                fontSize: isSmallScreen ? 12 : 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.close,
                              color: Colors.grey.shade700,
                              size: isSmallScreen ? 18 : 20),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Divider with improved styling
                  Container(
                    height: 1,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade100, Colors.transparent],
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Scrollable content area
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildBrainLevelItemEnhanced(
                            context,
                            'assets/icon/level5_brain.png',
                            translations['rainbow_brain_level5'] ??
                                'Rainbow Brain (Level 5)',
                            translations['rainbow_brain_desc'] ??
                                'Your brain is sparkling with colorful brilliance!',
                            translations['rainbow_brain_fun'] ??
                                'You\'ve reached the cognitive equivalent of a double rainbow - absolutely dazzling!',
                            Colors.redAccent,
                            5,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 18),
                          _buildBrainLevelItemEnhanced(
                            context,
                            'assets/icon/level4_brain.png',
                            translations['gold_brain_level4'] ??
                                'Gold Brain (Level 4)',
                            translations['gold_brain_desc'] ??
                                'Excellent cognitive function and memory.',
                            translations['gold_brain_fun'] ??
                                'Almost superhuman memory - you probably remember where you left your keys!',
                            Colors.amber,
                            4,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 18),
                          _buildBrainLevelItemEnhanced(
                            context,
                            'assets/icon/level3_brain.png',
                            translations['silver_brain_level3'] ??
                                'Silver Brain (Level 3)',
                            translations['silver_brain_desc'] ??
                                'Good brain health with room for improvement.',
                            translations['silver_brain_fun'] ??
                                'Your brain is warming up - like a computer booting up in the morning.',
                            Colors.grey,
                            3,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 18),
                          _buildBrainLevelItemEnhanced(
                            context,
                            'assets/icon/level2_brain.png',
                            translations['bronze_brain_level2'] ??
                                'Bronze Brain (Level 2)',
                            translations['bronze_brain_desc'] ??
                                'Average cognitive function - more games needed!',
                            translations['bronze_brain_fun'] ??
                                'Your brain is a bit sleepy - time for some mental coffee!',
                            Colors.orangeAccent,
                            2,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 18),
                          _buildBrainLevelItemEnhanced(
                            context,
                            'assets/icon/level1_brain.png',
                            translations['poop_brain_level1'] ??
                                'Poop Brain (Level 1)',
                            translations['poop_brain_desc'] ??
                                'Just starting your brain health journey.',
                            translations['poop_brain_fun'] ??
                                'Your brain right now is like a smartphone at 1% battery - desperately needs charging!',
                            Colors.brown,
                            1,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Footer note
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.purple.shade400,
                          size: isSmallScreen ? 18 : 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            translations['keep_playing_memory_games'] ??
                                'Keep playing memory games to increase your brain level!',
                            style: GoogleFonts.notoSans(
                              fontSize: isSmallScreen ? 12 : 13,
                              color: Colors.purple.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrainLevelItemEnhanced(
    BuildContext context,
    String imagePath,
    String title,
    String description,
    String funComment,
    Color color,
    int level,
  ) {
    final isSmallScreen = MediaQuery.of(context).size.width < 350;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              imagePath,
              width: isSmallScreen ? 24 : 30,
              height: isSmallScreen ? 24 : 30,
            ),
          ),
          SizedBox(width: isSmallScreen ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSans(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  description,
                  style: GoogleFonts.notoSans(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withOpacity(0.1)),
                  ),
                  child: Text(
                    funComment,
                    style: GoogleFonts.notoSans(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
