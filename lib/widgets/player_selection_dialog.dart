import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flag/flag.dart';
import '../services/memory_game_service.dart';
import 'dart:math' as math;

class PlayerSelectionDialog {
  static Future<List<Map<String, dynamic>>?> show(
      BuildContext context, MemoryGameService memoryGameService) {
    return showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (BuildContext context) {
        return PlayerSelectionDialogWidget(
            memoryGameService: memoryGameService);
      },
    );
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

  @override
  void initState() {
    super.initState();
    _fetchUsers();

    // 서비스에서 선택된 플레이어 가져오기
    _selectedUsers.addAll(widget.memoryGameService.selectedPlayers);
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
  Future<List<Map<String, dynamic>>?> _verifySelectedUsersPin() async {
    if (_selectedUsers.isEmpty) {
      return _selectedUsers;
    }

    List<Map<String, dynamic>> verifiedUsers = [];

    for (var user in _selectedUsers) {
      // Firebase에서 최신 사용자 정보 가져오기
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user['id'])
          .get();

      if (!userDoc.exists) {
        // 사용자 정보가 없으면 스킵
        continue;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? shortPW = userData['shortPW'] as String?;

      if (shortPW == null || shortPW.isEmpty) {
        // shortPW가 없으면 생성 팝업 표시
        bool? created = await _showCreatePinDialog(user['nickname']);
        if (created != true) {
          // 사용자가 취소했으면 처리 중단
          return null;
        }
        continue;
      }

      // shortPW 확인 팝업 표시
      bool? verified = await _showVerifyPinDialog(user['nickname'], shortPW);
      if (verified != true) {
        // 인증 실패 또는 사용자가 취소했으면 처리 중단
        return null;
      }

      verifiedUsers.add(user);
    }

    return verifiedUsers;
  }

  // shortPW 인증 다이얼로그
  Future<bool?> _showVerifyPinDialog(String nickname, String correctPin) async {
    TextEditingController pinController = TextEditingController();
    String? pinError;

    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '멀티플레이어 인증',
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
                                colors: [Color(0xFF833AB4), Color(0xFFF77737)],
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
                                    Icons.verified_user_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '멀티플레이어 인증',
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
                                    color: Colors.grey.shade100,
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
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            Color(0xFF833AB4).withOpacity(0.1),
                                        radius: 20,
                                        child: Text(
                                          nickname.substring(
                                              0, math.min(1, nickname.length)),
                                          style: TextStyle(
                                            color: Color(0xFF833AB4),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '$nickname님의 PIN 번호를 입력하세요',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
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
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                          color: Color(0xFF833AB4), width: 2),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 32),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
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
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (pinController.text ==
                                              correctPin) {
                                            Navigator.of(context).pop(true);
                                          } else {
                                            setState(() {
                                              pinError = '잘못된 PIN 번호입니다';
                                            });
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          elevation: 0,
                                          backgroundColor: Color(0xFF833AB4),
                                          padding: EdgeInsets.symmetric(
                                              vertical: 16),
                                        ),
                                        child: Text(
                                          '확인',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
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
                                colors: [Color(0xFF2980B9), Color(0xFF6DD5FA)],
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
                                              nickname.substring(0,
                                                  math.min(1, nickname.length)),
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
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade200,
                                          width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                          color: Colors.blue.shade400,
                                          width: 2),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    // PIN 번호 유효성 검사
                                    if (value.length != 2 ||
                                        !RegExp(r'^[0-9]+$').hasMatch(value)) {
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
                                            Navigator.of(context).pop(false),
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
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          if (pinController.text.length == 2 &&
                                              RegExp(r'^[0-9]+$').hasMatch(
                                                  pinController.text)) {
                                            // Firebase에 shortPW 저장
                                            try {
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(_selectedUsers
                                                      .firstWhere((u) =>
                                                          u['nickname'] ==
                                                          nickname)['id'])
                                                  .update({
                                                'shortPW': pinController.text
                                              });
                                              Navigator.of(context).pop(true);
                                            } catch (e) {
                                              setState(() {
                                                pinError = '저장 중 오류가 발생했습니다';
                                              });
                                            }
                                          } else {
                                            setState(() {
                                              pinError = '2자리 숫자를 입력하세요';
                                            });
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          elevation: 0,
                                          backgroundColor: Colors.blue.shade500,
                                          padding: EdgeInsets.symmetric(
                                              vertical: 16),
                                        ),
                                        child: Text(
                                          '저장',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
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
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Players',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Select up to 3 other players',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              '(You will always be included as a player)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 16),
            _buildUsersList(),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    // 선택된 플레이어 리스트를 콘솔에 출력
                    if (_selectedUsers.isNotEmpty) {
                      print('선택된 플레이어 목록:');
                      for (var user in _selectedUsers) {
                        print(
                            '- ${user['nickname']} (국가: ${user['country']}, 성별: ${user['gender']}, 나이: ${user['age']}, 점수: ${user['brainHealthScore']})');
                      }
                      print('선택된 플레이어 수: ${_selectedUsers.length}');

                      // 각 플레이어의 PIN 번호 확인
                      final verifiedUsers = await _verifySelectedUsersPin();
                      if (verifiedUsers == null) {
                        // 사용자가 취소했거나 인증 실패
                        return;
                      }

                      // 선택된 플레이어 목록을 MemoryGameService에 저장
                      widget.memoryGameService.selectedPlayers = verifiedUsers;

                      // 다이얼로그 닫고 선택된 플레이어 리스트 반환
                      Navigator.of(context).pop(verifiedUsers);
                    } else {
                      print('플레이어를 선택하지 않음 - 혼자 진행');
                      // 다이얼로그 닫고 선택된 플레이어 리스트 반환
                      Navigator.of(context).pop([]);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF833AB4), Color(0xFFF77737)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Confirm',
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
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    if (_isLoading) {
      return Container(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Container(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 40),
              SizedBox(height: 16),
              Text(
                'Error loading users',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return Container(
        height: 300,
        child: Center(
          child: Text(
            'No users found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 300,
      child: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final isSelected = _isUserSelected(user);
          final countryCode = (user['country'] as String).toUpperCase();
          final brainHealthScore = user['brainHealthScore'] ?? 0;
          final gender = user['gender'] ?? 'unknown';
          final age = user['age'] ?? 0;

          return ListTile(
            onTap: () => _toggleUserSelection(user),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            tileColor: isSelected ? Colors.purple.withOpacity(0.1) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: isSelected
                  ? BorderSide(color: Color(0xFF833AB4), width: 2)
                  : BorderSide(color: Colors.transparent),
            ),
            leading: Flag.fromString(
              countryCode,
              height: 30,
              width: 40,
              borderRadius: 4,
              flagSize: FlagSize.size_4x3,
              fit: BoxFit.cover,
            ),
            title: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: user['nickname'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Color(0xFF833AB4) : Colors.black87,
                    ),
                  ),
                  TextSpan(
                    text: ' (${brainHealthScore})',
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      color:
                          isSelected ? Color(0xFF833AB4) : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            subtitle: Text(
              '${gender.toUpperCase()}, ${age} years, ${countryCode}',
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Color(0xFF833AB4) : Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: Color(0xFF833AB4))
                : null,
          );
        },
      ),
    );
  }
}
