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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
  User? _user;
  String? _nickname;
  StreamSubscription<User?>? _authSubscription;

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

      if (mounted) {
        setState(() {
          _user = user;
          _nickname = userDoc.exists ? userDoc['nickname'] : null;
        });
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      if (mounted) {
        setState(() {
          _user = user;
          _nickname = null;
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

        // Check if new document already exists
        DocumentSnapshot newUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(newDocumentId)
            .get();

        // Check old document
        DocumentSnapshot oldUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(oldDocumentId)
            .get();

        // If new document doesn't exist but old does, migrate data
        if (!newUserDoc.exists && oldUserDoc.exists) {
          // Copy old data
          Map<String, dynamic> userData =
              oldUserDoc.data() as Map<String, dynamic>;

          // Save to new document
          await FirebaseFirestore.instance
              .collection('users')
              .doc(newDocumentId)
              .set(userData);

          print(
              'User data migrated from old ID ($oldDocumentId) to new ID ($newDocumentId)');
        }
      }
    } catch (e) {
      print('Error during data migration: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      // UI에서 로그아웃 상태 먼저 반영
      setState(() {
        _user = null;
        _nickname = null;
      });

      // 그 다음 Firebase 로그아웃 실행
      await FirebaseAuth.instance.signOut();

      // MemoryGamePage 리셋 (필요시)
      setState(() {
        _memoryGameKey = UniqueKey();
      });
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out. Please try again.')),
      );

      // 에러 발생시 현재 사용자 정보 다시 확인
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', languageCode);
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    languageProvider.setLanguage(languageCode);
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
      'pt-BR': 'Portuguese (Brazil)',
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
      'lv-LV': 'Latvian (Latviešu)',
      'et-EE': 'Estonian (Eesti)',
      'is-IS': 'Icelandic (Íslenska)',
      'ca-ES': 'Catalan (Català)',
      'eu-ES': 'Basque (Euskara)',
      'gl-ES': 'Galician (Galego)',
      'cy-GB': 'Welsh (Cymraeg)',

      // 중동어
      'ar-SA': 'Arabic (Saudi Arabia) (العربية)',
      'fa-IR': 'Persian (فارسی)',
      'he-IL': 'Hebrew (עברית)',
      'tr-TR': 'Turkish (Türkçe)',

      // 기타 지역어
      'az-AZ': 'Azerbaijani (Azərbaycan)',
      'be-BY': 'Belarusian (Беларуская)',
      'hy-AM': 'Armenian (Հայերեն)',
      'ka-GE': 'Georgian (ქართული)',
      'kk-KZ': 'Kazakh (Қазақ)',
      'ky-KG': 'Kyrgyz (Кыргызча)',
      'mk-MK': 'Macedonian (Македонски)',
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
          code.startsWith('ta') ||
          code.startsWith('te') ||
          code.startsWith('ml') ||
          code.startsWith('gu') ||
          code.startsWith('kn') ||
          code.startsWith('mr') ||
          code.startsWith('pa')) {
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
      playerScores[player] = score;
    });
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
    List<Widget> _pages = [
      MemoryGamePage(
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
      ),
      TestPage(),
      BrainHealthPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: _currentIndex == 0 ? 100 : 70,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Memory Game',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _showLanguageSelectionDialog(context),
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Consumer<LanguageProvider>(
                      builder: (context, languageProvider, child) {
                        return Flag.fromString(
                          _getCountryCode(languageProvider.currentLanguage),
                          height: 20,
                          width: 20,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (_currentIndex == 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      icon: Icon(Icons.people, size: 16),
                      label: Text(
                          '$numberOfPlayers Player${numberOfPlayers > 1 ? 's' : ''}'),
                      onPressed: _showPlayerSelectionDialog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.purple.shade200),
                        visualDensity: VisualDensity.compact,
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: Icon(Icons.grid_on, size: 16),
                      label: Text(gridSize),
                      onPressed: _showGridSizeSelectionDialog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.purple.shade200),
                        visualDensity: VisualDensity.compact,
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flip, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '$flipCount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          if (_currentIndex == 2)
            Consumer<BrainHealthProvider>(
              builder: (context, brainHealthProvider, child) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: _getBrainHealthColor(
                            brainHealthProvider.preventionLevel),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${brainHealthProvider.brainHealthScore}',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _getBrainHealthColor(
                              brainHealthProvider.preventionLevel),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          // Add login/logout button
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: _buildUserProfileButton(),
          ),
        ],
      ),
      body: _pages[_currentIndex],
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
            icon: Icon(Icons.games),
            label: 'Game',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Test',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'Brain Health',
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileButton() {
    if (_user == null) {
      return IconButton(
        icon: Icon(Icons.login, color: Colors.black),
        onPressed: () => _showSignInDialog(context),
        tooltip: 'Sign In',
      );
    } else {
      return InkWell(
        onTap: () => _showAccountEditDialog(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.purple),
              SizedBox(width: 4),
              Text(
                _nickname ?? 'User',
                style: TextStyle(
                  color: Colors.purple.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showAccountEditDialog(BuildContext context) {
    final TextEditingController nicknameController =
        TextEditingController(text: _nickname);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.purple.shade100,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.purple.shade700,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Account Settings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  _user?.email ?? 'No email',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 24),
                TextField(
                  controller: nicknameController,
                  decoration: InputDecoration(
                    labelText: 'Nickname',
                    hintText: 'Enter your nickname',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_user != null &&
                              nicknameController.text.isNotEmpty) {
                            try {
                              // 닉네임 업데이트
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(_user!.uid)
                                  .update(
                                      {'nickname': nicknameController.text});

                              // UI 업데이트
                              setState(() {
                                _nickname = nicknameController.text;
                              });

                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Profile updated successfully')),
                              );
                            } catch (e) {
                              print('Error updating profile: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Failed to update profile')),
                              );
                            }
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
                    Navigator.of(context).pop();
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
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSignOutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sign Out'),
          content: Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _signOut();
              },
              child: Text('Sign Out', style: TextStyle(color: Colors.red)),
            ),
          ],
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

  void _showSignUpDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController nicknameController = TextEditingController();

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
                  onPressed: () => _signUp(
                    context,
                    emailController.text,
                    passwordController.text,
                    nicknameController.text,
                  ),
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
        );
      },
    );
  }

  Future<void> _signUp(BuildContext context, String email, String password,
      String nickname) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': email,
        'nickname': nickname,
        'language': 'en',
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account created successfully.')),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during account creation.';
      if (e.code == 'weak-password') {
        errorMessage = 'The password is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The email address is already in use.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is invalid.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('An error occurred during account creation: $e')),
      );
    }
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
}
