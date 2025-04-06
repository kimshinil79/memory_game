import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flag/flag.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/language_provider.dart';

class LanguageDialog {
  static Future<void> show(BuildContext context) {
    // 다이얼로그를 표시하기 전에 LanguageProvider 인스턴스를 가져옵니다
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    return showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: LanguageSelectionContent(languageProvider: languageProvider),
      ),
    );
  }
}

class LanguageSelectionContent extends StatelessWidget {
  final LanguageProvider languageProvider;

  LanguageSelectionContent({Key? key, required this.languageProvider})
      : super(key: key);

  final Map<String, String> languageNames = {
    // Asian Languages
    'ko-KR': '한국어 (Korean)',
    'ja-JP': '日本語 (Japanese)',
    'zh-CN': '中文 (Chinese Simplified)',
    'fil-PH': 'Filipino',
    'hi-IN': 'हिन्दी (Hindi)',
    'bn-BD': 'বাংলা (Bengali Bangladesh)',
    'bn-IN': 'বাংলা (Bengali India)',
    'id-ID': 'Bahasa Indonesia',
    'jv-ID': 'Basa Jawa',
    'km-KH': 'ខ្មែរ (Khmer)',
    'lo-LA': 'ລາວ (Lao)',
    'ms-MY': 'Bahasa Melayu',
    'my-MM': 'မြန်မာ (Burmese)',
    'ne-NP': 'नेपाली (Nepali)',
    'si-LK': 'සිංහල (Sinhala)',
    'su-ID': 'Basa Sunda',
    'ta-IN': 'தமிழ் (Tamil)',
    'th-TH': 'ไทย (Thai)',
    'vi-VN': 'Tiếng Việt (Vietnamese)',

    // European Languages
    'bg-BG': 'Български (Bulgarian)',
    'hr-HR': 'Hrvatski (Croatian)',
    'cs-CZ': 'Čeština (Czech)',
    'da-DK': 'Dansk (Danish)',
    'nl-NL': 'Nederlands (Dutch)',
    'en-US': 'English (US)',
    'fi-FI': 'Suomi (Finnish)',
    'fr-FR': 'Français (French)',
    'de-DE': 'Deutsch (German)',
    'el-GR': 'Ελληνικά (Greek)',
    'hu-HU': 'Magyar (Hungarian)',
    'it-IT': 'Italiano (Italian)',
    'lt-LT': 'Lietuvių (Lithuanian)',
    'no-NO': 'Norsk (Norwegian)',
    'pl-PL': 'Polski (Polish)',
    'pt-PT': 'Português (Portuguese)',
    'ro-RO': 'Română (Romanian)',
    'ru-RU': 'Русский (Russian)',
    'sk-SK': 'Slovenčina (Slovak)',
    'sl-SI': 'Slovenščina (Slovenian)',
    'es-ES': 'Español (Spanish)',
    'sv-SE': 'Svenska (Swedish)',
    'uk-UA': 'Українська (Ukrainian)',

    // Middle Eastern Languages
    'ar-SA': 'العربية (Arabic)',
    'he-IL': 'עברית (Hebrew)',
    'fa-IR': 'فارسی (Persian)',
    'tr-TR': 'Türkçe (Turkish)',

    // African Languages
    'af-ZA': 'Afrikaans',
    'am-ET': 'አማርኛ (Amharic)',
    'sw-KE': 'Kiswahili (Swahili)',
    'zu-ZA': 'isiZulu (Zulu)',
  };

