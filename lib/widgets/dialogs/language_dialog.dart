import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flag/flag.dart';
import 'package:provider/provider.dart';
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
        backgroundColor: const Color(0xFF0B0D13),
        child: LanguageSelectionContent(languageProvider: languageProvider),
      ),
    );
  }
}

class LanguageSelectionContent extends StatefulWidget {
  final LanguageProvider languageProvider;

  const LanguageSelectionContent({super.key, required this.languageProvider});

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
    'zh-TW': '中文 (Chinese Traditional)',
    'zh-SG': '中文 (Chinese Singapore)',
    'fil-PH': 'Filipino',
    'hi-IN': 'हिन्दी (Hindi)',
    'bn-BD': 'বাংলা (Bengali Bangladesh)',
    'bn-IN': 'বাংলা (Bengali India)',
    'id-ID': 'Bahasa Indonesia',
    'jv-ID': 'Basa Jawa',
    'km-KH': 'ខ្មែរ (Khmer)',
    'lo-LA': 'ລາວ (Lao)',
    'ms-MY': 'Bahasa Melayu',
    'ms-SG': 'Bahasa Melayu (Singapore)',
    'my-MM': 'မြန်မာ (Burmese)',
    'ne-NP': 'नेपाली (Nepali)',
    'si-LK': 'සිංහල (Sinhala)',
    'su-ID': 'Basa Sunda',
    'ta-IN': 'தமிழ் (Tamil)',
    'ta-LK': 'தமிழ் (Tamil Sri Lanka)',
    'ta-SG': 'தமிழ் (Tamil Singapore)',
    'th-TH': 'ไทย (Thai)',
    'vi-VN': 'Tiếng Việt (Vietnamese)',
    'dz-BT': 'རྫོང་ཁ (Dzongkha)',
    'dv-MV': 'ދިވެހި (Dhivehi)',
    'mn-MN': 'Монгол (Mongolian)',
    'ur-PK': 'اردو (Urdu)',
    'ko-KP': '한국어 (Korean North)',

