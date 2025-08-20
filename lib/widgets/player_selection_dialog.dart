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

  // 실시간 화면 크기 기반 동적 크기 계산 (고정 분류 제거)
  double get _screenWidth => MediaQuery.of(context).size.width;
  double get _screenHeight => MediaQuery.of(context).size.height;

  // 안전한 크기 계산을 위한 헬퍼 메서드
  double _getProportionalSize(double basePercentage,
      {double minSize = 0, double maxSize = double.infinity}) {
    final calculatedSize = _screenWidth * basePercentage;
    return calculatedSize.clamp(minSize, maxSize);
  }

  double _getProportionalHeight(double basePercentage,
      {double minSize = 0, double maxSize = double.infinity}) {
    final calculatedSize = _screenHeight * basePercentage;
    return calculatedSize.clamp(minSize, maxSize);
  }

  // 다이얼로그 크기 - 화면 비율에 따라 동적 조정
  double get _dialogWidth {
    // 화면 너비가 클수록 다이얼로그 비율을 줄여서 적절한 크기 유지
    if (_screenWidth >= 768) return _screenWidth * 0.5; // 태블릿/폴더블 펼침
    if (_screenWidth >= 414) return _screenWidth * 0.75; // 중간 크기
    return _screenWidth * 0.85; // 작은 화면
  }

  double get _dialogMaxHeight => _screenHeight * 0.8;

  // 패딩 및 테두리 - 화면 크기에 비례 (최소/최대 제한)
  double get _dialogPadding =>
      _getProportionalSize(0.07, minSize: 20, maxSize: 40);
  double get _dialogBorderRadius =>
      _getProportionalSize(0.07, minSize: 20, maxSize: 40);

  // 폰트 크기 - 화면 크기에 비례하여 연속적으로 조정 (최소/최대 제한)
  double get _titleFontSize => _getProportionalSize(0.075,
      minSize: 26, maxSize: 42); // 0.065 → 0.075, 22-38 → 26-42
  double get _subtitleFontSize => _getProportionalSize(0.05,
      minSize: 16, maxSize: 28); // 0.042 → 0.05, 14-24 → 16-28
  double get _bodyFontSize => _getProportionalSize(0.045,
      minSize: 14, maxSize: 26); // 0.038 → 0.045, 12-22 → 14-26
  double get _buttonFontSize => _getProportionalSize(0.05,
      minSize: 16, maxSize: 28); // 0.042 → 0.05, 14-24 → 16-28

  // 사용자 리스트 관련 크기 - 화면 크기에 비례하여 연속적으로 조정
  double get _userListHeight => _getProportionalHeight(0.4,
      minSize: 220, maxSize: 450); // 0.38 → 0.4, 200-400 → 220-450

  double get _avatarRadius => _getProportionalSize(0.065,
      minSize: 24, maxSize: 40); // 0.058 → 0.065, 20-35 → 24-40

  double get _userItemFontSize => _getProportionalSize(0.045,
      minSize: 16, maxSize: 28); // 0.038 → 0.045, 14-24 → 16-28

  double get _userDetailFontSize => _getProportionalSize(0.038,
      minSize: 14, maxSize: 24); // 0.032 → 0.038, 12-20 → 14-24

  // 버튼 크기 - 화면 높이에 비례하여 연속적으로 조정
  double get _buttonHeight => _getProportionalHeight(0.065,
      minSize: 45, maxSize: 70); // 0.058 → 0.065, 40-60 → 45-70

  // 여백 및 간격 - 화면 크기에 비례하여 연속적으로 조정
  double get _verticalSpacing => _getProportionalHeight(0.02,
      minSize: 10, maxSize: 25); // 0.015 → 0.02, 8-20 → 10-25
  double get _horizontalSpacing => _getProportionalSize(0.045,
      minSize: 18, maxSize: 36); // 0.04 → 0.045, 16-32 → 18-36

  // 아이콘 크기 - 화면 너비에 비례하여 연속적으로 조정
  double get _iconSize => _getProportionalSize(0.075,
      minSize: 28, maxSize: 48); // 0.065 → 0.075, 24-40 → 28-48

  // 실제 사용 가능한 공간을 기반으로 한 동적 크기 계산 메서드들
  double _calculateDynamicWidth(
      double availableWidth, Orientation orientation) {
    // 폴더블 화면에서 실제 사용 가능한 공간을 고려한 너비 계산
    if (orientation == Orientation.landscape) {
      // 가로 모드에서는 더 넓게 사용
      if (availableWidth >= 1200) return availableWidth * 0.35; // 대형 폴더블 펼침
      if (availableWidth >= 800) return availableWidth * 0.45; // 중형 폴더블 펼침
      if (availableWidth >= 600) return availableWidth * 0.6; // 작은 폴더블 펼침
      return availableWidth * 0.75; // 일반 가로 모드
    } else {
      // 세로 모드에서는 적당한 비율 사용
      if (availableWidth >= 800) return availableWidth * 0.4; // 폴더블 펼침
      if (availableWidth >= 600) return availableWidth * 0.5; // 중간 크기
      if (availableWidth >= 400) return availableWidth * 0.7; // 일반 스마트폰
      return availableWidth * 0.85; // 작은 스마트폰
    }
  }

  double _calculateDynamicHeight(
      double availableHeight, Orientation orientation) {
    // 폴더블 화면에서 실제 사용 가능한 높이를 고려
    // 위아래 여백을 더 주어 여유로운 레이아웃 구성
    if (orientation == Orientation.landscape) {
      // 가로 모드에서는 높이를 더 적게 사용
      if (availableHeight >= 800)
        return availableHeight * 0.65; // 대형 폴더블 (60% → 65%)
      if (availableHeight >= 600)
        return availableHeight * 0.7; // 중형 폴더블 (65% → 70%)
      return availableHeight * 0.75; // 일반 가로 모드 (70% → 75%)
    } else {
      // 세로 모드에서는 높이를 더 많이 사용
      if (availableHeight >= 1000)
        return availableHeight * 0.75; // 대형 폴더블 (70% → 75%)
      if (availableHeight >= 800)
        return availableHeight * 0.8; // 중형 폴더블 (75% → 80%)
      return availableHeight * 0.85; // 일반 세로 모드 (80% → 85%)
    }
  }

  // 팝업창의 실제 크기를 기반으로 한 동적 UI 요소 크기 계산 메서드들
  double _getDynamicContainerPadding(double dialogWidth) {
    return (dialogWidth * 0.06).clamp(18.0, 36.0);
  }

  double _getDynamicBorderRadius(double dialogWidth) {
    return (dialogWidth * 0.06).clamp(18.0, 36.0);
  }

  double _getDynamicTitleFontSize(double dialogWidth) {
    return (dialogWidth * 0.065).clamp(22.0, 38.0);
  }

  double _getDynamicSubtitleFontSize(double dialogWidth) {
    return (dialogWidth * 0.042).clamp(14.0, 24.0);
  }

  double _getDynamicBodyFontSize(double dialogWidth) {
    return (dialogWidth * 0.038).clamp(12.0, 22.0);
  }

  double _getDynamicButtonFontSize(double containerWidth) {
    return (containerWidth * 0.042).clamp(14.0, 24.0);
  }

  double _getDynamicUserListHeight(double dialogHeight) {
    return (dialogHeight * 0.38).clamp(200.0, 400.0);
  }

  double _getDynamicAvatarRadius(double dialogWidth) {
    return (dialogWidth * 0.058).clamp(20.0, 35.0);
  }

  double _getDynamicUserItemFontSize(double containerWidth) {
    return (containerWidth * 0.045).clamp(16.0, 28.0); // 컨테이너 폭 기반 동적 폰트 크기
  }

  double _getDynamicUserDetailFontSize(double dialogWidth) {
    return (dialogWidth * 0.032).clamp(12.0, 20.0);
  }

  double _getDynamicButtonHeight(double dialogHeight) {
    return (dialogHeight * 0.058).clamp(40.0, 60.0);
  }

  double _getDynamicVerticalSpacing(double dialogHeight) {
    return (dialogHeight * 0.015).clamp(8.0, 20.0);
  }

  double _getDynamicHorizontalSpacing(double dialogWidth) {
    return (dialogWidth * 0.04).clamp(16.0, 32.0);
  }

  double _getDynamicIconSize(double dialogWidth) {
    return (dialogWidth * 0.065).clamp(24.0, 40.0);
  }

  // 리스트 항목 내부 요소들의 동적 크기 계산 메서드들
  double _getDynamicFlagHeight(double containerWidth) {
    return (containerWidth * 0.08).clamp(20.0, 35.0); // 컨테이너 폭의 8%
  }

  double _getDynamicFlagWidth(double containerWidth) {
    return (containerWidth * 0.12).clamp(25.0, 45.0); // 컨테이너 폭의 12%
  }

  double _getDynamicFlagSpacing(double containerWidth) {
    return (containerWidth * 0.03).clamp(8.0, 15.0); // 컨테이너 폭의 3%
  }

  double _getDynamicSelectionButtonSize(double containerWidth) {
    return (containerWidth * 0.15).clamp(30.0, 50.0); // 컨테이너 폭의 15%
  }

  double _getDynamicSelectionIconSize(double containerWidth) {
    return (containerWidth * 0.1).clamp(20.0, 35.0); // 컨테이너 폭의 10%
  }

  // 액션 버튼 관련 동적 크기 계산 메서드들
  double _getDynamicButtonSpacing(double containerWidth) {
    return (containerWidth * 0.04).clamp(16.0, 32.0); // 컨테이너 폭의 4%
  }

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
          child: SingleChildScrollView(
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
                SizedBox(height: _verticalSpacing * 1),
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
                              vertical: _buttonHeight * 0.25,
                              horizontal: _dialogWidth * 0.02), // 가로 패딩 추가
                          height: _buttonHeight,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(
                                _dialogBorderRadius * 0.85),
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _translations['cancel'] ?? 'Cancel',
                                style: _getTextStyle(
                                  fontSize: _getDynamicButtonFontSize(
                                      _dialogWidth), // 동적 폰트 크기
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                        width:
                            _getDynamicButtonSpacing(_dialogWidth)), // 동적 버튼 간격
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
                              vertical: _buttonHeight * 0.25,
                              horizontal: _dialogWidth * 0.02), // 가로 패딩 추가
                          height: _buttonHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF833AB4), Color(0xFFF77737)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(
                                _dialogBorderRadius * 0.85),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF833AB4).withOpacity(0.3),
                                blurRadius: _dialogWidth * 0.025, // 동적 그림자
                                offset:
                                    Offset(0, _dialogWidth * 0.006), // 동적 오프셋
                              ),
                            ],
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _translations['confirm'] ?? 'Confirm',
                                style: _getTextStyle(
                                  fontSize: _getDynamicButtonFontSize(
                                      _dialogWidth), // 동적 폰트 크기
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
                        // User info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (user['country'] != null) ...[
                                    Flag.fromString(
                                      (user['country'] as String).toUpperCase(),
                                      height: _getDynamicFlagHeight(
                                          _dialogWidth), // 컨테이너 폭 기반 동적 높이
                                      width: _getDynamicFlagWidth(
                                          _dialogWidth), // 컨테이너 폭 기반 동적 너비
                                      borderRadius: 3, // 2 → 3, 더 부드러운 모서리
                                    ),
                                    SizedBox(
                                        width: _getDynamicFlagSpacing(
                                            _dialogWidth)), // 컨테이너 폭 기반 동적 간격
                                  ],
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      user['nickname'] as String? ??
                                          (_translations['unknown_player'] ??
                                              'Unknown Player'),
                                      style: _getTextStyle(
                                        fontSize: _getDynamicUserItemFontSize(
                                            _dialogWidth), // 컨테이너 폭 기반 동적 폰트 크기
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey.shade800,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Selection indicator
                        Container(
                          width: _getDynamicSelectionButtonSize(
                              _dialogWidth), // 컨테이너 폭 기반 동적 크기
                          height: _getDynamicSelectionButtonSize(
                              _dialogWidth), // 컨테이너 폭 기반 동적 크기
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade100,
                            border: isSelected
                                ? null
                                : Border.all(
                                    color: Colors.grey.shade300,
                                    width: _dialogWidth *
                                        0.008), // 컨테이너 폭 기반 동적 테두리
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: _getDynamicSelectionIconSize(
                                      _dialogWidth), // 컨테이너 폭 기반 동적 아이콘 크기
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
