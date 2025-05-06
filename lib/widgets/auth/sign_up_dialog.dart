import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flag/flag.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../data/countries.dart';
import '../country_selection_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Constants for SharedPreferences keys (same as in main.dart)
const String PREF_USER_COUNTRY_CODE = 'user_country_code';

class SignUpDialog {
  static Future<Map<String, dynamic>?> show(BuildContext context) async {
    // Get screen size for responsive layout
    final Size screenSize = MediaQuery.of(context).size;
    // Calculate dialog width based on screen size
    final double dialogWidth =
        screenSize.width > 600 ? 400 : screenSize.width * 0.85;

    // Try to load saved country code from local storage
    String? savedCountryCode = await _loadSavedCountryCode();
    Country? initialCountry;

    // If we have a saved country code, find the corresponding country
    if (savedCountryCode != null) {
      for (var country in countries) {
        if (country.code.toLowerCase() == savedCountryCode.toLowerCase()) {
          initialCountry = country;
          break;
        }
      }
    }

    // Get the language provider from the parent context
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    // Get translations based on the country code
    Map<String, String> translations = {};

    if (savedCountryCode != null &&
        LanguageProvider.countryToLanguageMap
            .containsKey(savedCountryCode.toUpperCase())) {
      // Update the language provider with the saved nationality if any
      await languageProvider.setNationality(savedCountryCode);

      // Get language code from country code
      String languageCode = LanguageProvider
          .countryToLanguageMap[savedCountryCode.toUpperCase()]!;
      // Get translations for that language
      translations = languageProvider.getTranslations(languageCode);
    } else {
      // Default to UI translations if no saved country or mapping
      translations = languageProvider.getUITranslations();
    }

    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    final TextEditingController shortPasswordController =
        TextEditingController();
    final TextEditingController nicknameController = TextEditingController();
    final TextEditingController birthdayController = TextEditingController();

    String? selectedGender;
    Country? selectedCountry = initialCountry;
    String? selectedCountryCode = savedCountryCode;
    String? passwordError;
    String? shortPasswordError;
    DateTime? selectedBirthday;

    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            // Handle country selection
            void selectCountry() async {
              final country = await CountrySelectionDialog.show(dialogContext);
              if (country != null) {
                setState(() {
                  selectedCountry = country;
                  selectedCountryCode = country.code;
                });

                // Update translations for the new country code
                // This is done outside the dialog using the parent context
                if (LanguageProvider.countryToLanguageMap
                    .containsKey(country.code.toUpperCase())) {
                  // Update the language provider in the parent context
                  await languageProvider.setNationality(country.code);

                  // Get the new language code
                  String languageCode = LanguageProvider
                      .countryToLanguageMap[country.code.toUpperCase()]!;
                  // Get updated translations
                  translations = languageProvider.getTranslations(languageCode);

                  // Save selected country to SharedPreferences
                  _saveCountryCode(country.code);

                  // Force rebuild the dialog with new translations
                  setState(() {});
                }
              }
            }

            // Password validation
            void validatePassword() {
              if (passwordController.text != confirmPasswordController.text) {
                setState(() {
                  passwordError = translations['passwords_do_not_match'] ??
                      'Passwords do not match';
                });
              } else {
                setState(() {
                  passwordError = null;
                });
              }
            }

            // Short password validation
            void validateShortPassword() {
              if (shortPasswordController.text.length != 2 ||
                  !RegExp(r'^[0-9]+$').hasMatch(shortPasswordController.text)) {
                setState(() {
                  shortPasswordError = translations['must_be_2_digit'] ??
                      'Must be a 2-digit number';
                });
              } else {
                setState(() {
                  shortPasswordError = null;
                });
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  maxHeight: screenSize.height * 0.8, // Limit max height
                ),
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title with FittedBox to handle long text
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            translations['create_account'] ?? 'Create Account',
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        // Email field
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            hintText: translations['email'] ?? 'Email',
                            hintStyle: TextStyle(
                                fontSize: 14), // Slightly smaller hint text
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.email_outlined),
                            isDense: true, // More compact field
                          ),
                        ),
                        SizedBox(height: 16),
                        // Nickname field
                        TextField(
                          controller: nicknameController,
                          decoration: InputDecoration(
                            hintText: translations['nickname'] ?? 'Nickname',
                            hintStyle: TextStyle(fontSize: 14),
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.person_outline),
                            isDense: true,
                          ),
                        ),
                        SizedBox(height: 16),
                        // Birthday field with GestureDetector
                        GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: dialogContext,
                              initialDate:
                                  selectedBirthday ?? DateTime(2000, 1, 1),
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
                                birthdayController.text =
                                    DateFormat('yyyy-MM-dd').format(picked);
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: TextField(
                              controller: birthdayController,
                              decoration: InputDecoration(
                                hintText:
                                    translations['birthday'] ?? 'Birthday',
                                hintStyle: TextStyle(fontSize: 14),
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: Icon(Icons.cake_outlined),
                                suffixIcon: Icon(Icons.calendar_today),
                                isDense: true,
                              ),
                            ),
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
                                translations['gender'] ?? 'Gender',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
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
                                            vertical: 12,
                                            horizontal:
                                                8), // Reduced horizontal padding
                                        decoration: BoxDecoration(
                                          color: selectedGender == 'Male'
                                              ? Colors.blue.shade700
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                              size: 16, // Smaller icon
                                              color: selectedGender == 'Male'
                                                  ? Colors.white
                                                  : Colors.blue.shade700,
                                            ),
                                            SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                translations['male'] ?? 'Male',
                                                style: TextStyle(
                                                  fontSize: 13, // Smaller text
                                                  fontWeight: FontWeight.bold,
                                                  color: selectedGender ==
                                                          'Male'
                                                      ? Colors.white
                                                      : Colors.grey.shade700,
                                                ),
                                                overflow: TextOverflow.ellipsis,
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
                                            vertical: 12,
                                            horizontal:
                                                8), // Reduced horizontal padding
                                        decoration: BoxDecoration(
                                          color: selectedGender == 'Female'
                                              ? Colors.pink.shade700
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                              size: 16, // Smaller icon
                                              color: selectedGender == 'Female'
                                                  ? Colors.white
                                                  : Colors.pink.shade700,
                                            ),
                                            SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                translations['female'] ??
                                                    'Female',
                                                style: TextStyle(
                                                  fontSize: 13, // Smaller text
                                                  fontWeight: FontWeight.bold,
                                                  color: selectedGender ==
                                                          'Female'
                                                      ? Colors.white
                                                      : Colors.grey.shade700,
                                                ),
                                                overflow: TextOverflow.ellipsis,
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
                                          ? (translations['select_country'] ??
                                              'Select Country')
                                          : '${translations['country'] ?? 'Country'}: ${selectedCountry!.name}',
                                      style: TextStyle(
                                        color: selectedCountry == null
                                            ? Colors.grey[600]
                                            : Colors.black,
                                        fontWeight: selectedCountry == null
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                        fontSize: 14, // Slightly smaller text
                                      ),
                                      overflow: TextOverflow
                                          .ellipsis, // Handle text overflow
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
                              SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity, // Full width button
                                child: ElevatedButton(
                                  onPressed: selectCountry,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.purple,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                          color: Colors.purple.shade200),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        vertical:
                                            10), // Slightly reduced padding
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                        translations['select_country_button'] ??
                                            'Select Country'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        // Password field
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          onChanged: (_) => validatePassword(),
                          decoration: InputDecoration(
                            hintText: translations['password'] ?? 'Password',
                            hintStyle: TextStyle(fontSize: 14),
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.lock_outline),
                            isDense: true,
                          ),
                        ),
                        SizedBox(height: 16),
                        // Confirm password field
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          onChanged: (_) => validatePassword(),
                          decoration: InputDecoration(
                            hintText: translations['confirm_password'] ??
                                'Confirm Password',
                            hintStyle: TextStyle(fontSize: 14),
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.lock_outline),
                            errorText: passwordError,
                            isDense: true,
                            // Allow error text to wrap
                            errorMaxLines: 2,
                          ),
                        ),
                        SizedBox(height: 16),
                        // PIN field
                        TextField(
                          controller: shortPasswordController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => validateShortPassword(),
                          maxLength: 2,
                          decoration: InputDecoration(
                            hintText: translations['multi_game_pin'] ??
                                'Multi-Game PIN (2 digits)',
                            hintStyle: TextStyle(fontSize: 14),
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.pin_outlined),
                            errorText: shortPasswordError,
                            counterText: "",
                            helperText: translations['pin_helper_text'] ??
                                "2-digit PIN for multiplayer games",
                            helperStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            isDense: true,
                            // Allow helper text to wrap
                            helperMaxLines: 2,
                            // Allow error text to wrap
                            errorMaxLines: 2,
                          ),
                        ),
                        SizedBox(height: 24),
                        // Button row
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side: BorderSide(color: Colors.grey.shade300),
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child:
                                      Text(translations['cancel'] ?? 'Cancel'),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Validate passwords before submission
                                  validatePassword();
                                  validateShortPassword();
                                  if (passwordError != null ||
                                      shortPasswordError != null) {
                                    return;
                                  }

                                  final userData = {
                                    'email': emailController.text,
                                    'password': passwordController.text,
                                    'nickname': nicknameController.text,
                                    'birthday': selectedBirthday != null
                                        ? Timestamp.fromDate(selectedBirthday!)
                                        : null,
                                    'gender': selectedGender,
                                    'country': selectedCountryCode,
                                    'shortPW': shortPasswordController.text,
                                  };
                                  Navigator.of(dialogContext).pop(userData);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple.shade400,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                      translations['create_account_button'] ??
                                          'Create Account'),
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
          },
        );
      },
    );
  }

  // Helper method to load the saved country code from SharedPreferences
  static Future<String?> _loadSavedCountryCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCountryCode = prefs.getString(PREF_USER_COUNTRY_CODE);
      print(
          'Loaded country code from local storage for sign-up dialog: $savedCountryCode');
      return savedCountryCode;
    } catch (e) {
      print('Error loading country code from local storage: $e');
      return null;
    }
  }

  // Helper method to save the selected country code to SharedPreferences
  static Future<void> _saveCountryCode(String countryCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PREF_USER_COUNTRY_CODE, countryCode);
      print('Country code saved to local storage: $countryCode');
    } catch (e) {
      print('Error saving country code to local storage: $e');
    }
  }
}
