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
          backgroundColor: const Color(0xFF0B0D13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: Color(0xFF00E5FF),
              width: 2,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E2430), Color(0xFF2A2F3A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFFFF2D95).withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF2D95), Color(0xFF00E5FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF2D95).withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.login,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFF2D95), Color(0xFF00E5FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          translations['sign_in'] ?? 'Sign In',
                          style: GoogleFonts.notoSans(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: translations['email'] ?? 'Email',
                        hintStyle: TextStyle(
                          color: const Color(0xFF00E5FF).withOpacity(0.7),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF252B3A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: const Color(0xFF00E5FF).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: const Color(0xFF00E5FF).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF2D95),
                            width: 2,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: const Color(0xFF00E5FF),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    );
                  },
                  optionsViewBuilder: (BuildContext context,
                      AutocompleteOnSelected<String> onSelected,
                      Iterable<String> options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 8.0,
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF252B3A),
                        child: Container(
                          constraints: const BoxConstraints(
                            maxHeight: 200,
                            maxWidth: 300,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF00E5FF).withOpacity(0.5),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00E5FF).withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: index % 2 == 0 
                                        ? const Color(0xFF252B3A) 
                                        : const Color(0xFF2A2F3A),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.history,
                                        size: 16, 
                                        color: const Color(0xFF00E5FF),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
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
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: translations['password'] ?? 'Password',
                    hintStyle: TextStyle(
                      color: const Color(0xFF00E5FF).withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF252B3A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color(0xFF00E5FF).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color(0xFF00E5FF).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF2D95),
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: const Color(0xFF00E5FF),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop({'signUp': true});
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00E5FF),
                          backgroundColor: const Color(0xFF2A2F3A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(
                            color: Color(0xFF00E5FF),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shadowColor: const Color(0xFF00E5FF).withOpacity(0.3),
                        ),
                        child: Text(
                          translations['sign_up'] ?? 'Sign Up',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF2D95), Color(0xFF00E5FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2D95).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withOpacity(0.2),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
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
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            translations['sign_in'] ?? 'Sign In',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
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
