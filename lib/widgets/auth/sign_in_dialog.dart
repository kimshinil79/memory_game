import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Constants for SharedPreferences keys (same as in main.dart)
const String PREF_USER_COUNTRY_CODE = 'user_country_code';
const String PREF_EMAIL_HISTORY = 'email_history';

class SignInDialog {
  static Future<Map<String, dynamic>?> show(BuildContext context) async {
    // Try to load saved country code from local storage
    String? savedCountryCode = await _loadSavedCountryCode();

    // Load email history for autocomplete
    List<String> emailHistory = await _loadEmailHistory();

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
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return emailHistory.where((String option) {
                      return option
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    emailController.text = selection;
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController fieldTextEditingController,
                      FocusNode fieldFocusNode,
                      VoidCallback onFieldSubmitted) {
                    // Use the provided controller instead of creating a new one
                    emailController.text = fieldTextEditingController.text;
                    fieldTextEditingController.addListener(() {
                      emailController.text = fieldTextEditingController.text;
                    });

                    return TextField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
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
                    );
                  },
                  optionsViewBuilder: (BuildContext context,
                      AutocompleteOnSelected<String> onSelected,
                      Iterable<String> options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: 200,
                            maxWidth: 300,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Icon(Icons.history,
                                          size: 16, color: Colors.grey[600]),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
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
                        onPressed: () async {
                          final email = emailController.text.trim();
                          final credentials = {
                            'email': email,
                            'password': passwordController.text,
                          };

                          // Save email to history if it's valid
                          if (email.isNotEmpty && email.contains('@')) {
                            await _saveEmailToHistory(email);
                          }

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

  // Load email history from SharedPreferences
  static Future<List<String>> _loadEmailHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emailHistory = prefs.getStringList(PREF_EMAIL_HISTORY) ?? [];
      print('Loaded email history: ${emailHistory.length} emails');
      return emailHistory;
    } catch (e) {
      print('Error loading email history: $e');
      return [];
    }
  }

  // Save email to history (max 10 recent emails)
  static Future<void> _saveEmailToHistory(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> emailHistory = prefs.getStringList(PREF_EMAIL_HISTORY) ?? [];

      // Remove if already exists to avoid duplicates
      emailHistory.remove(email);

      // Add to the beginning of the list
      emailHistory.insert(0, email);

      // Keep only the 10 most recent emails
      if (emailHistory.length > 10) {
        emailHistory = emailHistory.take(10).toList();
      }

      await prefs.setStringList(PREF_EMAIL_HISTORY, emailHistory);
      print('Saved email to history: $email (total: ${emailHistory.length})');
    } catch (e) {
      print('Error saving email to history: $e');
    }
  }
}
