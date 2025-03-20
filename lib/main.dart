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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/l10n.dart';
import 'l10n/app_localizations.dart';
import 'widgets/player_selection_dialog.dart';
import 'widgets/grid_selection_dialog.dart';
import 'widgets/country_selection_dialog.dart';
import 'widgets/auth/sign_in_dialog.dart';
import 'widgets/auth/sign_up_dialog.dart';
import 'widgets/auth/profile_edit_dialog.dart';
import 'widgets/auth/auth_dialogs.dart';
import 'widgets/buttons/profile_button.dart';
import 'widgets/buttons/control_button.dart';
import 'widgets/dialogs/language_dialog.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 렌더링 최적화 설정
  if (Platform.isAndroid) {
    // 세로 방향 고정 및 시스템 UI 최적화
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    // 렌더링 성능 최적화
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );
  }

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
      supportedLocales: L10n.all,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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

  void _showLanguageSelectionDialog(BuildContext context) {
    LanguageDialog.show(context);
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
        return 3; // Triple points for 6x4 grid
      case '6x6':
        return 5; // 5x points for 6x6 grid
      case '8x6':
        return 8; // 8x points for 8x6 grid
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
                              String countryCode = languageProvider
                                  .currentLanguage
                                  .split('-')
                                  .last
                                  .toLowerCase();
                              return Flag.fromString(
                                countryCode,
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
    return ControlButton(
      icon: icon,
      label: label,
      onTap: onTap,
    );
  }

  Widget _buildUserProfileButton() {
    return ProfileButton(
      user: _user,
      nickname: _nickname,
      onSignInPressed: () => _showSignInDialog(context),
      onProfilePressed: () => _showAccountEditDialog(context),
      gradientStart: instagramGradientStart,
      gradientEnd: instagramGradientEnd,
    );
  }

  void _showAccountEditDialog(BuildContext context) async {
    final result = await ProfileEditDialog.show(
      context,
      nickname: _nickname,
      userAge: _userAge,
      userGender: _userGender,
      userCountryCode: _userCountryCode,
    );

    if (result != null) {
      if (result['signOut'] == true) {
        _showSignOutConfirmDialog(context);
        return;
      }

      try {
        if (_user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .update({
            'nickname': result['nickname'],
            'age': result['age'],
            'gender': result['gender'],
            'country': result['country'],
          });

          setState(() {
            _nickname = result['nickname'];
            _userAge = result['age'];
            _userGender = result['gender'];
            _userCountryCode = result['country'];
          });
        }
      } catch (e) {
        print('Profile update error: $e');
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Failed to update profile. Please try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showSignOutConfirmDialog(BuildContext context) {
    SignOutConfirmDialog.show(context, _signOut);
  }

  void _showSignInDialog(BuildContext context) async {
    final result = await SignInDialog.show(context);
    if (result != null) {
      if (result['signUp'] == true) {
        _showSignUpDialog(context);
        return;
      }

      try {
        final userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: result['email'],
          password: result['password'],
        );

        if (userCredential.user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

          if (userDoc.exists) {
            setState(() {
              _user = userCredential.user;
              _nickname = userDoc.data()?['nickname'];
              _userAge = userDoc.data()?['age'];
              _userGender = userDoc.data()?['gender'];
              _userCountryCode = userDoc.data()?['countryCode'];
            });
          }
        }
      } catch (e) {
        print('Sign in error: $e');
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Failed to sign in. Please check your credentials.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showSignUpDialog(BuildContext context) async {
    final userData = await SignUpDialog.show(context);
    if (userData != null) {
      try {
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: userData['email'],
          password: userData['password'],
        );

        if (userCredential.user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'nickname': userData['nickname'],
            'age': userData['age'],
            'gender': userData['gender'],
            'country': userData['country'],
          });

          setState(() {
            _user = userCredential.user;
            _nickname = userData['nickname'];
            _userAge = userData['age'];
            _userGender = userData['gender'];
            _userCountryCode = userData['country'];
          });
        }
      } catch (e) {
        print('Sign up error: $e');
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Failed to create account. Please try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
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
    LoginRequiredDialog.show(context, () => _showSignInDialog(context));
  }

  void _showPlayerSelectionDialog() async {
    final selectedPlayers =
        await PlayerSelectionDialog.show(context, numberOfPlayers);
    if (selectedPlayers != null) {
      setState(() {
        numberOfPlayers = selectedPlayers;
        currentPlayerIndex = 0;
        resetScores();
      });
    }
  }

  void _showGridSizeSelectionDialog() async {
    final selectedGridSize = await GridSelectionDialog.show(context, gridSize);
    if (selectedGridSize != null) {
      setState(() {
        gridSize = selectedGridSize;
      });
    }
  }
}
