import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flag/flag.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
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
    Timestamp? userBirthday,
    String? shortPW,
  }) async {
    final TextEditingController nicknameController =
        TextEditingController(text: nickname);
    final TextEditingController birthdayController = TextEditingController();
    final TextEditingController shortPasswordController =
        TextEditingController(text: shortPW);
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    // Set initial birthday
    DateTime? selectedBirthday;
    if (userBirthday != null) {
      selectedBirthday = userBirthday.toDate();
      birthdayController.text =
          DateFormat('yyyy-MM-dd').format(selectedBirthday);
    } else if (userAge != null) {
      // Approximate birthday from age
      selectedBirthday = DateTime(DateTime.now().year - userAge, 1, 1);
      birthdayController.text =
          DateFormat('yyyy-MM-dd').format(selectedBirthday);
    }

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
            birthdayController: birthdayController,
            shortPasswordController: shortPasswordController,
            currentPasswordController: currentPasswordController,
            newPasswordController: newPasswordController,
            confirmPasswordController: confirmPasswordController,
            selectedBirthday: selectedBirthday,
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
  final TextEditingController birthdayController;
  final TextEditingController shortPasswordController;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final DateTime? selectedBirthday;
  final String? selectedGender;
  final String? selectedCountryCode;
  final Country? selectedCountry;
  final String? shortPasswordError;
  final String? passwordError;
  final bool showPasswordFields;
  final int? userAge;

  const ProfileEditDialogContent({
    Key? key,
    required this.dialogContext,
    required this.nicknameController,
    required this.birthdayController,
    required this.shortPasswordController,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    this.selectedBirthday,
    this.selectedGender,
    this.selectedCountryCode,
    this.selectedCountry,
    this.shortPasswordError,
    this.passwordError,
    required this.showPasswordFields,
    this.userAge,
  }) : super(key: key);

  @override
  _ProfileEditDialogContentState createState() =>
      _ProfileEditDialogContentState();
}

class _ProfileEditDialogContentState extends State<ProfileEditDialogContent> {
  LanguageProvider? _languageProvider;
  Map<String, String> _translations = {};
  bool _didInitProvider = false;

