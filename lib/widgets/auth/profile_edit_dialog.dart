import 'package:flutter/material.dart';
import 'package:flag/flag.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/countries.dart';
import '../country_selection_dialog.dart';
import '../../providers/language_provider.dart';

class ProfileEditDialog {
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String? nickname,
    required int? userAge,
    required String? userGender,
    required String? userCountryCode,
    String? shortPW,
  }) async {
    final TextEditingController nicknameController =
        TextEditingController(text: nickname);
    final TextEditingController shortPasswordController =
        TextEditingController(text: shortPW);
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    String? selectedGender = userGender;
    String? selectedCountryCode = userCountryCode;
    Country? selectedCountry;
    String? shortPasswordError;
    String? passwordError;
    bool showPasswordFields = false;

    // 국가 코드에 해당하는 Country 객체 찾기
    if (userCountryCode != null) {
      selectedCountry = countries.firstWhere(
        (country) => country.code == userCountryCode,
        orElse: () => countries.first,
      );
    }
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    // 사용자의 국적 정보 로드 - 비동기 작업 완료 대기
    await languageProvider.getUserCountryFromFirebase();

    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (BuildContext dialogContext) {
        // 다이얼로그 위젯 트리에 LanguageProvider를 전달합니다
        return ChangeNotifierProvider.value(
          value: languageProvider,
          child: ProfileEditDialogContent(
            dialogContext: dialogContext,
            nicknameController: nicknameController,
            shortPasswordController: shortPasswordController,
            currentPasswordController: currentPasswordController,
            newPasswordController: newPasswordController,
            confirmPasswordController: confirmPasswordController,
            selectedGender: selectedGender,
            selectedCountryCode: selectedCountryCode,
            selectedCountry: selectedCountry,
            shortPasswordError: shortPasswordError,
            passwordError: passwordError,
            showPasswordFields: showPasswordFields,
            userAge: userAge,
          ),
        );
      },
    );
  }
}

class ProfileEditDialogContent extends StatefulWidget {
  final BuildContext dialogContext;
  final TextEditingController nicknameController;
  final TextEditingController shortPasswordController;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final String? selectedGender;
  final String? selectedCountryCode;
  final Country? selectedCountry;
  final String? shortPasswordError;
  final String? passwordError;
  final bool showPasswordFields;
  final int? userAge;

  const ProfileEditDialogContent({
    super.key,
    required this.dialogContext,
    required this.nicknameController,
    required this.shortPasswordController,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    this.selectedGender,
    this.selectedCountryCode,
    this.selectedCountry,
    this.shortPasswordError,
    this.passwordError,
    required this.showPasswordFields,
    this.userAge,
  });

  @override
  _ProfileEditDialogContentState createState() =>
      _ProfileEditDialogContentState();
}

class _ProfileEditDialogContentState extends State<ProfileEditDialogContent> {
  LanguageProvider? _languageProvider;
  Map<String, String> _translations = {};
  bool _didInitProvider = false;

  String? selectedGender;
  String? selectedCountryCode;
  Country? selectedCountry;
  String? shortPasswordError;
  String? passwordError;
  bool showPasswordFields = false;
  bool passwordChanged = false;

  // Define text scale factor for dynamic text sizing
  double get _textScaleFactor {
    final width = MediaQuery.of(context).size.width;
    // Adjust these breakpoints as needed
    if (width < 360) return 0.8;
    if (width < 400) return 0.9;
    return 1.0;
  }