    // European Languages
    'bg-BG': 'Български (Bulgarian)',
    'hr-HR': 'Hrvatski (Croatian)',
    'cs-CZ': 'Čeština (Czech)',
    'da-DK': 'Dansk (Danish)',
    'nl-NL': 'Nederlands (Dutch)',
    'nl-BE': 'Nederlands (Belgian Dutch)',
    'nl-SR': 'Nederlands (Suriname Dutch)',
    'en-US': 'English (US)',
    'en-GB': 'English (UK)',
    'en-AU': 'English (Australia)',
    'en-CA': 'English (Canada)',
    'en-IE': 'English (Ireland)',
    'en-NZ': 'English (New Zealand)',
    'en-ZA': 'English (South Africa)',
    'en-UG': 'English (Uganda)',
    'en-TT': 'English (Trinidad and Tobago)',
    'en-ZM': 'English (Zambia)',
    'en-ZW': 'English (Zimbabwe)',
    'en-AG': 'English (Antigua and Barbuda)',
    'en-BS': 'English (Bahamas)',
    'en-BB': 'English (Barbados)',
    'en-BZ': 'English (Belize)',
    'en-DM': 'English (Dominica)',
    'en-FJ': 'English (Fiji)',
    'en-GM': 'English (Gambia)',
    'en-GH': 'English (Ghana)',
    'en-GD': 'English (Grenada)',
    'en-GY': 'English (Guyana)',
    'en-JM': 'English (Jamaica)',
    'en-KI': 'English (Kiribati)',
    'en-LC': 'English (Saint Lucia)',
    'en-VC': 'English (Saint Vincent)',
    'en-WS': 'English (Samoa)',
    'en-SC': 'English (Seychelles)',
    'en-SG': 'English (Singapore)',
    'en-SS': 'English (South Sudan)',
    'en-SZ': 'English (Eswatini)',
    'en-TO': 'English (Tonga)',
    'en-NA': 'English (Namibia)',
    'en-NG': 'English (Nigeria)',
    'en-MU': 'English (Mauritius)',
    'en-MW': 'English (Malawi)',
    'en-LR': 'English (Liberia)',
    'en-NR': 'English (Nauru)',
    'en-FM': 'English (Micronesia)',
    'en-MH': 'English (Marshall Islands)',
    'en-SL': 'English (Sierra Leone)',
    'en-SB': 'English (Solomon Islands)',
    'en-PG': 'English (Papua New Guinea)',
    'en-PW': 'English (Palau)',
    'en-KN': 'English (Saint Kitts and Nevis)',
    'fi-FI': 'Suomi (Finnish)',
    'fr-FR': 'Français (French)',
    'fr-CA': 'Français (Canadian French)',
    'fr-BE': 'Français (Belgian French)',
    'fr-CH': 'Français (Swiss French)',
    'fr-LU': 'Français (Luxembourg French)',
    'fr-MC': 'Français (Monaco French)',
    'fr-DZ': 'Français (Algerian French)',
    'fr-TG': 'Français (Togolese French)',
    'fr-SN': 'Français (Senegalese French)',
    'fr-BJ': 'Français (Beninese French)',
    'fr-BF': 'Français (Burkina Faso French)',
    'fr-CM': 'Français (Cameroonian French)',
    'fr-CF': 'Français (Central African French)',
    'fr-TD': 'Français (Chadian French)',
    'fr-CG': 'Français (Congolese French)',
    'fr-GA': 'Français (Gabonese French)',
    'fr-GN': 'Français (Guinean French)',
    'fr-HT': 'Français (Haitian French)',
    'fr-ML': 'Français (Malian French)',
    'de-DE': 'Deutsch (German)',
    'de-AT': 'Deutsch (Austrian German)',
    'de-CH': 'Deutsch (Swiss German)',
    'de-LI': 'Deutsch (Liechtenstein German)',
    'de-LU': 'Deutsch (Luxembourg German)',
    'el-GR': 'Ελληνικά (Greek)',
    'el-CY': 'Ελληνικά (Cypriot Greek)',
    'hu-HU': 'Magyar (Hungarian)',
    'is-IS': 'Íslenska (Icelandic)',
    'it-IT': 'Italiano (Italian)',
    'it-CH': 'Italiano (Swiss Italian)',
    'it-SM': 'Italiano (San Marino Italian)',
    'it-VA': 'Italiano (Vatican Italian)',
    'lt-LT': 'Lietuvių (Lithuanian)',
    'lv-LV': 'Latviešu (Latvian)',
    'mk-MK': 'Македонски (Macedonian)',
    'mt-MT': 'Malti (Maltese)',
    'no-NO': 'Norsk (Norwegian)',
    'pl-PL': 'Polski (Polish)',
    'pt-PT': 'Português (Portuguese)',
    'pt-BR': 'Português (Brazilian Portuguese)',
    'pt-AO': 'Português (Angolan Portuguese)',
    'pt-CV': 'Português (Cape Verdean Portuguese)',
    'pt-GW': 'Português (Guinea-Bissau Portuguese)',
    'pt-MZ': 'Português (Mozambican Portuguese)',
    'pt-ST': 'Português (São Tomé and Príncipe Portuguese)',
    'pt-TL': 'Português (East Timorese Portuguese)',
    'ro-RO': 'Română (Romanian)',
    'ro-MD': 'Română (Moldovan Romanian)',
    'ru-RU': 'Русский (Russian)',
    'sk-SK': 'Slovenčina (Slovak)',
    'sl-SI': 'Slovenščina (Slovenian)',
    'sr-RS': 'Српски (Serbian)',
    'es-ES': 'Español (Spanish)',
    'es-AR': 'Español (Argentine Spanish)',
    'es-BO': 'Español (Bolivian Spanish)',
    'es-CL': 'Español (Chilean Spanish)',
    'es-CO': 'Español (Colombian Spanish)',
    'es-CR': 'Español (Costa Rican Spanish)',
    'es-CU': 'Español (Cuban Spanish)',
    'es-DO': 'Español (Dominican Spanish)',
    'es-EC': 'Español (Ecuadorian Spanish)',
    'es-SV': 'Español (Salvadoran Spanish)',
    'es-GT': 'Español (Guatemalan Spanish)',
    'es-HN': 'Español (Honduran Spanish)',
    'es-MX': 'Español (Mexican Spanish)',
    'es-NI': 'Español (Nicaraguan Spanish)',
    'es-PA': 'Español (Panamanian Spanish)',
    'es-PY': 'Español (Paraguayan Spanish)',
    'es-PE': 'Español (Peruvian Spanish)',
    'es-PR': 'Español (Puerto Rican Spanish)',
    'es-UY': 'Español (Uruguayan Spanish)',
    'es-VE': 'Español (Venezuelan Spanish)',
    'sv-SE': 'Svenska (Swedish)',
    'et-EE': 'Eesti (Estonian)',
    'uk-UA': 'Українська (Ukrainian)',
    'ca-AD': 'Català (Catalan)',
    'sq-AL': 'Shqip (Albanian)',
    'be-BY': 'Беларуская (Belarusian)',
    'bs-BA': 'Bosanski (Bosnian)',
    'lb-LU': 'Lëtzebuergesch (Luxembourgish)',

