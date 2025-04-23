import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    // List of supported languages with their codes and names
    final supportedLanguages = [
      {'code': 'en-US', 'name': 'English', 'localName': 'English'},
      {'code': 'ko-KR', 'name': 'Korean', 'localName': '한국어'},
      {'code': 'ja-JP', 'name': 'Japanese', 'localName': '日本語'},
      {'code': 'zh-CN', 'name': 'Chinese', 'localName': '中文'},
      {'code': 'es-ES', 'name': 'Spanish', 'localName': 'Español'},
      {'code': 'fr-FR', 'name': 'French', 'localName': 'Français'},
      {'code': 'de-DE', 'name': 'German', 'localName': 'Deutsch'},
    ];

    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 제목
            Row(
              children: [
                Icon(Icons.language, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Language',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // 언어 선택 목록
            ...supportedLanguages
                .map((language) =>
                    _buildLanguageItem(context, language, languageProvider))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem(BuildContext context, Map<String, String> language,
      LanguageProvider provider) {
    final isSelected = language['code'] == provider.currentLanguage;

    return InkWell(
      onTap: () {
        provider.setLanguage(language['code']!);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border:
              isSelected ? Border.all(color: Colors.purple, width: 1) : null,
        ),
        child: Row(
          children: [
            // 언어 이름 (현지 언어로)
            Expanded(
              child: Text(
                language['localName']!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.purple : Colors.black87,
                ),
              ),
            ),

            // 영어 이름
            if (!isSelected)
              Text(
                language['name']!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

            // 선택 아이콘
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.purple, size: 20),
          ],
        ),
      ),
    );
  }
}

// 언어 선택 다이얼로그
class LanguageSelectorDialog extends StatelessWidget {
  const LanguageSelectorDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 제목
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Language',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8),

            // 언어 선택기
            LanguageSelector(),

            // 닫기 버튼
            SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  // 다이얼로그 표시 메서드
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => LanguageSelectorDialog(),
    );
  }
}