  // Helper method for creating text styles with dynamic sizing
  TextStyle _getTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black87,
  }) {
    return TextStyle(
      fontSize: fontSize * _textScaleFactor,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  void initState() {
    super.initState();

    // 초기 상태 복사
    selectedGender = widget.selectedGender;
    selectedCountryCode = widget.selectedCountryCode;
    selectedCountry = widget.selectedCountry;
    shortPasswordError = widget.shortPasswordError;
    passwordError = widget.passwordError;
    showPasswordFields = widget.showPasswordFields;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Provider 초기화 (첫 번째 didChangeDependencies 호출에서만)
    if (!_didInitProvider) {
      _initializeLanguageProvider();
      _didInitProvider = true;
    }
  }

  void _initializeLanguageProvider() {
    try {
      _languageProvider = Provider.of<LanguageProvider>(context, listen: false);

      // 번역 데이터 업데이트 - nationality 기반 UI 언어 사용
      if (_languageProvider != null) {
        _updateTranslations();
      }

      // LanguageProvider의 변경사항을 감지하는 리스너 추가
      _languageProvider?.addListener(_updateTranslations);
    } catch (e) {
      print('LanguageProvider 초기화 오류: $e');
    }
  }

  @override
  void dispose() {
    // 리스너 제거
    _languageProvider?.removeListener(_updateTranslations);
    super.dispose();
  }

  // 번역 업데이트 헬퍼 메서드
  void _updateTranslations() {
    if (_languageProvider != null && mounted) {
      setState(() {
        // nationality 기반 UI 언어로 번역 받기
        _translations = _languageProvider!.getUITranslations();
      });
    }
  }

  // _languageProvider 안전하게 접근하는 헬퍼 메서드 (간편 번역)
  String t(String key) {
    if (_translations.containsKey(key)) {
      return _translations[key]!;
    }
    return key; // 키가 없으면 키 그대로 반환
  }

  // 비밀번호 유효성 검사
  void validatePassword() {
    setState(() {
      if (widget.currentPasswordController.text.isEmpty && showPasswordFields) {
        passwordError = t('current_password_required');
      } else if (widget.newPasswordController.text.length < 6 &&
          widget.newPasswordController.text.isNotEmpty) {
        passwordError = t('password_length_error');
      } else if (widget.newPasswordController.text !=
              widget.confirmPasswordController.text &&
          widget.confirmPasswordController.text.isNotEmpty) {
        passwordError = t('passwords_do_not_match');
      } else {
        passwordError = null;
      }

      // 비밀번호 필드가 채워져 있으면 변경된 것으로 표시
      passwordChanged = widget.newPasswordController.text.isNotEmpty &&
          widget.confirmPasswordController.text.isNotEmpty &&
          widget.currentPasswordController.text.isNotEmpty;
    });
  }

  // 두 자리 PIN 유효성 검사
  void validateShortPassword() {
    setState(() {
      final pin = widget.shortPasswordController.text;
      if (pin.isEmpty) {
        shortPasswordError = null;
      } else if (pin.length != 2 || !RegExp(r'^[0-9]{2}$').hasMatch(pin)) {
        shortPasswordError = t('must_be_two_digit');
      } else {
        shortPasswordError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A0C12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF00D4FF), width: 1.5),
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 350,
          decoration: const BoxDecoration(
            color: Color(0xFF1E2430),
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const SizedBox(width: 40), // 왼쪽 공간
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFF4081), Color(0xFF00D4FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        t('edit_profile'),
                        style: _getTextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                // Settings 버튼을 제목 오른쪽에 배치
                IconButton(
                  icon: const Icon(Icons.settings, color: Color(0xFF00D4FF)),
                  onPressed: () async {
                    final result = await _showSettingsDialog(context);
                    if (result != null && result['deleteAccount'] == true) {
                      // 설정 다이얼로그에서 계정 삭제가 확인되면 프로필 수정 다이얼로그를 닫고 신호를 보냄
                      Navigator.of(widget.dialogContext)
                          .pop({'deleteAccount': true});
                    }
                  },
                ),
              ]),

              const SizedBox(height: 16),
              TextField(
                controller: widget.nicknameController,
                style: _getTextStyle(fontSize: 16, color: Colors.white),
                decoration: InputDecoration(
                  labelText: t('nickname'),
                  labelStyle:
                      _getTextStyle(fontSize: 14, color: const Color(0xFF00D4FF)),
                  hintText: t('enter_nickname'),
                  hintStyle:
                      _getTextStyle(fontSize: 14, color: Colors.grey[400]!),
                  filled: true,
                  fillColor: const Color(0xFF252B3A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFFF4081), width: 2),
                  ),
                  prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF00D4FF)),
                ),
              ),
              const SizedBox(height: 16),
              // Gender selection
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF252B3A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00D4FF), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('gender'),
                      style: _getTextStyle(
                        fontSize: 14,
                        color: const Color(0xFF00D4FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedGender = 'Male';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: selectedGender == 'Male'
                                    ? const Color(0xFF252B3A)
                                    : const Color(0xFF2F3542),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedGender == 'Male'
                                      ? const Color(0xFFFF4081)
                                      : const Color(0xFF00D4FF),
                                  width: selectedGender == 'Male' ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.male,
                                    size: 18 * _textScaleFactor,
                                    color: selectedGender == 'Male'
                                        ? const Color(0xFFFF4081)
                                        : const Color(0xFF00D4FF),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.center,
                                      child: Text(
                                        t('male'),
                                        style: _getTextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: selectedGender == 'Male'
                                              ? const Color(0xFFFF4081)
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                selectedGender = 'Female';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: selectedGender == 'Female'
                                    ? const Color(0xFF252B3A)
                                    : const Color(0xFF2F3542),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedGender == 'Female'
                                      ? const Color(0xFFFF4081)
                                      : const Color(0xFF00D4FF),
                                  width: selectedGender == 'Female' ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.female,
                                    size: 18 * _textScaleFactor,
                                    color: selectedGender == 'Female'
                                        ? const Color(0xFFFF4081)
                                        : const Color(0xFF00D4FF),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.center,
                                      child: Text(
                                        t('female'),
                                        style: _getTextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: selectedGender == 'Female'
                                              ? const Color(0xFFFF4081)
                                              : Colors.white,
                                        ),
                                      ),
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
              const SizedBox(height: 16),
              // Country selection
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF252B3A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00D4FF), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedCountry == null
                                ? t('select_country')
                                : '${t('country')}: ${selectedCountry!.name}',
                            style: _getTextStyle(
                              fontSize: 14,
                              color: selectedCountry == null
                                  ? const Color(0xFF00D4FF)
                                  : Colors.white,
                              fontWeight: selectedCountry == null
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (selectedCountry != null)
                          Flag.fromString(
                            selectedCountry!.code,
                            height: 24 * _textScaleFactor,
                            width: 32 * _textScaleFactor,
                            borderRadius: 4,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final country =
                            await CountrySelectionDialog.show(context);
                        if (country != null) {
                          setState(() {
                            selectedCountry = country;
                            selectedCountryCode = country.code;
                          });

                          // 국가 선택 즉시 LanguageProvider에 반영
                          if (_languageProvider != null) {
                            await _languageProvider!
                                .setNationality(country.code);
                            // 번역 데이터 즉시 업데이트
                            _updateTranslations();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F3542),
                        foregroundColor: const Color(0xFF00D4FF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFF00D4FF)),
                        ),
                      ),
                      child: Text(
                        t('select_country'),
                        style: _getTextStyle(fontSize: 14, color: const Color(0xFF00D4FF), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Short Password (PIN)
              TextField(
                controller: widget.shortPasswordController,
                keyboardType: TextInputType.number,
                onChanged: (_) => validateShortPassword(),
                maxLength: 2,
                style: _getTextStyle(fontSize: 16, color: Colors.white),
                decoration: InputDecoration(
                  labelText: t('multi_game_pin'),
                  labelStyle:
                      _getTextStyle(fontSize: 14, color: const Color(0xFF00D4FF)),
                  hintText: t('enter_two_digit_pin'),
                  hintStyle:
                      _getTextStyle(fontSize: 14, color: Colors.grey[400]!),
                  filled: true,
                  fillColor: const Color(0xFF252B3A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFFF4081), width: 2),
                  ),
                  prefixIcon: const Icon(Icons.pin_outlined, color: Color(0xFF00D4FF)),
                  errorText: shortPasswordError,
                  errorStyle: _getTextStyle(fontSize: 12, color: Colors.red),
                  counterText: "",
                  helperText: t('two_digit_pin_helper'),
                  helperStyle: _getTextStyle(
                    fontSize: 12,
                    color: const Color(0xFF00D4FF),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Change Password Section
              InkWell(
                onTap: () {
                  setState(() {
                    showPasswordFields = !showPasswordFields;

                    // Clear fields and errors when toggling
                    if (!showPasswordFields) {
                      widget.currentPasswordController.clear();
                      widget.newPasswordController.clear();
                      widget.confirmPasswordController.clear();
                      passwordError = null;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252B3A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF00D4FF), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t('change_password'),
                        style: _getTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00D4FF),
                        ),
                      ),
                      Icon(
                        showPasswordFields
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFF00D4FF),
                        size: 24 * _textScaleFactor,
                      ),
                    ],
                  ),
                ),
              ),

              if (showPasswordFields) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: widget.currentPasswordController,
                  obscureText: true,
                  onChanged: (_) => validatePassword(),
                  style: _getTextStyle(fontSize: 16, color: Colors.white),
                  decoration: InputDecoration(
                    labelText: t('current_password'),
                    labelStyle:
                        _getTextStyle(fontSize: 14, color: const Color(0xFF00D4FF)),
                    hintText: t('enter_current_password'),
                    hintStyle:
                        _getTextStyle(fontSize: 14, color: Colors.grey[400]!),
                    filled: true,
                    fillColor: const Color(0xFF252B3A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFFF4081), width: 2),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00D4FF)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: widget.newPasswordController,
                  obscureText: true,
                  onChanged: (_) => validatePassword(),
                  style: _getTextStyle(fontSize: 16, color: Colors.white),
                  decoration: InputDecoration(
                    labelText: t('new_password'),
                    labelStyle:
                        _getTextStyle(fontSize: 14, color: const Color(0xFF00D4FF)),
                    hintText: t('enter_new_password'),
                    hintStyle:
                        _getTextStyle(fontSize: 14, color: Colors.grey[400]!),
                    filled: true,
                    fillColor: const Color(0xFF252B3A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFFF4081), width: 2),
                    ),
                    prefixIcon: const Icon(Icons.vpn_key_outlined, color: Color(0xFF00D4FF)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: widget.confirmPasswordController,
                  obscureText: true,
                  onChanged: (_) => validatePassword(),
                  style: _getTextStyle(fontSize: 16, color: Colors.white),
                  decoration: InputDecoration(
                    labelText: t('confirm_password'),
                    labelStyle:
                        _getTextStyle(fontSize: 14, color: const Color(0xFF00D4FF)),
                    hintText: t('confirm_new_password'),
                    hintStyle:
                        _getTextStyle(fontSize: 14, color: Colors.grey[400]!),
                    filled: true,
                    fillColor: const Color(0xFF252B3A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFFF4081), width: 2),
                    ),
                    prefixIcon: const Icon(Icons.check_circle_outline, color: Color(0xFF00D4FF)),
                    errorText: passwordError,
                    errorStyle: _getTextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(widget.dialogContext).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F3542),
                        foregroundColor: const Color(0xFF00D4FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: const BorderSide(color: Color(0xFF00D4FF)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        t('cancel'),
                        style: _getTextStyle(fontSize: 14, color: const Color(0xFF00D4FF), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // 저장 로직
                        final result = {
                          'nickname': widget.nicknameController.text,
                          'gender': selectedGender,
                          'country': selectedCountryCode,
                          'shortPW': widget.shortPasswordController.text,
                          'passwordChanged': passwordChanged &&
                              showPasswordFields &&
                              widget.newPasswordController.text.isNotEmpty,
                        };
                        Navigator.of(widget.dialogContext).pop(result);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF252B3A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: const BorderSide(color: Color(0xFFFF4081), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        t('save'),
                        style: _getTextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Sign Out 버튼 추가
              ElevatedButton(
                onPressed: () {
                  Navigator.of(widget.dialogContext).pop({'signOut': true});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F3542),
                  foregroundColor: Colors.red.shade400,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.red.shade400),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout,
                      size: 20 * _textScaleFactor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t('sign_out'),
                      style: _getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // 설정 다이얼로그
  Future<Map<String, dynamic>?> _showSettingsDialog(
      BuildContext context) async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final translations = languageProvider.getUITranslations();

    // SharedPreferences에서 현재 푸쉬 알림 설정 읽기
    final prefs = await SharedPreferences.getInstance();
    bool pushNotificationsEnabled =
        prefs.getBool('push_notifications_enabled') ?? true;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0B0D13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF9C27B0), width: 2),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9C27B0).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.settings, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          translations['settings'] ?? 'Settings',
                          style: _getTextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 푸쉬 알림 설정
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E2430), Color(0xFF2A2F3A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF9C27B0).withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9C27B0).withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF00BCD4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  translations['push_notifications'] ??
                                      'Push Notifications',
                                  style: _getTextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  translations['receive_game_notifications'] ??
                                      'Receive game notifications',
                                  style: _getTextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFF00E5FF),
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: pushNotificationsEnabled,
                          onChanged: (value) async {
                            setState(() {
                              pushNotificationsEnabled = value;
                            });
                            // SharedPreferences에 저장
                            await prefs.setBool(
                                'push_notifications_enabled', value);
                          },
                          activeThumbColor: const Color(0xFF00E5FF),
                          activeColor: const Color(0xFF00E5FF).withOpacity(0.3),
                          inactiveThumbColor: const Color(0xFF2A2F3A),
                          inactiveTrackColor: const Color(0xFF1E2430),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 회원탈퇴 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop({'deleteAccount': true});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A2F3A),
                        foregroundColor: Colors.red.shade400,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.red.shade400, width: 2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shadowColor: Colors.red.shade400.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.delete_forever_outlined,
                              size: 18,
                              color: Colors.red.shade400,
                            ),
                          ),
                          const SizedBox(width: 12),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              translations['delete_account'] ??
                                  'Delete Account',
                              style: _getTextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8, right: 8),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2430),
                      foregroundColor: const Color(0xFF9C27B0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF9C27B0), width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        translations['close'] ?? 'Close',
                        style: _getTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9C27B0),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
