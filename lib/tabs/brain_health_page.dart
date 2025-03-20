import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/brain_health_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flag/flag.dart'; // 국기 표시용 패키지 import

class BrainHealthPage extends StatefulWidget {
  const BrainHealthPage({Key? key}) : super(key: key);

  @override
  State<BrainHealthPage> createState() => _BrainHealthPageState();
}

class _BrainHealthPageState extends State<BrainHealthPage> {
  bool _isRefreshing = false;

  // 튜토리얼 관련 변수
  bool _showTutorial = false;
  bool _doNotShowAgain = false;
  final String _tutorialPrefKey = 'brain_health_tutorial_shown';

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
  }

  // 튜토리얼 표시 여부 확인
  Future<void> _checkTutorialStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool tutorialShown = prefs.getBool(_tutorialPrefKey) ?? false;

    if (!tutorialShown) {
      setState(() {
        _showTutorial = true;
      });
    }
  }

  // 튜토리얼 표시 여부 저장
  Future<void> _saveTutorialPreference() async {
    if (_doNotShowAgain) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tutorialPrefKey, true);
    }
  }

  // 튜토리얼 닫기
  void _closeTutorial() {
    setState(() {
      _showTutorial = false;
    });
    _saveTutorialPreference();
  }

  Future<void> _refreshData(BuildContext context) async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await Provider.of<BrainHealthProvider>(context, listen: false)
          .refreshData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BrainHealthProvider>(
      builder: (context, brainHealthProvider, child) {
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => _refreshData(context),
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(brainHealthProvider),
                      SizedBox(height: 24),
                      _buildFightButton(),
                      SizedBox(height: 24),
                      _buildUserRankings(brainHealthProvider),
                      SizedBox(height: 32),
                      _buildActivityChart(brainHealthProvider),
                      SizedBox(height: 32),
                      _buildBrainHealthProgress(brainHealthProvider),
                      SizedBox(height: 32),
                      _buildInfoCards(brainHealthProvider),
                      SizedBox(height: 32),
                      _buildBenefitsSection(),
                      SizedBox(height: 80), // Extra space at bottom
                    ],
                  ),
                ),

                // Loading Indicator
                if (brainHealthProvider.isLoading || _isRefreshing)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text(
                                'Loading data...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Error message
                if (brainHealthProvider.error != null &&
                    !brainHealthProvider.isLoading &&
                    !_isRefreshing)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.red.shade400,
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              brainHealthProvider.error!,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh, color: Colors.white),
                            onPressed: () => _refreshData(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 튜토리얼 오버레이
                if (_showTutorial) _buildTutorialOverlay(),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _refreshData(context),
            tooltip: 'Refresh Data',
            child: Icon(Icons.refresh),
            backgroundColor: Colors.purple,
          ),
        );
      },
    );
  }

  Widget _buildHeader(BrainHealthProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Brain Health Dashboard',
          style: GoogleFonts.notoSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Play memory games to improve your brain health!',
          style: GoogleFonts.notoSans(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildBrainHealthProgress(BrainHealthProvider provider) {
    final percentage = provider.preventionPercentage / 100;
    final level = provider.preventionLevel;
    final pointsToNext = provider.pointsToNextLevel;

    // 레벨에 따른 색상 설정
    Color progressColor;
    switch (level) {
      case 1:
        progressColor = Colors.redAccent;
        break;
      case 2:
        progressColor = Colors.orangeAccent;
        break;
      case 3:
        progressColor = Colors.amber;
        break;
      case 4:
        progressColor = Colors.lightGreen;
        break;
      case 5:
        progressColor = Colors.green;
        break;
      default:
        progressColor = Colors.blue;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Brain Health Index',
              style: GoogleFonts.notoSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            CircularPercentIndicator(
              radius: 80.0,
              lineWidth: 15.0,
              animation: true,
              percent: percentage,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${provider.preventionPercentage.toStringAsFixed(1)}%',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Level $level',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: progressColor,
              backgroundColor: Colors.grey.shade200,
            ),
            SizedBox(height: 20),
            level < 5
                ? Text(
                    'You need $pointsToNext points to reach the next level',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Text(
                    'Maximum level reached',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
            SizedBox(height: 16),
            Text(
              'Total Brain Health Score: ${provider.brainHealthScore}',
              style: GoogleFonts.notoSans(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards(BrainHealthProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Game Statistics',
          style: GoogleFonts.notoSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.sports_esports,
                title: 'Games Played',
                value: '${provider.totalGamesPlayed}',
                color: Colors.blue,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.find_in_page,
                title: 'Matches Found',
                value: '${provider.totalMatchesFound}',
                color: Colors.purple,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildBestTimesCard(provider),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.leaderboard,
                title: 'Prevention Effect',
                value: '${provider.preventionPercentage.toStringAsFixed(1)}%',
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBestTimesCard(BrainHealthProvider provider) {
    // Get all recorded grid sizes
    final gridSizes = provider.bestTimesByGridSize.keys.toList();
    gridSizes.sort(); // Sort grid sizes for consistent display

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Best Times',
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (gridSizes.isEmpty)
              Text(
                'No records yet',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              )
            else
              Column(
                children: [
                  // Overall best time
                  if (provider.bestTime > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Overall Best:',
                            style: GoogleFonts.notoSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${provider.bestTime}s',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Divider(),
                  // Individual grid size best times
                  ...gridSizes.map((gridSize) {
                    final time = provider.bestTimesByGridSize[gridSize] ?? 0;
                    if (time <= 0)
                      return SizedBox.shrink(); // Skip if no record

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$gridSize Grid:',
                            style: GoogleFonts.notoSans(
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${time}s',
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Benefits of Brain Games',
          style: GoogleFonts.notoSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildBenefitItem(
                  icon: Icons.memory,
                  title: 'Short-term Memory Improvement',
                  description:
                      'Memory games effectively strengthen short-term memory and memory capacity.',
                ),
                Divider(),
                _buildBenefitItem(
                  icon: Icons.psychology,
                  title: 'Cognitive Function Enhancement',
                  description:
                      'Regular brain activity helps maintain and improve cognitive functions.',
                ),
                Divider(),
                _buildBenefitItem(
                  icon: Icons.timer,
                  title: 'Response Time Reduction',
                  description:
                      'Quick matching improves reaction time and processing speed.',
                ),
                Divider(),
                _buildBenefitItem(
                  icon: Icons.healing,
                  title: 'Dementia Prevention',
                  description:
                      'Regular brain exercises help reduce the risk of dementia and cognitive decline.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart(BrainHealthProvider provider) {
    final List<ScoreRecord> weeklyData = provider.getWeeklyData();
    final List<FlSpot> spots = [];

    // 데이터가 있는 경우에만 처리
    if (weeklyData.isNotEmpty) {
      for (int i = 0; i < weeklyData.length; i++) {
        spots.add(FlSpot(i.toDouble(), weeklyData[i].score.toDouble()));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Brain Health Progress',
              style: GoogleFonts.notoSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (weeklyData.isNotEmpty && weeklyData[0].score > 0)
              Text(
                _getDateRangeText(weeklyData),
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          height: 200,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: weeklyData.isEmpty || weeklyData[0].score == 0
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.psychology_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Welcome to Brain Health!',
                        style: GoogleFonts.notoSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start playing memory games\nto track your progress',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                )
              : LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < weeklyData.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _getShortDate(weeklyData[value.toInt()].date),
                                  style: GoogleFonts.notoSans(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              );
                            }
                            return Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 100,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: GoogleFonts.notoSans(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            );
                          },
                          reservedSize: 40,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (spots.length - 1).toDouble(),
                    minY: 0,
                    maxY: _calculateMaxY(weeklyData),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade300,
                            Colors.blue.shade500,
                          ],
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: Colors.blue.shade500,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade200.withOpacity(0.3),
                              Colors.blue.shade200.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // Y 축 최대값 계산
  double _calculateMaxY(List<ScoreRecord> data) {
    if (data.isEmpty) return 100;

    double maxScore = 0;
    for (var record in data) {
      if (record.score > maxScore) {
        maxScore = record.score.toDouble();
      }
    }

    // 최대값의 10% 여유 공간 추가
    return maxScore * 1.1;
  }

  // 사용자 랭킹 섹션 위젯
  Widget _buildUserRankings(BrainHealthProvider provider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: provider.getUserRankings(),
      builder: (context, snapshot) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Rankings',
                style: GoogleFonts.notoSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (snapshot.hasError)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Failed to load rankings',
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
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
                      'No ranking data available',
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
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
                              width: 40,
                              child: Text('Rank',
                                  style: GoogleFonts.notoSans(
                                      fontWeight: FontWeight.bold))),
                          SizedBox(width: 8),
                          Expanded(
                              child: Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Text('User',
                                style: GoogleFonts.notoSans(
                                    fontWeight: FontWeight.bold)),
                          )),
                          SizedBox(
                              width: 80,
                              child: Text('Score',
                                  style: GoogleFonts.notoSans(
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.end)),
                        ],
                      ),
                    ),
                    Divider(),
                    // 랭킹 목록
                    ...snapshot.data!.map((ranking) {
                      bool isCurrentUser = ranking['isCurrentUser'] ?? false;
                      return Container(
                        padding: EdgeInsets.symmetric(
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
                              width: 40,
                              child: Text(
                                '#${ranking['rank']}',
                                style: GoogleFonts.notoSans(
                                  fontWeight: isCurrentUser
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _getRankColor(ranking['rank']),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
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
                                              height: 16,
                                              width: 24,
                                              borderRadius: 4,
                                            );
                                          } catch (e) {
                                            // 오류 발생 시 간단한 컨테이너로 대체
                                            return Container(
                                              height: 16,
                                              width: 24,
                                              decoration: BoxDecoration(
                                                color: Colors.grey
                                                    .withOpacity(0.2),
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
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(
                                '${ranking['score']}',
                                style: GoogleFonts.notoSans(
                                  fontWeight: isCurrentUser
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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

  // 튜토리얼 오버레이 위젯
  Widget _buildTutorialOverlay() {
    final Color tutorialColor = Colors.purple.shade500;

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '브레인 헬스 대시보드',
                  style: GoogleFonts.notoSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: tutorialColor,
                  ),
                ),
                SizedBox(height: 20),
                _buildTutorialItem(
                  Icons.psychology,
                  '브레인 헬스 지수',
                  '메모리 게임을 통해 향상된 두뇌 건강 점수를 확인할 수 있습니다. 레벨이 올라갈수록 치매 예방 효과가 증가합니다.',
                  tutorialColor,
                ),
                SizedBox(height: 15),
                _buildTutorialItem(
                  Icons.bar_chart,
                  '활동 그래프',
                  '시간 경과에 따른 브레인 헬스 점수의 변화를 그래프로 확인할 수 있습니다.',
                  tutorialColor,
                ),
                SizedBox(height: 15),
                _buildTutorialItem(
                  Icons.emoji_events,
                  '랭킹 시스템',
                  '다른 사용자들과 브레인 헬스 점수를 비교하고 순위를 확인할 수 있습니다. 상위 랭킹에 도전해보세요!',
                  tutorialColor,
                ),
                SizedBox(height: 15),
                _buildTutorialItem(
                  Icons.assessment,
                  '게임 통계',
                  '플레이한 게임 수, 찾은, 매치 수, 최고 기록 등 다양한 통계를 확인할 수 있습니다.',
                  tutorialColor,
                ),
                SizedBox(height: 15),
                _buildTutorialItem(
                  Icons.refresh,
                  '데이터 새로고침',
                  '화면을 아래로 당기거나 새로고침 버튼을 눌러 데이터를 업데이트할 수 있습니다.',
                  tutorialColor,
                ),
                SizedBox(height: 25),
                Row(
                  children: [
                    Checkbox(
                      value: _doNotShowAgain,
                      onChanged: (value) {
                        setState(() {
                          _doNotShowAgain = value ?? false;
                        });
                      },
                      activeColor: tutorialColor,
                    ),
                    Text(
                      '다시 보지 않기',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _closeTutorial,
                  child: Text(
                    '확인했습니다',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tutorialColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
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

  // 튜토리얼 항목 위젯
  Widget _buildTutorialItem(
      IconData icon, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFightButton() {
    return Container(
      width: double.infinity,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showOpponentSelectionDialog(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_mma,
                  color: Colors.purple,
                  size: 32,
                ),
                SizedBox(width: 16),
                Text(
                  'Fight!',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOpponentSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // 선택된 사용자와 그리드 크기를 위한 변수
        String? selectedUser;
        String selectedGrid = '4x4'; // 기본 그리드 크기

        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: 500,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 대화상자 헤더
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Select Opponent',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 검색 텍스트 필드
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search users...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.purple),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 0, horizontal: 16),
                          ),
                          onChanged: (value) {
                            // 검색 기능 구현
                            // 실제 구현시 검색 로직 추가
                          },
                        ),

                        SizedBox(height: 16),

                        // 사용자 목록 레이블
                        Text(
                          'Registered Users',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 12),

                        // 사용자 목록
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: _getUsersList(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Failed to load users',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                );
                              }

                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Center(
                                  child: Text('No users available'),
                                );
                              }

                              return ListView.builder(
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  final user = snapshot.data![index];
                                  final isSelected =
                                      selectedUser == user['userId'];

                                  return ListTile(
                                    leading: user['countryCode'] != null
                                        ? Builder(
                                            builder: (context) {
                                              try {
                                                return Flag.fromString(
                                                  user['countryCode']
                                                      .toString()
                                                      .toUpperCase(),
                                                  height: 24,
                                                  width: 36,
                                                  borderRadius: 4,
                                                );
                                              } catch (e) {
                                                return Container(
                                                  height: 24,
                                                  width: 36,
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
                                          )
                                        : Icon(Icons.person),
                                    title: Text(
                                      user['displayName'] ?? 'Anonymous',
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Text('Score: ${user['score']}'),
                                    selected: isSelected,
                                    selectedTileColor:
                                        Colors.purple.withOpacity(0.1),
                                    onTap: () {
                                      setState(() {
                                        selectedUser = user['userId'];
                                      });
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        SizedBox(height: 24),

                        // 그리드 선택 레이블
                        Text(
                          'Select Grid Size',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 12),

                        // 그리드 선택 버튼들
                        Wrap(
                          spacing: 10,
                          children: [
                            _buildGridSizeButton('2x2', selectedGrid, (grid) {
                              setState(() => selectedGrid = grid);
                            }),
                            _buildGridSizeButton('3x3', selectedGrid, (grid) {
                              setState(() => selectedGrid = grid);
                            }),
                            _buildGridSizeButton('4x4', selectedGrid, (grid) {
                              setState(() => selectedGrid = grid);
                            }),
                            _buildGridSizeButton('5x5', selectedGrid, (grid) {
                              setState(() => selectedGrid = grid);
                            }),
                            _buildGridSizeButton('6x6', selectedGrid, (grid) {
                              setState(() => selectedGrid = grid);
                            }),
                          ],
                        ),

                        SizedBox(height: 24),

                        // 확인 버튼
                        Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: selectedUser == null
                                ? null
                                : () {
                                    Navigator.of(context).pop();
                                    // 실제 구현시 선택된 사용자와 게임 시작 로직 추가
                                    _startMultiplayerGame(
                                        selectedUser!, selectedGrid);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Fight!!',
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // 그리드 크기 선택 버튼 위젯
  Widget _buildGridSizeButton(
      String grid, String selectedGrid, Function(String) onSelect) {
    final isSelected = grid == selectedGrid;

    return GestureDetector(
      onTap: () => onSelect(grid),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Text(
          grid,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 사용자 목록을 가져오는 메서드 (실제 구현은 프로젝트에 맞게 수정 필요)
  Future<List<Map<String, dynamic>>> _getUsersList() async {
    // 여기서는 예시 데이터를 반환하지만, 실제로는 Firebase 또는 다른 데이터 소스에서 사용자 목록을 가져와야 함
    try {
      // Provider에서 유저 랭킹 데이터 가져오기 (임시 사용)
      final brainHealthProvider =
          Provider.of<BrainHealthProvider>(context, listen: false);
      return await brainHealthProvider.getUserRankings();
    } catch (e) {
      print('Error fetching users list: $e');
      return [];
    }
  }

  // 멀티플레이어 게임 시작 메서드 (실제 구현은 프로젝트에 맞게 수정 필요)
  void _startMultiplayerGame(String opponentId, String gridSize) {
    // 멀티플레이어 게임 시작 로직
    print(
        'Starting multiplayer game with opponent $opponentId on grid $gridSize');
    // 실제 구현시 게임 화면으로 이동하거나 게임 시작 로직 추가
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Multiplayer game will be implemented in the future!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 날짜 범위 텍스트 생성
  String _getDateRangeText(List<ScoreRecord> data) {
    if (data.isEmpty) return '';

    final firstDate = data.first.date;
    final lastDate = data.last.date;

    return '${_getShortDate(firstDate)} - ${_getShortDate(lastDate)}';
  }

  // 날짜를 간단한 형식으로 변환
  String _getShortDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
