import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/brain_health_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flag/flag.dart'; // 국기 표시용 패키지 import
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/auth/auth_dialogs.dart'; // LoginRequiredDialog 추가
import '../widgets/auth/sign_in_dialog.dart'; // SignInDialog 추가
import '../widgets/auth/sign_up_dialog.dart'; // SignUpDialog 추가

class BrainHealthPage extends StatefulWidget {
  const BrainHealthPage({Key? key}) : super(key: key);

  @override
  State<BrainHealthPage> createState() => _BrainHealthPageState();
}

class _BrainHealthPageState extends State<BrainHealthPage>
    with AutomaticKeepAliveClientMixin {
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

  // 사용자 나이 입력 대화상자
  void _showAgeInputDialog() async {
    final prefs = await SharedPreferences.getInstance();
    int currentAge = prefs.getInt('user_age') ?? 30;

    // Firebase에서 나이 가져오기 시도
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          if (userData.containsKey('age')) {
            currentAge = userData['age'] as int;
          }
        }
      } catch (e) {
        print('Error fetching age from Firebase: $e');
      }
    }

    // 텍스트 컨트롤러 초기화
    final TextEditingController controller =
        TextEditingController(text: currentAge.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Your Age',
            style: GoogleFonts.notoSans(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your age helps us calculate a more accurate Brain Health Index.',
              style: GoogleFonts.notoSans(fontSize: 14),
            ),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // 나이 값 확인 및 저장
              final String text = controller.text.trim();
              int? age = int.tryParse(text);

              if (age != null && age > 0 && age < 120) {
                // SharedPreferences에 저장
                await prefs.setInt('user_age', age);

                // Firebase에도 저장
                final User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .set({'age': age}, SetOptions(merge: true));
                    print('Age updated in Firebase');
                  } catch (e) {
                    print('Error updating age in Firebase: $e');
                    // 문서가 존재하지 않을 경우 set으로 생성 시도
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .set({'age': age}, SetOptions(merge: true));
                      print('Age created in Firebase');
                    } catch (e) {
                      print('Error creating age in Firebase: $e');
                    }
                  }
                }

                Navigator.pop(context);

                // Brain Health 데이터 새로고침
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Age updated successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid age (1-120)'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
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
    super.build(context);

    // 로그인 상태 확인
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;

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

                      // 로그인하지 않은 경우 로그인 권장 메시지 표시
                      if (!isLoggedIn)
                        _buildLoginPrompt(context)
                      else ...[
                        // 로그인한 경우만 다음 위젯들을 표시
                        _buildUserRankings(brainHealthProvider),
                        SizedBox(height: 32),
                        _buildActivityChart(brainHealthProvider),
                        SizedBox(height: 32),
                        _buildBrainHealthProgress(brainHealthProvider),
                        SizedBox(height: 32),
                        _buildInfoCards(brainHealthProvider),
                        SizedBox(height: 32),
                        _buildBenefitsSection(),
                      ],
                      SizedBox(height: 80), // Extra space at bottom
                    ],
                  ),
                ),

                // Loading Indicator (로그인 상태일 때만 표시)
                if (isLoggedIn &&
                    (brainHealthProvider.isLoading || _isRefreshing))
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

                // Error message (로그인 상태이고 오류가 있을 때만 표시)
                if (isLoggedIn &&
                    brainHealthProvider.error != null &&
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
          floatingActionButton: isLoggedIn
              ? FloatingActionButton(
                  onPressed: () => _refreshData(context),
                  tooltip: 'Refresh Data',
                  child: Icon(Icons.refresh),
                  backgroundColor: Colors.purple,
                )
              : null,
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

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
    return FutureBuilder<Map<String, dynamic>>(
      future: provider.calculateBrainHealthIndex(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Brain Health Index',
                      style: GoogleFonts.notoSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24),
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Calculating your Brain Health Index...',
                        style: GoogleFonts.notoSans(fontSize: 16)),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text('Error calculating Brain Health Index',
                        style: GoogleFonts.notoSans(fontSize: 16)),
                  ],
                ),
              ),
            ),
          );
        }

        // Get data from calculation
        final data = snapshot.data!;
        final brainHealthIndex = data['brainHealthIndex'] as double? ?? 0.0;
        final indexLevel = data['indexLevel'] as int? ?? 1;
        final pointsToNext = data['pointsToNextLevel'] as double? ?? 0.0;

        // Calculate percentage for circular indicator
        final percentage = brainHealthIndex / 100;

        // Color based on index level
        Color progressColor;
        switch (indexLevel) {
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Age: ${data['details']?['age'] ?? 30}',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(width: 8),
                    InkWell(
                      onTap: _showAgeInputDialog,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit,
                                size: 12, color: Colors.grey.shade700),
                            SizedBox(width: 4),
                            Text(
                              'Update',
                              style: GoogleFonts.notoSans(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                CircularPercentIndicator(
                  radius: 80.0,
                  lineWidth: 15.0,
                  animation: true,
                  percent: percentage,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${brainHealthIndex.toStringAsFixed(1)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Level $indexLevel',
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
                indexLevel < 5
                    ? Text(
                        'You need ${pointsToNext.toInt()} points to reach the next level',
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

                // Index Components
                Container(
                  margin: EdgeInsets.only(top: 10),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Index Components',
                        style: GoogleFonts.notoSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildIndexComponent(
                        'Age Factor',
                        data['ageComponent'] as double? ?? 0.0,
                        Icons.person,
                        Colors.blue,
                        isNegative: true,
                      ),
                      _buildIndexComponent(
                        'Recent Activity',
                        data['activityComponent'] as double? ?? 0.0,
                        Icons.trending_up,
                        Colors.green,
                      ),
                      _buildIndexComponent(
                        'Game Performance',
                        data['performanceComponent'] as double? ?? 0.0,
                        Icons.psychology,
                        Colors.purple,
                      ),
                      _buildIndexComponent(
                        'Persistence Bonus',
                        data['persistenceBonus'] as double? ?? 0.0,
                        Icons.emoji_events,
                        Colors.amber,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndexComponent(
      String title, double value, IconData icon, Color color,
      {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            isNegative
                ? '-${value.toStringAsFixed(1)}'
                : '+${value.toStringAsFixed(1)}',
            style: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isNegative ? Colors.red : Colors.green,
            ),
          ),
        ],
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
              : Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: LineChart(
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
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 500,
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
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.blue.shade700,
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((LineBarSpot spot) {
                              final index = spot.x.toInt();
                              final date = weeklyData[index].date;
                              final score = weeklyData[index].score;
                              final formattedDate =
                                  '${date.month}/${date.day}/${date.year.toString().substring(2)}';

                              return LineTooltipItem(
                                '$formattedDate\n',
                                GoogleFonts.notoSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Score: $score',
                                    style: GoogleFonts.notoSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          tooltipMargin: 8,
                          tooltipPadding: EdgeInsets.all(8),
                          tooltipRoundedRadius: 8,
                          showOnTopOfTheChartBoxArea: true,
                        ),
                        handleBuiltInTouches: true,
                        touchSpotThreshold: 20,
                        getTouchedSpotIndicator:
                            (LineChartBarData barData, List<int> spotIndexes) {
                          return spotIndexes.map((spotIndex) {
                            return TouchedSpotIndicatorData(
                              FlLine(
                                  color: Colors.blue.shade300, strokeWidth: 2),
                              FlDotData(
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 6,
                                    color: Colors.white,
                                    strokeWidth: 3,
                                    strokeColor: Colors.blue.shade700,
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
        ),
      ],
    );
  }

  // Y 축 최대값 계산
  double _calculateMaxY(List<ScoreRecord> data) {
    if (data.isEmpty) return 400; // 기본값 400으로 설정

    double maxScore = 0;
    for (var record in data) {
      if (record.score > maxScore) {
        maxScore = record.score.toDouble();
      }
    }

    // 최대값을 깔끔한 숫자로 올림
    if (maxScore <= 100) return 200;
    if (maxScore <= 200) return 400;
    if (maxScore <= 400) return 600;
    if (maxScore <= 600) return 800;
    if (maxScore <= 800) return 1000;

    // 1000 이상인 경우 500 단위로 올림
    return (maxScore / 500).ceil() * 500;
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
                  'Brain Health Dashboard',
                  style: GoogleFonts.notoSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: tutorialColor,
                  ),
                ),
                SizedBox(height: 15),
                _buildTutorialItem(
                  Icons.psychology,
                  'Brain Health Index',
                  'Check your brain health score improved through memory games. Higher levels increase dementia prevention effect.',
                  tutorialColor,
                ),
                SizedBox(height: 10),
                _buildTutorialItem(
                  Icons.bar_chart,
                  'Activity Graph',
                  'View changes in your brain health score over time through the graph.',
                  tutorialColor,
                ),
                SizedBox(height: 10),
                _buildTutorialItem(
                  Icons.emoji_events,
                  'Ranking System',
                  'Compare your brain health score with other users and check your ranking.',
                  tutorialColor,
                ),
                SizedBox(height: 10),
                _buildTutorialItem(
                  Icons.assessment,
                  'Game Statistics',
                  'Check various statistics such as games played, matches found, and best records.',
                  tutorialColor,
                ),
                SizedBox(height: 15),
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
                      'Don\'t show again',
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
                    'Got it!',
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
            size: 20,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
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

  // 로그인 권장 메시지 위젯
  Widget _buildLoginPrompt(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology,
            size: 60,
            color: Colors.purple.shade300,
          ),
          SizedBox(height: 16),
          Text(
            'Start Tracking Your Brain Health',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Sign in to record your brain health score and track your progress. Play memory games to improve your cognitive abilities.',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showSignInDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Sign In',
              style: GoogleFonts.notoSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 10),
          TextButton(
            onPressed: () => _showSignUpDialog(context),
            child: Text(
              'Create Account',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: Colors.purple.shade700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 로그인 다이얼로그 표시
  void _showSignInDialog(BuildContext context) async {
    try {
      // SignInDialog에서 정의된 show 메서드를 사용하여 다이얼로그 표시
      final result = await SignInDialog.show(context);

      if (result != null) {
        // SignUp 버튼을 눌렀을 경우 회원가입 다이얼로그 표시
        if (result['signUp'] == true) {
          _showSignUpDialog(context);
          return;
        }

        try {
          // Firebase 로그인 처리
          final userCredential =
              await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: result['email'],
            password: result['password'],
          );

          if (userCredential.user != null) {
            // 로그인 성공 메시지
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully signed in'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            // 화면 새로고침
            if (mounted) {
              setState(() {});
            }
          }
        } catch (e) {
          // 로그인 실패 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign in failed: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error showing sign in dialog: $e');
    }
  }

  // 회원가입 다이얼로그 표시
  void _showSignUpDialog(BuildContext context) async {
    try {
      // SignUpDialog에서 정의된 show 메서드를 사용하여 다이얼로그 표시
      final userData = await SignUpDialog.show(context);

      if (userData != null) {
        try {
          // Firebase 회원가입 처리
          final userCredential =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: userData['email'],
            password: userData['password'],
          );

          if (userCredential.user != null) {
            // 사용자 정보 저장
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .set({
              'nickname': userData['nickname'],
              'age': userData['age'],
              'gender': userData['gender'],
              'country': userData['country'],
              'shortPW': userData['shortPW'],
            });

            // 계정 생성 성공 메시지
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Account created successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            // 화면 새로고침
            if (mounted) {
              setState(() {});
            }
          }
        } catch (e) {
          // 계정 생성 실패 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account creation failed: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error showing sign up dialog: $e');
    }
  }
}