  @override
  Widget build(BuildContext context) {
    Map<String, List<MapEntry<String, String>>> groupedLanguages =
        _groupLanguages();

    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Language',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: DefaultTabController(
              length: groupedLanguages.length + 1,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    labelColor: Colors.purple,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: 'All'),
                      ...groupedLanguages.keys
                          .map((group) => Tab(text: group))
                          .toList(),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildLanguageList(context, [
                          ...languageNames.entries.toList()
                            ..sort((a, b) => a.value.compareTo(b.value))
                        ]),
                        ...groupedLanguages.values
                            .map(
                              (languages) =>
                                  _buildLanguageList(context, languages),
                            )
                            .toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF833AB4), Color(0xFFF77737)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                'Cancel',
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
    );
  }

  Widget _buildLanguageList(
      BuildContext context, List<MapEntry<String, String>> languages) {
    return ListView.builder(
      itemCount: languages.length,
      itemBuilder: (context, index) {
        String languageCode = languages[index].key;
        String languageName = languages[index].value;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.withOpacity(0.1),
          ),
          child: ListTile(
            leading: Flag.fromString(
              _getCountryCode(languageCode),
              height: 30,
              width: 40,
              fit: BoxFit.cover,
              borderRadius: 8,
            ),
            title: Text(
              languageName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              _updateLanguage(context, languageCode);
              Navigator.of(context).pop();
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
        );
      },
    );
  }

  Map<String, List<MapEntry<String, String>>> _groupLanguages() {
    // 영어 이름과 원래 entry를 매핑하는 함수
    String getEnglishName(MapEntry<String, String> entry) {
      // 괄호 안의 영어 이름을 추출
      final match = RegExp(r'\((.*?)\)').firstMatch(entry.value);
      if (match != null && match.group(1) != null) {
        return match.group(1)!;
      }
      // 괄호가 없는 경우 (예: Afrikaans)는 전체 값을 반환
      return entry.value;
    }

    Map<String, List<MapEntry<String, String>>> groupedLanguages = {
      'Asian Languages': [],
      'European Languages': [],
      'Middle Eastern Languages': [],
      'African Languages': [],
    };

    languageNames.entries.forEach((entry) {
      if ([
        'ko-KR',
        'ja-JP',
        'zh-CN',
        'fil-PH',
        'hi-IN',
        'bn-BD',
        'bn-IN',
        'id-ID',
        'jv-ID',
        'km-KH',
        'lo-LA',
        'ms-MY',
        'my-MM',
        'ne-NP',
        'si-LK',
        'su-ID',
        'ta-IN',
        'th-TH',
        'vi-VN'
      ].contains(entry.key)) {
        groupedLanguages['Asian Languages']!.add(entry);
      } else if ([
        'bg-BG',
        'hr-HR',
        'cs-CZ',
        'da-DK',
        'nl-NL',
        'en-US',
        'fi-FI',
        'fr-FR',
        'de-DE',
        'el-GR',
        'hu-HU',
        'it-IT',
        'lt-LT',
        'no-NO',
        'pl-PL',
        'pt-PT',
        'ro-RO',
        'ru-RU',
        'sk-SK',
        'sl-SI',
        'es-ES',
        'sv-SE',
        'uk-UA'
      ].contains(entry.key)) {
        groupedLanguages['European Languages']!.add(entry);
      } else if (['ar-SA', 'he-IL', 'fa-IR', 'tr-TR'].contains(entry.key)) {
        groupedLanguages['Middle Eastern Languages']!.add(entry);
      } else if (['af-ZA', 'am-ET', 'sw-KE', 'zu-ZA'].contains(entry.key)) {
        groupedLanguages['African Languages']!.add(entry);
      }
    });

    // 각 그룹을 영어 이름 기준으로 정렬
    groupedLanguages.forEach((key, value) {
      value.sort((a, b) => getEnglishName(a).compareTo(getEnglishName(b)));
    });

    return groupedLanguages;
  }

  String _getCountryCode(String languageCode) {
    Map<String, String> languageToCountry = {
      // Asian Languages
      'ko-KR': 'kr',
      'ja-JP': 'jp',
      'zh-CN': 'cn',
      'fil-PH': 'ph',
      'hi-IN': 'in',
      'bn-BD': 'bd',
      'bn-IN': 'in',
      'id-ID': 'id',
      'jv-ID': 'id',
      'km-KH': 'kh',
      'lo-LA': 'la',
      'ms-MY': 'my',
      'my-MM': 'mm',
      'ne-NP': 'np',
      'si-LK': 'lk',
      'su-ID': 'id',
      'ta-IN': 'in',
      'th-TH': 'th',
      'vi-VN': 'vn',

      // European Languages
      'bg-BG': 'bg',
      'hr-HR': 'hr',
      'cs-CZ': 'cz',
      'da-DK': 'dk',
      'nl-NL': 'nl',
      'en-US': 'us',
      'fi-FI': 'fi',
      'fr-FR': 'fr',
      'de-DE': 'de',
      'el-GR': 'gr',
      'hu-HU': 'hu',
      'it-IT': 'it',
      'lt-LT': 'lt',
      'no-NO': 'no',
      'pl-PL': 'pl',
      'pt-PT': 'pt',
      'ro-RO': 'ro',
      'ru-RU': 'ru',
      'sk-SK': 'sk',
      'sl-SI': 'si',
      'es-ES': 'es',
      'sv-SE': 'se',
      'uk-UA': 'ua',

      // Middle Eastern Languages
      'ar-SA': 'sa',
      'he-IL': 'il',
      'fa-IR': 'ir',
      'tr-TR': 'tr',

      // African Languages
      'af-ZA': 'za',
      'am-ET': 'et',
      'sw-KE': 'ke',
      'zu-ZA': 'za',
    };

    return languageToCountry[languageCode] ??
        languageCode.split('-').last.toLowerCase();
  }

  Future<void> _updateLanguage(
      BuildContext context, String languageCode) async {
    try {
      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedLanguage', languageCode);

      // Provider 접근에 전달받은 languageProvider 사용
      await languageProvider.setLanguage(languageCode);

      // Update Firebase if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'language': languageCode});
        } catch (firebaseError) {
          print('Firebase update error: $firebaseError');
          // Firebase 업데이트 실패해도 앱의 언어는 변경 완료된 상태로 유지
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'User profile update failed, but language has been changed.'),
              duration: Duration(seconds: 2),
            ),
          );
          // Firebase 오류지만 언어 변경은 성공했으므로 오류를 throw하지 않고 반환
          return;
        }
      }

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Language update error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to update language setting: ${e.toString()}')),
      );
    }
  }
}
