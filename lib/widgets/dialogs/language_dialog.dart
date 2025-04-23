import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flag/flag.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/language_provider.dart';

class LanguageDialog {
  static Future<void> show(BuildContext context) async {
    // 다이얼로그를 표시하기 전에 LanguageProvider 인스턴스를 가져옵니다
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    // 다이얼로그를 표시하기 전에 데이터를 미리 가져옵니다
    try {
      // 이미 로딩 중이 아닐 경우에만 호출
      if (!languageProvider.isLoadingCountry) {
        await languageProvider.getUserCountryFromFirebase();
      }
    } catch (e) {
      print('Error pre-loading country data: $e');
    }

    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 10,
        backgroundColor: Colors.white,
        child: LanguageSelectionContent(languageProvider: languageProvider),
      ),
    );
  }
}

class LanguageSelectionContent extends StatefulWidget {
  final LanguageProvider languageProvider;

  LanguageSelectionContent({Key? key, required this.languageProvider})
      : super(key: key);

  @override
  _LanguageSelectionContentState createState() =>
      _LanguageSelectionContentState();
}

class _LanguageSelectionContentState extends State<LanguageSelectionContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

    // Current language (from provider)
    String currentLanguage = widget.languageProvider.currentLanguage;
    // Check if currently loading country data
    bool isLoading = widget.languageProvider.isLoadingCountry;

    // LanguageProvider를 통해 번역 텍스트 가져오기
    Map<String, String> translations =
        widget.languageProvider.getTranslations(currentLanguage);

    // 로딩 상태를 더이상 체크하지 않고 항상 컨텐츠를 보여줍니다.
    // 로딩 표시는 다이얼로그 표시 전에 처리합니다.
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with gradient text
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Color(0xFF833AB4), Color(0xFFF77737)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              translations['select_language'] ?? 'Select Language',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 16),

          // Search box
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          translations['search_language'] ?? 'Search language',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                    child: Icon(Icons.close,
                        color: Colors.grey.shade400, size: 20),
                  ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Language list
          Container(
            height: 400,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: DefaultTabController(
              length: groupedLanguages.length + 1,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      isScrollable: true,
                      labelColor: Color(0xFF833AB4),
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      indicator: UnderlineTabIndicator(
                        borderSide: BorderSide(
                          width: 3,
                          color: Color(0xFF833AB4),
                        ),
                      ),
                      tabs: [
                        Tab(text: translations['all'] ?? 'All'),
                        ...groupedLanguages.keys.map((group) => Tab(
                            text: widget.languageProvider
                                .getTranslatedGroupName(group)))
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildLanguageList(
                          context,
                          [
                            ...languageNames.entries.toList()
                              ..sort((a, b) => a.value.compareTo(b.value))
                          ],
                          currentLanguage,
                        ),
                        ...groupedLanguages.values
                            .map(
                              (languages) => _buildLanguageList(
                                context,
                                languages,
                                currentLanguage,
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Cancel button
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF833AB4), Color(0xFFF77737)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF833AB4).withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                translations['cancel'] ?? 'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageList(
    BuildContext context,
    List<MapEntry<String, String>> languages,
    String currentLanguage,
  ) {
    // Filter languages if search query exists
    if (_searchQuery.isNotEmpty) {
      languages = languages.where((entry) {
        return entry.value.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return languages.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 16),
                Text(
                  'No languages found',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: languages.length,
            itemBuilder: (context, index) {
              String languageCode = languages[index].key;
              String languageName = languages[index].value;
              bool isSelected = languageCode == currentLanguage;

              return Container(
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [Color(0xFF833AB4), Color(0xFFF77737)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? Color(0xFF833AB4).withOpacity(0.2)
                          : Colors.black.withOpacity(0.03),
                      blurRadius: isSelected ? 6 : 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _updateLanguage(context, languageCode);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Flag
                          Container(
                            width: 38,
                            height: 26,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Flag.fromString(
                                _getCountryCode(languageCode),
                                height: 26,
                                width: 38,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 14),

                          // Language name
                          Expanded(
                            child: Text(
                              languageName,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade800,
                              ),
                            ),
                          ),

                          // Selected indicator
                          if (isSelected)
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              child: Icon(
                                Icons.check,
                                color: Color(0xFF833AB4),
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
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
      // 현재 사용자 정보 가져오기
      User? currentUser = FirebaseAuth.instance.currentUser;

      // LanguageProvider를 사용하여 언어 업데이트
      await widget.languageProvider.setLanguage(languageCode);

      // 로그인한 사용자가 있으면 Firestore에도 업데이트
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'language': languageCode});
      }

      // 이전 화면으로 돌아가기
      Navigator.of(context).pop();
    } catch (e) {
      print('Failed to update language: $e');
      // 에러 처리 - 필요하면 사용자에게 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update language')),
      );
    }
  }
}
