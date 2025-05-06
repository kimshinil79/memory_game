import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Constants for SharedPreferences keys (same as in main.dart)
const String PREF_USER_COUNTRY_CODE = 'user_country_code';

class SignInDialog {
  static Future<Map<String, dynamic>?> show(BuildContext context) async {
    // Try to load saved country code from local storage
    String? savedCountryCode = await _loadSavedCountryCode();

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

    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  translations['sign_in'] ?? 'Sign In',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: translations['email'] ?? 'Email',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: translations['password'] ?? 'Password',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop({'signUp': true});
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: BorderSide(color: Colors.purple.shade200),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(translations['sign_up'] ?? 'Sign Up'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final credentials = {
                            'email': emailController.text,
                            'password': passwordController.text,
                          };
                          Navigator.of(dialogContext).pop(credentials);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(translations['sign_in'] ?? 'Sign In'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
          'Loaded country code from local storage for sign-in dialog: $savedCountryCode');
      return savedCountryCode;
    } catch (e) {
      print('Error loading country code from local storage: $e');
      return null;
    }
  }
}