    // Middle Eastern Languages
    'ar-SA': 'العربية (Arabic)',
    'ar-AE': 'العربية (UAE Arabic)',
    'ar-BH': 'العربية (Bahraini Arabic)',
    'ar-DZ': 'العربية (Algerian Arabic)',
    'ar-EG': 'العربية (Egyptian Arabic)',
    'ar-IQ': 'العربية (Iraqi Arabic)',
    'ar-JO': 'العربية (Jordanian Arabic)',
    'ar-KW': 'العربية (Kuwaiti Arabic)',
    'ar-LB': 'العربية (Lebanese Arabic)',
    'ar-LY': 'العربية (Libyan Arabic)',
    'ar-MA': 'العربية (Moroccan Arabic)',
    'ar-OM': 'العربية (Omani Arabic)',
    'ar-QA': 'العربية (Qatari Arabic)',
    'ar-SD': 'العربية (Sudanese Arabic)',
    'ar-SY': 'العربية (Syrian Arabic)',
    'ar-YE': 'العربية (Yemeni Arabic)',
    'ar-KM': 'العربية (Comorian Arabic)',
    'ar-MR': 'العربية (Mauritanian Arabic)',
    'ar-DJ': 'العربية (Djiboutian Arabic)',
    'fa-IR': 'فارسی (Persian)',
    'fa-AF': 'فارسی (Afghan Persian)',
    'he-IL': 'עברית (Hebrew)',
    'tr-TR': 'Türkçe (Turkish)',
    'tk-TM': 'Türkmençe (Turkmen)',
    'az-AZ': 'Azərbaycan (Azerbaijani)',
    'hy-AM': 'Հայերեն (Armenian)',
    'ka-GE': 'ქართული (Georgian)',
    'kk-KZ': 'Қазақ (Kazakh)',
    'ky-KG': 'Кыргызча (Kyrgyz)',
    'tg-TJ': 'Тоҷикӣ (Tajik)',
    'uz-UZ': 'O\'zbek (Uzbek)',

