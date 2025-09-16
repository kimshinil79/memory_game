import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/brain_health_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flag/flag.dart'; // 국기 표시용 패키지 import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// LoginRequiredDialog 추가
import '../widgets/auth/sign_in_dialog.dart'; // SignInDialog 추가
import '../widgets/auth/sign_up_dialog.dart'; // SignUpDialog 추가
import 'package:intl/intl.dart';
import '../providers/language_provider.dart';
import '../widgets/tutorials/brain_health_tutorial_overlay.dart';

class BrainHealthPage extends StatefulWidget {
  const BrainHealthPage({super.key});

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
    DateTime? currentBirthday;

    // Firebase에서 생일 가져오기 시도
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
          if (userData.containsKey('birthday')) {
            currentBirthday = (userData['birthday'] as Timestamp).toDate();
            // Calculate age from birthday
            currentAge =
                (DateTime.now().difference(currentBirthday).inDays / 365)
                    .floor();
          } else if (userData.containsKey('age')) {
            currentAge = userData['age'] as int;
            // Calculate an approximate birth date
            currentBirthday = DateTime(DateTime.now().year - currentAge, 1, 1);
          }
        }
      } catch (e) {
        print('Error fetching birthday from Firebase: $e');
      }
    }

    // 텍스트 컨트롤러 초기화
    final TextEditingController controller = TextEditingController();
    if (currentBirthday != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(currentBirthday);
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 부분
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.cake,
                      color: Colors.purple.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Update Your Birthday',
                      style: GoogleFonts.notoSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 설명 텍스트
              Text(
                'Your birthday helps us calculate a more accurate Brain Health Index.',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),

              // 생일 입력 필드
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: currentBirthday != null
                        ? currentBirthday!
                        : DateTime(DateTime.now().year - currentAge, 1, 1),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Colors.purple.shade400,
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    controller.text = DateFormat('yyyy-MM-dd').format(picked);
                    currentBirthday = picked;
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Birthday',
                      labelStyle: TextStyle(color: Colors.purple.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.purple.shade400),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      prefixIcon: Icon(Icons.cake_outlined,
                          color: Colors.purple.shade400),
                      suffixIcon: Icon(Icons.calendar_today,
                          color: Colors.purple.shade400),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 액션 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (currentBirthday != null) {
                        // Calculate age from birthday
                        int age = (DateTime.now()
                                    .difference(currentBirthday!)
                                    .inDays /
                                365)
                            .floor();

                        // SharedPreferences에 저장
                        await prefs.setInt('user_age', age);

                        // Firebase에도 저장
                        final User? user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .set({
                              'birthday': Timestamp.fromDate(currentBirthday!),
                              'age': age // For backward compatibility
                            }, SetOptions(merge: true));
                            print('Birthday updated in Firebase');
                          } catch (e) {
                            print('Error updating birthday in Firebase: $e');
                          }
                        }

                        Navigator.pop(context);

                        // Brain Health 데이터 새로고침
                        setState(() {
                          _refreshData(context);
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade400,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Update',
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(brainHealthProvider),
                      const SizedBox(height: 24),

                      // 로그인하지 않은 경우 로그인 권장 메시지 표시
                      if (!isLoggedIn)
                        _buildLoginPrompt(context)
                      else ...[
                        // 로그인한 경우만 다음 위젯들을 표시
                        _buildUserRankings(brainHealthProvider),
                        const SizedBox(height: 32),
                        _buildActivityChart(brainHealthProvider),
                        const SizedBox(height: 32),
                        _buildBrainHealthProgress(brainHealthProvider),
                        const SizedBox(height: 32),
                        _buildInfoCards(brainHealthProvider),
                        const SizedBox(height: 32),
                        _buildBenefitsSection(),
                      ],
                      const SizedBox(height: 80), // Extra space at bottom
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
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                Provider.of<LanguageProvider>(context,
                                            listen: false)
                                        .getUITranslations()['loading_data'] ??
                                    'Loading data...',
                                style: const TextStyle(
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
                          const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              brainHealthProvider.error!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: () => _refreshData(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 튜토리얼 오버레이
                BrainHealthTutorialOverlay(
                  showTutorial: _showTutorial,
                  doNotShowAgain: _doNotShowAgain,
                  onDoNotShowAgainChanged: (value) {
                    setState(() {
                      _doNotShowAgain = value;
                    });
                  },
                  onClose: _closeTutorial,
                  textScaleFactor: MediaQuery.of(context).textScaleFactor,
                ),
              ],
            ),
          ),
          floatingActionButton: isLoggedIn
              ? FloatingActionButton(
                  onPressed: () => _refreshData(context),
                  tooltip: Provider.of<LanguageProvider>(context, listen: false)
                          .getUITranslations()['refresh_data'] ??
                      'Refresh Data',
                  backgroundColor: Colors.purple,
                  child: const Icon(Icons.refresh),
                )
              : null,
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  // Add text scale factor getter for dynamic text sizing with foldable support
  double get _textScaleFactor {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;

    // LanguageProvider를 통해 폴더블 상태 확인
    try {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      final isFolded = languageProvider.isFolded;

      // 폴더블 상태에 따른 텍스트 크기 조정
      if (isFolded) {
        if (width < 360) return 0.75; // 폴드된 작은 화면
        if (width < 400) return 0.8; // 폴드된 중간 화면
        return 0.85; // 폴드된 큰 화면
      } else {
        // 일반 화면
        if (width < 360) return 0.85;
        if (width < 400) return 0.9;
        return 1.0;
      }
    } catch (e) {
      // Provider 접근 실패 시 기본값 사용
      if (width < 360) return 0.85;
      if (width < 400) return 0.9;
      return 1.0;
    }
  }

  Widget _buildHeader(BrainHealthProvider provider) {
    // 언어 제공자에서 번역 가져오기
    final translations = Provider.of<LanguageProvider>(context, listen: false)
        .getUITranslations();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translations['brain_health_dashboard'] ?? 'Brain Health Dashboard',
          style: GoogleFonts.notoSans(
            fontSize: 28 * _textScaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          translations['play_memory_games_description'] ??
              'Play memory games to improve your brain health!',
          style: GoogleFonts.notoSans(
            fontSize: 16 * _textScaleFactor,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildBrainHealthProgress(BrainHealthProvider provider) {
    // 언어 제공자에서 번역 가져오기
    final translations = Provider.of<LanguageProvider>(context, listen: false)
        .getUITranslations();

    return FutureBuilder<Map<String, dynamic>>(
      future: _getBrainHealthIndexData(provider),
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
                      translations['brain_health_index_title'] ??
                          'Brain Health Index',
                      style: GoogleFonts.notoSans(
                        fontSize: 20 * _textScaleFactor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                        translations['calculating_brain_health_index'] ??
                            'Calculating your Brain Health Index...',
                        style: GoogleFonts.notoSans(
                            fontSize: 16 * _textScaleFactor)),
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
                    Icon(Icons.error_outline,
                        size: 48 * _textScaleFactor, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                        translations['error_calculating_index'] ??
                            'Error calculating Brain Health Index',
                        style: GoogleFonts.notoSans(
                            fontSize: 16 * _textScaleFactor)),
                  ],
                ),
              ),
            ),
          );
        }

        // Get data from calculation
        print('snapshot.data: ${snapshot.data}');
        final data = snapshot.data!;
        final brainHealthIndex = data['brainHealthIndex'] as double? ?? 0.0;
        final indexLevel = data['brainHealthIndexLevel'] as int? ?? 1;
        final dataSource = data['dataSource'] as String? ?? 'calculated';
        print('indexLevel: $indexLevel, dataSource: $dataSource');
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
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          translations['brain_health_index_title'] ??
                              'Brain Health Index',
                          style: GoogleFonts.notoSans(
                            fontSize: 20 * _textScaleFactor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 데이터 소스 표시 (디버깅용)
                        if (dataSource == 'firebase')
                          const Tooltip(
                            message: 'Using saved data from Firebase',
                            child: Icon(
                              Icons.cloud_done,
                              size: 16,
                              color: Colors.green,
                            ),
                          )
                        else if (dataSource == 'calculated')
                          const Tooltip(
                            message: 'Calculated in real-time',
                            child: Icon(
                              Icons.refresh,
                              size: 16,
                              color: Colors.orange,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: progressColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: progressColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: progressColor,
                            size: 16 * _textScaleFactor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            brainHealthIndex.toStringAsFixed(1),
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 16 * _textScaleFactor,
                              color: progressColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                CircularPercentIndicator(
                  radius: 80.0,
                  lineWidth: 15.0,
                  animation: true,
                  percent: percentage,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icon/level${indexLevel}_brain.png',
                        width: 40 * _textScaleFactor,
                        height: 40 * _textScaleFactor,
                      ),
                      Text(
                        '${translations['level'] ?? 'Level'} $indexLevel',
                        style: GoogleFonts.notoSans(
                          fontSize: 16 * _textScaleFactor,
                        ),
                      ),
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: progressColor,
                  backgroundColor: Colors.grey.shade200,
                ),
                const SizedBox(height: 20),
                indexLevel < 5
                    ? Text(
                        translations['points_to_next_level']?.replaceFirst(
                                '{points}', pointsToNext.toInt().toString()) ??
                            'You need ${pointsToNext.toInt()} points to reach the next level',
                        style: GoogleFonts.notoSans(
                          fontSize: 16 * _textScaleFactor,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : Text(
                        translations['maximum_level_reached'] ??
                            'Maximum level reached',
                        style: GoogleFonts.notoSans(
                          fontSize: 16 * _textScaleFactor,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                const SizedBox(height: 16),

                // Index Components
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translations['index_components'] ?? 'Index Components',
                        style: GoogleFonts.notoSans(
                          fontSize: 16 * _textScaleFactor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildIndexComponent(
                        translations['age_factor'] ?? 'Age Factor',
                        data['ageComponent'] as double? ?? 0.0,
                        Icons.person,
                        Colors.blue,
                        isNegative: true,
                      ),
                      _buildIndexComponent(
                        translations['recent_activity'] ?? 'Recent Activity',
                        data['activityComponent'] as double? ?? 0.0,
                        Icons.trending_up,
                        Colors.green,
                      ),
                      _buildIndexComponent(
                        translations['game_performance'] ?? 'Game Performance',
                        data['performanceComponent'] as double? ?? 0.0,
                        Icons.psychology,
                        Colors.purple,
                      ),
                      _buildIndexComponent(
                        translations['persistence_bonus'] ??
                            'Persistence Bonus',
                        data['persistenceBonus'] as double? ?? 0.0,
                        Icons.emoji_events,
                        Colors.amber,
                      ),
                      _buildIndexComponent(
                        translations['inactivity_penalty'] ??
                            'Inactivity Penalty',
                        data['inactivityPenalty'] as double? ?? 0.0,
                        Icons.timer_off,
                        Colors.redAccent,
                        isNegative: true,
                      ),
                    ],
                  ),
                ),

                // Add inactivity warning if needed
                if ((data['daysSinceLastGame'] as int? ?? 0) > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            translations['inactivity_warning']?.replaceFirst(
                                    '{days}',
                                    data['daysSinceLastGame'].toString()) ??
                                'You haven\'t played for ${data['daysSinceLastGame']} day(s). Your score is decreasing each day!',
                            style: GoogleFonts.notoSans(
                              fontSize: 14 * _textScaleFactor,
                              fontWeight: FontWeight.w500,
                              color: Colors.red.shade700,
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
      },
    );
  }

  // Firebase에 저장된 값을 우선 사용하고, 필요시에만 실시간 계산하는 새 메서드
  Future<Map<String, dynamic>> _getBrainHealthIndexData(
      BrainHealthProvider provider) async {
    try {
      // 현재 Firebase에 저장된 값들 확인
      final storedIndex = provider.brainHealthIndex;
      final storedLevel = provider.brainHealthIndexLevel;

      print('Stored BHI: $storedIndex, Level: $storedLevel');

      // Firebase에 유효한 값이 저장되어 있고, 최근에 업데이트 되었다면 그 값을 사용
      if (storedIndex > 0 && storedLevel > 0) {
        // 마지막 게임 이후 경과 시간을 확인해서 실시간 계산이 필요한지 판단
        final weeklyData = provider.getWeeklyData();
        int daysSinceLastGame = 0;

        if (weeklyData.isNotEmpty && weeklyData.last.score > 0) {
          final lastGameDate = weeklyData.last.date;
          daysSinceLastGame = DateTime.now().difference(lastGameDate).inDays;
        }

        // 최근 3일 이내에 게임을 했다면 저장된 값 사용
        if (daysSinceLastGame <= 3) {
          print('Using stored Firebase data (recent activity)');
          return {
            'brainHealthIndex': storedIndex,
            'brainHealthIndexLevel': storedLevel,
            'pointsToNextLevel':
                _calculatePointsToNext(storedIndex, storedLevel),
            'ageComponent': provider.ageComponent,
            'activityComponent': provider.activityComponent,
            'performanceComponent': provider.performanceComponent,
            'persistenceBonus': provider.persistenceBonus,
            'inactivityPenalty': provider.inactivityPenalty,
            'daysSinceLastGame': daysSinceLastGame,
            'levelDropDueToInactivity': 0,
            'dataSource': 'firebase',
          };
        }
      }

      // Firebase에 저장된 값이 없거나 오래된 경우 실시간 계산
      print('Calculating BHI in real-time');
      final calculatedData = await provider.calculateBrainHealthIndex();
      calculatedData['dataSource'] = 'calculated';
      return calculatedData;
    } catch (e) {
      print('Error getting BHI data: $e');
      // 오류 발생 시 실시간 계산으로 폴백
      final calculatedData = await provider.calculateBrainHealthIndex();
      calculatedData['dataSource'] = 'calculated';
      return calculatedData;
    }
  }

  // 다음 레벨까지 필요한 포인트 계산
  double _calculatePointsToNext(double currentIndex, int currentLevel) {
    if (currentLevel >= 5) return 0.0;

    List<double> thresholds = [0, 35, 60, 80, 95, 100];
    double nextThreshold = thresholds[currentLevel];
    double pointsNeeded = nextThreshold - currentIndex;
    return pointsNeeded > 0 ? pointsNeeded : 0.0;
  }

  Widget _buildIndexComponent(
      String title, double value, IconData icon, Color color,
      {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16 * _textScaleFactor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.notoSans(
                fontSize: 14 * _textScaleFactor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            isNegative
                ? '-${value.toStringAsFixed(1)}'
                : '+${value.toStringAsFixed(1)}',
            style: GoogleFonts.notoSans(
              fontSize: 14 * _textScaleFactor,
              fontWeight: FontWeight.bold,
              color: isNegative ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(BrainHealthProvider provider) {
    // Get translations from language provider
    final translations =
        Provider.of<LanguageProvider>(context).getUITranslations();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translations['game_statistics'] ?? 'Game Statistics',
          style: GoogleFonts.notoSans(
            fontSize: 20 * _textScaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.sports_esports,
                title: translations['games_played'] ?? 'Games Played',
                value: '${provider.totalGamesPlayed}',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.find_in_page,
                title: translations['matches_found'] ?? 'Matches Found',
                value: '${provider.totalMatchesFound}',
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildBestTimesCard(provider),
      ],
    );
  }

  Widget _buildBestTimesCard(BrainHealthProvider provider) {
    // Get translations from language provider
    final translations =
        Provider.of<LanguageProvider>(context).getUITranslations();

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
                Icon(Icons.speed,
                    color: Colors.orange, size: 28 * _textScaleFactor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    translations['best_times'] ?? 'Best Times',
                    style: GoogleFonts.notoSans(
                      fontSize: 18 * _textScaleFactor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (gridSizes.isEmpty)
              Text(
                translations['no_records_yet'] ?? 'No records yet',
                style: GoogleFonts.notoSans(
                  fontSize: 16 * _textScaleFactor,
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
                            '${translations['overall_best'] ?? 'Overall Best'}:',
                            style: GoogleFonts.notoSans(
                              fontSize: 16 * _textScaleFactor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${provider.bestTime}s',
                            style: GoogleFonts.montserrat(
                              fontSize: 16 * _textScaleFactor,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(),
                  // Individual grid size best times
                  ...gridSizes.map((gridSize) {
                    final time = provider.bestTimesByGridSize[gridSize] ?? 0;
                    if (time <= 0) {
                      return const SizedBox.shrink(); // Skip if no record
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$gridSize ${translations['grid'] ?? 'Grid'}:',
                            style: GoogleFonts.notoSans(
                              fontSize: 15 * _textScaleFactor,
                            ),
                          ),
                          Text(
                            '${time}s',
                            style: GoogleFonts.montserrat(
                              fontSize: 15 * _textScaleFactor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
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
            Icon(icon, color: color, size: 28 * _textScaleFactor),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.notoSans(
                fontSize: 14 * _textScaleFactor,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 20 * _textScaleFactor,
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
    // Get translations from language provider
    final translations =
        Provider.of<LanguageProvider>(context).getUITranslations();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translations['benefits_of_brain_games'] ?? 'Benefits of Brain Games',
          style: GoogleFonts.notoSans(
            fontSize: 20 * _textScaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
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
                  title: translations['short_term_memory_improvement'] ??
                      'Short-term Memory Improvement',
                  description: translations['short_term_memory_desc'] ??
                      'Memory games effectively strengthen short-term memory and memory capacity.',
                ),
                const Divider(),
                _buildBenefitItem(
                  icon: Icons.psychology,
                  title: translations['cognitive_function_enhancement'] ??
                      'Cognitive Function Enhancement',
                  description: translations['cognitive_function_desc'] ??
                      'Regular brain activity helps maintain and improve cognitive functions.',
                ),
                const Divider(),
                _buildBenefitItem(
                  icon: Icons.timer,
                  title: translations['response_time_reduction'] ??
                      'Response Time Reduction',
                  description: translations['response_time_desc'] ??
                      'Quick matching improves reaction time and processing speed.',
                ),
                const Divider(),
                _buildBenefitItem(
                  icon: Icons.healing,
                  title: translations['dementia_prevention'] ??
                      'Dementia Prevention',
                  description: translations['dementia_prevention_desc'] ??
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
          Image.asset(
            'assets/icon/rainbowBrain.png',
            width: 24 * _textScaleFactor,
            height: 24 * _textScaleFactor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSans(
                    fontSize: 16 * _textScaleFactor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.notoSans(
                    fontSize: 14 * _textScaleFactor,
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

    // Get translations from language provider
    final translations =
        Provider.of<LanguageProvider>(context).getUITranslations();

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
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  translations['brain_health_progress'] ??
                      'Brain Health Progress',
                  style: GoogleFonts.notoSans(
                    fontSize: 20 * _textScaleFactor,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            if (weeklyData.isNotEmpty && weeklyData[0].score > 0)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _getDateRangeText(weeklyData),
                  style: GoogleFonts.notoSans(
                    fontSize: 12 * _textScaleFactor,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
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
          child: weeklyData.isEmpty || weeklyData[0].score == 0
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.psychology_outlined,
                        size: 48 * _textScaleFactor,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          translations['welcome_to_brain_health'] ??
                              'Welcome to Brain Health!',
                          style: GoogleFonts.notoSans(
                            fontSize: 16 * _textScaleFactor,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          translations['start_playing_memory_games'] ??
                              'Start playing memory games\nto track your progress',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSans(
                            fontSize: 14 * _textScaleFactor,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _calculateYAxisInterval(weeklyData),
                            getTitlesWidget: (value, meta) {
                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  value.toInt().toString(),
                                  style: GoogleFonts.notoSans(
                                    fontSize: 12 * _textScaleFactor,
                                    color: Colors.black54,
                                  ),
                                ),
                              );
                            },
                            reservedSize: 40 * _textScaleFactor,
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
                                radius: 4 * _textScaleFactor,
                                color: Colors.white,
                                strokeWidth: 2 * _textScaleFactor,
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
                                  fontSize: 12 * _textScaleFactor,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        '${translations['score'] ?? 'Score'}: $score',
                                    style: GoogleFonts.notoSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.normal,
                                      fontSize: 14 * _textScaleFactor,
                                    ),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          tooltipMargin: 8,
                          tooltipPadding: EdgeInsets.all(8 * _textScaleFactor),
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
                                  color: Colors.blue.shade300,
                                  strokeWidth: 2 * _textScaleFactor),
                              FlDotData(
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 6 * _textScaleFactor,
                                    color: Colors.white,
                                    strokeWidth: 3 * _textScaleFactor,
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

  // Y 축 간격 계산
  double _calculateYAxisInterval(List<ScoreRecord> data) {
    double maxY = _calculateMaxY(data);

    // maxY 값에 따라 적절한 간격 설정
    if (maxY <= 200) return 50; // 0, 50, 100, 150, 200
    if (maxY <= 400) return 100; // 0, 100, 200, 300, 400
    if (maxY <= 600) return 150; // 0, 150, 300, 450, 600
    if (maxY <= 800) return 200; // 0, 200, 400, 600, 800
    if (maxY <= 1000) return 250; // 0, 250, 500, 750, 1000

    // 1000 이상인 경우 maxY의 1/4 정도로 간격 설정
    return (maxY / 4).roundToDouble();
  }

  // 사용자 랭킹 섹션 위젯
  Widget _buildUserRankings(BrainHealthProvider provider) {
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
                      fontSize: 20 * _textScaleFactor,
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
                        fontSize: 16 * _textScaleFactor,
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
                        fontSize: 16 * _textScaleFactor,
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
                              width: 40 * _textScaleFactor,
                              child: Text(translations['rank'] ?? 'Rank',
                                  style: GoogleFonts.notoSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14 * _textScaleFactor))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Text(translations['user'] ?? 'User',
                                style: GoogleFonts.notoSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14 * _textScaleFactor)),
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
                                size: 16 * _textScaleFactor,
                              ),
                            ),
                          ),
                          SizedBox(
                              width: 80 * _textScaleFactor,
                              child: Text(translations['score'] ?? 'Score',
                                  style: GoogleFonts.notoSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14 * _textScaleFactor),
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
                                  width: 40 * _textScaleFactor,
                                  child: Text(
                                    '#${ranking['rank']}',
                                    style: GoogleFonts.notoSans(
                                      fontWeight: isCurrentUser
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 14 * _textScaleFactor,
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
                                                  height: 16 * _textScaleFactor,
                                                  width: 24 * _textScaleFactor,
                                                  borderRadius: 4,
                                                );
                                              } catch (e) {
                                                // 오류 발생 시 간단한 컨테이너로 대체
                                                return Container(
                                                  height: 16 * _textScaleFactor,
                                                  width: 24 * _textScaleFactor,
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
                                            fontSize: 14 * _textScaleFactor,
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
                                          width: 18 * _textScaleFactor,
                                          height: 18 * _textScaleFactor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 80 * _textScaleFactor,
                                  child: Text(
                                    '${ranking['score']}',
                                    style: GoogleFonts.notoSans(
                                      fontWeight: isCurrentUser
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 14 * _textScaleFactor,
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

  // Calculate brain health level based on score
  int _calculateBrainHealthLevel(int score) {
    // Assuming 1000 points is the maximum (based on the provider code)
    double percentage = (score / 1000.0) * 100;

    if (percentage < 20) return 1;
    if (percentage < 40) return 2;
    if (percentage < 60) return 3;
    if (percentage < 80) return 4;
    return 5;
  }

  // 랭킹에 따른 색상 반환
  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber.shade700; // 금메달
    if (rank == 2) return Colors.blueGrey.shade400; // 은메달
    if (rank == 3) return Colors.brown.shade400; // 동메달
    return Colors.black87; // 기본 색상
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

    // Get translations from language provider
    final translations =
        Provider.of<LanguageProvider>(context).getUITranslations();

    if (dateToCheck == today) {
      return translations['today'] ?? 'Today';
    } else if (dateToCheck == yesterday) {
      return translations['yesterday'] ?? 'Yesterday';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  // 로그인 권장 메시지 위젯
  Widget _buildLoginPrompt(BuildContext context) {
    // Get the language provider to access translations
    final languageProvider = Provider.of<LanguageProvider>(context);
    final translations = languageProvider.getUITranslations();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology,
            size: 60 * _textScaleFactor,
            color: Colors.purple.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            translations['start_tracking_brain_health'] ??
                'Start Tracking Your Brain Health',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              fontSize: 20 * _textScaleFactor,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            translations['login_prompt_desc'] ??
                'Sign in to record your brain health score and track your progress. Play memory games to improve your cognitive abilities.',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              fontSize: 16 * _textScaleFactor,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showSignInDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                  horizontal: 32 * _textScaleFactor,
                  vertical: 12 * _textScaleFactor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              translations['sign_in'] ?? 'Sign In',
              style: GoogleFonts.notoSans(
                fontSize: 16 * _textScaleFactor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => _showSignUpDialog(context),
            child: Text(
              translations['create_account'] ?? 'Create Account',
              style: GoogleFonts.notoSans(
                fontSize: 14 * _textScaleFactor,
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
              const SnackBar(
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
              duration: const Duration(seconds: 3),
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
              'birthday': userData['birthday'],
              'gender': userData['gender'],
              'country': userData['country'],
              'shortPW': userData['shortPW'],
            });

            // 계정 생성 성공 메시지
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
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
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error showing sign up dialog: $e');
    }
  }

  Color _getBrainHealthColor(int level) {
    switch (level) {
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orangeAccent;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.blue;
    }
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
