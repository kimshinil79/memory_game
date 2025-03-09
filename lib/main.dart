import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tabs/memory_game_page.dart';
import 'tabs/test_page.dart';
import 'tabs/settings_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/language_provider.dart';
import 'package:flag/flag.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
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

  String _getCountryCode(String languageCode) {
    switch (languageCode) {
      case 'ko-KR':
        return 'kr';
      case 'en-US':
        return 'us';
      case 'es-ES':
        return 'es';
      case 'fr-FR':
        return 'fr';
      case 'de-DE':
        return 'de';
      case 'ja-JP':
        return 'jp';
      case 'zh-CN':
        return 'cn';
      case 'ru-RU':
        return 'ru';
      case 'it-IT':
        return 'it';
      case 'pt-PT':
        return 'pt';
      case 'ar-SA':
        return 'sa';
      case 'tr-TR':
        return 'tr';
      case 'vi-VN':
        return 'vn';
      case 'nl-NL':
        return 'nl';
      case 'pl-PL':
        return 'pl';
      case 'cs-CZ':
        return 'cz';
      case 'hu-HU':
        return 'hu';
      default:
        return 'us';
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
    final Map<String, String> languageNames = {
      'mute': '무음',
      'ko-KR': 'Korean',
      'en-US': 'English',
      'es-ES': 'Spanish',
      'fr-FR': 'French',
      'de-DE': 'German',
      'ja-JP': 'Japanese',
      'zh-CN': 'Chinese',
      'ru-RU': 'Russian',
      'it-IT': 'Italian',
      'pt-PT': 'Portuguese',
      'ar-SA': 'Arabic',
      'tr-TR': 'Turkish',
      'vi-VN': 'Vietnamese',
      'nl-NL': 'Dutch',
      'pl-PL': 'Polish',
      'cs-CZ': 'Czech',
      'hu-HU': 'Hungarian'
    };

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 20),
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
                Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: languageNames.length,
                    itemBuilder: (context, index) {
                      String languageCode = languageNames.keys.elementAt(index);
                      String countryName = languageNames[languageCode]!;
                      return Container(
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                            countryName,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Memory Game',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showLanguageSelectionDialog(context),
                  child: Flag.fromString(
                    _getCountryCode(languageProvider.currentLanguage),
                    height: 24,
                    width: 24,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: Icon(Icons.people, color: Colors.black),
              onPressed: _showPlayerSelectionDialog,
            ),
          if (_currentIndex == 0)
            IconButton(
              icon: Icon(Icons.grid_on, color: Colors.black),
              onPressed: _showGridSizeSelectionDialog,
            ),
          if (_currentIndex == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  'Flips: $flipCount',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
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
          ),
          const TestPage(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.games),
            label: 'Game',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Test',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
        showUnselectedLabels: true,
      ),
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
}
