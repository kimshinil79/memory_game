import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flag/flag.dart';
import 'package:provider/provider.dart';
import '../services/memory_game_service.dart';
import '../providers/language_provider.dart';
import 'dart:math' as math;

class PlayerSelectionDialog {
  static Future<List<Map<String, dynamic>>> show(
      BuildContext context, MemoryGameService memoryGameService) {
    // 상위 컨텍스트에서 LanguageProvider 가져오기
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    return showDialog<List<Map<String, dynamic>>>(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        // LanguageProvider를 다이얼로그에 전달
        return ChangeNotifierProvider<LanguageProvider>.value(
          value: languageProvider,
          child:
              PlayerSelectionDialogWidget(memoryGameService: memoryGameService),
        );
      },
    ).then((result) {
      if (result == null) return <Map<String, dynamic>>[];
      return result;
    });
  }
}

class PlayerSelectionDialogWidget extends StatefulWidget {
  final MemoryGameService memoryGameService;

  const PlayerSelectionDialogWidget({
    Key? key,
    required this.memoryGameService,
  }) : super(key: key);

  @override
  _PlayerSelectionDialogWidgetState createState() =>
      _PlayerSelectionDialogWidgetState();
}

class _PlayerSelectionDialogWidgetState
    extends State<PlayerSelectionDialogWidget> {
  final List<Map<String, dynamic>> _selectedUsers = [];
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;
  LanguageProvider? _languageProvider;
  Map<String, String> _translations = {};
  bool _didInitProvider = false; // Provider 초기화 여부 추적

  // 화면 크기 기반 동적 크기 계산
  double get _screenWidth => MediaQuery.of(context).size.width;
  double get _screenHeight => MediaQuery.of(context).size.height;

  // 화면 크기 분류
  bool get _isSmallScreen => _screenWidth < 360 || _screenHeight < 640;
  bool get _isMediumScreen => _screenWidth < 414 || _screenHeight < 736;
  bool get _isLargeScreen => _screenWidth >= 768;

  // 다이얼로그 크기
  double get _dialogWidth =>
      _isLargeScreen ? _screenWidth * 0.5 : _screenWidth * 0.85;
  double get _dialogMaxHeight => _screenHeight * 0.8;
  double get _dialogPadding => _screenWidth * 0.07;
  double get _dialogBorderRadius => _screenWidth * 0.07;

  // 폰트 크기
  double get _titleFontSize => _isSmallScreen
      ? _screenWidth * 0.065
      : _isMediumScreen
          ? _screenWidth * 0.07
          : _screenWidth * 0.075;

  double get _subtitleFontSize => _isSmallScreen
      ? _screenWidth * 0.035
      : _isMediumScreen
          ? _screenWidth * 0.038
          : _screenWidth * 0.04;

  double get _bodyFontSize => _isSmallScreen
      ? _screenWidth * 0.032
      : _isMediumScreen
          ? _screenWidth * 0.035
          : _screenWidth * 0.038;

  double get _buttonFontSize => _isSmallScreen
      ? _screenWidth * 0.035
      : _isMediumScreen
          ? _screenWidth * 0.038
          : _screenWidth * 0.04;

  // 사용자 리스트 관련 크기
  double get _userListHeight => _isSmallScreen
      ? _screenHeight * 0.35
      : _isMediumScreen
          ? _screenHeight * 0.37
          : _screenHeight * 0.4;

  double get _avatarRadius => _isSmallScreen
      ? _screenWidth * 0.055
      : _isMediumScreen
          ? _screenWidth * 0.058
          : _screenWidth * 0.06;

  double get _userItemFontSize => _isSmallScreen
      ? _screenWidth * 0.035
      : _isMediumScreen
          ? _screenWidth * 0.038
          : _screenWidth * 0.04;

  double get _userDetailFontSize => _isSmallScreen
      ? _screenWidth * 0.03
      : _isMediumScreen
          ? _screenWidth * 0.032
          : _screenWidth * 0.035;

  // 버튼 크기
  double get _buttonHeight => _isSmallScreen
      ? _screenHeight * 0.055
      : _isMediumScreen
          ? _screenHeight * 0.058
          : _screenHeight * 0.06;

  // 여백 및 간격
  double get _verticalSpacing => _screenHeight * 0.015;
  double get _horizontalSpacing => _screenWidth * 0.04;

  // 아이콘 크기
  double get _iconSize => _isSmallScreen
      ? _screenWidth * 0.06
      : _isMediumScreen
          ? _screenWidth * 0.065
          : _screenWidth * 0.07;

  // Helper method for creating text styles with dynamic sizing
  TextStyle _getTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black87,
    String? fontFamily,
  }) {
    final style = GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
    return style;
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();

    // 서비스에서 선택된 플레이어 가져오기
    _selectedUsers.addAll(widget.memoryGameService.selectedPlayers);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 첫 번째 didChangeDependencies 호출에서만 Provider 초기화
    if (!_didInitProvider) {
      _initializeLanguageProvider();
      _didInitProvider = true;
    }
  }

  void _initializeLanguageProvider() {
    try {
      _languageProvider = Provider.of<LanguageProvider>(context, listen: false);

      // 사용자 국적에 따른 언어 설정 가져오기
      _languageProvider?.getUserCountryFromFirebase().then((_) {
        if (mounted && _languageProvider != null) {
          setState(() {
            // nationality 기반 UI 언어로 번역 받기
            _translations = _languageProvider!.getUITranslations();
          });
        }
      });
    } catch (e) {
      print('LanguageProvider 초기화 오류: $e');
      // 오류 발생 시 빈 맵 사용
      _translations = {};
    }
  }

  // _languageProvider 안전하게 접근하는 헬퍼 메서드
  Map<String, String> _getTranslations() {
    if (_languageProvider == null) {
      return {};
    }
    // nationality 기반 UI 언어로 번역 받기
    return _languageProvider!.getUITranslations();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // MemoryGameService를 사용하여 사용자 목록 가져오기
      List<Map<String, dynamic>> users =
          await widget.memoryGameService.fetchUsers();

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load users: $e';
        _isLoading = false;
      });
      print('Error fetching users: $e');
    }
  }

  void _toggleUserSelection(Map<String, dynamic> user) {
    setState(() {
      if (_isUserSelected(user)) {
        _selectedUsers
            .removeWhere((selectedUser) => selectedUser['id'] == user['id']);
      } else {
        // Only allow selecting up to 3 users
        if (_selectedUsers.length < 3) {
          _selectedUsers.add(user);
        }
      }
    });
  }

  bool _isUserSelected(Map<String, dynamic> user) {
    return _selectedUsers
        .any((selectedUser) => selectedUser['id'] == user['id']);
  }

  // 각 선택된 유저마다 shortPW를 확인하고 인증하는 메서드
  Future<List<Map<String, dynamic>>> _verifySelectedUsersPin() async {
    try {
      if (_selectedUsers.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> verifiedUsers = [];

      for (var user in _selectedUsers) {
        if (user['id'] == null) continue;

        try {
          // 이미 인증된 플레이어는 건너뛰기
          if (user['verified'] == true) {
            verifiedUsers.add(user);
            continue;
          }

          // Firebase에서 최신 사용자 정보 가져오기
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user['id'])
              .get();

          if (!userDoc.exists) {
            continue;
          }

          Map<String, dynamic>? userData =
              userDoc.data() as Map<String, dynamic>?;
          if (userData == null) continue;

          String? shortPW = userData['shortPW'] as String?;

          if (shortPW == null || shortPW.isEmpty) {
            // shortPW가 없으면 생성 팝업 표시
            bool? created =
                await _showCreatePinDialog(user['nickname'] ?? 'Unknown User');
            if (created != true) {
              return [];
            }
            continue;
          }

          // shortPW 확인 팝업 표시
          bool? verified = await _showVerifyPinDialog(
              user['nickname'] ?? 'Unknown User', shortPW);
          if (verified != true) {
            return [];
          }

          // 인증된 플레이어 표시
          user['verified'] = true;
          verifiedUsers.add(user);
        } catch (e) {
          print('Error verifying user ${user['id']}: $e');
          continue;
        }
      }

      // 선택한 플레이어 목록을 MemoryGameService에 직접 업데이트
      widget.memoryGameService.selectedPlayers = verifiedUsers;
      print('MemoryGameService에 선택된 플레이어 업데이트: ${verifiedUsers.length}명');

      return verifiedUsers;
    } catch (e) {
      print('Error in _verifySelectedUsersPin: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // build 메서드에서는 Provider.of 호출하지 않음
    // 이미 초기화된 _translations 사용

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_dialogBorderRadius),
      ),
      elevation: 10,
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _dialogWidth,
          maxHeight: _dialogMaxHeight,
        ),
        child: Container(
          padding: EdgeInsets.all(_dialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient text
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Color(0xFF833AB4), Color(0xFFF77737)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _translations['select_players'] ?? 'Select Players',
                    style: _getTextStyle(
                      fontSize: _titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: _verticalSpacing),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _translations['select_up_to_3_players'] ??
                      'Select up to 3 other players',
                  style: _getTextStyle(
                    fontSize: _subtitleFontSize,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: _horizontalSpacing,
                    vertical: _verticalSpacing * 0.5),
                margin: EdgeInsets.only(top: _verticalSpacing * 0.5),
                decoration: BoxDecoration(
                  color: Color(0xFF833AB4).withOpacity(0.08),
                  borderRadius:
                      BorderRadius.circular(_dialogBorderRadius * 0.6),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _translations['you_will_be_included'] ??
                        'You will always be included as a player',
                    style: _getTextStyle(
                      fontSize: _bodyFontSize,
                      color: Color(0xFF833AB4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(height: _verticalSpacing * 1.6),
              _buildUsersList(),
              SizedBox(height: _verticalSpacing * 2),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cancel button
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(null),
                      borderRadius:
                          BorderRadius.circular(_dialogBorderRadius * 0.85),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: _buttonHeight * 0.25),
                        height: _buttonHeight,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius:
                              BorderRadius.circular(_dialogBorderRadius * 0.85),
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _translations['cancel'] ?? 'Cancel',
                              style: _getTextStyle(
                                fontSize: _buttonFontSize,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: _horizontalSpacing),
                  // Confirm button
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        // 선택된 유저 목록에 대해 PIN 인증 진행
                        List<Map<String, dynamic>> verifiedUsers =
                            await _verifySelectedUsersPin();
                        // 선택된 플레이어가 없어도 다이얼로그를 닫음
                        Navigator.of(context).pop(verifiedUsers);
                      },
                      borderRadius:
                          BorderRadius.circular(_dialogBorderRadius * 0.85),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: _buttonHeight * 0.25),
                        height: _buttonHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF833AB4), Color(0xFFF77737)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(_dialogBorderRadius * 0.85),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF833AB4).withOpacity(0.3),
                              blurRadius: _screenWidth * 0.025,
                              offset: Offset(0, _screenHeight * 0.006),
                            ),
                          ],
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _translations['confirm'] ?? 'Confirm',
                              style: _getTextStyle(
                                fontSize: _buttonFontSize,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
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

  Widget _buildUsersList() {
    if (_isLoading) {
      return Container(
        height: _userListHeight,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF833AB4)),
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        height: _userListHeight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade400,
                size: _iconSize,
              ),
              SizedBox(height: _verticalSpacing),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _translations['failed_to_load_users'] ??
                      'Failed to load users',
                  style: _getTextStyle(
                    fontSize: _subtitleFontSize,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
              SizedBox(height: _verticalSpacing * 0.5),
              ElevatedButton(
                onPressed: _fetchUsers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF833AB4),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(_dialogBorderRadius * 0.7),
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal: _horizontalSpacing,
                      vertical: _verticalSpacing * 0.5),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _translations['retry'] ?? 'Retry',
                    style: _getTextStyle(
                      fontSize: _bodyFontSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return Container(
        height: _userListHeight,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _translations['no_other_users'] ?? 'No other users found',
              style: _getTextStyle(
                fontSize: _subtitleFontSize,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),
      );
    }

    // Limiting height with a scrollable container
    return Container(
      height: _userListHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(_dialogBorderRadius * 0.7),
        border: Border.all(
            color: Colors.grey.shade200, width: _screenWidth * 0.004),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_dialogBorderRadius * 0.7),
        child: ListView.builder(
          padding: EdgeInsets.all(_screenWidth * 0.01),
          itemCount: _users.length,
          itemBuilder: (context, index) {
            final user = _users[index];
            final isSelected = _isUserSelected(user);

            return Container(
              margin: EdgeInsets.symmetric(
                  vertical: _verticalSpacing * 0.25,
                  horizontal: _horizontalSpacing * 0.5),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [Color(0xFF833AB4), Color(0xFFF77737)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(_dialogBorderRadius * 0.55),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? Color(0xFF833AB4).withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: _screenWidth * 0.015,
                    offset: Offset(0, _screenHeight * 0.004),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _toggleUserSelection(user),
                  borderRadius:
                      BorderRadius.circular(_dialogBorderRadius * 0.55),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: _horizontalSpacing * 0.75,
                        vertical: _verticalSpacing * 0.5),
                    child: Row(
                      children: [
                        // Avatar or profile image
                        CircleAvatar(
                          radius: _avatarRadius,
                          backgroundColor: isSelected
                              ? Colors.white.withOpacity(0.9)
                              : Color(0xFF833AB4).withOpacity(0.1),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              (user['nickname'] as String?)?.isNotEmpty == true
                                  ? (user['nickname'] as String)
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : 'U',
                              style: _getTextStyle(
                                fontSize: _avatarRadius * 0.8,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Color(0xFF833AB4)
                                    : Color(0xFF833AB4),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: _horizontalSpacing * 0.75),
                        // User info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  user['nickname'] as String? ??
                                      (_translations['unknown_player'] ??
                                          'Unknown Player'),
                                  style: _getTextStyle(
                                    fontSize: _userItemFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  if (user['country'] != null)
                                    Container(
                                      margin: EdgeInsets.only(
                                          right: _screenWidth * 0.01),
                                      child: Flag.fromString(
                                        (user['country'] as String)
                                            .toUpperCase(),
                                        height: _screenHeight * 0.012,
                                        width: _screenWidth * 0.04,
                                        borderRadius: 2,
                                      ),
                                    ),
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '${_translations['country'] ?? 'Country'}: ${user['country'] ?? (_translations['unknown'] ?? 'unknown')} ${user['level'] != null ? '• ${_translations['level'] ?? 'Level'} ${user['level']}' : ''}',
                                        style: _getTextStyle(
                                          fontSize: _userDetailFontSize,
                                          color: isSelected
                                              ? Colors.white.withOpacity(0.9)
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Selection indicator
                        Container(
                          width: _avatarRadius * 1.2,
                          height: _avatarRadius * 1.2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade100,
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: Colors.grey.shade300,
                                    width: _screenWidth * 0.005),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: _avatarRadius * 0.9,
                                  color: Color(0xFF833AB4),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 수정된 PIN 인증 다이얼로그
  Future<bool?> _showVerifyPinDialog(String nickname, String correctPin) async {
    TextEditingController pinController = TextEditingController();
    String? pinError;

    // 안전하게 번역 가져오기 - nationality 기반
    final translations = _getTranslations();

    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: translations['multiplayer_verification'] ??
          'Multiplayer Verification',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: StatefulBuilder(
              builder: (context, setState) {
                // 이 컨텍스트에서의 동적 크기 계산
                final dialogWidth = MediaQuery.of(context).size.width;
                final dialogHeight = MediaQuery.of(context).size.height;
                final isSmallDialog = dialogWidth < 360 || dialogHeight < 640;
                final isMediumDialog = dialogWidth < 414 || dialogHeight < 736;

                // PIN 다이얼로그 전용 크기 계산
                final pinDialogWidth = dialogWidth * 0.9;
                final pinDialogPadding = dialogWidth * 0.06;
                final pinDialogBorderRadius = dialogWidth * 0.07;
                final pinTitleFontSize = isSmallDialog
                    ? dialogWidth * 0.045
                    : isMediumDialog
                        ? dialogWidth * 0.048
                        : dialogWidth * 0.05;
                final pinBodyFontSize = isSmallDialog
                    ? dialogWidth * 0.035
                    : isMediumDialog
                        ? dialogWidth * 0.038
                        : dialogWidth * 0.04;
                final pinInputFontSize = isSmallDialog
                    ? dialogWidth * 0.06
                    : isMediumDialog
                        ? dialogWidth * 0.065
                        : dialogWidth * 0.07;
                final pinIconSize = isSmallDialog
                    ? dialogWidth * 0.08
                    : isMediumDialog
                        ? dialogWidth * 0.09
                        : dialogWidth * 0.1;

                TextStyle getDialogTextStyle({
                  required double fontSize,
                  FontWeight fontWeight = FontWeight.normal,
                  Color color = Colors.black87,
                }) {
                  return GoogleFonts.poppins(
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                    color: color,
                  );
                }

                return Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: pinDialogWidth,
                          padding: const EdgeInsets.all(0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(pinDialogBorderRadius),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: dialogWidth * 0.05,
                                offset: Offset(0, dialogHeight * 0.012),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 헤더 부분 (그라데이션 적용)
                              Container(
                                height: dialogHeight * 0.13,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF833AB4),
                                      Color(0xFFF77737)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft:
                                        Radius.circular(pinDialogBorderRadius),
                                    topRight:
                                        Radius.circular(pinDialogBorderRadius),
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.verified_user_rounded,
                                        color: Colors.white,
                                        size: pinIconSize,
                                      ),
                                      SizedBox(height: dialogHeight * 0.01),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          translations[
                                                  'multiplayer_verification'] ??
                                              'Multiplayer Verification',
                                          style: getDialogTextStyle(
                                            fontSize: pinTitleFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // 콘텐츠 부분
                              Padding(
                                padding: EdgeInsets.all(pinDialogPadding),
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(
                                            pinDialogBorderRadius * 0.6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            blurRadius: dialogWidth * 0.02,
                                            offset:
                                                Offset(0, dialogHeight * 0.003),
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.all(
                                          pinDialogPadding * 0.67),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Color(0xFF833AB4)
                                                .withOpacity(0.1),
                                            radius: dialogWidth * 0.05,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                nickname.substring(
                                                    0,
                                                    math.min(
                                                        1, nickname.length)),
                                                style: getDialogTextStyle(
                                                  fontSize: pinTitleFontSize,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF833AB4),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: dialogWidth * 0.03),
                                          Expanded(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                '$nickname${translations['enter_pin_for'] ?? 'Enter PIN for'}',
                                                style: getDialogTextStyle(
                                                  fontSize: pinBodyFontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: dialogHeight * 0.03),
                                    TextField(
                                      controller: pinController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 2,
                                      autofocus: true,
                                      textAlign: TextAlign.center,
                                      style: getDialogTextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: InputDecoration(
                                        counterText: "",
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 16, horizontal: 16),
                                        hintText: "••",
                                        hintStyle: getDialogTextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade300,
                                        ),
                                        errorText: pinError,
                                        errorStyle: getDialogTextStyle(
                                          fontSize: 13,
                                          color: Colors.red.shade400,
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade200,
                                              width: 1),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                              color: Color(0xFF833AB4),
                                              width: 2),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        if (value.length == 2) {
                                          if (value == correctPin) {
                                            Navigator.of(context).pop(true);
                                          } else {
                                            setState(() {
                                              pinError =
                                                  translations['wrong_pin'] ??
                                                      'Wrong PIN';
                                            });
                                          }
                                        } else {
                                          setState(() {
                                            pinError = null;
                                          });
                                        }
                                      },
                                    ),
                                    SizedBox(height: 32),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              side: BorderSide(
                                                  color: Colors.grey.shade300),
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 16),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                translations['cancel'] ??
                                                    'Cancel',
                                                style: getDialogTextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // shortPW 생성 다이얼로그
  Future<bool?> _showCreatePinDialog(String nickname) async {
    TextEditingController pinController = TextEditingController();
    String? pinError;

    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'PIN 번호 생성',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          padding: const EdgeInsets.all(0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 헤더 부분 (그라데이션 적용)
                              Container(
                                height: 110,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF2980B9),
                                      Color(0xFF6DD5FA)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(28),
                                    topRight: Radius.circular(28),
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.pin_rounded,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'PIN 번호 생성',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // 콘텐츠 부분
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor:
                                                    Colors.blue.shade100,
                                                radius: 20,
                                                child: Text(
                                                  nickname.substring(
                                                      0,
                                                      math.min(
                                                          1, nickname.length)),
                                                  style: TextStyle(
                                                    color: Colors.blue.shade700,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  '$nickname님에게 PIN 번호가 없습니다',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            '멀티플레이어를 위한 2자리 PIN 번호를 생성하세요',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 24),
                                    TextField(
                                      controller: pinController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 2,
                                      autofocus: true,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 6,
                                      ),
                                      decoration: InputDecoration(
                                        counterText: "",
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 16, horizontal: 16),
                                        hintText: "••",
                                        hintStyle: GoogleFonts.poppins(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade300,
                                        ),
                                        errorText: pinError,
                                        errorStyle: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.red.shade400,
                                        ),
                                        helperText: "PIN은 숫자 2자리로 설정해주세요",
                                        helperStyle: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade200,
                                              width: 1),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                              color: Colors.blue.shade400,
                                              width: 2),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        // PIN 번호 유효성 검사
                                        if (value.length != 2 ||
                                            !RegExp(r'^[0-9]+$')
                                                .hasMatch(value)) {
                                          setState(() {
                                            pinError = '2자리 숫자를 입력하세요';
                                          });
                                        } else {
                                          setState(() {
                                            pinError = null;
                                          });
                                        }
                                      },
                                    ),
                                    SizedBox(height: 32),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              side: BorderSide(
                                                  color: Colors.grey.shade300),
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 16),
                                            ),
                                            child: Text(
                                              '취소',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
