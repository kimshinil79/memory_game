import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/brain_health_provider.dart';

class BrainHealthPage extends StatefulWidget {
  const BrainHealthPage({Key? key}) : super(key: key);

  @override
  State<BrainHealthPage> createState() => _BrainHealthPageState();
}

class _BrainHealthPageState extends State<BrainHealthPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<BrainHealthProvider>(
      builder: (context, brainHealthProvider, child) {
        return Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(brainHealthProvider),
                SizedBox(height: 24),
                _buildBrainHealthProgress(brainHealthProvider),
                SizedBox(height: 32),
                _buildInfoCards(brainHealthProvider),
                SizedBox(height: 32),
                _buildBenefitsSection(),
                SizedBox(height: 32),
                _buildActivityChart(brainHealthProvider),
              ],
            ),
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
          '두뇌 건강 대시보드',
          style: GoogleFonts.notoSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '메모리 게임을 플레이하여 두뇌 건강을 향상시키세요!',
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
              '두뇌 건강 지수',
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
                    '레벨 $level',
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
                    '다음 레벨까지 $pointsToNext 포인트 필요',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Text(
                    '최고 레벨 달성! 계속 유지하세요',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                  ),
            SizedBox(height: 16),
            Text(
              '총 Brain Health 점수: ${provider.brainHealthScore}',
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
          '게임 통계',
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
                title: '게임 수',
                value: '${provider.totalGamesPlayed}',
                color: Colors.blue,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.find_in_page,
                title: '찾은 매치',
                value: '${provider.totalMatchesFound}',
                color: Colors.purple,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.speed,
                title: '최고 시간',
                value:
                    provider.bestTime > 0 ? '${provider.bestTime}초' : '기록 없음',
                color: Colors.orange,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.leaderboard,
                title: '예방 효과',
                value: '${provider.preventionPercentage.toStringAsFixed(1)}%',
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
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
          '두뇌 게임의 이점',
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
                  title: '단기 기억력 향상',
                  description: '메모리 게임은 단기 기억력과 기억 용량을 효과적으로 강화시킵니다.',
                ),
                Divider(),
                _buildBenefitItem(
                  icon: Icons.psychology,
                  title: '인지 기능 개선',
                  description: '규칙적인 두뇌 활동은 인지 기능을 유지하고 개선하는 데 도움을 줍니다.',
                ),
                Divider(),
                _buildBenefitItem(
                  icon: Icons.timer,
                  title: '반응 시간 단축',
                  description: '빠른 매칭은 반응 시간과 처리 속도를 향상시킵니다.',
                ),
                Divider(),
                _buildBenefitItem(
                  icon: Icons.healing,
                  title: '치매 예방',
                  description: '정기적인 두뇌 운동은 치매 및 인지 감퇴의 위험을 줄이는 데 도움이 됩니다.',
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
    // 더미 데이터 - 실제 앱에서는 이 부분을 사용자의 활동 데이터로 대체
    final List<FlSpot> spots = [
      FlSpot(0, 0),
      FlSpot(1, provider.brainHealthScore * 0.2),
      FlSpot(2, provider.brainHealthScore * 0.4),
      FlSpot(3, provider.brainHealthScore * 0.5),
      FlSpot(4, provider.brainHealthScore * 0.7),
      FlSpot(5, provider.brainHealthScore * 0.8),
      FlSpot(6, provider.brainHealthScore.toDouble()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '두뇌 건강 진행도',
          style: GoogleFonts.notoSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
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
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 50,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      const titles = ['시작', '1주', '2주', '3주', '4주', '5주', '현재'];
                      if (value >= 0 && value < titles.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            titles[value.toInt()],
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
              borderData: FlBorderData(
                show: false,
              ),
              minX: 0,
              maxX: 6,
              minY: 0,
              maxY: provider.brainHealthScore * 1.2 > 0
                  ? provider.brainHealthScore * 1.2
                  : 100,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.7),
                      Colors.purpleAccent.withOpacity(0.7),
                    ],
                  ),
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: Colors.purpleAccent,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.3),
                        Colors.purpleAccent.withOpacity(0.1),
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
}
