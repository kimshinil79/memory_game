import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tabs/memory_game_page.dart';
import 'tabs/test_page.dart';
import 'tabs/brain_health_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/language_provider.dart';
import 'providers/brain_health_provider.dart';
import 'package:flag/flag.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'utils/route_observer.dart';
import 'data/countries.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('Initializing Firebase app...');
    await Firebase.initializeApp();
    print('Firebase app initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => BrainHealthProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Game',
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          color: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String selectedLanguage = 'en-US';
  int _currentIndex = 0;
  int numberOfPlayers = 1;
  String gridSize = '4x4';
  int flipCount = 0;
  List<String> players = ['Genius', 'Idiot', 'Cute', 'Lovely'];
  Map<String, int> playerScores = {
    'Genius': 0,
    'Idiot': 0,
    'Cute': 0,
    'Lovely': 0
  };
  int currentPlayerIndex = 0;
  UniqueKey _memoryGameKey = UniqueKey();
  MemoryGamePage? _memoryGamePage;
  User? _user;
  String? _nickname;
  String? _profileImageUrl;
  int? _userAge;
  String? _userGender;
  String? _userCountryCode;
  StreamSubscription<User?>? _authSubscription;

  // Add gradient color constants
  final Color instagramGradientStart = Color(0xFF833AB4);
  final Color instagramGradientEnd = Color(0xFFF77737);

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    _migrateUserData();
  }

  @override
  void dispose() {
    // 구독 해제
    _authSubscription?.cancel();
    super.dispose();
  }

  void _initializeAuth() {
    // 기존 구독이 있으면 취소
    _authSubscription?.cancel();

    // 새로운 구독 설정
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (!mounted) return;

      if (user == null) {
        setState(() {
          _user = null;
          _nickname = null;
        });
      } else {
        _fetchUserProfile(user);
      }
    });
  }

  Future<void> _fetchUserProfile(User user) async {
    if (!mounted) return;

    try {
      String uid = user.uid;
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _user = user;
            _nickname = userData['nickname'] as String?;
            _userAge = userData['age'] as int?;
            _userGender = userData['gender'] as String?;
            _userCountryCode = userData['country'] as String?;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _user = user;
            _nickname = null;
            _userAge = null;
            _userGender = null;
            _userCountryCode = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _user = user;
          _nickname = null;
          _userAge = null;
          _userGender = null;
          _userCountryCode = null;
        });
      }
    }
  }

  Future<void> _migrateUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        String uid = user.uid;
        String emailPrefix = user.email!.split('@')[0];
        String oldDocumentId = '$emailPrefix$uid';
        String newDocumentId = uid;

        DocumentSnapshot newUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(newDocumentId)
            .get();

        DocumentSnapshot oldUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(oldDocumentId)
            .get();

        if (!newUserDoc.exists && oldUserDoc.exists) {
          Map<String, dynamic> userData =
              oldUserDoc.data() as Map<String, dynamic>;

          await FirebaseFirestore.instance
              .collection('users')
              .doc(newDocumentId)
              .set(userData);
        }
      }
    } catch (e) {
      // Error handling without print
    }
  }

  Future<void> _signOut() async {
    try {
      setState(() {
        _user = null;
        _nickname = null;
      });

      await FirebaseAuth.instance.signOut();

      setState(() {
        _memoryGameKey = UniqueKey();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out. Please try again.')),
      );

      _initializeAuth();
    }
  }

  String _getCountryCode(String languageCode) {
    // Extract the country part from the language code (e.g., 'en-US' -> 'US')
    if (languageCode == 'mute') {
      return 'un'; // UN flag for mute option
    }

    // ISO 639 language code to ISO 3166-1 alpha-2 country code mapping
    Map<String, String> languageToCountry = {
      // 기존 언어
      'ko-KR': 'kr',
      'en-US': 'us',
      'en-GB': 'gb',
      'en-AU': 'au',
      'en-CA': 'ca',
      'en-IN': 'in',
      'es-ES': 'es',
      'es-MX': 'mx',
      'es-US': 'us',
      'fr-FR': 'fr',
      'fr-CA': 'ca',
      'de-DE': 'de',
      'ja-JP': 'jp',
      'zh-CN': 'cn',
      'zh-TW': 'tw',
      'zh-HK': 'hk',
      'ru-RU': 'ru',
      'it-IT': 'it',
      'pt-PT': 'pt',
      'pt-BR': 'br',
      'ar-SA': 'sa',
      'ar-AE': 'ae',
      'ar-EG': 'eg',
      'tr-TR': 'tr',
      'vi-VN': 'vn',
      'nl-NL': 'nl',
      'pl-PL': 'pl',
      'cs-CZ': 'cz',
      'hu-HU': 'hu',

      // 추가 언어
      'af-ZA': 'za', // 아프리카어 (남아프리카)
      'am-ET': 'et', // 암하라어 (에티오피아)
      'ar-DZ': 'dz', // 아랍어 (알제리)
      'ar-BH': 'bh', // 아랍어 (바레인)
      'ar-IQ': 'iq', // 아랍어 (이라크)
      'ar-JO': 'jo', // 아랍어 (요르단)
      'ar-KW': 'kw', // 아랍어 (쿠웨이트)
      'ar-LB': 'lb', // 아랍어 (레바논)
      'ar-LY': 'ly', // 아랍어 (리비아)
      'ar-MA': 'ma', // 아랍어 (모로코)
      'ar-QA': 'qa', // 아랍어 (카타르)
      'ar-SY': 'sy', // 아랍어 (시리아)
      'ar-TN': 'tn', // 아랍어 (튀니지)
      'ar-YE': 'ye', // 아랍어 (예멘)
      'az-AZ': 'az', // 아제르바이잔어
      'be-BY': 'by', // 벨라루스어
      'bg-BG': 'bg', // 불가리아어
      'bn-BD': 'bd', // 벵골어 (방글라데시)
      'bn-IN': 'in', // 벵골어 (인도)
      'bs-BA': 'ba', // 보스니아어
      'ca-ES': 'es', // 카탈로니아어
      'cy-GB': 'gb', // 웨일스어
      'da-DK': 'dk', // 덴마크어
      'el-GR': 'gr', // 그리스어
      'et-EE': 'ee', // 에스토니아어
      'eu-ES': 'es', // 바스크어
      'fa-IR': 'ir', // 페르시아어
      'fi-FI': 'fi', // 핀란드어
      'fil-PH': 'ph', // 필리핀어
      'gl-ES': 'es', // 갈리시아어
      'gu-IN': 'in', // 구자라트어
      'he-IL': 'il', // 히브리어
      'hi-IN': 'in', // 힌디어
      'hr-HR': 'hr', // 크로아티아어
      'hy-AM': 'am', // 아르메니아어
      'id-ID': 'id', // 인도네시아어
      'is-IS': 'is', // 아이슬란드어
      'jv-ID': 'id', // 자바어
      'ka-GE': 'ge', // 조지아어
      'kk-KZ': 'kz', // 카자흐어
      'km-KH': 'kh', // 크메르어
      'kn-IN': 'in', // 칸나다어
      'ky-KG': 'kg', // 키르기스어
      'lo-LA': 'la', // 라오어
      'lt-LT': 'lt', // 리투아니아어
      'lv-LV': 'lv', // 라트비아어
      'mk-MK': 'mk', // 마케도니아어
      'ml-IN': 'in', // 말라얄람어
      'mn-MN': 'mn', // 몽골어
      'mr-IN': 'in', // 마라티어
      'ms-MY': 'my', // 말레이어
      'mt-MT': 'mt', // 몰타어
      'my-MM': 'mm', // 미얀마어
      'nb-NO': 'no', // 노르웨이어 (보크몰)
      'ne-NP': 'np', // 네팔어
      'nn-NO': 'no', // 노르웨이어 (니노르스크)
      'pa-IN': 'in', // 펀자브어
      'ro-RO': 'ro', // 루마니아어
      'si-LK': 'lk', // 싱할라어
      'sk-SK': 'sk', // 슬로바키아어
      'sl-SI': 'si', // 슬로베니아어
      'sq-AL': 'al', // 알바니아어
      'sr-RS': 'rs', // 세르비아어
      'su-ID': 'id', // 순다어
      'sv-SE': 'se', // 스웨덴어
      'sw-KE': 'ke', // 스와힐리어
      'ta-IN': 'in', // 타밀어
      'te-IN': 'in', // 텔루구어
      'th-TH': 'th', // 태국어
      'uk-UA': 'ua', // 우크라이나어
      'ur-PK': 'pk', // 우르두어
      'uz-UZ': 'uz', // 우즈베크어
    };

    // 매핑된 국가 코드 반환, 없으면 언어 코드의 뒷부분 사용
    if (languageToCountry.containsKey(languageCode)) {
      return languageToCountry[languageCode]!;
    } else {
      // 언어 코드에서 국가 부분 추출
      List<String> parts = languageCode.split('-');
      if (parts.length > 1) {
        return parts[1].toLowerCase();
      }
      return 'us'; // 기본값
    }
  }

  Future<void> _updateLanguage(String languageCode) async {
    try {
      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedLanguage', languageCode);

      // Update Provider
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      languageProvider.setLanguage(languageCode);

      // Update Firebase if user is logged in
      if (_user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'language': languageCode});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update language setting')),
      );
    }
  }

  void _showLanguageSelectionDialog(BuildContext context) {
    // Google TTS가 지원하는 언어 매핑 (언어 코드: 표시 이름)
    final Map<String, String> languageNames = {
      'mute': '무음 (Mute)',

      // 아프리카어
      'af-ZA': 'Afrikaans',
      'am-ET': 'Amharic (አማርኛ)',
      'zu-ZA': 'Zulu (isiZulu)',
      'sw-KE': 'Swahili (Kiswahili)',

      // 아시아어
      'ko-KR': 'Korean (한국어)',
      'ja-JP': 'Japanese (日本語)',
      'zh-CN': 'Chinese Simplified (简体中文)',
      'hi-IN': 'Hindi (हिन्दी)',
      'bn-IN': 'Bengali (বাংলা)',
      'id-ID': 'Indonesian (Bahasa Indonesia)',
      'km-KH': 'Khmer (ខ្មែរ)',
      'ne-NP': 'Nepali (नेपाली)',
      'si-LK': 'Sinhala (සිංහල)',
      'th-TH': 'Thai (ไทย)',
      'vi-VN': 'Vietnamese (Tiếng Việt)',
      'my-MM': 'Myanmar (မြန်မာ)',
      'lo-LA': 'Lao (ລາວ)',
      'fil-PH': 'Filipino',
      'ms-MY': 'Malay (Bahasa Melayu)',
      'jv-ID': 'Javanese (Basa Jawa)',
      'su-ID': 'Sundanese (Basa Sunda)',
      'ta-IN': 'Tamil (தமிழ்)',
      'te-IN': 'Telugu (తెలుగు)',
      'ml-IN': 'Malayalam (മലയാളം)',
      'gu-IN': 'Gujarati (ગુજરાતી)',
      'kn-IN': 'Kannada (ಕನ್ನಡ)',
      'mr-IN': 'Marathi (मराठी)',
      'pa-IN': 'Punjabi (ਪੰਜਾਬੀ)',
      'ur-PK': 'Urdu (اردو)',

      // 유럽어
      'en-US': 'English (US)',
      'es-ES': 'Spanish (Spain)',
      'fr-FR': 'French (France)',
      'de-DE': 'German (Deutsch)',
      'it-IT': 'Italian (Italiano)',
      'pt-PT': 'Portuguese (Portugal)',
      'ru-RU': 'Russian (Русский)',
      'nl-NL': 'Dutch (Nederlands)',
      'pl-PL': 'Polish (Polski)',
      'cs-CZ': 'Czech (Čeština)',
      'hu-HU': 'Hungarian (Magyar)',
      'sv-SE': 'Swedish (Svenska)',
      'da-DK': 'Danish (Dansk)',
      'fi-FI': 'Finnish (Suomi)',
      'nb-NO': 'Norwegian (Norsk)',
      'bg-BG': 'Bulgarian (Български)',
      'el-GR': 'Greek (Ελληνικά)',
      'ro-RO': 'Romanian (Română)',
      'sk-SK': 'Slovak (Slovenčina)',
      'uk-UA': 'Ukrainian (Українська)',
      'hr-HR': 'Croatian (Hrvatski)',
      'sl-SI': 'Slovenian (Slovenščina)',
      'lt-LT': 'Lithuanian (Lietuvių)',

      // 중동어
      'ar-SA': 'Arabic (Saudi Arabia) (العربية)',
      'fa-IR': 'Persian (فارسی)',
      'he-IL': 'Hebrew (עברית)',
      'tr-TR': 'Turkish (Türkçe)',

      // 기타 지역어
      'mn-MN': 'Mongolian (Монгол)',
      'sq-AL': 'Albanian (Shqip)',
      'sr-RS': 'Serbian (Српски)',
      'uz-UZ': 'Uzbek (O\'zbek)',
    };

    // 언어를 지역별로 분류
    Map<String, List<MapEntry<String, String>>> groupedLanguages = {
      'Asian Languages': [],
      'European Languages': [],
      'Middle Eastern Languages': [],
      'African Languages': [],
      'Other Languages': [],
    };

    // 분류 규칙 설정
    languageNames.forEach((code, name) {
      if (code == 'mute') return; // mute는 따로 처리

      MapEntry<String, String> entry = MapEntry(code, name);

      if (code.startsWith('zh') ||
          code.startsWith('ja') ||
          code.startsWith('ko') ||
          code.startsWith('hi') ||
          code.startsWith('bn') ||
          code.startsWith('id') ||
          code.startsWith('km') ||
          code.startsWith('ne') ||
          code.startsWith('si') ||
          code.startsWith('th') ||
          code.startsWith('vi') ||
          code.startsWith('ms') ||
          code.startsWith('my') ||
          code.startsWith('lo') ||
          code.startsWith('fil') ||
          code.startsWith('jv') ||
          code.startsWith('su') ||
          code.startsWith('ta')) {
        groupedLanguages['Asian Languages']!.add(entry);
      } else if (code.startsWith('en') ||
          code.startsWith('es') ||
          code.startsWith('fr') ||
          code.startsWith('de') ||
          code.startsWith('it') ||
          code.startsWith('pt') ||
          code.startsWith('ru') ||
          code.startsWith('nl') ||
          code.startsWith('pl') ||
          code.startsWith('cs') ||
          code.startsWith('hu') ||
          code.startsWith('sv') ||
          code.startsWith('da') ||
          code.startsWith('fi') ||
          code.startsWith('nb') ||
          code.startsWith('bg') ||
          code.startsWith('el') ||
          code.startsWith('ro') ||
          code.startsWith('sk') ||
          code.startsWith('uk') ||
          code.startsWith('hr') ||
          code.startsWith('sl') ||
          code.startsWith('lt') ||
          code.startsWith('lv') ||
          code.startsWith('et') ||
          code.startsWith('is') ||
          code.startsWith('ca') ||
          code.startsWith('eu') ||
          code.startsWith('gl') ||
          code.startsWith('cy')) {
        groupedLanguages['European Languages']!.add(entry);
      } else if (code.startsWith('ar') ||
          code.startsWith('fa') ||
          code.startsWith('he') ||
          code.startsWith('tr')) {
        groupedLanguages['Middle Eastern Languages']!.add(entry);
      } else if (code.startsWith('af') ||
          code.startsWith('am') ||
          code.startsWith('zu') ||
          code.startsWith('sw')) {
        groupedLanguages['African Languages']!.add(entry);
      } else {
        groupedLanguages['Other Languages']!.add(entry);
      }
    });

    // 각 그룹 내에서 알파벳 순으로 정렬
    groupedLanguages.forEach((key, value) {
      value.sort((a, b) => a.value.compareTo(b.value));
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Language',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: DefaultTabController(
                    length: groupedLanguages.length + 1, // +1 for 'All' tab
                    child: Column(
                      children: [
                        TabBar(
                          isScrollable: true,
                          labelColor: Colors.purple,
                          unselectedLabelColor: Colors.grey,
                          tabs: [
                            Tab(text: 'All'),
                            ...groupedLanguages.keys
                                .map((group) => Tab(text: group))
                                .toList(),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // All languages tab
                              _buildLanguageList(context, [
                                MapEntry('mute', languageNames['mute']!),
                                ...languageNames.entries
                                    .where((e) => e.key != 'mute')
                                    .toList()
                                  ..sort((a, b) => a.value.compareTo(b.value))
                              ]),
                              // Group tabs
                              ...groupedLanguages.values
                                  .map(
                                    (languages) =>
                                        _buildLanguageList(context, languages),
                                  )
                                  .toList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF833AB4), Color(0xFFF77737)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageList(
      BuildContext context, List<MapEntry<String, String>> languages) {
    return ListView.builder(
      itemCount: languages.length,
      itemBuilder: (context, index) {
        String languageCode = languages[index].key;
        String languageName = languages[index].value;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.withOpacity(0.1),
          ),
          child: ListTile(
            leading: languageCode == 'mute'
                ? Icon(Icons.volume_off, size: 30)
                : Flag.fromString(
                    _getCountryCode(languageCode),
                    height: 30,
                    width: 40,
                    fit: BoxFit.cover,
                    borderRadius: 8,
                  ),
            title: Text(
              languageName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              if (languageCode == 'mute') {
                _setMute(true);
              } else {
                _updateLanguage(languageCode);
              }
              Navigator.of(context).pop();
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
        );
      },
    );
  }

  void _setMute(bool isMute) {
    // 무음 설정 로직 구현
    // 예: 사운드 플레이어의 볼륨을 0으로 설정
  }

  void updateFlipCount(int count) {
    if (mounted) {
      setState(() {
        flipCount = count;
      });
    }
  }

  void updatePlayerScore(String player, int score) {
    setState(() {
      // Apply grid size multiplier to the score
      int multiplier = getGridSizeMultiplier(gridSize);
      playerScores[player] = score * multiplier;
    });
  }

  // Calculate score multiplier based on grid size
  int getGridSizeMultiplier(String gridSize) {
    switch (gridSize) {
      case '4x4':
        return 1; // Base multiplier
      case '6x4':
        return 2; // Double points for 6x4 grid
      case '6x6':
        return 3; // Triple points for 6x6 grid
      case '8x6':
        return 4; // Quadruple points for 8x6 grid
      default:
        return 1;
    }
  }

  void nextPlayer() {
    setState(() {
      currentPlayerIndex = (currentPlayerIndex + 1) % numberOfPlayers;
    });
  }

  void resetScores() {
    setState(() {
      for (String player in players) {
        playerScores[player] = 0;
      }
    });
  }

  void updateNumberOfPlayers(int newNumberOfPlayers) {
    setState(() {
      numberOfPlayers = newNumberOfPlayers;
      currentPlayerIndex = 0;
      resetScores();
    });
  }

  void updateGridSize(String newGridSize) {
    setState(() {
      gridSize = newGridSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Create MemoryGamePage instance and save reference
    _memoryGamePage = MemoryGamePage(
      key: _memoryGameKey,
      numberOfPlayers: numberOfPlayers,
      gridSize: gridSize,
      updateFlipCount: updateFlipCount,
      updatePlayerScore: updatePlayerScore,
      nextPlayer: nextPlayer,
      currentPlayer: players[currentPlayerIndex],
      playerScores: playerScores,
      resetScores: resetScores,
      isTimeAttackMode: true,
      timeLimit: 60,
    );

    List<Widget> _pages = [
      GestureDetector(
        onTap: () {
          if (_user == null) {
            _showLoginRequiredDialog(context);
          }
        },
        child: AbsorbPointer(
          absorbing: _user == null,
          child: _memoryGamePage!,
        ),
      ),
      BrainHealthPage(),
      TestPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: _currentIndex == 0 ? 90 : 60,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Memory Game',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (_currentIndex != 1) ...[
                  const SizedBox(width: 8),
                  Container(
                    height: 24,
                    width: 1,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showLanguageSelectionDialog(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Consumer<LanguageProvider>(
                            builder: (context, languageProvider, child) {
                              return Flag.fromString(
                                _getCountryCode(
                                    languageProvider.currentLanguage),
                                height: 16,
                                width: 24,
                                borderRadius: 4,
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down,
                              size: 16, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (_currentIndex == 0) ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildControlButton(
                      icon: Icons.people,
                      label:
                          '$numberOfPlayers Player${numberOfPlayers > 1 ? 's' : ''}',
                      onTap: _showPlayerSelectionDialog,
                    ),
                    const SizedBox(width: 8),
                    _buildControlButton(
                      icon: Icons.grid_on,
                      label: gridSize,
                      onTap: _showGridSizeSelectionDialog,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            instagramGradientStart,
                            instagramGradientEnd
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flip, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '$flipCount',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_currentIndex == 1)
            Consumer<BrainHealthProvider>(
              builder: (context, brainHealthProvider, child) {
                return Container(
                  margin: EdgeInsets.only(right: 8),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBrainHealthColor(
                            brainHealthProvider.preventionLevel)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.psychology,
                        color: _getBrainHealthColor(
                            brainHealthProvider.preventionLevel),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${brainHealthProvider.brainHealthScore}',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _getBrainHealthColor(
                              brainHealthProvider.preventionLevel),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: _buildUserProfileButton(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_on),
            label: 'Game',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'Brain Health',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Test',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.black87),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileButton() {
    if (_user == null) {
      return IconButton(
        icon: Icon(Icons.login, color: Colors.black87, size: 20),
        onPressed: () => _showSignInDialog(context),
        tooltip: 'Sign In',
      );
    }

    return InkWell(
      onTap: () => _showAccountEditDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              instagramGradientStart.withOpacity(0.1),
              instagramGradientEnd.withOpacity(0.1)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _nickname ?? 'User',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: instagramGradientEnd,
          ),
        ),
      ),
    );
  }

  void _showAccountEditDialog(BuildContext context) {
    final TextEditingController nicknameController =
        TextEditingController(text: _nickname);
    final TextEditingController ageController =
        TextEditingController(text: _userAge?.toString());

    String? selectedGender = _userGender;
    String? selectedCountryCode = _userCountryCode;
    Country? selectedCountry;

    // 국가 코드에 해당하는 Country 객체 찾기
    if (_userCountryCode != null) {
      selectedCountry = countries.firstWhere(
        (country) => country.code == _userCountryCode,
        orElse: () => countries.first, // null 대신 기본값 반환
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(24),
                  width: 350,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: nicknameController,
                        decoration: InputDecoration(
                          labelText: 'Nickname',
                          hintText: 'Enter your nickname',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Age',
                          hintText: 'Enter your age',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Gender selection
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedGender == null
                                  ? 'Select Gender'
                                  : 'Gender: $selectedGender',
                              style: TextStyle(
                                color: selectedGender == null
                                    ? Colors.grey[600]
                                    : Colors.black,
                                fontWeight: selectedGender == null
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedGender = 'Male';
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: selectedGender == 'Male'
                                              ? [
                                                  Colors.blue.shade700,
                                                  Colors.blue.shade500
                                                ]
                                              : [Colors.white, Colors.white],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: selectedGender == 'Male'
                                            ? [
                                                BoxShadow(
                                                  color: Colors.blue.shade700
                                                      .withOpacity(0.3),
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                )
                                              ]
                                            : [],
                                        border: Border.all(
                                          color: selectedGender == 'Male'
                                              ? Colors.blue.shade700
                                              : Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.male,
                                            size: 18,
                                            color: selectedGender == 'Male'
                                                ? Colors.white
                                                : Colors.blue.shade700,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Male',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: selectedGender == 'Male'
                                                  ? Colors.white
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedGender = 'Female';
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: selectedGender == 'Female'
                                              ? [
                                                  Colors.pink.shade700,
                                                  Colors.pink.shade500
                                                ]
                                              : [Colors.white, Colors.white],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: selectedGender == 'Female'
                                            ? [
                                                BoxShadow(
                                                  color: Colors.pink.shade700
                                                      .withOpacity(0.3),
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                )
                                              ]
                                            : [],
                                        border: Border.all(
                                          color: selectedGender == 'Female'
                                              ? Colors.pink.shade700
                                              : Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.female,
                                            size: 18,
                                            color: selectedGender == 'Female'
                                                ? Colors.white
                                                : Colors.pink.shade700,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Female',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: selectedGender == 'Female'
                                                  ? Colors.white
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      // Country selection
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    selectedCountry == null
                                        ? 'Select Country'
                                        : 'Country: ${selectedCountry!.name}',
                                    style: TextStyle(
                                      color: selectedCountry == null
                                          ? Colors.grey[600]
                                          : Colors.black,
                                      fontWeight: selectedCountry == null
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (selectedCountry != null)
                                  Flag.fromString(
                                    selectedCountry!.code,
                                    height: 24,
                                    width: 32,
                                    borderRadius: 4,
                                  ),
                              ],
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                _showCountrySelectionDialog(dialogContext,
                                    (Country country) {
                                  setState(() {
                                    selectedCountry = country;
                                    selectedCountryCode = country.code;
                                  });
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.purple,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side:
                                      BorderSide(color: Colors.purple.shade200),
                                ),
                              ),
                              child: Text('Change Country'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_user != null &&
                                    nicknameController.text.isNotEmpty &&
                                    ageController.text.isNotEmpty &&
                                    selectedGender != null &&
                                    selectedCountryCode != null) {
                                  try {
                                    // 로딩 대화상자 표시
                                    showDialog(
                                      context: dialogContext,
                                      barrierDismissible: false,
                                      builder: (BuildContext loadingContext) {
                                        return Dialog(
                                          child: Padding(
                                            padding: const EdgeInsets.all(20.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CircularProgressIndicator(),
                                                SizedBox(width: 20),
                                                Text("Updating profile..."),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );

                                    // 프로필 업데이트
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(_user!.uid)
                                        .update({
                                      'nickname': nicknameController.text,
                                      'age': int.parse(ageController.text),
                                      'gender': selectedGender,
                                      'country': selectedCountryCode,
                                    });

                                    // UI 업데이트
                                    setState(() {
                                      _nickname = nicknameController.text;
                                      _userAge = int.parse(ageController.text);
                                      _userGender = selectedGender;
                                      _userCountryCode = selectedCountryCode;
                                    });

                                    // 로딩 다이얼로그 닫기
                                    Navigator.of(dialogContext).pop();

                                    // 프로필 편집 다이얼로그 닫기
                                    Navigator.of(dialogContext).pop();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Profile updated successfully')),
                                    );
                                  } catch (e) {
                                    // 로딩 다이얼로그가 열려있으면 닫기
                                    Navigator.of(dialogContext).pop();

                                    print('Error updating profile: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Failed to update profile')),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(dialogContext)
                                      .showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Please fill in all fields')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text('Update Profile'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _showSignOutConfirmDialog(context);
                        },
                        icon: Icon(Icons.logout, size: 18),
                        label: Text('Sign Out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: Colors.red.shade200),
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCountrySelectionDialog(
      BuildContext context, Function(Country) onSelect) {
    TextEditingController searchController = TextEditingController();
    List<Country> filteredCountries = List.from(countries);

    void filterCountries(String query) {
      if (query.trim().isEmpty) {
        filteredCountries = List.from(countries);
      } else {
        filteredCountries = countries
            .where((country) =>
                country.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 300,
                height: 450,
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Select Country',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search country...',
                        prefixIcon: Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          filterCountries(value);
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredCountries.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: Flag.fromString(
                              filteredCountries[index].code,
                              height: 24,
                              width: 32,
                              borderRadius: 4,
                            ),
                            title: Text(filteredCountries[index].name),
                            onTap: () {
                              onSelect(filteredCountries[index]);
                              Navigator.of(dialogContext).pop();
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSignOutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.shade50,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 40,
                    color: Colors.red.shade400,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Sign Out',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Are you sure you want to sign out?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _signOut();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.red.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Sign Out',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSignInDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _signIn(
                      context, emailController.text, passwordController.text),
                  child: Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showSignUpDialog(context);
                  },
                  child: Text('Don\'t have an account? Sign Up'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signIn(
      BuildContext context, String email, String password) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // _initializeAuth를 통해 상태가 업데이트됨
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in successful')),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during sign in.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
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

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purple.shade50,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: Colors.purple.shade400,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Login Required',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Please sign in to play the Memory Game',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showSignInDialog(context);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.purple.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPlayerSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Number of Players',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [1, 2].map((int value) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            numberOfPlayers = value;
                            currentPlayerIndex = 0;
                            resetScores();
                          });
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: value == numberOfPlayers
                                  ? [Color(0xFF833AB4), Color(0xFFF77737)]
                                  : [
                                      Colors.grey.shade200,
                                      Colors.grey.shade300
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person,
                                size: 30,
                                color: value == numberOfPlayers
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                              SizedBox(height: 4),
                              Text(
                                '$value Player${value > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: value == numberOfPlayers
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [3, 4].map((int value) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            numberOfPlayers = value;
                            currentPlayerIndex = 0;
                            resetScores();
                          });
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: value == numberOfPlayers
                                  ? [Color(0xFF833AB4), Color(0xFFF77737)]
                                  : [
                                      Colors.grey.shade200,
                                      Colors.grey.shade300
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person,
                                size: 30,
                                color: value == numberOfPlayers
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                              SizedBox(height: 4),
                              Text(
                                '$value Player${value > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: value == numberOfPlayers
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF833AB4), Color(0xFFF77737)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGridSizeSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Grid Size',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['4x4', '6x4'].map((String value) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            gridSize = value;
                          });
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: value == gridSize
                                  ? [Color(0xFF833AB4), Color(0xFFF77737)]
                                  : [
                                      Colors.grey.shade200,
                                      Colors.grey.shade300
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.grid_4x4,
                                size: 36,
                                color: value == gridSize
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                              SizedBox(height: 8),
                              Text(
                                value,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: value == gridSize
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '×${getGridSizeMultiplier(value)} points',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: value == gridSize
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['6x6', '8x6'].map((String value) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            gridSize = value;
                          });
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: value == gridSize
                                  ? [Color(0xFF833AB4), Color(0xFFF77737)]
                                  : [
                                      Colors.grey.shade200,
                                      Colors.grey.shade300
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.grid_on,
                                size: 36,
                                color: value == gridSize
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                              SizedBox(height: 8),
                              Text(
                                value,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: value == gridSize
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '×${getGridSizeMultiplier(value)} points',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: value == gridSize
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF833AB4), Color(0xFFF77737)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSignUpDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController nicknameController = TextEditingController();
    final TextEditingController ageController = TextEditingController();
    final TextEditingController countrySearchController =
        TextEditingController();

    String? selectedGender;
    Country? selectedCountry;
    List<Country> filteredCountries = List.from(countries);

    // Clean up the controllers when the dialog is closed
    void dispose() {
      emailController.dispose();
      passwordController.dispose();
      nicknameController.dispose();
      ageController.dispose();
      countrySearchController.dispose();
    }

    // Filter countries based on search text
    void filterCountries(String query) {
      if (query.trim().isEmpty) {
        filteredCountries = List.from(countries);
      } else {
        filteredCountries = countries
            .where((country) =>
                country.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(20),
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: nicknameController,
                        decoration: InputDecoration(
                          hintText: 'Nickname',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Age',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      // Gender selection
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedGender == null
                                  ? 'Select Gender'
                                  : 'Gender: $selectedGender',
                              style: TextStyle(
                                color: selectedGender == null
                                    ? Colors.grey[600]
                                    : Colors.black,
                                fontWeight: selectedGender == null
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedGender = 'Male';
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: selectedGender == 'Male'
                                              ? [
                                                  Colors.blue.shade700,
                                                  Colors.blue.shade500
                                                ]
                                              : [Colors.white, Colors.white],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: selectedGender == 'Male'
                                            ? [
                                                BoxShadow(
                                                  color: Colors.blue.shade700
                                                      .withOpacity(0.3),
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                )
                                              ]
                                            : [],
                                        border: Border.all(
                                          color: selectedGender == 'Male'
                                              ? Colors.blue.shade700
                                              : Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.male,
                                            size: 18,
                                            color: selectedGender == 'Male'
                                                ? Colors.white
                                                : Colors.blue.shade700,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Male',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: selectedGender == 'Male'
                                                  ? Colors.white
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedGender = 'Female';
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: selectedGender == 'Female'
                                              ? [
                                                  Colors.pink.shade700,
                                                  Colors.pink.shade500
                                                ]
                                              : [Colors.white, Colors.white],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: selectedGender == 'Female'
                                            ? [
                                                BoxShadow(
                                                  color: Colors.pink.shade700
                                                      .withOpacity(0.3),
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                )
                                              ]
                                            : [],
                                        border: Border.all(
                                          color: selectedGender == 'Female'
                                              ? Colors.pink.shade700
                                              : Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.female,
                                            size: 18,
                                            color: selectedGender == 'Female'
                                                ? Colors.white
                                                : Colors.pink.shade700,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Female',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: selectedGender == 'Female'
                                                  ? Colors.white
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      // Country search field
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedCountry == null
                                  ? 'Select Country'
                                  : 'Country: ${selectedCountry!.name}',
                              style: TextStyle(
                                color: selectedCountry == null
                                    ? Colors.grey[600]
                                    : Colors.black,
                                fontWeight: selectedCountry == null
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextField(
                              controller: countrySearchController,
                              decoration: InputDecoration(
                                hintText: 'Search country...',
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: Icon(Icons.search, size: 20),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  filterCountries(value);
                                });
                              },
                            ),
                            SizedBox(height: 8),
                            Container(
                              constraints: BoxConstraints(
                                maxHeight: 150,
                              ),
                              child: filteredCountries.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'No countries found',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: filteredCountries.length,
                                      itemBuilder: (context, index) {
                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              selectedCountry =
                                                  filteredCountries[index];
                                              countrySearchController.clear();
                                              filterCountries('');
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 8,
                                              horizontal: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Colors.grey[300]!,
                                                  width: 0.5,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Flag.fromString(
                                                  filteredCountries[index].code,
                                                  height: 16,
                                                  width: 24,
                                                  borderRadius: 4,
                                                ),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    filteredCountries[index]
                                                        .name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (selectedGender == null) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                  content: Text('Please select your gender')),
                            );
                            return;
                          }
                          if (selectedCountry == null) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                  content: Text('Please select your country')),
                            );
                            return;
                          }
                          if (ageController.text.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('Please enter your age')),
                            );
                            return;
                          }
                          _signUp(
                            dialogContext,
                            emailController.text,
                            passwordController.text,
                            nicknameController.text,
                            int.tryParse(ageController.text) ?? 0,
                            selectedGender!,
                            selectedCountry!.code,
                          );
                        },
                        child: Text('Create Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) => dispose()); // Clean up controllers when dialog is closed
  }

  Future<void> _signUp(
    BuildContext context,
    String email,
    String password,
    String nickname,
    int age,
    String gender,
    String countryCode,
  ) async {
    // 로딩 대화상자 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Creating account..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Firebase 인증으로 사용자 생성
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      Map<String, dynamic> userData = {
        'email': email,
        'nickname': nickname,
        'age': age,
        'gender': gender,
        'country': countryCode,
        'language': 'en',
      };

      // Firestore에 사용자 데이터 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData);

      // 로딩 대화상자 닫기
      Navigator.of(context).pop();

      // 회원가입 대화상자 닫기
      Navigator.of(context).pop();

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account created successfully.')),
      );

      // 인증 상태를 강제로 새로고침하여 UI 업데이트 촉진
      _initializeAuth();
    } on FirebaseAuthException catch (e) {
      // 로딩 대화상자 닫기
      Navigator.of(context).pop();

      String errorMessage = 'An error occurred during account creation.';
      if (e.code == 'weak-password') {
        errorMessage = 'The password is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The email address is already in use.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is invalid.';
      }

      print('Firebase Auth Error: ${e.code} - ${e.message}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      // 로딩 대화상자 닫기
      Navigator.of(context).pop();

      print('Signup error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An error occurred during account creation: $e')),
      );
    }
  }
}
