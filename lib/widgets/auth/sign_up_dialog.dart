import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flag/flag.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../data/countries.dart';
import '../country_selection_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Constants for SharedPreferences keys (same as in main.dart)
const String PREF_USER_COUNTRY_CODE = 'user_country_code';

class SignUpDialog {
  // Gradient colors matching the app theme
  static const Color instagramGradientStart = Color(0xFF833AB4);
  static const Color instagramGradientEnd = Color(0xFFF77737);
  
  static Future<Map<String, dynamic>?> show(BuildContext context) async {
    // Get screen size for responsive layout
    final Size screenSize = MediaQuery.of(context).size;
    // Calculate dialog width based on screen size
    final double dialogWidth =
        screenSize.width > 600 ? 450 : screenSize.width * 0.9;

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

    String? selectedGender;
    Country? selectedCountry = initialCountry;
    String? selectedCountryCode = savedCountryCode;
    String? passwordError;
    String? shortPasswordError;

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
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  maxHeight: screenSize.height * 0.85,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0B0D13),
                        Color(0xFF121826),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: instagramGradientStart.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: instagramGradientStart.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Text(
                            translations['create_account'] ?? 'Create Account',
                            style: GoogleFonts.montserrat(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: instagramGradientStart.withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          // Email field
                          _buildTextField(
                            controller: emailController,
                            hintText: translations['email'] ?? 'Email',
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 16),
                          // Nickname field
                          _buildTextField(
                            controller: nicknameController,
                            hintText: translations['nickname'] ?? 'Nickname',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                          // Gender selection
                          _buildGenderSelector(
                            translations: translations,
                            selectedGender: selectedGender,
                            onGenderSelected: (gender) {
                              setState(() {
                                selectedGender = gender;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          // Country selection
                          _buildCountrySelector(
                            translations: translations,
                            selectedCountry: selectedCountry,
                            onSelectCountry: selectCountry,
                          ),
                          const SizedBox(height: 16),
                          // Password field
                          _buildTextField(
                            controller: passwordController,
                            hintText: translations['password'] ?? 'Password',
                            icon: Icons.lock_outline,
                            obscureText: true,
                            onChanged: (_) => validatePassword(),
                          ),
                          const SizedBox(height: 16),
                          // Confirm password field
                          _buildTextField(
                            controller: confirmPasswordController,
                            hintText: translations['confirm_password'] ?? 'Confirm Password',
                            icon: Icons.lock_outline,
                            obscureText: true,
                            errorText: passwordError,
                            onChanged: (_) => validatePassword(),
                          ),
                          const SizedBox(height: 16),
                          // PIN field
                          _buildTextField(
                            controller: shortPasswordController,
                            hintText: translations['multi_game_pin'] ?? 'Multi-Game PIN (2 digits)',
                            icon: Icons.pin_outlined,
                            keyboardType: TextInputType.number,
                            maxLength: 2,
                            errorText: shortPasswordError,
                            helperText: translations['pin_helper_text'] ?? "2-digit PIN for multiplayer games",
                            onChanged: (_) => validateShortPassword(),
                          ),
                          const SizedBox(height: 32),
                          // Button row
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white38, width: 2),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    translations['cancel'] ?? 'Cancel',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [instagramGradientStart, instagramGradientEnd],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: instagramGradientStart.withOpacity(0.6),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 6),
                                      ),
                                      BoxShadow(
                                        color: instagramGradientEnd.withOpacity(0.4),
                                        blurRadius: 15,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
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
                                        'gender': selectedGender,
                                        'country': selectedCountryCode,
                                        'shortPW': shortPasswordController.text,
                                      };
                                      Navigator.of(dialogContext).pop(userData);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Center(
                                      child: Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            translations['create_account_button'] ?? 'Create Account',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    String? errorText,
    String? helperText,
    TextInputType? keyboardType,
    int? maxLength,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: instagramGradientStart, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        prefixIcon: Icon(icon, color: Colors.white70),
        errorText: errorText,
        helperText: helperText,
        helperStyle: TextStyle(color: Colors.white54, fontSize: 12),
        errorStyle: const TextStyle(color: Colors.redAccent),
        counterText: "",
        isDense: true,
      ),
    );
  }

  static Widget _buildGenderSelector({
    required Map<String, String> translations,
    required String? selectedGender,
    required Function(String) onGenderSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translations['gender'] ?? 'Gender',
            style: GoogleFonts.montserrat(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => onGenderSelected('Male'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: selectedGender == 'Male'
                          ? const LinearGradient(
                              colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                            )
                          : null,
                      color: selectedGender == 'Male' ? null : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedGender == 'Male'
                            ? Colors.blue
                            : Colors.white24,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.male,
                          color: selectedGender == 'Male' ? Colors.white : Colors.blue.shade300,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          translations['male'] ?? 'Male',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: selectedGender == 'Male' ? Colors.white : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => onGenderSelected('Female'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: selectedGender == 'Female'
                          ? const LinearGradient(
                              colors: [Color(0xFFEC407A), Color(0xFFD81B60)],
                            )
                          : null,
                      color: selectedGender == 'Female' ? null : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedGender == 'Female'
                            ? Colors.pink
                            : Colors.white24,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.female,
                          color: selectedGender == 'Female' ? Colors.white : Colors.pink.shade300,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          translations['female'] ?? 'Female',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: selectedGender == 'Female' ? Colors.white : Colors.white70,
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
    );
  }

  static Widget _buildCountrySelector({
    required Map<String, String> translations,
    required Country? selectedCountry,
    required VoidCallback onSelectCountry,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedCountry == null
                      ? (translations['select_country'] ?? 'Select Country')
                      : '${translations['country'] ?? 'Country'}: ${selectedCountry.name}',
                  style: GoogleFonts.montserrat(
                    color: selectedCountry == null ? Colors.white38 : Colors.white,
                    fontWeight: selectedCountry == null ? FontWeight.normal : FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selectedCountry != null)
                Flag.fromString(
                  selectedCountry.code,
                  height: 24,
                  width: 32,
                  borderRadius: 4,
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSelectCountry,
              style: ElevatedButton.styleFrom(
                backgroundColor: instagramGradientStart.withOpacity(0.2),
                foregroundColor: Colors.white,
                side: BorderSide(color: instagramGradientStart.withOpacity(0.5), width: 2),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                translations['select_country_button'] ?? 'Select Country',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
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
