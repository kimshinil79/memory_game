import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flag/flag.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/brain_health_provider.dart';
import '../providers/language_provider.dart';

class UserRankingWidget extends StatefulWidget {
  final BrainHealthProvider provider;
  final double textScaleFactor;

  const UserRankingWidget({
    Key? key,
    required this.provider,
    required this.textScaleFactor,
  }) : super(key: key);

  @override
  State<UserRankingWidget> createState() => _UserRankingWidgetState();
}

class _UserRankingWidgetState extends State<UserRankingWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get translations from language provider
    final translations =
        Provider.of<LanguageProvider>(context).getUITranslations();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200.withOpacity(0.8),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더와 탭바 - 개선된 디자인
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade100, Colors.purple.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.leaderboard,
                  color: Colors.purple.shade700,
                  size: 20 * widget.textScaleFactor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translations['user_rankings'] ?? 'User Rankings',
                      style: GoogleFonts.notoSans(
                        fontSize: 20 * widget.textScaleFactor,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      translations['compete_with_others'] ??
                          'Compete with players worldwide',
                      style: GoogleFonts.notoSans(
                        fontSize: 12 * widget.textScaleFactor,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 탭바 추가 - 개선된 디자인
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  spreadRadius: 0,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade400,
                    Colors.purple.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              // 커스텀 탭에서 직접 스타일을 관리하므로 기본 스타일은 제거
              dividerColor: Colors.transparent,
              indicatorPadding: EdgeInsets.zero,
              tabs: [
                _buildAdaptiveTab(translations['total'] ?? '전체'),
                _buildAdaptiveTab(translations['weekly'] ?? '주간'),
                _buildAdaptiveTab(translations['monthly'] ?? '월간'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 탭 내용
          SizedBox(
            height: 350, // 고정된 높이 설정
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRankingContent('total', translations),
                _buildRankingContent('weekly', translations),
                _buildRankingContent('monthly', translations),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 동적으로 크기 조절되는 탭을 빌드하는 메서드
  Widget _buildAdaptiveTab(String text) {
    return Tab(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 탭의 최대 너비 계산 (패딩을 더 적게 고려하여 더 많은 공간 확보)
          final maxWidth = constraints.maxWidth - 8; // 좌우 패딩 4px씩으로 줄임

          // 기본 폰트 크기를 더 크게 설정
          double fontSize = 14 * widget.textScaleFactor;

          // 텍스트 크기 측정을 위한 임시 스타일
          TextStyle measureStyle = GoogleFonts.notoSans(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          );

          // 텍스트 크기 측정
          TextPainter textPainter = TextPainter(
            text: TextSpan(text: text, style: measureStyle),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();

          // 텍스트가 너무 길면 폰트 크기 줄이기 (최소 크기를 10px로 상향 조정)
          while (textPainter.width > maxWidth &&
              fontSize > 10 * widget.textScaleFactor) {
            fontSize -= 0.3 * widget.textScaleFactor; // 더 세밀한 조정
            measureStyle = GoogleFonts.notoSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: fontSize < 13 * widget.textScaleFactor
                  ? 0.0
                  : 0.2, // 레터 스페이싱 더 줄임
            );
            textPainter.text = TextSpan(text: text, style: measureStyle);
            textPainter.layout();
          }

          return Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                // 현재 탭의 인덱스 확인
                final currentIndex = _tabController.index;
                final tabIndex = _getTabIndex(text);
                final isSelected = currentIndex == tabIndex;

                // 선택 상태에 따른 색상 및 스타일 결정
                final color = isSelected ? Colors.white : Colors.grey.shade600;
                final fontWeight =
                    isSelected ? FontWeight.w600 : FontWeight.w500;

                return Text(
                  text,
                  style: GoogleFonts.notoSans(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    letterSpacing: fontSize < 13 * widget.textScaleFactor
                        ? 0.0
                        : 0.2, // 동일한 레터 스페이싱 적용
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                );
              },
            ),
          );
        },
      ),
    );
  }

  // 탭 텍스트로부터 인덱스를 구하는 헬퍼 메서드
  int _getTabIndex(String text) {
    final translations = Provider.of<LanguageProvider>(context, listen: false)
        .getUITranslations();
    if (text == (translations['total'] ?? '전체')) return 0;
    if (text == (translations['weekly'] ?? '주간')) return 1;
    if (text == (translations['monthly'] ?? '월간')) return 2;
    return 0;
  }

  // 랭킹 콘텐츠를 빌드하는 메서드
  Widget _buildRankingContent(String period, Map<String, String> translations) {
    // period에 따라 다른 데이터를 가져옵니다
    Future<List<Map<String, dynamic>>> future;

    switch (period) {
      case 'weekly':
        future = _getWeeklyRankings();
        break;
      case 'monthly':
        future = _getMonthlyRankings();
        break;
      case 'total':
      default:
        future = widget.provider.getUserRankings();
        break;
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                translations['failed_to_load_rankings'] ??
                    'Failed to load rankings',
                style: GoogleFonts.notoSans(
                  fontSize: 16 * widget.textScaleFactor,
                  color: Colors.red,
                ),
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                translations['no_ranking_data'] ?? 'No ranking data available',
                style: GoogleFonts.notoSans(
                  fontSize: 16 * widget.textScaleFactor,
                  color: Colors.black54,
                ),
              ),
            ),
          );
        } else {
          return Column(
            children: [
              // 랭킹 헤더
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    SizedBox(
                        width: 40 * widget.textScaleFactor,
                        child: Text(translations['rank'] ?? 'Rank',
                            style: GoogleFonts.notoSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 14 * widget.textScaleFactor))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(translations['user'] ?? 'User',
                          style: GoogleFonts.notoSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14 * widget.textScaleFactor)),
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
                          size: 16 * widget.textScaleFactor,
                        ),
                      ),
                    ),
                    SizedBox(
                        width: 80 * widget.textScaleFactor,
                        child: Text(translations['score'] ?? 'Score',
                            style: GoogleFonts.notoSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 14 * widget.textScaleFactor),
                            textAlign: TextAlign.end)),
                  ],
                ),
              ),
              const Divider(),
              // 랭킹 목록을 Container로 감싸서 높이 제한
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final ranking = snapshot.data![index];
                    bool isCurrentUser = ranking['isCurrentUser'] ?? false;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        color:
                            isCurrentUser ? Colors.blue.withOpacity(0.1) : null,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40 * widget.textScaleFactor,
                            child: Text(
                              '#${ranking['rank']}',
                              style: GoogleFonts.notoSans(
                                fontWeight: isCurrentUser
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14 * widget.textScaleFactor,
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
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Builder(
                                      builder: (context) {
                                        try {
                                          return Flag.fromString(
                                            ranking['countryCode']
                                                .toString()
                                                .toUpperCase(),
                                            height: 16 * widget.textScaleFactor,
                                            width: 24 * widget.textScaleFactor,
                                            borderRadius: 4,
                                          );
                                        } catch (e) {
                                          // 오류 발생 시 간단한 컨테이너로 대체
                                          return Container(
                                            height: 16 * widget.textScaleFactor,
                                            width: 24 * widget.textScaleFactor,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.grey.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
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
                                      fontSize: 14 * widget.textScaleFactor,
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
                                    width: 18 * widget.textScaleFactor,
                                    height: 18 * widget.textScaleFactor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 80 * widget.textScaleFactor,
                            child: Text(
                              '${ranking['score']}',
                              style: GoogleFonts.notoSans(
                                fontWeight: isCurrentUser
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14 * widget.textScaleFactor,
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
          );
        }
      },
    );
  }

  // 주간 랭킹 데이터를 가져오는 메서드
  Future<List<Map<String, dynamic>>> _getWeeklyRankings() async {
    try {
      final rankings = await widget.provider.getUserRankings();

      // 각 유저의 주간 점수를 계산
      final weeklyRankings = <Map<String, dynamic>>[];
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      for (final ranking in rankings) {
        final userId = ranking['userId'] as String?;
        if (userId == null) continue;

        // 해당 유저의 주간 점수 계산
        final weeklyScore =
            await _calculateUserWeeklyScore(userId, oneWeekAgo, now);

        final weeklyRanking = Map<String, dynamic>.from(ranking);
        weeklyRanking['score'] = weeklyScore;
        weeklyRankings.add(weeklyRanking);
      }

      // 주간 점수로 정렬
      weeklyRankings
          .sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      // 새로운 순위 부여
      for (int i = 0; i < weeklyRankings.length; i++) {
        weeklyRankings[i]['rank'] = i + 1;
      }

      return weeklyRankings;
    } catch (e) {
      print('Error getting weekly rankings: $e');
      return [];
    }
  }

  // 월간 랭킹 데이터를 가져오는 메서드
  Future<List<Map<String, dynamic>>> _getMonthlyRankings() async {
    try {
      final rankings = await widget.provider.getUserRankings();

      // 각 유저의 월간 점수를 계산
      final monthlyRankings = <Map<String, dynamic>>[];
      final now = DateTime.now();
      final oneMonthAgo = now.subtract(const Duration(days: 30));

      for (final ranking in rankings) {
        final userId = ranking['userId'] as String?;
        if (userId == null) continue;

        // 해당 유저의 월간 점수 계산
        final monthlyScore =
            await _calculateUserMonthlyScore(userId, oneMonthAgo, now);

        final monthlyRanking = Map<String, dynamic>.from(ranking);
        monthlyRanking['score'] = monthlyScore;
        monthlyRankings.add(monthlyRanking);
      }

      // 월간 점수로 정렬
      monthlyRankings
          .sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      // 새로운 순위 부여
      for (int i = 0; i < monthlyRankings.length; i++) {
        monthlyRankings[i]['rank'] = i + 1;
      }

      return monthlyRankings;
    } catch (e) {
      print('Error getting monthly rankings: $e');
      return [];
    }
  }

  // 특정 유저의 주간 점수를 계산 (기간 내 순증가치 기반)
  Future<int> _calculateUserWeeklyScore(
      String userId, DateTime startDate, DateTime endDate) async {
    return _calculateUserScoreDelta(userId, startDate, endDate);
  }

  // 특정 유저의 월간 점수를 계산 (기간 내 순증가치 기반)
  Future<int> _calculateUserMonthlyScore(
      String userId, DateTime startDate, DateTime endDate) async {
    return _calculateUserScoreDelta(userId, startDate, endDate);
  }

  // 기간 내 순증가치(Delta)를 계산: 누적 점수 스냅샷에서 종료값 - 시작값
  Future<int> _calculateUserScoreDelta(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return 0;

      final userData = userDoc.data() as Map<String, dynamic>;
      if (!userData.containsKey('brain_health') ||
          !(userData['brain_health'] is Map) ||
          !(userData['brain_health'] as Map).containsKey('scoreHistory')) {
        return 0;
      }

      final scoreHistoryMap =
          (userData['brain_health']['scoreHistory'] as Map<String, dynamic>);

      // 타임스탬프 오름차순 정렬된 리스트로 변환
      final entries = scoreHistoryMap.entries
          .map((e) {
            try {
              final ts = int.parse(e.key);
              return MapEntry<DateTime, int>(
                  DateTime.fromMillisecondsSinceEpoch(ts),
                  (e.value as num).toInt());
            } catch (_) {
              return null;
            }
          })
          .whereType<MapEntry<DateTime, int>>()
          .toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      if (entries.isEmpty) return 0;

      // 기간 내 엔트리들
      final inPeriod = entries
          .where((e) => !e.key.isBefore(startDate) && !e.key.isAfter(endDate))
          .toList();
      if (inPeriod.isEmpty) return 0;

      // 시작 기준값: 시작일 이전의 마지막 값이 있으면 그 값, 없으면 기간 내 첫 값
      int startBaseline;
      final beforeStart =
          entries.where((e) => e.key.isBefore(startDate)).toList();
      if (beforeStart.isNotEmpty) {
        startBaseline = beforeStart.last.value;
      } else {
        startBaseline = inPeriod.first.value;
      }

      // 종료값: 기간 내 마지막 값
      final endValue = inPeriod.last.value;

      final delta = endValue - startBaseline;
      return delta > 0 ? delta : 0;
    } catch (e) {
      print('Error calculating score delta for user $userId: $e');
      return 0;
    }
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