    // African Languages
    'af-ZA': 'Afrikaans',
    'am-ET': 'አማርኛ (Amharic)',
    'sw-KE': 'Kiswahili (Swahili Kenya)',
    'sw-TZ': 'Kiswahili (Swahili Tanzania)',
    'zu-ZA': 'isiZulu (Zulu)',
    'rw-RW': 'Kinyarwanda (Rwanda)',
    'so-SO': 'Soomaali (Somali)',
    'st-LS': 'Sesotho (Lesotho)',
    'tn-BW': 'Setswana (Botswana)',
    'mg-MG': 'Malagasy (Madagascar)',
    'ti-ER': 'ትግርኛ (Tigrinya)',
    'rn-BI': 'Kirundi (Burundi)',
    'to-TO': 'Lea Fakatonga (Tongan)',
    'bi-VU': 'Bislama (Vanuatu)',
  };

  @override
  Widget build(BuildContext context) {
    Map<String, List<MapEntry<String, String>>> groupedLanguages =
        _groupLanguages();

    // Current language (from provider)
    String currentLanguage = widget.languageProvider.currentLanguage;
    // Check if currently loading country data
    bool isLoading = widget.languageProvider.isLoadingCountry;

    // LanguageProvider를 통해 번역 텍스트 가져오기 - 사용자 국적 기반
    Map<String, String> translations =
        widget.languageProvider.getUITranslations();

    // 로딩 상태를 더이상 체크하지 않고 항상 컨텐츠를 보여줍니다.
    // 로딩 표시는 다이얼로그 표시 전에 처리합니다.
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with gradient text
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFF2D95), Color(0xFFF77737)],
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
          const SizedBox(height: 16),

          // Search box
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A2F3A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey.shade300, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          translations['search_language'] ?? 'Search language',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade300,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
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
                        color: Colors.grey.shade300, size: 20),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Language list
          Container(
            height: 400,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2F3A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
            ),
            child: DefaultTabController(
              length: groupedLanguages.length + 1,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0D13),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      isScrollable: true,
                      labelColor: const Color(0xFFFF2D95),
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(
                          width: 3,
                          color: Color(0xFFFF2D95),
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
                            ,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Cancel button
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF2D95), Color(0xFFF77737)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2D95).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
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
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No languages found',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: languages.length,
            itemBuilder: (context, index) {
              String languageCode = languages[index].key;
              String languageName = languages[index].value;
              bool isSelected = languageCode == currentLanguage;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFFF2D95), Color(0xFF00E5FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : const Color(0xFF2A2F3A),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFFFF2D95).withOpacity(0.2)
                          : const Color(0xFF00E5FF).withOpacity(0.1),
                      blurRadius: isSelected ? 6 : 4,
                      offset: const Offset(0, 2),
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
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                  offset: const Offset(0, 1),
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
                          const SizedBox(width: 14),

                          // Language name
                          Expanded(
                            child: Text(
                              languageName,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
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
                              child: const Icon(
                                Icons.check,
                                color: Color(0xFFFF2D95),
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

    for (var entry in languageNames.entries) {
      String langCode = entry.key.split('-')[0].toLowerCase();
      String countryCode = entry.key.split('-')[1].toUpperCase();

      // Asian Languages
      if ([
        'ko',
        'ja',
        'zh',
        'fil',
        'hi',
        'bn',
        'id',
        'jv',
        'km',
        'lo',
        'ms',
        'my',
        'ne',
        'si',
        'su',
        'ta',
        'th',
        'vi',
        'dz',
        'dv',
        'mn',
        'ur'
      ].contains(langCode)) {
        groupedLanguages['Asian Languages']!.add(entry);
      }
      // European Languages
      else if ([
        'bg',
        'hr',
        'cs',
        'da',
        'nl',
        'en',
        'fi',
        'fr',
        'de',
        'el',
        'hu',
        'is',
        'it',
        'lt',
        'lv',
        'mk',
        'mt',
        'no',
        'pl',
        'pt',
        'ro',
        'ru',
        'sk',
        'sl',
        'sr',
        'es',
        'sv',
        'et',
        'uk',
        'ca',
        'sq',
        'be',
        'bs',
        'lb'
      ].contains(langCode)) {
        groupedLanguages['European Languages']!.add(entry);
      }
      // Middle Eastern Languages
      else if ([
        'ar',
        'fa',
        'he',
        'tr',
        'tk',
        'az',
        'hy',
        'ka',
        'kk',
        'ky',
        'tg',
        'uz'
      ].contains(langCode)) {
        groupedLanguages['Middle Eastern Languages']!.add(entry);
      }
      // African Languages
      else if ([
        'af',
        'am',
        'sw',
        'zu',
        'rw',
        'so',
        'st',
        'tn',
        'mg',
        'ti',
        'rn',
        'to',
        'bi'
      ].contains(langCode)) {
        groupedLanguages['African Languages']!.add(entry);
      }
      // 분류되지 않은 언어는 첫 번째 그룹에 넣기
      else {
        groupedLanguages['Asian Languages']!.add(entry);
      }
    }

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
      'zh-TW': 'tw',
      'zh-SG': 'sg',
      'fil-PH': 'ph',
      'hi-IN': 'in',
      'bn-BD': 'bd',
      'bn-IN': 'in',
      'id-ID': 'id',
      'jv-ID': 'id',
      'km-KH': 'kh',
      'lo-LA': 'la',
      'ms-MY': 'my',
      'ms-SG': 'sg',
      'my-MM': 'mm',
      'ne-NP': 'np',
      'si-LK': 'lk',
      'su-ID': 'id',
      'ta-IN': 'in',
      'ta-LK': 'lk',
      'ta-SG': 'sg',
      'th-TH': 'th',
      'vi-VN': 'vn',
      'dz-BT': 'bt',
      'dv-MV': 'mv',
      'mn-MN': 'mn',
      'ur-PK': 'pk',
      'ko-KP': 'kp',

      // European Languages
      'bg-BG': 'bg',
      'hr-HR': 'hr',
      'cs-CZ': 'cz',
      'da-DK': 'dk',
      'nl-NL': 'nl',
      'nl-BE': 'be',
      'nl-SR': 'sr',
      'en-US': 'us',
      'en-GB': 'gb',
      'en-AU': 'au',
      'en-CA': 'ca',
      'en-IE': 'ie',
      'en-NZ': 'nz',
      'en-ZA': 'za',
      'en-UG': 'ug',
      'en-TT': 'tt',
      'en-ZM': 'zm',
      'en-ZW': 'zw',
      'en-AG': 'ag',
      'en-BS': 'bs',
      'en-BB': 'bb',
      'en-BZ': 'bz',
      'en-DM': 'dm',
      'en-FJ': 'fj',
      'en-GM': 'gm',
      'en-GH': 'gh',
      'en-GD': 'gd',
      'en-GY': 'gy',
      'en-JM': 'jm',
      'en-KI': 'ki',
      'en-LC': 'lc',
      'en-VC': 'vc',
      'en-WS': 'ws',
      'en-SC': 'sc',
      'en-SG': 'sg',
      'en-SS': 'ss',
      'en-SZ': 'sz',
      'en-TO': 'to',
      'en-NA': 'na',
      'en-NG': 'ng',
      'en-MU': 'mu',
      'en-MW': 'mw',
      'en-LR': 'lr',
      'en-NR': 'nr',
      'en-FM': 'fm',
      'en-MH': 'mh',
      'en-SL': 'sl',
      'en-SB': 'sb',
      'en-PG': 'pg',
      'en-PW': 'pw',
      'en-KN': 'kn',
      'fi-FI': 'fi',
      'fr-FR': 'fr',
      'fr-CA': 'ca',
      'fr-BE': 'be',
      'fr-CH': 'ch',
      'fr-LU': 'lu',
      'fr-MC': 'mc',
      'fr-DZ': 'dz',
      'fr-TG': 'tg',
      'fr-SN': 'sn',
      'fr-BJ': 'bj',
      'fr-BF': 'bf',
      'fr-CM': 'cm',
      'fr-CF': 'cf',
      'fr-TD': 'td',
      'fr-CG': 'cg',
      'fr-GA': 'ga',
      'fr-GN': 'gn',
      'fr-HT': 'ht',
      'fr-ML': 'ml',
      'de-DE': 'de',
      'de-AT': 'at',
      'de-CH': 'ch',
      'de-LI': 'li',
      'de-LU': 'lu',
      'el-GR': 'gr',
      'el-CY': 'cy',
      'hu-HU': 'hu',
      'is-IS': 'is',
      'it-IT': 'it',
      'it-CH': 'ch',
      'it-SM': 'sm',
      'it-VA': 'va',
      'lt-LT': 'lt',
      'lv-LV': 'lv',
      'mk-MK': 'mk',
      'mt-MT': 'mt',
      'no-NO': 'no',
      'pl-PL': 'pl',
      'pt-PT': 'pt',
      'pt-BR': 'br',
      'pt-AO': 'ao',
      'pt-CV': 'cv',
      'pt-GW': 'gw',
      'pt-MZ': 'mz',
      'pt-ST': 'st',
      'pt-TL': 'tl',
      'ro-RO': 'ro',
      'ro-MD': 'md',
      'ru-RU': 'ru',
      'sk-SK': 'sk',
      'sl-SI': 'si',
      'sr-RS': 'rs',
      'es-ES': 'es',
      'es-AR': 'ar',
      'es-BO': 'bo',
      'es-CL': 'cl',
      'es-CO': 'co',
      'es-CR': 'cr',
      'es-CU': 'cu',
      'es-DO': 'do',
      'es-EC': 'ec',
      'es-SV': 'sv',
      'es-GT': 'gt',
      'es-HN': 'hn',
      'es-MX': 'mx',
      'es-NI': 'ni',
      'es-PA': 'pa',
      'es-PY': 'py',
      'es-PE': 'pe',
      'es-PR': 'pr',
      'es-UY': 'uy',
      'es-VE': 've',
      'sv-SE': 'se',
      'et-EE': 'ee',
      'uk-UA': 'ua',
      'ca-AD': 'ad',
      'sq-AL': 'al',
      'be-BY': 'by',
      'bs-BA': 'ba',
      'lb-LU': 'lu',

      // Middle Eastern Languages
      'ar-SA': 'sa',
      'ar-AE': 'ae',
      'ar-BH': 'bh',
      'ar-DZ': 'dz',
      'ar-EG': 'eg',
      'ar-IQ': 'iq',
      'ar-JO': 'jo',
      'ar-KW': 'kw',
      'ar-LB': 'lb',
      'ar-LY': 'ly',
      'ar-MA': 'ma',
      'ar-OM': 'om',
      'ar-QA': 'qa',
      'ar-SD': 'sd',
      'ar-SY': 'sy',
      'ar-YE': 'ye',
      'ar-KM': 'km',
      'ar-MR': 'mr',
      'ar-DJ': 'dj',
      'fa-IR': 'ir',
      'fa-AF': 'af',
      'he-IL': 'il',
      'tr-TR': 'tr',
      'tk-TM': 'tm',
      'az-AZ': 'az',
      'hy-AM': 'am',
      'ka-GE': 'ge',
      'kk-KZ': 'kz',
      'ky-KG': 'kg',
      'tg-TJ': 'tj',
      'uz-UZ': 'uz',

      // African Languages
      'af-ZA': 'za',
      'am-ET': 'et',
      'sw-KE': 'ke',
      'sw-TZ': 'tz',
      'zu-ZA': 'za',
      'rw-RW': 'rw',
      'so-SO': 'so',
      'st-LS': 'ls',
      'tn-BW': 'bw',
      'mg-MG': 'mg',
      'ti-ER': 'er',
      'rn-BI': 'bi',
      'to-TO': 'to',
      'bi-VU': 'vu',
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
        const SnackBar(content: Text('Failed to update language')),
      );
    }
  }
}
