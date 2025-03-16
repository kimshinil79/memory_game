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
  bool _isRefreshing = false;

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
                      _buildActivityChart(brainHealthProvider),
                      SizedBox(height: 32),
                      _buildBrainHealthProgress(brainHealthProvider),
                      SizedBox(height: 32),
                      _buildUserRankings(brainHealthProvider),
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
                    'Highest level achieved! Keep it up',
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
    // 원본 데이터 가져오기
    List<ScoreRecord> originalData = provider.getWeeklyData();

    // 처리된 데이터를 저장할 리스트
    List<ScoreRecord> processedData = [];

    if (originalData.isNotEmpty) {
      // 오늘 날짜 구하기
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 날짜별 최고 점수를 저장할 맵 (오늘 제외)
      Map<String, ScoreRecord> highestScoreByDay = {};

      // 오늘 데이터 따로 저장
      List<ScoreRecord> todayData = [];

      // 데이터 분류
      for (var record in originalData) {
        final recordDate =
            DateTime(record.date.year, record.date.month, record.date.day);

        // 오늘 데이터인지 확인
        if (recordDate == today) {
          todayData.add(record);
        } else {
          // 지난 날짜의 경우, 날짜별 최고 점수만 저장
          String dateKey =
              '${recordDate.year}-${recordDate.month}-${recordDate.day}';

          if (!highestScoreByDay.containsKey(dateKey) ||
              record.score > highestScoreByDay[dateKey]!.score) {
            highestScoreByDay[dateKey] = record;
          }
        }
      }

      // 지난 날짜의 최고 점수들을 날짜순으로 정렬
      List<ScoreRecord> pastDaysData = highestScoreByDay.values.toList();
      pastDaysData.sort((a, b) => a.date.compareTo(b.date));

      // 오늘 데이터를 시간순으로 정렬
      todayData.sort((a, b) => a.date.compareTo(b.date));

      // 최종 처리된 데이터 생성 (지난 날짜 + 오늘)
      processedData = [...pastDaysData, ...todayData];
    }

    // 그래프 데이터 포인트 생성
    final List<FlSpot> spots = [];
    for (int i = 0; i < processedData.length; i++) {
      spots.add(FlSpot(i.toDouble(), processedData[i].score.toDouble()));
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
            if (processedData.isNotEmpty)
              Text(
                _getDateRangeText(processedData),
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
          child: processedData.isEmpty
              ? Center(
                  child: Text(
                    'No data available yet',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                )
              : LineChart(
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
                          reservedSize: 40,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            // 날짜 기반 X축 라벨 생성
                            if (value.toInt() >= 0 &&
                                value.toInt() < processedData.length) {
                              final record = processedData[value.toInt()];
                              final date = record.date;
                              final now = DateTime.now();
                              final today =
                                  DateTime(now.year, now.month, now.day);
                              final recordDate =
                                  DateTime(date.year, date.month, date.day);
                              String label;

                              // 오늘 데이터인 경우 시간 표시
                              if (recordDate == today) {
                                // 시간 포맷 (오전/오후 구분)
                                final hour = date.hour;
                                final minute =
                                    date.minute.toString().padLeft(2, '0');
                                if (hour == 0) {
                                  label = '12:$minute AM';
                                } else if (hour < 12) {
                                  label = '$hour:$minute AM';
                                } else if (hour == 12) {
                                  label = '12:$minute PM';
                                } else {
                                  label = '${hour - 12}:$minute PM';
                                }
                              } else {
                                // 지난 날짜는 날짜만 표시
                                label = _formatDate(date);
                              }

                              // 데이터 포인트 수에 따라 표시 여부 결정
                              if (processedData.length <= 5) {
                                // 데이터가 적으면 모두 표시
                              } else if (processedData.length <= 10) {
                                // 데이터가 중간 정도면 일부만 표시
                                if (recordDate != today &&
                                    value.toInt() % 2 != 0) {
                                  return const SizedBox.shrink();
                                }
                              } else {
                                // 데이터가 많으면 더 적게 표시
                                if (recordDate != today &&
                                    value.toInt() != 0 &&
                                    value.toInt() != processedData.length - 1 &&
                                    value.toInt() % 3 != 0) {
                                  return const SizedBox.shrink();
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  children: [
                                    Text(
                                      label,
                                      style: GoogleFonts.notoSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: recordDate == today
                                            ? Colors.purple.shade700
                                            : Colors.black54,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    // 점수 표시
                                    Text(
                                      '${record.score}',
                                      style: GoogleFonts.notoSans(
                                        fontSize: 10,
                                        color: recordDate == today
                                            ? Colors.purple.shade700
                                                .withOpacity(0.8)
                                            : Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
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
                    maxX: (processedData.length - 1).toDouble(),
                    minY: 0,
                    maxY: _calculateMaxY(processedData),
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
                            // 오늘 데이터는 다른 색상으로 표시
                            if (index < processedData.length) {
                              final date = processedData[index].date;
                              final now = DateTime.now();
                              final today =
                                  DateTime(now.year, now.month, now.day);
                              final recordDate =
                                  DateTime(date.year, date.month, date.day);

                              return FlDotCirclePainter(
                                radius: recordDate == today ? 7 : 6,
                                color: recordDate == today
                                    ? Colors.purple.shade700
                                    : Colors.purpleAccent,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            }
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
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.blueAccent.withOpacity(0.8),
                        tooltipRoundedRadius: 8,
                        tooltipPadding: EdgeInsets.all(8),
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            final int index = spot.x.toInt();
                            if (index >= 0 && index < processedData.length) {
                              final record = processedData[index];
                              final date = record.date;
                              final now = DateTime.now();
                              final today =
                                  DateTime(now.year, now.month, now.day);
                              final recordDate =
                                  DateTime(date.year, date.month, date.day);

                              String tooltip;
                              if (recordDate == today) {
                                // 오늘 데이터는 시간 포함하여 상세 표시
                                final dateText = _formatDateDetailed(date);
                                final hourFormatted =
                                    date.hour.toString().padLeft(2, '0');
                                final minuteFormatted =
                                    date.minute.toString().padLeft(2, '0');
                                tooltip =
                                    'Today at $hourFormatted:$minuteFormatted\nScore: ${record.score}';
                              } else {
                                // 과거 데이터는 일자만 표시
                                final dateText = _formatDateDetailed(date);
                                tooltip =
                                    'Date: $dateText\nBest Score: ${record.score}';
                              }

                              return LineTooltipItem(
                                tooltip,
                                GoogleFonts.notoSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }
                            return null;
                          }).toList();
                        },
                      ),
                      getTouchedSpotIndicator: (barData, spotIndexes) {
                        return spotIndexes.map((spotIndex) {
                          return TouchedSpotIndicatorData(
                            FlLine(
                              color: Colors.white,
                              strokeWidth: 2,
                              dashArray: [3, 3],
                            ),
                            FlDotData(
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 8,
                                  color: Colors.white,
                                  strokeWidth: 2,
                                  strokeColor: Colors.purpleAccent,
                                );
                              },
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // 상세 날짜 포맷 (툴팁용)
  String _formatDateDetailed(DateTime date) {
    final now = DateTime.now();

    if (date.year == now.year) {
      // 올해 안이면 년도 생략
      return '${date.month}월 ${date.day}일';
    } else {
      // 년도가 다르면 년도 포함
      return '${date.year}년 ${date.month}월 ${date.day}일';
    }
  }

  // 날짜 범위 텍스트 생성
  String _getDateRangeText(List<ScoreRecord> data) {
    if (data.isEmpty) return '';

    // 첫 번째와 마지막 데이터의 날짜
    final firstDate = data.first.date;
    final lastDate = data.last.date;

    // 간단한 날짜 포맷
    String formatCompactDate(DateTime date) {
      return '${date.month}/${date.day}';
    }

    return '${formatCompactDate(firstDate)} - ${formatCompactDate(lastDate)}';
  }

  // 날짜 포맷팅 메서드
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      // 1주일 이내
      List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } else if (date.year == now.year) {
      // 올해 안에 있는 날짜
      return '${date.month}/${date.day}';
    } else {
      // 작년 이전 날짜
      return '${date.year}.${date.month}';
    }
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

    // 최대값의 20% 여유 공간 추가
    return maxScore * 1.2;
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
                              child: Text('User',
                                  style: GoogleFonts.notoSans(
                                      fontWeight: FontWeight.bold))),
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
}