  DateTime? selectedBirthday;
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
    selectedBirthday = widget.selectedBirthday;
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
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                SizedBox(width: 40), // 왼쪽 공간
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      t('edit_profile'),
                      style: _getTextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(width: 40), // 오른쪽 공간 (로그아웃 버튼 제거)
              ]),

              SizedBox(height: 16),
              TextField(
                controller: widget.nicknameController,
                style: _getTextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: t('nickname'),
                  labelStyle:
                      _getTextStyle(fontSize: 14, color: Colors.grey[600]!),
                  hintText: t('enter_nickname'),
                  hintStyle:
                      _getTextStyle(fontSize: 14, color: Colors.grey[400]!),
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
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: widget.dialogContext,
                    initialDate: selectedBirthday ?? DateTime(2000, 1, 1),
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
                    setState(() {
                      selectedBirthday = picked;
                      widget.birthdayController.text =
                          DateFormat('yyyy-MM-dd').format(picked);
                    });
                  }
                },
                child: TextField(
                  controller: widget.birthdayController,
                  style: _getTextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: t('birthday'),
                    labelStyle:
                        _getTextStyle(fontSize: 14, color: Colors.grey[600]!),
                    hintText: t('select_birthday'),
                    hintStyle:
                        _getTextStyle(fontSize: 14, color: Colors.grey[400]!),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  enabled: false,
                ),
              ),
              SizedBox(height: 16),
              // Gender selection
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('gender'),
                      style: _getTextStyle(
                        fontSize: 14,
                        color: Colors.grey[600]!,
                      ),
                    ),
                    SizedBox(height: 8),
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
                              padding: EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: selectedGender == 'Male'
                                    ? Colors.blue.shade700
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedGender == 'Male'
                                      ? Colors.blue.shade700
                                      : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.male,
                                    size: 18 * _textScaleFactor,
                                    color: selectedGender == 'Male'
                                        ? Colors.white
                                        : Colors.blue.shade700,
                                  ),
                                  SizedBox(width: 4),
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
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                        ),
                                      ),
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
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: selectedGender == 'Female'
                                    ? Colors.pink.shade700
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedGender == 'Female'
                                      ? Colors.pink.shade700
                                      : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.female,
                                    size: 18 * _textScaleFactor,
                                    color: selectedGender == 'Female'
                                        ? Colors.white
                                        : Colors.pink.shade700,
                                  ),
                                  SizedBox(width: 4),
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
                                              ? Colors.white
                                              : Colors.grey.shade700,
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
              SizedBox(height: 16),
              // Country selection
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                ? t('select_country')
                                : '${t('country')}: ${selectedCountry!.name}',
                            style: _getTextStyle(
                              fontSize: 14,
                              color: selectedCountry == null
                                  ? Colors.grey[600]!
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
                            height: 24 * _textScaleFactor,
                            width: 32 * _textScaleFactor,
                            borderRadius: 4,
                          ),
                      ],
                    ),
                    SizedBox(height: 10),
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
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.purple,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.purple.shade200),
                        ),
                      ),
                      child: Text(
                        t('select_country'),
                        style: _getTextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Short Password (PIN)
              TextField(
                controller: widget.shortPasswordController,
                keyboardType: TextInputType.number,
                onChanged: (_) => validateShortPassword(),
                maxLength: 2,
                style: _getTextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: t('multi_game_pin'),
                  labelStyle:
                      _getTextStyle(fontSize: 14, color: Colors.grey[600]!),
                  hintText: t('enter_two_digit_pin'),
                  hintStyle:
                      _getTextStyle(fontSize: 14, color: Colors.grey[400]!),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.pin_outlined),
                  errorText: shortPasswordError,
                  errorStyle: _getTextStyle(fontSize: 12, color: Colors.red),
                  counterText: "",
                  helperText: t('two_digit_pin_helper'),
                  helperStyle: _getTextStyle(
                    fontSize: 12,
                    color: Colors.grey[600]!,
                  ),
                ),
              ),
              SizedBox(height: 16),

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
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t('change_password'),
                        style: _getTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Icon(
                        showPasswordFields
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.black54,
                        size: 24 * _textScaleFactor,
                      ),
                    ],
                  ),
                ),
              ),

              if (showPasswordFields) ...[
                SizedBox(height: 16),
                TextField(
                  controller: widget.currentPasswordController,
                  obscureText: true,
                  onChanged: (_) => validatePassword(),
                  style: _getTextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: t('current_password'),
                    labelStyle:
                        _getTextStyle(fontSize: 14, color: Colors.grey[600]!),
                    hintText: t('enter_current_password'),
                    hintStyle:
                        _getTextStyle(fontSize: 14, color: Colors.grey[400]!),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: widget.newPasswordController,
                  obscureText: true,
                  onChanged: (_) => validatePassword(),
                  style: _getTextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: t('new_password'),
                    labelStyle:
                        _getTextStyle(fontSize: 14, color: Colors.grey[600]!),
                    hintText: t('enter_new_password'),
                    hintStyle:
                        _getTextStyle(fontSize: 14, color: Colors.grey[400]!),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: widget.confirmPasswordController,
                  obscureText: true,
                  onChanged: (_) => validatePassword(),
                  style: _getTextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: t('confirm_password'),
                    labelStyle:
                        _getTextStyle(fontSize: 14, color: Colors.grey[600]!),
                    hintText: t('confirm_new_password'),
                    hintStyle:
                        _getTextStyle(fontSize: 14, color: Colors.grey[400]!),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.check_circle_outline),
                    errorText: passwordError,
                    errorStyle: _getTextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ],

              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(widget.dialogContext).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.grey.shade50,
                        foregroundColor: Colors.grey.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        t('cancel'),
                        style: _getTextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // 저장 로직
                        final result = {
                          'nickname': widget.nicknameController.text,
                          'birthday': selectedBirthday != null
                              ? Timestamp.fromDate(selectedBirthday!)
                              : null,
                          'age': selectedBirthday != null
                              ? (DateTime.now()
                                          .difference(selectedBirthday!)
                                          .inDays /
                                      365)
                                  .floor()
                              : widget.userAge,
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
                        backgroundColor: Colors.purple.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        t('save'),
                        style: _getTextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // 회원 탈퇴 버튼 추가
              ElevatedButton(
                onPressed: () {
                  Navigator.of(widget.dialogContext)
                      .pop({'deleteAccount': true});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade700,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  minimumSize: Size(double.infinity, 48),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_forever,
                      size: 20 * _textScaleFactor,
                    ),
                    SizedBox(width: 8),
                    Text(
                      t('delete_account'),
                      style: _getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              // 로그아웃 버튼을 하단에 추가
              ElevatedButton(
                onPressed: () {
                  Navigator.of(widget.dialogContext).pop({'signOut': true});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade400,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  minimumSize: Size(double.infinity, 48),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout,
                      size: 20 * _textScaleFactor,
                    ),
                    SizedBox(width: 8),
                    Text(
                      t('sign_out'),
                      style: _getTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
