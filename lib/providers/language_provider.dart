import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'ko-KR'; // 기본값은 한국어로 변경
  bool _isInitialized = false;

  String get currentLanguage => _currentLanguage;
  bool get isInitialized => _isInitialized;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString('selectedLanguage') ?? 'ko-KR';
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error loading language: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedLanguage', language);
      _currentLanguage = language;
      notifyListeners();
    } catch (e) {
      print('Error setting language: $e');
    }
  }
}
